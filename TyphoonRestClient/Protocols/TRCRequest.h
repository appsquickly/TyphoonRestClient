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

#import <Foundation/Foundation.h>

/**
* ValueOrNull returns value if it's not `nil` or `[NSNull null]` instead.
* Useful when you compose dictionary with optional values to avoid crashes or annoying checking for each value.
* `TyphoonRestClient` skips any `[NSNull null]` values in response and request dictionaries by default.
* @see
* `TyphoonRestClient.validationOptions`
* */
#define ValueOrNull(value) (value?:(__typeof(value))[NSNull null])

typedef NSInteger TRCHttpStatusCode;

//-------------------------------------------------------------------------------------------
#pragma mark - HTTP METHODS
//-------------------------------------------------------------------------------------------

/**
* `TRCRequestMethod` is NSString used as HTTP method.
* If you need some additional HTTP methods, feel free to use your own.
**/
typedef NSString * TRCRequestMethod;
/// POST
extern TRCRequestMethod TRCRequestMethodPost;
/// GET
extern TRCRequestMethod TRCRequestMethodGet;
/// PUT
extern TRCRequestMethod TRCRequestMethodPut;
/// DELETE
extern TRCRequestMethod TRCRequestMethodDelete;
/// PATCH
extern TRCRequestMethod TRCRequestMethodPatch;
/// HEAD
extern TRCRequestMethod TRCRequestMethodHead;


//-------------------------------------------------------------------------------------------
#pragma mark - SERIALIZATION
//-------------------------------------------------------------------------------------------
/**
* `TRCSerialization` is registered name of request/response serializer.
*
* `TyphoonRestClient` uses that string as identifier to find registered `TRCRequestSerializer`/`TRCResponseSerializer`
* implementation and uses it to process response/request body object.
*
* It's NSString, so you can create your own `TRCSerialization` string, and register your `TRCRequestSerializer` and
* `TRCResponseSerializer` implementation, using `registerRequestSerializer:forName:` and `registerResponseSerializer:forName:`
* methods of `TyphoonRestClient`
*
* @see
* `TRCRequestSerializer`
* @see
* `TRCResponseSerializer`
* @see
* `TyphoonRestClient.registerRequestSerializer:forName:`
* @see
* `TyphoonRestClient.registerResponseSerializer:forName:`
* */
typedef NSString *TRCSerialization;

/**
* Registered for `TRCSerializerJson`.
* Can be used as request and response serializer
*
* Request body object must be `NSDictionary` or `NSArray`, based on structure.
* Response object would be `NSDictionary` or `NSArray` based on structure
* */
extern TRCSerialization TRCSerializationJson;

/**
* Registered for `TRCSerializationPlist`.
* Can be used as request and response serializer
*
* Request body object must be `NSDictionary` or `NSArray`, based on structure.
* Response object would be `NSDictionary` or `NSArray` based on structure
* */
extern TRCSerialization TRCSerializationPlist;

/**
* Registered for `TRCSerializerData`.
* Can be used as request and response serializer
*
* This serialization just send data as is.
* Request object must be `NSData`
* Response object would be `NSData` (or nil, if `TRCRequest.responseBodyOutputStream` specified)
*
* @see
* `TRCRequest.responseBodyOutputStream`
* */
extern TRCSerialization TRCSerializationData;

/**
* Registered for `TRCSerializerString`.
* Can be used as request and response serializer
*
* This serialization just converts `NSString` into `NSData` using UTF-8 encoding and vise versa.
* Request object must be `NSString`
* Response object would be `NSString`
* */
extern TRCSerialization TRCSerializationString;

/**
* Registered for `TRCSerializerHttpQuery`.
* Can be used **ONLY** for request body.
*
* This serialization converts `NSDictionary` into HTTP Query String
* (see https://en.wikipedia.org/wiki/Query_string for details)
*
* Request object must be `NSDictionary`
* */
extern TRCSerialization TRCSerializationRequestHttp;

/** Registered for `TRCSerializerInputStream`.
* Can be used **ONLY** for request body.
*
* This serialization similar to `TRCSerializationData` but takes `NSInputStream` as
* request object.
* Useful when request body too large to load into memory. Usually used for file uploading.
*
* Request object must be `NSInputStream`
* */
extern TRCSerialization TRCSerializationRequestInputStream;

/** Registered for `TRCSerializerImage`.
* Can be used **ONLY** for response body.
*
* This serialization converts received data into UIImage. This also makes
* minimal validation (by content-type header).
*
* Response object would be `UIImage`
* */
extern TRCSerialization TRCSerializationResponseImage;


