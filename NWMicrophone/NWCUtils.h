//
//  NWCUtils.h
//  NWMicrophone
//
//  Created by Nicholas White on 10/31/15.
//  Copyright © 2015 Nicholas White. All rights reserved.
//

#ifndef NWCUtils_h
#define NWCUtils_h

void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    
    char str[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    
    exit(1);
}

NSString* descriptionForStandardFlags(UInt32 mFormatFlags)
{
    NSMutableString *description = [NSMutableString new];
    
    if (mFormatFlags & kAudioFormatFlagIsFloat)
    { [description appendString:@"kAudioFormatFlagIsFloat \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsBigEndian)
    { [description appendString:@"kAudioFormatFlagIsBigEndian \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsSignedInteger)
    { [description appendString:@"kAudioFormatFlagIsSignedInteger \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsPacked)
    { [description appendString:@"kAudioFormatFlagIsPacked \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsAlignedHigh)
    { [description appendString:@"kAudioFormatFlagIsAlignedHigh \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsNonInterleaved)
    { [description appendString:@"kAudioFormatFlagIsNonInterleaved \n"]; }
    if (mFormatFlags & kAudioFormatFlagIsNonMixable)
    { [description appendString:@"kAudioFormatFlagIsNonMixable \n"]; }
    if (mFormatFlags & kAudioFormatFlagsAreAllClear)
    { [description appendString:@"kAudioFormatFlagsAreAllClear \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsFloat)
    { [description appendString:@"kLinearPCMFormatFlagIsFloat \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsBigEndian)
    { [description appendString:@"kLinearPCMFormatFlagIsBigEndian \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsSignedInteger)
    { [description appendString:@"kLinearPCMFormatFlagIsSignedInteger \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsPacked)
    { [description appendString:@"kLinearPCMFormatFlagIsPacked \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsAlignedHigh)
    { [description appendString:@"kLinearPCMFormatFlagIsAlignedHigh \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsNonInterleaved)
    { [description appendString:@"kLinearPCMFormatFlagIsNonInterleaved \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagIsNonMixable)
    { [description appendString:@"kLinearPCMFormatFlagIsNonMixable \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagsSampleFractionShift)
    { [description appendString:@"kLinearPCMFormatFlagsSampleFractionShift \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagsSampleFractionMask)
    { [description appendString:@"kLinearPCMFormatFlagsSampleFractionMask \n"]; }
    if (mFormatFlags & kLinearPCMFormatFlagsAreAllClear)
    { [description appendString:@"kLinearPCMFormatFlagsAreAllClear \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_16BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_16BitSourceData \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_20BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_20BitSourceData \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_24BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_24BitSourceData \n"]; }
    if (mFormatFlags & kAppleLosslessFormatFlag_32BitSourceData)
    { [description appendString:@"kAppleLosslessFormatFlag_32BitSourceData \n"]; }
    
    return [NSString stringWithString:description];
}

NSString* NSStringFromASBD(AudioStreamBasicDescription audioFormat)
{
    NSMutableString *description = [NSMutableString new];
    
    // From https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/ConstructingAudioUnitApps/ConstructingAudioUnitApps.html (Listing 2-8)
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (audioFormat.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    [description appendFormat:@"Sample Rate:         %10.0f \n",  audioFormat.mSampleRate];
    [description appendFormat:@"Format ID:           %10s \n",    formatIDString];
    [description appendFormat:@"Format Flags:        %10X \n",    (unsigned int)audioFormat.mFormatFlags];
    [description appendFormat:@"Bytes per Packet:    %10d \n",    (unsigned int)audioFormat.mBytesPerPacket];
    [description appendFormat:@"Frames per Packet:   %10d \n",    (unsigned int)audioFormat.mFramesPerPacket];
    [description appendFormat:@"Bytes per Frame:     %10d \n",    (unsigned int)audioFormat.mBytesPerFrame];
    [description appendFormat:@"Channels per Frame:  %10d \n",    (unsigned int)audioFormat.mChannelsPerFrame];
    [description appendFormat:@"Bits per Channel:    %10d \n",    (unsigned int)audioFormat.mBitsPerChannel];
    
    // Add flags (supposing standard flags).
    [description appendString:descriptionForStandardFlags(audioFormat.mFormatFlags)];
    
    return [NSString stringWithString:description];
}

#endif /* NWCUtils_h */
