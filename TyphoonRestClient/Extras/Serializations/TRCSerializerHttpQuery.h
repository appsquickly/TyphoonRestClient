////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON REST CLIENT
//  Copyright 2015, Typhoon Rest Client Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "TRCInfrastructure.h"

typedef NS_OPTIONS(NSInteger, TRCSerializerHttpQueryOptions) {
    TRCSerializerHttpQueryOptionsNone = 0,
    TRCSerializerHttpQueryOptionsIncludeArrayIndices = 1 << 0
};

@interface TRCSerializerHttpQuery : NSObject <TRCRequestSerializer>

@property (nonatomic) TRCSerializerHttpQueryOptions options;

@end