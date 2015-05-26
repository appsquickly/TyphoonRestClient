////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON REST CLIENT
//  Copyright 2015, Typhoon Rest Client Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "TRCConnection.h"

@class AFNetworkReachabilityManager;
@protocol AFURLRequestSerialization;
@protocol AFURLResponseSerialization;

@interface TRCConnectionAFNetworking : NSObject <TRCConnection>

@property (nonatomic, strong, readonly) AFNetworkReachabilityManager *reachabilityManager;

@property (nonatomic, strong, readonly) NSURL *baseUrl;

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl;

- (void)startReachabilityMonitoring;

- (void)stopReachabilityMonitoring;

@end

@interface NSError(HttpStatusCode)

@property (nonatomic, readonly) NSInteger httpStatusCode;

@end