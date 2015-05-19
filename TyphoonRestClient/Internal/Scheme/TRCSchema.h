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

#ifndef TRCSchemaTrackErrorTrace
    #define TRCSchemaTrackErrorTrace 1
#endif

#import "TyphoonRestClient.h"

@protocol TRCConvertersRegistry;
@protocol TRCSchemaData;

@interface TRCSchema : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) id<TRCSchemaData> data;

@property (nonatomic, weak) id<TRCConvertersRegistry> converterRegistry;
@property (nonatomic) TRCValidationOptions options;

+ (instancetype)schemaWithData:(id<TRCSchemaData>)data name:(NSString *)name;

- (BOOL)validateRequest:(id)request error:(NSError **)error;

- (BOOL)validateResponse:(id)response error:(NSError **)error;

@end