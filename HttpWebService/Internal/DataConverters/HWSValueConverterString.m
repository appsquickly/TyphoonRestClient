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





#import "HWSValueConverterString.h"
#import "HWSUtils.h"


@implementation HWSValueConverterString

- (id)objectFromResponseValue:(id)value error:(NSError **)error
{
    return value;
}

- (id)requestValueFromObject:(id)object error:(NSError **)error
{
    if (![object isKindOfClass:[NSString class]]) {
        if (error) {
            *error = NSErrorWithFormat(@"Can't convert '%@' into string", [object class]);
        }
        return nil;
    }
    return object;
}

- (HWSValueConverterType)types
{
    return HWSValueConverterTypeString;
}

@end