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

@property (nonatomic, strong) NSMutableOrderedSet *internalErrors;
@end

@implementation TRCConverter
{
    BOOL _convertingForRequest;
}

- (instancetype)initWithSchema:(TRCSchema *)schema
{
    NSParameterAssert(schema);
    self = [super init];
    if (self) {
        self.schema = schema;
        self.internalErrors = [NSMutableOrderedSet new];
    }
    return self;
}

- (id)convertResponseValue:(id)value error:(NSError **)error
{
    _convertingForRequest = NO;
    id result = [self.schema.data modify:value withModifier:self];
    if (error) {
        *error = [self conversionError];
    }
    return result;
}

- (id)convertRequestValue:(id)value error:(NSError **)error
{
    _convertingForRequest = YES;
    id result = [self.schema.data modify:value withModifier:self];
    if (error) {
        *error = [self conversionError];
    }
    return result;
}

- (NSError *)conversionError
{
    return TRCErrorFromErrorSet(self.internalErrors, TyphoonRestClientErrorCodeTransformation, @"value transformations");
}

- (NSOrderedSet *)conversionErrorSet
{
    return self.internalErrors;
}

//-------------------------------------------------------------------------------------------
#pragma mark - TRCSchemaData Modifier
//-------------------------------------------------------------------------------------------

- (id)schemaData:(id<TRCSchemaData>)data replacementForValue:(id)object withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue
{
    //Handle NSNull case
    if ([object isKindOfClass:[NSNull class]]) {
        object = nil;
    }

    //Handle object missing in scheme
    if (!schemeValue) {
        if (_convertingForRequest && (self.options & TRCValidationOptionsRemoveValuesMissedInSchemeForRequests)) {
            object = nil;
        }
        else if (!_convertingForRequest && (self.options & TRCValidationOptionsRemoveValuesMissedInSchemeForResponses)) {
            object = nil;
        }
    }

    if (object && self.registry && [schemeValue isKindOfClass:[NSString class]]) {
        return [self convertValue:object toType:schemeValue];
    } else {
        return object;
    }
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
    NSError *error = TRCConversionError([NSString stringWithFormat:@"Object of type '%@' doesn't match type '%@'", [value class], [schemaValue class]], self.schema.name, _convertingForRequest);
    [self.internalErrors addObject:error];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Utils
//-------------------------------------------------------------------------------------------

- (id)convertValue:(id)dataValue toType:(NSString *)typeName
{
    NSParameterAssert(self.registry);

    NSError *convertError = nil;
    id result = dataValue;
    id<TRCValueTransformer>typeConverter = [self.registry valueTransformerForTag:typeName];

    if (typeConverter) {
        if (_convertingForRequest) {
            result = [typeConverter requestValueFromObject:dataValue error:&convertError];
        } else {
            result = [typeConverter objectFromResponseValue:dataValue error:&convertError];
        }
    }

    if (convertError) {
        [self.internalErrors addObject:convertError];
        result = nil;
    }
    return result;
}

- (id)convertObject:(id)object withMapperTag:(NSString *)tag usingSelector:(SEL)sel
{
    NSParameterAssert(tag);
    NSParameterAssert(self.registry);
    id<TRCObjectMapper> converter = [self.registry objectMapperForTag:tag];
    if (!converter) {
        [self.internalErrors addObject:TRCConversionError([NSString stringWithFormat:@"Can't find converter for tag '%@'", tag], self.schema.name, !_convertingForRequest)];
        return nil;
    }
    NSError *error = nil;
    id result = nil;
    if ([converter respondsToSelector:sel]) {
        id(*impl)(id, SEL, id, NSError **) = (id(*)(id, SEL, id, NSError **))[(NSObject*)converter methodForSelector:sel];
        result = impl(converter, sel, object, &error);
        if (error) {
            [self.internalErrors addObject:error];
            result = nil;
        }
    } else {
        [self.internalErrors addObject:TRCConversionError([NSString stringWithFormat:@"Converter for tag '%@' (Class: %@) not responds to '%@'", tag, [converter class], NSStringFromSelector(sel)], self.schema.name, !_convertingForRequest)];
    }
    return result;
}

@end