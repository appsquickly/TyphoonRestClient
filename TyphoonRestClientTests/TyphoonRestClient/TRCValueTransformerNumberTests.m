//
//  TRCValueTransformerNumberTests.m
//  Iconic
//
//  Created by Aleksey Garbarev on 21.09.14.
//  Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRCValueTransformerNumber.h"

@interface TRCValueTransformerNumberTests : XCTestCase

@end

@implementation TRCValueTransformerNumberTests
{
    TRCValueTransformerNumber *converter;
}

- (void)setUp
{
    [super setUp];

    converter = [TRCValueTransformerNumber new];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)test_convert_number
{
    XCTAssertEqualObjects([converter objectFromResponseValue:@1 error:nil], @1);
}

- (void)test_convert_string
{
    XCTAssertEqualObjects([converter objectFromResponseValue:@"123" error:nil], @123);
}

- (void)test_convert_string_float
{
    XCTAssertEqualObjects([converter objectFromResponseValue:@"123.123" error:nil], @123.123);
}

- (void)test_convert_string_incorrect
{
    NSError *error = nil;
    XCTAssertEqualObjects([converter objectFromResponseValue:@"asfaf" error:&error], nil);
    XCTAssertNotNil(error);
}

@end
