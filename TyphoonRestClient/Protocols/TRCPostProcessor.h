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

@protocol TRCRequest;

@protocol TRCPostProcessor<NSObject>

@optional

/**
* This method invokes at the end of response processing. The result of this method would be used instead of
* input responseObject. Sometime it's useful to post-process all responseObjects in one centralized place, for example
* to wire circular dependencies in received object graph.
* */
- (id)postProcessResponseObject:(id)responseObject forRequest:(id<TRCRequest>)request postProcessError:(NSError **)error;

/**
*  Useful to handle all errors from RestClient in one place, and replace them with own error with own error codes.
* */
- (NSError *)postProcessError:(id)responseError forRequest:(id<TRCRequest>)request;

@end