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


#import "TRCValueTransformerString.h"
#import "TRCUtils.h"
#import "TyphoonRestClientErrors.h"


@implementation TRCValueTransformerString

- (id)objectFromResponseValue:(id)value error:(NSError **)error
{
    return value;
}

- (id)requestValueFromObject:(id)object error:(NSError **)error
{
    if (![object isKindOfClass:[NSString class]]) {
        if (error) {
            *error = TRCErrorWithFormat(TyphoonRestClientErrorCodeTransformation, @"Can't convert '%@' into string", [object class]);
        }
        return nil;
    }
    return object;
}

@end