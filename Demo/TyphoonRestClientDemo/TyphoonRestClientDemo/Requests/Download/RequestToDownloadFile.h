
#import "TRCRequest.h"

@interface RequestToDownloadFile : NSObject <TRCRequest>

@property (nonatomic, strong) NSURL *downloadUrl;
@property (nonatomic, strong) NSString *outputPath;

@end
