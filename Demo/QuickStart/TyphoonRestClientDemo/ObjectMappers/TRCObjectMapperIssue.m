////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON REST CLIENT
//  Copyright 2015, Typhoon Rest Client Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import "TRCObjectMapperIssue.h"
#import "Issue.h"

@implementation TRCObjectMapperIssue

- (id)objectFromResponseObject:(NSDictionary *)dict error:(NSError **)error
{
    Issue *issue = [Issue new];
    issue.identifier = dict[@"id"];
    issue.projectName = dict[@"project"][@"name"];
    issue.authorName = dict[@"author"][@"name"];
    issue.statusText = dict[@"status"][@"name"];
    issue.subject = dict[@"subject"];
    issue.descriptionText = dict[@"description"];
    issue.updated = dict[@"created_on"];
    issue.created = dict[@"updated_on"];
    issue.doneRatio = dict[@"done_ratio"];
    return issue; //You allowed to return nil. If items in the array, this item would be skipped
}

@end
