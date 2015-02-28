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


#import "TRCSchema.h"
#import "TRCUtils.h"
#import "TRCConvertersRegistry.h"
#import "TRCValueConverter.h"
#import "TRCSchemeStackTrace.h"
#import "TyphoonRestClientErrors.h"

//////////////////////////////////////////////////////////////////////////////////////////

@interface TRCSchema ()

@property (nonatomic, strong) id schemeObject;

@end

@implementation TRCSchema
{
    BOOL _isRequestValidation;
}

+ (instancetype)schemaWithName:(NSString *)name
{
    if (!name) {
        return nil;
    }
    
    NSString *path = nil;

    if ([name pathExtension].length > 0) {
        path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:nil];
    } else {
        NSArray *extensionsToTry = @[@"json", @"schema"];

        for (NSString *extension in extensionsToTry) {
            path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:extension];
            if (path) {
                break;
            }
        }
    }

    if (path.length == 0) {
        return nil;
    } else {
        return [[self alloc] initWithFilePath:path];
    }
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    id schemeObject = nil;

    NSData *fileContent = [[NSData alloc] initWithContentsOfFile:filePath];
    if (fileContent) {
        NSError *jsonParsingError = nil;
        schemeObject = [NSJSONSerialization JSONObjectWithData:fileContent options:NSJSONReadingAllowFragments error:&jsonParsingError];
        if (jsonParsingError || !schemeObject) {
            NSLog(@"Error: can't parse JSON at path: %@. %@", filePath, jsonParsingError ? jsonParsingError.localizedDescription : @"");
            return nil;
        }
    } else {
        NSLog(@"Error: can't open scheme at path: %@.", filePath);
        return nil;
    }

    return [self initWithSchemeObject:schemeObject name:[filePath lastPathComponent]];
}


- (instancetype)initWithSchemeObject:(id)object name:(NSString *)name
{
    self = [super init];
    if (self) {
        NSParameterAssert(object);
        NSParameterAssert(name);
        _name = name;
        _schemeObject = object;
    }
    return self;
}

- (BOOL)validateResponse:(id)response error:(NSError **)error
{
    TRCSchemeStackTrace *stackTrace = nil;
#if TRCSchemaTrackErrorTrace
    stackTrace = [TRCSchemeStackTrace new];
    stackTrace.originalObject = response;
#endif
    NSError *validationError = [self validateReceivedValue:response withSchemaValue:self.schemeObject stackTrace:stackTrace];
    if (validationError && error) {
        *error = validationError;
    }
    return validationError == nil;
}

- (BOOL)validateRequest:(id)request error:(NSError **)error
{
    _isRequestValidation = YES;
    TRCSchemeStackTrace *stackTrace = nil;
#if TRCSchemaTrackErrorTrace
    stackTrace = [TRCSchemeStackTrace new];
    stackTrace.originalObject = request;
#endif
    NSError *validationError = [self validateReceivedValue:request withSchemaValue:self.schemeObject stackTrace:stackTrace];
    if (validationError && error) {
        *error = validationError;
    }
    _isRequestValidation = NO;
    return validationError == nil;
}

- (id)schemeArrayOrDictionary
{
    return self.schemeObject;
}

- (id)schemeObjectOrArrayItem
{
    if ([self.schemeObject isKindOfClass:[NSArray class]]) {
        return [self.schemeObject firstObject];
    } else {
        return self.schemeObject;
    }
}


- (NSError *)validateReceivedValue:(id)value withSchemaValue:(id)schemeValue stackTrace:(TRCSchemeStackTrace *)stack
{
    //1. Check that types are same
    if (![self isTypeOfValue:value validForSchemeValue:schemeValue]) {
        //1.1 Check if schemeValue is mapper tag
        if ([self isMapperTagValue:schemeValue]) {
            return [self validateReceivedValue:value withMapperTag:schemeValue stackTrace:stack];
        } else {
            return [self errorForIncorrectType:[[value class] description] correctType:[self typeRepresentationForSchemeValue:schemeValue] stack:stack];
        }
    }
    //2. Check if collection type - call recurrent function
    if ([schemeValue isKindOfClass:[NSArray class]]) {
        return [self validateArray:value withSchemeArrayValue:[schemeValue firstObject] stackTrace:stack];
    } else if ([schemeValue isKindOfClass:[NSDictionary class]]) {
        return [self validateDictionary:value withSchemaDictionary:schemeValue stackTrace:stack];
    } else {
        return nil;
    }
}

- (BOOL)isMapperTagValue:(id)value
{
    return [value isKindOfClass:[NSString class]] && [self.converterRegistry objectMapperForTag:value];
}

- (NSError *)validateReceivedValue:(id)value withMapperTag:(NSString *)mapperTag stackTrace:(TRCSchemeStackTrace *)stack
{
    TRCSchema *schema;
    if (_isRequestValidation) {
        schema = [self.converterRegistry requestSchemaForMapperWithTag:mapperTag];
    } else {
        schema = [self.converterRegistry responseSchemaForMapperWithTag:mapperTag];
    }

    schema->_isRequestValidation = _isRequestValidation;
    return [schema validateReceivedValue:value withSchemaValue:schema.schemeObject stackTrace:stack];
}

