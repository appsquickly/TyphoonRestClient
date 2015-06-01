//
//  TRCSchemeTests.m
//  Iconic
//
//  Created by Aleksey Garbarev on 19.09.14.
//  Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRCSchema.h"
#import "TRCRequest.h"
#import "TRCConvertersRegistry.h"
#import "TRCUtils.h"
#import "TRCConverter.h"
#import "TRCValueTransformer.h"
#import "TRCValueTransformerStub.h"
#import "TRCMapperPerson.h"
#import "Person.h"
#import "Phone.h"
#import "TRCMapperPhone.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCSerializerJson.h"
#import "TestUtils.h"
#import "TRCMapperWithArray.h"

@interface TRCConverterTests : XCTestCase<TRCConvertersRegistry, TRCSchemaDataProvider>

@end

@implementation TRCConverterTests {
    TRCValidationOptions validationOptions;
}

- (void)setUp
{
    validationOptions = TRCValidationOptionsNone;
    [super setUp];
}


- (void)enumerateTransformerTypesWithClasses:(void (^)(TRCValueTransformerType type, Class clazz, BOOL *stop))block
{
    static NSDictionary *typesRegistry = nil;
    if (!typesRegistry) {
        typesRegistry = @{
                @(TRCValueTransformerTypeNumber): [NSNumber class],
                @(TRCValueTransformerTypeString): [NSString class]
        };
    }

    [typesRegistry enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        block([key integerValue], obj, stop);
    }];
}

- (id<TRCValueTransformer>)valueTransformerForTag:(NSString *)type
{
    TRCValueTransformerStub *stub = [TRCValueTransformerStub new];
    stub.supportedTypes = TRCValueTransformerTypeString;

    if ([type isEqualToString:@"NSURL"]) {
        stub.object = @"Url";
        stub.value = @"Url";
    } else if ([type isEqualToString:@"{url}"]) {
        stub.object = [[NSURL alloc] initWithString:@"http://appsquick.ly"];
        stub.value = [[NSURL alloc] initWithString:@"http://appsquick.ly"];
    } else if ([type isEqualToString:@"NSDate"]) {
        stub.object = @"Date";
        stub.supportedTypes = TRCValueTransformerTypeNumber | TRCValueTransformerTypeString;
    } else if ([type isEqualToString:@"NSObject"]) {
        stub.error = NSErrorWithFormat(@"Can't convert NSObject type");
    } else {
        return nil;
    }
    return stub;
}

- (id<TRCObjectMapper>)objectMapperForTag:(NSString *)tag
{
    if ([tag isEqualToString:@"test"]) {
        return [TRCMapperPerson new];
    } else if ([tag isEqualToString:@"test_without_response"]) {
        TRCMapperPerson *mapper = [TRCMapperPerson new];
        mapper.responseParsingImplemented = NO;
        return mapper;
    } else if ([tag isEqualToString:@"test_without_request"]) {
        TRCMapperPerson *mapper = [TRCMapperPerson new];
        mapper.requestParsingImplemented = NO;
        return mapper;
    } else if ([tag isEqualToString:@"{person}"]) {
        return [TRCMapperPerson new];
    } else if ([tag isEqualToString:@"{phone}"]) {
        return [TRCMapperPhone new];
    } else if ([tag isEqualToString:@"{person-cant-laod}"]) {
        return nil;
    } else if ([tag isEqualToString:@"{array}"]) {
        return [TRCMapperWithArray new];
    } else {
        return nil;
    };
}

- (id<TRCValidationErrorPrinter>)validationErrorPrinterForExtension:(NSString *)extension
{
    return nil;
}

