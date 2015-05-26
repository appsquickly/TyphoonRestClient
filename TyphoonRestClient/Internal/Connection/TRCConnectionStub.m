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


#import "TRCConnectionStub.h"
#import "TRCInfrastructure.h"
#import "TyphoonRestClientErrors.h"
#import "TRCUtils.h"

@interface TRCConnectionStubResponseInfo : NSObject <TRCResponseInfo>

@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSHTTPURLResponse *response;

@end

@interface TRCConnectionStub()
@property (nonatomic, strong) NSMutableDictionary *responsesForUrl;
@end

@implementation TRCConnectionStub {
    TRCConnectionStubResponseBlock _responseForRequestBlock;
    id<TRCConnection> _requestMakingConnection;

    NSTimeInterval _minDelay;
    NSTimeInterval _maxDelay;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestMakingConnection = [[TRCConnectionAFNetworking alloc] initWithBaseUrl:[NSURL URLWithString:@"http://connection.stub"]];
    }

    return self;
}

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError
{
    return [_requestMakingConnection requestWithOptions:options error:requestComposingError];
}

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion
{
    TRCConnectionStubResponse *response = [self responseForRequest:request];
    
    id<TRCResponseInfo>responseInfo = [self responseInfoForRequest:request andResponse:response];
    
    id responseObject = nil;
    NSError *responseError = nil;
    
    if (response.error) {
        responseError = response.error;
        responseObject = nil;
    } else if ([options outputStream]) {
        [[options outputStream] write:[[responseInfo responseData] bytes] maxLength:[[responseInfo responseData] length]];
    } else {
        BOOL isContentTypeCorrect = YES;
        id<TRCResponseSerializer>responseSerializer = [options responseSerialization];
        if (response.mime && [responseSerializer respondsToSelector:@selector(isCorrectContentType:)]) {
            isContentTypeCorrect = [responseSerializer isCorrectContentType:response.mime];
        }
        if (isContentTypeCorrect) {
            responseObject = [responseSerializer objectFromResponseData:[responseInfo responseData] error:&responseError];
        } else {
            responseObject = nil;
            responseError = TRCErrorWithFormat(TyphoonRestClientErrorCodeBadResponseMime, @"Unacceptable content-type: %@", response.mime);
        }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
        responseError = TRCErrorWithFormat(TyphoonRestClientErrorCodeBadResponseCode, @"Incorrect HTTP status code %lu", (unsigned long)response.statusCode);
    }

    if (completion) {
        if (response.delayInSeconds > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(response.delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completion(responseObject, responseError, responseInfo);
            });
        } else {
            completion(responseObject, responseError, responseInfo);
        }
    }
    
    return nil;
}

- (TRCConnectionStubResponse *)responseForRequest:(NSURLRequest *)request
{
    NSParameterAssert(_responseForRequestBlock);
    
    return _responseForRequestBlock(request);
}

- (id<TRCResponseInfo>)responseInfoForRequest:(NSURLRequest *)request andResponse:(TRCConnectionStubResponse *)response
{
    TRCConnectionStubResponseInfo *info = [TRCConnectionStubResponseInfo new];
    info.responseData = response.data;
    NSMutableDictionary *responseHeaders = [NSMutableDictionary new];
    responseHeaders[@"Server"] = @"TyphoonRestClient Stub Connection";
    responseHeaders[@"Content-Length"] = [@([info.responseData length]) stringValue];
    responseHeaders[@"Connection"] = @"close";
    if (response.headers) {
        [responseHeaders addEntriesFromDictionary:response.headers];
    }
    info.response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:response.statusCode HTTPVersion:@"1.1" headerFields:responseHeaders];
    return info;
}

#pragma mark - Response Registration

#define KeyFromPathAndQuery(path, query) [NSString stringWithFormat:@"%@%@", path, query.length > 0 ?query:@""]