- (NSError *)validateArray:(NSArray *)array withSchemeArrayValue:(id)schemeValue stackTrace:(TRCSchemeStackTrace *)stack
{
    __block NSError *error = nil;

    [array enumerateObjectsUsingBlock:^(id givenValue, NSUInteger idx, BOOL *stop) {
        [stack pushSymbolWithArrayIndex:idx];
        error = [self validateReceivedValue:givenValue withSchemaValue:schemeValue stackTrace:stack];
        if (error) {
            *stop = YES;
        }
        [stack pop];
    }];

    return error;
}

- (NSError *)validateDictionary:(NSDictionary *)dictionary withSchemaDictionary:(NSDictionary *)scheme stackTrace:(TRCSchemeStackTrace *)stack
{
    __block NSError *error = nil;

    [scheme enumerateKeysAndObjectsUsingBlock:^(NSString *key, id schemeValue, BOOL *stop) {

        if (![key isEqualToString:TRCConverterNameKey]) {

            BOOL isOptional = NO;
            key = TRCKeyFromOptionalKey(key, &isOptional);

            id givenValue = dictionary[key];

            //0. Handle NSNull case
            if ([givenValue isKindOfClass:[NSNull class]]) {
                givenValue = nil;
            }

            givenValue = TRCValueAfterApplyingOptions(givenValue, self.options, _isRequestValidation, isOptional);

            //1. Check value exists
            if (!isOptional && !givenValue) {
                error = [self errorForMissedKey:key withStack:stack];
                *stop = YES;
            }
                //2. Check value correct
            else if (givenValue) {
                [stack pushSymbol:key];

                error = [self validateReceivedValue:givenValue withSchemaValue:schemeValue stackTrace:stack];
                if (error) {
                    *stop = YES;
                }

                [stack pop];
            }
        }
    }];

    return error;
}

#define IsSameParent(value1, value2, parent) ([value1 isKindOfClass:[parent class]] && [value2 isKindOfClass:[parent class]])

- (BOOL)isTypeOfValue:(id)dataValue validForSchemeValue:(id)schemeValue
{
    if ([schemeValue isKindOfClass:[NSString class]]) {
        
        id<TRCValueConverter>converter = [self.converterRegistry valueConverterForTag:schemeValue];
        if (!converter || ![converter respondsToSelector:@selector(types)]) {
            return [dataValue isKindOfClass:[NSString class]];
        }
        TRCValueConverterType types = [converter types];
        BOOL isNumber = [dataValue isKindOfClass:[NSNumber class]];
        BOOL isString = [dataValue isKindOfClass:[NSString class]];
        BOOL supportNumbers = (types & TRCValueConverterTypeNumber);
        BOOL supportStrings = (types & TRCValueConverterTypeString);

        return (isNumber && supportNumbers) || (isString && supportStrings);
    }
    else {
        BOOL isBothNumbers = IsSameParent(dataValue, schemeValue, NSValue);
        BOOL isBothDictionaries = IsSameParent(dataValue, schemeValue, NSDictionary);
        BOOL isBothArray = IsSameParent(dataValue, schemeValue, NSArray);

        return isBothNumbers || isBothDictionaries || isBothArray;
    }
}


- (NSString *)typeRepresentationForSchemeValue:(id)schemeValue
{
    if ([schemeValue isKindOfClass:[NSString class]]) {
        id<TRCValueConverter>converter = [self.converterRegistry valueConverterForTag:schemeValue];
        if (converter) {
            TRCValueConverterType types = TRCValueConverterTypeString;
            if ([converter respondsToSelector:@selector(types)]) {
                types = [converter types];
            }
            NSMutableArray *supportedTypes = [NSMutableArray new];
            if (types & TRCValueConverterTypeNumber) {
                [supportedTypes addObject:@"'NSNumber'"];
            }
            if (types & TRCValueConverterTypeString) {
                [supportedTypes addObject:@"'NSString'"];
            }
            return [supportedTypes componentsJoinedByString:@" or "];
        }
    }

    return [NSString stringWithFormat:@"'%@'",NSStringFromClass([schemeValue class])];
}

- (NSError *)errorForMissedKey:(NSString *)key withStack:(TRCSchemeStackTrace *)stack
{
    NSString *fullDescriptionErrorMessage = [NSString stringWithFormat:@"Can't find value for key '%@' in this dictionary", key];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (stack) {
        userInfo[TyphoonRestClientErrorKeyFullDescription] = [stack fullDescriptionWithErrorMessage:fullDescriptionErrorMessage];
    }
    userInfo[TyphoonRestClientErrorKeySchemaName] = _name;
    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Can't find value for key '%@' in '%@' dictionary", key, [stack shortDescription]];
    return [NSError errorWithDomain:@"TyphoonRestClientErrors" code:TyphoonRestClientErrorCodeValidation userInfo:userInfo];
}

- (NSError *)errorForIncorrectType:(NSString *)incorrectType correctType:(NSString *)correctType stack:(TRCSchemeStackTrace *)stack
{
    NSString *fullDescriptionErrorMessage = [NSString stringWithFormat:@"Type mismatch: must be %@, but '%@' has given", correctType, incorrectType];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (stack) {
        userInfo[TyphoonRestClientErrorKeyFullDescription] = [stack fullDescriptionWithErrorMessage:fullDescriptionErrorMessage];
    }
    userInfo[TyphoonRestClientErrorKeySchemaName] = _name;
    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Type mismatch for '%@' (Must be %@, but '%@' has given)", [stack shortDescription], correctType, incorrectType];
    return [NSError errorWithDomain:@"TyphoonRestClientErrors" code:TyphoonRestClientErrorCodeValidation userInfo:userInfo];
}

@end