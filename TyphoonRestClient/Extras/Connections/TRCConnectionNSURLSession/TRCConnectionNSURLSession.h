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
@protocol TRCConnectionNSURLSessionDelegate;
@class TRCSessionTaskContext;

@interface TRCConnectionNSURLSession : NSObject <TRCConnection>

@property (nonatomic, strong, readonly) NSURLSession *session;

/**
* Current `reachabilityManager`, it can be used to get current `networkReachabilityStatus`, `isReachable`, etc...
* */
@property (nonatomic, strong, readonly) TRCNetworkReachabilityManager *reachabilityManager;

/**
 *
 * */
@property (nonatomic) id<TRCConnectionNSURLSessionDelegate> delegate;

/**
 * `init` and `initWithBaseUrl` will use [NSURLSessionConfiguration defaultSessionConfiguration] as configuration.
 */
- (instancetype)init;
- (instancetype)initWithBaseUrl:(NSURL *)baseUrl;

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl configuration:(NSURLSessionConfiguration *)configuration;

/**
 * You may change baseUrl in runtime.
 */
@property (nonatomic) NSURL *baseUrl;

/**
* Invokes `startMonitoring` on `reachabilityManager`
* */
- (void)startReachabilityMonitoring;

/**
* Invokes `stopMonitoring` on `reachabilityManager`
* */
- (void)stopReachabilityMonitoring;

@end


@protocol TRCConnectionNSURLSessionDelegate <NSObject>

@optional
- (void)connection:(TRCConnectionNSURLSession *)connection context:(TRCSessionTaskContext *)context
                                               didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
                                                 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

//TODO: All other NSURLSessionDataDelegate methods

@end