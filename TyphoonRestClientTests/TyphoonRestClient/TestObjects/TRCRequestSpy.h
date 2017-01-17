//
// Created by Aleksey Garbarev on 20.09.14.
// Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRCRequest.h"


@interface TRCRequestSpy : NSObject <TRCRequest>

@property (nonatomic) BOOL parseResponseObjectCalled;

@property (nonatomic) BOOL shouldFailConversion;

@property (nonatomic, strong) id requestBody;
@property (nonatomic, strong) NSString *requestSchemeName;

@property (nonatomic, strong) NSString *responseSchemeName;

@property (nonatomic, strong) id parseResult;
@property (nonatomic, strong) NSError *parseError;

@property (nonatomic) BOOL parseObjectImplemented;

@property (nonatomic, copy) void(^insideParseBlock)();

@end