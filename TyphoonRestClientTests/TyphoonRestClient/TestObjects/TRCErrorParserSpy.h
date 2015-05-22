//
//  TRCErrorParserSpy.h
//  Iconic
//
//  Created by Aleksey Garbarev on 20.09.14.
//  Copyright (c) 2014 Apps Quickly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRCErrorHandler.h"

@interface TRCErrorParserSpy : NSObject <TRCErrorHandler>

@property (nonatomic) BOOL parseErrorCalled;

@property (nonatomic, strong) NSError *parsedError;
@property (nonatomic, strong) NSError *errorParsingError;

@property (nonatomic, strong) NSString *schemaName;

@end
