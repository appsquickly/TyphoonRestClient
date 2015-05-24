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

@protocol TRCRequest;

@protocol TRCPostProcessor<NSObject>

@optional

- (id)postProcessResponseObject:(id)responseObject forRequest:(id<TRCRequest>)request;

@end