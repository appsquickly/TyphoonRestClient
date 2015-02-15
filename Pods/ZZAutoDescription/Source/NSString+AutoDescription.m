//
//  NSString+AutoDescription.m
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import "NSString+AutoDescription.h"
#import "AutoDescriptionPrinter.h"

@implementation NSString (AutoDescription)

- (void) autoDescribeWithPrinter:(AutoDescriptionPrinter *)printer
{
    NSString *quotedDescription = [NSString stringWithFormat:@"\"%@\"", [self description]];
    [printer printText:quotedDescription];
}

@end
