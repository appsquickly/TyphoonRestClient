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

- (void)test_path_without_param
{
    NSString *path = @"path/to/request";
    NSMutableDictionary *params = nil;
    NSError *error = nil;

    NSString *result = TRCUrlPathFromPathByApplyingArguments(path, params, &error);

    XCTAssertNil(error);
    XCTAssertNil(params);
    XCTAssertEqualObjects(result, path);
}

- (void)test_path_with_one_param
{
    NSString *path = @"path/to/request/{param}";
    NSMutableDictionary *params = [@{@"param" : @1} mutableCopy];
    NSError *error = nil;

    NSString *result = TRCUrlPathFromPathByApplyingArguments(path, params, &error);

    XCTAssertNil(error);
    XCTAssertTrue([params count] == 0);
    XCTAssertEqualObjects(result, @"path/to/request/1");
}

- (void)test_path_with_incorrect_param
{
    NSString *path = @"path/to/request/{param2}";
    NSMutableDictionary *params = [@{@"param" : @1} mutableCopy];
    NSError *error = nil;

    NSString *result = TRCUrlPathFromPathByApplyingArguments(path, params, &error);

    XCTAssertNotNil(error);
    XCTAssertTrue([params count] == 1);
    XCTAssertNil(result);
}

- (void)test_path_with_multiple_params
{
    NSString *path = @"path/to/{param}/request/{param}";
    NSMutableDictionary *params = [@{@"param" : @1} mutableCopy];
    NSError *error = nil;

    NSString *result = TRCUrlPathFromPathByApplyingArguments(path, params, &error);

    XCTAssertNil(error);
    XCTAssertTrue([params count] == 0);
    XCTAssertEqualObjects(result, @"path/to/1/request/1");
}

- (void)test_path_used_params_removed
{
    NSString *path = @"path/to/request/{param}";
    NSMutableDictionary *params = [@{@"param" : @1, @"param2": @2} mutableCopy];
    NSError *error = nil;

    NSString *result = TRCUrlPathFromPathByApplyingArguments(path, params, &error);

    XCTAssertNil(error);
    XCTAssertTrue([params count] == 1);
    XCTAssertEqualObjects(params, [@{@"param2": @2} mutableCopy]);
    XCTAssertEqualObjects(result, @"path/to/request/1");
}

- (void)test_path_without_parameters_dict
{
    NSString *path = @"path/to/request/{param}";
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSError *error = nil;

    NSString *result = TRCUrlPathFromPathByApplyingArguments(path, params, &error);

    XCTAssertNotNil(error);
    XCTAssertNil(result);

    result = TRCUrlPathFromPathByApplyingArguments(path, nil, &error);

    XCTAssertNotNil(error);
    XCTAssertNil(result);
}

//- (void)test_nested_dictionaries_in_query_params
//{
//    NSString *path = @"path/to/request";
//    NSMutableDictionary *params = [NSMutableDictionary new];
//    params[@"location"][@"long"] = @"123";
//    params[@"location"][@"lat"] = @321;
//    params[@"searchQuery"] = @"qwerty";
//    params[@"page"] = @2;
//    params[@"pages"] = @[@1, @2, @3];
//    NSError *error = nil;
//
//    NSString *result = TRCQueryStringFromParametersWithEncoding(params, NSUTF8StringEncoding);
//
//    XCTAssertNil(error);
//}

@end