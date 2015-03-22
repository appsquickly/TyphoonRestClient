//
//  Person.h
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 17.02.15.
//  Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Phone;

@interface Person : NSObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSURL *avatarUrl;
@property (nonatomic, strong) Phone *phone;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToPerson:(Person *)person;

- (NSUInteger)hash;

@end
