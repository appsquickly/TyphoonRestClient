//
// Created by alex on 28/07/15.
// Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import "RequestToSetIssue.h"


@implementation RequestToSetIssue
{

}
- (NSString *)path
{
    return @"issue";
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodPost;
}

- (id)requestBody
{
    return @{
            @"id": @123
    };
}


@end