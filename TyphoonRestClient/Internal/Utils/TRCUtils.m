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

#import "TRCUtils.h"
#import "TyphoonRestClientErrors.h"

NSString *TRCRootMapperKey = @"{root_mapper}";

NSError *TRCErrorWithFormat(NSInteger code, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [NSError errorWithDomain:TyphoonRestClientErrors code:code userInfo:@{NSLocalizedDescriptionKey : description}];
}

NSError *TRCRequestSerializationErrorWithFormat(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeRequestSerialization userInfo:@{ NSLocalizedDescriptionKey : description}];

}

NSError *TRCErrorWithOriginalError(NSInteger code, NSError *originalError, NSString *format, ...)
{
    NSCParameterAssert(originalError);
    va_list args;
    va_start(args, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return [NSError errorWithDomain:TyphoonRestClientErrors code:code userInfo:@{ NSLocalizedDescriptionKey : description, TyphoonRestClientErrorKeyOriginalError: originalError}];
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

NSError *TRCErrorFromErrorSet(NSOrderedSet *errors, NSInteger code, NSString *action)
{
    if (errors.count == 0) {
        return nil;
    } else {
        NSMutableString *description = [NSMutableString stringWithFormat:@"There is %d errors during %@:",(int)errors.count, action];
        for (NSError *error in errors) {
            [description appendFormat:@"\n- %@",error.localizedDescription];
        }
        return TRCErrorWithFormat(code, @"%@", description);
    }
}

NSError *TRCUnknownValidationErrorForObject(id object, NSString *schemaName, BOOL isResponse)
{
    NSString *errorMessage = [NSString stringWithFormat:@"Unknown error while %@ validation", isResponse?@"response":@"request"];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[TyphoonRestClientErrorKeyFullDescription] = [NSString stringWithFormat:@"Origianl object: %@", object];
    userInfo[TyphoonRestClientErrorKeySchemaName] = schemaName;
    userInfo[NSLocalizedDescriptionKey] = errorMessage;
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeValidation userInfo:userInfo];
}

NSError *TRCConversionError(NSString *errorMessage, NSString *schemaName, BOOL isResponse)
{
    NSString *message = errorMessage ?: [NSString stringWithFormat:@"Unknown error while %@ conversion", isResponse?@"response":@"request"];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
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
                *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeRequestUrlComposing, @"Can't process path '%@', since it has arguments (%@) but no parameters specified ", path, [arguments componentsJoinedByString:@", "]);
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
                    *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeRequestUrlComposing, @"Can't process path '%@', since value for argument %@ missing or invalid (must be NSNumber or non-empty NSString)", path, argument);
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

//-------------------------------------------------------------------------------------------
#pragma mark - AFNetworking code
//-------------------------------------------------------------------------------------------

/**
 * The code below was copy-pasted from AFNetworking. Many thanks authors
 * AF prefix was replaced with TRC to avoid possible linking error while using with AFNetworking library
 * */

static NSString * const kTRCCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * TRCPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kTRCCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";

    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kTRCCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kTRCCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * TRCPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kTRCCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

@interface TRCQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

@implementation TRCQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return TRCPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", TRCPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding), TRCPercentEscapedQueryStringValueFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

static NSArray *TRCQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:TRCQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:TRCQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:TRCQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[TRCQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

static NSArray * TRCQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return TRCQueryStringPairsFromKeyAndValue(nil, dictionary);
}

//-------------------------------------------------------------------------------------------
#pragma mark -
//-------------------------------------------------------------------------------------------

NSString * TRCQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding)
{
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (TRCQueryStringPair *pair in TRCQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }
    return [mutablePairs componentsJoinedByString:@"&"];
}