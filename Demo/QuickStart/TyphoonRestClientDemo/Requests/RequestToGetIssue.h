

#import <Foundation/Foundation.h>
#import "TRCRequest.h"

@interface RequestToGetIssue : NSObject <TRCRequest>

- (instancetype)initWithIssueId:(NSNumber *)issueId;

@end
