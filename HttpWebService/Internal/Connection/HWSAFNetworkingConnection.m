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



#import "HWSAFNetworkingConnection.h"
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import "AFHTTPRequestOperationManager.h"
#import "HWSUtils.h"


NSError *NSErrorWithDictionaryUnion(NSError *error, NSDictionary *dictionary);
NSString *NSStringFromHttpRequestMethod(HttpRequestMethod method);
Class ClassFromHttpRequestSerialization(HttpRequestSerialization serialization);
Class ClassFromHttpResponseSerialization(HttpResponseSerialization serialization);
BOOL IsBodyAllowedInHttpMethod(HttpRequestMethod method);

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

@interface AFNetworkingHttpWebServiceConnectionProgressHandler : NSObject <HWSProgressHandler>

@property (nonatomic, weak) AFHTTPRequestOperation *operation;

@property (atomic, strong) HWSUploadProgressBlock uploadProgressBlock;
@property (atomic, strong) HWSDownloadProgressBlock downloadProgressBlock;

@end

@implementation AFNetworkingHttpWebServiceConnectionProgressHandler
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

@interface AFNetworkingHttpWebServiceConnectionResponseInfo : NSObject <HWSResponseInfo>
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSData *responseData;
+ (instancetype)infoWithOperation:(AFHTTPRequestOperation *)operation;
@end
@implementation AFNetworkingHttpWebServiceConnectionResponseInfo
+ (instancetype)infoWithOperation:(AFHTTPRequestOperation *)operation
{
    AFNetworkingHttpWebServiceConnectionResponseInfo *object = [AFNetworkingHttpWebServiceConnectionResponseInfo new];
    object.response = operation.response;
    object.responseData = operation.responseData;
    return object;
}
@end

//=============================================================================================================================

@implementation HWSAFNetworkingConnection
{
    NSCache *requestSerializersCache;
    NSCache *responseSerializersCache;

    AFHTTPRequestOperationManager *operationManager;
    NSRegularExpression *catchUrlArgumentsRegexp;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl
{
    self = [super init];
    if (self) {
        _baseUrl = baseUrl;
        operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseUrl];
        responseSerializersCache = [NSCache new];
        requestSerializersCache = [NSCache new];
        catchUrlArgumentsRegexp = [[NSRegularExpression alloc] initWithPattern:@"\\{.*?\\}" options:0 error:nil];
    }
    return self;
}

#pragma mark - HttpWebServiceConnection protocol

- (NSMutableURLRequest *)requestWithMethod:(HttpRequestMethod)httpMethod path:(NSString *)path pathParams:(NSDictionary *)pathParams body:(id)bodyObject serialization:(HttpRequestSerialization)serialization headers:(NSDictionary *)headers error:(NSError **)requestComposingError
{
    NSError *urlComposingError = nil;
    NSURL *url = [self urlFromPath:path parameters:pathParams error:&urlComposingError];

    if (urlComposingError && requestComposingError) {
        *requestComposingError = urlComposingError;
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

- (id<HWSProgressHandler>)sendRequest:(NSURLRequest *)request responseSerialization:(HttpResponseSerialization)serialization outputStream:(NSOutputStream *)outputStream completion:(HWSConnectionCompletion)completion
{
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    requestOperation.responseSerializer = [self responseSerializerForType:serialization];

    requestOperation.outputStream = outputStream;

    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion) {
            completion(operation.responseObject, nil, [AFNetworkingHttpWebServiceConnectionResponseInfo infoWithOperation:operation]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error) {
            NSInteger httpCode = operation.response.statusCode;
            error = NSErrorWithDictionaryUnion(error, @{@"HttpStatusCode": @(httpCode)});
        }
        if (completion) {
            completion(operation.responseObject, error, [AFNetworkingHttpWebServiceConnectionResponseInfo infoWithOperation:operation]);
        }
    }];

    AFNetworkingHttpWebServiceConnectionProgressHandler *progressHandler = [AFNetworkingHttpWebServiceConnectionProgressHandler new];
    progressHandler.operation = requestOperation;

    [operationManager.operationQueue addOperation:requestOperation];

    return progressHandler;
}

#pragma mark - URL composing

