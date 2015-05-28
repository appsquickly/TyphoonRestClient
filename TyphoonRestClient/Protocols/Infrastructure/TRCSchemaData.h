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

/**
* Called when TRCSchemaData can't enumerate or modify object because type mismatching in schema and object structure.
* This can be called, for example, when schema value is array, but object's value is string, so TRCSchemaData can't
* iterate dictionary in same way as string.
* */
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

/**
* Implementation of this protocol provides `TRCSchemaData` data for specified mapper tag or `nil`
*
* Used by `TRCSchemaData`, to load child schemes and replace mapper tags with them.
* */
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