//
//  NSDictionary+AutoDescription.m
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import "NSDictionary+AutoDescription.h"
#import "NSObject+AutoDescription.h"
#import "AutoDescriptionPrinter.h"

@implementation NSDictionary (AutoDescription)

- (void) autoDescribeWithPrinter:(AutoDescriptionPrinter *)printer
{
    [printer printText:@"{"];
    
    NSArray *allKeys = [self allKeys];

    if ([allKeys count]) {
        [printer printNewLine];
        [printer increaseIndent];
    }

	for (id key in self)
    {
        [printer printIndent];

        id value = self[key];

        if ([printer isObjectInPrintedStack:value]) {
            continue;
        }

        [key autoDescribeWithPrinter:printer];
        [printer printText:@" = "];
        [value autoDescribeWithPrinter:printer];
        
        if ([allKeys lastObject] != key) {
            [printer printText:@","];
        }
        [printer printNewLine];
	}

    if ([allKeys count]) {
        [printer decreaseIndent];
        [printer printIndent];
    }
    [printer printText:@"}"];
}

@end
