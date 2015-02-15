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
#import "HWSRequest.h"

@protocol HWSErrorParser;
@protocol HWSConnection;
@protocol HWSValueConverter;
@class HWSSchema;
@protocol HWSProgressHandler;

typedef NS_OPTIONS(NSInteger , HWSValidationOptions)
{
    HWSValidationOptionsNone = 0,
    HWSValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional = 1 << 0,
    HWSValidationOptionsTreatEmptyDictionaryAsNilInResponsesForRequired = 1 << 1,
    HWSValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional  = 1 << 2,
    HWSValidationOptionsTreatEmptyDictionaryAsNilInRequestsForRequired  = 1 << 3
};


@interface HttpWebService : NSObject

@property (nonatomic, strong) id<HWSErrorParser> errorParser;
@property (nonatomic, strong) id<HWSConnection> connection;

/// Default: HttpRequestSerializationJson;
@property (nonatomic) HttpRequestSerialization defaultRequestSerialization;

/// Default: HttpResponseSerializationJson
@property (nonatomic) HttpResponseSerialization defaultResponseSerialization;

/// Default: NO
@property (nonatomic) BOOL shouldSuppressWarnings;

/// Default: HWSValidationOptionsTreatEmptyDictionaryAsNilInResponsesForOptional | HWSValidationOptionsTreatEmptyDictionaryAsNilInRequestsForOptional
@property (nonatomic) HWSValidationOptions validationOptions;

- (id<HWSProgressHandler>)sendRequest:(id<HWSRequest>)request completion:(void(^)(id result, NSError *error))completion;

- (void)registerValueConverter:(id<HWSValueConverter>)valueConverter forTag:(NSString *)tag;

@end