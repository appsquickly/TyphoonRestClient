//
// Created by Aleksey Garbarev on 20.09.14.
// Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <objc/runtime.h>
#import "TRCConnectionStub.h"

@interface HttpWebServiceConnectionStubResponse : NSObject
@property (nonatomic, strong) id response;
@property (nonatomic, strong) NSError *error;
@end

@implementation HttpWebServiceConnectionStubResponse
@end

@implementation TRCConnectionStub
{
    NSError *responseError;
    id responseObject;
    NSMutableDictionary *responses;


    BOOL (^responseBlock)(NSURLRequest *, id *, NSError **);
}

- (id)init
{
    self = [super init];
    if (self) {
        responses = [NSMutableDictionary new];
    }
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(TRCRequestMethod)httpMethod path:(NSString *)path pathParams:(NSDictionary *)pathParams body:(id)bodyObject serialization:(TRCRequestSerialization)serialization headers:(NSDictionary *)headers error:(NSError **)requestComposingError
{
    if (path.length > 0) {
        return [super requestWithMethod:httpMethod path:path pathParams:pathParams body:bodyObject serialization:serialization headers:headers error:requestComposingError];
    } else {
        return [NSMutableURLRequest new];
    }
}

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request responseSerialization:(TRCResponseSerialization)serialization completion:(void (^)(id arrayOrDictionary, NSError *error, id<TRCResponseInfo> responseInfo))completion
{
    __block id response = responseObject;
    __block NSError *error = responseError;

    if (responseBlock) {
        if (responseBlock(request, &response, &error)) {
            if (completion) {
                completion(response, error, nil);
            }
            return nil;
        }
    }

    [responses enumerateKeysAndObjectsUsingBlock:^(NSString *key, HttpWebServiceConnectionStubResponse *obj, BOOL *stop) {
        if ([[[request URL] absoluteString] hasSuffix:key]) {
            response = obj.response;
            error = obj.error;
        }
    }];

    if (completion) {
        completion(response, error, nil);
    }
    return nil;
}

+ (id)newWithResponse:(id)responseObject1 error:(NSError *)error
{
    TRCConnectionStub *stub = [TRCConnectionStub new];
    [stub setResponseObject:responseObject1 responseError:error];
    return stub;
}

- (void)setResponseObject:(id)_responseObject responseError:(NSError *)_error
{
    responseObject = _responseObject;
    responseError = _error;
}

- (void)setResponse:(id)responseObject1 error:(NSError *)error forUrl:(NSString *)urlSuffix
{
    HttpWebServiceConnectionStubResponse *response = [HttpWebServiceConnectionStubResponse new];
    response.response = responseObject1;
    response.error = error;
    responses[urlSuffix] = response;
}

- (void)setResponseBlock:(BOOL (^)(NSURLRequest *request, id *response, NSError **error))_responseBlock
{
    responseBlock = _responseBlock;
}


@end