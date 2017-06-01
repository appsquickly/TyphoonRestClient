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

@class TRCSessionTaskContext;

@interface TRCSessionHandler : NSObject <NSURLSessionDataDelegate>

- (void)startTask:(NSURLSessionTask *)task withContext:(TRCSessionTaskContext *)context;

@end
