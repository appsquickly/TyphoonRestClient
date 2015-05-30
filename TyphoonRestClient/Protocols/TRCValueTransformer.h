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
* TRCValueTransformerType describes types which can be used in serialization format.
*
* Available values for `TRCValueTransformerType` are depends on serialization format you using. For example, JSON has only
* two simple (atomic) types, it's number and string (array and dictionary are not simple (or atomic)).
* Another example is Plist, it has all JSON types, plus date and  data. If your format has another format, you can register them
* using `TyphoonRestClient.registerTRCValueTransformerType:withValueClass:` method. Like this:
* @code
* [_restClient registerTRCValueTransformerType:&TRCValueTransformerTypeString withValueClass:[NSString class]];
* [_restClient registerTRCValueTransformerType:&TRCValueTransformerTypeNumber withValueClass:[NSNumber class]];
* @endcode
* */
typedef NSInteger TRCValueTransformerType;

/// Represents NSString
TRCValueTransformerType TRCValueTransformerTypeString;

/// Represents NSNumber
TRCValueTransformerType TRCValueTransformerTypeNumber;

/**
* `TRCValueTransformer` aimed to convert simple (atomic) typed objects, received as response, into
* objects to use inside app, and vise versa.
*
* Examples:
* - Convert received NSString into NSURL
* - Convert NSDate in request into NSString(using special formatting) or NSNumber(unix time)
* - Convert received string value into something like ENUM, or custom object
* */
@protocol TRCValueTransformer <NSObject>

/**
* Converts received value into custom object.
*
* @param responseValue input value to process, has external type (type which can be used in your serialization format)
* @param error pointer to write back
* @return returns value to use in the app
* */
- (id)objectFromResponseValue:(id)responseValue error:(NSError **)error;

/**
* Converts object into value which can be used in request
*
* @param object object specified in request
* @param error error to write back
* @return value which can be used in request (type allowed by your serialization format)
* */
- (id)requestValueFromObject:(id)object error:(NSError **)error;

@optional

/**
* BitMask of value types (`TRCValueTransformerType`), used in request and response. Used for validation purpose.
* If not implemented, TRCValueTransformerTypeString is assumed
*
* *external* means that these types used outside the app, so we have to convert them into app's types. For example JSON
* has only number and string value - they are external types. Inside app we have NSData and we want to send it to the server
* we can't send our NSDate using JSON directly, but we can convert NSDate into NSNumber or NSString.
* This method declares acceptable types, that sounds like 'this value transformer accepts NSNumber for response value and at
* same time, it converts NSDate into NSNumber'.
*
* See `TRCValueTransformerType` for more details about available values
*
* Validation examples:
* - If external type is `TRCValueTransformerTypeString` but received response value is not string, that will cause
* validation error.
* - If external type is `TRCValueTransformerTypeString` but request value after transforming is not string, that also
* will cause a validation error.
* */
- (TRCValueTransformerType)externalTypes;

@end
