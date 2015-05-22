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
#import "TyphoonRestClient.h"

extern NSString *TRCRootMapperKey;

NSError *TRCRequestSerializationErrorWithFormat(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

NSString *TRCKeyFromOptionalKey(NSString *key, BOOL *isOptional);

NSError *TRCErrorFromErrorSet(NSOrderedSet *errors, NSInteger code, NSString *action);

id TRCValueAfterApplyingOptions(id value, TRCValidationOptions options, BOOL isRequest, BOOL isOptional);

NSError *TRCUnknownValidationErrorForObject(id object, NSString *schemaName, BOOL isResponse);

NSError *TRCConversionError(NSString *errorMessage, NSString *schemaName, BOOL isResponse);

NSString *TRCUrlPathFromPathByApplyingArguments(NSString *path, NSMutableDictionary *arguments, NSError **error);

void TRCUrlPathParamsByRemovingNull(NSMutableDictionary *arguments);

NSString * TRCQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding);

NSError *TRCErrorWithFormat(NSInteger code, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);

NSError *TRCErrorWithOriginalError(NSInteger code, NSError *originalError, NSString *format, ...) NS_FORMAT_FUNCTION(3,4);