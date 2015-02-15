//
//  NSNumber+AutoDescription.m
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import "NSNumber+AutoDescription.h"
#import "AutoDescriptionPrinter.h"

@implementation NSNumber (AutoDescription)

- (void) autoDescribeWithPrinter:(AutoDescriptionPrinter *)printer
{
    const char *objcType = [self objCType];
    if (strlen(objcType) == 0) {
        return;
    }
    
    NSString *suffix = @"";
    
    char type = objcType[0];
    
    if (type == 'l') {
        suffix = @"L";
    } else if (type == 'q') {
        suffix = @"LL";
    } else if (type == 'I') {
        suffix = @"U";
    } else if (type == 'L') {
        suffix = @"UL";
    } else if (type == 'Q') {
        suffix = @"ULL";
    } else if (type == 'f') {
        suffix = @"f";
    }
    
    NSString *result = [NSString stringWithFormat:@"%@%@", [self description], suffix];
    [printer printText:result];
}

@end