- (NSURL *)urlFromPath:(NSString *)path parameters:(NSDictionary *)parameters error:(NSError **)error
{
    NSURL *result = nil;

    NSArray *arguments = [catchUrlArgumentsRegexp matchesInString:path options:0 range:NSMakeRange(0, [path length])];

    NSMutableDictionary *mutableParams = [parameters mutableCopy];

    // Applying arguments
    if ([arguments count] > 0) {
        if ([mutableParams count] == 0) {
            if (error) {
                *error = NSErrorWithFormat(@"Can't process path '%@', since it has arguments (%@) but no parameters specified ", path, [arguments componentsJoinedByString:@", "]);
            }
            return nil;
        }
        NSMutableString *mutablePath = [path mutableCopy];

        for (NSTextCheckingResult *argumentMatch in arguments) {
            NSString *argument = [path substringWithRange:argumentMatch.range];
            NSString *argumentKey = [argument substringWithRange:NSMakeRange(1, argument.length-2)];
            id value = mutableParams[argumentKey];
            if (![self isValidPathArgumentValue:value]) {
                if (error) {
                    *error = NSErrorWithFormat(@"Can't process path '%@', since value for argument %@ missing or invalid (must be NSNumber or non-empty NSString)", path, argument);
                }
                return nil;
            }
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [value description];
            }
            [mutablePath replaceOccurrencesOfString:argument withString:value options:0 range:NSMakeRange(0, [mutablePath length])];
            [mutableParams removeObjectForKey:argumentKey];
        }
        path = mutablePath;
    }

    if ([mutableParams count] > 0) {
        //Applying variables
        id<AFURLRequestSerialization> serializer = [self requestSerializerForType:HttpRequestSerializationHttp];

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

- (BOOL)isValidPathArgumentValue:(id)value
{
    return [value isKindOfClass:[NSNumber class]] || ([value isKindOfClass:[NSString class]] && [value length] > 0);
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

- (id<AFURLRequestSerialization>)requestSerializerForType:(HttpRequestSerialization)serialization
{
    Class serializerClass = ClassFromHttpRequestSerialization(serialization);
    NSString *key = NSStringFromClass(serializerClass);
    id<AFURLRequestSerialization> cached = [requestSerializersCache objectForKey:key];
    if (!cached) {
        cached = (id<AFURLRequestSerialization>)[serializerClass new];
        [requestSerializersCache setObject:cached forKey:key];
    }
    return cached;
}

- (id<AFURLResponseSerialization>)responseSerializerForType:(HttpResponseSerialization)serialization
{
    Class serializerClass = ClassFromHttpResponseSerialization(serialization);
    NSString *key = NSStringFromClass(serializerClass);
    id<AFURLResponseSerialization> cached = [responseSerializersCache objectForKey:key];
    if (!cached) {
        cached = (id<AFURLResponseSerialization>)[serializerClass new];
        [responseSerializersCache setObject:cached forKey:key];
    }
    return cached;
}

NSString *NSStringFromHttpRequestMethod(HttpRequestMethod method)
{
    switch (method) {
        case HttpRequestMethodDelete: return @"DELETE";
        case HttpRequestMethodGet: return @"GET";
        case HttpRequestMethodHead: return @"HEAD";
        case HttpRequestMethodPatch: return @"PATCH";
        case HttpRequestMethodPost: return @"POST";
        case HttpRequestMethodPut: return @"PUT";
    }
    NSCAssert(NO, @"Unknown HttpRequestMethod: %d", (int)method);
    return @"";
}

BOOL IsBodyAllowedInHttpMethod(HttpRequestMethod method)
{
    return method == HttpRequestMethodPost || method == HttpRequestMethodPut || method == HttpRequestMethodPatch;
}

Class ClassFromHttpRequestSerialization(HttpRequestSerialization serialization)
{
    switch (serialization) {
        case HttpRequestSerializationJson: return [AFJSONRequestSerializer class];
        case HttpRequestSerializationHttp: return [AFHTTPRequestSerializer class];
        case HttpRequestSerializationPlist: return [AFPropertyListRequestSerializer class];
    }
    NSCAssert(NO, @"Unknown HttpRequestSerialization: %d", (int)serialization);
    return nil;
}

Class ClassFromHttpResponseSerialization(HttpResponseSerialization serialization)
{
    switch (serialization) {
        case HttpResponseSerializationJson: return [AFJSONResponseSerializer class];
        case HttpResponseSerializationData: return [AFHTTPResponseSerializer class];
        case HttpResponseSerializationImage: return [AFImageResponseSerializer class];
        case HttpResponseSerializationPlist: return [AFPropertyListResponseSerializer class];
        case HttpResponseSerializationXml: return [AFXMLParserResponseSerializer class];
        case HttpResponseSerializationString: return [AFStringResponseSerializer class];
    }
    NSCAssert(NO, @"Unknown HttpResponseSerialization: %d", (int)serialization);
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
    return [self.userInfo[@"HttpStatusCode"] integerValue];
}


@end