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

#import "TRCSerializerData.h"
#import "TRCRequest.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationData = @"TRCSerializationData";

@implementation TRCSerializerData

- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error
{
    if (![requestObject isKindOfClass:[NSData class]]) {
        if (error) {
            *error = TRCRequestSerializationErrorWithFormat(@"Can't use '%@' object in TRCSerializerData. Must be NSData", requestObject);
        }
        return nil;
    } else {
        return requestObject;
    }
}

- (NSString *)contentType
{
    return @"application/octet-stream";
}

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
    return data;
}

@end