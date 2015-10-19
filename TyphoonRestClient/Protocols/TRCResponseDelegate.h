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

@protocol TRCConnection;

@protocol TRCResponseDelegate <NSObject>

@optional
- (BOOL)connection:(id<TRCConnection>)connection shouldProcessResponse:(NSURLResponse *)response;

- (void)connection:(id<TRCConnection>)connection didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

- (void)connection:(id<TRCConnection>)connection didReceiveData:(NSData *)data;

- (void)connection:(id<TRCConnection>)connection didCompleteWithError:(NSError *)networkError;

@end