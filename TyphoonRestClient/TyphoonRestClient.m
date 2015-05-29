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




#import "TyphoonRestClient.h"
#import "TRCRequest.h"
#import "TRCSchema.h"
#import "TRCUtils.h"
#import "TRCConverter.h"
#import "TRCValueTransformer.h"
#import "TRCConvertersRegistry.h"
#import "TRCErrorHandler.h"
#import "TRCConnection.h"
#import "TRCValueTransformerUrl.h"
#import "TRCValueTransformerString.h"
#import "TRCValueTransformerNumber.h"
#import "TRCObjectMapper.h"
#import "TRCSchemaDictionaryData.h"
#import "TRCSchemeFactory.h"
#import "TRCSerializerJson.h"
#import "TRCSerializerPlist.h"
#import "TRCSerializerData.h"
#import "TRCSerializerHttpQuery.h"
#import "TRCSerializerImage.h"
#import "TRCSerializerInputStream.h"
#import "TRCSerializerString.h"
#import "TyphoonRestClientErrors.h"
#import "TRCPostProcessor.h"

TRCRequestMethod TRCRequestMethodPost = @"POST";
TRCRequestMethod TRCRequestMethodGet = @"GET";
TRCRequestMethod TRCRequestMethodPut = @"PUT";
TRCRequestMethod TRCRequestMethodDelete = @"DELETE";
TRCRequestMethod TRCRequestMethodPatch = @"PATCH";
TRCRequestMethod TRCRequestMethodHead = @"HEAD";

NSString *TyphoonRestClientReachabilityDidChangeNotification = @"TyphoonRestClientReachabilityDidChangeNotification";

@interface TRCRequestCreateOptions : NSObject <TRCConnectionRequestCreationOptions>
@end
@implementation TRCRequestCreateOptions
@synthesize method, path, pathParameters, body, headers, serialization, customProperties;
@end

@interface TRCRequestSendOptions : NSObject <TRCConnectionRequestSendingOptions>
@end
@implementation TRCRequestSendOptions
@synthesize outputStream, responseSerialization, customProperties, queuePriority;
@end


#define TRCSetError(errorPointer, error) if (errorPointer) { *errorPointer = error; }
#define TRCCompleteWithError(completion, error) if (completion) { completion(nil, error); }

@interface TyphoonRestClient ()<TRCConvertersRegistry, TRCSchemaDataProvider, TRCConnectionReachabilityDelegate>
@end

@implementation TyphoonRestClient
{
    NSMutableDictionary *_typeTransformerRegistry;
    NSMutableDictionary *_objectMapperRegistry;

    TRCSchemeFactory *_schemeFactory;

    NSMutableDictionary *_responseSerializers;
    NSMutableDictionary *_requestSerializers;
    NSMutableDictionary *_validationErrorPrinters;

    NSMutableOrderedSet *_postProcessors;
    NSMutableDictionary *_trcValueTransformerTypesRegistry;

    NSMutableDictionary *_defaultRequestSerializationsPerType;
    NSMutableDictionary *_defaultResponseSerializationsPerType;

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _typeTransformerRegistry = [NSMutableDictionary new];
        _objectMapperRegistry = [NSMutableDictionary new];
        self.validationOptions = TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional |
                TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional;
        _schemeFactory = [TRCSchemeFactory new];
        _schemeFactory.owner = self;
        _responseSerializers = [NSMutableDictionary new];
        _requestSerializers = [NSMutableDictionary new];
        _validationErrorPrinters = [NSMutableDictionary new];
        _postProcessors = [NSMutableOrderedSet new];
        _trcValueTransformerTypesRegistry = [NSMutableDictionary new];

        _defaultRequestSerializationsPerType = [NSMutableDictionary new];
        _defaultResponseSerializationsPerType = [NSMutableDictionary new];

        [self registerDefaultRequestSerializations];
        [self registerDefaultTypeConverters];
        [self registerDefaultSchemeFormats];
        self.defaultResponseSerialization = TRCSerializationJson;

    }
    return self;
}

