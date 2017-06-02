////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON REST CLIENT
//  Copyright 2015, Typhoon Rest Client Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////


#import <Foundation/Foundation.h>
#import "TRCRequest.h"
#import "TRCSerializerHttpQuery.h"

//=============================================================================================================================
#pragma mark - Connection
//=============================================================================================================================

@protocol TRCProgressHandler;
@protocol TRCResponseInfo;
@protocol TRCConnectionRequestCreationOptions;
@protocol TRCConnectionRequestSendingOptions;
@protocol TRCRequestSerializer;
@protocol TRCResponseSerializer;
@protocol TRCConnectionReachabilityDelegate;

typedef enum {
    ///Unknown means that connection doesn't support reachability, or reachability monitoring not started
    TRCConnectionReachabilityStateUnknown = -1,
    ///Not Reachable means that connection can't access to the internet or specified host is not accessible
    TRCConnectionReachabilityStateNotReachable = 0,
    ///Internet or specified host accessible via cellular network
    TRCConnectionReachabilityStateReachableViaWWAN = 1,
    ///Internet or specified host accessible via WiFi network
    TRCConnectionReachabilityStateReachableViaWifi = 2
} TRCConnectionReachabilityState;

typedef void (^TRCConnectionCompletion)(id responseObject, NSError *error, id<TRCResponseInfo> responseInfo);

/**
* TRCConnection provides abstraction over network connection. TyphoonRestClient instance uses `connection` to two main tasks:
* - request creation, using `requestWithOptions:error:` method
* - request sending, using `sendRequest:withOptions:completion:` method
*
* You can use default implementation of `TRCConnection` protocol, which uses AFNetworking library (see `TRCConnectionAFNetworking`).
* It's also useful to inject your own connection between `TyphoonRestClient` and real `TRCConnection`, to listen all network events, and modify request if needed.
* For example `TRCConnectionLogger` just prints any network activity into log.
*
* @see TRCConnectionLogger.
* @see TRCConnectionAFNetworking
* @see TRCConnectionStub
* */
@protocol TRCConnection

/**
* Creates `NSURLRequest` using information from `TRCRequest`.
*
* `TyphoonRestClient` handles `TRCRequest` and collect all necessary info into special, easy-to-use object of `<TRCConnectionRequestCreationOptions>` protocol.
*
* Notice, that return value is **mutable** NSMutableURLRequest. That useful for connections-in-the-middle to modify request made by real network connection (usually used to add additional headers)
*
* @param options contains all information required to compose NSURLRequest
* @param requestComposingError pointer to NSError object. Write your error object into that pointer, if you can't create NSURLRequest and return nil
* */
- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError;

/**
* Sends `NSURLRequest` via network, then handles response using `options.responseBodySerialization` or writes into `options.outputStream`.
* `TyphoonRestClient` makes `TRCConnectionRequestSendingOptions` using `TRCRequest`. These send options contains all necessary information to send request and handle response.
*
* Note that this method should return object that confirms `<TRCProgressHandler>` protocol, so  caller can track upload and download progress. (Implemented in `TRCConnectionAFNetworking`)
*
* @param request request to send via network
* @param options contains information required to send request and handle response
* @param completion block that contains result, response information and error arguments. Note that completion block is not retained, so it's not necessary to put weak varies inside.
* @return returns object that used by caller to track upload/download progress
* */
- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion;

@optional
/**
* Returns current reachability state if implemented. If not implemented, treats as `TRCConnectionReachabilityStateUnknown`
* */
- (TRCConnectionReachabilityState)reachabilityState;

/**
* Sets `TRCConnectionReachabilityDelegate`, which used to get notified about reachabilityState changes.
* Used by `TyphoonRestClient`, which post `TyphoonRestClientReachabilityDidChangeNotification` after each changing
* */
- (void)setReachabilityDelegate:(id<TRCConnectionReachabilityDelegate>)reachabilityDelegate;

@end

//=============================================================================================================================
#pragma mark - Progress Handler
//=============================================================================================================================

typedef void (^TRCUploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);
typedef void (^TRCDownloadProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);

typedef NS_ENUM(NSInteger, TRCProgressHandlerState) {
    TRCProgressHandlerStateRunning,
    TRCProgressHandlerStateSuspended,
    TRCProgressHandlerStateCanceling,
    TRCProgressHandlerStateCompleted
};

