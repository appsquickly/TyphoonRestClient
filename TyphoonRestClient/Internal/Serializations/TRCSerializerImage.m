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

#import "TRCSerializerImage.h"
#import "TRCRequest.h"
#import <UIKit/UIKit.h>

TRCSerialization TRCSerializationResponseImage = @"TRCSerializationResponseImage";

@implementation TRCSerializerImage

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
    return [UIImage imageWithData:data];
}

- (BOOL)isCorrectContentType:(NSString *)responseContentType
{
    return [responseContentType hasPrefix:@"image"];
}

@end