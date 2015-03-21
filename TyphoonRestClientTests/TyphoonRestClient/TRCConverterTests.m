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
#import "TRCValueConverterStub.h"
#import "TRCMapperPerson.h"
#import "Person.h"
#import "Phone.h"
#import "TRCMapperPhone.h"

@interface TRCConverterTests : XCTestCase<TRCConvertersRegistry>

@end

@implementation TRCConverterTests

TRCValidationOptions validationOptions;

- (id<TRCValueTransformer>)valueConverterForTag:(NSString *)type
{
    TRCValueConverterStub *stub = [TRCValueConverterStub new];

    if ([type isEqualToString:@"NSURL"]) {
        stub.object = @"Url";
        stub.value = @"Url";
    } else if ([type isEqualToString:@"{url}"]) {
        stub.object = [[NSURL alloc] initWithString:@"http://appsquick.ly"];
        stub.value = [[NSURL alloc] initWithString:@"http://appsquick.ly"];
    } else if ([type isEqualToString:@"NSDate"]) {
        stub.object = @"Date";
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
    } else {
        return nil;
    };
}

- (id)convertValuesInResponse:(id)arrayOrDictionary schema:(TRCSchema *)scheme1 error:(NSError **)parseError
{
    return [self convertResponseObject:arrayOrDictionary schema:scheme1.schemeArrayOrDictionary errors:nil];
}

- (id)convertValuesInRequest:(id)arrayOrDictionary schema:(TRCSchema *)scheme1 error:(NSError **)parseError
{
    return [self convertRequestObject:arrayOrDictionary schema:scheme1.schemeArrayOrDictionary errors:nil];
}

- (TRCSchema *)requestSchemaForMapperWithTag:(NSString *)tag
{
    if ([tag isEqualToString:@"{person}"]) {
        TRCSchema *schema = [TRCSchema schemaWithName:@"TRCMapperPerson.json" extensionsToTry:nil];
        schema.converterRegistry = self;
        return schema;
    } else if ([tag isEqualToString:@"{phone}"]) {
        TRCSchema *schema = [TRCSchema schemaWithName:@"TRCMapperPhone.json" extensionsToTry:nil];
        schema.converterRegistry = self;
        return schema;
    }  else {
        return nil;
    }
}

- (TRCSchema *)responseSchemaForMapperWithTag:(NSString *)tag
{
    return [self requestSchemaForMapperWithTag:tag];
}

+ (void)setUp
{
    validationOptions = TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional | TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional;
    [super setUp];
}


- (void)tearDown
{
    [super tearDown];
}

- (id)convertResponseObject:(id)data schema:(id)schemaArrayOrDictionary errors:(NSOrderedSet **)errorsSet
{
    TRCConverter *converter = [[TRCConverter alloc] initWithResponseValue:data schemaValue:schemaArrayOrDictionary schemaName:@"test"];
    converter.options = validationOptions;
    converter.registry = self;
    if (errorsSet) {
        *errorsSet = converter.conversionErrorSet;
    }
    return [converter convertValues];
}

- (id)convertRequestObject:(id)data schema:(id)schemaArrayOrDictionary errors:(NSOrderedSet **)errorsSet
{
    TRCConverter *converter = [[TRCConverter alloc] initWithRequestValue:data schemaValue:schemaArrayOrDictionary schemaName:@"test"];
    converter.options = validationOptions;
    converter.registry = self;
    if (errorsSet) {
        *errorsSet = converter.conversionErrorSet;
    }
    return [converter convertValues];
}

- (void)test_request_with_conversion
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @"123"};
    NSDictionary *schema = @{@"key" : @"value", @"key2" : @"NSURL"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertRequestObject:data schema:schema errors:&errors];

    XCTAssertTrue([errors count] == 0);
    XCTAssertEqualObjects(object[@"key2"], @"Url");
}

