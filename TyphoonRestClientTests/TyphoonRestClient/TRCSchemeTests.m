//
//  TRCSchemeTests.m
//  Iconic
//
//  Created by Aleksey Garbarev on 19.09.14.
//  Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRCSchema.h"
#import "TRCConvertersRegistry.h"
#import "TRCValueTransformer.h"
#import "TRCValueTransformerStub.h"
#import "TRCMapperPerson.h"
#import "TRCSchemaData.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCSerializerJson.h"
#import "TRCSerializerPlist.h"

@interface TRCSchemeTests : XCTestCase<TRCConvertersRegistry, TRCSchemaDataProvider>

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

- (TRCSchema *)schemaWithName:(NSString *)name forRequest:(BOOL)request
{
    NSBundle *bundle = [NSBundle bundleForClass:[TRCSchemeTests class]];
    NSString *schemePath = [bundle pathForResource:name ofType:nil];


    TRCSerializerJson *jsonSerializer = [TRCSerializerJson new];
    NSData *data = [NSData dataWithContentsOfFile:schemePath];
    id<TRCSchemaData> schemaData = nil;
    if (request) {
        schemaData = [jsonSerializer requestSchemaDataFromData:data dataProvider:self error:NULL];
    } else {
        schemaData = [jsonSerializer responseSchemaDataFromData:data dataProvider:self error:NULL];
    }
    TRCSchema *schema = [TRCSchema schemaWithData:schemaData name:name];
    schema.converterRegistry = self;

    return schema;
}


- (id<TRCValueTransformer>)valueTransformerForTag:(NSString *)type
{
    TRCValueTransformerStub *stub = [TRCValueTransformerStub new];
    if ([type isEqualToString:@"NSURL"]) {
        stub.supportedTypes = TRCValueTransformerTypeString;
        return stub;
    } else if ([type isEqualToString:@"NSNumber"]) {
        stub.supportedTypes = TRCValueTransformerTypeString | TRCValueTransformerTypeNumber;
        return stub;
    } else if ([type isEqualToString:@"NSDate"]) {
        stub.supportedTypes = TRCValueTransformerTypeString | TRCValueTransformerTypeNumber;
        return stub;
    } else if ([type isEqualToString:@"NSString"]) {
        stub.supportedTypes = TRCValueTransformerTypeString;
        return stub;
    }

    return nil;
}

