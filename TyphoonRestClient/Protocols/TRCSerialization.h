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

@class TRCSchema;
@protocol TRCSchemaData;
@protocol TRCSchemaDataProvider;

@protocol TRCRequestSerializer <NSObject>

@optional

- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error;

- (NSInputStream *)dataStreamFromRequestObject:(id)requestObject error:(NSError **)error;

- (NSString *)contentType;

@end

@protocol TRCResponseSerializer <NSObject>

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error;

@optional

- (BOOL)isCorrectContentType:(NSString *)responseContentType;

@end


@protocol TRCSchemaFormat <NSObject>

- (id<TRCSchemaData>)requestSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error;

- (id<TRCSchemaData>)responseSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error;

@end
