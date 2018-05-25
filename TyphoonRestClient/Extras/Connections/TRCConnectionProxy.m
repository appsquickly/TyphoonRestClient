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

#import "TRCConnectionProxy.h"


@implementation TRCConnectionProxy {
    id<TRCConnection> _connection;
}

- (instancetype)initWithConnection:(id<TRCConnection>)connection
{
    self = [super init];
    if (self) {
        _connection = connection;
    }
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Proxy connection must be initialized with underlaying connection");
    return nil;
}

- (NSMutableURLRequest *)requestWithOptions:(id<TRCConnectionRequestCreationOptions>)options error:(NSError **)requestComposingError
{
    return [_connection requestWithOptions:options error:requestComposingError];
}

- (id<TRCProgressHandler>)sendRequest:(NSURLRequest *)request withOptions:(id<TRCConnectionRequestSendingOptions>)options completion:(TRCConnectionCompletion)completion
{
    return [_connection sendRequest:request withOptions:options completion:completion];
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
