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

#import "TRCSerializerHttpQuery.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationRequestHttp = @"TRCSerializationRequestHttp";

@implementation TRCSerializerHttpQuery

- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error
{
    return [TRCQueryStringFromParametersWithEncoding(requestObject, NSUTF8StringEncoding) dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)contentType
{
    return @"application/x-www-form-urlencoded";
}

@end