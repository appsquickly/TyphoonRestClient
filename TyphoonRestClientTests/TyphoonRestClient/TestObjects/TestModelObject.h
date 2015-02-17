//
//  TestModelObject.h
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 17.02.15.
//  Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestModelObject : NSObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSURL *avatarUrl;

@end