/**
* The `TRCRequest` implementation manages request composing and response handling at same time. Each `TRCRequest` implementation
* represents one API call which does one function.
*
* @discussion
* Any information and logic, specific for that API call should be placed inside implementation of `TRCRequest`. Then you can easily
* manage your *requests*: just add one more `TRCRequest` implementation and this means adding one more API call. Same for deletion,
* no need to change something else somewhere in the app. Only `TRCRequest` and it's usage in the app.
*
* `TRCRequest` implementations should be lite. If see that something can be reused, check if it can be done via `TRCObjectMapper`,
* `TRCValueTransformer`, `TRCConnection`. I thought to place here only information specific to API call (i.e. can't be reused)
*
* Most methods, related to request composing, starts from `request` prefix. At same time,
* method related tot response processing, starts from `response` prefix
* */
@protocol TRCRequest<NSObject>

//=============================================================================================================================
#pragma mark - Request
//=============================================================================================================================

@required

/**
* Provide endpoint here. It can be relative path as well as absolute path to endpoint (matching by http: or https: prefix)
* I.e. if path starts from `http://` or `https://`, then it used as absolute URL, in other case path would be appended into
* base URL, specified in connection.
*
* If your URL has dynamic parts, you can mark them as path argument via curly braces like this:
*    order/{id}
* that means that url has one argument named 'id' and it will be replaced by real value specified in `TRCRequest.pathParameters`.
* @see `TRCRequest.pathParameters`
* */
- (NSString *)path;

/**
* Specify one of HTTP methods type here. `TRCRequestMethod` is NSString, so if you server requires some custom, non-standard HTTP method,
* just return it here as NSString
* @see `TRCRequestMethod`
* */
- (TRCRequestMethod)method;

@optional

/**
* This method should return dictionary with path arguments and variables
*
* 1) Arguments - dynamic parts of URL path, wrapped by braces.
* For example:
*    - order/{id}
*    - person/{person-id}/children/{child-id}
*
* 2) Variables - usual URL parameters, like this:
*    - order?id=123
*    - person?person-id=123&child-id=321
*
* In both examples dictionary should be:
* @code @{ @"person-id":@"123", @"child-id": @"321" } @endcode
*
* Of course you can mix arguments and variables together in one dictionary
* For example if want to compose something like this:
*
*   ``` person/123?child-id=321 ```
*
* your path should be:
*
*  ```person/{person-id}```
*
* and pathParameters should be:
*    @code @{ @"person-id":@"123", @"child-id": @"321" } @endcode
*
* This dictionary can be validated (and transformed) using schema file. See `TRCRequest.pathParametersValidationSchemaName`
*
* @see
* `TRCRequest.requestPathParametersValidationSchemaName`
* */
- (NSDictionary *)pathParameters;

/**
* Specify name of schema file. This file must be included into application bundle.
* If this method not implemented then ClassName.path.{format} name assumed
* */
- (NSString *)pathParametersValidationSchemaName;

/**
* Provide custom HTTP headers here. These headers will override default on conflicts.
* */
- (NSDictionary *)requestHeaders;

/**
* Provide data for the request body here.
*
* Type of that object depends on `TRCSerialization` used for that request.
*
* For example, `requestBody` value could be:
* - NSArray or NSDictionary - in case of `TRCSerializationJson` or `TRCSerializationPlist`
* - NSData - in case of `TRCSerializationData`
* - NSString - in case of `TRCSerializationString`
* - NSInputStream - in case of `TRCSerializationRequestInputStream`
* - any custom object in case of custom serializers you may registered
*
* It uses `TRCSerialization` from `TRCRequest.requestBodySerialization` method if specified. If `TRCRequest.requestSerialization`
* not implemented, then used default serialization for that type, specified in `TyphoonRestClient`.
* To register default serialization for `requestBody` type, use `TyphoonRestClient.registerDefaultRequestSerialization:forBodyObjectWithClass:`
* method.
*
* Note, if you `TRCRequest has request body validation scheme, then this object would be transformed using `TRCValueTransformer`s and
* `TRCObjectMapper`s specified in schema, and the validated.
* If validation isn't passed, request wouldn't being sent and finishes with error
*
* @see
* `TRCRequest.requestSerialization`
* @see
* `TyphoonRestClient.registerDefaultRequestSerialization:forBodyObjectWithClass:`
* * @see
* `TRCSerialization`
* */
- (id)requestBody;

/**
* Specify name of schema file. This file must be included into application bundle.
* If this method not implemented then ClassName.request.{format} name assumed
* */
- (NSString *)requestBodyValidationSchemaName;

