////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
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
