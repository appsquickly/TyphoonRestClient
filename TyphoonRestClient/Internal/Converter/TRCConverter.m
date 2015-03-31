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




#import "TRCConverter.h"
#import "TRCUtils.h"
#import "TRCConvertersRegistry.h"
#import "TRCValueTransformer.h"
#import "TRCObjectMapper.h"
#import "TRCSchema.h"
#import "TRCSchemaData.h"

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
    return NSErrorFromErrorSet(self.internalErrors, @"value transformations");
}

- (NSOrderedSet *)conversionErrorSet
{
    return self.internalErrors;
}

//- (id)parseValue:(id)dataValue withSchemaValue:(id)schemeValue
//{
//    if ([schemeValue isKindOfClass:[NSDictionary class]]) {
//        return [self parseObject:dataValue withSchemaDictionary:schemeValue];
//    } else if ([schemeValue isKindOfClass:[NSArray class]]) {
//        return [self parseArray:dataValue withItemSchema:[schemeValue firstObject]];
//    } else if (self.registry && [schemeValue isKindOfClass:[NSString class]]) {
//        return [self convertValue:dataValue toType:schemeValue];
//    } else {
//        return dataValue;
//    }
//}
//
//- (id)parseArray:(NSArray *)array withItemSchema:(id)itemSchema
//{
//    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:array.count];
//
//    for (id item in array) {
//        id convertedItem = [self parseValue:item withSchemaValue:itemSchema];
//        if (convertedItem) {
//            [result addObject:convertedItem];
//        }
//    }
//
//    return result;
//}
//
//- (id)parseObject:(id)object withSchemaDictionary:(NSDictionary *)schemeDict
//{
//    if (_convertingForRequest) {
//        return [self composeRequestDictionary:object withSchemaDictionary:schemeDict];
//    } else {
//        return [self parseResponseDictionary:object withSchemaDictionary:schemeDict];
//    }
//}

//- (id)composeRequestDictionary:(id)object withSchemaDictionary:(NSDictionary *)schemeDict
//{
//    NSDictionary *dictionary = object;
//
//    NSString *converterTag = schemeDict[TRCConverterNameKey];
//    TRCSchema *customSchema = [_registry requestSchemaForMapperWithTag:converterTag];
//
//    id result = nil;
//
//    if (converterTag) {
//        dictionary = [self mapObject:object intoDictionaryUsingMapperTag:converterTag];
//    } else if (![object isKindOfClass:[NSDictionary class]]) {
//        dictionary = @{};
//        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Can't compose dictionary from %@, {mapper} tag missing", [object class]], _data, _schemaName, !_convertingForRequest)];
//    }
//
//    if (converterTag && customSchema) {
//        NSError *error = nil;
//        result = [_registry convertValuesInRequest:dictionary schema:customSchema error:&error];
//        if (error) {
//            [self.internalErrors addObject:error];
//            result = nil;
//        }
//    } else {
//        result = [self parseDictionary:dictionary withSchemaDictionary:schemeDict];
//    }
//
//    return result;
//}

//- (id)parseResponseDictionary:(id)object withSchemaDictionary:(NSDictionary *)schemeDict
//{
//    NSDictionary *dictionary = object;
//    NSString *converterTag = schemeDict[TRCConverterNameKey];
//    TRCSchema *customSchema = [_registry requestSchemaForMapperWithTag:converterTag];
//
//    id result = nil;
//
//    if (converterTag && customSchema) {
//        NSError *convertError = nil;
//        result = [_registry convertValuesInResponse:dictionary schema:customSchema error:&convertError];
//        if (convertError) {
//            [self.internalErrors addObject:convertError];
//            result = nil;
//        }
//    } else {
//        result = [self parseDictionary:dictionary withSchemaDictionary:schemeDict];
//    }
//
//    if (converterTag) {
//        result = [self mapDictionary:result intoObjectUsingTag:converterTag];
//    }
//
//    return result;
//}

//- (id)parseDictionary:(NSDictionary *)dictionary withSchemaDictionary:(NSDictionary *)schemaDict
//{
//    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:[dictionary count]];
//
//    [schemaDict enumerateKeysAndObjectsUsingBlock:^(NSString *schemaKey, id schemaValue, BOOL *stop) {
//        if (![schemaKey isEqualToString:TRCConverterNameKey]) {
//            BOOL isOptional;
//            NSString *key = TRCKeyFromOptionalKey(schemaKey, &isOptional);
//            id dataValue = dictionary[key];
//
//            //Handle NSNull case
//            if ([dataValue isKindOfClass:[NSNull class]]) {
//                dataValue = nil;
//            }
//
//            dataValue = TRCValueAfterApplyingOptions(dataValue, self.options, _convertingForRequest, isOptional);
//
//            if (dataValue) {
//                id converted = [self parseValue:dataValue withSchemaValue:schemaValue];
//                if (converted) {
//                    result[key] = converted;
//                }
//            } else if (!isOptional) {
//                [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Can't find value for key '%@'", key], _data, _schemaName, !_convertingForRequest)];
//            }
//        }
//    }];
//
//    [result addEntriesFromDictionary:[self entriesFromDictionary:dictionary missedInScheme:schemaDict]];
//
//    return result;
//}

