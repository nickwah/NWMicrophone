//
//  NWMicrophone.h
//  NWMicrophone
//
//  Created by Nicholas White on 10/30/15.
//  Copyright © 2015 Nicholas White. All rights reserved.
//

#import <Foundation/Foundation.h>
@import VideoToolbox;
@import AVFoundation;

@interface NWMicrophone : AVCaptureOutput

@property (nonatomic, readonly) id<AVCaptureAudioDataOutputSampleBufferDelegate>sampleBufferDelegate;
@property (nonatomic) BOOL echoCancellation;

- (void)setSampleBufferDelegate:(id<AVCaptureAudioDataOutputSampleBufferDelegate>)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue;

- (BOOL) start;
- (void) stop;

@end
