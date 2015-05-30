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

/**
* `TRCObjectMapper` creates model objects from response data and creates response data from model objects.
*
* It's called `mapper` because response data already converted using child `TRCObjectMappers` and `TRCValueTransfers`,
* so you'll just map data into your model object here, without any conversion and checking.
*
* Use `TRCObjectMapper` to reuse mapping code you may have in `TRCRequest.responseProcessedFromBody:headers:status:error:`,
* then each your model object will have own `TRCObjectMapper`.
*
* Each `TRCObjectMapper` can have schemes just like `TRCRequest`, to validate and post-process request and response objects.
*
* */
@protocol TRCObjectMapper<NSObject>

@optional

//-------------------------------------------------------------------------------------------
#pragma mark - Parsing from Request
//-------------------------------------------------------------------------------------------

/**
* Specify name of schema file here, to validate response object.
*
* if this method isn't implemented, ClassName.response.{format} or ClassName.{format} will be used
* */
- (NSString *)responseValidationSchemaName;


/**
* Creates model object and map values from `responseObject` into that object.
*
* If your `TRCObjectMapper` has scheme for response object, then `responseObject` already validated and
* post-processed by child mappers and `TRCValueTransformers`.
*
* To see more information kind of `responseObject`, see `TRCRequest.responseProcessedFromBody:headers:status:error:`
*
* You are free to return `nil` in that method. That object would be skipped. You also can write into
* `error` pointer in case of error. Then request will be finished with that error
*
* @return your custom model object or `nil`
*
* @see
* `TRCRequest.responseProcessedFromBody:headers:status:error:`
* */
- (id)objectFromResponseObject:(id)responseObject error:(NSError **)error;

//-------------------------------------------------------------------------------------------
#pragma mark - Composing for Request
//-------------------------------------------------------------------------------------------

/**
* Specify name of schema file here, to validate request object.
*
* if this method isn't implemented, ClassName.request.{format} or ClassName.{format} will be used
* */
- (NSString *)requestValidationSchemaName;

/**
* Creates request object, acceptable by request serialization, using `object`.
*
* Returned object would be transformed using child `TRCObjectMappers` and `TRCValueTransformer`s if specified in schema,
* and then validated
*
* See `TRCRequest.requestBody` for details, because same rules applies to returned object.
*
* @return
* request object, which can be used by request serialization. For example JSON request serialization requires NSArray or NSDictionary
* */
- (id)requestObjectFromObject:(id)object error:(NSError **)error;

@end
