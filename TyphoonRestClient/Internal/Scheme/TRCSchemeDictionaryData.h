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
#import "TRCSchemaData.h"


@interface TRCSchemeDictionaryData : NSObject <TRCSchemaData>

@property (nonatomic, weak) id<TRCSchemaDataProvider> dataProvider;

- (instancetype)initWithArrayOrDictionary:(id)arrayOrDictionary;

@end