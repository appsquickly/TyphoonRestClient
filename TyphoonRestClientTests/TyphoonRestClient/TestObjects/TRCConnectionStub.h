//
// Created by Aleksey Garbarev on 20.09.14.
// Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRCConnection.h"
#import "TRCConnectionAFNetworking.h"


@interface TRCConnectionStub : TRCConnectionAFNetworking<TRCConnection>

+ (id)newWithResponse:(id)responseObject error:(NSError *)error;

- (void)setResponseObject:(id)_responseObject responseError:(NSError *)error;

- (void)setResponse:(id)responseObject error:(NSError *)error forUrl:(NSString *)urlSuffix;

- (void)setResponseBlock:(BOOL (^)(NSURLRequest *request, id *response, NSError **error))responseBlock;

@end