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
@protocol TRCValueTransformer;

@protocol TRCConvertersRegistry<NSObject>

//-------------------------------------------------------------------------------------------
#pragma mark - Value Converters
//-------------------------------------------------------------------------------------------

- (id<TRCValueTransformer>)valueTransformerForTag:(NSString *)tag;

//-------------------------------------------------------------------------------------------
#pragma mark - Object Mappers
//-------------------------------------------------------------------------------------------

- (id<TRCObjectMapper>)objectMapperForTag:(NSString *)tag;

//-------------------------------------------------------------------------------------------
#pragma mark - Error Printer
//-------------------------------------------------------------------------------------------

- (id<TRCValidationErrorPrinter>)validationErrorPrinterForExtension:(NSString *)extension;

@end