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
#import "HWSRequest.h"

//=============================================================================================================================
#pragma mark - Connection
//=============================================================================================================================

@protocol HWSProgressHandler;
@protocol HWSResponseInfo;

typedef void (^HWSConnectionCompletion)(id responseObject, NSError *error, id<HWSResponseInfo> responseInfo);

@protocol HWSConnection

- (NSMutableURLRequest *)requestWithMethod:(HttpRequestMethod)httpMethod path:(NSString *)path pathParams:(NSDictionary *)pathParams body:(id)bodyObject serialization:(HttpRequestSerialization)serialization headers:(NSDictionary *)headers error:(NSError **)requestComposingError;

- (id<HWSProgressHandler>)sendRequest:(NSURLRequest *)request responseSerialization:(HttpResponseSerialization)serialization outputStream:(NSOutputStream *)outputStream completion:(HWSConnectionCompletion)completion;

@end

//=============================================================================================================================
#pragma mark - Progress Handler
//=============================================================================================================================

typedef void (^HWSUploadProgressBlock)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite);
typedef void (^HWSDownloadProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);

@protocol HWSProgressHandler<NSObject>

- (void)setUploadProgressBlock:(HWSUploadProgressBlock)block;
- (HWSUploadProgressBlock)uploadProgressBlock;

- (void)setDownloadProgressBlock:(HWSDownloadProgressBlock)block;
- (HWSDownloadProgressBlock)downloadProgressBlock;

- (void)pause;
- (void)resume;

- (void)cancel;

@end

//=============================================================================================================================
#pragma mark - Response Info
//=============================================================================================================================

@protocol HWSResponseInfo<NSObject>

- (NSHTTPURLResponse *)response;

- (NSData *)responseData;

@end
