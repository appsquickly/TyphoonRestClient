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

#import "RequestToGetIssue.h"

@implementation RequestToGetIssue {
    NSNumber *_issueId;
}

- (instancetype)initWithIssueId:(NSNumber *)issueId
{
    self = [super init];
    if (self) {
        _issueId = issueId;
    }
    return self;
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodGet;
}

- (NSString *)path
{
    return @"issues/{issue_id}.json";
}

- (NSDictionary *)pathParameters
{
    NSParameterAssert(_issueId);
    return @{ @"issue_id" : _issueId };
}

- (id)responseProcessedFromBody:(NSDictionary *)bodyObject headers:(NSDictionary *)responseHeaders status:(TRCHttpStatusCode)statusCode error:(NSError **)parseError
{
    return bodyObject[@"issue"];
}

@end