- (void)registerDefaultSchemeFormats
{
    TRCSerializerJson *json = [TRCSerializerJson new];
    [self registerSchemeFormat:json forFileExtension:@"json"];
    [self registerValidationErrorPrinter:json forFormatWithFileExtension:@"json"];
    [self registerRequestSerializer:json forName:TRCSerializationJson];
    [self registerResponseSerializer:json forName:TRCSerializationJson];

    TRCSerializerPlist *plist = [TRCSerializerPlist new];
    [self registerSchemeFormat:plist forFileExtension:@"plist"];
    [self registerRequestSerializer:plist forName:TRCSerializationPlist];
    [self registerResponseSerializer:plist forName:TRCSerializationPlist];

    TRCSerializerData *data = [TRCSerializerData new];
    [self registerRequestSerializer:data forName:TRCSerializationData];
    [self registerResponseSerializer:data forName:TRCSerializationData];

    TRCSerializerString *string = [TRCSerializerString new];
    [self registerRequestSerializer:string forName:TRCSerializationString];
    [self registerResponseSerializer:string forName:TRCSerializationString];

    TRCSerializerHttpQuery *http = [TRCSerializerHttpQuery new];
    [self registerRequestSerializer:http forName:TRCSerializationRequestHttp];

    TRCSerializerInputStream *inputStream = [TRCSerializerInputStream new];
    [self registerRequestSerializer:inputStream forName:TRCSerializationRequestInputStream];

    TRCSerializerImage *image = [TRCSerializerImage new];
    [self registerResponseSerializer:image forName:TRCSerializationResponseImage];
}

