//
//  TRCTestableObjectConverter.m
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 17.02.15.
//  Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import "TRCMapperPerson.h"
#import "Person.h"
#import "TRCUtils.h"

@implementation TRCMapperPerson

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(objectFromResponseObject:error:)) {
        return self.responseParsingImplemented;
    } else if (aSelector == @selector(requestObjectFromObject:error:)) {
        return self.requestParsingImplemented;
    }
    return [super respondsToSelector:aSelector];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestParsingImplemented = YES;
        self.responseParsingImplemented =  YES;
    }
    return self;
}

- (id)objectFromResponseObject:(NSDictionary *)responseObject error:(NSError **)error
{
    if ([responseObject[@"first_name"] length] < 2) {
        if (error) {
            *error = NSErrorWithFormat(@"first name can't be less than 2 symbols");
        }
        return nil;
    }

    Person *object = [Person new];
    object.firstName = responseObject[@"first_name"];
    object.lastName = responseObject[@"last_name"];
    object.avatarUrl = responseObject[@"avatar_url"];
    object.phone = responseObject[@"phone"];
    return object;
}

- (id)requestObjectFromObject:(Person *)object error:(NSError **)error
{
    if ([object.firstName length] < 2) {
        if (error) {
            *error = NSErrorWithFormat(@"first name can't be less than 2 symbols");
        }
        return nil;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    dictionary[@"first_name"] = object.firstName;
    dictionary[@"last_name"] = object.lastName;
    dictionary[@"avatar_url"] = object.avatarUrl;
    dictionary[@"phone"] = ValueOrNull(object.phone);
    return dictionary;
}

@end
