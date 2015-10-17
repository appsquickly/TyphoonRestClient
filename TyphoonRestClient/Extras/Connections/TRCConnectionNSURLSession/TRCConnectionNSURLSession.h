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

@interface TRCConnectionNSURLSession : NSObject <TRCConnection>

@property (nonatomic, strong) NSURLSession *session;

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl;

@end