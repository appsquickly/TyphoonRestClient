//
//  HttpResponseErrorParserSpy.m
//  Iconic
//
//  Created by Aleksey Garbarev on 20.09.14.
//  Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import "HttpResponseErrorParserSpy.h"
#import "HWSConverter.h"
#import "HWSUtils.h"

@implementation HttpResponseErrorParserSpy

- (NSError *)errorFromResponseBody:(id)object headers:(NSDictionary *)headers status:(HttpStatusCode)statusCode error:(NSError **)error
{
    self.parseErrorCalled = YES;

    if (self.parsedError) {
        return self.parsedError;
    } else if (self.errorParsingError) {
        *error = self.errorParsingError;
        return nil;
    } else {
        NSURL *url = object[@"reason_url"];
        NSMutableDictionary *userInfo = [NSMutableDictionary new];
        userInfo[NSLocalizedDescriptionKey] = object[@"message"];
        if (url) {
            userInfo[@"url"] = url;
        }
        return [NSError errorWithDomain:@"" code:0 userInfo:userInfo];
    }
}

- (NSString *)errorValidationSchemaName
{
    return self.schemaName;
}

@end