- (BOOL)schemaData:(id<TRCSchemaData>)data hasObjectMapperForTag:(NSString *)schemaName
{
    if ([schemaName isEqualToString:@"{person-cant-laod}"]) {
        return YES;
    } else {
        return  [self objectMapperForTag:schemaName] != nil;
    }
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data requestSchemaForMapperWithTag:(NSString *)schemaName
{
    id<TRCSchemaData>result = nil;
    NSString *name = nil;

    if ([schemaName isEqualToString:@"{person}"]) {
        name = @"TRCMapperPerson.json";
    } else if ([schemaName isEqualToString:@"{phone}"]) {
        name = @"TRCMapperPhone.json";
    } else if ([schemaName isEqualToString:@"{array}"]) {
        name = @"TRCMapperWithArray.json";
    }

    if (name) {
        TRCSerializerJson *jsonSerializer = [TRCSerializerJson new];
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:nil];
        result = [jsonSerializer responseSchemaDataFromData:[NSData dataWithContentsOfFile:path] dataProvider:self error:nil];
    }
    return result;
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data responseSchemaForMapperWithTag:(NSString *)schemaName
{
    return [self schemaData:data requestSchemaForMapperWithTag:schemaName];
}

+ (void)setUp
{
    TRCValueTransformerTypeNumber = 1 << 0;
    TRCValueTransformerTypeString = 1 << 1;
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (id)convertResponseObject:(id)data schema:(id)schemaArrayOrDictionary error:(NSError **)error
{
    TRCSchemaDictionaryData *schemeData = [[TRCSchemaDictionaryData alloc] initWithArrayOrDictionary:schemaArrayOrDictionary request:NO dataProvider:self];
    TRCSchema *schema = [TRCSchema schemaWithData:schemeData name:@"test"];
    if (!schema) {
        return data;
    }
    TRCConverter *converter = [[TRCConverter alloc] initWithSchema:schema];
    converter.options = validationOptions;
    converter.registry = self;

    return [converter convertResponseValue:data error:error];
}

- (id)convertRequestObject:(id)data schema:(id)schemaArrayOrDictionary error:(NSError **)error
{
    TRCSchemaDictionaryData *schemeData = [[TRCSchemaDictionaryData alloc] initWithArrayOrDictionary:schemaArrayOrDictionary request:YES dataProvider:self];
    TRCSchema *schema = [TRCSchema schemaWithData:schemeData name:@"test"];
    if (!schema) {
        return data;
    }
    TRCConverter *converter = [[TRCConverter alloc] initWithSchema:schema];
    converter.options = validationOptions;
    converter.registry = self;
    
    return [converter convertRequestValue:data error:error];
}

- (void)test_request_with_conversion
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @"123"};
    NSDictionary *schema = @{@"key" : @"value", @"key2" : @"NSURL"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertRequestObject:data schema:schema error:&conversionError];

    XCTAssertTrue(conversionError == nil);
    XCTAssertEqualObjects(object[@"key2"], @"Url");
}

- (void)test_plain_dictionary_with_schema
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @23};
    NSDictionary *schema = @{@"key" : @"value", @"key2" : @12};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssertTrue([object[@"key"] isEqualToString:@"value"]);
    XCTAssertTrue([object[@"key2"] isEqualToNumber:@23]);
    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_plain_dictionary_without_schema
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @23};

    NSError *conversionError;
    NSDictionary *object = [self convertResponseObject:data schema:nil error:&conversionError];

    XCTAssertTrue([[object objectForKey:@"key"] isEqualToString:@"value"]);
    XCTAssertTrue([[object objectForKey:@"key2"] isEqualToNumber:@23]);
    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_plain_dictionary_with_schema_and_converting
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2" : @"NSDate"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssertTrue([object[@"key"] isEqualToString:@"Url"]);
    XCTAssertTrue([object[@"key2"] isEqual:@"Date"]);
    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_plain_dictionary_with_schema_and_converting_incorrect_class
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2": @"NSObject"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssertTrue([[object objectForKey:@"key"] isEqualToString:@"Url"]);
    XCTAssertTrue([object objectForKey:@"key2"] == nil);
    XCTAssertTrue(conversionError != nil, @"Error: %@", conversionError);
}

- (void)test_plain_dictionary_with_schema_and_converting_unknown_class
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2" : @"UnknownClass"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssertTrue([object[@"key"] isEqualToString:@"Url"]);
    XCTAssertTrue([object[@"key2"] isEqual:@12]);
    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_plain_dictionary_with_schema_and_converting_dict_repr
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2" : @"NSDate"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    NSDictionary *expect = @{@"key" : @"Url", @"key2" : @"Date"};
    XCTAssertEqualObjects(object, expect);
    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_plain_dictionary_without_schema_and_converting_dict_repr
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil error:&conversionError];

    NSDictionary *expect = @{@"key" : @"value", @"key2" : @12};
    XCTAssertEqualObjects(object, expect);
    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_nested_object_with_schema
{
    NSDictionary *data = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};
    NSDictionary *schema = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    NSDictionary *excpected = @{@"key" : @"value", @"date" : @"date"};
    XCTAssertEqualObjects(object[@"key"], @"value");
    XCTAssertEqualObjects(object[@"object"], excpected);

    NSDictionary *nestedObject = [object objectForKey:@"object"];
    XCTAssertEqualObjects(nestedObject[@"key"], @"value");
    XCTAssertEqualObjects(nestedObject[@"date"], @"date");

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_nested_object_with_schema_and_converter
{
    NSDictionary *data = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};
    NSDictionary *schema = @{@"key" : @"value", @"object" : @{@"key" : @"NSURL", @"date" : @"NSDate"}};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    NSDictionary *excpected = @{@"key" : @"Url", @"date" : @"Date"};
    XCTAssertEqualObjects(object[@"key"], @"value");
    XCTAssertEqualObjects(object[@"object"], excpected);

    NSDictionary *nestedObject = [object objectForKey:@"object"];
    XCTAssertEqualObjects(nestedObject[@"key"], @"Url");
    XCTAssertEqualObjects(nestedObject[@"date"], @"Date");

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_object_with_values_missed_in_scheme_response
{
    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNotNil(object[@"value2"]);
}

