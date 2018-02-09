#import "Phone.h"
#import "Phone.h"//
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
#import "TyphoonRestClientErrors.h"
#import "TRCMapperPerson.h"
#import "Person.h"
#import "TRCSchemeFactory.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCErrorParserSimple.h"
#import "TRCMapperPhone.h"
#import "SyncOperationQueue.h"

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
    TyphoonRestClient *_restClient;
    TRCConnectionTestStub *_connectionStub;
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


- (TyphoonRestClient *)newRestClient
{
    TyphoonRestClient *resetClient = [[TyphoonRestClient alloc] init];
    [resetClient registerValueTransformer:[NumberToStringConverter new] forTag:@"number-as-string"];
    [resetClient registerObjectMapper:[TRCMapperPerson new] forTag:@"{person}"];
    [resetClient registerObjectMapper:[TRCMapperPhone new] forTag:@"{phone}"];
    resetClient.workQueue = [SyncOperationQueue new];
    resetClient.callbackQueue = [SyncOperationQueue new];
    return resetClient;
}

- (void)setUp
{
    [super setUp];
    _restClient = [self newRestClient];
    _connectionStub = [[TRCConnectionTestStub alloc] init];
    _restClient.connection = _connectionStub;

    currentWebService = _restClient;
}

- (void)tearDown
{
    [super tearDown];
    currentWebService = nil;
    _restClient = nil;
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
        schemeObject = @{ @"{root}" : @"{person}"};
    }

    if ([name isEqualToString:@"RootUrl"]) {
        schemeObject = @{ @"{root}" : @"{url}"};
    }

    if ([name isEqualToString:@"RootString"]) {
        schemeObject = @{ @"{root}" : @"string"};
    }

    if ([name isEqualToString:@"RootExtraDict"]) {
        schemeObject = @{ @"{root_mapper}" : @{
                @"number": @1,
                @"string": @"NSString",
                @"url{?}": @"{url}"
        }};
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
    [_connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];
    
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertEqualObjects(result, @"result");
        XCTAssertNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_request_schema
{
    [_connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = @{ @"key": @"123"};
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertEqualObjects(result, @"result");
        XCTAssertNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_request_schema_convert_error
{
    [_connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = @{ @"key": @123};
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        NSLog(@"** %@",error.localizedDescription);
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_request_schema_error
{
    [_connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = @{ @"key2": @123};
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        NSLog(@"** %@",error.localizedDescription);
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_plain_dictionary_request_with_error
{
    [_connectionStub setResponseObject:@{ @"key": @"value" } responseError:nil];
    
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";
    request.parseError = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"123"}];
    

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
        XCTAssertEqualObjects(error.localizedDescription, @"123");
    }];
}

- (void)test_plain_dictionary_request_with_network_error
{
    NSError *networkError = [[NSError alloc] initWithDomain:@"" code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Network Error!"}];

    [_connectionStub setResponseObject:@{ @"key": @"value" } responseError:networkError];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
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

    [_connectionStub setResponseObject:@{ @"message": @"Unknown error happens" } responseError:networkError];

    _restClient.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
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

    [_connectionStub setResponseObject:@{ @"message": @"Unknown error happens" } responseError:networkError];

    _restClient.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
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

    [_connectionStub setResponseObject:@{ @"code": @"string", @"message": @"Unknown error happens" } responseError:networkError];

    _restClient.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
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

    [_connectionStub setResponseObject:@{ @"code": @123, @"message": @"Unknown error happens", @"reason_url": @"http://google.com/"} responseError:networkError];

    _restClient.errorHandler = errorParserSpy;

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseResult = @"result";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.localizedDescription, @"Unknown error happens");
        XCTAssertEqualObjects(error.userInfo[@"url"], [[NSURL alloc] initWithString:@"http://google.com/"]);
    }];
}

- (void)test_nsobject_pass_though
{
    [_connectionStub setResponseObject:[NSObject new] responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        XCTAssertTrue([result isMemberOfClass:[NSObject class]]);
    }];
}

- (void)test_dictionary_with_scheme_and_parsing
{
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleDictionary";

    [_connectionStub setResponseObject:@{ @"number": @2, @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertTrue([result isMemberOfClass:[NSObject class]]);
        XCTAssertNil(error);
    }];
}

- (void)test_dictionary_with_scheme_and_validation_error
{
    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleDictionary";

    [_connectionStub setResponseObject:@{ @"number": @"string_value", @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
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

    [_connectionStub setResponseObject:@{ @"number": @1, @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];
    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
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

    [_connectionStub setResponseObject:@{ @"number": @1, @"string": @"123", @"url": [NSObject new]} responseError:nil];

    request.parseResult = [NSObject new];
    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(result);
        XCTAssertNotNil(error);
    }];
}

- (void)test_dictionary_without_scheme_and_converting_error
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@{ @"number": @1, @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.parseResult = [NSObject new];
    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSDictionary *expect = @{ @"number": @1, @"string": @"123", @"url": @"http://google.com"};
        XCTAssertEqualObjects(result, expect);
    }];
}

