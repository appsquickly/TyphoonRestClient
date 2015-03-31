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

#import "TRCSchemeStackTrace.h"

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

@interface TRCSchemeStackTraceContext : NSObject

@property (nonatomic) NSInteger level;
@property (nonatomic, strong) NSArray *stack;
@property (nonatomic) NSString *errorMessage;

@property (nonatomic, strong) TRCSchemeStackTrace *printingStack;

@end

@implementation TRCSchemeStackTraceContext
@end

@implementation TRCSchemeStackTrace
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

- (NSString *)fullDescriptionWithErrorMessage:(NSString *)errorMessage
{
    TRCSchemeStackTraceContext *context = [TRCSchemeStackTraceContext new];
    context.level = 0;
    context.stack = _stack;
    context.errorMessage = errorMessage;
    context.printingStack = [TRCSchemeStackTrace new];

    return [[self class] stringFromObject:self.originalObject context:context];
}

+ (NSString *)descriptionOfObject:(id)object
{
    TRCSchemeStackTraceContext *context = [TRCSchemeStackTraceContext new];
    context.level = 0;

    return [[self class] stringFromObject:object context:context];
}

+ (NSString *)stringFromObject:(id)object context:(TRCSchemeStackTraceContext *)context
{
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [self stringFromDictionary:object context:context];
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [self stringFromArray:object context:context];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [self stringFromNumber:object context:context];
    } else if ([object isKindOfClass:[NSString class]]) {
        return [self stringFromString:object context:context];
    } else if ([object isKindOfClass:[NSNull class]]) {
        return [self stringFromNull:object context:context];
    } else {
        return [object description];
    }
}

+ (NSString *)stringFromDictionary:(NSDictionary *)dictionary context:(TRCSchemeStackTraceContext *)context
{

    NSMutableString *buffer = [NSMutableString new];
    [buffer appendString:@"{"];

    if ([[context.printingStack stack] isEqualToArray:context.stack]) {
        [buffer appendFormat:@"  <----- %@", context.errorMessage];
        context.printingStack = nil;
    }
    [buffer appendString:@"\n"];

    context.level++;
    NSString *indent = [self indentForContext:context];

    NSUInteger count = [dictionary count];
    __block NSUInteger index = 0;

    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {

        [context.printingStack pushSymbol:key];

        [buffer appendFormat:@"%@\"%@\" = %@", indent, key, [self stringFromObject:obj context:context]];

        if ([[context.printingStack stack] isEqualToArray:context.stack]) {
            [buffer appendFormat:@"  <----- %@", context.errorMessage];
            context.printingStack = nil;
        }

        BOOL isLast = (++index == count);
        [buffer appendFormat:@"%@\n",isLast?@"":@","];

        [context.printingStack pop];
    }];

    context.level--;

    [buffer appendFormat:@"%@}", [self indentForContext:context]];

    return buffer;
}

+ (NSString *)stringFromArray:(NSArray *)array context:(TRCSchemeStackTraceContext *)context
{
    context.level++;

    NSMutableString *buffer = [NSMutableString new];

    NSString *indent = [self indentForContext:context];

    [buffer appendString:@"[\n"];

    NSUInteger count = [array count];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        [context.printingStack pushSymbolWithArrayIndex:@(idx)];

        [buffer appendString:indent];
        [buffer appendString:[self stringFromObject:obj context:context]];

        BOOL isLast = (idx == count - 1);
        [buffer appendFormat:@"%@\n",isLast?@"":@","];

        [context.printingStack pop];
    }];

    context.level--;

    [buffer appendFormat:@"%@]", [self indentForContext:context]];

    return buffer;
}

+ (NSString *)stringFromNumber:(NSNumber *)number context:(TRCSchemeStackTraceContext *)context
{
    return [number description];
}

+ (NSString *)stringFromString:(NSString *)string context:(TRCSchemeStackTraceContext *)context
{
    return [NSString stringWithFormat:@"\"%@\"", string];
}

+ (NSString *)stringFromNull:(NSNull *)object context:(TRCSchemeStackTraceContext *)context
{
    return @"null";
}

+ (NSString *)indentForContext:(TRCSchemeStackTraceContext *)context
{
    return [@" " stringByPaddingToLength:(NSUInteger)context.level withString:@" " startingAtIndex:0];
}

@end