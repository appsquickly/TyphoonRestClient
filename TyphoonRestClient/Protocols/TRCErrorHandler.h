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
* with error status code (For example 4xx or 5xx codes)
* */
@protocol TRCErrorHandler<NSObject>

/**
* This method returns custom NSError composed from response body. Body represented by 'bodyObject'
* argument.
*
* 'bodyObject' can be:
* - NSArray or NSDictionary, in cases when 'responseSerialization' is Json, Xml or Plist
* - UIImage when 'responseSerialization' is TRCSerializationData
* - NSString when 'responseSerialization' is TRCSerializationString
* - nil when 'responseBodyOutputStream' specified in TRCRequest
* */
- (NSError *)errorFromResponseBody:(id)bodyObject headers:(NSDictionary *)headers status:(TRCHttpStatusCode)statusCode error:(NSError **)error;

@optional

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

/**
* If you expect NSArray or NSDictionary representable 'bodyObject' for error composing, you can specify
* validation scheme, to be sure that all needed for parsing keys specified and has correct type.
* If this method not implement then ClassName.response name assumed
* */
- (NSString *)errorValidationSchemaName;

@end