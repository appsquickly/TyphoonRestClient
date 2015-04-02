////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import "TRCMapperPhone.h"
#import "Phone.h"


@implementation TRCMapperPhone

- (id)objectFromResponseObject:(NSDictionary *)responseObject error:(NSError **)error
{
    Phone *phone = [Phone new];
    phone.mobile = responseObject[@"mobile"];
    phone.work = responseObject[@"work"];
    return phone;
}

- (id)requestObjectFromObject:(Phone *)object error:(NSError **)error
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    result[@"mobile"] = object.mobile?:@"";
    result[@"work"] = object.work?:@"";
    return result;
}

@end