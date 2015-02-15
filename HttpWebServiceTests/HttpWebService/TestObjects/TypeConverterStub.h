//
// Created by Aleksey Garbarev on 21.09.14.
// Copyright (c) 2014 Code Monastery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HWSValueConverter.h"


@interface TypeConverterStub: NSObject <HWSValueConverter>

@property (nonatomic) HWSValueConverterType supportedTypes;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSError *error;


@end