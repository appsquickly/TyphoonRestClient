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

#import "SimpleErrorParser.h"
#import "TRCUtils.h"
#import "TyphoonRestClientErrors.h"


@implementation SimpleErrorParser
{

}
- (NSError *)errorFromResponseBody:(NSDictionary *)bodyObject headers:(NSDictionary *)headers status:(TRCHttpStatusCode)statusCode error:(NSError **)error
{
    return TRCErrorWithFormat(TyphoonRestClientErrorCodeBadResponseCode, @"%@", bodyObject[@"message"]);
}

@end