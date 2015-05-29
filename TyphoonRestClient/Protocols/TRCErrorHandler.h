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
#import "TRCRequest.h"

/**
* TRCErrorHandler used to compose custom NSError from response body when request finished
* with error status code (For example 4xx or 5xx codes), or when response body contains error.
* */
 @protocol TRCErrorHandler<NSObject>

/**
* This method returns custom NSError composed from response body. Body represented by 'bodyObject'
* argument.
*
* `bodyObject` comes through serialization, validation, conversions (using `TRCObjectMapper` and `TRCValueTransformer`)
* before appears here.
*
* See more information about `bodyObject` in `TRCRequest.responseProcessedFromBody:headers:status:error:`.
*
* You also may want to specify schema for validation. Check `TRCErrorHandler.errorValidationSchemaName` method.
* If schema specified, then `bodyObject` validation failed, this method will not be called, and general error returns at
* top-level call
*
* @see `TRCRequest.responseProcessedFromBody:headers:status:error:`
* @see `TyphoonRestClient.errorHandler`
* */
- (NSError *)errorFromResponseBody:(id)bodyObject headers:(NSDictionary *)headers status:(TRCHttpStatusCode)statusCode error:(NSError **)error;

@optional

/**
* Specify schema name to validate `bodyObject` before processing.
* If this method not implemented then ClassName.response.{format} name assumed
* */
- (NSString *)errorValidationSchemaName;

/**
* Implement your body checking for error. This is required when your API uses some status codes inside response body, instead of
* HTTP status codes.
*
* Note that `bodyObject` is raw object, which goes directly from `TRCConnection`. Without applying any schema.
*
* The goal of this method is just say that body looks like error or not.
*
* Examples:
* If each response contains `status` field, then you'll check for that code in that method
* {
*    "status": 200
* }
* or if each response contains `success` boolean field, you can check it here
* {
*   "success": true
* }
*
* */
- (BOOL)isErrorResponseBody:(id)bodyObject headers:(NSDictionary *)headers status:(TRCHttpStatusCode)statusCode;

@end
