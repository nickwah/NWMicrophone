//
//  ViewController.m
//  NWMicrophone
//
//  Created by Nicholas White on 10/30/15.
//  Copyright © 2015 Nicholas White. All rights reserved.
//

#import "ViewController.h"
#import "NWMicrophone.h"
#import "Novocaine.h"

@interface ViewController () <AVCaptureAudioDataOutputSampleBufferDelegate>
@end

@implementation ViewController {
    NWMicrophone *_mic;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVideoChat error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    //[[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    Novocaine *audioManager = [Novocaine audioManager];
    /*
    __block float magnitude = 0.0;
    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels, CMTime pts)
     {
         NSLog(@"Input block: %.3f %.3f %.3f %.3f ", data[0], data[1], data[2], data[3]);
         vDSP_rmsqv(data, 1, &magnitude, numFrames*numChannels);
     }];
    */
    /*
    __block float frequency = 100.0;
    __block float phase = 0.0;
    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {

         printf("Magnitude: %f\n", magnitude);
         float samplingRate = audioManager.samplingRate;
         for (int i=0; i < numFrames; ++i)
         {
             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
             {
                 float theta = phase * M_PI * 2;
                 data[i*numChannels + iChannel] = magnitude*sin(theta);
             }
             phase += 1.0 / (samplingRate / (frequency));
             if (phase > 1.0) phase = -1;
         }
     }];
     */
    /*
    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         for (int i = 0; i < numFrames; i++) {
             data[i] = i / (float)numFrames - 0.5;
         }
     }];
    [audioManager play];
    */
    _mic = [[NWMicrophone alloc] init];
    [_mic setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_mic start];

}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    NSUInteger channelIndex = 0;
    int srcNumSamples = (int)CMSampleBufferGetNumSamples(sampleBuffer);
    
    CMBlockBufferRef audioBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t audioBlockBufferOffset = (channelIndex * srcNumSamples * sizeof(float));
    size_t lengthAtOffset = 0;
    size_t totalLength = 0;
    float *samples = NULL;
    if (audioBlockBuffer) {
        CMBlockBufferGetDataPointer(audioBlockBuffer, audioBlockBufferOffset, &lengthAtOffset, &totalLength, (char **)(&samples));

        NSLog(@"Received sample buffer with %d samples: %.3f %.3f %.3f %.3f", srcNumSamples, samples[0], samples[1], samples[2], samples[3]);
    } else {
        NSLog(@"Received null audio buffer. num samples = %d", srcNumSamples);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