- (void)test_plain_dictionary_with_schema
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @23};
    NSDictionary *schema = @{@"key" : @"value", @"key2" : @12};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

    XCTAssertTrue([[object objectForKey:@"key"] isEqualToString:@"value"]);
    XCTAssertTrue([[object objectForKey:@"key2"] isEqualToNumber:@23]);
    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_plain_dictionary_without_schema
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @23};

    NSOrderedSet *errors;
    NSDictionary *object = [self convertResponseObject:data schema:nil errors:&errors];

    XCTAssertTrue([[object objectForKey:@"key"] isEqualToString:@"value"]);
    XCTAssertTrue([[object objectForKey:@"key2"] isEqualToNumber:@23]);
    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_plain_dictionary_with_schema_and_converting
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2" : @"NSDate"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

    XCTAssertTrue([[object objectForKey:@"key"] isEqualToString:@"Url"]);
    XCTAssertTrue([[object objectForKey:@"key2"] isEqual:@"Date"]);
    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_plain_dictionary_with_schema_and_converting_incorrect_class
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2" : @"NSObject"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

    XCTAssertTrue([[object objectForKey:@"key"] isEqualToString:@"Url"]);
    XCTAssertTrue([object objectForKey:@"key2"] == nil);
    XCTAssertTrue(errors.count == 1, @"Error: %@", errors);
}

- (void)test_plain_dictionary_with_schema_and_converting_unknown_class
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2" : @"UnknownClass"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

    XCTAssertTrue([[object objectForKey:@"key"] isEqualToString:@"Url"]);
    XCTAssertTrue([[object objectForKey:@"key2"] isEqual:@12]);
    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_plain_dictionary_with_schema_and_converting_dict_repr
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};
    NSDictionary *schema = @{@"key" : @"NSURL", @"key2" : @"NSDate"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

    NSDictionary *expect = @{@"key" : @"Url", @"key2" : @"Date"};
    XCTAssertEqualObjects(object, expect);
    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_plain_dictionary_without_schema_and_converting_dict_repr
{
    NSDictionary *data = @{@"key" : @"value", @"key2" : @12};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil errors:&errors];

    NSDictionary *expect = @{@"key" : @"value", @"key2" : @12};
    XCTAssertEqualObjects(object, expect);
    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_nested_object_with_schema
{
    NSDictionary *data = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};
    NSDictionary *schema = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

    NSDictionary *excpected = @{@"key" : @"value", @"date" : @"date"};
    XCTAssertEqualObjects(object[@"key"], @"value");
    XCTAssertEqualObjects(object[@"object"], excpected);

    NSDictionary *nestedObject = [object objectForKey:@"object"];
    XCTAssertEqualObjects(nestedObject[@"key"], @"value");
    XCTAssertEqualObjects(nestedObject[@"date"], @"date");

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_nested_object_with_schema_and_converter
{
    NSDictionary *data = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};
    NSDictionary *schema = @{@"key" : @"value", @"object" : @{@"key" : @"NSURL", @"date" : @"NSDate"}};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

    NSDictionary *excpected = @{@"key" : @"Url", @"date" : @"Date"};
    XCTAssertEqualObjects(object[@"key"], @"value");
    XCTAssertEqualObjects(object[@"object"], excpected);

    NSDictionary *nestedObject = [object objectForKey:@"object"];
    XCTAssertEqualObjects(nestedObject[@"key"], @"Url");
    XCTAssertEqualObjects(nestedObject[@"date"], @"Date");

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_object_with_values_missed_in_scheme_response
{
    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNotNil(object[@"value2"]);
}

- (void)test_object_with_values_missed_in_scheme_response_with_option_to_skip
{
    validationOptions |= TRCValidationOptionsRemoveValuesMissedInSchemeForResponses;

    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNil(object[@"value2"]);
}

- (void)test_object_with_values_missed_in_scheme_request
{
    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertRequestObject:data schema:schema errors:&errors];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNotNil(object[@"value2"]);
}

