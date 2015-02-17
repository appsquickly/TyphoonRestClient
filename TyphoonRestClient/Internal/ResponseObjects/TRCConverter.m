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
#import "TRCValueConverterRegistry.h"
#import "TRCValueConverter.h"
#import "TyphoonRestClient.h"

@interface TRCConverter ()
@property (nonatomic, strong) NSMutableOrderedSet *internalErrors;
@end

@implementation TRCConverter
{
    id schema;
    id data;
    BOOL convertingForRequest;
    NSString *schemaName;
}

- (instancetype)initWithResponseValue:(id)arrayOrDictionary schemaValue:(id)schemaArrayOrDictionary schemaName:(NSString *)name
{
    self = [super init];
    if (self) {
        data = arrayOrDictionary;
        schema = schemaArrayOrDictionary;
        self.internalErrors = [NSMutableOrderedSet new];
        convertingForRequest = NO;
        schemaName = name;
    }
    return self;
}

- (instancetype)initWithRequestValue:(id)arrayOrDictionary schemaValue:(id)schemaArrayOrDictionary schemaName:(NSString *)name
{
    self = [super init];
    if (self) {
        data = arrayOrDictionary;
        schema = schemaArrayOrDictionary;
        self.internalErrors = [NSMutableOrderedSet new];
        convertingForRequest = YES;
        schemaName = name;
    }
    return self;
}

- (id)convertValues
{
    return [self parseValue:data withSchemaValue:schema];
}

- (NSError *)conversionError
{
    return NSErrorFromErrorSet(self.internalErrors, @"parsing");
}

- (NSOrderedSet *)conversionErrorSet
{
    return self.internalErrors;
}

- (id)parseValue:(id)dataValue withSchemaValue:(id)schemeValue
{
    if ([schemeValue isKindOfClass:[NSDictionary class]]) {
        return [self parseDictionary:dataValue withSchemaDictionary:schemeValue];
    } else if ([schemeValue isKindOfClass:[NSArray class]]) {
        return [self parseArray:dataValue withItemSchema:[schemeValue firstObject]];
    } else if (self.registry && [schemeValue isKindOfClass:[NSString class]]) {
        return [self convertValue:dataValue toType:schemeValue];
    } else {
        return dataValue;
    }
}

- (id)convertValue:(id)dataValue toType:(NSString *)typeName
{
    NSParameterAssert(self.registry);

    NSError *convertError = nil;
    id result = dataValue;
    id<TRCValueConverter>typeConverter = [self.registry valueConverterForTag:typeName];

    if (typeConverter) {
        if (convertingForRequest) {
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

- (id)parseArray:(NSArray *)array withItemSchema:(id)itemSchema
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:array.count];

    for (id item in array) {
        id convertedItem = [self parseValue:item withSchemaValue:itemSchema];
        if (convertedItem) {
            [result addObject:convertedItem];
        }
    }

    return result;
}

- (id)parseDictionary:(NSDictionary *)dictionary withSchemaDictionary:(NSDictionary *)schemaDict
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:[dictionary count]];

    [schemaDict enumerateKeysAndObjectsUsingBlock:^(NSString *schemaKey, id schemaValue, BOOL *stop) {
        BOOL isOptional;
        NSString *key = KeyFromOptionalKey(schemaKey, &isOptional);
        id dataValue = dictionary[key];

        //Handle NSNull case
        if ([dataValue isKindOfClass:[NSNull class]]) {
            dataValue = nil;
        }

        dataValue = ValueAfterApplyingOptions(dataValue, self.options, convertingForRequest, isOptional);

        if (dataValue) {
            id converted = [self parseValue:dataValue withSchemaValue:schemaValue];
            if (converted) {
                result[key] = converted;
            }
        } else if (!isOptional) {
            [self.internalErrors addObject:NSErrorWithFormat(@"ValidationError: Can't find value for key '%@'. Schema: %@, Original object: %@", key, schemaName, dictionary)];
        }
    }];

    return result;
}

@end