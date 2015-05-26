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

typedef NS_OPTIONS(NSInteger, TRCValueTransformerType)  {
    TRCValueTransformerTypeString = 1 << 0,
    TRCValueTransformerTypeNumber = 1 << 1,
};

@protocol TRCValueTransformer<NSObject>

/**
* Converts received value into custom object.
* You can receive NSString or NSNumber representation and create custom object from it.
* For example you can create NSURL object based on it's NSString representation
* */
- (id)objectFromResponseValue:(id)responseValue error:(NSError **)error;

/**
* Converts object into value used in request.
* For example you have NSURL object but want to use it as NSString in request
* Another example is NSDate represented as NSString or NSNumber(unix time) in request
* */
- (id)requestValueFromObject:(id)object error:(NSError **)error;

@optional

/**
* BitMask of value types in request and response. Used for validation purpose.
* Default value is TRCValueTransformerTypeString
*
* Examples
* If external type is TRCValueTransformerTypeString but received response value is not string, that will cause
* validation error.
* If external type is TRCValueTransformerTypeString but request value after transforming is not string, that also
* will cause a validation error.
**/
- (TRCValueTransformerType)externalTypes;

@end