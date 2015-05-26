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

- (NSString *)errorDescriptionForObject:(id)object errorMessage:(NSString *)errorMessage stackTrace:(NSArray *)stackTrace;

@end