
#import "RequestToUploadFile.h"

@implementation RequestToUploadFile

- (NSString *)path
{
    return @"uploads.json";
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodPost;
}

- (id)requestBody
{
    return [NSInputStream inputStreamWithFileAtPath:self.uploadPath];
}

- (NSDictionary *)requestHeaders
{
    return @{
        @"Content-Type": @"application/octet-stream"
    };
}

- (id)responseProcessedFromBody:(NSDictionary *)bodyObject headers:(NSDictionary *)responseHeaders status:(TRCHttpStatusCode)statusCode error:(NSError **)parseError
{
    return bodyObject[@"upload"][@"token"];
}

@end
