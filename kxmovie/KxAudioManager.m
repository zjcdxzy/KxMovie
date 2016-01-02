//
//  KxAudioManager.m
//  kxmovie
//
//  Created by Kolyvan on 23.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

// ios-only and output-only version of Novocaine https://github.com/alexbw/novocaine
// Copyright (c) 2012 Alex Wiltschko


#import "KxAudioManagerImpl.h"
#import "KxAudioQueueImpl.h"

@implementation KxAudioManager

+ (id<KxAudioManager>) audioManager
{
//    static KxAudioManagerImpl *audioManager = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        audioManager = [[KxAudioManagerImpl alloc] init];
//    });
//    return audioManager;
    
    static KxAudioQueueImpl *audioManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioManager = [[KxAudioQueueImpl alloc] init];
    });
    return audioManager;
}

@end

