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
    BOOL _isStopped;
    id _delegate;
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
        _isStopped = NO;
        _delegate = delegate;
        [self enumerateObject:object withSchemeObject:_schemeValue result:result];
    }
}

- (void)stop
{
    @synchronized (self) {
        _isStopped = YES;
        _delegate = nil;
    }
}

- (void)enumerateObject:(id)object withSchemeObject:(id)schemeObject result:(id *)result
{
    if ([schemeObject isKindOfClass:[NSArray class]]) {
        [self enumerateArray:object withSchemeArray:schemeObject result:result];
    } else if ([schemeObject isKindOfClass:[NSDictionary class]]) {
        [self enumerateDictionary:object withSchemeDictionary:schemeObject result:result];
    } else {
        [self notifyObject:object withSchemeObject:schemeObject replacement:result];
    };
}

- (void)enumerateArray:(NSArray *)array withSchemeArray:(NSArray *)schemeArray result:(id *)result
{
    NSMutableArray *resultArray = nil;
    if (result) {
        resultArray = [[NSMutableArray alloc] initWithCapacity:[array count]];
        *result = resultArray;
    }

    id schemeObject = schemeArray;

    [self notifyCollectionStart:array];

    [array enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
        if (_isStopped) {
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
    NSMutableDictionary *resultDictionary = nil;
    if (result) {
        resultDictionary = [[NSMutableDictionary alloc] initWithCapacity:[dictionary count]];
        *result = resultDictionary;
    }

    NSMutableSet *allKeys = [NSMutableSet setWithArray:[dictionary allKeys]];

    [self notifyCollectionStart:dictionary];

    for (NSString *schemaKey in [schemeDictionary allKeys]) {
        if (_isStopped) {
            break;
        }
        [self notifyEnumeratingItemStart:schemaKey];

        NSString *unwrappedKey = TRCKeyFromOptionalKey(schemaKey, NULL);
        id schemaObject = schemeDictionary[schemaKey];
        id object = dictionary[unwrappedKey];
        [allKeys removeObject:unwrappedKey];

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

    for (NSString *missingKey in allKeys) {
        if (_isStopped) {
            break;
        }
        [self notifyEnumeratingItemStart:missingKey];

        id schemaObject = nil;
        id object = dictionary[missingKey];

        if (resultDictionary) {
            id itemResult = nil;
            [self enumerateObject:object withSchemeObject:schemaObject result:&itemResult];
            if (itemResult) {
                resultDictionary[missingKey] = itemResult;
            }
        } else {
            [self enumerateObject:object withSchemeObject:schemaObject result:NULL];
        }

        [self notifyEnumeratingItemEnd:missingKey];
    }

    [self notifyCollectionEnd:dictionary];
}

- (void)notifyCollectionStart:(id)collection
{
    [_delegate schemaData:self willEnumerateCollection:collection];
}

- (void)notifyCollectionEnd:(id)collection
{
    [_delegate schemaData:self didEnumerateCollection:collection];
}

- (void)notifyEnumeratingItemStart:(id)itemId
{
    [_delegate schemaData:self willEnumerateItemAtIndentifier:itemId];
}

- (void)notifyEnumeratingItemEnd:(id)itemId
{
    [_delegate schemaData:self didEnumerateItemAtIndentifier:itemId];
}

- (void)notifyObject:(id)object withSchemeObject:(id)schemeObject replacement:(id *)replacement
{
    id result = object;
    [_delegate schemaData:self foundValue:object withSchemeValue:schemeObject replacement:&result];
    if (replacement) {
        *replacement = result;
    }
}


@end