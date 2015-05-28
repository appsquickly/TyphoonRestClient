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

/**
* Defines protocol for objects which converts `TRCRequest.requestBody` object into `NSData`
*
* You should implement one of these method:
* - `dataFromRequestObject:error:`
* - `dataStreamFromRequestObject:error:`
*
* If both implemented, then only `dataFromRequestObject:error` will be used.
* */
@protocol TRCRequestSerializer <NSObject>

@optional

/**
* Convert your `requestObject` into `NSData` here.
*
* @param requestObject object taken from `TRCRequest.requestBody`
* @param error write NSError into that pointer if error happens
* @return NSData which used as request body
* */
- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error;

/**
* Convert your `requestObject` into `NSInputStream` here.
*
* This method useful in next cases:
* - when your `requestObject` is `NSInputStream`
* - when your `requestObject` points to file to upload, or too large to be loaded into memory
*
* @param requestObject object taken from `TRCRequest.requestBody`
* @param error write NSError into that pointer if error happens
* @return NSInputStream which used to upload request body
* */
- (NSInputStream *)dataStreamFromRequestObject:(id)requestObject error:(NSError **)error;

/**
* This is string which would be used as Content-Type HTTP header value.
* If not implemented or returns nil, then Content-Type would not be specified.
* */
- (NSString *)contentType;

@end

/**
* Defines protocol for objects which converts `NSData` of response body into `responseObject`
*
* Main method is `objectFromResponseData:error:`, which does all work, plus another optional method `isCorrectContentType:`
* used to validate content-type
* */
@protocol TRCResponseSerializer <NSObject>

/**
* Converts `NSData` of response body into `responseObject` which would be used in parsing, validation or just as result
*
* @param data input `NSData`
* @param error write `NSError` into that pointer if error happens
* @return `responseObject` which would be used as result
* */
- (id)objectFromResponseData:(NSData *)data error:(NSError **)error;

@optional

/**
* Check that `NSData` content-type correct before processing here.
* If this method not implemented or returns `nil`, then validation avoided.
*
* @param responseContentType input content-type string
* @return YES if content-type correct otherwise NO. If content-type is not correct, error would be produces as result
* */
- (BOOL)isCorrectContentType:(NSString *)responseContentType;

@end

/**
* Describes schema format protocol.
*
* Currently only JSON and PLIST schema formats available.
* If you want to add your own schema format, you must implement `TRCSchemaFormat`, and register your implementation using
* `TyphoonRestClient.registerSchemeFormat:forFileExtension:`
* */
@protocol TRCSchemaFormat <NSObject>

/**
* Creates `TRCSchemaData` for **request** from schema file's `NSData`.
*
* @param data file's data
* @param dataProvider provides schemas by *mapperTag*. Used to treat `TRCSchemaData` with *sub-schemes* as single schema.
* @return abstract data structure, described by `TRCSchemaData` protocol
* */
- (id<TRCSchemaData>)requestSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error;

/**
* Creates `TRCSchemaData` for **response** from schema file's `NSData`.
*
* @param data file's data
* @param dataProvider provides schemas by *mapperTag*. Used to treat `TRCSchemaData` with *sub-schemes* as single schema.
* @return abstract data structure, described by `TRCSchemaData` protocol
* */
- (id<TRCSchemaData>)responseSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error;

@end

@protocol TRCValidationErrorPrinter

- (NSString *)errorDescriptionForObject:(id)object errorMessage:(NSString *)errorMessage stackTrace:(NSArray *)stackTrace;

@end