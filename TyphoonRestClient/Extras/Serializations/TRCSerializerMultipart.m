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


#import "TRCSerializerMultipart.h"
#import "TRCUtils.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


static NSString * const TRCMultipartFormCRLF = @"\r\n";

TRCSerialization TRCSerializationMultipart = @"TRCSerializationMultipart";

@implementation TRCSerializerMultipart

- (NSData *)bodyDataFromObject:(id)requestObject forRequest:(NSMutableURLRequest *)request error:(NSError **)error
{
    NSData *bodyData = nil;

    if (![requestObject isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = TRCRequestSerializationErrorWithFormat(@"Can't use '%@' object in TRCSerializerMultipart. Must be NSDictionary.", requestObject);
        }
    } else {
        NSString *boundary = [self newBoundary];

        bodyData = [self bodyDataFromParameters:requestObject boundary:boundary];

        [request setValue:[self contentLengthForData:bodyData] forHTTPHeaderField:@"Content-Length"];
        [request setValue:[self contentTypeForBoundary:boundary] forHTTPHeaderField:@"Content-Type"];
    }

    return bodyData;
}

- (NSData *)bodyDataFromParameters:(NSDictionary *)parameters boundary:(NSString *)boundary
{
    NSMutableData *data = [NSMutableData new];

    __block BOOL didAppendInitialBoundary = NO;
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *name, id parameter, BOOL *stop) {
        if (didAppendInitialBoundary) {
            [self data:data appendIntermidiantBoundary:boundary];
        } else {
            [self data:data appendInitialBoundary:boundary];
            didAppendInitialBoundary = YES;
        }
        [self data:data appendParameter:parameter withName:name];
    }];

    [self data:data appendFinalBoundary:boundary];

    return data;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Boundaries
//-------------------------------------------------------------------------------------------

- (NSString *)newBoundary
{
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

- (void)data:(NSMutableData *)data appendInitialBoundary:(NSString *)boundary
{
    NSString *initialBoundaryString = [NSString stringWithFormat:@"--%@%@", boundary, TRCMultipartFormCRLF];
    NSData *initialBoundaryData = [initialBoundaryString dataUsingEncoding:NSUTF8StringEncoding];
    [data appendData:initialBoundaryData];
}

- (void)data:(NSMutableData *)data appendIntermidiantBoundary:(NSString *)boundary
{
    NSString *boundaryString = [NSString stringWithFormat:@"%@--%@%@", TRCMultipartFormCRLF, boundary, TRCMultipartFormCRLF];
    NSData *boundaryData = [boundaryString dataUsingEncoding:NSUTF8StringEncoding];
    [data appendData:boundaryData];
}

- (void)data:(NSMutableData *)data appendFinalBoundary:(NSString *)boundary
{
    NSString *boundaryString = [NSString stringWithFormat:@"%@--%@--%@", TRCMultipartFormCRLF, boundary, TRCMultipartFormCRLF];
    NSData *boundaryData = [boundaryString dataUsingEncoding:NSUTF8StringEncoding];
    [data appendData:boundaryData];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Part data
//-------------------------------------------------------------------------------------------

- (void)data:(NSMutableData *)data appendParameter:(id)param withName:(NSString *)name
{
    NSData *partData;
    if ([param isKindOfClass:[NSData class]]) {
        partData = [self partDataFromData:param withName:name];
    } else if ([param isKindOfClass:[TRCMultipartFile class]]) {
        partData = [self partDataFromFile:param withName:name];
    } else if ([param isKindOfClass:[NSNull class]]) {
        partData = [self partDataFromData:[NSData data] withName:name];
    }
#if TARGET_OS_IPHONE
    else if ([param isKindOfClass:[UIImage class]]) {
        TRCMultipartFile *file = [TRCMultipartFile new];
        file.data = UIImageJPEGRepresentation(param, 0.8);
        file.filename = name;
        file.mimeType = @"image/jpeg";
        partData = [self partDataFromFile:file withName:name];
    }
#endif
    else {
        NSData *partBodyData = [[param description] dataUsingEncoding:NSUTF8StringEncoding];
        partData = [self partDataFromData:partBodyData withName:name];
    }
    [data appendData:partData];
}

- (NSData *)partDataFromFile:(TRCMultipartFile *)file withName:(NSString *)name
{
    NSDictionary *headers = @{
            @"Content-Disposition": [NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, file.filename?:name],
            @"Content-Type": file.mimeType?:@""
    };
    return [self partDataFromData:file.data withHeaders:headers];
}

- (NSData *)partDataFromData:(NSData *)partData withName:(NSString *)name
{
    NSDictionary *headers = @{
            @"Content-Disposition": [NSString stringWithFormat:@"form-data; name=\"%@\"", name]
    };
    return [self partDataFromData:partData withHeaders:headers];
}

- (NSData *)partDataFromData:(NSData *)bodyData withHeaders:(NSDictionary *)headers
{
    NSData *headersData = [self dataFromHeaders:headers];
    NSMutableData *partData = [NSMutableData dataWithCapacity:[headersData length] + [bodyData length]];
    [partData appendData:headersData];
    [partData appendData:bodyData];
    return partData;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Headers
//-------------------------------------------------------------------------------------------

- (NSData *)dataFromHeaders:(NSDictionary *)headers
{
    NSMutableString *headersString = [NSMutableString new];
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSString *value, BOOL *stop) {
        if ([value length] > 0) {
            [headersString appendString:[NSString stringWithFormat:@"%@: %@%@", name, value, TRCMultipartFormCRLF]];
        }
    }];
    [headersString appendString:TRCMultipartFormCRLF];

    return  [headersString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)contentTypeForBoundary:(NSString *)boundary
{
    return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
}

- (NSString *)contentLengthForData:(NSData *)data
{
    return [NSString stringWithFormat:@"%llu", (unsigned long long int)[data length]];
}

@end


@implementation TRCMultipartFile


@end
