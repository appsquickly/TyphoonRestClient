//
//  TRCIntegrationTests.m
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 20.05.15.
//  Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TyphoonRestClient.h"
#import "TRCObjectMapperIssue.h"
#import "TRCValueTransformerDateISO8601.h"
#import "TRCConnectionStub.h"
#import "RequestToGetIssue.h"
#import "Issue.h"
#import "TyphoonRestClientErrors.h"
#import "SimpleErrorParser.h"
#import "RequestToGetIssueIntoRoot.h"

@interface TRCIntegrationTests : XCTestCase

@end

@implementation TRCIntegrationTests {
    TyphoonRestClient *_restClient;
    TRCConnectionStub *_connection;
}

- (void)setUp
{
    [super setUp];

    _restClient = [[TyphoonRestClient alloc] init];
    _restClient.errorParser = [SimpleErrorParser new];
    [_restClient registerValueTransformer:[TRCValueTransformerDateISO8601 new] forTag:@"{date_iso8601}"];
    [_restClient registerObjectMapper:[TRCObjectMapperIssue new] forTag:@"{issue}"];

    _connection = [TRCConnectionStub new];

    _restClient.connection = [[TRCConnectionLogger alloc] initWithConnection:_connection];
}

- (void)test_get_issue
{
    [_connection setResponseText:@"{\"issue\":{\"id\":3,\"project\":{\"id\":1,\"name\":\"Redmine\"},\"tracker\":{\"id\":1,\"name\":\"Defect\"},\"status\":{\"id\":5,\"name\":\"Closed\"},\"priority\":{\"id\":4,\"name\":\"Normal\"},\"author\":{\"id\":6,\"name\":\"Todd McGrath\"},\"subject\":\"ajax pagination of projects\",\"description\":\"Is it just me or is the AJAX project pagination broken in .4.1?\\r\\n\\r\\nI'm testing with more than 15 projects and the Next and Page 2 links are not working.\\r\\n\\r\\nI can research more, but perhaps this is a known issue?\\r\\n\",\"done_ratio\":0,\"custom_fields\":[{\"id\":2,\"name\":\"Resolution\"},{\"id\":4,\"name\":\"Affected version\"}],\"created_on\":\"2007-01-19T06:42:00Z\",\"updated_on\":\"2012-10-03T16:02:32Z\",\"closed_on\":\"2007-01-19T06:42:00Z\"}}" status:200];

    RequestToGetIssue *request = [[RequestToGetIssue alloc] initWithIssueId:@3];

    [_restClient sendRequest:request completion:^(Issue *result, NSError *error) {
        XCTAssertNotNil(result);
        XCTAssertNil(error);
        XCTAssertEqualObjects(result.projectName, @"Redmine");
        XCTAssertEqualObjects(result.authorName, @"Todd McGrath");
        XCTAssertEqualObjects(result.identifier, @3);
    }];
}

- (void)test_get_issue_incorrect
{
    [_connection setResponseText:@"{\"issue\":{\"id_incorrect_key\":3,\"project\":{\"id\":1,\"name\":\"Redmine\"},\"tracker\":{\"id\":1,\"name\":\"Defect\"},\"status\":{\"id\":5,\"name\":\"Closed\"},\"priority\":{\"id\":4,\"name\":\"Normal\"},\"author\":{\"id\":6,\"name\":\"Todd McGrath\"},\"subject\":\"ajax pagination of projects\",\"description\":\"Is it just me or is the AJAX project pagination broken in .4.1?\\r\\n\\r\\nI'm testing with more than 15 projects and the Next and Page 2 links are not working.\\r\\n\\r\\nI can research more, but perhaps this is a known issue?\\r\\n\",\"done_ratio\":0,\"custom_fields\":[{\"id\":2,\"name\":\"Resolution\"},{\"id\":4,\"name\":\"Affected version\"}],\"created_on\":\"2007-01-19T06:42:00Z\",\"updated_on\":\"2012-10-03T16:02:32Z\",\"closed_on\":\"2007-01-19T06:42:00Z\"}}" status:200];

    RequestToGetIssue *request = [[RequestToGetIssue alloc] initWithIssueId:@3];

    [_restClient sendRequest:request completion:^(Issue *result, NSError *error) {
        XCTAssertNotNil(error);
    }];
}

- (void)test_timeout_error
{
    [_connection setResponseWithConnectionError];

    RequestToGetIssue *request = [[RequestToGetIssue alloc] initWithIssueId:@3];

    [_restClient sendRequest:request completion:^(Issue *result, NSError *error) {
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssert(error.code == TyphoonRestClientErrorCodeConnectionError);
    }];
}

- (void)test_forbidden_error
{
    [_connection setResponseText:@"{ \"message\":\"You are not authorized for that content\" }" status:403];

    RequestToGetIssue *request = [[RequestToGetIssue alloc] initWithIssueId:@3];

    [_restClient sendRequest:request completion:^(Issue *result, NSError *error) {
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssert(error.code == TyphoonRestClientErrorCodeBadResponseCode);
        XCTAssertEqualObjects(error.localizedDescription, @"You are not authorized for that content");
    }];
}

- (void)test_get_issue_into_root
{
    [_connection setResponseText:@"{\"id\":3,\"project\":{\"id\":1,\"name\":\"Redmine\"},\"tracker\":{\"id\":1,\"name\":\"Defect\"},\"status\":{\"id\":5,\"name\":\"Closed\"},\"priority\":{\"id\":4,\"name\":\"Normal\"},\"author\":{\"id\":6,\"name\":\"Todd McGrath\"},\"subject\":\"ajax pagination of projects\",\"description\":\"Is it just me or is the AJAX project pagination broken in .4.1?\\r\\n\\r\\nI'm testing with more than 15 projects and the Next and Page 2 links are not working.\\r\\n\\r\\nI can research more, but perhaps this is a known issue?\\r\\n\",\"done_ratio\":0,\"custom_fields\":[{\"id\":2,\"name\":\"Resolution\"},{\"id\":4,\"name\":\"Affected version\"}],\"created_on\":\"2007-01-19T06:42:00Z\",\"updated_on\":\"2012-10-03T16:02:32Z\",\"closed_on\":\"2007-01-19T06:42:00Z\"}" status:200];

    RequestToGetIssueIntoRoot *request = [[RequestToGetIssueIntoRoot alloc] init];

    [_restClient sendRequest:request completion:^(Issue *result, NSError *error) {
        XCTAssertNotNil(result);
        XCTAssertNil(error);
        XCTAssertEqualObjects(result.authorName, @"Todd McGrath");
        XCTAssertEqualObjects(result.identifier, @3);
    }];
}

@end
