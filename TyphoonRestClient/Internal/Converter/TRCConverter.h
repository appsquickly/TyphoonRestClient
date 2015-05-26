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
#import "TRCRequest.h"
#import "TyphoonRestClient.h"

@protocol TRCConvertersRegistry;
@class TRCSchema;

/** TRCConverter converts whole responses or requests using TRCValueTransformer from registry */

@interface TRCConverter : NSObject

@property (nonatomic, strong) id<TRCConvertersRegistry> registry;
@property (nonatomic) TRCValidationOptions options;

#pragma mark - Initialization

- (instancetype)initWithSchema:(TRCSchema *)schema;

#pragma mark - Instance methods

- (id)convertResponseValue:(id)value error:(NSError **)error;

- (id)convertRequestValue:(id)value error:(NSError **)error;

#pragma mark - Errors

- (NSError *)conversionError;

- (NSOrderedSet *)conversionErrorSet;

@end
