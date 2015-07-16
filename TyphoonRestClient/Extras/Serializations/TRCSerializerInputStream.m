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

#import "TRCSerializerInputStream.h"
#import "TRCRequest.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationRequestInputStream = @"TRCSerializationRequestInputStream";

@implementation TRCSerializerInputStream

- (NSInputStream *)bodyStreamFromObject:(id)requestObject forRequest:(NSMutableURLRequest *)urlRequest error:(NSError **)error
{
    if ([requestObject isKindOfClass:[NSInputStream class]]) {
        return requestObject;
    } else if ([requestObject isKindOfClass:[NSString class]]) {
        return [[NSInputStream alloc] initWithFileAtPath:requestObject];
    } else if (error) {
        *error = TRCRequestSerializationErrorWithFormat(@"Can't use '%@' object in TRCSerializerInputStream. Must be NSInputStream or NSString file path.", requestObject);
    }
    return nil;
}

@end