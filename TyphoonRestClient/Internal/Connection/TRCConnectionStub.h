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

#import <Foundation/Foundation.h>
#import "TRCConnection.h"
#import "TRCConnectionAFNetworking.h"

@class TRCConnectionStubResponse;
typedef TRCConnectionStubResponse *(^TRCConnectionStubResponseBlock)(NSURLRequest *);

//-------------------------------------------------------------------------------------------
#pragma mark - Connection
//-------------------------------------------------------------------------------------------

@interface TRCConnectionStub : NSObject <TRCConnection>

- (void)setResponse:(TRCConnectionStubResponse *)response forPath:(NSString *)urlPath withQuery:(NSString *)urlQuery;

- (void)setResponse:(TRCConnectionStubResponse *)response;

- (void)setResponseBlock:(TRCConnectionStubResponseBlock)block;

@end

//-------------------------------------------------------------------------------------------
#pragma mark - Connection Shorthands
//-------------------------------------------------------------------------------------------

@interface TRCConnectionStub (Shorthands)

//Useful for unit testing
- (void)setResponseText:(NSString *)text;
- (void)setResponseText:(NSString *)text status:(NSUInteger)status;
- (void)setResponseWithConnectionError;

//Useful for integrated tests
- (void)setResponseText:(NSString *)text forRequestPath:(NSString *)path;
- (void)setResponseText:(NSString *)text status:(NSUInteger)status forRequestPath:(NSString *)path;
- (void)setResponseTimeoutErrorForRequestPath:(NSString *)path;

//Default response delay. Useful to test loading UI in the integration tests.
- (void)setResponseMinDelay:(NSTimeInterval)minDelay maxDelay:(NSTimeInterval)maxDelay;

@end

//-------------------------------------------------------------------------------------------
#pragma mark - Stub Response Model
//-------------------------------------------------------------------------------------------

@interface TRCConnectionStubResponse : NSObject

@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, readonly) NSUInteger statusCode;
@property (nonatomic, strong, readonly) NSDictionary *headers;
@property (nonatomic, strong, readonly) NSString *mime;

@property (nonatomic) NSTimeInterval delayInSeconds; //Default: 0

- (instancetype)initWithResponseData:(NSData *)data mime:(NSString *)mime headers:(NSDictionary *)headers status:(NSUInteger)status;

- (instancetype)initWithConnectionError;

- (instancetype)initWithContentNotFoundError;

@end

//-------------------------------------------------------------------------------------------
#pragma mark - Utils
//-------------------------------------------------------------------------------------------

/**
* Shorthand to load text file from NSBundle using it's name
*
* Useful to stub connection like that:
* [connection setResponseText:TRCBundleFile(@"ResponseStub.json")];
* */
NSString *TRCBundleFile(NSString *fileName);