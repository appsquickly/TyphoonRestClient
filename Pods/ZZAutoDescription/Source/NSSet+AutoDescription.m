//
//  NSSet+AutoDescription.m
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import "NSSet+AutoDescription.h"
#import "AutoDescriptionPrinter.h"

@implementation NSSet (AutoDescription)

- (void) autoDescribeWithPrinter:(AutoDescriptionPrinter *)printer
{
    [printer printText:@"<["];
    
    NSArray *allObjects = [self allObjects];

    if ([allObjects count]) {
        [printer printNewLine];
        [printer increaseIndent];
    }

	for (id object in allObjects)
    {
        [printer printIndent];
        [object autoDescribeWithPrinter:printer];

        if ([allObjects lastObject] != object) {
            [printer printText:@","];
        }
        [printer printNewLine];
	}
    
    if ([allObjects count]) {
        [printer decreaseIndent];
        [printer printIndent];
    }
    [printer printText:@"]>"];
}

@end
