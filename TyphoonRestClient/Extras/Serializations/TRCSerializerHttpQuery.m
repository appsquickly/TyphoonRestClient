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

#import "TRCSerializerHttpQuery.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationRequestHttp = @"TRCSerializationRequestHttp";

@implementation TRCSerializerHttpQuery

- (NSData *)bodyDataFromObject:(id)requestObject forRequest:(NSMutableURLRequest *)urlRequest error:(NSError **)error
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