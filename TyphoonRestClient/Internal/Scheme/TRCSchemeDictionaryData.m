////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import "TRCSchemeDictionaryData.h"
#import "TRCUtils.h"


@implementation TRCSchemeDictionaryData
{
    id _schemeValue;
    BOOL _isCancelled;
    id<TRCSchemaDataEnumerator> _enumerator;
    id<TRCSchemaDataModifier> _modifier;
}

- (instancetype)initWithArrayOrDictionary:(id)arrayOrDictionary
{
    self = [super init];
    if (self) {
        _schemeValue = arrayOrDictionary;
    }
    return self;
}

- (void)process:(id)object into:(id *)result withDelegate:(id)delegate
{
    @synchronized (self) {
        _isCancelled = NO;
        _enumerator = delegate;
        [self enumerateObject:object withSchemeObject:_schemeValue result:result];
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Main API
//-------------------------------------------------------------------------------------------

- (void)enumerate:(id)object withEnumerator:(id<TRCSchemaDataEnumerator>)enumerator
{

}

- (id)modify:(id)object withModifier:(id<TRCSchemaDataModifier>)modifier
{
    _modifier = modifier;


    return nil;
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

- (void)enumerateObject:(id)object withSchemeObject:(id)schemeObject result:(id *)result
{
    if (_isCancelled) {
        return;
    }

    if ([self isSubSchemaName:schemeObject]) {
        [self enumerateObject:object withSchemaName:schemeObject result:result];
    } else if ([schemeObject isKindOfClass:[NSArray class]]) {
        [self enumerateArray:object withSchemeArray:schemeObject result:result];
    } else if ([schemeObject isKindOfClass:[NSDictionary class]]) {
        [self enumerateDictionary:object withSchemeDictionary:schemeObject result:result];
    } else {
        [self notifyObject:object withSchemeObject:schemeObject replacement:result];
    }
}

- (BOOL)isSubSchemaName:(id)object
{
    return [object isKindOfClass:[NSString class]] && [self.dataProvider schemaData:self hasObjectMapperForTag:object];
}

- (void)enumerateObject:(id)object withSchemaName:(NSString *)name result:(id *)result
{
    if (result) {
        *result = object;
    }

    //Map Request Model Objects in NSDictionary
    if ([self isRequestData] && _modifier && result) {
        *result = [_modifier schemaData:self unmapObject:*result withMapperTag:name];
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
        } else {
            [child enumerate:object withEnumerator:_enumerator];
        }
        _isCancelled = [child isCancelled];
    }

    //Map Response NSDictionary into Model Objects
    if (![self isRequestData] && _modifier && result) {
        *result = [_modifier schemaData:self mapObject:*result withMapperTag:name];
    }
}

- (void)enumerateArray:(NSArray *)array withSchemeArray:(NSArray *)schemeArray result:(id *)result
{
    [self notifyCollectionStart:array];

    if (![array isKindOfClass:[NSArray class]]) {
        [self notifyFail:array withSchemaObject:schemeArray];
        [self notifyCollectionEnd:array];
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
                [self enumerateObject:object withSchemeObject:schemeObject result:&itemResult];
                if (itemResult) {
                    [resultArray addObject:itemResult];
                }
            } else {
                [self enumerateObject:object withSchemeObject:schemeObject result:NULL];
            }

            [self notifyEnumeratingItemEnd:index];
        }
    }];

    [self notifyCollectionEnd:array];
}

- (void)enumerateDictionary:(NSDictionary *)dictionary withSchemeDictionary:(NSDictionary *)schemeDictionary result:(id *)result
{
    [self notifyCollectionStart:dictionary];


    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        [self notifyFail:dictionary withSchemaObject:schemeDictionary];
        [self notifyCollectionEnd:dictionary];
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
        [self notifyEnumeratingItemStart:schemaKey];

        NSString *unwrappedKey = TRCKeyFromOptionalKey(schemaKey, NULL);
        id schemaObject = schemeDictionary[schemaKey];
        id object = dictionary[unwrappedKey];

        if (resultDictionary) {
            id itemResult = nil;
            [self enumerateObject:object withSchemeObject:schemaObject result:&itemResult];
            if (itemResult) {
                resultDictionary[unwrappedKey] = itemResult;
            }
        } else {
            [self enumerateObject:object withSchemeObject:schemaObject result:NULL];
        }

        [self notifyEnumeratingItemEnd:schemaKey];
    }

    [self notifyCollectionEnd:dictionary];
}

- (void)notifyCollectionStart:(id)collection
{
    [_enumerator schemaData:self willEnumerateCollection:collection];
}

- (void)notifyCollectionEnd:(id)collection
{
    [_enumerator schemaData:self didEnumerateCollection:collection];
}

- (void)notifyEnumeratingItemStart:(id)itemId
{
    [_enumerator schemaData:self willEnumerateItemAtIndentifier:itemId];
}

- (void)notifyEnumeratingItemEnd:(id)itemId
{
    [_enumerator schemaData:self didEnumerateItemAtIndentifier:itemId];
}

- (void)notifyFail:(id)object withSchemaObject:(id)schemaObject
{
    [_enumerator schemaData:self failPorcessingValue:object withSchemaValue:schemaObject];
}

- (void)notifyObject:(id)object withSchemeObject:(id)schemeObject replacement:(id *)replacement
{
    id result = object;
    [_enumerator schemaData:self foundValue:object withSchemeValue:schemeObject replacement:&result];
    if (replacement) {
        *replacement = result;
    }
}

@end