////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2016 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import "SyncOperationQueue.h"


@implementation SyncOperationQueue
{

}

- (void)addOperation:(NSOperation *)op
{
    if ([op isConcurrent]) {
        [super addOperation:op];
    } else {
        [op start];
    }
}
@end