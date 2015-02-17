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





#import "TyphoonRestClient.h"

@protocol TRCConvertersRegistry;

@interface TRCSchema : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong) id<TRCConvertersRegistry>converterRegistry;
@property (nonatomic) TRCValidationOptions options;

+ (instancetype)schemaWithName:(NSString *)name;

- (instancetype)initWithFilePath:(NSString *)filePath;

- (BOOL)validateRequest:(id)request error:(NSError **)error;

- (BOOL)validateResponse:(id)response error:(NSError **)error;

- (id)schemeArrayOrDictionary;

- (id)schemeObjectOrArrayItem;

@end