- (void)test_object_with_values_missed_in_scheme_request_with_option_to_skip
{
    validationOptions |= TRCValidationOptionsRemoveValuesMissedInSchemeForRequests;

    NSDictionary *data = @{@"value1" : @1, @"value2": @2};
    NSDictionary *schema = @{ @"value1" : @1 };

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertRequestObject:data schema:schema errors:&errors];
    XCTAssertNotNil(object[@"value1"]);
    XCTAssertNil(object[@"value2"]);
}

- (void)test_nested_object_without_schema
{
    NSDictionary *data = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date"}};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil errors:&errors];

    NSDictionary *excpected = @{@"key" : @"value", @"date" : @"date"};
    XCTAssertEqualObjects(object[@"key"], @"value");
    XCTAssertEqualObjects(object[@"object"], excpected);

    NSDictionary *nestedObject = [object objectForKey:@"object"];
    XCTAssertEqualObjects(nestedObject[@"key"], @"value");
    XCTAssertEqualObjects(nestedObject[@"date"], @"date");

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
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

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];

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

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_nested_array_of_objects_without_schema
{
    NSDictionary *data = @{
            @"array" : @[
                    @{@"key1" : @"value1", @"key2" : @"date1"},
                    @{@"key1" : @"value2", @"key2" : @"date2"}
            ]
    };

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil errors:&errors];

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

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_nested_array_of_primitives_with_schema
{
    NSDictionary *data = @{@"array" : @[@"1", @"2", @"3"]};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil errors:&errors];

    NSArray *excpected = @[@"1", @"2", @"3"];

    NSArray *array = object[@"array"];
    XCTAssertNotNil(array);
    XCTAssertEqualObjects(object[@"array"], excpected);

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_nested_array_of_primitives_with_schema_converting
{
    NSDictionary *data = @{@"array" : @[@"1", @"2", @"3"]};

    NSDictionary *scheme = @{@"array" : @[@"NSURL"]};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:scheme errors:&errors];

    NSArray *excpected = @[@"Url", @"Url", @"Url"];

    NSArray *array = object[@"array"];
    XCTAssertNotNil(array);

    XCTAssertEqualObjects(object[@"array"], excpected);

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_nested_array_of_primitives_without_schema
{
    NSDictionary *data = @{@"array" : @[@"1", @"2", @"3"]};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertResponseObject:data schema:nil errors:&errors];

    NSArray *excpected = @[@"1", @"2", @"3"];

    XCTAssertEqualObjects(object[@"array"], excpected);

    XCTAssertTrue([errors count] == 0, @"Error: %@", errors);
}

- (void)test_nested_object_with_schema_and_errors
{
    NSDictionary *data = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date", @"array" : @[@{@"another_array" : @[@"1", @"2"]}]}};
    NSDictionary *schema = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date", @"array" : @[@{@"key" : @"value", @"key2{?}" : @"value2", @"another_array" : @[@"NSObject"]}]}};

    NSOrderedSet *errors = nil;
    __unused NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];


    XCTAssertTrue(errors.count == 2, @"Error: %@", errors);
}

