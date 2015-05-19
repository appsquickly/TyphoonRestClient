////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import "TRCErrorParserSimple.h"
#import "TRCUtils.h"
#import "TestUtils.h"


@implementation TRCErrorParserSimple
{

}

- (NSError *)errorFromResponseBody:(id)bodyObject headers:(NSDictionary *)headers status:(TRCHttpStatusCode)statusCode error:(NSError **)error
{
    return NSErrorWithFormat(@"%@", bodyObject[@"message"]);
}

- (BOOL)isErrorResponseBody:(id)bodyObject headers:(NSDictionary *)headers status:(TRCHttpStatusCode)statusCode
{
    if ([bodyObject isKindOfClass:[NSDictionary class]] && bodyObject[@"status"]) {
        NSInteger status = [bodyObject[@"status"] integerValue];
        return status < 200 || status >= 300;
    }
    return NO;
}


@end