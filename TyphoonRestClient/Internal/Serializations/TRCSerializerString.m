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

#import "TRCSerializerString.h"
#import "TRCRequest.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationString = @"TRCSerializationString";

@implementation TRCSerializerString

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.encoding = NSUTF8StringEncoding;
    }
    return self;
}

- (NSData *)dataFromRequestObject:(NSString *)requestObject error:(NSError **)error
{
    if ([requestObject isKindOfClass:[NSString class]]) {
        return [requestObject dataUsingEncoding:self.encoding];
    } else {
        if (error) {
            *error = TRCRequestSerializationErrorWithFormat(@"Can't use '%@' object in TRCSerializerString. Must be NSString.", requestObject);
        }
        return nil;
    }
}

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
    return [[NSString alloc] initWithData:data encoding:self.encoding];
}

@end