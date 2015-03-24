

#import "TRCRequest.h"

@interface RequestToGetIssues : NSObject <TRCRequest>

@property (nonatomic) NSRange range;
@property (nonatomic) NSNumber *projectId;

@end