/**
* Specify kind of `requestBody` serialization here.
*
* Specify body serialization here. Using that type, your `requestBody` object will be converted into `NSDate` or `NSInputStream`.
*
* By default, next values available:
* - `TRCSerializationJson`
* - `TRCSerializationPlist`
* - `TRCSerializationData`
* - `TRCSerializationString`
* - `TRCSerializationRequestHttp`
* - `TRCSerializationRequestInputStream`
*
* Use `TyphoonRestClient.registerRequestSerializer:forName:` to register your own request serializers
*
* @see
* `TRCSerialization`
* */
- (TRCSerialization)requestBodySerialization;

//=============================================================================================================================
#pragma mark - Response
//=============================================================================================================================

@optional
/**
* Specify name of schema file. This file must be included into application bundle.
* If this method not implemented then ClassName.response.{format} name assumed
* */
- (NSString *)responseBodyValidationSchemaName;

/**
* Specify kind of expected response here. This information used to compose object from response body.
*
* By default, next values available:
* - `TRCSerializationJson`
* - `TRCSerializationPlist`
* - `TRCSerializationData`
* - `TRCSerializationString`
* - `TRCSerializationResponseImage`
*
* Use `TyphoonRestClient.registerResponseSerializer:forName:` to register your own response serializers
*
* If this method is not implemented, default value assumed, specified as `TyphoonRestClient.defaultResponseSerialization`
*
* @note
* If want to save response body as is to file, then don't implement this method. Check `TRCRequest.responseBodyOutputStream`
* method instead.
*
* @see
* `TRCRequest.responseBodyOutputStream`
* @see
* `TRCSerialization`
* @see
* `TyphoonRestClient.defaultResponseSerialization`
* */
- (TRCSerialization)responseBodySerialization;

/**
* Implement this method to specify custom output stream. If you implement this method all output will be forwarded into
* that stream and `bodyObject` will be `nil` (so any schema validation will not be used). Useful when you want to save binary
* response data to disk to avoid memory overhead.
*
* @note
* If you override this method, `responseBodySerialization` must be `TRCSerializationData` or not implemented.
* */
- (NSOutputStream *)responseBodyOutputStream;

/**
* Result of this method will be returned as `result` in the `TyphoonRestClient.sendRequest:completion:`.
*
* If this method not implemented, it's equal to returning `bodyObject` as is.
* You can add additional validation of `responseHeaders` and `statusCode` here, and write `parseError` if something goes wrong.
*
* This method aimed to post-process `bodyObject` in per-request basis. It's also useful to compose your model objects, based on
* information from `bodyObject` (i.e. doing mapping into model objects)
*
* `bodyObject` depends on `TRCRequest.responseBodySerialization` type, and can be, for example:
* - `NSArray` or `NSDictionary`, if serialization is `TRCSerializationJson` or `TRCSerializationPlist`
* - `NSData`, if serialization is `TRCSerializationData`
* - `UIImage`, if serialization is `TRCSerializationResponseImage`
* - `NSString`, if serialization is `TRCSerializationString`
* - nil, when `TRCRequest.responseBodyOutputStream` is implemented
* - custom model object, when using custom `TRCSerialization`
* - custom model object, when using `TRCObjectMapper` for root object
*
* Also note, `bodyObject` that comes from serializer, validated using schema, post-processed by `TRCValueTransformer` and `TRCObjectMapper`s
*
* ```NSData -> TRCSerializer -> ... TRCObjectMapper-s ... -> bodyObject```
*
* That means, that `bodyObject` already validated here (has correct structure), no need to check it here again. That also means, that some parts of
* object (or whole objects itself) already converted into model objects to use in the app
*
* @see
* `TRCObjectMapper`
* `TRCValueTransformer`
** */
- (id)responseProcessedFromBody:(id)bodyObject headers:(NSDictionary *)responseHeaders status:(TRCHttpStatusCode)statusCode error:(NSError **)parseError;

/**
* Error notification. Called when network call ended with error. Used to do some custom logic on error (for example delete resource at output stream, clean up, etc.. )
* */
- (void)respondedWithError:(NSError *)networkError headers:(NSDictionary *)responseHeaders status:(TRCHttpStatusCode)statusCode;

//-------------------------------------------------------------------------------------------
#pragma mark - Custom context
//-------------------------------------------------------------------------------------------

@optional
/**
* Use custom properties dictionary to pass parameters into your own
* `TRCConnection` implementation or `TRCPostProcessor` (to handle specific per-request cases)
* */
- (NSDictionary *)customProperties;

/**
* Use queue priority for your custom `TRCConnection` implementation. Useful if your `TRCConnection` has limitation on
* number of concurrent requests, then you can specify priority here
**/
- (NSOperationQueuePriority)queuePriority;

@end
