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




#import "HWSUtils.h"

NSError *NSErrorWithFormat(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [NSError errorWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey : description}];
}

NSString *KeyFromOptionalKey(NSString *key, BOOL *isOptional)
{
    *isOptional = [key hasSuffix:@"?"];
    if (*isOptional) {
        key = [key substringToIndex:[key length]-1];
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

id ValueAfterApplyingOptions(id value, HWSValidationOptions options, BOOL isRequest, BOOL isOptional)
{
    id result = value;
    BOOL isEmptyDictionary = [result isKindOfClass:[NSDictionary class]] && [result count] == 0;
    if (isEmptyDictionary) {
        HWSValidationOptions treadForOptional = isRequest ? HWSValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional :
                HWSValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional;
        HWSValidationOptions treadForRequired = isRequest ? HWSValidationOptionsTreatEmptyDictionaryAsNilInRequestsForRequired :
                HWSValidationOptionsTreatEmptyDictionaryAsNilInResponsesForRequired;

        if (isOptional && (options & treadForOptional)) {
            result = nil;
        }
        if (!isOptional && (options & treadForRequired)) {
            result = nil;
        }
    }
    return result;
}
