
#import "RequestToDownloadFile.h"

@implementation RequestToDownloadFile

- (NSString *)path
{
    return [self.downloadUrl absoluteString];
}

- (TRCRequestMethod)method
{
    return TRCRequestMethodGet;
}

- (NSOutputStream *)responseBodyOutputStream
{
    return [NSOutputStream outputStreamToFileAtPath:self.outputPath append:NO];
}

- (TRCResponseSerialization)responseSerialization
{
    return TRCResponseSerializationData;
}

- (id)responseProcessedFromBody:(NSData *)bodyObject headers:(NSDictionary *)responseHeaders status:(TRCHttpStatusCode)statusCode error:(NSError **)parseError
{
    [bodyObject writeToFile:self.outputPath atomically:YES];
    return nil;
}

@end
