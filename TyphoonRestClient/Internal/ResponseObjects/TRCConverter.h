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
#import "TRCRequest.h"
#import "TyphoonRestClient.h"

@protocol TRCValueConverterRegistry;

/** TRCConverter converts whole responses or requests using TRCValueConverter from registry */

@interface TRCConverter : NSObject

@property (nonatomic, strong) id<TRCValueConverterRegistry> registry;
@property (nonatomic) TRCValidationOptions options;

#pragma mark - Initialization

- (instancetype)initWithResponseValue:(id)arrayOrDictionary schemaValue:(id)schemaArrayOrDictionary schemaName:(NSString *)schemaName;

- (instancetype)initWithRequestValue:(id)arrayOrDictionary schemaValue:(id)schemaArrayOrDictionary schemaName:(NSString *)schemaName;

#pragma mark - Instance methods

- (id)convertValues;

#pragma mark - Errors

- (NSError *)conversionError;

- (NSOrderedSet *)conversionErrorSet;

@end
