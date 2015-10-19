//
// Created by Aleksey Garbarev on 20.09.14.
// Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <objc/runtime.h>
#import "TRCConnectionTestStub.h"

@interface HttpWebServiceConnectionStubResponse : NSObject
@property (nonatomic, strong) id response;
@property (nonatomic, strong) NSError *error;
@end

@implementation HttpWebServiceConnectionStubResponse
@end

@implementation TRCConnectionTestStub
{
    NSError *responseError;
    id responseObject;
    NSMutableDictionary *responses;


    BOOL (^responseBlock)(NSURLRequest *, id *, NSError **);

    id<TRCConnection> _requestMakingConnection;
}

- (id)init
{
    self = [super init];
    if (self) {
        _requestMakingConnection = [[TRCConnectionNSURLSession alloc] initWithBaseUrl:[NSURL URLWithString:@"http://connection.stub"]];
        responses = [NSMutableDictionary new];
    }
    return self;
}

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError
{
    if (options.path.length > 0) {
        return [_requestMakingConnection requestWithOptions:options error:requestComposingError];
    } else {
        return [NSMutableURLRequest new];
    }
}


- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion
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
    TRCConnectionTestStub *stub = [TRCConnectionTestStub new];
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