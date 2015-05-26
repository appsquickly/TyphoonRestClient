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

#import "TRCValueTransformerDateISO8601.h"
#import "TRCUtils.h"
#import "TyphoonRestClientErrors.h"

@implementation TRCValueTransformerDateISO8601

+ (NSDateFormatter *)sharedDateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:posix];
    });
    return dateFormatter;
}

- (NSDate *)objectFromResponseValue:(NSString *)responseValue error:(NSError **)error
{
    NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
    
    NSDate *date = [dateFormatter dateFromString:responseValue];
    if (!date && error) {
        *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeResponseSerialization, @"Can't create NSDate from string '%@'", responseValue);
    }
    return date;
}

- (NSString *)requestValueFromObject:(id)object error:(NSError **)error
{
    if (![object isKindOfClass:[NSDate class]]) {
        if (error) {
            *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeRequestSerialization, @"Can't convert '%@' into NSString using %@", [object class], [self class]);
        }
        return nil;
    }
    NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
    
    NSString *string = [dateFormatter stringFromDate:object];
    
    if (!string && error) {
        *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeRequestSerialization, @"Can't convert NSDate '%@' into NSStrign", object);
    }
    
    return string;
}

@end