- (void)test_object_with_values_missed_in_scheme_response_with_option_to_skip
{
    validationOptions |= TRCValidationOptionsRemoveValuesMissedInSchemeForResponses;

    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNil(object[@"value2"]);
}

- (void)test_object_with_values_missed_in_scheme_request
{
    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSError *conversionError = nil;
    NSDictionary *object = [self convertRequestObject:data schema:schema error:&conversionError];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNotNil(object[@"value2"]);
}

- (void)test_object_with_values_missed_in_scheme_request_with_option_to_skip
{
    validationOptions |= TRCValidationOptionsRemoveValuesMissedInSchemeForRequests;

    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSError *conversionError = nil;
    NSDictionary *object = [self convertRequestObject:data schema:schema error:&conversionError];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNil(object[@"value2"]);
}

- (void)test_nested_object_without_schema
{
    NSDictionary *data = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil error:&conversionError];

    NSDictionary *excpected = @{@"key" : @"value", @"date" : @"date"};
    XCTAssertEqualObjects(object[@"key"], @"value");
    XCTAssertEqualObjects(object[@"object"], excpected);

    NSDictionary *nestedObject = [object objectForKey:@"object"];
    XCTAssertEqualObjects(nestedObject[@"key"], @"value");
    XCTAssertEqualObjects(nestedObject[@"date"], @"date");

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}


- (void)test_nested_array_of_objects_with_schema
{
    NSDictionary *data = @{
            @"array" : @[
                    @{@"key1" : @"value1", @"key2" : @"date1"},
                    @{@"key1" : @"value2", @"key2" : @"date2"}
            ]
    };

    NSDictionary *schema = @{
            @"array" : @[
                    @{@"key1" : @"value1", @"key2" : @"NSURL"},
            ]
    };

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    NSDictionary *excpected0 = @{@"key1" : @"value1", @"key2" : @"Url"};
    NSDictionary *excpected1 = @{@"key1" : @"value2", @"key2" : @"Url"};

    NSArray *array = [object objectForKey:@"array"];

    XCTAssertEqualObjects(array[0], excpected0);
    XCTAssertEqualObjects(array[1], excpected1);

    NSDictionary *nestedObject1 = array[0];
    XCTAssertEqualObjects(nestedObject1[@"key1"], @"value1");
    XCTAssertEqualObjects(nestedObject1[@"key2"], @"Url");

    NSDictionary *nestedObject2 = array[1];
    XCTAssertEqualObjects(nestedObject2[@"key1"], @"value2");
    XCTAssertEqualObjects(nestedObject2[@"key2"], @"Url");

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_nested_array_of_objects_without_schema
{
    NSDictionary *data = @{
            @"array" : @[
                    @{@"key1" : @"value1", @"key2" : @"date1"},
                    @{@"key1" : @"value2", @"key2" : @"date2"}
            ]
    };

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil error:&conversionError];

    NSDictionary *excpected0 = @{@"key1" : @"value1", @"key2" : @"date1"};
    NSDictionary *excpected1 = @{@"key1" : @"value2", @"key2" : @"date2"};

    NSArray *array = object[@"array"];

    XCTAssertEqualObjects(array[0], excpected0);
    XCTAssertEqualObjects(array[1], excpected1);

    NSDictionary *nestedObject1 = array[0];
    XCTAssertEqualObjects(nestedObject1[@"key1"], @"value1");
    XCTAssertEqualObjects(nestedObject1[@"key2"], @"date1");

    NSDictionary *nestedObject2 = array[1];
    XCTAssertEqualObjects(nestedObject2[@"key1"], @"value2");
    XCTAssertEqualObjects(nestedObject2[@"key2"], @"date2");

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_nested_array_of_primitives_with_schema
{
    NSDictionary *data = @{@"array" : @[@"1", @"2", @"3"]};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil error:&conversionError];

    NSArray *excpected = @[@"1", @"2", @"3"];

    NSArray *array = object[@"array"];
    XCTAssertNotNil(array);
    XCTAssertEqualObjects(object[@"array"], excpected);

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_nested_array_of_primitives_with_schema_converting
{
    NSDictionary *data = @{@"array" : @[@"1", @"2", @"3"]};

    NSDictionary *scheme = @{@"array" : @[@"NSURL"]};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:scheme error:&conversionError];

    NSArray *excpected = @[@"Url", @"Url", @"Url"];

    NSArray *array = object[@"array"];
    XCTAssertNotNil(array);

    XCTAssertEqualObjects(object[@"array"], excpected);

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_nested_array_of_primitives_without_schema
{
    NSDictionary *data = @{@"array" : @[@"1", @"2", @"3"]};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil error:&conversionError];

    NSArray *excpected = @[@"1", @"2", @"3"];

    XCTAssertEqualObjects(object[@"array"], excpected);

    XCTAssertTrue(conversionError == nil, @"Error: %@", conversionError);
}

