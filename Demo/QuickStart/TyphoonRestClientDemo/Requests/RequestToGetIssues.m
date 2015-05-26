////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON REST CLIENT
//  Copyright 2015, Typhoon Rest Client Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "RequestToGetIssues.h"

@implementation RequestToGetIssues

- (NSString *)path
{
    return @"issues.json";
}

- (NSDictionary *)pathParameters
{
    return @{
        @"project_id": ValueOrNull(self.projectId),
        @"offset": @(self.range.location),
        @"limit": self.range.length > 0 ? @(self.range.length) : @10
    };
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodGet;
}

- (id)responseProcessedFromBody:(NSDictionary *)bodyObject headers:(NSDictionary *)responseHeaders status:(TRCHttpStatusCode)statusCode error:(NSError **)parseError
{
    return bodyObject[@"issues"];
}

@end
