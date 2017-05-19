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


#import "TRCSchema.h"
#import "TRCUtils.h"
#import "TRCConvertersRegistry.h"
#import "TRCValueTransformer.h"
#import "TRCSchemaStackTrace.h"
#import "TyphoonRestClientErrors.h"
#import "TRCSchemaData.h"
#import "TRCSchemaDictionaryData.h"

//////////////////////////////////////////////////////////////////////////////////////////

@interface TRCSchema () <TRCSchemaDataEnumerator>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id<TRCSchemaData> data;

@end

@implementation TRCSchema
{
    BOOL _isRequestValidation;

    NSError *_error;
    TRCSchemaStackTrace *_stack;


}

//-------------------------------------------------------------------------------------------
#pragma mark - Init
//-------------------------------------------------------------------------------------------

+ (instancetype)schemaWithData:(id<TRCSchemaData>)data name:(NSString *)name
{
    if (!data) {
        return nil;
    } else {
        TRCSchema *schema = [[self alloc] init];
        schema.data = data;
        schema.name = name;
        return schema;
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark -
//-------------------------------------------------------------------------------------------

- (BOOL)validate:(id)object isRequest:(BOOL)request error:(NSError **)error
{
    _stack = nil;
    _error = nil;
    _isRequestValidation = request;

#if TRCSchemaTrackErrorTrace
    _stack = [TRCSchemaStackTrace new];
    _stack.originalObject = object;
#endif
    
    [self.data enumerate:object withEnumerator:self];
    NSError *validationError = _error;
    if (validationError && error) {
        *error = validationError;
    }
    return validationError == nil;
}

- (BOOL)validateResponse:(id)response error:(NSError **)error
{
    return [self validate:response isRequest:NO error:error];
}

- (BOOL)validateRequest:(id)request error:(NSError **)error
{
    return [self validate:request isRequest:YES error:error];
}

//-------------------------------------------------------------------------------------------
#pragma mark - TRCSchemaData Enumeration
//-------------------------------------------------------------------------------------------

- (void)schemaData:(id<TRCSchemaData>)data foundValue:(id)value withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue
{
    if ([value isKindOfClass:[NSNull class]]) {
        value = nil;
    }

    if (!schemeValue) {
        return;
    }

    //1. Check value exists
    if (![options isOptional] && !value) {
        _error = [self errorForMissedKey:options.identifier withStack:_stack schemaValue:schemeValue];
        [data cancel];
    }
    else if (value) {
        //2. Check value correct
        if (![self isTypeOfValue:value validForSchemeValue:schemeValue]) {
            if (![self isValue:value canBeConvertedToSchemeValue:schemeValue]) {
                _error = [self errorForIncorrectValue:value
                                          correctType:[self typeRepresentationForSchemeValue:schemeValue] stack:_stack];
                [data cancel];
            }
        }
    }
}

- (void)schemaData:(id<TRCSchemaData>)data willEnumerateItemAtIndentifier:(id)itemIdentifier
{
    [_stack pushSymbol:itemIdentifier];
}

- (void)schemaData:(id<TRCSchemaData>)data didEnumerateItemAtIndentifier:(id)itemIdentifier
{
    [_stack pop];
}

- (void)schemaData:(id<TRCSchemaData>)data typeMismatchForValue:(id)value withSchemaValue:(id)schemaValue
{
    _error = [self errorForIncorrectValue:value correctType:[self typeRepresentationForSchemeValue:schemaValue]
                                    stack:_stack];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Utils
//-------------------------------------------------------------------------------------------

- (BOOL)isValue:(id)value hasSameParentWith:(id)value2
{
    BOOL hasSameParent = NO;
    Class superClass = [value class];
    while (superClass != [NSObject class]) {
        if ([value2 isKindOfClass:superClass]) {
            hasSameParent = YES;
            break;
        }
        superClass = [superClass superclass];
    }
    return hasSameParent;
}

- (BOOL)isTypeOfValue:(id)dataValue validForSchemeValue:(id)schemeValue
{
    if ([schemeValue isKindOfClass:[NSString class]]) {

        id<TRCValueTransformer>converter = [self.converterRegistry valueTransformerForTag:schemeValue];
        if (!converter || ![converter respondsToSelector:@selector(externalTypes)]) {
            return [dataValue isKindOfClass:[NSString class]];
        }

        __block BOOL isTypeSupported = NO;
        TRCValueTransformerType types = [converter externalTypes];
        [self.converterRegistry enumerateTransformerTypesWithClasses:^(TRCValueTransformerType type, Class clazz, BOOL *stop) {
            BOOL typeSupported = (BOOL)(types & type);
            if (typeSupported) {
                BOOL isThatType = [dataValue isKindOfClass:clazz];
                if (isThatType) {
                    isTypeSupported = YES;
                    *stop = YES;
                }
            }
        }];

        return isTypeSupported;
    }
    else {
        return [self isValue:dataValue hasSameParentWith:schemeValue];
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Numbers Auto Convertion
//-------------------------------------------------------------------------------------------

+ (NSCharacterSet *)nonDigitsCharacterSet
{
    static NSCharacterSet *nonDigits = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSCharacterSet *digits = [NSCharacterSet characterSetWithCharactersInString:@"1234567890."];
        nonDigits = [digits invertedSet];
    });
    return nonDigits;
}

- (BOOL)isValue:(id)dataValue canBeConvertedToSchemeValue:(id)schemeValue
{
    if (self.options & TRCValidationOptionsConvertNumbersAutomatically) {

        // 1 -> "1"
        if ([dataValue isKindOfClass:[NSNumber class]] && [schemeValue isKindOfClass:[NSString class]]) {
            //We can always convert Number to String.
            return YES;
        }
        if ([dataValue isKindOfClass:[NSString class]] && [schemeValue isKindOfClass:[NSNumber class]]) {
            NSRange nonCharacterRange = [dataValue rangeOfCharacterFromSet:[[self class] nonDigitsCharacterSet]];
            return nonCharacterRange.location == NSNotFound;
        }
    }

    return NO;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Error Composing
//-------------------------------------------------------------------------------------------

- (NSError *)errorForMissedKey:(NSString *)key withStack:(TRCSchemaStackTrace *)stack schemaValue:(id)schemaValue
{
    NSMutableArray *stackArray = [[stack stack] mutableCopy];
    [stackArray removeLastObject];
    NSString *fullDescriptionErrorMessage = nil;
    NSString *descriptionMessage = nil;
    if (key) {
        fullDescriptionErrorMessage = [NSString stringWithFormat:@"Can't find value for key '%@' in this dictionary", key];
        descriptionMessage = [NSString stringWithFormat:@"Can't find value for key '%@' in '%@' dictionary", key, [TRCSchemaStackTrace shortDescriptionFromObject:stackArray]];
    } else {
        fullDescriptionErrorMessage = [NSString stringWithFormat:@"Can't find root value. Must be kind of %@", NSStringFromClass([schemaValue class])];
        descriptionMessage = fullDescriptionErrorMessage;
    }
    NSMutableDictionary *userInfo = [self userInfoForErrorDescriptionWithObject:stack.originalObject errorMessage:fullDescriptionErrorMessage stack:stackArray];
    userInfo[NSLocalizedDescriptionKey] = descriptionMessage;
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeValidation userInfo:userInfo];
}

- (NSError *)errorForIncorrectValue:(id)value correctType:(NSString *)correctType stack:(TRCSchemaStackTrace *)stack
{
    NSString *incorrectType = [self typeDescriptionForValue:value];
    NSString *fullDescriptionErrorMessage = [NSString stringWithFormat:@"Type mismatch: must be %@, but '%@' has given", correctType, incorrectType];
    NSMutableDictionary *userInfo = [self userInfoForErrorDescriptionWithObject:stack.originalObject errorMessage:fullDescriptionErrorMessage stack:[stack stack]];
    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Type mismatch for '%@' (Must be %@, but '%@' has given)", [stack shortDescription], correctType, incorrectType];
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeValidation userInfo:userInfo];
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
            [self.converterRegistry enumerateTransformerTypesWithClasses:^(TRCValueTransformerType type, Class clazz, BOOL *stop) {
                if (types & type) {
                    [supportedTypes addObject:NSStringFromClass(clazz)];
                }
            }];
            return [supportedTypes componentsJoinedByString:@" or "];
        }
    }

    return [self typeDescriptionForValue:schemeValue];
}

- (NSMutableDictionary *)userInfoForErrorDescriptionWithObject:(id)object errorMessage:(NSString *)message stack:(NSArray *)stack
{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (stack && message) {
        NSString *fullDescription = [self errorDescriptionWithObject:object errorMessage:message stack:stack];
        if (fullDescription) {
            userInfo[TyphoonRestClientErrorKeyFullDescription] = fullDescription;
        }
    }
    userInfo[TyphoonRestClientErrorKeySchemaName] = _name;
    return userInfo;
}

- (NSString *)errorDescriptionWithObject:(id)object errorMessage:(NSString *)message stack:(NSArray *)stack
{
    NSString *errorDescription = nil;
    id<TRCValidationErrorPrinter>errorPrinter = nil;

    if ([[self.name pathExtension] length] > 0) {
        errorPrinter = [self.converterRegistry validationErrorPrinterForExtension:[self.name pathExtension]];
    }

    if (errorPrinter) {
        errorDescription = [errorPrinter errorDescriptionForObject:object errorMessage:message stackTrace:stack];
    }

    return errorDescription;
}

- (NSString *)typeDescriptionForValue:(id)value
{
    return [[value class] description];
}

@end
