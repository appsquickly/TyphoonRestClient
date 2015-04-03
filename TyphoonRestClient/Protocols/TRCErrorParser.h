////////////////////////////////////////////////////////////////////////////////
//
//  AppsQuick.ly
//  Copyright 2015 AppsQuick.ly
//  All Rights Reserved.
//
//  NOTICE: This software is the proprietary information of AppsQuick.ly
//  Use is subject to license terms.
//
////////////////////////////////////////////////////////////////////////////////




#import <Foundation/Foundation.h>
#import "TRCRequest.h"

/**
* TRCErrorParser used to compose custom NSError from response body when request finished
* with error status code (For example 4xx or 5xx codes)
* */
@protocol TRCErrorParser<NSObject>

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
* If you expect NSArray or NSDictionary representable 'bodyObject' for error composing, you can specify
* validation scheme, to be sure that all needed for parsing keys specified and has correct type.
* If this method not implement then ClassName.response name assumed
* */
- (NSString *)errorValidationSchemaName;

@end