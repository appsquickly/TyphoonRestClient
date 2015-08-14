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
#import "TRCConnection.h"
#import "TRCConnectionProxy.h"


@protocol TRCConnectionLoggerWriter;
@protocol TRCConnection;


@interface TRCConnectionLogger : TRCConnectionProxy <TRCConnection>

@property(nonatomic, strong) id<TRCConnectionLoggerWriter> writer;

@property(nonatomic) BOOL shouldLogUploadProgress;
@property(nonatomic) BOOL shouldLogDownloadProgress;

@property(nonatomic) BOOL shouldLogBinaryDataAsBase64;

@end

@protocol TRCConnectionLoggerWriter <NSObject>

- (void)writeLogString:(NSString *)string;

@end