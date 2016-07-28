////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2016 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////

#import "TRCProxyProgressHandler.h"


@implementation TRCProxyProgressHandler
{
    id<TRCProgressHandler> _progressHandler;

    TRCUploadProgressBlock _uploadProgressBlock;
    TRCDownloadProgressBlock _downloadProgressBlock;
    TRCProgressHandlerState _state;
}

- (void)setProgressHandler:(id<TRCProgressHandler>)progressHandler
{
    _progressHandler = progressHandler;

    if (_state == TRCProgressHandlerStateCanceling) {
        [_progressHandler cancel];
    } else if (_state == TRCProgressHandlerStateSuspended) {
        [progressHandler pause];
    } else if (_state == TRCProgressHandlerStateRunning) {
        [progressHandler resume];
    }
    [_progressHandler setUploadProgressBlock:_uploadProgressBlock];
    [_progressHandler setDownloadProgressBlock:_downloadProgressBlock];
}

- (BOOL)isCancelled
{
    return [self state] == TRCProgressHandlerStateCanceling;
}

- (void)setUploadProgressBlock:(TRCUploadProgressBlock)block
{
    if (_progressHandler) {
        [_progressHandler setUploadProgressBlock:block];
    } else {
        _uploadProgressBlock = block;
    }
}

- (void)setDownloadProgressBlock:(TRCDownloadProgressBlock)block
{
    if (_progressHandler) {
        [_progressHandler setDownloadProgressBlock:block];
    } else {
        _downloadProgressBlock = block;
    }
}

- (void)pause
{
    if (_progressHandler) {
        [_progressHandler pause];
    } else {
        _state = TRCProgressHandlerStateSuspended;
    }
}

- (void)resume
{
    if (_progressHandler) {
        [_progressHandler resume];
    } else {
        _state = TRCProgressHandlerStateRunning;
    }
}

- (void)cancel
{
    if (_progressHandler) {
        [_progressHandler cancel];
    } else {
        _state = TRCProgressHandlerStateCanceling;
    }
}

- (TRCProgressHandlerState)state
{
    if (_progressHandler) {
        return [_progressHandler state];
    } else {
        return _state;
    }
}


@end