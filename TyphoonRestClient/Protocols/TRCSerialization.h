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

#import <Foundation/Foundation.h>

@class TRCSchema;

@protocol TRCRequestSerializer <NSObject>

- (NSData *)dataFromRequestObject:(id)requestObject;

- (NSString *)contentType;

@end

@protocol TRCResponseSerializer <NSObject>

- (id)objectFromResponseData:(NSData *)data;

- (BOOL)isCorrectContentType:(NSString *)responseContentType;

@end


@protocol TRCSchemaFormat <NSObject>

- (NSString *)extension;

- (TRCSchema *)schemaFromData:(NSData *)data;

@end
