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
#import "TyphoonRestClient.h"

NSError *NSErrorWithFormat(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
NSString *KeyFromOptionalKey(NSString *key, BOOL *isOptional);
NSError *NSErrorFromErrorSet(NSOrderedSet *errors, NSString *action);

id ValueAfterApplyingOptions(id value, TRCValidationOptions options, BOOL isRequest, BOOL isOptional);