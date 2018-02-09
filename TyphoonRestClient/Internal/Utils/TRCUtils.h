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
#import "TyphoonRestClient.h"
#import "TRCSerializerHttpQuery.h"

extern NSString *TRCRootMapperKey;
extern NSString *TRCRootKey;

NSError *TRCRequestSerializationErrorWithFormat(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

NSString *TRCKeyFromOptionalKey(NSString *key, BOOL *isOptional);

NSError *TRCErrorFromErrorSet(NSOrderedSet *errors, NSInteger code, NSString *action);

NSError *TRCUnknownValidationErrorForObject(id object, NSString *schemaName, BOOL isResponse);

NSError *TRCConversionError(NSString *errorMessage, NSString *schemaName, BOOL isResponse);

NSString *TRCUrlPathFromPathByApplyingArguments(NSString *path, NSMutableDictionary *arguments, NSError **error);

void TRCUrlPathParamsByRemovingNull(NSMutableDictionary *arguments);

NSString *TRCQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding, TRCSerializerHttpQueryOptions options);

NSError *TRCErrorWithFormat(NSInteger code, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);

NSError *TRCErrorWithOriginalError(NSInteger code, NSError *originalError, NSString *format, ...) NS_FORMAT_FUNCTION(3,4);
