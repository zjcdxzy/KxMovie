//
//  KxAudioSession.h
//  kxmovie
//
//  Created by zjc on 16/1/2.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KxAudioSession : NSObject

+ (KxAudioSession *)sharedInstance;
- (void)setupAudioSession;
- (BOOL)setActive:(BOOL)active;

@end