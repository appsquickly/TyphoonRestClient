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


@interface TRCSchemeStackTrace : NSObject

@property (nonatomic, strong) id originalObject;

- (void)pushSymbol:(NSString *)symbol;
- (void)pushSymbolWithArrayIndex:(NSUInteger)index;
- (void)pop;

- (NSString *)shortDescription;
- (NSString *)fullDescriptionWithErrorMessage:(NSString *)errorMessage;

+ (NSString *)descriptionOfObject:(id)object;

@end