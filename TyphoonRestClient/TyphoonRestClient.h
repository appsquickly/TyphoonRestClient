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


#import <Foundation/Foundation.h>
#import "TRCRequest.h"

@protocol TRCErrorParser;
@protocol TRCConnection;
@protocol TRCValueTransformer;
@class TRCSchema;
@protocol TRCProgressHandler;
@protocol TRCObjectMapper;

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

/// Default: TRCRequestSerializationJson;
@property (nonatomic) TRCRequestSerialization defaultRequestSerialization;

/// Default: TRCResponseSerializationJson
@property (nonatomic) TRCResponseSerialization defaultResponseSerialization;

/// Default: NO
@property (nonatomic) BOOL shouldSuppressWarnings;

/// Default: TRCValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional | TRCValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional
@property (nonatomic) TRCValidationOptions validationOptions;

- (id<TRCProgressHandler>)sendRequest:(id<TRCRequest>)request completion:(void(^)(id result, NSError *error))completion;

- (void)registerValueConverter:(id<TRCValueTransformer>)valueConverter forTag:(NSString *)tag;

- (void)registerObjectMapper:(id<TRCObjectMapper>)objectConverter forTag:(NSString *)tag;

@end