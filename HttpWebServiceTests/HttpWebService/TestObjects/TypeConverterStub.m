//
// Created by Aleksey Garbarev on 21.09.14.
// Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import "TypeConverterStub.h"

@implementation TypeConverterStub

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

- (HWSValueConverterType)types
{
    return self.supportedTypes;
}

@end