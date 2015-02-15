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

typedef NS_OPTIONS(NSInteger, HWSValueConverterType)  {
    HWSValueConverterTypeString = 1,
    HWSValueConverterTypeNumber = 2,
};

@protocol HWSValueConverter<NSObject>

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
* BitMask of value types in request and response. Used for validation purpose
* Default value is HWSValueConverterTypeString
* */
- (HWSValueConverterType)types;

@end