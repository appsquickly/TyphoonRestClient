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

@protocol TRCValueConverter;

@protocol TRCValueConverterRegistry<NSObject>

- (id<TRCValueConverter>)valueConverterForTag:(NSString *)type;

@end