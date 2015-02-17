//
// Created by Aleksey Garbarev on 21.09.14.
// Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import "TRCValueConverterStub.h"

@implementation TRCValueConverterStub

- (id)objectFromResponseValue:(id)value error:(NSError **)error
{
    if (self.error) {
        if (error) {
            *error = self.error;
        }
        return nil;
    }

    return self.object;
}

- (id)requestValueFromObject:(id)object error:(NSError **)error
{
    if (self.error) {
        if (error) {
            *error = self.error;
        }
        return nil;
    }

    return self.value;
}

- (TRCValueConverterType)types
{
    return self.supportedTypes;
}

@end