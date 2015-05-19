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

#import "TRCConnectionProxy.h"


@implementation TRCConnectionProxy

- (instancetype)initWithConnection:(id<TRCConnection>)connection
{
    self = [super init];
    if (self) {
        self.connection = connection;
    }
    return self;
}

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError
{
    return [self.connection requestWithOptions:options error:requestComposingError];
}

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion
{
    return [self.connection sendRequest:request withOptions:options completion:completion];
}

- (void)setReachabilityDelegate:(id<TRCConnectionReachabilityDelegate>)reachabilityDelegate
{
    if ([(id)_connection respondsToSelector:@selector(setReachabilityDelegate:)]) {
        [_connection setReachabilityDelegate:reachabilityDelegate];
    }
}

- (TRCConnectionReachabilityState)reachabilityState
{
    if ([(id)_connection respondsToSelector:@selector(reachabilityState)]) {
        return [_connection reachabilityState];
    }
    return TRCConnectionReachabilityStateUnknown;
}

@end