//
//  TRCTestableObjectConverter.h
//  TyphoonRestClient
//
//  Created by Aleksey Garbarev on 17.02.15.
//  Copyright (c) 2015 Apps Quickly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRCObjectMapper.h"

@interface TRCPersonMapper : NSObject <TRCObjectMapper>

@property (nonatomic) BOOL requestParsingImplemented;
@property (nonatomic) BOOL responseParsingImplemented;


@end