- (void)setResponse:(TRCConnectionStubResponse *)response forPath:(NSString *)urlPath withQuery:(NSString *)urlQuery
{
    NSString *key = KeyFromPathAndQuery(urlPath, urlQuery);
    if (!self.responsesForUrl) {
        self.responsesForUrl = [NSMutableDictionary new];
    }
    self.responsesForUrl[key] = response;
    
    __weak __typeof (self) weakSelf = self;
    [self setResponseBlock:^TRCConnectionStubResponse*(NSURLRequest *request) {
        NSDictionary *responsesDict = weakSelf.responsesForUrl;
        NSString *getKey = KeyFromPathAndQuery(request.URL.path, request.URL.query);
        TRCConnectionStubResponse *result = responsesDict[getKey];
        if (!result) {
            result = [[TRCConnectionStubResponse alloc] initWithContentNotFoundError];
        }
        return result;
    }];
}

- (void)setResponse:(TRCConnectionStubResponse *)response
{
    [self setResponseBlock:^TRCConnectionStubResponse *(NSURLRequest *request) {
        return response;
    }];
}

- (void)setResponseBlock:(TRCConnectionStubResponseBlock)block
{
    _responseForRequestBlock = block;
}

@end


@implementation TRCConnectionStubResponse

- (instancetype)initWithConnectionError
{
    self = [super init];
    if (self) {
        _error = TRCErrorWithFormat(TyphoonRestClientErrorCodeConnectionError, @"Can't connect to the server");
    }
    return self;
}

- (instancetype)initWithResponseData:(NSData *)data mime:(NSString *)mime headers:(NSDictionary *)headers status:(NSUInteger)status
{
    self = [super init];
    if (self) {
        _data = data;
        _mime = mime;
        _headers = headers;
        _statusCode = status;
    }
    return self;
}

- (instancetype)initWithContentNotFoundError
{
    self = [super init];
    if (self) {
        _data = [@"Error 404. Content Not Found" dataUsingEncoding:NSUTF8StringEncoding];
        _mime = @"text/html";
        _statusCode = 404;
    }
    return self;
}

@end

@implementation TRCConnectionStubResponseInfo
@end

@implementation TRCConnectionStub (Shorthands)

- (void)setResponseText:(NSString *)text
{
    [self setResponseText:text status:200];
}

- (void)setResponseText:(NSString *)text status:(NSUInteger)status
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    TRCConnectionStubResponse *response = [[TRCConnectionStubResponse alloc] initWithResponseData:data mime:nil headers:nil status:status];
    [self setDelayForResponse:response];
    [self setResponse:response];
}

- (void)setResponseWithConnectionError
{
    [self setResponse:[[TRCConnectionStubResponse alloc] initWithConnectionError]];
}

- (void)setResponseText:(NSString *)text forRequestPath:(NSString *)path
{
    [self setResponseText:text status:200 forRequestPath:path];
}

- (void)setResponseText:(NSString *)text status:(NSUInteger)status forRequestPath:(NSString *)path
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    TRCConnectionStubResponse *response = [[TRCConnectionStubResponse alloc] initWithResponseData:data mime:nil headers:nil status:status];
    [self setDelayForResponse:response];
    [self setResponse:response forPath:path withQuery:nil];
}

- (void)setResponseTimeoutErrorForRequestPath:(NSString *)path
{
    TRCConnectionStubResponse *response = [[TRCConnectionStubResponse alloc] initWithConnectionError];
    response.delayInSeconds = _maxDelay;
    [self setResponse:response forPath:path withQuery:nil];
}

- (void)setResponseMinDelay:(NSTimeInterval)minDelay maxDelay:(NSTimeInterval)maxDelay
{
    if (_maxDelay > 0 && _minDelay > 0 && _maxDelay >= _minDelay) {
        _minDelay = minDelay;
        _maxDelay = maxDelay;
    }
}

- (void)setDelayForResponse:(TRCConnectionStubResponse *)response
{
    if (_maxDelay != _minDelay) {
        NSTimeInterval maxValueToGenerate = _maxDelay - _minDelay;
        int randValueInt = rand() % (int)(maxValueToGenerate * 1000);
        NSTimeInterval randValue = randValueInt / (NSTimeInterval)1000 + _minDelay;
        response.delayInSeconds = randValue;
    } else {
        response.delayInSeconds = _minDelay;
    }
}

@end

NSString *TRCBundleFile(NSString *fileName)
{
    NSString *path = [[NSBundle bundleForClass:[TRCConnectionStub class]] pathForResource:fileName ofType:nil];
    if (path) {
        return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    } else {
        return nil;
    }
}