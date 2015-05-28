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

/// Default: TRCSerializationJson;
@property (nonatomic) TRCSerialization defaultRequestSerialization;

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

@end

//-------------------------------------------------------------------------------------------
#pragma mark - Extensions
//-------------------------------------------------------------------------------------------

/**
* This category declares additional methods to extend `TyphoonRestClient` with additional formats and serializations
* */
@interface TyphoonRestClient (Infrastructure)

- (void)registerRequestSerializer:(id<TRCRequestSerializer>)serializer forName:(TRCSerialization)serializerName;

- (void)registerResponseSerializer:(id<TRCResponseSerializer>)serializer forName:(TRCSerialization)serializerName;

- (void)registerSchemeFormat:(id<TRCSchemaFormat>)schemeFormat forFileExtension:(NSString *)extension;

- (void)registerValidationErrorPrinter:(id<TRCValidationErrorPrinter>)printer forFormatWithFileExtension:(NSString *)extension;

- (void)registerTRCValueTransformerType:(TRCValueTransformerType *)type withValueClass:(Class)clazz;

@end