/**
* `TRCProgressHandler` describes methods of object, used to track download and upload progress
* */
@protocol TRCProgressHandler<NSObject>

/**
* Sets upload block, which called after each upload progress change.
*
* @note This block is retained until network operation in progress
* */
- (void)setUploadProgressBlock:(TRCUploadProgressBlock)block;

/**
* Sets download block, which called after each upload progress change.
*
* @note This block is retained until network operation in progress
* */
- (void)setDownloadProgressBlock:(TRCDownloadProgressBlock)block;

/**
*  Pauses current upload or download progress
* */
- (void)pause;

/**
* Resumes current upload or download progress
* */
- (void)resume;

/**
* Cancels current upload or download progress
* */
- (void)cancel;

/**
 * Returns current state of network operation
 * */
- (TRCProgressHandlerState)state;

@end

//=============================================================================================================================
#pragma mark - Response Info
//=============================================================================================================================

/**
* Additional information about response
* */
@protocol TRCResponseInfo<NSObject>

/**
* Response info which includes:
* - all HTTP headers
* - HTTP status code
**/
- (NSHTTPURLResponse *)response;

/**
* Response body in `NSData` representation
* */
- (NSData *)responseData;

@end

//=============================================================================================================================
#pragma mark - Request Context
//=============================================================================================================================

/**
* Information required to create NSURLResponse
* */
@protocol TRCConnectionRequestCreationOptions <NSObject>

/// HTTP method string, like GET, POST, PUT, etc... See `TRCRequest.method`
@property (nonatomic, assign) TRCRequestMethod method;

/// Part of url, used to compose absolute url, or absolute url itself (if starts from http:// or https://). See `TRCRequest.path`
@property (nonatomic, strong) NSString *path;

/// Parameters used to compose absolute url. See `TRCRequest.pathParameters`
@property (nonatomic, strong) NSDictionary *pathParameters;

/// Request body object. See `TRCRequest.requestBody`
@property (nonatomic, strong) id body;

/// Serialization object, to transform body object into NSData
@property (nonatomic, assign) id<TRCRequestSerializer> serialization;

/// Custom headers to include into request, See `TRCRequest.requestHeaders`
@property (nonatomic, strong) NSDictionary *headers;

/// User-defined custom properties, which can be used by connections-in-the-middle. See `TRCRequest.customProperties`
@property (nonatomic, strong) NSDictionary *customProperties;

/// Please use this property only for `requestPostProcessedFromRequest` call
@property (nonatomic, strong) id<TRCRequest> requestPostProcessor;

@property (nonatomic, assign) TRCSerializerHttpQueryOptions queryOptions;

@property (nonatomic, assign) TRCRequestType requestType;

@end

/**
* Information required to send request and handle response
* */
@protocol TRCConnectionRequestSendingOptions <NSObject>

/// If set, response should be written into that stream
@property (nonatomic, strong) NSOutputStream *outputStream;

/// Object which will transform response body NSData into response object
@property (nonatomic, assign) id<TRCResponseSerializer> responseSerialization;

/// User-defined custom properties, which can be used by connections-in-the-middle. See `TRCRequest.customProperties`
@property (nonatomic, strong) NSDictionary *customProperties;

/// Queue priority in case there is limitation of concurrent requests. See `TRCRequest.queuePriority`
@property (nonatomic, assign) NSOperationQueuePriority queuePriority;

/// Custom response delegate. Useful to intercept all traffic, or implement custom logic
@property (nonatomic, strong) id<TRCResponseDelegate> responseDelegate;

@property (nonatomic, assign) TRCRequestType requestType;

/// Used for download/upload tasks to/from file on disk.
@property (nonatomic, strong) NSURL *localFileUrl;

@end

//=============================================================================================================================
#pragma mark - Reachability Delegate
//=============================================================================================================================

/**
* Defines method that would be called when reachability state changed
* */
@protocol TRCConnectionReachabilityDelegate <NSObject>

/**
* Called when reachability state of TRCConnection changed
* */
- (void)connection:(id<TRCConnection>)connection didChangeReachabilityState:(TRCConnectionReachabilityState)state;

@end