- (void)test_array_without_scheme_and_parsing
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        XCTAssertTrue([result isMemberOfClass:[NSObject class]]);
    }];
}

- (void)test_array_without_scheme_and_converting
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];

    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expect = @[@{@"number":@1, @"string":@"2", @"url": @"3"}];
        XCTAssertEqualObjects(expect, result);
    }];
}

- (void)test_array_without_scheme_and_parsing_error
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];
    NSError *parseError = [NSError new];
    request.parseError = parseError;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertTrue(request.parseResponseObjectCalled);
        XCTAssertEqualObjects(error, parseError);
        XCTAssertTrue(result == nil);
    }];
}

- (void)test_array_without_scheme_and_without_parsing
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @1, @2, @3] responseError:nil];

    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expected = @[ @1, @2, @3];
        XCTAssertEqualObjects(expected, result);
    }];
}

- (void)test_array_with_scheme_and_converting
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @{@"number":@1, @"string":@"2", @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];
    request.responseSchemeName = @"ArrayOfObjects";
    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expect = @[@{@"number":@1, @"string":@"2", @"url": [[NSURL alloc] initWithString:@"3"]}];
        XCTAssertEqualObjects(expect, result);
        NSLog(@"expect: %@", [expect description]);
        NSLog(@"got: %@", [result description]);
    }];
}

- (void)test_array_with_scheme_and_converting_numbers
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @{@"number":@"1", @"string":@2, @"url": @"3"} ] responseError:nil];

    request.parseResult = [NSObject new];
    request.responseSchemeName = @"ArrayOfObjects";
    request.parseObjectImplemented = NO;

    _restClient.options = TRCOptionsConvertNumbersAutomatically;

    __block BOOL callbackCalled = NO;
    
    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expect = @[@{@"number":@1, @"string":@"2", @"url": [[NSURL alloc] initWithString:@"3"]}];
        XCTAssertEqualObjects(expect, result);
        NSLog(@"expect: %@", [expect description]);
        NSLog(@"got: %@", [result description]);
        callbackCalled = YES;
    }];
    
    XCTAssertTrue(callbackCalled);
}

- (void)test_array_with_scheme_2_and_converting
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @"1", @"2", @"3" ] responseError:nil];

    request.parseResult = [NSObject new];
    request.responseSchemeName = @"SimpleArray";
    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNil(error);
        NSArray *expect = @[ [[NSURL alloc] initWithString:@"1"],[[NSURL alloc] initWithString:@"2"],[[NSURL alloc] initWithString:@"3"] ];
        XCTAssertEqualObjects(expect, result);
    }];
}

- (void)test_array_with_scheme_2_and_converting_with_fail
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @"1", @"2", [NSObject new] ] responseError:nil];

    request.parseResult = [NSObject new];
    request.responseSchemeName = @"SimpleArray";
    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertFalse(request.parseResponseObjectCalled);
        XCTAssertNotNil(error);
        XCTAssertNil(result);
    }];
}


- (void)test_array_of_arrays
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@[ @[ @1, @2, @3], @[@1, @2, @3], @[@1, @2, @3]] responseError:nil];

    request.parseObjectImplemented = NO;
    request.responseSchemeName = @"ArrayOfArray";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
        NSArray *expectedResult = @[ @[ @"1", @"2", @"3"], @[ @"1", @"2", @"3"], @[ @"1", @"2", @"3"]];
        XCTAssertEqualObjects(expectedResult, result);
    }];
}

- (void)test_person_mapper_response
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@{@"first_name" : @"Ivan",
            @"last_name" : @"Ivanov",
            @"avatar_url" : @"http://google.com"} responseError:nil];

    request.parseObjectImplemented = NO;
    request.responseSchemeName = @"Person";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
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

    [_connectionStub setResponseObject:@{
            @"token_type" : @"Bearer",
            @"expires_in" : @36000,
            @"scope" : @"write read groups",
            @"access_token": @"s57JLTxcxR8YPdo4GxgC62ovzWKtFf",
            @"refresh_token": @"IpqCFzvmRE35DiiHzTBwMz0mcOYMlO"
    } responseError:nil];

    request.parseObjectImplemented = NO;
    request.responseSchemeName = @"Token";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
    }];
}

- (void)test_simple_error_parser
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@{@"status":@200, @"message":@"OK"} responseError:nil];

    _restClient.errorHandler = [TRCErrorParserSimple new];

    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        NSDictionary *expect = @{@"status":@200, @"message":@"OK"};
        XCTAssertEqualObjects(expect, result);
    }];
}

