////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2016 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "TRCConnection.h"


@interface TRCProxyProgressHandler : NSObject <TRCProgressHandler>

- (void)setProgressHandler:(id<TRCProgressHandler>)progressHandler;

- (BOOL)isCancelled;

@end