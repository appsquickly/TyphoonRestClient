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
#import "TRCSerialization.h"
#import "TRCUtils.h"

TRCRequestSerialization TRCRequestSerializationJson = @"TRCRequestSerializationJson";
TRCRequestSerialization TRCRequestSerializationHttp = @"TRCRequestSerializationHttp";
TRCRequestSerialization TRCRequestSerializationPlist = @"TRCRequestSerializationPlist";

TRCResponseSerialization TRCResponseSerializationJson = @"TRCResponseSerializationJson";
TRCResponseSerialization TRCResponseSerializationXml = @"TRCResponseSerializationXml";
TRCResponseSerialization TRCResponseSerializationPlist = @"TRCResponseSerializationPlist";
TRCResponseSerialization TRCResponseSerializationData = @"TRCResponseSerializationData";
TRCResponseSerialization TRCResponseSerializationString = @"TRCResponseSerializationString";
TRCResponseSerialization TRCResponseSerializationImage = @"TRCResponseSerializationImage";

TRCRequestMethod TRCRequestMethodPost = @"POST";
TRCRequestMethod TRCRequestMethodGet = @"GET";
TRCRequestMethod TRCRequestMethodPut = @"PUT";
TRCRequestMethod TRCRequestMethodDelete = @"DELETE";
TRCRequestMethod TRCRequestMethodPatch = @"PATCH";
TRCRequestMethod TRCRequestMethodHead = @"HEAD";

NSError *NSErrorWithDictionaryUnion(NSError *error, NSDictionary *dictionary);
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


@interface AFTRCResponseSerializer : AFHTTPResponseSerializer
@property (nonatomic, strong) id<TRCResponseSerializer> serializer;
@end

@implementation AFTRCResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (![self.serializer isCorrectContentType:[response MIMEType]]) {
        if (error) {
            *error = NSErrorWithFormat(@"Request failed: unacceptable content-type: %@", [response MIMEType]);
        }
        return nil;
    } else {
        return [self.serializer objectFromResponseData:data error:error];
    }
}

@end

@interface AFTRCRequestSerializer : AFHTTPRequestSerializer
@property (nonatomic, strong) id<TRCRequestSerializer> serializer;
@end

@implementation AFTRCRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];

    if (parameters) {
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:[self.serializer contentType] forHTTPHeaderField:@"Content-Type"];
        }

        NSData *data = [self.serializer dataFromRequestObject:parameters error:error];
        if (data) {
            [mutableRequest setHTTPBody:data];
        }
    }

    return mutableRequest;
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
    AFHTTPRequestOperationManager *_operationManager;
    NSCache *_serializersCache;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl
{
    self = [super init];
    if (self) {
        _baseUrl = baseUrl;
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseUrl];
        _serializersCache = [NSCache new];
    }
    return self;
}

+ (void)initialize
{
    [self registerDefaultSerializers];
}

+ (void)registerDefaultSerializers
{
    /** Request */
    [self registerRequestSerializer:[AFJSONRequestSerializer new] forType:TRCRequestSerializationJson];
    [self registerRequestSerializer:[AFHTTPRequestSerializer new] forType:TRCRequestSerializationHttp];
    [self registerRequestSerializer:[AFPropertyListRequestSerializer new] forType:TRCRequestSerializationPlist];

    /** Response */
    [self registerResponseSerializer:[AFJSONResponseSerializer new] forType:TRCResponseSerializationJson];
    [self registerResponseSerializer:[AFHTTPResponseSerializer new] forType:TRCResponseSerializationData];
    [self registerResponseSerializer:[AFImageResponseSerializer new] forType:TRCResponseSerializationImage];
    [self registerResponseSerializer:[AFPropertyListResponseSerializer new] forType:TRCResponseSerializationPlist];
    [self registerResponseSerializer:[AFXMLParserResponseSerializer new] forType:TRCResponseSerializationXml];
    [self registerResponseSerializer:[AFStringResponseSerializer new] forType:TRCResponseSerializationString];
}

