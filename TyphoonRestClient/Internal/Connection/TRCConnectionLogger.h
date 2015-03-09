////////////////////////////////////////////////////////////////////////////////
//
//  AppsQuick.ly
//  Copyright 2015 AppsQuick.ly
//  All Rights Reserved.
//
//  NOTICE: This software is the proprietary information of AppsQuick.ly
//  Use is subject to license terms.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "TRCConnection.h"


@protocol TRCConnectionLoggerWriter;
@protocol TRCConnection;


@interface TRCConnectionLogger : NSObject <TRCConnection>

@property(nonatomic, strong) id <TRCConnection> connection;
@property(nonatomic, strong) id <TRCConnectionLoggerWriter> writer;

@property(nonatomic) BOOL shouldLogUploadProgress;
@property(nonatomic) BOOL shouldLogDownloadProgress;

@end

@protocol TRCConnectionLoggerWriter <NSObject>

- (void)logString:(NSString *)string;

@end