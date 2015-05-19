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

#import "TRCSerializerJson.h"
#import "TRCSchema.h"
#import "TRCSchemaData.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCUtils.h"

TRCSerialization TRCSerializationJson = @"TRCSerializationJson";

@interface TRCSerializerJson ()
@property (nonatomic, strong) NSSet *acceptableContentTypes;
@end

@implementation TRCSerializerJson

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
        self.readingOptions = NSJSONReadingAllowFragments;
    }
    return self;
}

- (NSData *)dataFromRequestObject:(id)requestObject error:(NSError **)error
{
    if ([NSJSONSerialization isValidJSONObject:requestObject]) {
        return [NSJSONSerialization dataWithJSONObject:requestObject options:self.writingOptions error:error];
    } else {
        if (error) {
            *error = TRCRequestSerializationErrorWithFormat(@"Can't create JSON string from '%@'. Object is invalid.", requestObject);
        }
        return nil;
    }
}

- (NSString *)contentType
{
    return @"application/json";
}

- (id)objectFromResponseData:(NSData *)data error:(NSError **)error
{
    return [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:error];
}

- (BOOL)isCorrectContentType:(NSString *)responseContentType
{
    return [self.acceptableContentTypes containsObject:responseContentType];
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
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:error];
    if (jsonObject) {
        TRCSchemaDictionaryData *result = [[TRCSchemaDictionaryData alloc] initWithArrayOrDictionary:jsonObject];
        result.requestData = request;
        result.dataProvider = dataProvider;
        return result;
    } else {
        return nil;
    }
}

@end