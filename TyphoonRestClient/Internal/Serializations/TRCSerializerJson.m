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

#import "TRCSerializerJson.h"
#import "TRCSchema.h"
#import "TRCSchemaData.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCUtils.h"
#import "TRCSchemaStackTrace.h"

TRCSerialization TRCSerializationJson = @"TRCSerializationJson";

@interface TRCSchemeStackTraceContext : NSObject

@property (nonatomic) NSInteger level;
@property (nonatomic, strong) NSArray *stack;
@property (nonatomic) NSString *errorMessage;

@property (nonatomic, strong) TRCSchemaStackTrace *printingStack;

@property (nonatomic) BOOL cancelPrinting;

@end

@implementation TRCSchemeStackTraceContext
@end



@interface TRCSerializerJson ()
@property (nonatomic, strong) NSSet *acceptableContentTypes;
@end

@implementation TRCSerializerJson

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
        self.readingOptions = NSJSONReadingAllowFragments;
    }
    return self;
}

//-------------------------------------------------------------------------------------------
#pragma mark - REQUEST SERIALIZATION
//-------------------------------------------------------------------------------------------

- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error
{
    if ([NSJSONSerialization isValidJSONObject:requestObject]) {
        return [NSJSONSerialization dataWithJSONObject:requestObject options:self.writingOptions error:error];
    } else {
        if (error) {
            *error = TRCRequestSerializationErrorWithFormat(@"Can't create JSON string from '%@'. Object is invalid.", requestObject);
        }
        return nil;
    }
}

- (NSString *)contentType
{
    return @"application/json";
}

//-------------------------------------------------------------------------------------------
#pragma mark - RESPONSE SERIALIZATION
//-------------------------------------------------------------------------------------------

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
    return [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:error];
}

- (BOOL)isCorrectContentType:(NSString *)responseContentType
{
    return [self.acceptableContentTypes containsObject:responseContentType];
}

//-------------------------------------------------------------------------------------------
#pragma mark - SCHEMA FORMAT
//-------------------------------------------------------------------------------------------

- (id<TRCSchemaData>)requestSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error
{
    return [self schemeDataFromData:data isRequest:YES dataProvider:dataProvider error:error];
}

- (id<TRCSchemaData>)responseSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error
{
    return [self schemeDataFromData:data isRequest:NO dataProvider:dataProvider error:error];
}

- (id<TRCSchemaData>)schemeDataFromData:(NSData *)data isRequest:(BOOL)request dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error
{
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:error];
    if (jsonObject) {
        return [[TRCSchemaDictionaryData alloc] initWithArrayOrDictionary:jsonObject request:request dataProvider:dataProvider];
    } else {
        return nil;
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - VALIDATION ERROR PRINTER
//-------------------------------------------------------------------------------------------

- (NSString *)errorDescriptionForObject:(id)object errorMessage:(NSString *)errorMessage stackTrace:(NSArray *)stackTrace
{
    TRCSchemeStackTraceContext *context = [TRCSchemeStackTraceContext new];
    context.level = 0;
    if (errorMessage) {
        context.stack = stackTrace;
        context.errorMessage = errorMessage;
        context.printingStack = [TRCSchemaStackTrace new];
    }
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

    [self printErrorMessageIfNeededIntoBuffer:buffer withContext:context];

    [buffer appendString:@"\n"];

    context.level++;
    NSString *indent = [self indentForContext:context];

    NSUInteger count = [dictionary count];
    __block NSUInteger index = 0;

    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {

        [context.printingStack pushSymbol:key];

        [buffer appendFormat:@"%@\"%@\" = %@", indent, key, [self stringFromObject:obj context:context]];

        [self printErrorMessageIfNeededIntoBuffer:buffer withContext:context];

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

        [context.printingStack pushSymbol:@(idx)];

        [buffer appendString:indent];
        [buffer appendString:[self stringFromObject:obj context:context]];

        BOOL isLast = (idx == count - 1);
        [buffer appendFormat:@"%@",isLast?@"":@","];

        [self printErrorMessageIfNeededIntoBuffer:buffer withContext:context];

        [buffer appendString:@"\n"];
        [context.printingStack pop];
    }];

    context.level--;

    [buffer appendFormat:@"%@]", [self indentForContext:context]];

    return buffer;
}

+ (void)printErrorMessageIfNeededIntoBuffer:(NSMutableString *)buffer withContext:(TRCSchemeStackTraceContext *)context
{
    if ([[context.printingStack stack] isEqualToArray:context.stack]) {
        [buffer appendFormat:@"  <----- %@", context.errorMessage];
        context.printingStack = nil;
    }
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


