//
//  Person.m
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 17.02.15.
//  Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import "Person.h"
#import "Phone.h"

@implementation Person

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToPerson:other];
}

- (BOOL)isEqualToPerson:(Person *)person
{
    if (self == person)
        return YES;
    if (person == nil)
        return NO;
    if (self.firstName != person.firstName && ![self.firstName isEqualToString:person.firstName])
        return NO;
    if (self.lastName != person.lastName && ![self.lastName isEqualToString:person.lastName])
        return NO;
    if (self.avatarUrl != person.avatarUrl && ![self.avatarUrl isEqual:person.avatarUrl])
        return NO;
    if (self.phone != person.phone && ![self.phone isEqual:person.phone])
        return NO;
    return YES;
}

- (NSUInteger)hash
{
    NSUInteger hash = [self.firstName hash];
    hash = hash * 31u + [self.lastName hash];
    hash = hash * 31u + [self.avatarUrl hash];
    hash = hash * 31u + [self.phone hash];
    return hash;
}

@end
