//
//  TyphoonRestClientTests.m
//  Iconic
//
//  Created by Aleksey Garbarev on 20.09.14.
//  Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TyphoonRestClient.h"
#import "TRCConnectionTestStub.h"
#import "TRCRequestSpy.h"
#import "TRCErrorParserSpy.h"
#import "TRCSchema.h"
#import "TRCUtils.h"
#import "TRCValueTransformer.h"
#import <objc/runtime.h>
#import "NSObject+AutoDescription.h"
#import "TyphoonRestClientErrors.h"
#import "TRCMapperPerson.h"
#import "Person.h"
#import "TRCSchemeFactory.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCErrorParserSimple.h"

@interface NumberToStringConverter : NSObject <TRCValueTransformer>

@end

@implementation NumberToStringConverter

- (id)objectFromResponseValue:(id)value error:(NSError **)error
{
    return [NSString stringWithFormat:@"%@",value];
}


- (id)requestValueFromObject:(id)object error:(NSError **)error
{
    return object;
}

- (TRCValueTransformerType)externalTypes
{
    return TRCValueTransformerTypeNumber;
}

@end

@interface TyphoonRestClientTests : XCTestCase

@end

@implementation TyphoonRestClientTests
{
    TyphoonRestClient *webService;
    TRCConnectionTestStub *connectionStub;
}

static TyphoonRestClient *currentWebService;

id(*originalImp)(id, SEL, NSString *, BOOL);

+ (void)load
{
    Method m1 = class_getInstanceMethod([self class], @selector(schemeForName:isRequest:));
    Method m2 = class_getInstanceMethod([TRCSchemeFactory class], @selector(schemeForName:isRequest:));
    originalImp = (id(*)(id, SEL, NSString *, BOOL))method_getImplementation(m2);
    method_exchangeImplementations(m1, m2);
}


- (void)setUp
{
    [super setUp];
    webService = [[TyphoonRestClient alloc] init];
    [webService registerValueTransformer:[NumberToStringConverter new] forTag:@"number-as-string"];
    [webService registerObjectMapper:[TRCMapperPerson new] forTag:@"{person}"];
    connectionStub = [[TRCConnectionTestStub alloc] init];
    webService.connection = connectionStub;

    currentWebService = webService;
}

- (void)tearDown
{
    [super tearDown];
    currentWebService = nil;
}

- (TRCSchema *)schemeForName:(NSString *)name isRequest:(BOOL)isRequest
{
    id schemeObject = nil;
    if ([name isEqualToString:@"ErrorSchema"]) {
        schemeObject = @{@"code": @1, @"message": @"", @"reason_url{?}": @"{url}"};
    }
    if ([name isEqualToString:@"SimpleDictionary"]) {
        schemeObject = @{
                @"number": @1,
                @"string": @"NSString",
                @"url{?}": @"{url}"
        };
    }
    if ([name isEqualToString:@"SimpleRequest.json"]) {
        schemeObject = @{
                @"key": @"{url}",
        };
    }
    if ([name isEqualToString:@"SimpleArray"]) {
        schemeObject = @[
                @"{url}",
        ];
    }
    if ([name isEqualToString:@"ArrayOfObjects"]) {
        schemeObject = @[@{
                @"number" : @1,
                @"string" : @"NSString",
                @"url{?}" : @"{url}"
        }];
    }
    if ([name isEqualToString:@"ArrayOfArray"]) {
        schemeObject = @[@[@"number-as-string"]];
    }

    if ([name isEqualToString:@"Person"]) {
        schemeObject = @"{person}";
    }


    if ([name isEqualToString:@"Token"]) {
        schemeObject = @{
                @"access_token": @"{string}",
                @"token_type": @"bearer",
                @"refresh_token{?}": @"{string}",
                @"expires_in{?}": @36000
        };
    }

    if (schemeObject) {
        NSParameterAssert(currentWebService);
        TRCSchemaDictionaryData *data = [[TRCSchemaDictionaryData alloc] initWithArrayOrDictionary:schemeObject request:isRequest dataProvider:(id<TRCSchemaDataProvider>)currentWebService];
        TRCSchema *schema = [TRCSchema schemaWithData:data name:name];
        schema.converterRegistry = (id<TRCConvertersRegistry>)currentWebService;
        return schema;
    } else {
        return originalImp(self, _cmd, name, isRequest);
    }
}

