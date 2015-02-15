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




#import "HWSValueConverterUrl.h"
#import "HWSUtils.h"


@implementation HWSValueConverterUrl

- (id)objectFromResponseValue:(id)value error:(NSError **)error
{
    NSURL *url = [[NSURL alloc] initWithString:value];
    if (!url && error) {
        *error = NSErrorWithFormat(@"Can't create URL from string '%@'", value);
    }
    return url;
}

- (id)requestValueFromObject:(id)object error:(NSError **)error
{
    if ([object isKindOfClass:[NSURL class]]) {
        return [object absoluteString];
    } else if ([object isKindOfClass:[NSString class]]) {
        return object;
    } else {
        if (error) {
            *error = NSErrorWithFormat(@"Can't convert type '%@' to url string", [object class]);
        }
        return nil;
    }
}

@end