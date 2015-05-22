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

#import "RequestToGetIssueIntoRoot.h"


@implementation RequestToGetIssueIntoRoot
{

}
- (NSString *)path
{
    return @"issues/test_root";
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodGet;
}

@end