//
//  NWMicrophone.m
//  NWMicrophone
//
//  Created by Nicholas White on 10/30/15.
//  Copyright © 2015 Nicholas White. All rights reserved.
//

#import "NWMicrophone.h"
#include "NWCUtils.h"

#define kOutputBusNumber 0
#define kInputBusNumber 1

@interface NWMicrophone()

@property (nonatomic, readonly)AudioUnit *audioUnit;
- (OSStatus)receivedAudioBuffers:(AudioBufferList*)buffers numFrames:(UInt32)numFrames time:(CMTime)time;

@end


OSStatus renderCallback(void *userData, AudioUnitRenderActionFlags *actionFlags,
                        const AudioTimeStamp *audioTimeStamp, UInt32 busNumber,
                        UInt32 numFrames, AudioBufferList *buffers) {
    NWMicrophone *delegate = (__bridge NWMicrophone*)userData;
    OSStatus status = AudioUnitRender(*(delegate.audioUnit), actionFlags, audioTimeStamp, 1, numFrames, buffers);
    if(status != noErr) {
        NSLog(@"render callback error %d", status);
        return status;
    }
    return [delegate receivedAudioBuffers:buffers numFrames:numFrames time:CMTimeMake((UInt32)(44100 * audioTimeStamp->mSampleTime), 44100)];
}

int initAudioStreams(AudioUnit *audioUnit, id delegate, AudioStreamBasicDescription *streamDescription) {
    AudioComponentDescription componentDescription;
    componentDescription.componentType = kAudioUnitType_Output;
    componentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDescription.componentFlags = 0;
    componentDescription.componentFlagsMask = 0;
    AudioComponent component = AudioComponentFindNext(NULL, &componentDescription);
    int err;
    if((err = AudioComponentInstanceNew(component, audioUnit)) != noErr) {
        NSLog(@"no audio unit: %d", err);
        return 1;
    }
    
    UInt32 flag = 1;
    if((err = AudioUnitSetProperty(*audioUnit, kAudioOutputUnitProperty_EnableIO,
                            kAudioUnitScope_Input, kInputBusNumber, &flag, sizeof(flag))) != noErr) {
        NSLog(@"Can't set input io: %d", err);
        return 1;
    }
    /*
    //flag = 0;
    if((err = AudioUnitSetProperty(*audioUnit, kAudioOutputUnitProperty_EnableIO,
                                   kAudioUnitScope_Output, kOutputBusNumber, &flag, sizeof(flag))) != noErr) {
        NSLog(@"Can't set output io: %d", err);
        return 1;
    }
     */
    
    AudioStreamBasicDescription outputFormat;
    UInt32 size;
    size = sizeof( AudioStreamBasicDescription );
    CheckError( AudioUnitGetProperty(*audioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Input,
                                     1,
                                     streamDescription,
                                     &size ),
               "Couldn't get the hardware input stream format");
    
    // Check the output stream format
    size = sizeof( AudioStreamBasicDescription );
    CheckError( AudioUnitGetProperty(*audioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Output,
                                     1,
                                     &outputFormat,
                                     &size ),
               "Couldn't get the hardware output stream format");
    NSLog(@"inputFormat : %@", NSStringFromASBD(*streamDescription));
    NSLog(@"outputFormat : %@", NSStringFromASBD(outputFormat));
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback; // Render function
    if (delegate) {
        callbackStruct.inputProcRefCon = (__bridge void *)delegate;
    } else {
        callbackStruct.inputProcRefCon = NULL;
    }
    if((err = AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_SetRenderCallback,
                            kAudioUnitScope_Global, kInputBusNumber, &callbackStruct,
                            sizeof(AURenderCallbackStruct))) != noErr) {
        NSLog(@"Can't set property callback: %d", err);
        return 1;
    }
    
    // You might want to replace this with a different value, but keep in mind that the
    // iPhone does not support all sample rates. 8kHz, 22kHz, and 44.1kHz should all work.
    streamDescription->mSampleRate = 44100.00;
    /*
    // Yes, I know you probably want floating point samples, but the iPhone isn't going
    // to give you floating point data. You'll need to make the conversion by hand from
    // linear PCM <-> float.
    streamDescription->mFormatID = kAudioFormatLinearPCM;
    // This part is important!
    streamDescription->mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    //streamDescription->mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
    // Not sure if the iPhone supports recording >16-bit audio, but I doubt it.
    streamDescription->mBitsPerChannel = 16;
    // Record in mono. Use 2 for stereo, though I don't think the iPhone does true stereo recording
    streamDescription->mChannelsPerFrame = 1;
    // 1 sample per frame, will always be 2 as long as 16-bit samples are being used
    streamDescription->mBytesPerFrame = 2;
    streamDescription->mBytesPerPacket = streamDescription->mBytesPerFrame * streamDescription->mChannelsPerFrame;
    // Always should be set to 1
    streamDescription->mFramesPerPacket = 1;
    // Always set to 0, just to be sure
    streamDescription->mReserved = 0;
     */
    
    /*
    
    // Set up input stream with above properties
    if((err = AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_StreamFormat,
                            kAudioUnitScope_Input, kInputBusNumber, streamDescription, sizeof(*streamDescription))) != noErr) {
        NSLog(@"Can't set property audio format: %d", err);
        return 1;
    }
     */

    /*
    // Ditto for the output stream, which we will be sending the processed audio to
    if((err = AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_StreamFormat,
                            kAudioUnitScope_Output, 1, &streamDescription, sizeof(streamDescription))) != noErr) {
        NSLog(@"Can't set output format: %d", err);
        return 1;
    }
     */
    
    return 0;
}


