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

#import "TRCSessionHandler.h"
#import "TRCSessionTaskContext.h"

@implementation TRCSessionHandler
{
    NSMutableDictionary<NSNumber *, TRCSessionTaskContext *> *_taskContextRegistry;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _taskContextRegistry = [NSMutableDictionary new];
    }
    return self;
}

- (TRCSessionTaskContext *)contextForTask:(NSURLSessionTask *)task
{
    @synchronized (self) {
        return _taskContextRegistry[@(task.taskIdentifier)];
    }
}

- (void)startTask:(NSURLSessionTask *)task withContext:(TRCSessionTaskContext *)context
{
    @synchronized (self) {
        _taskContextRegistry[@(task.taskIdentifier)] = context;
    }
    [task resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    TRCSessionTaskContext *context = [self contextForTask:dataTask];

    if ([context shouldProcessResponse:response]) {
        completionHandler(NSURLSessionResponseAllow);
    } else {
        completionHandler(NSURLSessionResponseCancel);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    TRCSessionTaskContext *context = [self contextForTask:task];
    [context didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    TRCSessionTaskContext *context = [self contextForTask:dataTask];
    [context didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    TRCSessionTaskContext *context = [self contextForTask:task];
    [context didCompleteWithError:error];

    @synchronized (self) {
        [_taskContextRegistry removeObjectForKey:@(task.taskIdentifier)];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential))completionHandler
{
    TRCSessionTaskContext *context = [self contextForTask:task];
    [context didReceiveChallenge:challenge completionHandler:completionHandler];
}


@end
