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

#import "TRCMapperWithArray.h"

@implementation TRCMapperWithArrayItemsCollection {
    NSMutableArray *_items;
}
- (instancetype)initWithItems:(NSArray *)items
{
    self = [super init];
    if (self) {
        _items = [items mutableCopy];
    }
    return self;
}

- (NSArray *)allItems
{
    return _items;
}

@end

@implementation TRCMapperWithArrayItem

@end

@implementation TRCMapperWithArray

- (id)objectFromResponseObject:(NSArray *)responseObject error:(NSError **)error
{
    NSMutableArray *array = [NSMutableArray new];
    for (NSDictionary *dict in responseObject) {
        TRCMapperWithArrayItem *item = [TRCMapperWithArrayItem new];
        item.identifier = dict[@"id"];
        item.text = dict[@"text"];
        [array addObject:item];
    }
    return [[TRCMapperWithArrayItemsCollection alloc] initWithItems:array];
}

- (NSArray *)requestObjectFromObject:(TRCMapperWithArrayItemsCollection *)object error:(NSError **)error
{
    NSMutableArray *array = [NSMutableArray new];

    for (TRCMapperWithArrayItem *item in [object allItems]) {
        [array addObject:@{
                @"id": item.identifier,
                @"text": item.text
        }];
    }
    return array;
}

@end