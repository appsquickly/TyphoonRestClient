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
@class TRCSchemaStackTrace;

@protocol TRCRequestSerializer <NSObject>

@optional

/**
* Convert your requestObject into NSData here.
* */
- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error;

/**
* Convert your requestObject into NSInputStream here.
* */
- (NSInputStream *)dataStreamFromRequestObject:(id)requestObject error:(NSError **)error;

/**
* This is string which would be used as Content-Type HTTP header value.
* If not implemented or returns nil, then Content-Type would be not specified.
* */
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

@protocol TRCValidationErrorPrinter

- (NSString *)errorDescriptionWithErrorMessage:(NSString *)errorMessage stackTrace:(TRCSchemaStackTrace *)stackTrace;

- (NSString *)errorDescriptionWithErrorMessage:(NSString *)errorMessage schemaData:(id<TRCSchemaData>)data stackTrace:(TRCSchemaStackTrace *)stackTrace;

@end