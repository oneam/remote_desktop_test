//
//  RDServer.m
//  RemoteDesktopServerOSX
//
//  Copyright (c) 2013 Sam Leitch. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

#import "RDServer.h"
#import "RDSession.h"

@implementation RDServer

- (id)init
{
    self = [super init];
    
    if(self)
    {
        self.activeSessions = [NSMutableArray array];
    }
    
    return self;
}

- (void)updateStatusWithMessage:(NSString *)status
{
    if([self.delegate respondsToSelector:@selector(statusUpdatedWithMessage:)])
    {
        [self.delegate statusUpdatedWithMessage:status];
    }
}

- (void)startWithListenPort:(uint16_t)listenPort
{
    self.socketDispatchQueue = dispatch_queue_create("socket", 0);
    self.connectionListener = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketDispatchQueue];
    
    NSError *error;
    [self.connectionListener acceptOnPort:listenPort error:&error];
    [self updateStatusWithMessage:[NSString stringWithFormat:@"Listening on port %d...", listenPort]];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    RDSession *session = [[RDSession alloc] init];
    [self.activeSessions addObject:session];
    newSocket.userData = session;
    
    [self updateStatusWithMessage:@"Remote client connected"];
    [session startWithConnection:newSocket];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    RDSession *session = (RDSession *)sock.userData;
    [self.activeSessions removeObject:session];
}

@end