- (void)test_plain_dictionary_request
{
    [connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];
    
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertEqualObjects(result, @"result");
        XCTAssertNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_request_schema
{
    [connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = @{ @"key": @"123"};
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertEqualObjects(result, @"result");
        XCTAssertNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_request_schema_convert_error
{
    [connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = @{ @"key": @123};
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        NSLog(@"** %@",error.localizedDescription);
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_request_schema_error
{
    [connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = @{ @"key2": @123};
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        NSLog(@"** %@",error.localizedDescription);
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_error
{
    [connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];
    
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";
    request.parseError = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"123"}];
    

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
        XCTAssertEqualObjects(error.localizedDescription, @"123");
    }];
}

- (void)test_plain_dictionary_request_with_network_error
{
    NSError *networkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Network Error!"}];

    [connectionStub setResponseObject:@{ @"key": @"value" } responseError:networkError];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.localizedDescription, @"Connection error");
    }];
}

- (void)test_plain_dictionary_request_with_network_error_parse
{
    NSError *parsedNetworkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Parsed network error"}];

    TRCErrorParserSpy *errorParserSpy = [TRCErrorParserSpy new];
    errorParserSpy.parsedError = parsedNetworkError;

    NSError *networkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Network Error!"}];

    [connectionStub setResponseObject:@{ @"message": @"Unknown error happens" } responseError:networkError];

    webService.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.localizedDescription, @"Parsed network error");
    }];
}

- (void)test_plain_dictionary_request_with_network_error_parse_with_error
{
    NSError *parsedNetworkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Parsing error"}];

    TRCErrorParserSpy *errorParserSpy = [TRCErrorParserSpy new];
    errorParserSpy.errorParsingError = parsedNetworkError;

    NSError *networkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Network Error!"}];

    [connectionStub setResponseObject:@{ @"message": @"Unknown error happens" } responseError:networkError];

    webService.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.localizedDescription, @"Connection error");
    }];
}

- (void)test_plain_dictionary_request_with_network_error_parse_with_schema_error
{

    TRCErrorParserSpy *errorParserSpy = [TRCErrorParserSpy new];
    errorParserSpy.schemaName = @"ErrorSchema";

    NSError *networkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Network Error!"}];

    [connectionStub setResponseObject:@{ @"code": @"string", @"message": @"Unknown error happens" } responseError:networkError];

    webService.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.localizedDescription, @"Connection error");
    }];
}

- (void)test_plain_dictionary_request_with_network_error_parse_with_schema_success
{
    TRCErrorParserSpy *errorParserSpy = [TRCErrorParserSpy new];
    errorParserSpy.schemaName = @"ErrorSchema";

    NSError *networkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Network Error!"}];

    [connectionStub setResponseObject:@{ @"code": @123, @"message": @"Unknown error happens", @"reason_url": @"http://google.com/"} responseError:networkError];

    webService.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.localizedDescription, @"Unknown error happens");
        XCTAssertEqualObjects(error.userInfo[@"url"], [[NSURL alloc] initWithString:@"http://google.com/"]);
    }];
}

- (void)test_nsobject_pass_though
{
    [connectionStub setResponseObject:[NSObject new] responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        XCTAssertTrue([result isMemberOfClass:[NSObject class]]);
    }];
}

- (void)test_dictionary_with_scheme_and_parsing
{
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleDictionary";

    [connectionStub setResponseObject:@{ @"number": @2, @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertTrue([result isMemberOfClass:[NSObject class]]);
        XCTAssertNil(error);
    }];
}

- (void)test_dictionary_with_scheme_and_validation_error
{
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleDictionary";

    [connectionStub setResponseObject:@{ @"number": @"string_value", @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == TyphoonRestClientErrorCodeValidation);
    }];
}

- (void)test_dictionary_with_scheme_and_converting
{
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleDictionary";

    [connectionStub setResponseObject:@{ @"number": @1, @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];
    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSDictionary *expect = @{ @"number": @1, @"string": @"123", @"url": [[NSURL alloc] initWithString:@"http://google.com"]};
        XCTAssertEqualObjects(result, expect);
    }];
}

- (void)test_dictionary_with_scheme_and_converting_error
{
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleDictionary";

    [connectionStub setResponseObject:@{ @"number": @1, @"string": @"123", @"url": @"not an url at all.\n"} responseError:nil];

    request.parseResult = [NSObject new];
    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
    }];
}

- (void)test_dictionary_without_scheme_and_converting_error
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@{ @"number": @1, @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];
    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSDictionary *expect = @{ @"number": @1, @"string": @"123", @"url": @"http://google.com"};
        XCTAssertEqualObjects(result, expect);
    }];
}

