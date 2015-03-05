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

#import "TRCConnectionAFNetworking.h"
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import "AFHTTPRequestOperationManager.h"

NSError *NSErrorWithDictionaryUnion(NSError *error, NSDictionary *dictionary);
NSString *NSStringFromHttpRequestMethod(TRCRequestMethod method);
Class ClassFromHttpRequestSerialization(TRCRequestSerialization serialization);
Class ClassFromHttpResponseSerialization(TRCResponseSerialization serialization);
BOOL IsBodyAllowedInHttpMethod(TRCRequestMethod method);

//============================================================================================================================

@interface AFStringResponseSerializer : AFHTTPResponseSerializer
@end

@implementation AFStringResponseSerializer
- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    data = [super responseObjectForResponse:response data:data error:error];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end

//=============================================================================================================================

@interface TRCAFNetworkingConnectionProgressHandler : NSObject <TRCProgressHandler>

@property (nonatomic, weak) AFHTTPRequestOperation *operation;

@property (atomic, strong) TRCUploadProgressBlock uploadProgressBlock;
@property (atomic, strong) TRCDownloadProgressBlock downloadProgressBlock;

@end

@implementation TRCAFNetworkingConnectionProgressHandler
- (void)setOperation:(AFHTTPRequestOperation *)operation
{
    [_operation setUploadProgressBlock:nil];
    [_operation setDownloadProgressBlock:nil];

    _operation = operation;

    [_operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long int totalBytesWritten, long long int totalBytesExpectedToWrite) {
        if (self.uploadProgressBlock) {
            self.uploadProgressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }
    }];

    [_operation setDownloadProgressBlock:^(NSUInteger bytesWritten, long long int totalBytesWritten, long long int totalBytesExpectedToWrite) {
        if (self.downloadProgressBlock) {
            self.downloadProgressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        }
    }];
}
- (void)pause
{
    [_operation pause];
}
- (void)resume
{
    [_operation resume];
}
- (void)cancel
{
    [_operation cancel];
}
@end

@interface TRCAFNetworkingConnectionResponseInfo : NSObject <TRCResponseInfo>
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSData *responseData;
+ (instancetype)infoWithOperation:(AFHTTPRequestOperation *)operation;
@end
@implementation TRCAFNetworkingConnectionResponseInfo
+ (instancetype)infoWithOperation:(AFHTTPRequestOperation *)operation
{
    TRCAFNetworkingConnectionResponseInfo *object = [TRCAFNetworkingConnectionResponseInfo new];
    object.response = operation.response;
    object.responseData = operation.responseData;
    return object;
}
@end

//=============================================================================================================================

@implementation TRCConnectionAFNetworking
{
    NSCache *_requestSerializersCache;
    NSCache *_responseSerializersCache;

    AFHTTPRequestOperationManager *_operationManager;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl
{
    self = [super init];
    if (self) {
        _baseUrl = baseUrl;
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseUrl];
        _responseSerializersCache = [NSCache new];
        _requestSerializersCache = [NSCache new];
    }
    return self;
}

- (AFNetworkReachabilityManager *)reachabilityManager
{
    return _operationManager.reachabilityManager;
}

#pragma mark - HttpWebServiceConnection protocol

- (NSMutableURLRequest *)requestWithMethod:(TRCRequestMethod)httpMethod path:(NSString *)path pathParams:(NSDictionary *)pathParams body:(id)bodyObject serialization:(TRCRequestSerialization)serialization headers:(NSDictionary *)headers error:(NSError **)requestComposingError
{
    NSError *urlComposingError = nil;
    NSURL *url = [self urlFromPath:path parameters:pathParams error:&urlComposingError];

    if (urlComposingError) {
        if(requestComposingError) {
            *requestComposingError = urlComposingError;
        }
        return nil;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = NSStringFromHttpRequestMethod(httpMethod);

    if (!IsBodyAllowedInHttpMethod(httpMethod)) {
        bodyObject = nil;
    }

    if ([bodyObject isKindOfClass:[NSData class]]) {
        [request setHTTPBody:bodyObject];
    } else if ([bodyObject isKindOfClass:[NSString class]]) {
        [request setHTTPBody:[bodyObject dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([bodyObject isKindOfClass:[NSInputStream class]]) {
        [request setHTTPBodyStream:bodyObject];
    } else if ([bodyObject isKindOfClass:[NSArray class]] || [bodyObject isKindOfClass:[NSDictionary class]]) {
        id<AFURLRequestSerialization> serializer = [self requestSerializerForType:serialization];
        request = [[serializer requestBySerializingRequest:request withParameters:bodyObject error:requestComposingError] mutableCopy];
    }

    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
            [request setValue:value forHTTPHeaderField:field];
        }
    }];

    return request;
}

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request responseSerialization:(TRCResponseSerialization)serialization outputStream:(NSOutputStream *)outputStream completion:(TRCConnectionCompletion)completion
{
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    requestOperation.responseSerializer = [self responseSerializerForType:serialization];

    requestOperation.outputStream = outputStream;

    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion) {
            completion(operation.responseObject, nil, [TRCAFNetworkingConnectionResponseInfo infoWithOperation:operation]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error) {
            NSInteger httpCode = operation.response.statusCode;
            error = NSErrorWithDictionaryUnion(error, @{@"TRCHttpStatusCode": @(httpCode)});
        }
        if (completion) {
            completion(operation.responseObject, error, [TRCAFNetworkingConnectionResponseInfo infoWithOperation:operation]);
        }
    }];

    TRCAFNetworkingConnectionProgressHandler *progressHandler = [TRCAFNetworkingConnectionProgressHandler new];
    progressHandler.operation = requestOperation;

    [_operationManager.operationQueue addOperation:requestOperation];

    return progressHandler;
}

