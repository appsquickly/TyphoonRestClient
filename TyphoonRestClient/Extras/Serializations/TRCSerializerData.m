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

#import "TRCSerializerData.h"
#import "TRCRequest.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationData = @"TRCSerializationData";

@implementation TRCSerializerData

- (NSData *)bodyDataFromObject:(id)requestObject forRequest:(NSMutableURLRequest *)urlRequest error:(NSError **)error
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