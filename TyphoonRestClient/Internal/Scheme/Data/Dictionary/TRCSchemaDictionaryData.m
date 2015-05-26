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

#import "TRCSchemaDictionaryData.h"
#import "TRCUtils.h"

@implementation TRCSchemaDictionaryData
{
    id _schemeValue;
    BOOL _isCancelled;
    id<TRCSchemaDataEnumerator> _enumerator;
    id<TRCSchemaDataModifier> _modifier;
}

- (instancetype)initWithArrayOrDictionary:(id)arrayOrDictionary request:(BOOL)isRequest dataProvider:(id<TRCSchemaDataProvider>)dataProvider
{
    if (!arrayOrDictionary) {
        return nil;
    } else {
        self = [super init];
        if (self) {
            _dataProvider = dataProvider;
            _requestData = isRequest;


            NSString *rootMapperKey = nil;
            if ([arrayOrDictionary isKindOfClass:[NSDictionary class]]) {
                rootMapperKey = arrayOrDictionary[TRCRootMapperKey];
            }
            if (rootMapperKey.length > 0 && [self.dataProvider schemaData:self hasObjectMapperForTag:rootMapperKey]) {
                _schemeValue = rootMapperKey;
            } else {
                _schemeValue = arrayOrDictionary;
            }
        }
        return self;
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Main API
//-------------------------------------------------------------------------------------------

- (void)enumerate:(id)object withEnumerator:(id<TRCSchemaDataEnumerator>)enumerator
{
    @synchronized (self) {
        [self clearState];
        _enumerator = enumerator;
        [self enumerateObject:object withIdentifier:nil withSchemeObject:_schemeValue result:NULL];
    }
}

- (id)modify:(id)object withModifier:(id<TRCSchemaDataModifier>)modifier
{
    @synchronized (self) {
        [self clearState];
        _modifier = modifier;
        id result = nil;
        [self enumerateObject:object withIdentifier:nil withSchemeObject:_schemeValue result:&result];
        return result;
    }
}

- (void)clearState
{
    _modifier = nil;
    _enumerator = nil;
    _isCancelled = NO;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Cancel
//-------------------------------------------------------------------------------------------

- (void)cancel
{
    @synchronized (self) {
        _enumerator = nil;
        _isCancelled = YES;
    }
}

- (BOOL)isCancelled
{
    return _isCancelled;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Enumeration
//-------------------------------------------------------------------------------------------

- (void)enumerateObject:(id)object withIdentifier:(id)identifier withSchemeObject:(id)schemeObject result:(id *)result
{
    if (_isCancelled) {
        return;
    }

    if (!object || [object isKindOfClass:[NSNull class]]) {
        [self notifyObject:object withIdentifier:identifier withSchemeObject:schemeObject replacement:result];
    } else if ([self isMapperName:schemeObject]) {
        [self enumerateObject:object withMapperName:schemeObject result:result];
    } else if ([schemeObject isKindOfClass:[NSArray class]]) {
        [self enumerateArray:object withSchemeArray:schemeObject result:result];
    } else if ([schemeObject isKindOfClass:[NSDictionary class]]) {
        [self enumerateDictionary:object withSchemeDictionary:schemeObject result:result];
    } else {
        [self notifyObject:object withIdentifier:identifier withSchemeObject:schemeObject replacement:result];
    }
}

- (BOOL)isMapperName:(id)object
{
    return [object isKindOfClass:[NSString class]] && [self.dataProvider schemaData:self hasObjectMapperForTag:object];
}

- (void)enumerateObject:(id)object withMapperName:(NSString *)name result:(id *)result
{
    if (result) {
        *result = object;
    }

    //Map Request Model Objects in NSDictionary
    if ([self isRequestData] && _modifier && result) {
        *result = [_modifier schemaData:self requestFromObject:*result withMapperTag:name];
        object = *result;
    }

    //Only NSDictionary can be used for mappers
    if (![object isKindOfClass:[NSDictionary class]]) {
        [self notifyFail:object withSchemaObject:[NSDictionary new]];
        [self cancel];
        return;
    }

    id<TRCSchemaData> child = nil;
    if ([self isRequestData]) {
        child = [self.dataProvider schemaData:self requestSchemaForMapperWithTag:name];
    } else {
        child = [self.dataProvider schemaData:self responseSchemaForMapperWithTag:name];
    }

    //Process value transformers and sub-schemes
    if (child) {
        if (result && _modifier) {
            *result = [child modify:*result withModifier:_modifier];
        }
        if (_enumerator) {
            [child enumerate:object withEnumerator:_enumerator];
        }
        _isCancelled = [child isCancelled];
    }

    //Map Response NSDictionary into Model Objects
    if (![self isRequestData] && _modifier && result) {
        *result = [_modifier schemaData:self objectFromResponse:*result withMapperTag:name];
    }
}

- (void)enumerateArray:(NSArray *)array withSchemeArray:(NSArray *)schemeArray result:(id *)result
{
    if (![array isKindOfClass:[NSArray class]]) {
        [self notifyFail:array withSchemaObject:schemeArray];
        [self cancel];
        return;
    }

    NSMutableArray *resultArray = nil;
    if (result) {
        resultArray = [[NSMutableArray alloc] initWithCapacity:[array count]];
        *result = resultArray;
    }

    id schemeObject = [schemeArray firstObject];

    [array enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        if (_isCancelled) {
            *stop = YES;
        } else {
            NSNumber *index = @(idx);
            [self notifyEnumeratingItemStart:index];

            if (resultArray) {
                id itemResult = nil;
                [self enumerateObject:object withIdentifier:index withSchemeObject:schemeObject result:&itemResult];
                if (itemResult) {
                    [resultArray addObject:itemResult];
                }
            } else {
                [self enumerateObject:object withIdentifier:index withSchemeObject:schemeObject result:NULL];
            }

            [self notifyEnumeratingItemEnd:index];
        }
    }];
}

- (void)enumerateDictionary:(NSDictionary *)dictionary withSchemeDictionary:(NSDictionary *)schemeDictionary result:(id *)result
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        [self notifyFail:dictionary withSchemaObject:schemeDictionary];
        [self cancel];
        return;
    }

    NSMutableDictionary *resultDictionary = nil;
    if (result) {
        resultDictionary = [[NSMutableDictionary alloc] initWithCapacity:[dictionary count]];
        *result = resultDictionary;
    }

    NSMutableSet *keysToEnumerate = [NSMutableSet setWithArray:[schemeDictionary allKeys]];
    NSMutableSet *keysMissingInScheme = [NSMutableSet setWithArray:[dictionary allKeys]];
    for (NSString *schemaKey in keysToEnumerate) {
        [keysMissingInScheme removeObject:TRCKeyFromOptionalKey(schemaKey, NULL)];
    }
    [keysToEnumerate unionSet:keysMissingInScheme];

    for (NSString *schemaKey in keysToEnumerate) {
        if (_isCancelled) {
            break;
        }

        NSString *unwrappedKey = TRCKeyFromOptionalKey(schemaKey, NULL);
        id schemaObject = schemeDictionary[schemaKey];
        id object = dictionary[unwrappedKey];

        [self notifyEnumeratingItemStart:unwrappedKey];


        if (resultDictionary) {
            id itemResult = nil;
            [self enumerateObject:object withIdentifier:schemaKey withSchemeObject:schemaObject result:&itemResult];
            //Check NSNull case
            if (itemResult) {
                resultDictionary[unwrappedKey] = itemResult;
            }
        } else {
            [self enumerateObject:object withIdentifier:schemaKey withSchemeObject:schemaObject result:NULL];
        }

        [self notifyEnumeratingItemEnd:unwrappedKey];
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Notifying
//-------------------------------------------------------------------------------------------

- (void)notifyEnumeratingItemStart:(id)itemId
{
    if ([_enumerator respondsToSelector:@selector(schemaData:willEnumerateItemAtIndentifier:)]) {
        [_enumerator schemaData:self willEnumerateItemAtIndentifier:itemId];
    }
}

- (void)notifyEnumeratingItemEnd:(id)itemId
{
    if ([_enumerator respondsToSelector:@selector(schemaData:didEnumerateItemAtIndentifier:)]) {
        [_enumerator schemaData:self didEnumerateItemAtIndentifier:itemId];
    }
}

- (void)notifyFail:(id)object withSchemaObject:(id)schemaObject
{
    [_enumerator schemaData:self typeMismatchForValue:object withSchemaValue:schemaObject];
}

- (void)notifyObject:(id)object withIdentifier:(id)identifier withSchemeObject:(id)schemeObject replacement:(id *)replacement
{
    BOOL isOptional = NO;
    if ([identifier isKindOfClass:[NSString class]]) {
        identifier = TRCKeyFromOptionalKey(identifier, &isOptional);
    }

    TRCSchemaDataValueOptions *options = [TRCSchemaDataValueOptions new];
    options.identifier = identifier;
    options.optional = isOptional;

    if (_enumerator) {
        [_enumerator schemaData:self foundValue:object withOptions:options withSchemeValue:schemeObject];
    }
    if (replacement && _modifier) {
        *replacement = [_modifier schemaData:self replacementForValue:object withOptions:options withSchemeValue:schemeObject];
    }
}

@end