@implementation NWMicrophone {
    __weak id<AVCaptureAudioDataOutputSampleBufferDelegate> _delegate;
    __weak dispatch_queue_t _dispatchQueue;
    
    AudioUnit *_audioUnit;
    AudioStreamBasicDescription _asbd;
    CMFormatDescriptionRef format;
    
    BOOL _configured;
}

- (AudioUnit*)audioUnit {
    return _audioUnit;
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
    if (!_configured) {
        _audioUnit = malloc(sizeof(AudioUnit));
        NSError *error;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (![[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        }
        if (error) return NO;
        Float32 bufferSizeInSec = 1024.0f / 44100.0f;
        [[AVAudioSession sharedInstance] setPreferredSampleRate:bufferSizeInSec error:&error];
        if (error) return NO;
        [[AVAudioSession sharedInstance] setPreferredSampleRate:44100.0 error:&error];
        if (error) return NO;
        if (initAudioStreams(_audioUnit, self, &_asbd) != 0) return NO;
        NSLog(@"init finished");
        _configured = YES;
    }
    OSStatus err;
    if((err = AudioUnitInitialize(*_audioUnit)) != noErr) {
        NSLog(@"Initialize error: %d", err);
        return NO;
    }
    
    if((err = AudioOutputUnitStart(*_audioUnit)) != noErr) {
        NSLog(@"Start error: %d", err);
        return NO;
    }
    return YES;
}

- (void)stop {
    if(AudioOutputUnitStop(*_audioUnit) != noErr) {
        return;
    }
    
    if(AudioUnitUninitialize(*_audioUnit) != noErr) {
        return;
    }
    
    free(_audioUnit);
    _audioUnit = NULL;
}

- (OSStatus)receivedAudioBuffers:(AudioBufferList *)buffers numFrames:(UInt32)numFrames time:(CMTime)time {
    OSStatus result = 0;

    CMSampleBufferRef sampleBuffer = NULL;
    CMSampleTimingInfo timing = { CMTimeMake(numFrames, _asbd.mSampleRate), time, kCMTimeInvalid };
    
    if (!format) {
        result = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &_asbd, 0, NULL, 0, NULL, NULL, &format);
    }
    
    if (!buffers->mNumberBuffers) {
        return 666;
    }
    AudioBuffer *buffer = buffers->mBuffers;
    SInt16 *shorts = (SInt16*) malloc(buffer->mDataByteSize);
    //NSLog(@"buffers: %d %d -- %d %d %d %d", buffers->mNumberBuffers, buffer->mDataByteSize, shorts[0], shorts[1], shorts[2], shorts[3]);
    memcpy(shorts, buffer->mData, buffer->mDataByteSize);
    CMBlockBufferRef blockBuffer;
    CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                     shorts,
                                     buffer->mDataByteSize,
                                     kCFAllocatorMalloc,
                                     NULL, 0, buffer->mDataByteSize,
                                     0, &blockBuffer);
    
    result = CMSampleBufferCreate(kCFAllocatorDefault,blockBuffer,true,NULL,NULL,format, numFrames, 1, &timing, 0, NULL, &sampleBuffer);
    
    dispatch_async(_dispatchQueue, ^{
        [_delegate captureOutput:self didOutputSampleBuffer:sampleBuffer fromConnection:nil];
        CFRelease(blockBuffer);
        CFRelease(sampleBuffer);
    });
    return result;
}


@end
