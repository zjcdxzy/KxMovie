//
//  KxAudioSession.m
//  kxmovie
//
//  Created by zjc on 16/1/2.
//
//

#import "KxAudioSession.h"

@implementation KxAudioSession{
    BOOL _audioSessionInitialized;
}

+ (KxAudioSession *)sharedInstance
{
    static KxAudioSession *xAudioSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xAudioSession = [[KxAudioSession alloc] init];
    });
    return xAudioSession;
}

- (void)setupAudioSession
{
    if (!_audioSessionInitialized) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleInterruption:)
                                                     name: AVAudioSessionInterruptionNotification
                                                   object: [AVAudioSession sharedInstance]];
        _audioSessionInitialized = YES;
    }
    
    /* Set audio session to mediaplayback */
    NSError *error = nil;
    if (NO == [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error]) {
        NSLog(@"KxAudioSession: AVAudioSession.setCategory() failed: %@\n", error ? [error localizedDescription] : @"nil");
        return;
    }
    
    error = nil;
    if (NO == [[AVAudioSession sharedInstance] setActive:YES error:&error]) {
        NSLog(@"KxAudioSession: AVAudioSession.setActive(YES) failed: %@\n", error ? [error localizedDescription] : @"nil");
        return;
    }
    
    return ;
}

//  YES if the session’s active state was changed successfully, or NO if it was not.
- (BOOL)setActive:(BOOL)active
{
    if (active != NO) {
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    } else {
        @try {
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
        } @catch (NSException *exception) {
            NSLog(@"failed to inactive AVAudioSession\n");
        }
    }
}

- (void)handleInterruption:(NSNotification *)notification
{
    int reason = [[[notification userInfo] valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    switch (reason) {
        case AVAudioSessionInterruptionTypeBegan: {
            NSLog(@"AVAudioSessionInterruptionTypeBegan\n");
            [self setActive:NO];
            break;
        }
        case AVAudioSessionInterruptionTypeEnded: {
            NSLog(@"AVAudioSessionInterruptionTypeEnded\n");
            [self setActive:YES];
            break;
        }
    }
}

@end
