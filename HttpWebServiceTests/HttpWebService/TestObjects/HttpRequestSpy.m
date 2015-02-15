//
// Created by Aleksey Garbarev on 20.09.14.
// Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import "HttpRequestSpy.h"
#import "NSObject+AutoDescription.h"
#import "HWSConverter.h"
#import "HWSUtils.h"

@implementation HttpRequestSpy

- (id)init
{
    self = [super init];
    if (self) {
        self.parseObjectImplemented = YES;
    }
    return self;
}


- (HttpRequestMethod)method
{
    return HttpRequestMethodPost;
}

- (NSString *)path
{
    return nil;
}

- (HttpRequestSerialization)requestSerialization
{
    return HttpRequestSerializationJson;
}

- (id)requestBody
{
    return self.requestParams;
}

- (HttpResponseSerialization)responseSerialization
{
    return HttpResponseSerializationImage;
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


- (id)responseProcessedFromBody:(id)responseObject headers:(NSDictionary *)headers status:(HttpStatusCode)status error:(NSError **)parseError
{
    self.parseResponseObjectCalled = YES;

    if (parseError && self.parseError) {
        *parseError = self.parseError;
    }

    if (self.shouldFailConversion) {
        [(NSMutableOrderedSet *)[(HWSConverter *)responseObject conversionErrorSet] addObject:NSErrorWithFormat(@"Unkown")];
    }

    return self.parseResult;
}

AUTO_DESCRIPTION

@end