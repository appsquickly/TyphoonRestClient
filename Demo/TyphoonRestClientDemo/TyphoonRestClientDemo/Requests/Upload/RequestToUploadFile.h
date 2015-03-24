
#import "TRCRequest.h"

@interface RequestToUploadFile : NSObject <TRCRequest>

@property (nonatomic, strong) NSString *uploadPath;

@end
