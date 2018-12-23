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


@interface TRCConnectionProxy : NSObject <TRCConnection>

@property(nonatomic, strong) id<TRCConnection> connection;

- (instancetype)initWithConnection:(id<TRCConnection>)connection;

@end