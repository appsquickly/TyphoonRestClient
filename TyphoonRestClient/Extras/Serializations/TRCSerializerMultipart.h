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

@interface TRCMultipartFile : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *mimeType;

@end

@interface TRCSerializerMultipart : NSObject <TRCRequestSerializer>

@end