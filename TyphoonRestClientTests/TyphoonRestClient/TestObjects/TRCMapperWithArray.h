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
#import "TRCObjectMapper.h"

@interface TRCMapperWithArrayItemsCollection : NSObject


- (instancetype)initWithItems:(NSArray *)items;

- (NSArray *)allItems;

@end

@interface TRCMapperWithArrayItem : NSObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *text;

@end

@interface TRCMapperWithArray : NSObject <TRCObjectMapper>

@end