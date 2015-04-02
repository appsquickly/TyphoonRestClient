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
#import "TRCSchemaDataValueOptions.h"

@protocol TRCSchemaDataModifier;
@protocol TRCSchemaDataDelegate;
@protocol TRCSchemaDataEnumerator;

@protocol TRCSchemaData <NSObject>

- (void)enumerate:(id)object withEnumerator:(id<TRCSchemaDataEnumerator>)enumerator;

- (id)modify:(id)object withModifier:(id<TRCSchemaDataModifier>)modifier;

- (void)cancel;

@end


@protocol TRCSchemaDataDelegate <NSObject>

- (void)schemaData:(id<TRCSchemaData>)data typeMismatchForValue:(id)value withSchemaValue:(id)schemaValue;

@end

@protocol TRCSchemaDataEnumerator <TRCSchemaDataDelegate>

/** Calls for each value in object. You can match 'value' with 'schemeValue'. Identifier could be array index or dictionary key   */
- (void)schemaData:(id<TRCSchemaData>)data foundValue:(id)value withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue;

@optional

- (void)schemaData:(id<TRCSchemaData>)data willEnumerateItemAtIndentifier:(id)itemIdentifier;

- (void)schemaData:(id<TRCSchemaData>)data didEnumerateItemAtIndentifier:(id)itemIdentifier;

@end


@protocol TRCSchemaDataModifier <TRCSchemaDataDelegate>

/** Returns replacement for value. Used for TRCValueTransformers. */
- (id)schemaData:(id<TRCSchemaData>)data replacementForValue:(id)object withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue;

- (id)schemaData:(id<TRCSchemaData>)data objectFromResponse:(id)object withMapperTag:(NSString *)tag;

- (id)schemaData:(id<TRCSchemaData>)data requestFromObject:(id)object withMapperTag:(NSString *)tag;

@end

@protocol TRCSchemaDataProvider <NSObject>

- (BOOL)schemaData:(id<TRCSchemaData>)data hasObjectMapperForTag:(NSString *)schemaName;

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data requestSchemaForMapperWithTag:(NSString *)schemaName;

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data responseSchemaForMapperWithTag:(NSString *)schemaName;

@end