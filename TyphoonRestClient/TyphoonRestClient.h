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

/**
* If `TRCConnection` set in `TyphoonRestClient` supports reachability, then this notification would be posted after each
* reachability state change.
* This notification would be posted on main thread
* */
extern NSString *TyphoonRestClientReachabilityDidChangeNotification;


//TODO: Describe each TRCValidationOptions option
/**
* `TRCValidationOptions` is special options to validation and conversion rules
* */
typedef NS_OPTIONS(NSInteger , TRCValidationOptions)
{
    TRCValidationOptionsNone = 0,

    TRCValidationOptionsReplaceEmptyDictionariesWithNilInResponsesForOptional = 1 << 0,
    TRCValidationOptionsReplaceEmptyDictionariesWithNilInResponsesForRequired = 1 << 1,
    TRCValidationOptionsReplaceEmptyDictionariesWithNilInRequestsForOptional = 1 << 2,
    TRCValidationOptionsReplaceEmptyDictionariesWithNilInRequestsForRequired = 1 << 3,
    ///If enabled, all values missed in schema would be removed in request object
    TRCValidationOptionsRemoveValuesMissedInSchemeForRequests  = 1 << 4,
    ///If enabled, all values missed in schema would be removed in response object
    TRCValidationOptionsRemoveValuesMissedInSchemeForResponses = 1 << 5
};


//TODO: Write summery
/**
* `TyphoonRestClient` is HTTP client which aimed to help building large application with flexible architecture.
*
* ...
*
* */
@interface TyphoonRestClient : NSObject

//Reachability

/// Returns `YES` if `connection` supports reachability and network is reachable - otherwise `NO`
@property (nonatomic, readonly, getter=isReachable) BOOL reachable;

/// Returns current reachabilityState. @see `TRCConnectionReachabilityState`
@property (nonatomic, readonly) TRCConnectionReachabilityState reachabilityState;

/// Set your `TRCErrorHandler` here. Default `nil`.
@property (nonatomic, strong) id<TRCErrorHandler> errorHandler;

/// Set your `TRCConnection` here. Default `nil`. You must set this property
@property (nonatomic, strong) id<TRCConnection> connection;

/// Default: TRCSerializationJson
@property (nonatomic) TRCSerialization defaultResponseSerialization;

/// If enabled, warning messages would be printed using NSLog. Disable if you are nervous, enable if you careful.
/// Default: NO
@property (nonatomic) BOOL shouldSuppressWarnings;

/// Set validation and processing options here.
/// Default: `TRCValidationOptionsReplaceEmptyDictionariesWithNilInResponsesForOptional` | `TRCValidationOptionsReplaceEmptyDictionariesWithNilInRequestsForOptional`
@property (nonatomic) TRCValidationOptions validationOptions;

/**
* Sends your `TRCRequest` using `connection` and returns result in `completion` block.
*
* Make sure that `connection` property set before calling this method.
*
* @see
* `TRCRequest`
* `TRCConnection`
* */
- (id<TRCProgressHandler>)sendRequest:(id<TRCRequest>)request completion:(void(^)(id result, NSError *error))completion;

#pragma mark - Registry

/**
* Registers `TRCValueTransformer` for specific `tag` string.
* Use this `tag` in your schemes to mark values which must be processed by this `valueTransformer`
*
* @see
* `TRCValueTransformer`
* */
- (void)registerValueTransformer:(id<TRCValueTransformer>)valueTransformer forTag:(NSString *)tag;

/**
* Registers `TRCObjectMapper` for specific `tag` string.
* Use this `tag` in schemas to mark which part of object should be processed by this `objectMapper`
*
* For example, you have next JSON object:
* @code
* {
*   "people": {
*      "first_name": "string",
*      "last_name": "string"
*   }
* }
* @endcode
* and your mappers process objects:
* @code
* {
*   "first_name": "string",
*   "last_name": "string"
* }
* @endcode
* then you can register your mapper, for example, with `tag = <people>`.
* After that registration you can modify your scheme into that:
* @code
* {
*   "people": "<people>"
* }
* @endcode
*
*
* @see
* `TRCObjectMapper`
* */
- (void)registerObjectMapper:(id<TRCObjectMapper>)objectMapper forTag:(NSString *)tag;

/**
* Adds your `TRCPostProcessor` into registry.
* See `TRCPostProcessor` for more details
*
* @see `TRCPostProcessor`
* */
- (void)registerPostProcessor:(id<TRCPostProcessor>)postProcessor;

/**
* Registers `TRCSerialization` as default for body object class.
*
* That's useful to avoid typing `TRCRequest.requestBodySerialization` in each `TRCRequest` in most cases.
*
* Default registration is:
* - `NSArray` registered with `TRCSerializationJson`
* - `NSDictionary` registered with `TRCSerializationJson`
* - `NSData` registered with `TRCSerializationData`
* - `NSInputStream` registered with `TRCSerializationRequestInputStream`
* - `NSString` registered with `TRCSerializationString`
*
* So if you return `NSInputStream` as `bodyObject.TRCRequest` and avoid implementation of `TRCRequest.requestBodySerialization`
* then `TRCSerializationRequestInputStream` serialization would be used automatically
*
* Feel free to change that registration, by re-registering for same classes, or registering `nil`s
*
* @note class matching done using `NSObject.isKindOfClass` method. If you register different `TRCSerialization`-s for classes
* that inherit each over, then result is unexpected. For example if you register `TRCSerializationJson` for `NSArray` and
* `TRCSerializationPlist` for  `NSMutableArray` it's undefined which serialization would be taken for `NSMutableArray`.
*
* @param requestSerialization `TRCSerialization` string identifier to register or `nil` to undo registration
* @param clazz class used for matching when search for default serialization.
* */
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
