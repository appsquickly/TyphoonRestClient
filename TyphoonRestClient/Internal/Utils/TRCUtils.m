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




#import "TRCUtils.h"
#import "TyphoonRestClientErrors.h"
#import "TRCSchemeStackTrace.h"

NSString *TRCConverterNameKey = @"{converter}";

NSError *NSErrorWithFormat(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [NSError errorWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey : description}];
}

NSString *TRCKeyFromOptionalKey(NSString *key, BOOL *isOptional)
{
    BOOL _isOptional = [key hasSuffix:@"{?}"];
    if (_isOptional) {
        key = [key substringToIndex:[key length]-3];
    }
    if (isOptional) {
        *isOptional = _isOptional;
    }
    return key;
}

NSError *NSErrorFromErrorSet(NSOrderedSet *errors, NSString *action)
{
    if (errors.count == 0) {
        return nil;
    } else {
        NSMutableString *description = [NSMutableString stringWithFormat:@"There is %d errors during %@:",(int)errors.count, action];
        for (NSError *error in errors) {
            [description appendFormat:@"\n- %@",error.localizedDescription];
        }
        return NSErrorWithFormat(@"%@", description);
    }
}

id TRCValueAfterApplyingOptions(id value, TRCValidationOptions options, BOOL isRequest, BOOL isOptional)
{
    id result = value;
    BOOL isEmptyDictionary = [result isKindOfClass:[NSDictionary class]] && [result count] == 0;
    if (isEmptyDictionary) {
        TRCValidationOptions treadForOptional = isRequest ? TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional :
                TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional;
        TRCValidationOptions treadForRequired = isRequest ? TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForRequired :
                TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForRequired;

        if (isOptional && (options & treadForOptional)) {
            result = nil;
        }
        if (!isOptional && (options & treadForRequired)) {
            result = nil;
        }
    }
    return result;
}

NSError *TRCUnknownValidationErrorForObject(id object, NSString *schemaName, BOOL isResponse)
{
    NSString *errorMessage = [NSString stringWithFormat:@"Unknown error while %@ validation", isResponse?@"response":@"request"];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[TyphoonRestClientErrorKeyFullDescription] = [NSString stringWithFormat:@"Origianl object: %@", [TRCSchemeStackTrace descriptionOfObject:object]];
    userInfo[TyphoonRestClientErrorKeySchemaName] = schemaName;
    userInfo[NSLocalizedDescriptionKey] = errorMessage;
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeValidation userInfo:userInfo];
}

NSError *TRCConversionErrorForObject(NSString *errorMessage, id object, NSString *schemaName, BOOL isResponse)
{
    NSString *message = errorMessage ?: [NSString stringWithFormat:@"Unknown error while %@ conversion", isResponse?@"response":@"request"];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[TyphoonRestClientErrorKeyFullDescription] = [NSString stringWithFormat:@"Origianl object: %@", [TRCSchemeStackTrace descriptionOfObject:object]];
    userInfo[TyphoonRestClientErrorKeySchemaName] = schemaName;
    userInfo[NSLocalizedDescriptionKey] = message;
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeConversion userInfo:userInfo];
}