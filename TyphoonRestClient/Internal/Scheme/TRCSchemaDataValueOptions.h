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

#import <Foundation/Foundation.h>

@interface TRCSchemaDataValueOptions : NSObject

/// Array index or dictionary key
@property (nonatomic, strong) id identifier;

/// Shows if value is optional or required
@property (nonatomic, getter=isOptional) BOOL optional;

@end