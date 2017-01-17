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


    NSArray *stack = @[@"order", @"suitable_packing_materials", @1];
    NSDictionary *object = @{
            @"order" : @{
                    @"suitable_packing_materials" : @[@"123", @"321"],
                    }
    };

    NSString *result = [_jsonPrinter errorDescriptionForObject:object errorMessage:@"Must be '123'" stackTrace:stack];

    XCTAssertEqualObjects(result, @"{\n"
            " \"order\" = {\n"
            "  \"suitable_packing_materials\" = [\n"
            "   \"123\",\n"
            "   \"321\"  <----- Must be '123'\n"
            "  ]\n"
            " }\n"
            "}");
}




@end
