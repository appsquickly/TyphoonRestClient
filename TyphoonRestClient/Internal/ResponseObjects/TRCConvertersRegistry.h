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




#import <Foundation/Foundation.h>

@protocol TRCValueConverter;

@protocol TRCConvertersRegistry<NSObject>

//-------------------------------------------------------------------------------------------
#pragma mark - Value Converters
//-------------------------------------------------------------------------------------------

- (id<TRCValueConverter>)valueConverterForTag:(NSString *)tag;

//-------------------------------------------------------------------------------------------
#pragma mark - Object Mappers
//-------------------------------------------------------------------------------------------

- (id<TRCObjectMapper>)objectMapperForTag:(NSString *)tag;

- (id)convertValuesInResponse:(id)arrayOrDictionary schema:(TRCSchema *)scheme error:(NSError **)parseError;

- (id)convertValuesInRequest:(id)arrayOrDictionary schema:(TRCSchema *)scheme error:(NSError **)parseError;

- (TRCSchema *)requestSchemaForMapperWithTag:(NSString *)tag;

- (TRCSchema *)responseSchemaForMapperWithTag:(NSString *)tag;

@end