#pragma mark - URL composing

- (NSURL *)urlFromPath:(NSString *)path parameters:(NSDictionary *)parameters error:(NSError **)error
{
    NSURL *result = nil;

    NSMutableDictionary *mutableParams = [parameters mutableCopy];

    if ([mutableParams count] > 0) {
        //Applying variables
        id<AFURLRequestSerialization> serializer = [self requestSerializerForType:TRCRequestSerializationHttp];

        static NSMutableURLRequest *request;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            request = [[NSMutableURLRequest alloc] init];
            request.HTTPMethod = @"GET";
        });

        request.URL = [self absoluteUrlFromPath:path];
        result = [[serializer requestBySerializingRequest:request withParameters:mutableParams error:error] URL];
    } else {
        result = [self absoluteUrlFromPath:path];
    }

    return result;
}

- (NSURL *)absoluteUrlFromPath:(NSString *)path
{
    BOOL isAlreadyAbsolute = [path hasPrefix:@"http://"] || [path hasPrefix:@"https://"];
    if (isAlreadyAbsolute) {
        return [[NSURL alloc] initWithString:path];
    } else {
        return [[NSURL alloc] initWithString:path relativeToURL:self.baseUrl];
    }
}

#pragma mark - Utils

- (id<AFURLRequestSerialization>)requestSerializerForType:(TRCRequestSerialization)serialization
{
    Class serializerClass = ClassFromHttpRequestSerialization(serialization);
    NSString *key = NSStringFromClass(serializerClass);
    id<AFURLRequestSerialization> cached = [_requestSerializersCache objectForKey:key];
    if (!cached) {
        cached = (id<AFURLRequestSerialization>)[serializerClass new];
        [_requestSerializersCache setObject:cached forKey:key];
    }
    return cached;
}

- (id<AFURLResponseSerialization>)responseSerializerForType:(TRCResponseSerialization)serialization
{
    Class serializerClass = ClassFromHttpResponseSerialization(serialization);
    NSString *key = NSStringFromClass(serializerClass);
    id<AFURLResponseSerialization> cached = [_responseSerializersCache objectForKey:key];
    if (!cached) {
        cached = (id<AFURLResponseSerialization>)[serializerClass new];
        [_responseSerializersCache setObject:cached forKey:key];
    }
    return cached;
}

NSString *NSStringFromHttpRequestMethod(TRCRequestMethod method)
{
    switch (method) {
        case TRCRequestMethodDelete: return @"DELETE";
        case TRCRequestMethodGet: return @"GET";
        case TRCRequestMethodHead: return @"HEAD";
        case TRCRequestMethodPatch: return @"PATCH";
        case TRCRequestMethodPost: return @"POST";
        case TRCRequestMethodPut: return @"PUT";
    }
    NSCAssert(NO, @"Unknown TRCRequestMethod: %d", (int)method);
    return @"";
}

BOOL IsBodyAllowedInHttpMethod(TRCRequestMethod method)
{
    return method == TRCRequestMethodPost || method == TRCRequestMethodPut || method == TRCRequestMethodPatch;
}

Class ClassFromHttpRequestSerialization(TRCRequestSerialization serialization)
{
    switch (serialization) {
        case TRCRequestSerializationJson: return [AFJSONRequestSerializer class];
        case TRCRequestSerializationHttp: return [AFHTTPRequestSerializer class];
        case TRCRequestSerializationPlist: return [AFPropertyListRequestSerializer class];
    }
    NSCAssert(NO, @"Unknown TRCRequestSerialization: %d", (int)serialization);
    return nil;
}

Class ClassFromHttpResponseSerialization(TRCResponseSerialization serialization)
{
    switch (serialization) {
        case TRCResponseSerializationJson: return [AFJSONResponseSerializer class];
        case TRCResponseSerializationData: return [AFHTTPResponseSerializer class];
        case TRCResponseSerializationImage: return [AFImageResponseSerializer class];
        case TRCResponseSerializationPlist: return [AFPropertyListResponseSerializer class];
        case TRCResponseSerializationXml: return [AFXMLParserResponseSerializer class];
        case TRCResponseSerializationString: return [AFStringResponseSerializer class];
    }
    NSCAssert(NO, @"Unknown TRCResponseSerialization: %d", (int)serialization);
    return nil;
}

NSError *NSErrorWithDictionaryUnion(NSError *error, NSDictionary *dictionary)
{
    NSMutableDictionary *userInfo = [[error userInfo] mutableCopy];
    [userInfo addEntriesFromDictionary:dictionary];
    return [NSError errorWithDomain:error.domain code:error.code userInfo:dictionary];
}

@end

@implementation NSError(HttpStatusCode)

- (NSInteger)httpStatusCode
{
    return [self.userInfo[@"TRCHttpStatusCode"] integerValue];
}


@end