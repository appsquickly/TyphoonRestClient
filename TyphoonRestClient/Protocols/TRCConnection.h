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
    TRCConnectionReachabilityStateUnknown = -1,
    TRCConnectionReachabilityStateNotReachable = 0,
    TRCConnectionReachabilityStateReachableViaWWAN = 1,
    TRCConnectionReachabilityStateReachableViaWifi = 2
} TRCConnectionReachabilityState;

typedef void (^TRCConnectionCompletion)(id responseObject, NSError *error, id<TRCResponseInfo> responseInfo);

@protocol TRCConnection

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError;
- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion;

@optional
- (TRCConnectionReachabilityState)reachabilityState;
- (void)setReachabilityDelegate:(id<TRCConnectionReachabilityDelegate>)reachabilityDelegate;

@end

//=============================================================================================================================
#pragma mark - Progress Handler
//=============================================================================================================================

typedef void (^TRCUploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);
typedef void (^TRCDownloadProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);

@protocol TRCProgressHandler<NSObject>

- (void)setUploadProgressBlock:(TRCUploadProgressBlock)block;
- (TRCUploadProgressBlock)uploadProgressBlock;

- (void)setDownloadProgressBlock:(TRCDownloadProgressBlock)block;
- (TRCDownloadProgressBlock)downloadProgressBlock;

- (void)pause;
- (void)resume;

- (void)cancel;

@end

//=============================================================================================================================
#pragma mark - Response Info
//=============================================================================================================================

@protocol TRCResponseInfo<NSObject>

- (NSHTTPURLResponse *)response;

- (NSData *)responseData;

@end

//=============================================================================================================================
#pragma mark - Request Context
//=============================================================================================================================

@protocol TRCConnectionRequestCreationOptions <NSObject>

@property (nonatomic, assign) TRCRequestMethod method;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSDictionary *pathParameters;
@property (nonatomic, strong) id body;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, assign) id<TRCRequestSerializer> serialization;
@property (nonatomic, strong) NSDictionary *customProperties;

@end


@protocol TRCConnectionRequestSendingOptions <NSObject>

@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, assign) id<TRCResponseSerializer> responseSerialization;
@property (nonatomic, strong) NSDictionary *customProperties;
@property (nonatomic, assign) NSOperationQueuePriority queuePriority;

@end

//=============================================================================================================================
#pragma mark - Reachability Delegate
//=============================================================================================================================

@protocol TRCConnectionReachabilityDelegate <NSObject>

- (void)connection:(id<TRCConnection>)connection didChangeReachabilityState:(TRCConnectionReachabilityState)state;

@end
