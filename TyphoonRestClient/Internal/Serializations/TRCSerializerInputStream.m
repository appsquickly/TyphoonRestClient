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

#import "TRCSerializerInputStream.h"
#import "TRCRequest.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationRequestInputStream = @"TRCSerializationRequestInputStream";

@implementation TRCSerializerInputStream

- (NSInputStream *)dataStreamFromRequestObject:(id)requestObject error:(NSError **)error
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