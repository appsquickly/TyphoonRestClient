//
//  TRCValidationErrorPrinterTests.m
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 22.05.15.
//  Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TRCSerializerJson.h"
#import "TRCSchemaData.h"
#import "TRCSchemaStackTrace.h"

@interface TRCValidationErrorPrinterTests : XCTestCase

@end

@implementation TRCValidationErrorPrinterTests {
    TRCSerializerJson *_jsonPrinter;
}

- (void)setUp {
    [super setUp];

    _jsonPrinter = [TRCSerializerJson new];
    
}

- (void)test_simple_output
{

    TRCSchemaStackTrace *stack = [TRCSchemaStackTrace new];
    [stack pushSymbol:@"order"];
    [stack pushSymbol:@"suitable_packing_materials"];
    [stack pushSymbol:@1];
    stack.originalObject = @{
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

    NSString *result = [_jsonPrinter errorDescriptionWithErrorMessage:@"Must be '123'" stackTrace:stack];

    XCTAssertEqualObjects(result, @"{\n"
            " \"order\" = {\n"
            "  \"products\" = [\n"
            "   {\n"
            "    \"color\" = \"adsfa\",\n"
            "    \"id\" = \"123\",\n"
            "    \"price\" = \"23\",\n"
            "    \"image_url\" = \"123123\",\n"
            "    \"size\" = \"123\",\n"
            "    \"brand\" = \"123\",\n"
            "    \"description\" = \"asdfsa\",\n"
            "    \"display_order\" = 0\n"
            "   },\n"
            "   {\n"
            "    \"color\" = \"adsfa\",\n"
            "    \"id\" = \"dfad\",\n"
            "    \"price\" = \"23\",\n"
            "    \"image_url\" = \"123123\",\n"
            "    \"size\" = \"123\",\n"
            "    \"brand\" = \"123\",\n"
            "    \"description\" = \"asdfsa\",\n"
            "    \"display_order\" = 0\n"
            "   }\n"
            "  ],\n"
            "  \"id\" = \"asfsaf\",\n"
            "  \"display_order\" = 2,\n"
            "  \"currency\" = \"AUD\",\n"
            "  \"suitable_packing_materials\" = [\n"
            "   \"123\",\n"
            "   \"321\"  <----- Must be '123'\n"
            "  ],\n"
            "  \"created_at\" = \"123123\"\n"
            " }\n"
            "}");
}




@end
