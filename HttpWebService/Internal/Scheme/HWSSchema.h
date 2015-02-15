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





#import "HttpWebService.h"

@protocol HWSValueConverterRegistry;

@interface HWSSchema : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong) id<HWSValueConverterRegistry>converterRegistry;
@property (nonatomic) HWSValidationOptions options;

+ (instancetype)schemaWithName:(NSString *)name;

- (instancetype)initWithFilePath:(NSString *)filePath;

- (BOOL)validateRequest:(id)request error:(NSError **)error;

- (BOOL)validateResponse:(id)response error:(NSError **)error;

- (id)schemeArrayOrDictionary;

- (id)schemeObjectOrArrayItem;

@end