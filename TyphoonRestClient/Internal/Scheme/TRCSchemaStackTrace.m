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
    return [[self class] shortDescriptionFromObject:_stack];
}

+ (NSString *)shortDescriptionFromObject:(id)object
{
    NSMutableString *buffer = [NSMutableString new];
    [buffer appendString:@"root"];
    for (id symbol in object) {
        if ([symbol isKindOfClass:[NSString class]]) {
            [buffer appendFormat:@".%@",symbol];
        } else if ([symbol isKindOfClass:[NSNumber class]]) {
            [buffer appendFormat:@"[%@]",symbol];
        }
    }
    return buffer;
}


@end