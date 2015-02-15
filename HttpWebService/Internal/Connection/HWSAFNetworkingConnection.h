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
#import "HWSConnection.h"


@interface HWSAFNetworkingConnection : NSObject <HWSConnection>

@property (nonatomic, strong, readonly) NSURL *baseUrl;

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl;

@end

@interface NSError(HttpStatusCode)

@property (nonatomic, readonly) NSInteger httpStatusCode;

@end