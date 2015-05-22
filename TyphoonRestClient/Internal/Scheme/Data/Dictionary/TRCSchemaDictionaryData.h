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


@interface TRCSchemaDictionaryData : NSObject <TRCSchemaData>

@property (nonatomic, getter=isRequestData, readonly) BOOL requestData;

@property (nonatomic, weak, readonly) id<TRCSchemaDataProvider> dataProvider;

- (instancetype)initWithArrayOrDictionary:(id)arrayOrDictionary request:(BOOL)isRequest dataProvider:(id<TRCSchemaDataProvider>)dataProvider;

@end