//
//  TRCSchemeTests.m
//  Iconic
//
//  Created by Aleksey Garbarev on 19.09.14.
//  Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRCSchema.h"
#import "TRCValueConverterRegistry.h"
#import "TRCValueConverter.h"
#import "TRCValueConverterStub.h"

@interface TRCSchemeTests : XCTestCase<TRCValueConverterRegistry>

@end

@implementation TRCSchemeTests
{
    TRCSchema *scheme;
    TRCSchema *stringsArrayScheme;
    TRCSchema *numbersArrayScheme;
    TRCSchema *dictionariesArrayScheme;
    TRCSchema *optionalsScheme;
    TRCSchema *getOrderScheme;
}


- (id<TRCValueConverter>)valueConverterForTag:(NSString *)type
{
    TRCValueConverterStub *stub = [TRCValueConverterStub new];
    if ([type isEqualToString:@"NSURL"]) {
        stub.supportedTypes = TRCValueConverterTypeString;
        return stub;
    } else if ([type isEqualToString:@"NSNumber"]) {
        stub.supportedTypes = TRCValueConverterTypeString | TRCValueConverterTypeNumber;
        return stub;
    } else if ([type isEqualToString:@"NSDate"]) {
        stub.supportedTypes = TRCValueConverterTypeString | TRCValueConverterTypeNumber;
        return stub;
    } else if ([type isEqualToString:@"NSString"]) {
        stub.supportedTypes = TRCValueConverterTypeString;
        return stub;
    }

    return nil;
}

- (TRCSchema *)schemeWithName:(NSString *)name
{
    NSBundle *bundle = [NSBundle bundleForClass:[TRCSchemeTests class]];
    NSString *schemePath = [bundle pathForResource:name ofType:nil];
    TRCSchema *aScheme = [[TRCSchema alloc] initWithFilePath:schemePath];
    aScheme.converterRegistry = self;
    return aScheme;
}

- (void)setUp
{
    scheme = [self schemeWithName:@"TestScheme.json"];
    stringsArrayScheme = [self schemeWithName:@"StringsArray.json"];
    dictionariesArrayScheme = [self schemeWithName:@"DictionaryArray.json"];
    numbersArrayScheme = [self schemeWithName:@"NumbersArray.json"];
    optionalsScheme = [self schemeWithName:@"TestSchemeOptionals.json"];
    getOrderScheme = [self schemeWithName:@"GetOrderScheme.json"];

    [super setUp];
}

- (void)test_schemes_exists
{
    XCTAssertNotNil(scheme);
    XCTAssertNotNil(stringsArrayScheme);
    XCTAssertNotNil(numbersArrayScheme);
    XCTAssertNotNil(dictionariesArrayScheme);
    XCTAssertNotNil(optionalsScheme);
    XCTAssertNotNil(getOrderScheme);
}

- (void)test_scheme_not_exist_at_path
{
    XCTAssertNil([TRCSchema schemaWithName:@"123"]);
    XCTAssertNil([[TRCSchema alloc] initWithFilePath:@"23"]);
}

- (void)test_correct_plain_dict
{
    NSDictionary *dictionary = @{
            @"string": @"",
            @"string_by_default": @"",
            @"number": @2,
            @"number_float": @2.0
    };

    NSError *error = nil;
    XCTAssertTrue([scheme validateResponse:dictionary error:&error]);
    XCTAssertNil(error);
}

- (void)test_mismatch_params_count
{
    NSDictionary *dictionary = @{
            @"string": @"",
            @"string_by_default": @"",
            @"number": @2
    };

    NSError *error = nil;
    XCTAssertFalse([scheme validateResponse:dictionary error:&error]);
    XCTAssertNotNil(error);
}

- (void)test_mismatch_params_type
{
    NSDictionary *dictionary = @{
            @"string": @"",
            @"string_by_default": @"",
            @"number": @"2",
            @"number_float": @2.0
    };

    NSError *error = nil;
    XCTAssertFalse([scheme validateResponse:dictionary error:&error]);
    XCTAssertNotNil(error);
}

- (void)test_mismatch_root_object
{
    NSArray *object = @[@"",@""];

    NSError *error = nil;
    XCTAssertFalse([scheme validateResponse:object error:&error]);
    XCTAssertNotNil(error);
}

- (void)test_numbers_array_correct
{
    NSArray *numbers = @[ @1, @2, @3];

    XCTAssertTrue([numbersArrayScheme validateResponse:numbers error:nil]);
}

- (void)test_numbers_array_incorrect
{
    NSArray *array = @[ @1, @2, @3, @"23"];

    XCTAssertFalse([numbersArrayScheme validateResponse:array error:nil]);
}

