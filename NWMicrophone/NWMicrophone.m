//
//  NWMicrophone.m
//  NWMicrophone
//
//  Created by Nicholas White on 10/30/15.
//  Copyright © 2015 Nicholas White. All rights reserved.
//

#import "NWMicrophone.h"
#import "Novocaine.h"

@interface NWMicrophone()

@end

@implementation NWMicrophone {
    __weak id<AVCaptureAudioDataOutputSampleBufferDelegate> _delegate;
    __weak dispatch_queue_t _dispatchQueue;
    
    AudioStreamBasicDescription _asbd;
    CMFormatDescriptionRef format;
    
    BOOL _configured;
}

static NWMicrophone *singleton;

+ (instancetype)audioManager {
    if (!singleton) {
        singleton = [[NWMicrophone alloc] init];
    }
    return singleton;
}

- (void)setSampleBufferDelegate:(id<AVCaptureAudioDataOutputSampleBufferDelegate>)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue {
    _delegate = sampleBufferDelegate;
    _dispatchQueue = sampleBufferCallbackQueue;
}

- (id<AVCaptureAudioDataOutputSampleBufferDelegate>)sampleBufferDelegate {
    return _delegate;
}

- (BOOL)start {
    NSLog(@"Start recording");
    Novocaine *audioManager = [Novocaine audioManager];
    if (!_configured) {
        __weak typeof(self)weakSelf = self;
        [audioManager setInputBlock:^(float *newAudio, UInt32 numSamples, UInt32 numChannels, CMTime pts) {
            [weakSelf receivedAudioBuffers:newAudio numFrames:numSamples time:pts];
            //NSLog(@"Received %d samples at %f: %.3f %.3f %.3f %.3f", numSamples, pts.value / (float)pts.timescale, newAudio[0], newAudio[1], newAudio[2], newAudio[3]);
            // Now you're getting audio from the microphone every 20 milliseconds or so. How's that for easy?
            // Audio comes in interleaved, so,
            // if numChannels = 2, newAudio[0] is channel 1, newAudio[1] is channel 2, newAudio[2] is channel 1, etc.
        }];
        _asbd = [audioManager inputFormat];
        _configured = YES;
    }
    [audioManager play];
    return YES;
}

- (void)stop {
    [[Novocaine audioManager] pause];
}

- (OSStatus)receivedAudioBuffers:(float *)buffers numFrames:(UInt32)numFrames time:(CMTime)time {
    OSStatus result = 0;
    
    @autoreleasepool {

        CMSampleBufferRef sampleBuffer = NULL;
        CMSampleTimingInfo timing = { CMTimeMake(numFrames, _asbd.mSampleRate), time, kCMTimeInvalid };
        
        if (!format) {
            result = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &_asbd, 0, NULL, 0, NULL, NULL, &format);
        }
        
        size_t size = numFrames * sizeof(float);
        float *blockData = (float*) malloc(size);
        //NSLog(@"buffers: %d %d -- %d %d %d %d", buffers->mNumberBuffers, buffer->mDataByteSize, shorts[0], shorts[1], shorts[2], shorts[3]);
        memcpy(blockData, buffers, size);
        CMBlockBufferRef blockBuffer;
        CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                         blockData,
                                         size,
                                         kCFAllocatorMalloc,
                                         NULL, 0, size,
                                         0, &blockBuffer);
        
        result = CMSampleBufferCreate(kCFAllocatorDefault,blockBuffer,true,NULL,NULL,format, numFrames, 1, &timing, 0, NULL, &sampleBuffer);
        
        dispatch_async(_dispatchQueue, ^{
            [_delegate captureOutput:self didOutputSampleBuffer:sampleBuffer fromConnection:nil];
            CFRelease(blockBuffer);
            CFRelease(sampleBuffer);
        });
        
    }
    return result;
}


@end
