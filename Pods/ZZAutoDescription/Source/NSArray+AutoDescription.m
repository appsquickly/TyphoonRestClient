//
//  NSArray+AutoDescription.m
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import "NSArray+AutoDescription.h"
#import "AutoDescriptionPrinter.h"

@implementation NSArray (AutoDescription)

- (void) autoDescribeWithPrinter:(AutoDescriptionPrinter *)printer
{
    [printer printText:@"["];
    
    if ([self count]) {
        [printer printNewLine];
        [printer increaseIndent];
    }

	for (id object in self)
    {
        [printer printIndent];
        [object autoDescribeWithPrinter:printer];
        
        if ([self lastObject] != object) {
            [printer printText:@","];
        }

        [printer printNewLine];
	}

    if ([self count]) {
        [printer decreaseIndent];
        [printer printIndent];
    }
    [printer printText:@"]"];
}

@end