- (void)test_array_without_scheme_and_parsing
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        XCTAssertTrue([result isMemberOfClass:[NSObject class]]);
    }];
}

- (void)test_array_without_scheme_and_converting
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];

    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expect = @[@{@"number":@1, @"string":@"2", @"url": @"3"}];
        XCTAssertEqualObjects(expect, result);
    }];
}

- (void)test_array_without_scheme_and_parsing_error
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];
    NSError *parseError = [NSError new];
    request.parseError = parseError;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertEqualObjects(error, parseError);
        XCTAssertTrue(result == nil);
    }];
}

- (void)test_array_without_scheme_and_without_parsing
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @1, @2, @3] responseError:nil];

    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expected = @[ @1, @2, @3];
        XCTAssertEqualObjects(expected, result);
    }];
}

- (void)test_array_with_scheme_and_converting
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];
    request.responseSchemeName = @"ArrayOfObjects";
    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expect = @[@{@"number":@1, @"string":@"2", @"url": [[NSURL alloc] initWithString:@"3"]}];
        XCTAssertEqualObjects(expect, result);
        NSLog(@"expect: %@", [expect autoDescription]);
        NSLog(@"got: %@", [result autoDescription]);
    }];
}

- (void)test_array_with_scheme_2_and_converting
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @"1", @"2", @"3" ] responseError:nil];

    request.parseResult = [NSObject new];
    request.responseSchemeName = @"SimpleArray";
    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expect = @[ [[NSURL alloc] initWithString:@"1"],[[NSURL alloc] initWithString:@"2"],[[NSURL alloc] initWithString:@"3"] ];
        XCTAssertEqualObjects(expect, result);
    }];
}

- (void)test_array_with_scheme_2_and_converting_with_fail
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @"1", @"2", @"3\n" ] responseError:nil];

    request.parseResult = [NSObject new];
    request.responseSchemeName = @"SimpleArray";
    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNotNil(error);
        XCTAssertNil(result);
    }];
}


- (void)test_array_of_arrays
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@[ @[ @1, @2, @3], @[@1, @2, @3], @[@1, @2, @3]] responseError:nil];

    request.parseObjectImplemented = NO;
    request.responseSchemeName = @"ArrayOfArray";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
        NSArray *expectedResult = @[ @[ @"1", @"2", @"3"], @[ @"1", @"2", @"3"], @[ @"1", @"2", @"3"]];
        XCTAssertEqualObjects(expectedResult, result);
    }];
}

- (void)test_person_mapper_response
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@{@"first_name" : @"Ivan",
            @"last_name" : @"Ivanov",
            @"avatar_url" : @"http://google.com"} responseError:nil];

    request.parseObjectImplemented = NO;
    request.responseSchemeName = @"Person";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
        Person *expected = [Person new];
        expected.firstName = @"Ivan";
        expected.lastName = @"Ivanov";
        expected.avatarUrl = [NSURL URLWithString:@"http://google.com"];
        XCTAssertEqualObjects(expected, result);
    }];
}

- (void)test_passthrough_params_without_schema
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@{
            @"token_type" : @"Bearer",
            @"expires_in" : @36000,
            @"scope" : @"write read groups",
            @"access_token": @"s57JLTxcxR8YPdo4GxgC62ovzWKtFf",
            @"refresh_token": @"IpqCFzvmRE35DiiHzTBwMz0mcOYMlO"
    } responseError:nil];

    request.parseObjectImplemented = NO;
    request.responseSchemeName = @"Token";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
    }];
}

- (void)test_simple_error_parser
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@{@"status":@200, @"message":@"OK"} responseError:nil];

    webService.errorHandler = [TRCErrorParserSimple new];

    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        NSDictionary *expect = @{@"status":@200, @"message":@"OK"};
        XCTAssertEqualObjects(expect, result);
    }];
}

- (void)test_simple_error_parser_wrong_status
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [connectionStub setResponseObject:@{@"status":@400, @"message":@"Fail"} responseError:nil];

    webService.errorHandler = [TRCErrorParserSimple new];

    request.parseObjectImplemented = NO;

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqualObjects(error.localizedDescription, @"Fail");
    }];
}

- (void)test_incorrect_object_received_for_request_with_schema
{
    [connectionStub setResponseObject:[NSData new] responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleArray";

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_incorrect_object_in_request_with_schema
{
    [connectionStub setResponseObject:[NSData new] responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = (id)[NSData new];

    [webService sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}


@end
