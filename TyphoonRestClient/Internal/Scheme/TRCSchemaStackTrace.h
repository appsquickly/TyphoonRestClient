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


@interface TRCSchemaStackTrace : NSObject

@property (nonatomic, strong) id originalObject;

- (NSArray *)stack;

- (void)pushSymbol:(NSString *)symbol;
- (void)pushSymbolWithArrayIndex:(NSNumber *)index;
- (void)pop;

- (NSString *)shortDescription;

@end