// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TRCHttpQueryComposer.h"
#import "TRCSerializerHttpQuery.h"

static NSString * const kTRCCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * TRCPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kTRCCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";

    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kTRCCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kTRCCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * TRCPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kTRCCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

@implementation TRCQueryStringPair

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return TRCPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", TRCPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding), TRCPercentEscapedQueryStringValueFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

static NSArray *TRCQueryStringPairsFromKeyAndValue(NSString *key, id value, TRCSerializerHttpQueryOptions options)
{
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:TRCQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]",
                                                                                                                                       key,
                                                                                                                                       nestedKey] : nestedKey), nestedValue, options)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        [array enumerateObjectsUsingBlock:^(id nestedValue, NSUInteger idx, BOOL *stop) {
            NSString *fullKey = nil;
            if (options & TRCSerializerHttpQueryOptionsIncludeArrayIndices) {
                fullKey =  [NSString stringWithFormat:@"%@[%lu]", key, (long unsigned)idx];
            } else {
                fullKey =  [NSString stringWithFormat:@"%@[]", key];
            }
            [mutableQueryStringComponents addObjectsFromArray:TRCQueryStringPairsFromKeyAndValue(fullKey, nestedValue, options)];
        }];
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:TRCQueryStringPairsFromKeyAndValue(key, obj, options)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[TRCQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

NSArray<TRCQueryStringPair *> *TRCQueryStringPairsFromDictionary(NSDictionary *dictionary, TRCSerializerHttpQueryOptions options)
{
    return TRCQueryStringPairsFromKeyAndValue(nil, dictionary, options);
}