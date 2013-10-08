//
//  RDSession.m
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

#import "RDSession.h"

@implementation RDSession

- (void)startWithConnection:(GCDAsyncSocket *)newSocket
{
    self.connection = newSocket;
    [self startScreenCapture];
}

- (void)startScreenCapture
{
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset960x540;
    
    self.screenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:kCGDirectMainDisplay];
    [self.session addInput:self.screenInput];
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoDataOutput.videoSettings = @{AVVideoCodecKey: AVVideoCodecH264};
    self.videoDispatchQueue = dispatch_queue_create("videoData", 0);
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDispatchQueue];
    [self.session addOutput:self.videoDataOutput];
    
    [self.session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t blockLength = CMBlockBufferGetDataLength(blockBuffer);
    NSMutableData *data = [NSMutableData dataWithLength:blockLength];
    CMBlockBufferCopyDataBytes(blockBuffer, 0, blockLength, data.mutableBytes);
    
    NSLog(@"Sending %zu bytes", blockLength);
    [self.connection writeData:data withTimeout:-1 tag:0];
}

@end
