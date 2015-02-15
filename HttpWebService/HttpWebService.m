////////////////////////////////////////////////////////////////////////////////
//
//  AppsQuick.ly
//  Copyright 2015 AppsQuick.ly
//  All Rights Reserved.
//
//  NOTICE: This software is the proprietary information of AppsQuick.ly
//  Use is subject to license terms.
//
////////////////////////////////////////////////////////////////////////////////




#import "HttpWebService.h"
#import "HWSRequest.h"
#import "HWSSchema.h"
#import "HWSUtils.h"
#import "HWSConverter.h"
#import "HWSValueConverter.h"
#import "HWSValueConverterRegistry.h"
#import "HWSErrorParser.h"
#import "HWSConnection.h"
#import "HWSValueConverterUrl.h"
#import "HWSValueConverterString.h"
#import "HWSValueConverterNumber.h"

@interface HttpWebService()<HWSValueConverterRegistry>
@end

@implementation HttpWebService {
    NSMutableDictionary *typeConverterRegistry;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        typeConverterRegistry = [NSMutableDictionary new];
        [self registerDefaultTypeConverters];
        self.defaultRequestSerialization = HttpRequestSerializationJson;
        self.defaultResponseSerialization = HttpResponseSerializationJson;
        self.validationOptions = HWSValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional |
                HWSValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional;
    }
    return self;
}

- (id<HWSProgressHandler>)sendRequest:(id<HWSRequest>)request completion:(void (^)(id result, NSError *error))completion
{
    NSParameterAssert(self.connection);

    NSError *requestComposingError = nil;
    NSMutableURLRequest *httpRequest = [self requestFromRequest:request error:&requestComposingError];

    if (requestComposingError) {
        if (completion) {
            completion(nil, requestComposingError);
        }
        return nil;
    }
    NSParameterAssert(httpRequest);

    NSOutputStream *output = nil;
    if ([request respondsToSelector:@selector(responseBodyOutputStream)]) {
        output = [request responseBodyOutputStream];
    }

    HttpResponseSerialization responseSerialization = self.defaultResponseSerialization;
    if ([request respondsToSelector:@selector(responseSerialization)]) {
        responseSerialization = [request responseSerialization];
        if (output && responseSerialization != HttpResponseSerializationData) {
            [self logWarning:@"Both 'responseSerialization' and 'responseBodyOutputStream' methods implemented in '%@' request. "
                                     "Value returned by 'responseSerialization' method will be ignored. To avoid this warning please remove"
                                     " 'responseSerialization' implementation or change returned value to HttpResponseSerializationData", [request class]];
        }
    }

    if (output) {
        responseSerialization = HttpResponseSerializationData;
    }

    return [self.connection sendRequest:httpRequest responseSerialization:responseSerialization outputStream:output completion:^(id responseObject, NSError *networkError, id<HWSResponseInfo> responseInfo) {
        [self handleResponse:responseObject withError:networkError info:responseInfo forRequest:request completion:^(id result, NSError *error) {
            if (completion) {
                completion(result, error);
            }
        }];
    }];
}

- (NSMutableURLRequest *)requestFromRequest:(id<HWSRequest>)request error:(NSError **)error
{
    id body = nil;
    if ([request respondsToSelector:@selector(requestBody)]) {
        body = [request requestBody];
        if ([body isKindOfClass:[NSArray class]] || [body isKindOfClass:[NSDictionary class]]) {
            NSError *validationOrConversionError = nil;
            HWSSchema *schema = [self schemeForRequest:request];
            body = [self convertAndValidateObject:body withScheme:schema error:&validationOrConversionError];
            if (validationOrConversionError) {
                if (error) {
                    *error = validationOrConversionError;
                }
                return nil;
            }
        }
    }

    HttpRequestSerialization serialization = self.defaultRequestSerialization;
    if ([request respondsToSelector:@selector(requestSerialization)]) {
        serialization = [request requestSerialization];
        if (![body isKindOfClass:[NSArray class]] && ![body isKindOfClass:[NSDictionary class]]) {
            [self logWarning:@"Body object of type '%@' can't be serialized, but you implemented 'requestSerialization' method in %@ request. Specified serialization will be ignored.", [body class], [request class]];
        }
    }

    NSDictionary *pathParams = nil;
    if ([request respondsToSelector:@selector(pathParameters)]) {
        pathParams = [request pathParameters];
        NSError *validationOrConversionError = nil;
        HWSSchema *schema = [self schemeForPathParametersWithRequest:request];
        pathParams = [self convertAndValidateObject:pathParams withScheme:schema error:&validationOrConversionError];
        if (validationOrConversionError) {
            if (error) {
                *error = validationOrConversionError;
            }
            return nil;
        }
    }

    NSDictionary *customHeaders = nil;
    if ([request respondsToSelector:@selector(requestHeaders)]) {
        customHeaders = [request requestHeaders];
    }

    return [self.connection requestWithMethod:[request method] path:[request path] pathParams:pathParams body:body serialization:serialization headers:customHeaders error:NULL];
}

