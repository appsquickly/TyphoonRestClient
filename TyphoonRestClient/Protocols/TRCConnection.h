////////////////////////////////////////////////////////////////////////////////
//
//  AppsQuick.ly
//  Copyright 2015 AppsQuick.ly
//  All Rights Reserved.
//
//  NOTICE: This software is the proprietary information of AppsQuick.ly
//  Use is subject to license terms.
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

typedef void (^TRCConnectionCompletion)(id responseObject, NSError *error, id<TRCResponseInfo> responseInfo);

@protocol TRCConnection

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError;

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion;

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

//-------------------------------------------------------------------------------------------
#pragma mark - Request Context
//-------------------------------------------------------------------------------------------

@protocol TRCConnectionRequestCreationOptions <NSObject>

@property (nonatomic, assign) TRCRequestMethod method;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSDictionary *pathParameters;
@property (nonatomic, strong) id body;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, assign) TRCRequestSerialization serialization;
@property (nonatomic, strong) NSDictionary *customProperties;

@end


@protocol TRCConnectionRequestSendingOptions <NSObject>

@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, assign) TRCResponseSerialization responseSerialization;
@property (nonatomic, strong) NSDictionary *customProperties;

@end