//
// Created by Aleksey Garbarev on 20.09.14.
// Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import "TRCRequestSpy.h"
#import "NSObject+AutoDescription.h"
#import "TRCConverter.h"
#import "TRCUtils.h"

@implementation TRCRequestSpy

- (id)init
{
    self = [super init];
    if (self) {
        self.parseObjectImplemented = YES;
    }
    return self;
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodPost;
}

- (NSString *)path
{
    return nil;
}

- (TRCRequestSerialization)requestSerialization
{
    return TRCRequestSerializationJson;
}

- (id)requestBody
{
    return self.requestParams;
}

- (TRCResponseSerialization)responseSerialization
{
    return TRCResponseSerializationImage;
}


- (NSString *)responseBodyValidationSchemaName
{
    return self.responseSchemeName;
}

- (NSString *)requestBodyValidationSchemaName
{
    return self.requestSchemeName;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(responseProcessedFromBody:headers:status:error:)) {
        return self.parseObjectImplemented;
    }
    return [super respondsToSelector:aSelector];
}


- (id)responseProcessedFromBody:(id)responseObject headers:(NSDictionary *)headers status:(TRCHttpStatusCode)status error:(NSError **)parseError
{
    self.parseResponseObjectCalled = YES;

    if (parseError && self.parseError) {
        *parseError = self.parseError;
    }

    if (self.shouldFailConversion) {
        [(NSMutableOrderedSet *)[(TRCConverter *)responseObject conversionErrorSet] addObject:NSErrorWithFormat(@"Unkown")];
    }

    return self.parseResult;
}

AUTO_DESCRIPTION

@end