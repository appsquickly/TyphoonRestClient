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

#import <objc/runtime.h>
#import "TRCConverter.h"
#import "TRCUtils.h"
#import "TRCConvertersRegistry.h"
#import "TRCValueTransformer.h"
#import "TRCObjectMapper.h"
#import "TRCSchema.h"
#import "TRCSchemaData.h"
#import "TyphoonRestClientErrors.h"
#import "TRCSchemaStackTrace.h"

@interface TRCConverter () <TRCSchemaDataModifier>

@property (nonatomic, strong) TRCSchema *schema;

@end

@implementation TRCConverter
{
    NSError *_error;

    BOOL _convertingForRequest;

    TRCSchemaStackTrace *_stack;
}

- (instancetype)initWithSchema:(TRCSchema *)schema
{
    NSParameterAssert(schema);
    self = [super init];
    if (self) {
        self.schema = schema;
    }
    return self;
}

- (id)convertResponseValue:(id)value error:(NSError **)error
{
    _convertingForRequest = NO;

#if TRCSchemaTrackErrorTrace
    _stack = [TRCSchemaStackTrace new];
    _stack.originalObject = value;
#endif

    id result = [self.schema.data modify:value withModifier:self];
    if (error && _error) {
        *error = _error;
    }
    return result;
}

- (id)convertRequestValue:(id)value error:(NSError **)error
{
    _convertingForRequest = YES;

#if TRCSchemaTrackErrorTrace
    _stack = [TRCSchemaStackTrace new];
    _stack.originalObject = value;
#endif

    id result = [self.schema.data modify:value withModifier:self];
    if (error && _error) {
        *error = _error;
    }
    return result;
}

//-------------------------------------------------------------------------------------------
#pragma mark - TRCSchemaData Modifier
//-------------------------------------------------------------------------------------------

- (id)schemaData:(id<TRCSchemaData>)data replacementForValue:(id)object withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue
{
    //Handle NSNull case
    if ([object isKindOfClass:[NSNull class]] && !(self.transformationOptions & TRCTransformationOptionsPassNullAsIs)) {
        object = nil;
    }

    //Handle object missing in scheme
    if (!schemeValue) {
        if (_convertingForRequest && (self.registry.options & TRCOptionsRemoveValuesMissedInSchemeForRequests)) {
            object = nil;
        }
        else if (!_convertingForRequest && (self.registry.options & TRCOptionsRemoveValuesMissedInSchemeForResponses)) {
            object = nil;
        }
    }

    return [self convertValue:object usingSchemeValue:schemeValue];
}

- (id)schemaData:(id<TRCSchemaData>)data objectFromResponse:(id)object withMapperTag:(NSString *)tag
{
    return [self convertObject:object withMapperTag:tag usingSelector:@selector(objectFromResponseObject:error:)];
}

- (id)schemaData:(id<TRCSchemaData>)data requestFromObject:(id)object withMapperTag:(NSString *)tag
{
    return [self convertObject:object withMapperTag:tag usingSelector:@selector(requestObjectFromObject:error:)];
}

- (void)schemaData:(id<TRCSchemaData>)data typeMismatchForValue:(id)value withSchemaValue:(id)schemaValue
{
    NSString *errorDescription =  [NSString stringWithFormat:@"Type mismatch for '%@' (Must be %@, but '%@' has given)", [_stack shortDescription], [schemaValue class], [value class]];
    _error = TRCConversionError(errorDescription, self.schema.name, _convertingForRequest);
}

- (void)schemaData:(id<TRCSchemaData>)data willEnumerateItemAtIndentifier:(id)itemIdentifier
{
    [_stack pushSymbol:itemIdentifier];
}

- (void)schemaData:(id<TRCSchemaData>)data didEnumerateItemAtIndentifier:(id)itemIdentifier
{
    [_stack pop];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Utils
//-------------------------------------------------------------------------------------------

- (id)convertValue:(id)dataValue usingSchemeValue:(id)schemeValue
{
    NSParameterAssert(self.registry);

    id result = nil;

    id<TRCValueTransformer>typeConverter = nil;
    if (dataValue && [schemeValue isKindOfClass:[NSString class]] && self.registry) {
        typeConverter = [self.registry valueTransformerForTag:schemeValue];
    }

    if (typeConverter) {
        result = [self convertIfPossibleValue:dataValue usingConverter:typeConverter];
    } else {
        result = [self convertIfPossibleValue:dataValue usingSchemeValue:schemeValue];
    }

    return result;
}

- (id)convertIfPossibleValue:(id)dataValue usingConverter:(id<TRCValueTransformer>)typeConverter
{
    NSError *convertError = nil;
    id result = nil;

    if (_convertingForRequest) {
        result = [typeConverter requestValueFromObject:dataValue error:&convertError];
    } else {
        result = [typeConverter objectFromResponseValue:dataValue error:&convertError];
    }

    if (convertError) {
        _error = [self errorWithMessage:@"Can't transform value" originalError:convertError];
        [self.schema.data cancel];
        result = nil;
    }

    return result;
}

- (id)convertIfPossibleValue:(id)dataValue usingSchemeValue:(id)schemeValue
{
    if (self.registry.options & TRCOptionsConvertNumbersAutomatically) {
        if ([dataValue isKindOfClass:[NSNumber class]] && [schemeValue isKindOfClass:[NSString class]]) {
            return [dataValue description];
        }
        if ([dataValue isKindOfClass:[NSString class]] && [schemeValue isKindOfClass:[NSNumber class]]) {
            if ([dataValue rangeOfString:@"."].location == NSNotFound) {
                return @([(NSString *)dataValue longLongValue]);
            } else {
                return @([dataValue doubleValue]);
            }
        }
    }

    return dataValue;
}

- (id)convertObject:(id)object withMapperTag:(NSString *)tag usingSelector:(SEL)sel
{
    NSError *error = nil;
    id result = nil;
    NSParameterAssert(tag);
    NSParameterAssert(self.registry);
    id<TRCObjectMapper> converter = [self.registry objectMapperForTag:tag];
    if (!converter) {
        error = TRCConversionError([NSString stringWithFormat:@"Can't find TRCObjectMapper for '%@' with tag '%@'", [_stack shortDescription], tag], self.schema.name, !_convertingForRequest);
    } else {
        if ([converter respondsToSelector:sel]) {
            id(*impl)(id, SEL, id, NSError **) = (id(*)(id, SEL, id, NSError **))[(NSObject*)converter methodForSelector:sel];
            result = impl(converter, sel, object, &error);
            if (error) {
                error = [self errorWithMessage:@"Can't map object" originalError:error];
                result = nil;
            }
        } else {
            error = TRCConversionError([NSString stringWithFormat:@"TRCObjectMapper for '%@' with tag '%@' (Class: %@) not responds to '%@'", [_stack shortDescription], tag, [converter class], NSStringFromSelector(sel)], self.schema.name, !_convertingForRequest);
        }
    }

    if (error) {
        _error = error;
        [self.schema.data cancel];
    }

    return result;
}

- (NSError *)errorWithMessage:(NSString *)message originalError:(NSError *)originalError
{
    message = [NSString stringWithFormat:@"%@ for '%@': %@", message, [_stack shortDescription], [originalError localizedDescription]];
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[TyphoonRestClientErrorKeySchemaName] = self.schema.name;
    userInfo[NSLocalizedDescriptionKey] = message;
    userInfo[TyphoonRestClientErrorKeyOriginalError] = originalError;
    return [NSError errorWithDomain:TyphoonRestClientErrors code:TyphoonRestClientErrorCodeTransformation userInfo:userInfo];
}

@end