- (void)handleResponse:(id)responseObject withError:(NSError *)error info:(id<HWSResponseInfo>)responseInfo forRequest:(id<HWSRequest>)request completion:(void (^)(id result, NSError *error))completion
{
    NSParameterAssert(completion);
    if (error) {
        //Parse response for error description if needed:
        error = [self errorFromNetworkError:error withResponse:responseObject request:request responseInfo:responseInfo];

        //Notify request with error
        if ([request respondsToSelector:@selector(respondedWithError:headers:status:)]) {
            [request respondedWithError:error headers:[responseInfo.response allHeaderFields] status:[responseInfo.response statusCode]];
        }

        completion(nil, error);
        return;
    }

    HWSSchema *scheme = [self schemeForResponseWithRequest:request];

    NSError *validationOrConversionError = nil;
    id converted = [self validateAndConvertObject:responseObject withScheme:scheme error:&validationOrConversionError];

    if (validationOrConversionError) {
        completion(nil, validationOrConversionError);
    } else {
        [self parseResponse:converted withRequest:request responseInfo:responseInfo withCompletion:completion];
    }
}

- (void)parseResponse:(id)response withRequest:(id<HWSRequest>)request responseInfo:(id<HWSResponseInfo>)responseInfo withCompletion:(void (^)(id result, NSError *error))completion
{
    id result = response;

    NSError *parsingError = nil;

    if ([request respondsToSelector:@selector(responseProcessedFromBody:headers:status:error:)]) {
        result = [request responseProcessedFromBody:response headers:responseInfo.response.allHeaderFields status:responseInfo.response.statusCode error:&parsingError];
    }

    if (parsingError) {
        completion(nil, parsingError);
    } else {
        completion(result, nil);
    }
}

- (id)validateAndConvertObject:(id)object withScheme:(HWSSchema *)scheme error:(NSError **)error
{
    BOOL isObjectCanBeValidated = [object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]];
    if (!isObjectCanBeValidated) {
        if (scheme && object) {
            [self logWarning:@"Object of type '%@' can't be validated, but validation scheme '%@' specified. Validation scheme ignored", [object class], scheme.name];
        }
        return object;
    }

    //Scheme validation
    NSError *validationError = nil;
    if (![self validateResponse:object withSchema:scheme error:&validationError]) {
        if (!validationError) {
            validationError = NSErrorWithFormat(@"Unknown validation error while executing response: %@", object);
        }

        if (validationError && error) {
            *error = validationError;
        }
        return object;
    }

    //Values conversion
    NSError *convertError = nil;
    id converted = [self convertValuesInResponse:object schema:scheme error:&convertError];
    if (convertError && error) {
        *error = convertError;
    }
    return converted;
}

- (id)convertAndValidateObject:(id)object withScheme:(HWSSchema *)scheme error:(NSError **)error
{
    BOOL isObjectCanBeValidated = [object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]];
    if (!isObjectCanBeValidated) {
        if (scheme && object) {
            [self logWarning:@"Object of type '%@' can't be validated, but validation scheme '%@' specified. Validation scheme ignored", [object class], scheme.name];
        }
        return object;
    }

    //Values conversion
    NSError *convertError = nil;
    id converted = [self convertValuesInRequest:object schema:scheme error:&convertError];
    if (convertError && error) {
        *error = convertError;
    }
    if (convertError) {
        return converted;
    }

    //Scheme validation
    NSError *validationError = nil;
    if (![self validateRequest:converted withSchema:scheme error:&validationError]) {
        if (!validationError) {
            validationError = NSErrorWithFormat(@"Unknown validation error while executing response: %@", object);
        }
        if (validationError && error) {
            *error = validationError;
        }
    }

    return converted;
}

- (NSError *)errorFromNetworkError:(NSError *)networkError withResponse:(id)response request:(id<HWSRequest>)request responseInfo:(id<HWSResponseInfo>)info
{
    NSError *result = networkError;

    if (self.errorParser && response) {
        HWSSchema *scheme = [self schemeForErrorParser:self.errorParser];
        NSError *convertError = nil;
        id converted = [self validateAndConvertObject:response withScheme:scheme error:&convertError];

        if (convertError) {
            [self logWarning:@"Error schema validation/conversion error: \"%@\". Will return ordinary network error", convertError.localizedDescription];
        } else {
            NSError *error = nil;
            NSError *parsedError = [self.errorParser errorFromResponseBody:converted headers:info.response.allHeaderFields status:info.response.statusCode error:&error];

            if (error) {
                [self logWarning:@"Error parsing error: \"%@\". Will return ordinary network error", error.localizedDescription];
            } else {
                result = parsedError;
            }
        }
    }

    return result;
}

