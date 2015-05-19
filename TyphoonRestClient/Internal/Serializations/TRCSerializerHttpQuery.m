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
    if (![requestObject isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = TRCRequestSerializationErrorWithFormat(@"Can't use '%@' object in TRCSerializerHttpQuery. Must be NSDictionary.", requestObject);
        }
        return nil;
    } else {
        return [TRCQueryStringFromParametersWithEncoding(requestObject, NSUTF8StringEncoding) dataUsingEncoding:NSUTF8StringEncoding];
    }
}

- (NSString *)contentType
{
    return @"application/x-www-form-urlencoded";
}

@end