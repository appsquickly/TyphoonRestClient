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


@interface TRCSchemaStackTrace : NSObject

@property (nonatomic, strong) id originalObject;

- (NSArray *)stack;

- (void)pushSymbol:(id)symbol;
- (void)pop;

- (NSString *)shortDescription;

+ (NSString *)shortDescriptionFromObject:(id)object;

@end