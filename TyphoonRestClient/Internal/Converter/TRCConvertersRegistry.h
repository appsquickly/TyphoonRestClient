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