- (id<TRCProgressHandler>)sendRequest:(id<TRCRequest>)request completion:(void (^)(id result, NSError *error))completion
{
    NSParameterAssert(self.connection);

    NSError *error = nil;
    TRCRequestCreateOptions *createOptions = [self requestCreateOptionsFromRequest:request error:&error];
    if (error) {
        TRCCompleteWithError(completion, error);
        return nil;
    }

    NSMutableURLRequest *httpRequest = [self.connection requestWithOptions:createOptions error:&error];
    if (error) {
        TRCCompleteWithError(completion, error);
        return nil;
    }

    NSParameterAssert(httpRequest);

    TRCRequestSendOptions *sendOptions = [self requestSendOptionsFromRequest:request error:&error];
    if (error) {
        TRCCompleteWithError(completion, error);
        return nil;
    }

    return [self.connection sendRequest:httpRequest withOptions:sendOptions completion:^(id responseObject, NSError *networkError, id<TRCResponseInfo> responseInfo) {
        [self handleResponse:responseObject withError:networkError info:responseInfo forRequest:request completion:^(id result, NSError *handleError) {
            if (completion) {
                completion(result, handleError);
            }
        }];
    }];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Request composing
//-------------------------------------------------------------------------------------------

- (TRCRequestSendOptions *)requestSendOptionsFromRequest:(id<TRCRequest>)request error:(NSError **)error
{
    TRCRequestSendOptions *options = [TRCRequestSendOptions new];
    options.outputStream = nil;
    if ([request respondsToSelector:@selector(responseBodyOutputStream)]) {
        options.outputStream = [request responseBodyOutputStream];
    }

    TRCSerialization serializationName = self.defaultResponseSerialization;
    if ([request respondsToSelector:@selector(responseBodySerialization)]) {
        serializationName = [request responseBodySerialization];
        if (options.outputStream && serializationName != TRCSerializationData) {
            [self logWarning:@"Both 'responseBodySerialization' and 'responseBodyOutputStream' methods implemented in '%@' request. "
                                     "Value returned by 'responseBodySerialization' method will be ignored. To avoid this warning please remove"
                                     " 'responseBodySerialization' implementation or change returned value to TRCSerializationData", [request class]];
        }
    }

    if (options.outputStream) {
        serializationName = TRCSerializationData;
    }

    options.responseSerialization = _responseSerializers[serializationName];
    if (!options.responseSerialization) {
        TRCSetError(error, TRCErrorWithFormat(TyphoonRestClientErrorCodeResponseSerialization, @"Can't find response serialization for name '%@'", serializationName));
        return nil;
    }

    if ([request respondsToSelector:@selector(queuePriority)]) {
        options.queuePriority = [request queuePriority];
    } else {
        options.queuePriority = NSOperationQueuePriorityNormal;
    }

    if ([request respondsToSelector:@selector(customProperties)]) {
        options.customProperties = [request customProperties];
    }

    return options;
}

- (TRCRequestCreateOptions *)requestCreateOptionsFromRequest:(id<TRCRequest>)request error:(NSError **)error
{
    TRCRequestCreateOptions *options = [TRCRequestCreateOptions new];

    NSError *composingError = nil;

    options.body = [self requestBodyFromRequest:request error:&composingError];

    if (composingError) {
        TRCSetError(error, composingError);
        return nil;
    }

    TRCSerialization serializationName = [self requestSerializationFromRequest:request body:options.body];
    if  (!serializationName) {
        TRCSetError(error, TRCErrorWithFormat(TyphoonRestClientErrorCodeRequestSerialization, @"Request serialization not specified for object with type '%@'", [options.body class]));
        return nil;
    }
    options.serialization = _requestSerializers[serializationName];
    if (!options.serialization) {
        TRCSetError(error, TRCErrorWithFormat(TyphoonRestClientErrorCodeRequestSerialization, @"Can't find request serialization for name '%@'", serializationName));
        return nil;
    }

    NSMutableDictionary *pathParams = [[self requestPathParametersFromRequest:request error:&composingError] mutableCopy];
    if (composingError) {
        TRCSetError(error, composingError);
        return nil;
    }

    options.path = [self requestPathFromRequest:request params:pathParams error:&composingError];
    options.pathParameters = pathParams;
    options.method = [request method];
    options.headers = nil;
    if ([request respondsToSelector:@selector(requestHeaders)]) {
        options.headers = [request requestHeaders];
    }

    if ([request respondsToSelector:@selector(customProperties)]) {
        options.customProperties = [request customProperties];
    }

    if (composingError) {
        TRCSetError(error, composingError);
        return nil;
    }

    return options;
}

- (id)requestBodyFromRequest:(id<TRCRequest>)request error:(NSError **)error
{
    id body = nil;
    if ([request respondsToSelector:@selector(requestBody)]) {
        body = [request requestBody];
        if ([body isKindOfClass:[NSArray class]] || [body isKindOfClass:[NSDictionary class]]) {
            NSError *validationOrConversionError = nil;
            TRCSchema *schema = [_schemeFactory schemeForRequest:request];
            body = [self convertThenValidateObject:body withScheme:schema error:&validationOrConversionError];
            if (validationOrConversionError) {
                TRCSetError(error, validationOrConversionError);
                return nil;
            }
        }
    }
    return body;
}

- (TRCSerialization)requestSerializationFromRequest:(id<TRCRequest>)request body:(id)body
{
    TRCSerialization serialization = nil;
    if ([request respondsToSelector:@selector(requestBodySerialization)]) {
        serialization = [request requestBodySerialization];
    } else {
        serialization = [self defaultRequestSerializationForBodyObject:body];
    }
    return serialization;
}

- (NSDictionary *)requestPathParametersFromRequest:(id<TRCRequest>)request error:(NSError **)error
{
    NSDictionary *pathParams = nil;
    if ([request respondsToSelector:@selector(pathParameters)]) {
        pathParams = [request pathParameters];
        NSError *validationOrConversionError = nil;
        TRCSchema *schema = [_schemeFactory schemeForPathParametersWithRequest:request];
        pathParams = [self convertThenValidateObject:pathParams withScheme:schema error:&validationOrConversionError];
        if (validationOrConversionError) {
            TRCSetError(error, validationOrConversionError);
            return nil;
        }
    }
    return pathParams;
}

- (NSString *)requestPathFromRequest:(id<TRCRequest>)request params:(NSMutableDictionary *)params error:(NSError **)error
{
    TRCUrlPathParamsByRemovingNull(params);
    NSString *path = [request path];
    if (path && params.count > 0) {
        NSError *argumentsApplyingError = nil;
        path = TRCUrlPathFromPathByApplyingArguments(path, params, &argumentsApplyingError);
        if (argumentsApplyingError) {
            TRCSetError(error, argumentsApplyingError);
            return nil;
        }
    }
    return path;
}
//-------------------------------------------------------------------------------------------
#pragma mark - Response handling
//-------------------------------------------------------------------------------------------

- (void)handleResponse:(id)responseObject withError:(NSError *)error info:(id<TRCResponseInfo>)responseInfo forRequest:(id<TRCRequest>)request completion:(void (^)(id result, NSError *error))completion
{
    id response = nil;

    NSParameterAssert(completion);
    if (error || [self isErrorInResponse:responseObject responseInfo:responseInfo]) {
        //Parse response for error description if needed:
        error = [self errorFromNetworkError:error withResponse:responseObject request:request responseInfo:responseInfo];

        //Notify request with error
        if ([request respondsToSelector:@selector(respondedWithError:headers:status:)]) {
            [request respondedWithError:error headers:[responseInfo.response allHeaderFields] status:[responseInfo.response statusCode]];
        }
    }
    else {
        NSError *validationOrConversionError = nil;
        TRCSchema *scheme = [_schemeFactory schemeForResponseWithRequest:request];
        response = [self validateThenConvertObject:responseObject withScheme:scheme error:&validationOrConversionError];
        if (!validationOrConversionError) {
            response = [self parseResponse:response withRequest:request responseInfo:responseInfo error:&validationOrConversionError];
        }
        error = validationOrConversionError;
    }

    if (error) {
        error = [self postProcessError:error forRequest:request];
        completion(nil, error);
    } else {
        completion(response, nil);
    }
}

- (id)parseResponse:(id)response withRequest:(id<TRCRequest>)request responseInfo:(id<TRCResponseInfo>)responseInfo error:(NSError **)error
{
    id result = response;

    NSError *parsingError = nil;

    if ([request respondsToSelector:@selector(responseProcessedFromBody:headers:status:error:)]) {
        result = [request responseProcessedFromBody:response headers:responseInfo.response.allHeaderFields status:responseInfo.response.statusCode error:&parsingError];
    }

    if (!parsingError) {
        result = [self postProcessResponseObject:result forRequest:request postProcessError:&parsingError];
    }

    if (parsingError && error) {
        *error = parsingError;
        result = nil;
    }

    return result;
}

- (id)validateThenConvertObject:(id)object withScheme:(TRCSchema *)scheme error:(NSError **)error
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
            validationError = TRCUnknownValidationErrorForObject(object, [scheme name], YES);
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

- (id)convertThenValidateObject:(id)object withScheme:(TRCSchema *)scheme error:(NSError **)error
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
            validationError = TRCUnknownValidationErrorForObject(converted, [scheme name], NO);
        }
        if (validationError && error) {
            *error = validationError;
        }
    }

    return converted;
}

