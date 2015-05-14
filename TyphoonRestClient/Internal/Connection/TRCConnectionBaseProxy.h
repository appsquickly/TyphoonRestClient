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


@interface TRCConnectionBaseProxy : NSObject <TRCConnection>

@property(nonatomic, strong) id<TRCConnection> connection;

- (instancetype)initWithConnection:(id<TRCConnection>)connection;

@end