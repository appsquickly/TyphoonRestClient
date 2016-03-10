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

#import "TRCSessionTaskContext.h"
#import "TRCUtils.h"
#import "TyphoonRestClientErrors.h"
#import "TRCResponseDelegate.h"

@interface TRCSessionTaskContext ()<TRCResponseInfo>

@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) TRCConnectionCompletion completion;
@property (nonatomic, strong) id<TRCConnectionRequestSendingOptions> options;

@property (nonatomic, strong) TRCUploadProgressBlock uploadProgressBlock;
@property (nonatomic, strong) TRCDownloadProgressBlock downloadProgressBlock;

@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation TRCSessionTaskContext {
    int64_t _totalBytesReceived;
    NSIndexSet *_acceptableStatusCodes;
}

- (instancetype)initWithTask:(NSURLSessionDataTask *)task options:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion
{
    self = [super init];
    if (self) {
        self.task = task;
        self.options = options;
        self.completion = completion;
        _totalBytesReceived = 0;
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

- (BOOL)shouldProcessResponse:(NSURLResponse *)response
{
    self.response = (NSHTTPURLResponse *)response;

    BOOL shouldProcess = YES;

    if ([self.options.responseDelegate respondsToSelector:@selector(connection:shouldProcessResponse:)]) {
        shouldProcess = [self.options.responseDelegate connection:self.connection shouldProcessResponse:response];
    }

    if (self.options.outputStream) {
        [self.options.outputStream open];
    }

    return shouldProcess;
}

- (void)didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    if (self.uploadProgressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadProgressBlock((NSUInteger)bytesSent, totalBytesSent, totalBytesExpectedToSend);
        });
    }

    if ([self.options.responseDelegate respondsToSelector:@selector(connection:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
        [self.options.responseDelegate connection:self.connection didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
    }
}

- (void)didReceiveData:(NSData *)data
{
    _totalBytesReceived += [data length];
    if (self.downloadProgressBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloadProgressBlock([data length], _totalBytesReceived, self.response.expectedContentLength);
        });
    }

    if (self.options.outputStream) {
        NSUInteger dataLength = data.length;
        NSInteger written = [self.options.outputStream write:data.bytes maxLength:dataLength];
        if (written < (NSInteger)dataLength) {
            NSLog(@"Warning: Can't write data to output stream. Do we have enough disk space?");
        }
    } else {
        if (!self.responseData) {
            self.responseData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)MAX(self.response.expectedContentLength, 0)];
        }
        [self.responseData appendData:data];
    }

    if ([self.options.responseDelegate respondsToSelector:@selector(connection:didReceiveData:)]) {
        [self.options.responseDelegate connection:self.connection didReceiveData:data];
    }
}

- (void)didCompleteWithError:(NSError *)networkError
{
    NSError *error = networkError;
    id dataObject = nil;

    if (!networkError) {
        NSError *responseError = nil;
        NSError *dataError = nil;

        [self validateResponse:self.response error:&responseError];
        dataObject = [self bodyObjectWithError:&dataError];

        NSMutableOrderedSet *errors = [[NSMutableOrderedSet alloc] initWithCapacity:2];
        if (dataError) {
            [errors addObject:dataError];
        }
        if (responseError) {
            [errors addObject:responseError];
        }
        error = TRCErrorFromErrorSet(errors, TyphoonRestClientErrorCodeBadResponse, @"response");
    }

    if (self.options.outputStream) {
        [self.options.outputStream close];
    }

    if ([self.options.responseDelegate respondsToSelector:@selector(connection:didCompleteWithError:)]) {
        [self.options.responseDelegate connection:self.connection didCompleteWithError:error];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completion) {
            self.completion(dataObject, error, self);
        }
    });
}

//-------------------------------------------------------------------------------------------
#pragma mark - Progress Handler Protocol
//-------------------------------------------------------------------------------------------

- (void)pause
{
    [self.task suspend];
}

- (void)resume
{
    [self.task resume];
}

- (void)cancel
{
    [self.task cancel];
}

- (TRCProgressHandlerState)state
{
    //TODO: Do explicit states mapping
    return (TRCProgressHandlerState)self.task.state;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Private
//-------------------------------------------------------------------------------------------

- (BOOL)validateResponse:(NSURLResponse *)response error:(NSError **)error
{
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        if (error) {
            *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeBadResponse, @"Bad response");
        }
        return NO;
    }

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (![_acceptableStatusCodes containsIndex:(NSUInteger)httpResponse.statusCode]) {
        if (error) {
            NSMutableDictionary *mutableUserInfo = [@{
                    NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Request failed: %@ (%ld)", [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode], (long)httpResponse.statusCode],
                    NSURLErrorFailingURLErrorKey : [response URL],
                    TyphoonRestClientErrorKeyResponse : response,
            } mutableCopy];
            *error = [[NSError alloc] initWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeBadResponseCode userInfo:mutableUserInfo];
        }
        return NO;
    }

    return YES;
}

- (id)bodyObjectWithError:(NSError **)error
{
    id result = nil;

    if ([self.responseData length] > 0)
    {
        NSError *serializerError = nil;
        NSError *contentTypeError = nil;
        id<TRCResponseSerializer> serialization = self.options.responseSerialization;
        BOOL correctContentType = YES;

        if ([serialization respondsToSelector:@selector(isCorrectContentType:)]) {
            correctContentType = [serialization isCorrectContentType:[self.response MIMEType]];
        }

        if (correctContentType) {
            result = [serialization objectFromResponseData:self.responseData error:&serializerError];
        } else {
            contentTypeError = TRCErrorWithFormat(TyphoonRestClientErrorCodeBadResponseMime, @"Unacceptable content-type: %@", [self.response MIMEType]);
        }

        if (error) {
            if (contentTypeError) {
                *error = contentTypeError;
            } else if (serializerError) {
                *error = serializerError;
            }
        }
    }
    return result;
}

@end