- (void)test_simple_error_parser_wrong_status
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    [_connectionStub setResponseObject:@{@"status":@400, @"message":@"Fail"} responseError:nil];

    _restClient.errorHandler = [TRCErrorParserSimple new];

    request.parseObjectImplemented = NO;

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqualObjects(error.localizedDescription, @"Fail");
    }];
}

- (void)test_incorrect_object_received_for_request_with_schema
{
    [_connectionStub setResponseObject:[NSData new] responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.responseSchemeName = @"SimpleArray";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_incorrect_object_in_request_with_schema
{
    [_connectionStub setResponseObject:[NSData new] responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.requestSchemeName = @"SimpleRequest.json";
    request.requestBody = (id)[NSData new];

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNotNil(error, @"Error: %@", error.localizedDescription);
    }];
}

- (void)test_manual_mapper_method
{
    id input = [NSURL URLWithString:@"http://google.com/"];
    id result = [_restClient convertThenValidateRequestObject:input usingSchemaObject:@"{url}" options:TRCTransformationOptionsNone error:nil];

    XCTAssert( [result isKindOfClass:[NSString class]] );

    input = @"http://google.com/";
    result = [_restClient validateThenConvertResponseObject:input usingSchemaObject:@"{url}" options:TRCTransformationOptionsNone error:nil];

    XCTAssert( [result isKindOfClass:[NSURL class]] );

    input = @{
            @"first_name": @"Test1",
            @"last_name": @"Test2",
            @"avatar_url": @"http://google.com/",
            @"phone": @{
                    @"mobile" : @"123",
                    @"work": @"321"
            }
    };
    result = [_restClient validateThenConvertResponseObject:input usingSchemaObject:@"{person}" options:TRCTransformationOptionsNone error:nil];

    XCTAssert( [result isKindOfClass:[Person class]] );
    Person *person = result;

    XCTAssert([person.firstName isEqualToString:@"Test1"]);
    XCTAssert([person.phone.mobile isEqualToString:@"123"]);

    input = @[
            @"http://appsquick.ly",
            @"http://google.com"
    ];

    result = [_restClient validateThenConvertResponseObject:input usingSchemaObject:@[ @"{url}" ] options:TRCTransformationOptionsNone error:nil];

    XCTAssert( [result isKindOfClass:[NSArray class]] );
    XCTAssert( [result count] == 2 );

    XCTAssert([result[0] isKindOfClass:[NSURL class]]);
    XCTAssert([result[1] isKindOfClass:[NSURL class]]);

    input = @[
            @"http://appsquick.ly",
            @"http://google.com"
    ];

    NSError *error = nil;
    result = [_restClient validateThenConvertResponseObject:input usingSchemaObject:@[ @{@"url": @"{url}"} ] options:TRCTransformationOptionsNone error:&error];
    XCTAssert(error != nil);
    XCTAssert(result == nil);

    NSLog(@"Error: %@", error);


}

- (void)test_root_mapper
{
    TRCRequestSpy *request = [TRCRequestSpy new];

    // Value Transformer
    [_connectionStub setResponseObject:@"http://google.com" responseError:nil];

    request.parseObjectImplemented = NO;
    request.responseSchemeName = @"RootUrl";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
        XCTAssertEqualObjects([NSURL URLWithString:@"http://google.com"], result);
    }];

    // Text
    [_connectionStub setResponseObject:@"text" responseError:nil];

    request.responseSchemeName = @"RootString";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(@"text", result);
    }];

    //Extra Dictionary
    [_connectionStub setResponseObject:@{ @"number": @1, @"string": @"123", @"url": @"http://google.com"} responseError:nil];

    request.responseSchemeName = @"RootExtraDict";

    [_restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);
        NSDictionary *expect = @{ @"number": @1, @"string": @"123", @"url": [[NSURL alloc] initWithString:@"http://google.com"]};
        XCTAssertEqualObjects(result, expect);
    }];
}

- (void)test_parsing_on_background_queue
{
    TyphoonRestClient *restClient = [self newRestClient];
    TRCConnectionTestStub *stub = [[TRCConnectionTestStub alloc] init];
    restClient.connection = stub;
    
    NSOperationQueue *bgQueue = [NSOperationQueue new];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    restClient.workQueue = bgQueue;
    restClient.callbackQueue = mainQueue;

    [stub setResponseObject:[NSData new] responseError:nil];

    TRCRequestSpy *request = [TRCRequestSpy new];
    request.insideParseBlock = ^{
        XCTAssert([NSOperationQueue currentQueue] == bgQueue);
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"waiting for response"];
    [restClient sendRequest:request completion:^(id result, NSError *error) {
        XCTAssert([NSOperationQueue currentQueue] == mainQueue);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {

    }];
}

@end
