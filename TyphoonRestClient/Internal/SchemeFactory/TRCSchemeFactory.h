////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
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

//-------------------------------------------------------------------------------------------
#pragma mark - Registry
//-------------------------------------------------------------------------------------------

- (void)registerSchemeFormat:(id<TRCSchemaFormat>)schemeFormat forFileExtension:(NSString *)extension;

@end