- (void)test_dictionary_array_correct
{
    NSArray *array = @[ @{ @"key1":@"",@"key2":@"",@"key3":@2}, @{ @"key1":@"",@"key2":@"",@"key3":@2}];

    XCTAssertTrue([dictionariesArrayScheme validateResponse:array error:nil]);
}


- (void)test_dictionary_array_incorrect
{
    NSArray *array = @[@{ @"key1":@"",@"key2":@"",@"key3":@2}, @{ @"key1":@"",@"key2":@""}];

    XCTAssertFalse([dictionariesArrayScheme validateResponse:array error:nil]);
}

- (void)test_strings_array_correct
{
    NSArray *array = @[ @"a", @"b"];

    XCTAssertTrue([stringsArrayScheme validateResponse:array error:nil]);
}


- (void)test_strings_array_incorrect
{
    NSArray *array = @[@"a", @"b", @[]];

    XCTAssertFalse([stringsArrayScheme validateResponse:array error:nil]);
}

- (void)test_optional_with_all_values
{
    NSDictionary *dictionary = @{
            @"string": @"",
            @"string_by_default": @"",
            @"number": @2,
            @"number_float": @2.0
    };

    NSError *error = nil;
    XCTAssertTrue([optionalsScheme validateResponse:dictionary error:&error]);
    XCTAssertNil(error);
}

- (void)test_optional_without_optionals_values
{
    NSDictionary *dictionary = @{
            @"string": @"",
            @"number": @2,
    };

    NSError *error = nil;
    XCTAssertTrue([optionalsScheme validateResponse:dictionary error:&error]);
    XCTAssertNil(error);
}

- (void)test_optional_without_not_optionals_values
{
    NSDictionary *dictionary = @{
            @"string": @"",
            @"string_by_default": @""
    };

    NSError *error = nil;
    XCTAssertFalse([optionalsScheme validateResponse:dictionary error:&error]);
    XCTAssertNotNil(error);
}

- (void)test_order_scheme_correct
{
    NSDictionary *dictionary = @{
            @"order" : @{
                    @"id" : @"asfsaf",
                    @"created_at" : @"123123",
                    @"display_order" : @2,
                    @"currency": @"AUD",
                    @"suitable_packing_materials" : @[@"123", @"321"],
                    @"products" : @[
                            @{
                                    @"id" : @"123",
                                    @"price" : @"23",
                                    @"image_url" : @"123123",
                                    @"description" : @"asdfsa",
                                    @"size" : @"123",
                                    @"color" : @"adsfa",
                                    @"brand" : @"123",
                                    @"display_order" : @0
                            },
                            @{
                                    @"id" : @"dfad",
                                    @"price" : @"23",
                                    @"image_url" : @"123123",
                                    @"description" : @"asdfsa",
                                    @"size" : @"123",
                                    @"color" : @"adsfa",
                                    @"brand" : @"123",
                                    @"display_order" : @0
                            }
                    ]
            }
    };

    NSError *error = nil;
    XCTAssertTrue([getOrderScheme validateResponse:dictionary error:&error]);
    XCTAssertNil(error);

}

- (void)test_order_scheme_incorrect
{
    NSDictionary *dictionary = @{
            @"order" : @{
                    @"id" : @"asfsaf",
                    @"created_at" : @"123123",
                    @"display_order" : @2,
                    @"currency": @"AUD",
                    @"suitable_packing_materials" : @[@"123", @"321"],
                    @"products" : @[
                            @{
                                    @"id" : @"123",
                                    @"price" : @"23",
                                    @"image_url" : @2,
                                    @"description" : @"asdfsa",
                                    @"size" : @"123",
                                    @"color" : @"adsfa",
                                    @"brand" : @"123",
                                    @"display_order" : @0
                            },
                            @{
                                    @"id" : @"dfad",
                                    @"price" : @2,
                                    @"image_url" : @"123123",
                                    @"description" : @"asdfsa",
                                    @"size" : @"123",
                                    @"color" : @"adsfa",
                                    @"brand" : @"123",
                                    @"display_order" : @0
                            }
                    ]
            }
    };

    NSError *error = nil;
    XCTAssertFalse([getOrderScheme validateResponse:dictionary error:&error]);
    XCTAssertNotNil(error);
}

- (void)test_incorret_scheme_with_converter
{
    NSDictionary *dictionary = @{
            @"string": @"",
            @"string_by_default": @"",
            @"number": @2,
            @"number_float": @[ @1, @2]
    };

    NSError *error = nil;
    XCTAssertFalse([scheme validateResponse:dictionary error:&error]);
    XCTAssertNotNil(error);
    NSLog(@"Error: %@",error.localizedDescription);
}


@end
