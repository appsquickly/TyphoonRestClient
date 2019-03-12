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
#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#else 
    #import <Cocoa/Cocoa.h>
#endif

TRCSerialization TRCSerializationResponseImage = @"TRCSerializationResponseImage";

@implementation TRCSerializerImage

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
#if TARGET_OS_IPHONE
    return [UIImage imageWithData:data];
#else
    return [[NSImage alloc] initWithData:data];
#endif
}

- (BOOL)isCorrectContentType:(NSString *)responseContentType
{
    return [responseContentType hasPrefix:@"image"];
}

@end
