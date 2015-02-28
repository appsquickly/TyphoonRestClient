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

@protocol TRCObjectMapper<NSObject>

@optional

//-------------------------------------------------------------------------------------------
#pragma mark - Parsing from Request
//-------------------------------------------------------------------------------------------

- (NSString *)responseValidationSchemaName;

- (id)objectFromDictionary:(NSDictionary *)dictionary error:(NSError **)error;

//-------------------------------------------------------------------------------------------
#pragma mark - Composing for Request
//-------------------------------------------------------------------------------------------

- (NSString *)requestValidationSchemaName;

- (NSDictionary *)dictionaryFromObject:(id)object error:(NSError **)error;

@end