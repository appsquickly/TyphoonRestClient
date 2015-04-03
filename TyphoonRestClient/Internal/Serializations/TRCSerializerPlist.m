////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import "TRCSerializerPlist.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCRequest.h"

TRCSerialization TRCSerializationPlist = @"TRCSerializationPlist";

@implementation TRCSerializerPlist

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.format = NSPropertyListXMLFormat_v1_0;
    }
    return self;
}

- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error
{
    return [NSPropertyListSerialization dataWithPropertyList:requestObject format:self.format options:self.writeOptions error:error];
}

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
    return [NSPropertyListSerialization propertyListWithData:data options:self.readOptions format:NULL error:error];;
}

- (NSString *)contentType
{
    return @"application/x-plist";
}

- (BOOL)isCorrectContentType:(NSString *)responseContentType
{
    return [responseContentType isEqualToString:[self contentType]];
}

- (id<TRCSchemaData>)requestSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error
{
    return [self schemeDataFromData:data isRequest:YES dataProvider:dataProvider error:error];
}

- (id<TRCSchemaData>)responseSchemaDataFromData:(NSData *)data dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error
{
    return [self schemeDataFromData:data isRequest:NO dataProvider:dataProvider error:error];
}

- (id<TRCSchemaData>)schemeDataFromData:(NSData *)data isRequest:(BOOL)request dataProvider:(id<TRCSchemaDataProvider>)dataProvider error:(NSError **)error
{
    id object = [NSPropertyListSerialization propertyListWithData:data options:self.readOptions format:NULL error:error];;
    if (object) {
        TRCSchemaDictionaryData *result = [[TRCSchemaDictionaryData alloc] initWithArrayOrDictionary:object];
        result.requestData = request;
        result.dataProvider = dataProvider;
        return result;
    } else {
        return nil;
    }
}

@end