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




#import "TRCValueTransformerUrl.h"
#import "TRCUtils.h"
#import "TyphoonRestClientErrors.h"


@implementation TRCValueTransformerUrl

- (id)objectFromResponseValue:(id)value error:(NSError **)error
{
    NSAssert([value isKindOfClass:[NSString class]], @"");
    if ([value isKindOfClass:[NSURL class]]) {
        return value;
    } else if ([value isKindOfClass:[NSString class]]) {
        NSURL *url = [[NSURL alloc] initWithString:value];
        if (!url && error) {
            *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeTransformation, @"Can't create URL from string '%@'", value);
        }
        return url;
    } else {
        if (error) {
            *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeTransformation, @"Can't convert type '%@' to url", [value class]);
        }
        return nil;
    }
}

- (id)requestValueFromObject:(id)object error:(NSError **)error
{
    if ([object isKindOfClass:[NSURL class]]) {
        return [object absoluteString];
    } else if ([object isKindOfClass:[NSString class]]) {
        return object;
    } else {
        if (error) {
            *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeTransformation, @"Can't convert type '%@' to url string", [object class]);
        }
        return nil;
    }
}

@end