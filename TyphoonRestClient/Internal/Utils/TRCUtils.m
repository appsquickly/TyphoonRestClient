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

NSString *TRCConverterNameKey = @"{mapper}";

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
        TRCValidationOptions treatForOptional = isRequest ? TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional :
                TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional;
        TRCValidationOptions treatForRequired = isRequest ? TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForRequired :
                TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForRequired;

        if (isOptional && (options & treatForOptional)) {
            result = nil;
        }
        if (!isOptional && (options & treatForRequired)) {
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
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeTransformation userInfo:userInfo];
}


BOOL IsValidPathArgumentValue(id value)
{
    return [value isKindOfClass:[NSNumber class]] || ([value isKindOfClass:[NSString class]] && [value length] > 0);
}

static NSRegularExpression *catchUrlArgumentsRegexp;

NSString *TRCUrlPathFromPathByApplyingArguments(NSString *path, NSMutableDictionary *mutableParams, NSError **error)
{
    if (!catchUrlArgumentsRegexp) {
        catchUrlArgumentsRegexp = [[NSRegularExpression alloc] initWithPattern:@"\\{.*?\\}" options:0 error:nil];
    }

    NSArray *arguments = [catchUrlArgumentsRegexp matchesInString:path options:0 range:NSMakeRange(0, [path length])];

    // Applying arguments
    if ([arguments count] > 0) {
        if ([mutableParams count] == 0) {
            if (error) {
                *error = NSErrorWithFormat(@"Can't process path '%@', since it has arguments (%@) but no parameters specified ", path, [arguments componentsJoinedByString:@", "]);
            }
            return nil;
        }
        NSMutableString *mutablePath = [path mutableCopy];

        for (NSTextCheckingResult *argumentMatch in arguments) {
            NSString *argument = [path substringWithRange:argumentMatch.range];
            if ([mutablePath rangeOfString:argument].location == NSNotFound) {
                continue;
            }
            NSString *argumentKey = [argument substringWithRange:NSMakeRange(1, argument.length-2)];
            id value = mutableParams[argumentKey];
            if (!IsValidPathArgumentValue(value)) {
                if (error) {
                    *error = NSErrorWithFormat(@"Can't process path '%@', since value for argument %@ missing or invalid (must be NSNumber or non-empty NSString)", path, argument);
                }
                return nil;
            }
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [value description];
            }
            [mutablePath replaceOccurrencesOfString:argument withString:value options:0 range:NSMakeRange(0, [mutablePath length])];
            [mutableParams removeObjectForKey:argumentKey];
        }
        path = mutablePath;
    }

    return path;
}

void TRCUrlPathParamsByRemovingNull(NSMutableDictionary *arguments)
{
    for (NSString *key in [arguments allKeys]) {
        if ([arguments[key] isKindOfClass:[NSNull class]]) {
            [arguments removeObjectForKey:key];
        }
    }
}