- (AFNetworkReachabilityManager *)reachabilityManager
{
    return _operationManager.reachabilityManager;
}

- (void)startReachabilityMonitoring
{
    [self.reachabilityManager startMonitoring];
}

- (void)stopReachabilityMonitoring
{
    [self.reachabilityManager stopMonitoring];
}

#pragma mark - HttpWebServiceConnection protocol

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError
{
    NSError *urlComposingError = nil;
    NSURL *url = [self urlFromPath:options.path parameters:options.pathParameters error:&urlComposingError];

    if (urlComposingError) {
        if(requestComposingError) {
            *requestComposingError = urlComposingError;
        }
        return nil;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = options.method;
    NSAssert([request.HTTPMethod length] > 0, @"Incorrect HTTP method ('%@') for request with options: %@", options.method, options);

    id bodyObject = options.body;

    if (!IsBodyAllowedInHttpMethod(options.method)) {
        bodyObject = nil;
    }

    if ([bodyObject isKindOfClass:[NSData class]]) {
        [request setHTTPBody:bodyObject];
    } else if ([bodyObject isKindOfClass:[NSString class]]) {
        [request setHTTPBody:[bodyObject dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([bodyObject isKindOfClass:[NSInputStream class]]) {
        [request setHTTPBodyStream:bodyObject];
    } else if ([bodyObject isKindOfClass:[NSArray class]] || [bodyObject isKindOfClass:[NSDictionary class]]) {
        id<AFURLRequestSerialization> serializer = [self requestSerializationForTRCSerializer:options.serialization];
        request = [[serializer requestBySerializingRequest:request withParameters:bodyObject error:requestComposingError] mutableCopy];
    }

    [options.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
            [request setValue:value forHTTPHeaderField:field];
        }
    }];

    return request;
}

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion
{
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    requestOperation.responseSerializer = [self responseSerializationForTRCSerializer:options.responseSerialization];

    requestOperation.outputStream = options.outputStream;

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

    requestOperation.queuePriority = options.queuePriority;

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
        static id<AFURLRequestSerialization> serializer;
        static NSMutableURLRequest *request;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            request = [[NSMutableURLRequest alloc] init];
            request.HTTPMethod = @"GET";
            serializer = [AFHTTPRequestSerializer new];
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

BOOL IsBodyAllowedInHttpMethod(TRCRequestMethod method)
{
    return method == TRCRequestMethodPost || method == TRCRequestMethodPut || method == TRCRequestMethodPatch;
}

NSError *NSErrorWithDictionaryUnion(NSError *error, NSDictionary *dictionary)
{
    NSMutableDictionary *userInfo = [[error userInfo] mutableCopy];
    [userInfo addEntriesFromDictionary:dictionary];
    return [NSError errorWithDomain:error.domain code:error.code userInfo:dictionary];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Serializers Cache
//-------------------------------------------------------------------------------------------


- (id<AFURLResponseSerialization>)responseSerializationForTRCSerializer:(id<TRCResponseSerializer>)serializer
{
    AFTRCResponseSerializer *result = [_serializersCache objectForKey:serializer];
    if (!result) {
        result = [AFTRCResponseSerializer new];
        result.serializer = serializer;
        [_serializersCache setObject:result forKey:serializer];
    }
    return result;
}

- (id<AFURLRequestSerialization>)requestSerializationForTRCSerializer:(id<TRCRequestSerializer>)serializer
{
    AFTRCRequestSerializer *result = [_serializersCache objectForKey:serializer];
    if (!result) {
        result = [AFTRCRequestSerializer new];
        result.serializer = serializer;
        [_serializersCache setObject:result forKey:serializer];
    }
    return result;
}

@end

@implementation NSError(HttpStatusCode)

- (NSInteger)httpStatusCode
{
    return [self.userInfo[@"TRCHttpStatusCode"] integerValue];
}

@end