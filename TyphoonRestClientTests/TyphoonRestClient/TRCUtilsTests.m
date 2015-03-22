////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import <XCTest/XCTest.h>
#import "TRCUtils.h"

@interface TRCUtilsTests : XCTestCase

@end


@implementation TRCUtilsTests
{

}

- (void)test_optional_key_incorrect
{
    BOOL isOptional = NO;

    TRCKeyFromOptionalKey(@"key?", &isOptional);

    XCTAssertFalse(isOptional);
}

- (void)test_optional_key_correct
{
    BOOL isOptional = NO;

    TRCKeyFromOptionalKey(@"key{?}", &isOptional);

    XCTAssertTrue(isOptional);
}

- (void)test_optional_key_without_mark_correct
{
    BOOL isOptional = NO;

    NSString *key = TRCKeyFromOptionalKey(@"key{?}", &isOptional);

    XCTAssertTrue(isOptional);
    XCTAssertEqualObjects(key, @"key");
}

- (void)test_null_value_skipped_in_url_parameter
{
    NSMutableDictionary *data = [@{ @"key1": @"1", @"key2" : [NSNull null]} mutableCopy];
    
    TRCUrlPathParamsByRemovingNull(data);
    
    XCTAssertEqualObjects(data, @{@"key1": @"1" });
}

@end