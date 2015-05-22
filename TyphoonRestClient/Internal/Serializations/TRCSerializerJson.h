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
#import "TRCInfrastructure.h"


@interface TRCSerializerJson : NSObject <TRCRequestSerializer, TRCResponseSerializer, TRCSchemaFormat, TRCValidationErrorPrinter>

@property (nonatomic, assign) NSJSONReadingOptions readingOptions;
@property (nonatomic, assign) NSJSONWritingOptions writingOptions;

@end