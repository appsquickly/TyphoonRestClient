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

/**
* TRCSchemaData is abstract data structure, used to represent schema and validate it's values
* */
@protocol TRCSchemaData <NSObject>

/**
* Walk through all object structure and call appropriate methods from TRCSchemaDataEnumerator protocol in `enumerator`.
* Used by TRCSchema to validate object values
* */
- (void)enumerate:(id)object withEnumerator:(id<TRCSchemaDataEnumerator>)enumerator;

/**
* Walk through all object structure to replace (transform, convert) some of object's values. TRCSchemaDataModifier
* methods used to do that. Used by TRCConverter to convert some values using TRCValueTransformers and TRCObjectMappers.
* */
- (id)modify:(id)object withModifier:(id<TRCSchemaDataModifier>)modifier;

/**
* Cancels current process like enumeration or modifying (see methods above). Called when enumerator or modifier found some
* error and wants to cancel process.
* */
- (void)cancel;

/**
* Tells if current process is cancelled. This method must return YES after `cancel` method called.
* */
- (BOOL)isCancelled;

@end


@protocol TRCSchemaDataDelegate <NSObject>

- (void)schemaData:(id<TRCSchemaData>)data typeMismatchForValue:(id)value withSchemaValue:(id)schemaValue;

@end

@protocol TRCSchemaDataEnumerator <TRCSchemaDataDelegate>

/**
* Calls for each value in object. You can match 'value' with 'schemeValue'. Identifier could be array index or dictionary key
* */
- (void)schemaData:(id<TRCSchemaData>)data foundValue:(id)value withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue;

@optional

/** These two methods calls each collection item. For example for each array and dictionary item: in that case `itemIdentifier`
* is index in array and key in dictionary. Used to get great debugging information.
* */
- (void)schemaData:(id<TRCSchemaData>)data willEnumerateItemAtIndentifier:(id)itemIdentifier;
- (void)schemaData:(id<TRCSchemaData>)data didEnumerateItemAtIndentifier:(id)itemIdentifier;

@end


@protocol TRCSchemaDataModifier <TRCSchemaDataDelegate>

/**
* Returns replacement for value. Used to replace input value using TRCValueTransformers.
* */
- (id)schemaData:(id<TRCSchemaData>)data replacementForValue:(id)object withOptions:(TRCSchemaDataValueOptions *)options withSchemeValue:(id)schemeValue;

/**
* Returns replacement for responseObject using TRCObjectMapper for specified tag. TRCObjectMapper implements logic to
* transform received object into model object.
* For example, for JSON serializer, TRCObjectMappers converts received NSDictionary into your model object.
* */
- (id)schemaData:(id<TRCSchemaData>)data objectFromResponse:(id)object withMapperTag:(NSString *)tag;

/**
* Returns replacement for requestObject using TRCObjectMapper for specified tag. TRCObjectMapper implements logic to
* transform model object passed in request, into object which can be used by request serializer.
* For example, for JSON serialization, TRCObjectMapper converts your model object into NSDictionary which could be
* serialized into JSON string
* */
- (id)schemaData:(id<TRCSchemaData>)data requestFromObject:(id)object withMapperTag:(NSString *)tag;

@end

@protocol TRCSchemaDataProvider <NSObject>

/**
* Returns YES, if provider has object mapper for specified tag
* */
- (BOOL)schemaData:(id<TRCSchemaData>)data hasObjectMapperForTag:(NSString *)mapperTag;

/**
* Returns TRCSchemaData for specified mapperTag or nil, if not exists
* */
- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data requestSchemaForMapperWithTag:(NSString *)mapperTag;

/**
* Returns TRCSchemaData for specified mapperTag or nil, if not exists
* */
- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data responseSchemaForMapperWithTag:(NSString *)mapperTag;

@end