//- (NSDictionary *)entriesFromDictionary:(NSDictionary *)dictionary missedInScheme:(NSDictionary *)schemaDict
//{
//    TRCValidationOptions optionToCheck = _convertingForRequest ? TRCValidationOptionsRemoveValuesMissedInSchemeForRequests : TRCValidationOptionsRemoveValuesMissedInSchemeForResponses;
//
//    if (!(self.options & optionToCheck)) {
//        NSMutableSet *schemeKeys = [NSMutableSet new];
//        for (NSString *key in [schemaDict allKeys]) {
//            [schemeKeys addObject:TRCKeyFromOptionalKey(key, NULL)];
//        }
//        NSMutableSet *dictionaryKeys = [NSMutableSet setWithArray:[dictionary allKeys]];
//        [dictionaryKeys minusSet:schemeKeys];
//
//        NSMutableDictionary *entries = [[NSMutableDictionary alloc] initWithCapacity:[dictionaryKeys count]];
//        for (id key in dictionaryKeys) {
//            entries[key] = dictionary[key];
//        }
//        return entries;
//    } else {
//        return @{};
//    }
//}
//
//- (id)mapDictionary:(NSDictionary *)dictionary intoObjectUsingTag:(NSString *)tag
//{
//    NSParameterAssert(tag);
//    NSParameterAssert(self.registry);
//    id <TRCObjectMapper>converter = [self.registry objectMapperForTag:tag];
//    if (!converter) {
//        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Can't find converter for tag '%@'", tag], _data, _schemaName, !_convertingForRequest)];
//        return nil;
//    }
//    NSError *error = nil;
//    id result = nil;
//
//    if ([converter respondsToSelector:@selector(objectFromDictionary:error:)]) {
//        result = [converter objectFromDictionary:dictionary error:&error];
//        if (error) {
//            [self.internalErrors addObject:error];
//            result = nil;
//        }
//    } else {
//        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Converter for tag '%@' (Class: %@) not responds to 'objectFromDictionary:error:'", tag, [converter class]], _data, _schemaName, !_convertingForRequest)];
//    }
//
//    return result;
//}
//
//- (NSDictionary *)mapObject:(id)object intoDictionaryUsingMapperTag:(NSString *)tag
//{
//    NSParameterAssert(tag);
//    NSParameterAssert(self.registry);
//    id <TRCObjectMapper>converter = [self.registry objectMapperForTag:tag];
//    if (!converter) {
//        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Can't find converter for tag '%@'", tag], _data, _schemaName, !_convertingForRequest)];
//        return nil;
//    }
//    NSError *error = nil;
//    NSDictionary *result = nil;
//    if ([converter respondsToSelector:@selector(dictionaryFromObject:error:)]) {
//        result = [converter dictionaryFromObject:object error:&error];
//        if (error) {
//            [self.internalErrors addObject:error];
//            result = nil;
//        }
//    } else {
//        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Converter for tag '%@' (Class: %@) not responds to 'dictionaryFromObject:error:'", tag, [converter class]], _data, _schemaName, !_convertingForRequest)];
//    }
//
//    return result;
//}

//-------------------------------------------------------------------------------------------
#pragma mark - TRCSchemaData Modifier
//-------------------------------------------------------------------------------------------

- (id)schemaData:(id<TRCSchemaData>)data replacementForValue:(id)object withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue
{
    if (object && self.registry && [schemeValue isKindOfClass:[NSString class]]) {
        return [self convertValue:object toType:schemeValue];
    } else {
        return object;
    }
}

- (id)schemaData:(id<TRCSchemaData>)data objectFromResponse:(id)object withMapperTag:(NSString *)tag
{
    NSParameterAssert(tag);
    NSParameterAssert(self.registry);
    id <TRCObjectMapper>converter = [self.registry objectMapperForTag:tag];
    if (!converter) {
        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Can't find converter for tag '%@'", tag], object, self.schema.name, !_convertingForRequest)];
        return nil;
    }
    NSError *error = nil;
    id result = nil;

    if ([converter respondsToSelector:@selector(objectFromDictionary:error:)]) {
        result = [converter objectFromDictionary:object error:&error];
        if (error) {
            [self.internalErrors addObject:error];
            result = nil;
        }
    } else {
        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Converter for tag '%@' (Class: %@) not responds to 'objectFromDictionary:error:'", tag, [converter class]], object, self.schema.name, !_convertingForRequest)];
    }

    return result;
}

- (id)schemaData:(id<TRCSchemaData>)data requestFromObject:(id)object withMapperTag:(NSString *)tag
{
    NSParameterAssert(tag);
    NSParameterAssert(self.registry);
    id <TRCObjectMapper>converter = [self.registry objectMapperForTag:tag];
    if (!converter) {
        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Can't find converter for tag '%@'", tag], object, self.schema.name, !_convertingForRequest)];
        return nil;
    }
    NSError *error = nil;
    NSDictionary *result = nil;
    if ([converter respondsToSelector:@selector(dictionaryFromObject:error:)]) {
        result = [converter dictionaryFromObject:object error:&error];
        if (error) {
            [self.internalErrors addObject:error];
            result = nil;
        }
    } else {
        [self.internalErrors addObject:TRCConversionErrorForObject([NSString stringWithFormat:@"Converter for tag '%@' (Class: %@) not responds to 'dictionaryFromObject:error:'", tag, [converter class]], object, self.schema.name, !_convertingForRequest)];
    }

    return result;
}

- (void)schemaData:(id<TRCSchemaData>)data typeMismatchForValue:(id)value withSchemaValue:(id)schemaValue
{
    NSError *error = TRCConversionErrorForObject([NSString stringWithFormat:@"Object of type '%@' doesn't match type '%@'", [value class], [schemaValue class]], value, self.schema.name, _convertingForRequest);
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

@end