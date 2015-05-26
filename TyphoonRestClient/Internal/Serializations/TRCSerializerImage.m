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