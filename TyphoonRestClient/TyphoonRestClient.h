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


#import "TRCRequest.h"
#import "TRCObjectMapper.h"
#import "TRCValueTransformer.h"
#import "TRCConnection.h"
#import "TRCErrorHandler.h"
#import "TRCBuiltInObjects.h"
#import "TRCInfrastructure.h"
#import "TRCPostProcessor.h"

//TODO: Write docs
extern NSString *TyphoonRestClientReachabilityDidChangeNotification;


typedef NS_OPTIONS(NSInteger , TRCValidationOptions)
{
    TRCValidationOptionsNone = 0,
    TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional = 1 << 0,
    TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForRequired = 1 << 1,
    TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional = 1 << 2,
    TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForRequired = 1 << 3,
    TRCValidationOptionsRemoveValuesMissedInSchemeForRequests  = 1 << 4,
    TRCValidationOptionsRemoveValuesMissedInSchemeForResponses = 1 << 5
};

@interface TyphoonRestClient : NSObject

//Reachability
@property (nonatomic, readonly, getter=isReachable) BOOL reachable;
@property (nonatomic, readonly) TRCConnectionReachabilityState reachabilityState;

@property (nonatomic, strong) id<TRCErrorHandler> errorHandler;
@property (nonatomic, strong) id<TRCConnection> connection;

/// Default: TRCSerializationJson
@property (nonatomic) TRCSerialization defaultResponseSerialization;

/// Default: NO
@property (nonatomic) BOOL shouldSuppressWarnings;

/// Default: TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional | TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional
@property (nonatomic) TRCValidationOptions validationOptions;

- (id<TRCProgressHandler>)sendRequest:(id<TRCRequest>)request completion:(void(^)(id result, NSError *error))completion;

#pragma mark - Registry

- (void)registerValueTransformer:(id<TRCValueTransformer>)valueTransformer forTag:(NSString *)tag;

- (void)registerObjectMapper:(id<TRCObjectMapper>)objectConverter forTag:(NSString *)tag;

- (void)registerPostProcessor:(id<TRCPostProcessor>)postProcessor;

- (void)registerDefaultRequestSerialization:(TRCSerialization)requestSerialization forBodyObjectWithClass:(Class)clazz;

@end

//-------------------------------------------------------------------------------------------
#pragma mark - Extensions
//-------------------------------------------------------------------------------------------

/**
* This category declares additional methods to extend `TyphoonRestClient` with additional formats and serializations
* */
@interface TyphoonRestClient (Infrastructure)

/**
* Registers `TRCRequestSerializer` for special string identifier `TRCSerialization`.
* Use `TRCSerialization` identifier later in your `TRCRequest`-s
* */
- (void)registerRequestSerializer:(id<TRCRequestSerializer>)serializer forName:(TRCSerialization)serializerName;

/**
* Registers `TRCResponseSerializer` for special string identifier `TRCSerialization`.
* Use `TRCSerialization` identifier later in your `TRCRequest`-s
* */
- (void)registerResponseSerializer:(id<TRCResponseSerializer>)serializer forName:(TRCSerialization)serializerName;

/**
* Registers scheme file format in `TyphoonRestClient`. You are free to invent your own schema format to process and validate
* your own serialization formats.
*
* By default, only one format available for schema. It's JSON format (with file extension 'json')
*
* All scheme files must have path extensions of registered scheme format. For example all JSON schemes must ends
* with .json extension
*
* @see `TRCSchemaFormat`
* */
- (void)registerSchemeFormat:(id<TRCSchemaFormat>)schemeFormat forFileExtension:(NSString *)extension;

/**
* Registers validation error printer for schema file extension. Because schema files with different extensions, looks
* different, then full description of validation error should also looks different per extension.
*
* @see `TRCValidationErrorPrinter`
* */
- (void)registerValidationErrorPrinter:(id<TRCValidationErrorPrinter>)printer forFormatWithFileExtension:(NSString *)extension;

/**
* Registers `TRCValueTransformerType` with objective-c class. Then `TRCValueTransformerType` can be used as identifier
* in `TRCValueTransformer` to specify input types, and type validation would be done based on classes registered with it.
*
* To use `TRCValueTransformerType` as identifier, it useful to have them as global variable in serializer header,
* and register pointer to that variables with classes. Calling that method will set correct value to these variables.
*
* Note that value of `type` variable would be set as BitMask, so you can later combine all acceptable types as one value
* like that: ```type1 | type2 | type3```
*
* @see `TRCValueTransformerType`
* */
- (void)registerTRCValueTransformerType:(TRCValueTransformerType *)type withValueClass:(Class)clazz;

@end
