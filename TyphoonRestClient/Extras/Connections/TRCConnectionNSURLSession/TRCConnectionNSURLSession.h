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

@class TRCNetworkReachabilityManager;

@interface TRCConnectionNSURLSession : NSObject <TRCConnection>

@property (nonatomic, strong, readonly) NSURLSession *session;

/**
* Current `reachabilityManager`, it can be used to get current `networkReachabilityStatus`, `isReachable`, etc...
* */
@property (nonatomic, strong, readonly) TRCNetworkReachabilityManager *reachabilityManager;

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl;

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl configuration:(NSURLSessionConfiguration *)configuration;

/**
* Invokes `startMonitoring` on `reachabilityManager`
* */
- (void)startReachabilityMonitoring;

/**
* Invokes `stopMonitoring` on `reachabilityManager`
* */
- (void)stopReachabilityMonitoring;

@end