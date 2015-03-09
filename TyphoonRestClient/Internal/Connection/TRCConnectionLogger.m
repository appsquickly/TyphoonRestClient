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

#import "TRCConnectionLogger.h"


@implementation TRCConnectionLogger
{
    dispatch_queue_t printing_queue;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        printing_queue = dispatch_queue_create("TRCConnectionLogger", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(printing_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    }
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(TRCRequestMethod)httpMethod path:(NSString *)path
    pathParams:(NSDictionary *)pathParams body:(id)bodyObject serialization:(TRCRequestSerialization)serialization
    headers:(NSDictionary *)headers error:(NSError **)requestComposingError
{
    return [self.connection requestWithMethod:httpMethod path:path pathParams:pathParams body:bodyObject
                                serialization:serialization headers:headers error:requestComposingError];
}

- (id <TRCProgressHandler>)sendRequest:(NSURLRequest *)request
    responseSerialization:(TRCResponseSerialization)serialization outputStream:(NSOutputStream *)outputStream
    completion:(TRCConnectionCompletion)completion
{
    [self printRequest:request];

    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();

    id <TRCProgressHandler> progressHandler =
        [self.connection sendRequest:request responseSerialization:serialization outputStream:outputStream
                          completion:^(id responseObject, NSError *error, id<TRCResponseInfo> responseInfo) {
                              [self printResponseInfo:responseInfo withObject:nil error:error forRequest:request
                                             duration:CFAbsoluteTimeGetCurrent() - time];
                              if (completion) {
                                  completion(responseObject, error, responseInfo);
                              }
                          }];

    if (request.HTTPBodyStream && self.shouldLogUploadProgress) {
        [self printUploadingProgress:progressHandler forRequest:request];
    }

    if (outputStream && self.shouldLogDownloadProgress) {
        [self printDownloadingProgress:progressHandler forRequest:request];
    }

    return progressHandler;
}

#pragma mark - Utils

- (void)printDownloadingProgress:(id <TRCProgressHandler>)progressHandler forRequest:(NSURLRequest *)request
{
    [progressHandler setDownloadProgressBlock:[self printProgressBlockForProgress:@"DOWNLOADING"
        directionMarker:@"<======================================================================================================"
        request:request]];
}

- (TRCDownloadProgressBlock)printProgressBlockForProgress:(NSString *)progressName directionMarker:(NSString *)marker
    request:(NSURLRequest *)request
{
    __block BOOL headerPrinted = NO;

    __block NSUInteger numberOfPrintedSegments = 0;

    return ^(NSUInteger bytesRead, long long int totalBytesRead, long long int totalBytesExpectedToRead) {
        if (!headerPrinted) {
            if (totalBytesExpectedToRead > 0) {
                NSString *bytesString = [NSByteCountFormatter stringFromByteCount:totalBytesExpectedToRead
                    countStyle:NSByteCountFormatterCountStyleFile];
                [self printFormat:@"%@\n", marker];
                [self printFormat:@"%@ | id: %lu | %@ | [..", progressName, (unsigned long) request, bytesString];
                headerPrinted = YES;
            }
        }
        if (headerPrinted) {
            double percent = (totalBytesRead / (double) totalBytesExpectedToRead) * 100;

            if ((int64_t) percent >= (int64_t) numberOfPrintedSegments) {
                if ((int) percent % 10 == 0) {
                    [self printFormat:@"%d%%", (int) percent];
                }
                else {
                    [self printString:@".."];
                }
                numberOfPrintedSegments += 5;
            }

            if (totalBytesRead >= totalBytesExpectedToRead) {
                [self printFormat:@"]\n%@\n", marker];
            }
        }
    };
}

- (void)printUploadingProgress:(id <TRCProgressHandler>)progressHandler forRequest:(NSURLRequest *)request
{
    [progressHandler setUploadProgressBlock:[self printProgressBlockForProgress:@"UPLOADING"
        directionMarker:@"======================================================================================================>"
        request:request]];
}

- (void)printRequest:(NSURLRequest *)request
{
    NSMutableString *output = [NSMutableString new];

    NSString *body = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    [output appendString:@"======================================================================================================>\n"];
    [output appendFormat:@"REQUEST  | id: %lu", (unsigned long) request];
    [output appendString:@"\n======================================================================================================>"];
    [output appendFormat:@"\nHTTP %@ %@\n", request.HTTPMethod, [[request.URL absoluteString] stringByRemovingPercentEncoding]];
    [output appendString:[self httpHeadersString:request.allHTTPHeaderFields]];
    if (body.length > 0) {
        [output appendFormat:@"\n\n%@", body];
    }
    [output appendString:@"\n======================================================================================================>\n"];

    [self printString:output];
}

- (void)printResponseInfo:(id <TRCResponseInfo>)responseInfo withObject:(id)responseObject error:(NSError *)error
    forRequest:(NSURLRequest *)request duration:(CFAbsoluteTime)duration
{
    NSMutableString *output = [NSMutableString new];
    [output appendString:@"<======================================================================================================\n"];
    [output appendFormat:@"RESPONSE | id: %lu | request time: %@", (unsigned long) request,
                         [self stringFromDuration:duration]];
    [output appendString:@"\n<======================================================================================================"];
    [output appendFormat:@"\n%ld (%@)\n", (long) responseInfo.response.statusCode,
                         [[NSHTTPURLResponse localizedStringForStatusCode:responseInfo.response.statusCode]
                             capitalizedString]];
    [output appendString:[self httpHeadersString:responseInfo.response.allHeaderFields]];

    if ([responseInfo responseData]) {
        NSString
            *description = [[NSString alloc] initWithData:[responseInfo responseData] encoding:NSUTF8StringEncoding];
        [output appendFormat:@"\n\n%@", description];
    }
    [output appendString:@"\n<======================================================================================================\n"];

    [self printString:output];
}

- (NSString *)httpHeadersString:(NSDictionary *)headers
{
    NSMutableString *output = [NSMutableString new];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        [output appendFormat:@"\n%@: %@", key, obj];
    }];
    return output;
}

- (NSString *)stringFromDuration:(CFAbsoluteTime)duration
{
    return [NSString stringWithFormat:@"%d second%s", (int) duration, (int) duration == 1 ? "" : "s"];
}

- (void)printFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
{
    va_list args;
    va_start(args, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self printString:string];
}

- (void)printString:(NSString *)string
{
    dispatch_async(printing_queue, ^{
        if (self.writer) {
            [self.writer logString:string];
        } else {
            NSLog(@"\n%@", string);
        }
    });
}

@end