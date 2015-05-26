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
#import "TRCSchemaData.h"

/**
* Concrete implementation of TRCSchemaData protocol. Represents classical dictionary data structure, like JSON and Plist has.
* Each value in dictionary is one of
* - dictionary
* - array
* - object
* */
@interface TRCSchemaDictionaryData : NSObject <TRCSchemaData>

@property (nonatomic, getter=isRequestData, readonly) BOOL requestData;

@property (nonatomic, weak, readonly) id<TRCSchemaDataProvider> dataProvider;

- (instancetype)initWithArrayOrDictionary:(id)arrayOrDictionary request:(BOOL)isRequest dataProvider:(id<TRCSchemaDataProvider>)dataProvider;

@end