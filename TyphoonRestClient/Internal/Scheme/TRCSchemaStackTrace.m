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

#import "TRCSchemaStackTrace.h"

@implementation TRCSchemaStackTrace
{
    NSMutableArray *_stack;
}

- (NSArray *)stack
{
    return _stack;
}

- (id)init
{
    self = [super init];
    if (self) {
        _stack = [NSMutableArray new];
    }
    return self;
}

- (void)pushSymbol:(NSString *)symbol
{
    [_stack addObject:symbol];
}

- (void)pop
{
    [_stack removeLastObject];
}

- (NSString *)shortDescription
{
    NSMutableString *buffer = [NSMutableString new];
    [buffer appendString:@"root"];
    for (id symbol in _stack) {
        if ([symbol isKindOfClass:[NSString class]]) {
            [buffer appendFormat:@".%@",symbol];
        } else if ([symbol isKindOfClass:[NSNumber class]]) {
            [buffer appendFormat:@"[%@]",symbol];
        }
    }
    return buffer;
}



@end