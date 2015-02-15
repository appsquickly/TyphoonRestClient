//
// Created by Aleksey Garbarev on 20.09.14.
// Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HWSRequest.h"


@interface HttpRequestSpy : NSObject <HWSRequest>

@property (nonatomic) BOOL parseResponseObjectCalled;

@property (nonatomic) BOOL shouldFailConversion;

@property (nonatomic, strong) NSDictionary *requestParams;
@property (nonatomic, strong) NSString *requestSchemeName;

@property (nonatomic, strong) NSString *responseSchemeName;

@property (nonatomic, strong) id parseResult;
@property (nonatomic, strong) NSError *parseError;


@property (nonatomic) BOOL parseObjectImplemented;

@end