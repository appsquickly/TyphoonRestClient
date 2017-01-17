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

/**
* `TRCPreProcessor` is per-request pre-processor.
* This pre-processor useful when you want centralized place to modify all response objects.
* You can check for `TRCRequest.customProperties` here for targeting (or use another criteria for that)
*
* @note
*   If more than one `TRCPreProcessor` registered, then result chaining, i.e. output of preProcessor1 used as input
*   for preProcessor2:
*   (object ---> preProcessor1 --> preProcessor2 --> ... --> result)
*   This rule correct for both method in that protocol
*
* */
@protocol TRCPreProcessor<NSObject>

@optional

/**
* This method is invoked at the beginning (after checking for errors, but before validation and post-processing) of response processing.
* The result of this method would be used instead of input responseObject.
* */
- (id)preProcessResponseObject:(id)responseObject forRequest:(id<TRCRequest>)request preProcessError:(NSError **)error;

@end



