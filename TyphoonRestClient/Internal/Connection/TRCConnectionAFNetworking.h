////////////////////////////////////////////////////////////////////////////////
//
//  AppsQuick.ly
//  Copyright 2015 AppsQuick.ly
//  All Rights Reserved.
//
//  NOTICE: This software is the proprietary information of AppsQuick.ly
//  Use is subject to license terms.
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

// Custom serializers
+ (void)registerResponseSerializer:(id<AFURLResponseSerialization>)serialization forType:(TRCRequestSerialization)type;
+ (void)registerRequestSerializer:(id<AFURLRequestSerialization>)serialization forType:(TRCResponseSerialization)type;

@end

@interface NSError(HttpStatusCode)

@property (nonatomic, readonly) NSInteger httpStatusCode;

@end