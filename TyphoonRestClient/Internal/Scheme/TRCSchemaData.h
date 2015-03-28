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

@protocol TRCSchemaData <NSObject>

- (void)process:(id)object into:(id *)result withDelegate:(id)delegate;

- (void)stop;

@end

@protocol TRCSchemaDataDelegate <NSObject>

- (void)schemaData:(id<TRCSchemaData>)data willEnumerateCollection:(id)collection;

- (void)schemaData:(id<TRCSchemaData>)data willEnumerateItemAtIndentifier:(id)itemIdentifier;

- (void)schemaData:(id<TRCSchemaData>)data foundValue:(id)value withSchemeValue:(id)schemeValue replacement:(id *)replacement;

- (void)schemaData:(id<TRCSchemaData>)data didEnumerateItemAtIndentifier:(id)itemIdentifier;

- (void)schemaData:(id<TRCSchemaData>)data didEnumerateCollection:(id)collection;

@end