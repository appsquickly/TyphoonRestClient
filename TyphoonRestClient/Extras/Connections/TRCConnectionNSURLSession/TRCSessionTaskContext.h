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
#import "TRCConnection.h"

@class TRCConnectionNSURLSession;


@interface TRCSessionTaskContext : NSObject <TRCProgressHandler>

@property (nonatomic, weak) TRCConnectionNSURLSession *connection;

- (instancetype)initWithTask:(NSURLSessionTask *)task options:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion;

- (BOOL)shouldProcessResponse:(NSURLResponse *)response;

- (void)didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

- (void)didReceiveData:(NSData *)data;

- (void)didCompleteWithError:(NSError *)networkError;

- (void)didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
          completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

- (TRCProgressHandlerState)state;

@end
