//
//  TRCSchemeFactoryTests.m
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 26/06/2017.
//  Copyright (c) 2017 Apps Quickly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRCSchemeFactory.h"
#import "TRCSerializerPlist.h"
#import "TRCSerializerJson.h"

@interface TRCSchemeFactory (Tests)

- (NSString *)pathForSchemeWithClassName:(NSString *)className suffix:(NSString *)suffix;

@end


@interface TRCSchemeFactoryTests : XCTestCase

@end

@implementation TRCSchemeFactoryTests {
    TRCSchemeFactory *_schemeFactory;
}

- (void)setUp
{
    [super setUp];

    _schemeFactory = [TRCSchemeFactory new];

    TRCSerializerJson *json = [TRCSerializerJson new];
    [_schemeFactory registerSchemeFormat:json forFileExtension:@"json"];


    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testSimpleSchemeFinding
{
    NSString *path = [_schemeFactory pathForSchemeWithClassName:@"TestScheme" suffix:@""];

    XCTAssertTrue(path != nil);

    path = [_schemeFactory pathForSchemeWithClassName:@"PropertyListSchema" suffix:@""];

    XCTAssertTrue(path == nil);


    TRCSerializerPlist *plist = [TRCSerializerPlist new];
    [_schemeFactory registerSchemeFormat:plist forFileExtension:@"plist"];

    path = [_schemeFactory pathForSchemeWithClassName:@"PropertyListSchema" suffix:@""];

    XCTAssertTrue(path != nil);
}

- (void)testLoadPerformance
{
    [self measureBlock:^{
         [_schemeFactory pathForSchemeWithClassName:@"TestScheme" suffix:@""];
    }];
   
}

- (void)testCantLoadPerformance
{
    [self measureBlock:^{
        [_schemeFactory pathForSchemeWithClassName:@"TestScheme" suffix:@"response"];
    }];
}

- (void)testObjectMapper
{
    NSString *path = [_schemeFactory pathForSchemeWithClassName:@"TRCObjectMapperIssue" suffix:@"response"];

    XCTAssertTrue(path != nil);

    path = [_schemeFactory pathForSchemeWithClassName:@"TRCObjectMapperIssue" suffix:@"request"];

    XCTAssertTrue(path == nil);

    path = [_schemeFactory pathForSchemeWithClassName:@"TRCObjectMapperIssue" suffix:@""];

    XCTAssertTrue(path == nil);
}

- (void)testRequest
{
    NSString *path = [_schemeFactory pathForSchemeWithClassName:@"RequestToGetIssue" suffix:@"response"];
    XCTAssertTrue(path != nil);
}



@end
