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

@class TRCSchema;
@protocol TRCRequest;
@protocol TRCErrorHandler;
@protocol TRCObjectMapper;
@protocol TRCSchemaFormat;
@class TyphoonRestClient;
@protocol TRCSchemaData;


@interface TRCSchemeFactory : NSObject

@property (nonatomic, weak) TyphoonRestClient *owner;

- (TRCSchema *)schemeForErrorHandler:(id<TRCErrorHandler>)parser;

- (TRCSchema *)schemeForPathParametersWithRequest:(id<TRCRequest>)request;

- (TRCSchema *)schemeForRequest:(id<TRCRequest>)request;

- (TRCSchema *)schemeForResponseWithRequest:(id<TRCRequest>)request;

- (id<TRCSchemaData>)requestSchemaDataForMapper:(id<TRCObjectMapper>)mapper;

- (id<TRCSchemaData>)responseSchemaDataForMapper:(id<TRCObjectMapper>)mapper;

- (TRCSchema *)schemeFromData:(id<TRCSchemaData>)data withName:(NSString *)name;

//-------------------------------------------------------------------------------------------
#pragma mark - Registry
//-------------------------------------------------------------------------------------------

- (void)registerSchemeFormat:(id<TRCSchemaFormat>)schemeFormat forFileExtension:(NSString *)extension;

@end