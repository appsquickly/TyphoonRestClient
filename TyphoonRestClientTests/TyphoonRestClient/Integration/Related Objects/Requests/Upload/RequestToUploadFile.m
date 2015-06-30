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

#import "RequestToUploadFile.h"

@implementation RequestToUploadFile

- (NSString *)path
{
    return @"uploads.json";
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodPost;
}

- (id)requestBody
{
    return [NSInputStream inputStreamWithFileAtPath:self.uploadPath];
}

- (NSDictionary *)requestHeaders
{
    return @{
        @"Content-Type": @"application/octet-stream"
    };
}

- (id)responseProcessedFromBody:(NSDictionary *)bodyObject headers:(NSDictionary *)responseHeaders status:(TRCHttpStatusCode)statusCode error:(NSError **)parseError
{
    return bodyObject[@"upload"][@"token"];
}

@end
