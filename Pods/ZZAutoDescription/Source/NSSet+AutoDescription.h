//
//  NSSet+AutoSecription.h
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AutoDescriptionPrinter;

@interface NSSet (AutoSecription)

- (void) autoDescribeWithPrinter:(AutoDescriptionPrinter *)printer;

@end
