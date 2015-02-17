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

@protocol TRCConvertersRegistry<NSObject>

- (id<TRCValueConverter>)valueConverterForTag:(NSString *)tag;

- (id<TRCObjectConverter>)objectConverterForTag:(NSString *)tag;

@end