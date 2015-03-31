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
#import "TRCValueTransformer.h"
#import "TRCSchemeStackTrace.h"
#import "TyphoonRestClientErrors.h"
#import "TRCSchemaData.h"
#import "TRCSchemeDictionaryData.h"

//////////////////////////////////////////////////////////////////////////////////////////

@interface TRCSchema () <TRCSchemaDataEnumerator, TRCSchemaDataProvider>

@property (nonatomic, strong) id schemeObject;

@end

@implementation TRCSchema
{
    BOOL _isRequestValidation;

    NSError *_error;
    TRCSchemeStackTrace *_stack;
}

+ (instancetype)schemaWithName:(NSString *)name extensionsToTry:(NSArray *)extensions
{
    if (!name) {
        return nil;
    }
    
    NSString *path = nil;

    if ([name pathExtension].length > 0) {
        path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:nil];
    } else {
        NSArray *extensionsToTry = extensions?:@[@"json", @"schema"];

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
        self.data = [[TRCSchemeDictionaryData alloc] initWithArrayOrDictionary:object];
        ((TRCSchemeDictionaryData *)self.data).dataProvider = self;

        NSParameterAssert(object);
        NSParameterAssert(name);
        _name = name;
        _schemeObject = object;
    }
    return self;
}

- (BOOL)validateResponse:(id)response error:(NSError **)error
{
    _stack = nil;
#if TRCSchemaTrackErrorTrace
    _stack = [TRCSchemeStackTrace new];
    _stack.originalObject = response;
#endif

    ((TRCSchemeDictionaryData *)self.data).requestData = NO;
    [self.data enumerate:response withEnumerator:self];


    NSError *validationError = _error;//[self validateReceivedValue:response withSchemaValue:self.schemeObject stackTrace:stackTrace];
    if (validationError && error) {
        *error = validationError;
    }
    return validationError == nil;
}

- (BOOL)validateRequest:(id)request error:(NSError **)error
{
    _isRequestValidation = YES;
    _stack = nil;
#if TRCSchemaTrackErrorTrace
    _stack = [TRCSchemeStackTrace new];
    _stack.originalObject = request;
#endif
    ((TRCSchemeDictionaryData *)self.data).requestData = YES;
    [self.data enumerate:request withEnumerator:self];
    NSError *validationError = _error;//[self validateReceivedValue:request withSchemaValue:self.schemeObject stackTrace:stackTrace];
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

//-------------------------------------------------------------------------------------------
#pragma mark - TRCSchemaData Enumeration
//-------------------------------------------------------------------------------------------

- (void)schemaData:(id<TRCSchemaData>)data foundValue:(id)value withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue
{
    if ([value isKindOfClass:[NSNull class]]) {
        value = nil;
    }

    value = TRCValueAfterApplyingOptions(value, self.options, _isRequestValidation, [options isOptional]);

    //1. Check value exists
    if (![options isOptional] && !value) {
        _error = [self errorForMissedKey:options.identifier withStack:_stack];
        [data cancel];
    }
    else if (value) {
        //2. Check value correct
        if (![self isTypeOfValue:value validForSchemeValue:schemeValue]) {
            _error = [self errorForIncorrectType:[[value class] description] correctType:[self typeRepresentationForSchemeValue:schemeValue] stack:_stack];
            [data cancel];
        }
    }
}

- (void)schemaData:(id<TRCSchemaData>)data willEnumerateItemAtIndentifier:(id)itemIdentifier
{
    if ([itemIdentifier isKindOfClass:[NSNumber class]]) {
        [_stack pushSymbolWithArrayIndex:itemIdentifier];
    } else if ([itemIdentifier isKindOfClass:[NSString class]]) {
        [_stack pushSymbol:itemIdentifier];
    } else {
        NSAssert(NO, @"Unsupported identifier type: %@", itemIdentifier);
    }
}

- (void)schemaData:(id<TRCSchemaData>)data didEnumerateItemAtIndentifier:(id)itemIdentifier
{
    [_stack pop];
}

- (void)schemaData:(id<TRCSchemaData>)data willEnumerateCollection:(id)collection
{

}

- (void)schemaData:(id<TRCSchemaData>)data didEnumerateCollection:(id)collection
{

}

- (void)schemaData:(id<TRCSchemaData>)data typeMismatchForValue:(id)value withSchemaValue:(id)schemaValue
{
    _error = [self errorForIncorrectType:[[value class] description] correctType:[self typeRepresentationForSchemeValue:schemaValue] stack:_stack];
}

//-------------------------------------------------------------------------------------------
#pragma mark - TRCSchemaData Provider
//-------------------------------------------------------------------------------------------

- (BOOL)schemaData:(id<TRCSchemaData>)data hasObjectMapperForTag:(NSString *)schemaName
{
    return [self.converterRegistry objectMapperForTag:schemaName] != nil;
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data requestSchemaForMapperWithTag:(NSString *)schemaName
{
    return [self.converterRegistry requestSchemaForMapperWithTag:schemaName].data;
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data responseSchemaForMapperWithTag:(NSString *)schemaName
{
    return [self.converterRegistry responseSchemaForMapperWithTag:schemaName].data;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Utils
//-------------------------------------------------------------------------------------------

#define IsSameParent(value1, value2, parent) ([value1 isKindOfClass:[parent class]] && [value2 isKindOfClass:[parent class]])

- (BOOL)isTypeOfValue:(id)dataValue validForSchemeValue:(id)schemeValue
{
    if ([schemeValue isKindOfClass:[NSString class]]) {

        id<TRCValueTransformer>converter = [self.converterRegistry valueTransformerForTag:schemeValue];
        if (!converter || ![converter respondsToSelector:@selector(externalTypes)]) {
            return [dataValue isKindOfClass:[NSString class]];
        }
        TRCValueTransformerType types = [converter externalTypes];
        BOOL isNumber = [dataValue isKindOfClass:[NSNumber class]];
        BOOL isString = [dataValue isKindOfClass:[NSString class]];
        BOOL supportNumbers = (types & TRCValueTransformerTypeNumber);
        BOOL supportStrings = (types & TRCValueTransformerTypeString);

        return (isNumber && supportNumbers) || (isString && supportStrings);
    }
    else {
        BOOL isBothNumbers = IsSameParent(dataValue, schemeValue, NSValue);
        BOOL isBothDictionaries = IsSameParent(dataValue, schemeValue, NSDictionary);
        BOOL isBothArray = IsSameParent(dataValue, schemeValue, NSArray);

        return isBothNumbers || isBothDictionaries || isBothArray;
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Error Composing
//-------------------------------------------------------------------------------------------

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

- (NSString *)typeRepresentationForSchemeValue:(id)schemeValue
{
    if ([schemeValue isKindOfClass:[NSString class]]) {
        id<TRCValueTransformer>converter = [self.converterRegistry valueTransformerForTag:schemeValue];
        if (converter) {
            TRCValueTransformerType types = TRCValueTransformerTypeString;
            if ([converter respondsToSelector:@selector(externalTypes)]) {
                types = [converter externalTypes];
            }
            NSMutableArray *supportedTypes = [NSMutableArray new];
            if (types & TRCValueTransformerTypeNumber) {
                [supportedTypes addObject:@"'NSNumber'"];
            }
            if (types & TRCValueTransformerTypeString) {
                [supportedTypes addObject:@"'NSString'"];
            }
            return [supportedTypes componentsJoinedByString:@" or "];
        }
    }

    return [NSString stringWithFormat:@"'%@'",NSStringFromClass([schemeValue class])];
}

@end