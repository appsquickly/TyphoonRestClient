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