- (NSError *)errorFromNetworkError:(NSError *)networkError withResponse:(id)response request:(id<TRCRequest>)request responseInfo:(id<TRCResponseInfo>)info
{
    NSError *result = nil;
    if (networkError) {
        result = TRCErrorWithOriginalError(TyphoonRestClientErrorCodeConnectionError, networkError, @"Connection error");
    }

    if (self.errorHandler && response) {
        TRCSchema *scheme = [_schemeFactory schemeForErrorHandler:self.errorHandler];
        NSError *convertError = nil;
        id converted = [self validateThenConvertObject:response withScheme:scheme error:&convertError];

        if (convertError) {
            [self logWarning:@"Error schema validation/conversion error: \"%@\". Will return ordinary network error", convertError.localizedDescription];
        } else {
            NSError *error = nil;
            NSError *parsedError = [self.errorHandler errorFromResponseBody:converted headers:info.response.allHeaderFields status:info.response.statusCode error:&error];

            if (error) {
                [self logWarning:@"Error parsing error: \"%@\". Will return ordinary network error", error.localizedDescription];
            } else {
                result = parsedError;
            }
        }
    }

    return result;
}

- (BOOL)isErrorInResponse:(id)response responseInfo:(id<TRCResponseInfo>)info
{
    BOOL isError = NO;

    if (self.errorHandler && response) {
        if ([self.errorHandler respondsToSelector:@selector(isErrorResponseBody:headers:status:)]) {
            isError = [self.errorHandler isErrorResponseBody:response headers:info.response.allHeaderFields status:info.response.statusCode];
        }
    }

    return isError;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Validation
//-------------------------------------------------------------------------------------------

- (BOOL)validateResponse:(id)response withSchema:(TRCSchema *)schema error:(NSError **)error
{
    if (!response || !schema) {
        return YES;
    }

    return [schema validateResponse:response error:error];
}

- (BOOL)validateRequest:(id)request withSchema:(TRCSchema *)schema error:(NSError **)error
{
    if (!request || !schema) {
        return YES;
    }

    return [schema validateRequest:request error:error];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Conversion
//-------------------------------------------------------------------------------------------

- (id)convertValuesInResponse:(id)responseObject schema:(TRCSchema *)scheme error:(NSError **)parseError
{
    if (!scheme) {
        return responseObject;
    }

    TRCConverter *converter = [[TRCConverter alloc] initWithSchema:scheme];
    converter.registry = self;
    converter.options = self.validationOptions;
    NSError *error = nil;
    id result = [converter convertResponseValue:responseObject error:&error];
    if (error && parseError) {
        *parseError = error;
    }

    return result;
}

- (id)convertValuesInRequest:(id)requestObject schema:(TRCSchema *)scheme error:(NSError **)parseError
{
    if (!scheme) {
        return requestObject;
    }

    TRCConverter *converter = [[TRCConverter alloc] initWithSchema:scheme];
    converter.registry = self;
    converter.options = self.validationOptions;
    NSError *error = nil;
    id result = [converter convertRequestValue:requestObject error:&error];
    if (error && parseError) {
        *parseError = error;
    }

    return result;
}

//-------------------------------------------------------------------------------------------
#pragma mark - TRCSchemaData Provider
//-------------------------------------------------------------------------------------------

- (BOOL)schemaData:(id<TRCSchemaData>)data hasObjectMapperForTag:(NSString *)schemaName
{
    return [self objectMapperForTag:schemaName] != nil;
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data requestSchemaForMapperWithTag:(NSString *)tag
{
    id<TRCObjectMapper>mapper = [self objectMapperForTag:tag];
    if (!mapper) {
        return nil;
    } else {
        return [_schemeFactory requestSchemaDataForMapper:mapper];
    }
}

- (id<TRCSchemaData>)schemaData:(id<TRCSchemaData>)data responseSchemaForMapperWithTag:(NSString *)tag
{
    id<TRCObjectMapper>mapper = [self objectMapperForTag:tag];
    if (!mapper) {
        return nil;
    } else {
        return [_schemeFactory responseSchemaDataForMapper:mapper];
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Value converters
//-------------------------------------------------------------------------------------------

- (void)registerDefaultTypeConverters
{
    [self registerValueTransformer:[TRCValueTransformerUrl new] forTag:@"{url}"];
    [self registerValueTransformer:[TRCValueTransformerString new] forTag:@"{string}"];
    [self registerValueTransformer:[TRCValueTransformerNumber new] forTag:@"{number}"];

    [self registerTRCValueTransformerType:&TRCValueTransformerTypeString withValueClass:[NSString class]];
    [self registerTRCValueTransformerType:&TRCValueTransformerTypeNumber withValueClass:[NSNumber class]];
    [self registerTRCValueTransformerType:&TRCValueTransformerTypeData withValueClass:[NSData class]];
    [self registerTRCValueTransformerType:&TRCValueTransformerTypeDate withValueClass:[NSDate class]];
}

- (void)registerValueTransformer:(id<TRCValueTransformer>)valueTransformer forTag:(NSString *)tag
{
    NSParameterAssert(tag);
    NSAssert(_objectMapperRegistry[tag] == nil, @"This tag already used as TRCObjectMapper. Call [registerObjectMapper:nil forTag:%@] before registering value transformer ", tag);
    if (valueTransformer) {
        _typeTransformerRegistry[tag] = valueTransformer;
    } else {
        [_typeTransformerRegistry removeObjectForKey:tag];
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - Object Mappers
//-------------------------------------------------------------------------------------------

- (void)registerObjectMapper:(id<TRCObjectMapper>)objectConverter forTag:(NSString *)tag
{
    NSParameterAssert(tag);
    NSAssert(_typeTransformerRegistry[tag] == nil, @"This tag already used as TRCValueTransformer. Call [registerValueTransformer:nil forTag:%@] before registering object mapper ", tag);
    if (objectConverter) {
        _objectMapperRegistry[tag] = objectConverter;
    } else {
        [_objectMapperRegistry removeObjectForKey:tag];
    }
}

- (id<TRCObjectMapper>)objectMapperForTag:(NSString *)tag
{
    NSParameterAssert(tag);
    return _objectMapperRegistry[tag];
}

- (id<TRCValidationErrorPrinter>)validationErrorPrinterForExtension:(NSString *)extension
{
    NSParameterAssert(extension);
    return _validationErrorPrinters[extension];
}

- (id<TRCValueTransformer>)valueTransformerForTag:(NSString *)tag
{
    NSParameterAssert(tag);
    return _typeTransformerRegistry[tag];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Warnings
//-------------------------------------------------------------------------------------------

- (void)logWarning:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    if (!self.shouldSuppressWarnings) {
        va_list args;
        va_start(args, format);
        NSString *warningString = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        NSLog(@"TyphoonRestClient Warning: %@",warningString);
    }
}

//-------------------------------------------------------------------------------------------
#pragma mark - PostProcessors
//-------------------------------------------------------------------------------------------

- (void)registerPostProcessor:(id<TRCPostProcessor>)postProcessor
{
    NSAssert(postProcessor, @"PostProcessor can't be nil");
    [_postProcessors addObject:postProcessor];
}

- (id)postProcessResponseObject:(id)responseObject forRequest:(id<TRCRequest>)request postProcessError:(NSError **)postProcessError
{
    id result = responseObject;

    for (id<TRCPostProcessor> postProcessor in _postProcessors) {
        if ([postProcessor respondsToSelector:@selector(postProcessResponseObject:forRequest:postProcessError:)]) {
            NSError *error = nil;
            result = [postProcessor postProcessResponseObject:result forRequest:request postProcessError:&error];
            if (error) {
                if (postProcessError) {
                    *postProcessError = error;
                }
                return nil;
            }
        }
    }

    return result;
}

- (NSError *)postProcessError:(NSError *)error forRequest:(id<TRCRequest>)request
{
    NSError *result = error;

    for (id<TRCPostProcessor> postProcessor in _postProcessors) {
        if ([postProcessor respondsToSelector:@selector(postProcessError:forRequest:)]) {
            result = [postProcessor postProcessError:result forRequest:request];
        }
    }

    return result;
}

//-------------------------------------------------------------------------------------------
#pragma mark - Default Serialization
//-------------------------------------------------------------------------------------------

- (void)registerDefaultRequestSerializations
{
    [self registerDefaultRequestSerialization:TRCSerializationJson forBodyObjectWithClass:[NSDictionary class]];
    [self registerDefaultRequestSerialization:TRCSerializationJson forBodyObjectWithClass:[NSArray class]];
    [self registerDefaultRequestSerialization:TRCSerializationData forBodyObjectWithClass:[NSData class]];
    [self registerDefaultRequestSerialization:TRCSerializationRequestInputStream forBodyObjectWithClass:[NSInputStream class]];
    [self registerDefaultRequestSerialization:TRCSerializationString forBodyObjectWithClass:[NSString class]];
}

- (void)registerDefaultRequestSerialization:(TRCSerialization)requestSerialization forBodyObjectWithClass:(Class)clazz
{
    if (requestSerialization) {
        _defaultRequestSerializationsPerType[(id<NSCopying>)clazz] = requestSerialization;
    } else {
        [_defaultRequestSerializationsPerType removeObjectForKey:(id<NSCopying>)clazz];
    }
}

- (TRCSerialization)defaultRequestSerializationForBodyObject:(id)bodyObject
{
    __block TRCSerialization result = nil;
    if (bodyObject) {
        [_defaultRequestSerializationsPerType enumerateKeysAndObjectsUsingBlock:^(id key, TRCSerialization serialization, BOOL *stop) {
            Class clazz = key;
            if ([bodyObject isKindOfClass:clazz]) {
                result = serialization;
                *stop = YES;
            }
        }];
    }
    return result;
}

//-------------------------------------------------------------------------------------------
#pragma mark - TRCValueTransformerType
//-------------------------------------------------------------------------------------------

- (void)enumerateTransformerTypesWithClasses:(void (^)(TRCValueTransformerType type, Class clazz, BOOL *stop))block
{
    [_trcValueTransformerTypesRegistry enumerateKeysAndObjectsUsingBlock:^(id clazz, NSNumber *value, BOOL *stop) {
        TRCValueTransformerType type = [value integerValue];
        block(type, clazz, stop);
    }];
}

//-------------------------------------------------------------------------------------------
#pragma mark - Reachability
//-------------------------------------------------------------------------------------------

- (void)setConnection:(id<TRCConnection>)connection
{
    if (_connection != connection) {
        _connection = connection;
        if ([(id)_connection respondsToSelector:@selector(setReachabilityDelegate:)]) {
            [_connection setReachabilityDelegate:self];
        }
    }
}

- (void)connection:(id<TRCConnection>)connection didChangeReachabilityState:(TRCConnectionReachabilityState)state
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TyphoonRestClientReachabilityDidChangeNotification object:@(state)];
    });
}

- (BOOL)isReachable
{
    TRCConnectionReachabilityState state = [self reachabilityState];
    return (state == TRCConnectionReachabilityStateReachableViaWifi) || (state == TRCConnectionReachabilityStateReachableViaWWAN);
}

- (TRCConnectionReachabilityState)reachabilityState
{
    TRCConnectionReachabilityState state = TRCConnectionReachabilityStateUnknown;
    if ([(id)_connection respondsToSelector:@selector(reachabilityState)]) {
        state = [_connection reachabilityState];
    }
    return state;
}

@end

@implementation TyphoonRestClient (Infrastructure)

- (void)registerRequestSerializer:(id<TRCRequestSerializer>)serializer forName:(TRCSerialization)serializerName
{
    NSParameterAssert(serializerName);
    if (serializer) {
        _requestSerializers[serializerName] = serializer;
    } else {
        [_requestSerializers removeObjectForKey:serializerName];
    }
}

- (void)registerResponseSerializer:(id<TRCResponseSerializer>)serializer forName:(TRCSerialization)serializerName
{
    NSParameterAssert(serializerName);
    if (serializer) {
        _responseSerializers[serializerName] = serializer;
    } else {
        [_responseSerializers removeObjectForKey:serializerName];
    }
}

- (void)registerSchemeFormat:(id<TRCSchemaFormat>)schemeFormat forFileExtension:(NSString *)extension
{
    [_schemeFactory registerSchemeFormat:schemeFormat forFileExtension:extension];
}

- (void)registerValidationErrorPrinter:(id<TRCValidationErrorPrinter>)printer forFormatWithFileExtension:(NSString *)extension
{
    NSParameterAssert(extension);
    if (printer) {
        _validationErrorPrinters[extension] = printer;
    } else {
        [_validationErrorPrinters removeObjectForKey:extension];
    }
}

- (void)registerTRCValueTransformerType:(TRCValueTransformerType *)type withValueClass:(Class)clazz
{
    if (type) {
        if (_trcValueTransformerTypesRegistry[clazz]) {
            NSNumber *currentValue = _trcValueTransformerTypesRegistry[clazz];
            *type = [currentValue integerValue];
        } else {
            NSUInteger currentCount = [_trcValueTransformerTypesRegistry count];
            *type = 1 << currentCount;
            _trcValueTransformerTypesRegistry[(id<NSCopying>)clazz] = @(*type);
        }
    }
}


@end