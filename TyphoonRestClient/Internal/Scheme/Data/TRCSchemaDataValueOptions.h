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

#import <Foundation/Foundation.h>

@interface TRCSchemaDataValueOptions : NSObject

/// Array index or dictionary key
@property (nonatomic, strong) id identifier;

/// Shows if value is optional or required
@property (nonatomic, getter=isOptional) BOOL optional;

@end