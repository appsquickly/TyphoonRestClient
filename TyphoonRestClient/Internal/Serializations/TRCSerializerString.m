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

#import "TRCSerializerString.h"
#import "TRCRequest.h"

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
    return [requestObject dataUsingEncoding:self.encoding];
}

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
    return [[NSString alloc] initWithData:data encoding:self.encoding];
}

@end