//
//  RequestSchemeTests.m
//  Iconic
//
//  Created by Aleksey Garbarev on 19.09.14.
//  Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRCSchema.h"
#import "TRCRequest.h"
#import "TRCValueConverterRegistry.h"
#import "TRCUtils.h"
#import "TRCConverter.h"
#import "TRCValueConverter.h"
#import "TRCValueConverterStub.h"

@interface ResponseObjectTests : XCTestCase<TRCValueConverterRegistry>

@end

@implementation ResponseObjectTests

- (id<TRCValueConverter>)valueConverterForTag:(NSString *)type
{
    TRCValueConverterStub *stub = [TRCValueConverterStub new];

    if ([type isEqualToString:@"NSURL"]) {
        stub.object = @"Url";
        stub.value = @"Url";
    } else if ([type isEqualToString:@"NSDate"]) {
        stub.object = @"Date";
    } else if ([type isEqualToString:@"NSObject"]) {
        stub.error = NSErrorWithFormat(@"Can't convert NSObject type");
    } else {
        return nil;
    }
    return stub;
}

- (void)tearDown
{
    [super tearDown];
}

- (id)convertResponseObject:(id)data schema:(id)schemaArrayOrDictionary errors:(NSOrderedSet **)errorsSet
{
    TRCConverter *object = [[TRCConverter alloc] initWithResponseValue:data schemaValue:schemaArrayOrDictionary schemaName:@"test"];
    object.registry = self;
    if (errorsSet) {
        *errorsSet = object.conversionErrorSet;
    }
    return [object convertValues];
}

- (id)convertRequestObject:(id)data schema:(id)schemaArrayOrDictionary errors:(NSOrderedSet **)errorsSet
{
    TRCConverter *object = [[TRCConverter alloc] initWithRequestValue:data schemaValue:schemaArrayOrDictionary schemaName:@"test"];
    object.registry = self;
    if (errorsSet) {
        *errorsSet = object.conversionErrorSet;
    }
    return [object convertValues];
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
    NSDictionary *schema = @{@"key" : @"value", @"object" : @{@"key" : @"value", @"date" : @"date", @"array" : @[@{@"key" : @"value", @"key2?" : @"value2", @"another_array" : @[@"NSObject"]}]}};

    NSOrderedSet *errors = nil;
    __unused NSDictionary *object = [self convertResponseObject:data schema:schema errors:&errors];


    XCTAssertTrue(errors.count == 2, @"Error: %@", errors);
}

@end
