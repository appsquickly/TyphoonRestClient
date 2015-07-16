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
#import "AFURLRequestSerialization.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationMultipart = @"TRCSerializationMultipart";

@implementation TRCSerializerMultipart

- (NSInputStream *)bodyStreamFromObject:(id)requestObject forRequest:(NSMutableURLRequest *)urlRequest error:(NSError **)error
{
    if (![requestObject isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = TRCRequestSerializationErrorWithFormat(@"Can't use '%@' object in TRCSerializerMultipart. Must be NSDictionary.", requestObject);
        }
        return nil;
    } else {

        NSDictionary *requestDictionary = requestObject;

        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];

        NSMutableURLRequest *request = [requestSerializer multipartFormRequestWithMethod:@"POST" URLString:@"http://example.com/" parameters:nil constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
            [requestDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                if ([obj isKindOfClass:[NSData class]]) {
                    [formData appendPartWithFormData:obj name:key];
                } else if ([obj isKindOfClass:[TRCMultipartFile class]]) {
                    TRCMultipartFile *file = obj;
                    [formData appendPartWithFileData:file.data name:key fileName:file.filename mimeType:file.mimeType];
                } else if ([obj isKindOfClass:[NSNull class]]) {
                    [formData appendPartWithFormData:[NSData data] name:key];
                } else if ([obj isKindOfClass:[UIImage class]]) {
                    [formData appendPartWithFileData:UIImageJPEGRepresentation(obj, 0.8) name:key fileName:key mimeType:@"image/jpeg"];
                } else {
                    [formData appendPartWithFormData:[[obj description] dataUsingEncoding:NSUTF8StringEncoding] name:key];
                }
            }];
        } error:error];

        [urlRequest setValue:[request valueForHTTPHeaderField:@"Content-Length"] forHTTPHeaderField:@"Content-Length"];
        [urlRequest setValue:[request valueForHTTPHeaderField:@"Content-Type"] forHTTPHeaderField:@"Content-Type"];

        return [request HTTPBodyStream];
    }
}

@end


@implementation TRCMultipartFile


@end