- (BOOL)schemaData:(id<TRCSchemaData>)data hasObjectMapperForTag:(NSString *)schemaName
{
    return [self objectMapperForTag:schemaName] != nil;
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data requestSchemaForMapperWithTag:(NSString *)schemaName
{
    if ([schemaName isEqualToString:@"{person}"]) {
        TRCSchema *schema = [self schemaWithName:@"TRCMapperPerson.json" forRequest:YES];
        schema.converterRegistry = self;
        return schema.data;
    } else {
        return nil;
    }
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data responseSchemaForMapperWithTag:(NSString *)schemaName
{
    if ([schemaName isEqualToString:@"{person}"]) {
        TRCSchema *schema = [self schemaWithName:@"TRCMapperPerson.json" forRequest:NO];
        schema.converterRegistry = self;
        return schema.data;
    } else {
        return nil;
    }}

- (id<TRCObjectMapper>)objectMapperForTag:(NSString *)tag
{
    if ([tag isEqualToString:@"{person}"]) {
        return [TRCMapperPerson new];
    } else if ([tag isEqualToString:@"{person-2}"]) {
        return [TRCMapperPerson new];
    } else {
        return nil;
    }
}

- (id)convertValuesInResponse:(id)arrayOrDictionary schema:(TRCSchema *)scheme1 error:(NSError **)parseError
{
    return nil;
}

- (id)convertValuesInRequest:(id)arrayOrDictionary schema:(TRCSchema *)scheme1 error:(NSError **)parseError
{
    return nil;
}

- (void)setUp
{
    scheme = [self schemaWithName:@"TestScheme.json" forRequest:NO];
    stringsArrayScheme = [self schemaWithName:@"StringsArray.json" forRequest:NO];
    dictionariesArrayScheme = [self schemaWithName:@"DictionaryArray.json" forRequest:NO];
    numbersArrayScheme = [self schemaWithName:@"NumbersArray.json" forRequest:NO];
    optionalsScheme = [self schemaWithName:@"TestSchemeOptionals.json" forRequest:NO];
    getOrderScheme = [self schemaWithName:@"GetOrderScheme.json" forRequest:NO];

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
    XCTAssertNil([TRCSchema schemaWithData:nil name:@""]);
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

- (void)test_embed_subscheme
{
    TRCSchema *listSchema = [self schemaWithName:@"PersonsList.json" forRequest:NO];


    NSDictionary *input = @{
            @"count": @1,
            @"content": @[
                    @{
                            @"first_name" : @"123",
                            @"last_name" : @"123"
                    }
            ]
    };

    NSError *error = nil;
    XCTAssertFalse([listSchema validateResponse:input error:&error]);
    XCTAssertNotNil(error);

}

- (void)test_embed_subscheme_correct
{
    TRCSchema *listSchema = [self schemaWithName:@"PersonsList.json" forRequest:NO];
    listSchema.converterRegistry = self;


    NSDictionary *input = @{
            @"count": @1,
            @"content": @[
                    @{
                            @"first_name" : @"123",
                            @"last_name" : @"",
                            @"avatar_url" : @"123"
                    }
            ]
    };

    NSError *error = nil;
    XCTAssertTrue([listSchema validateResponse:input error:&error]);
    XCTAssertNil(error);

}

- (void)test_mapper_without_schema_incorrect
{
    TRCSchema *listSchema = [self schemaWithName:@"PersonsList.json" forRequest:NO];
    listSchema.converterRegistry = self;


    NSDictionary *input = @{
            @"count": @1,
            @"content": @[
                    @{
                            @"first_name" : @"123",
                            @"last_name" : @"",
                            @"avatar_url" : @"123"
                    }
            ],
            @"observer": @"string"
    };

    NSError *error = nil;
    XCTAssertFalse([listSchema validateResponse:input error:&error]);
    XCTAssertNotNil(error);
}

- (void)test_mapper_without_schema_correct
{
    TRCSchema *listSchema = [self schemaWithName:@"PersonsList.json" forRequest:NO];
    listSchema.converterRegistry = self;


    NSDictionary *input = @{
            @"count": @1,
            @"content": @[
                    @{
                            @"first_name" : @"123",
                            @"last_name" : @"",
                            @"avatar_url" : @"123"
                    }
            ],
            @"observer": @{
             @"name": @""
            }
    };

    NSError *error = nil;
    XCTAssertTrue([listSchema validateResponse:input error:&error]);
    XCTAssertNil(error);
}

- (void)test_plist_scheme
{
    NSBundle *bundle = [NSBundle bundleForClass:[TRCSchemeTests class]];
    NSString *schemePath = [bundle pathForResource:@"PropertyListSchema" ofType:@"plist"];
    
    TRCSerializerPlist *jsonSerializer = [TRCSerializerPlist new];
    NSData *data = [NSData dataWithContentsOfFile:schemePath];
    id<TRCSchemaData> schemaData = [jsonSerializer responseSchemaDataFromData:data dataProvider:self error:NULL];;
    TRCSchema *schema = [TRCSchema schemaWithData:schemaData name:@"PropertyListSchema.plist"];
    schema.converterRegistry = self;
    
    NSDictionary *dataIncorrect = @{
                           @"item": @"string",
                           @"item2": @"string",
                           @"date": [NSDate date]
                           };
    
    NSError *error = nil;
    XCTAssertFalse([schema validateResponse:dataIncorrect error:&error]);
    XCTAssertNotNil(error);
    

    error = nil;
    NSDictionary *dataCorrect = @{
                                    @"item": @"string",
                                    @"item2": @"",
                                    @"date": [NSDate date]
                                    };
    
    XCTAssertTrue([schema validateResponse:dataCorrect error:&error]);
    XCTAssertNil(error);
}

@end
