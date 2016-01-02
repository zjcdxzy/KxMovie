//
//  KxAudioQueueImpl.m
//  kxmovie
//
//  Created by zjc on 15/12/31.
//
//

// 使用AudioQueue 代替 AudioUnit 实现音频的播放

#import "KxAudioQueueImpl.h"
#import "KxAudioSession.h"

#define kxAudioQueueNumberBuffers (3)

@interface KxAudioQueueImpl () {
    AudioQueueRef _audioQueueRef;
    AudioQueueBufferRef _audioQueueBufferRefArray[kxAudioQueueNumberBuffers];
    BOOL _isPaused;
    BOOL _isStopped;
    
    volatile BOOL _isAborted;
    NSLock *_lock;
}



@end

@implementation KxAudioQueueImpl
@synthesize outputBlock = _outputBlock; // 关键字synthesize的使用

- (instancetype) init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Audio protocol Method 

- (BOOL) activateAudioSession {
    if (!_activated) {
        if (!_initialized) {
            [[KxAudioSession sharedInstance] setupAudioSession];
            if ([[KxAudioSession sharedInstance] setActive:YES]) {
                NSLog(@"AudioSession Active failed");
                 return NO;
            }
            _initialized = YES;
        }
        
        if ( ![self setupAudio]) {
            NSLog(@"Audio create failed");
            return NO;
        }
        _activated = YES;
    }
    return _activated;
}
    
- (void) deactivateAudioSession {
    
}

- (BOOL) play {
    if (!_audioQueueRef)
        return NO;
    
    @synchronized(_lock) {
        _isPaused = NO;
        NSError *error = nil;
        if (NO == [[AVAudioSession sharedInstance] setActive:YES error:&error]) {
            NSLog(@"AudioQueue: AVAudioSession.setActive(YES) failed: %@\n", error ? [error localizedDescription] : @"nil");
        }
        
        OSStatus status = AudioQueueStart(_audioQueueRef, NULL);
        if (status != noErr)
            NSLog(@"AudioQueue: AudioQueueStart failed (%d)\n", (int)status);
    }
    
    return YES;
}

- (void) pause{
    if (!_audioQueueRef)
        return;
    
    @synchronized(_lock) {
        if (_isStopped)
            return;
        
        _isPaused = YES;
        OSStatus status = AudioQueuePause(_audioQueueRef);
        if (status != noErr)
            NSLog(@"AudioQueue: AudioQueuePause failed (%d)\n", (int)status);
    }
}

- (void)flush
{
    if (!_audioQueueRef)
        return;
    
    @synchronized(_lock) {
        if (_isStopped)
            return;
        
        AudioQueueFlush(_audioQueueRef);
    }
}

- (void)close
{
    [self stop];
    _audioQueueRef = nil;
}

- (void)stop
{
    if (!_audioQueueRef)
        return;
    
    @synchronized(_lock) {
        if (_isStopped)
            return;
        
        _isStopped = YES;
    }
    
    // do not lock AudioQueueStop, or may be run into deadlock
    AudioQueueStop(_audioQueueRef, true);
    AudioQueueDispose(_audioQueueRef, true);
}

#pragma mark -private 

- (BOOL) setupAudio {
    //  AudioStreamBasicDescription 函数的构造
    
    AudioStreamBasicDescription desc;
    /*
     mSampleRate = 44100
     mFormatID = 1819304813
     mFormatFlags = 12
     mBytesPerPacket = 4
     mFramesPerPacket = 1
     mBytesPerFrame = 4
     mChannelsPerFrame = 2
     mBitsPerChannel = 16
     mReserved = 0
     
     mSampleRate = 44100
     mFormatID = 1819304813
     mFormatFlags = 16
     mBytesPerPacket = 4
     mFramesPerPacket = 1
     mBytesPerFrame = 4
     mChannelsPerFrame = 2
     mBitsPerChannel = 16
     mReserved = 0
     
     */
    desc.mSampleRate = [AVAudioSession sharedInstance].sampleRate;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFormatFlags = 12;
    desc.mChannelsPerFrame = 2;
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = 16;
    desc.mBytesPerFrame = desc.mBitsPerChannel * desc.mChannelsPerFrame / 8;
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    
    _outputFormat = desc;
    _numOutputChannels = desc.mChannelsPerFrame;
    _numBytesPerSample = desc.mBitsPerChannel / 8;
    
    AudioQueueRef audioQueueRef;
    OSStatus status = AudioQueueNewOutput(&desc,
                                          IJKSDLAudioQueueOuptutCallback,
                                          (__bridge void *) self,
                                          NULL,
                                          kCFRunLoopCommonModes,
                                          0,
                                          &audioQueueRef);
    
    if (status != noErr) {
        
//        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
//                                             code:status
//                                         userInfo:nil];
//        NSLog(@"Error: %@", [error description]);
        
        NSLog(@"AudioQueue: AudioQueueNewOutput failed (%d)\n", (int)status);
        return NO;
    }
    
    // why ?
    _audioQueueRef = audioQueueRef;
    UInt32 propValue = 1;
    AudioQueueSetProperty(_audioQueueRef, kAudioQueueProperty_EnableTimePitch, &propValue, sizeof(propValue));
    propValue = 1;
    AudioQueueSetProperty(_audioQueueRef, kAudioQueueProperty_TimePitchBypass, &propValue, sizeof(propValue));
    propValue = kAudioQueueTimePitchAlgorithm_Spectral;
    AudioQueueSetProperty(_audioQueueRef, kAudioQueueProperty_TimePitchAlgorithm, &propValue, sizeof(propValue));
    
    status = AudioQueueStart(_audioQueueRef, NULL);
    if (status != noErr) {
        NSLog(@"AudioQueue: AudioQueueStart failed (%d)\n", (int)status);
        return nil;
    }
    
    UInt32 size = 8192;
    for (int i = 0;i < kxAudioQueueNumberBuffers; i++)
    {
        AudioQueueAllocateBuffer(audioQueueRef, size, &_audioQueueBufferRefArray[i]);
        _audioQueueBufferRefArray[i]->mAudioDataByteSize = size;
        AudioQueueEnqueueBuffer(audioQueueRef, _audioQueueBufferRefArray[i], 0, NULL);
    }
    
    _isStopped = NO;
    _lock = [[NSLock alloc] init];
    
    
    return YES;
}


static void IJKSDLAudioQueueOuptutCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    /// __bridge KxAudioManagerImpl *
     KxAudioQueueImpl* queueImpl = (__bridge KxAudioQueueImpl *) inUserData;
    [queueImpl renderAudioQueueRef:inAQ queueBufferRef:inBuffer];
}


- (void) renderAudioQueueRef:(AudioQueueRef) inAQ
               queueBufferRef: (AudioQueueBufferRef) inBuffer {
    
    @autoreleasepool {
        if (!self) {
            // do nothing;
        } else if (_isPaused || _isStopped) {
            memset(inBuffer->mAudioData, 0, inBuffer->mAudioDataByteSize);
        } else {
            if (_outputBlock) {
//                _outputBlock(inBuffer->mAudioData, inBuffer->mAudioDataByteSize / sizeof(inBuffer->mAudioData) / 2,2);
                _outputBlock(inBuffer->mAudioData, inBuffer->mAudioDataByteSize/(2 * sizeof(inBuffer->mAudioData)) ,2);
            }
        }
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}


@end
