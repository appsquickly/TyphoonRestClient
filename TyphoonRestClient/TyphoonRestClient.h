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


#import "TRCRequest.h"
#import "TRCObjectMapper.h"
#import "TRCValueTransformer.h"
#import "TRCConnection.h"
#import "TRCErrorParser.h"
#import "TRCBuiltInObjects.h"
#import "TRCSerialization.h"

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

@property (nonatomic, strong) id<TRCErrorParser> errorParser;
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

//-------------------------------------------------------------------------------------------
#pragma mark - Registry
//-------------------------------------------------------------------------------------------

- (void)registerValueTransformer:(id<TRCValueTransformer>)valueTransformer forTag:(NSString *)tag;

- (void)registerObjectMapper:(id<TRCObjectMapper>)objectConverter forTag:(NSString *)tag;

@end

//-------------------------------------------------------------------------------------------
#pragma mark - Extensions
//-------------------------------------------------------------------------------------------

@interface TyphoonRestClient (Infrastructure)

- (void)registerRequestSerializer:(id<TRCRequestSerializer>)serializer forName:(TRCSerialization)serializerName;

- (void)registerResponseSerializer:(id<TRCResponseSerializer>)serializer forName:(TRCSerialization)serializerName;

- (void)registerSchemeFormat:(id<TRCSchemaFormat>)schemeFormat forFileExtension:(NSString *)extension;

@end