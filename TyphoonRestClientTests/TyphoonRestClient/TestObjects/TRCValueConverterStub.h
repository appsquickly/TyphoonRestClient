//
// Created by Aleksey Garbarev on 21.09.14.
// Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRCValueConverter.h"


@interface TRCValueConverterStub : NSObject <TRCValueConverter>

@property (nonatomic) TRCValueConverterType supportedTypes;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSError *error;


@end