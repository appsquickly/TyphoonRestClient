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

typedef NS_ENUM(NSInteger, TRCSchemeStackTraceSymbolType) {
    TRCSchemeStackTraceSymbolTypeKey,
    TRCSchemeStackTraceSymbolTypeIndex
};

@interface TRCSchemeStackTraceSymbol : NSObject

@property (nonatomic) TRCSchemeStackTraceSymbolType type;
@property (nonatomic, strong) id value;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToSymbol:(TRCSchemeStackTraceSymbol *)symbol;

- (NSUInteger)hash;

@end

@implementation TRCSchemeStackTraceSymbol

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"type=%@, ",(self.type==TRCSchemeStackTraceSymbolTypeKey)?@"key":@"index"];
    [description appendFormat:@"value=%@",self.value];
    [description appendString:@">"];
    return description;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToSymbol:other];
}

- (BOOL)isEqualToSymbol:(TRCSchemeStackTraceSymbol *)symbol
{
    if (self == symbol)
        return YES;
    if (symbol == nil)
        return NO;
    if (self.type != symbol.type)
        return NO;
    if (self.value != symbol.value && ![self.value isEqual:symbol.value])
        return NO;
    return YES;
}

- (NSUInteger)hash
{
    NSUInteger hash = (NSUInteger)self.type;
    hash = hash * 31u + [self.value hash];
    return hash;
}

@end

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
    TRCSchemeStackTraceSymbol *stackItem = [TRCSchemeStackTraceSymbol new];
    stackItem.type = TRCSchemeStackTraceSymbolTypeKey;
    stackItem.value = symbol;
    [_stack addObject:stackItem];
}

- (void)pushSymbolWithArrayIndex:(NSNumber *)index
{
    TRCSchemeStackTraceSymbol *stackItem = [TRCSchemeStackTraceSymbol new];
    stackItem.type = TRCSchemeStackTraceSymbolTypeIndex;
    stackItem.value = index;
    [_stack addObject:stackItem];
}

- (void)pop
{
    [_stack removeLastObject];
}

- (NSString *)shortDescription
{
    NSMutableString *buffer = [NSMutableString new];
    [buffer appendString:@"root"];
    for (TRCSchemeStackTraceSymbol *symbol in _stack) {
        if ([symbol type] == TRCSchemeStackTraceSymbolTypeKey) {
            [buffer appendFormat:@".%@",symbol.value];
        } else {
            [buffer appendFormat:@"[%@]",symbol.value];
        }
    }
    return buffer;
}



@end