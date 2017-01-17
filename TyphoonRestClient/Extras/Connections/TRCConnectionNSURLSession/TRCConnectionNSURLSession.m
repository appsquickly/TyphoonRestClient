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

#import "TRCConnectionNSURLSession.h"
#import "TRCUtils.h"
#import "TRCSessionHandler.h"
#import "TRCSessionTaskContext.h"
#import "TRCNetworkReachabilityManager.h"


static BOOL IsBodyAllowedInHttpMethod(TRCRequestMethod method);
static float TaskPriorityFromQueuePriority(NSOperationQueuePriority priority);

@interface TRCConnectionNSURLSession ()

@property (nonatomic, strong) TRCSessionHandler *sessionHandler;

@property (nonatomic, weak) id<TRCConnectionReachabilityDelegate> reachabilityDelegate;
@end

@implementation TRCConnectionNSURLSession

//-------------------------------------------------------------------------------------------
#pragma mark - TRCConnection Protocol
//-------------------------------------------------------------------------------------------

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError
{
    NSError *urlComposingError = nil;
    NSURL *url = [self urlFromPath:options.path parameters:options.pathParameters queryOptions:options.queryOptions error:&urlComposingError];

    if (urlComposingError) {
        if(requestComposingError) {
            *requestComposingError = urlComposingError;
        }
        return nil;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = options.method;
    NSAssert([request.HTTPMethod length] > 0, @"Incorrect HTTP method ('%@') for request with options: %@", options.method, options);
    [options.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
            [request setValue:value forHTTPHeaderField:field];
        }
    }];

    BOOL success = [self composeBodyForRequest:request withOptions:options error:requestComposingError];
    if (!success) {
        request = nil;
    }

    if (request && options.requestPostProcessor && [options.requestPostProcessor respondsToSelector:@selector(requestPostProcessedFromRequest:)]) {
        request = [options.requestPostProcessor requestPostProcessedFromRequest:request];
    }

    return request;
}

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion
{
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    if ([task respondsToSelector:@selector(priority)]) {
        task.priority = TaskPriorityFromQueuePriority(options.queuePriority);
    }
    TRCSessionTaskContext *context = [[TRCSessionTaskContext alloc] initWithTask:task options:options completion:completion];
    context.connection = self;
    [self.sessionHandler startDataTask:task withContext:context];
    return context;
}

- (TRCConnectionReachabilityState)reachabilityState
{
    return (TRCConnectionReachabilityState)self.reachabilityManager.networkReachabilityStatus;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Private Methods
//-------------------------------------------------------------------------------------------

- (instancetype)init
{
    return [self initWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl
{
    return [self initWithBaseUrl:baseUrl configuration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl configuration:(NSURLSessionConfiguration *)configuration
{
    self = [super init];
    if (self) {
        _baseUrl = baseUrl;
        [self setupWithConfiguration:configuration];
    }
    return self;
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super init];
    if (self) {
        [self setupWithConfiguration:configuration];
    }
    return self;
}

- (void)setupWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSOperationQueue *backgroundQueue = [NSOperationQueue new];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
    if ([backgroundQueue respondsToSelector:@selector(qualityOfService)]) {
        backgroundQueue.qualityOfService = NSOperationQualityOfServiceUtility;
    }
#endif
    _sessionHandler = [TRCSessionHandler new];
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:_sessionHandler delegateQueue:backgroundQueue];

    __weak __typeof (self) weakSelf = self;
    _reachabilityManager = [TRCNetworkReachabilityManager sharedManager];
    [_reachabilityManager setReachabilityStatusChangeBlock:^(TRCNetworkReachabilityStatus status) {
        [weakSelf.reachabilityDelegate connection:weakSelf didChangeReachabilityState:(TRCConnectionReachabilityState)status];
    }];
}

- (void)startReachabilityMonitoring
{
    [self.reachabilityManager startMonitoring];
}

- (void)stopReachabilityMonitoring
{
    [self.reachabilityManager stopMonitoring];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Request composing
//-------------------------------------------------------------------------------------------

- (BOOL)composeBodyForRequest:(NSMutableURLRequest *)request withOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)error
{
    id<TRCRequestSerializer> serializer = options.serialization;
    id bodyObject = options.body;
    NSError *composeError = nil;

    if (!IsBodyAllowedInHttpMethod(options.method)) {
        bodyObject = nil;
    }

    if (bodyObject) {
        if (![request valueForHTTPHeaderField:@"Content-Type"]
                && [serializer respondsToSelector:@selector(contentType)] && [serializer contentType]) {
            [request setValue:[serializer contentType] forHTTPHeaderField:@"Content-Type"];
        }
        if ([serializer respondsToSelector:@selector(bodyDataFromObject:forRequest:error:)]) {
            NSData *data = [serializer bodyDataFromObject:bodyObject forRequest:request error:&composeError];
            if (data) {
                [request setHTTPBody:data];
                if (![request valueForHTTPHeaderField:@"Content-Length"]) {
                    NSString *bodyLength = [NSString stringWithFormat:@"%llu", (unsigned long long int)[data length]];
                    [request setValue:bodyLength forHTTPHeaderField:@"Content-Length"];
                }
            }
        } else if ([serializer respondsToSelector:@selector(bodyStreamFromObject:forRequest:error:)]) {
            NSInputStream *stream = [serializer bodyStreamFromObject:bodyObject forRequest:request error:&composeError];
            if (stream) {
                [request setHTTPBodyStream:stream];
            }
        }
    }

    if (composeError && error) {
        *error = composeError;
    }

    return (composeError == nil);
}

//-------------------------------------------------------------------------------------------
#pragma mark - URL Composing
//-------------------------------------------------------------------------------------------

- (NSURL *)urlFromPath:(NSString *)path parameters:(NSDictionary *)parameters queryOptions:(TRCSerializerHttpQueryOptions)options error:(NSError **)error
{
    NSURL *result = [self absoluteUrlFromPath:path];

    if ([parameters count] > 0) {
        NSString *query = TRCQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding, options);
        result = [NSURL URLWithString:[[result absoluteString] stringByAppendingFormat:result.query ? @"&%@" : @"?%@", query]];
    }

    return result;
}

- (NSURL *)absoluteUrlFromPath:(NSString *)path
{
    BOOL isAlreadyAbsolute = [path rangeOfString:@"://"].location != NSNotFound;
    if (isAlreadyAbsolute) {
        return [[NSURL alloc] initWithString:path];
    } else {
        return [[NSURL alloc] initWithString:path relativeToURL:self.baseUrl];
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Private Utils
//-------------------------------------------------------------------------------------------

static BOOL IsBodyAllowedInHttpMethod(TRCRequestMethod method)
{
    return method == TRCRequestMethodPost || method == TRCRequestMethodPut || method == TRCRequestMethodPatch;
}

static float TaskPriorityFromQueuePriority(NSOperationQueuePriority priority)
{
    switch (priority) {
        case NSOperationQueuePriorityVeryLow:
            return 0.15;
        case NSOperationQueuePriorityLow:
            return 0.25;
        default:
        case NSOperationQueuePriorityNormal:
            return 0.5;
        case NSOperationQueuePriorityHigh:
            return 0.75;
        case NSOperationQueuePriorityVeryHigh:
            return 0.95;
    }
}

@end