#pragma mark - Validation

- (BOOL)validateResponse:(id)response withSchema:(HWSSchema *)schema error:(NSError **)error
{
    if (!response || !schema) {
        return YES;
    }

    return [schema validateResponse:response error:error];
}

- (BOOL)validateRequest:(id)request withSchema:(HWSSchema *)schema error:(NSError **)error
{
    if (!request || !schema) {
        return YES;
    }

    return [schema validateRequest:request error:error];
}

#pragma mark - Conversion

- (id)convertValuesInResponse:(id)arrayOrDictionary schema:(HWSSchema *)scheme error:(NSError **)parseError
{
    if (!scheme) {
        return arrayOrDictionary;
    }

    HWSConverter *converter = [[HWSConverter alloc] initWithResponseValue:arrayOrDictionary schemaValue:[scheme schemeArrayOrDictionary] schemaName:[scheme name]];
    converter.registry = self;
    converter.options = self.validationOptions;
    id result = [converter convertValues];
    NSError *error = [converter conversionError];
    if (error && parseError) {
        *parseError = error;
    }

    return result;
}

- (id)convertValuesInRequest:(id)arrayOrDictionary schema:(HWSSchema *)scheme error:(NSError **)parseError
{
    if (!scheme) {
        return arrayOrDictionary;
    }

    HWSConverter *converter = [[HWSConverter alloc] initWithRequestValue:arrayOrDictionary schemaValue:[scheme schemeArrayOrDictionary] schemaName:[scheme name]];
    converter.registry = self;
    converter.options = self.validationOptions;
    id result = [converter convertValues];
    NSError *error = [converter conversionError];
    if (error && parseError) {
        *parseError = error;
    }

    return result;
}

#pragma mark - Scheme fetching

- (HWSSchema *)schemeForErrorParser:(id<HWSErrorParser>)parser
{
    NSString *schemaName = NSStringFromClass([parser class]);

    if ([parser respondsToSelector:@selector(errorValidationSchemaName)]) {
        schemaName = [parser errorValidationSchemaName];
    }

    return [self schemeWithName:schemaName];
}

- (HWSSchema *)schemeForResponseWithRequest:(id<HWSRequest>)request
{
    NSString *schemaName = [NSStringFromClass([request class]) stringByAppendingPathExtension:@"response"];

    if ([request respondsToSelector:@selector(responseBodyValidationSchemaName)]) {
       schemaName = [request responseBodyValidationSchemaName];
    }

    return [self schemeWithName:schemaName];
}

- (HWSSchema *)schemeForPathParametersWithRequest:(id<HWSRequest>)request
{
    NSString *schemaName = [NSStringFromClass([request class]) stringByAppendingPathExtension:@"url"];

    if ([request respondsToSelector:@selector(requestPathParametersValidationSchemaName)]) {
        schemaName = [request requestPathParametersValidationSchemaName];
    }
    return [self schemeWithName:schemaName];
}

- (HWSSchema *)schemeForRequest:(id<HWSRequest>)request
{
    NSString *schemaName = [NSStringFromClass([request class]) stringByAppendingPathExtension:@"request"];

    if ([request respondsToSelector:@selector(requestBodyValidationSchemaName)]) {
        schemaName = [request requestBodyValidationSchemaName];
    }
    return [self schemeWithName:schemaName];
}

- (HWSSchema *)schemeWithName:(NSString *)name
{
    HWSSchema *scheme = [HWSSchema schemaWithName:name];
    scheme.converterRegistry = self;
    scheme.options = self.validationOptions;
    return scheme;
}

#pragma mark - TypeConverter

- (void)registerDefaultTypeConverters
{
    [self registerValueConverter:[HWSValueConverterUrl new] forTag:@"{url}"];
    [self registerValueConverter:[HWSValueConverterString new] forTag:@"{string}"];
    [self registerValueConverter:[HWSValueConverterNumber new] forTag:@"{number}"];
}

- (void)registerValueConverter:(id<HWSValueConverter>)valueConverter forTag:(NSString *)tag
{
    NSParameterAssert(tag);
    if (valueConverter) {
        typeConverterRegistry[tag] = valueConverter;
    } else {
        [typeConverterRegistry removeObjectForKey:tag];
    }
}

- (id<HWSValueConverter>)valueConverterForTag:(NSString *)type
{
    return typeConverterRegistry[type];
}

#pragma mark - Log warning

- (void)logWarning:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (!self.shouldSuppressWarnings) {
        va_list args;
        va_start(args, format);
        NSString *warningString = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        NSLog(@"HttpWebService Warning: %@",warningString);
    }
}

@end