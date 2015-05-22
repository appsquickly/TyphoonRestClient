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

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (id<TRCSchemaData>)schemaDataForName:(NSString *)name
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:nil];
    NSData *schemaData = [NSData dataWithContentsOfFile:path];
    return [_jsonPrinter requestSchemaDataFromData:schemaData dataProvider:nil error:nil];
}


- (void)test_simple_output
{

    TRCSchemaStackTrace *stack = [TRCSchemaStackTrace new];
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

    NSString *result = [_jsonPrinter errorDescriptionWithErrorMessage:@"Test" stackTrace:stack];

    NSLog(@"result:\n===========================\n%@\n===========================\n", result);

    XCTAssert(result);

    XCTFail();
}




@end
