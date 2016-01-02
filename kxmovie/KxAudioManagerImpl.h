//
//  KxAudioManagerImpl.h
//  kxmovie
//
//  Created by zjc on 15/12/31.
//
//

#import <Foundation/Foundation.h>
#import "KxAudioManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>

// 继承NSObject 和继承KxAudioManager 之间的区别

@interface KxAudioManagerImpl : NSObject <KxAudioManager> {
    
    BOOL                        _initialized;
    BOOL                        _activated;
    float                       *_outData;
    AudioUnit                   _audioUnit;
    AudioStreamBasicDescription _outputFormat;
}

@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readwrite) Float32           outputVolume;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;

@property (readwrite, copy) KxAudioManagerOutputBlock outputBlock;
@property (readwrite) BOOL playAfterSessionEndInterruption;

- (BOOL) activateAudioSession;
- (void) deactivateAudioSession;
- (BOOL) play;
- (void) pause;

- (BOOL) checkAudioRoute;
- (BOOL) setupAudio;
- (BOOL) checkSessionProperties;
- (BOOL) renderFrames: (UInt32) numFrames
               ioData: (AudioBufferList *) ioData;

@end