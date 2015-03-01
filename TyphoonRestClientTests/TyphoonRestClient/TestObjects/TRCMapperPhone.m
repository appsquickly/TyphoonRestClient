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

- (id)objectFromDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
    Phone *phone = [Phone new];
    phone.mobile = dictionary[@"mobile"];
    phone.work = dictionary[@"work"];
    return phone;
}

- (NSDictionary *)dictionaryFromObject:(Phone *)object error:(NSError **)error
{
    NSMutableDictionary *result = [NSMutableDictionary new];
    result[@"mobile"] = object.mobile?:@"";
    result[@"work"] = object.work?:@"";
    return result;
}

@end