- (void)test_nested_object_with_schema_and_error
{
    NSDictionary *data =   @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date", @"array" : @[@{@"another_array" : @[@"1", @"2"]}]}};
    NSDictionary *schema = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date", @"array" : @[@{@"another_array" : @[@"NSObject"], @"key" : @"value", @"key2{?}" : @"value2",}]}};

    NSError *conversionError = nil;
    __unused NSDictionary *object = [self convertResponseObject:data schema:schema error:&conversionError];

    //Only one conversion error: can't convert "1" and "2" into NSObject

    XCTAssertTrue(conversionError != nil, @"Error: %@", conversionError);
}

- (void)test_model_object_response_parsing
{
    NSDictionary *data = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url"};
    NSDictionary *schema = @{ @"{root_mapper}": @"{person}"};

    NSError *conversionError = nil;
    Person *object = [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssertEqualObjects(object.firstName, @"Ivan");
    XCTAssertEqualObjects(object.lastName, @"Ivanov");
    XCTAssertEqualObjects(object.avatarUrl, [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue(conversionError == nil);
}

- (void)test_model_object_request_composing
{
    Person *test = [Person new];
    test.firstName = @"Ivan";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"{root_mapper}": @"{person}"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertRequestObject:test schema:schema error:&conversionError];

    XCTAssertEqualObjects(object[@"first_name"], @"Ivan");
    XCTAssertEqualObjects(object[@"last_name"], @"Ivanov");
    XCTAssertEqualObjects(object[@"avatar_url"], [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue(conversionError == nil);
}

- (void)test_model_object_response_parsing_error
{
    NSDictionary *data = @{ @"first_name": @"i", @"last_name": @"Ivanov", @"avatar_url": @"some_url"};
    NSDictionary *schema = @{ @"{root_mapper}": @"test"};

    NSError *conversionError = nil;
    Person *object = [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssertNil(object);
    XCTAssertTrue(conversionError != nil);
}

- (void)test_model_object_request_composing_error
{
    Person *test = [Person new];
    test.firstName = @"i";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"{root_mapper}": @"test"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertRequestObject:test schema:schema error:&conversionError];

    XCTAssertNil(object);
    XCTAssertTrue(conversionError != nil);
}

- (void)test_mapper_request_not_implemented
{
    Person *test = [Person new];
    test.firstName = @"Ivan";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"{root_mapper}": @"test_without_request"};

    NSError *conversionError = nil;
    [self convertRequestObject:test schema:schema error:&conversionError];

    XCTAssertTrue(conversionError != nil);
}


- (void)test_mapper_response_not_implemented
{
    NSDictionary *data = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url"};
    NSDictionary *schema = @{ @"{root_mapper}": @"test_without_response"};

    NSError *conversionError = nil;
    [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssertTrue(conversionError != nil);
}

- (void)test_model_with_incorrect_object_mapper
{

    Person *test = [Person new];
    test.firstName = @"Ivan";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSError *conversionError = nil;
    NSDictionary *schema = @{ @"person": @"{person-cant-laod}"};
    [self convertRequestObject:@{@"person" : test} schema:schema error:&conversionError];

    XCTAssertTrue(conversionError != nil);

}

- (void)test_model_object_request_composing_external_scheme
{
    Person *test = [Person new];
    test.firstName = @"Ivan";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"person": @"{person}"};

    NSError *conversionError = nil;
    NSDictionary *object = [self convertRequestObject:@{@"person" : test} schema:schema error:&conversionError];

    XCTAssertEqualObjects(object[@"person"][@"first_name"], @"Ivan");
    XCTAssertEqualObjects(object[@"person"][@"last_name"], @"Ivanov");
    XCTAssertEqualObjects(object[@"person"][@"avatar_url"], [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue(conversionError == nil);
}

- (void)test_model_object_response_parsing_external_scheme
{
    NSDictionary *data = @{ @"person": @{@"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url"}};
    NSDictionary *schema = @{ @"person": @"{person}"};

    NSError *conversionError = nil;
    Person *object = [self convertResponseObject:data schema:schema error:&conversionError][@"person"];

    XCTAssertEqualObjects(object.firstName, @"Ivan");
    XCTAssertEqualObjects(object.lastName, @"Ivanov");
    XCTAssertEqualObjects(object.avatarUrl, [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue(conversionError == nil, @"conversionError: %@", conversionError);
}

- (void)test_model_object_response_parsing_external_scheme_sub_scheme
{
    NSDictionary *data = @{ @"person": @{@"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url", @"phone": @{ @"mobile":@"123", @"work":@"321"}}};
    NSDictionary *schema = @{ @"person": @"{person}"};

    NSError *conversionError = nil;
    Person *object = [self convertResponseObject:data schema:schema error:&conversionError][@"person"];

    XCTAssertEqualObjects(object.firstName, @"Ivan");
    XCTAssertEqualObjects(object.lastName, @"Ivanov");
    XCTAssertEqualObjects(object.avatarUrl, [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertEqualObjects(object.phone.work, @"321");
    XCTAssertEqualObjects(object.phone.mobile, @"123");
    XCTAssertTrue(conversionError == nil);
}

- (void)test_null_value_skipped
{
    
    NSDictionary *data = @{ @"key1": @"1", @"key2" : [NSNull null]};
    
    NSDictionary *schema = @{ @"key1": @"1", @"key2{?}": @"2"};
    
    NSDictionary *result = [self convertResponseObject:data schema:schema error:nil];
    
    XCTAssertEqualObjects(result, @{@"key1": @"1" });
}

- (void)test_conversion_with_validation_options
{
    validationOptions = TRCValidationOptionsRemoveValuesMissedInSchemeForResponses;

    NSDictionary *data = @{ @"key1": @"1", @"key2": @"", @"key3": @"123"};
    NSDictionary *schema = @{ @"key1": @"1", @"key2": @""};

    NSError *conversionError = nil;
    NSDictionary *result = [self convertResponseObject:data schema:schema error:&conversionError];

    XCTAssert(conversionError == nil);
    XCTAssertNil(result[@"key3"]);

}
//
- (void)test_validation_option2
{
    validationOptions = TRCValidationOptionsRemoveValuesMissedInSchemeForRequests;

    NSDictionary *data = @{ @"key1": @"1", @"key2": @"", @"key3": @"123"};
    NSDictionary *schema = @{ @"key1": @"1", @"key2": @""};

    NSError *conversionError = nil;
    NSDictionary *result = [self convertRequestObject:data schema:schema error:&conversionError];

    XCTAssert(conversionError == nil);
    XCTAssertNil(result[@"key3"]);
}

- (void)test_response_mapper_with_array
{
    NSDictionary *data = @{ @"array": @[
            @{
                    @"id" : @1,
                    @"text" : @"one"
            },
            @{
                    @"id" : @2,
                    @"text" : @"two"
            },
    ]};
    NSDictionary *schema = @{ @"array": @"{array}"};

    NSError *conversionError = nil;
    NSDictionary *result = [self convertResponseObject:data schema:schema error:&conversionError];

    TRCMapperWithArrayItemsCollection *collection = result[@"array"];

    XCTAssertTrue(conversionError == nil);
    XCTAssertTrue([collection isKindOfClass:[TRCMapperWithArrayItemsCollection class]]);
    NSArray *items = [collection allItems];
    TRCMapperWithArrayItem *item1 = [items firstObject];
    XCTAssertTrue([item1.text isEqualToString:@"one"]);

}

- (void)test_request_mapper_with_array
{
    TRCMapperWithArrayItem *item = [TRCMapperWithArrayItem new];
    item.identifier = @1;
    item.text = @"one";
    TRCMapperWithArrayItemsCollection *collection = [[TRCMapperWithArrayItemsCollection alloc] initWithItems:@[item]];

    NSDictionary *schema = @{ @"array": @"{array}"};

    NSError *error = nil;
    NSDictionary *result = [self convertRequestObject:@{ @"array" : collection}  schema:schema error:&error];
    XCTAssertNil(error);
    NSDictionary *expected = @{@"array": @[@{ @"id": @1, @"text": @"one"}]};
    XCTAssertEqualObjects(result, expected, @"");
}

@end
