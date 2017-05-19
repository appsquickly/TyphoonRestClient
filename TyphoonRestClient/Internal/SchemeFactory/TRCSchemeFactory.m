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

#import "TRCSchemeFactory.h"
#import "TRCSchema.h"
#import "TRCRequest.h"
#import "TRCErrorHandler.h"
#import "TRCObjectMapper.h"
#import "TRCInfrastructure.h"
#import "TyphoonRestClient.h"
#import "TRCSchemaData.h"
#import "TRCConvertersRegistry.h"

@interface TyphoonRestClient (Private) <TRCConvertersRegistry, TRCSchemaDataProvider>

@end

@implementation TRCSchemeFactory
{
    NSMutableDictionary *_formats;

    NSString *_moduleName;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _formats = [NSMutableDictionary new];

        _moduleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        _moduleName = [_moduleName stringByAppendingString:@"."];
    }
    return self;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Schemes
//-------------------------------------------------------------------------------------------

- (TRCSchema *)schemeForErrorHandler:(id<TRCErrorHandler>)parser
{
    return [self schemeForObject:parser nameSelector:@selector(errorValidationSchemaName) suffix:@"response"
                   excludeSuffix:nil isRequest:NO];
}

- (TRCSchema *)schemeForPathParametersWithRequest:(id<TRCRequest>)request
{
    return [self schemeForObject:request nameSelector:@selector(pathParametersValidationSchemaName) suffix:@"path"
                   excludeSuffix:nil isRequest:YES];
}

- (TRCSchema *)schemeForRequest:(id<TRCRequest>)request
{
    return [self schemeForObject:request nameSelector:@selector(requestBodyValidationSchemaName) suffix:@"request"
                   excludeSuffix:nil isRequest:YES];
}

- (TRCSchema *)schemeForResponseWithRequest:(id<TRCRequest>)request
{
    return [self schemeForObject:request nameSelector:@selector(responseBodyValidationSchemaName) suffix:@"response"
                   excludeSuffix:nil isRequest:NO];
}

- (id<TRCSchemaData>)requestSchemaDataForMapper:(id<TRCObjectMapper>)mapper
{
    return [self schemeForObject:mapper nameSelector:@selector(requestValidationSchemaName) suffix:@[@"request", @""]
                   excludeSuffix:@"response" isRequest:YES].data;
}

- (id<TRCSchemaData>)responseSchemaDataForMapper:(id<TRCObjectMapper>)mapper
{
    return [self schemeForObject:mapper nameSelector:@selector(responseValidationSchemaName) suffix:@[@"response", @""]
                   excludeSuffix:@"request" isRequest:NO].data;
}

- (TRCSchema *)schemeForObject:(id)object nameSelector:(SEL)sel suffix:(id)suffix excludeSuffix:(NSString *)excludeSuffix isRequest:(BOOL)request
{
    NSString *filePath = nil;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    if ([object respondsToSelector:sel]) {
        NSString *(*impl)(id, SEL) = (NSString*(*)(id, SEL))[object methodForSelector:sel];
        NSString *fileName = impl(object, sel);
        filePath = [bundle pathForResource:fileName ofType:nil];
        //Used for UnitTests only
        if (fileName && !filePath) {
            return [self schemeForName:fileName isRequest:request];
        }
    }

    if (!filePath) {
        NSString *className = NSStringFromClass([object class]);

        if (_moduleName && [className hasPrefix:_moduleName]) {
            className = [className stringByReplacingOccurrencesOfString:_moduleName withString:@""];
        }

        if ([suffix isKindOfClass:[NSArray class]]) {
            for (NSString *suffixString in suffix) {
                filePath = [self pathForSchemeWithClassName:className suffix:suffixString excludeSuffix:excludeSuffix];
                if (filePath) {
                    break;
                }
            }
        } else if ([suffix isKindOfClass:[NSString class]]) {
            filePath = [self pathForSchemeWithClassName:className suffix:suffix excludeSuffix:excludeSuffix];
        }
    }

    if (filePath) {
        id<TRCSchemaData>schemaData = [self schemeDataFromFilePath:filePath isRequest:request];
        return [self schemeFromData:schemaData withName:[filePath lastPathComponent]];
    } else {
        return nil;
    }
}

- (NSString *)pathForSchemeWithClassName:(NSString *)className suffix:(NSString *)suffix excludeSuffix:(NSString *)excludeSuffix
{
    NSString *fileNamePrefix = suffix.length > 0 ? [NSString stringWithFormat:@"%@.%@", className, suffix] : className;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSArray *allFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[bundle bundlePath] error:nil];
    for (NSString *fileName in allFiles) {
        if ([fileName hasPrefix:fileNamePrefix]) {
            NSString *fullPath = [[bundle bundlePath] stringByAppendingPathComponent:fileName];
            if (excludeSuffix) {
                NSString *fileNameSuffix = [fileName stringByReplacingOccurrencesOfString:fileNamePrefix withString:@""];
                if ([fileNameSuffix rangeOfString:excludeSuffix].location == NSNotFound) {
                    return fullPath;
                }
            } else {
                return fullPath;
            }
        }
    }
    return nil;
}

- (id<TRCSchemaData>)schemeDataFromFilePath:(NSString *)filePath isRequest:(BOOL)isRequest
{
    id<TRCSchemaData> result = nil;
    id<TRCSchemaFormat> format = [self formatForFileExtension:[filePath pathExtension]];
    if (format) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
        if (data) {
            NSError *error = nil;
            if (isRequest) {
                result = [format requestSchemaDataFromData:data dataProvider:self.owner error:&error];
            } else {
                result = [format responseSchemaDataFromData:data dataProvider:self.owner error:&error];
            }

            if (error) {
                NSLog(@"Error: Can't load scheme at path: %@. Error: %@", filePath, error);
            }
        }
    }
    return result;
}

- (TRCSchema *)schemeFromData:(id<TRCSchemaData>)data withName:(NSString *)name
{
    TRCSchema *schema = [TRCSchema schemaWithData:data name:name];
    schema.converterRegistry = self.owner;
    return schema;
}

/** Used for unit tests only */
- (TRCSchema *)schemeForName:(NSString *)schemeName isRequest:(BOOL)isRequest
{
    return nil;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Registry
//-------------------------------------------------------------------------------------------

- (void)registerSchemeFormat:(id<TRCSchemaFormat>)schemeFormat forFileExtension:(NSString *)extension
{
    NSParameterAssert(extension);
    if (schemeFormat) {
        _formats[extension] = schemeFormat;
    } else {
        [_formats removeObjectForKey:extension];
    }
}

- (id<TRCSchemaFormat>)formatForFileExtension:(NSString *)extension
{
    if (extension) {
        return _formats[extension];
    } else {
        return nil;
    }
}

@end