- (void)test_model_object_response_parsing
{
    NSDictionary *data = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url"};
    NSDictionary *schema = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"{url}", @"{mapper}": @"test"};

    NSOrderedSet *errors = nil;
    Person *object = [self convertResponseObject:data schema:schema errors:&errors];

    XCTAssertEqualObjects(object.firstName, @"Ivan");
    XCTAssertEqualObjects(object.lastName, @"Ivanov");
    XCTAssertEqualObjects(object.avatarUrl, [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue([errors count] == 0);
}

- (void)test_model_object_request_composing
{
    Person *test = [Person new];
    test.firstName = @"Ivan";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"{url}", @"{mapper}": @"test"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertRequestObject:test schema:schema errors:&errors];

    XCTAssertEqualObjects(object[@"first_name"], @"Ivan");
    XCTAssertEqualObjects(object[@"last_name"], @"Ivanov");
    XCTAssertEqualObjects(object[@"avatar_url"], [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue([errors count] == 0);
}

- (void)test_model_object_response_parsing_error
{
    NSDictionary *data = @{ @"first_name": @"i", @"last_name": @"Ivanov", @"avatar_url": @"some_url"};
    NSDictionary *schema = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"{url}", @"{mapper}": @"test"};

    NSOrderedSet *errors = nil;
    Person *object = [self convertResponseObject:data schema:schema errors:&errors];

    XCTAssertNil(object);
    XCTAssertTrue([errors count] >= 1);
}

- (void)test_model_object_request_composing_error
{
    Person *test = [Person new];
    test.firstName = @"i";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"{url}", @"{mapper}": @"test"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertRequestObject:test schema:schema errors:&errors];

    XCTAssertEqualObjects(object, @{});
    XCTAssertTrue([errors count] >= 1);
}

- (void)test_mapper_request_not_implemented
{
    Person *test = [Person new];
    test.firstName = @"Ivan";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"{url}", @"{mapper}": @"test_without_request"};

    NSOrderedSet *errors = nil;
    [self convertRequestObject:test schema:schema errors:&errors];

    XCTAssertTrue([errors count] >= 1);
}


- (void)test_mapper_response_not_implemented
{
    NSDictionary *data = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url"};
    NSDictionary *schema = @{ @"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"{url}", @"{mapper}": @"test_without_response"};

    NSOrderedSet *errors = nil;
    [self convertResponseObject:data schema:schema errors:&errors];

    XCTAssertTrue([errors count] > 0);
}

- (void)test_model_object_request_composing_external_scheme
{
    Person *test = [Person new];
    test.firstName = @"Ivan";
    test.lastName = @"Ivanov";
    test.avatarUrl = [NSURL URLWithString:@"http://google.com"];

    NSDictionary *schema = @{ @"person": @"{person}"};

    NSOrderedSet *errors = nil;
    NSDictionary *object = [self convertRequestObject:@{ @"person" : test } schema:schema errors:&errors];

    XCTAssertEqualObjects(object[@"person"][@"first_name"], @"Ivan");
    XCTAssertEqualObjects(object[@"person"][@"last_name"], @"Ivanov");
    XCTAssertEqualObjects(object[@"person"][@"avatar_url"], [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue([errors count] == 0);
}

- (void)test_model_object_response_parsing_external_scheme
{
    NSDictionary *data = @{ @"person": @{@"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url"}};
    NSDictionary *schema = @{ @"person": @"{person}"};

    NSOrderedSet *errors = nil;
    Person *object = [self convertResponseObject:data schema:schema errors:&errors][@"person"];

    XCTAssertEqualObjects(object.firstName, @"Ivan");
    XCTAssertEqualObjects(object.lastName, @"Ivanov");
    XCTAssertEqualObjects(object.avatarUrl, [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertTrue([errors count] == 0);
}

- (void)test_model_object_response_parsing_external_scheme_sub_scheme
{
    NSDictionary *data = @{ @"person": @{@"first_name": @"Ivan", @"last_name": @"Ivanov", @"avatar_url": @"some_url", @"phone": @{ @"mobile":@"123", @"work":@"321"}}};
    NSDictionary *schema = @{ @"person": @"{person}"};

    NSOrderedSet *errors = nil;
    Person *object = [self convertResponseObject:data schema:schema errors:&errors][@"person"];

    XCTAssertEqualObjects(object.firstName, @"Ivan");
    XCTAssertEqualObjects(object.lastName, @"Ivanov");
    XCTAssertEqualObjects(object.avatarUrl, [NSURL URLWithString:@"http://appsquick.ly"]);
    XCTAssertEqualObjects(object.phone.work, @"321");
    XCTAssertEqualObjects(object.phone.mobile, @"123");
    XCTAssertTrue([errors count] == 0);
}

@end
