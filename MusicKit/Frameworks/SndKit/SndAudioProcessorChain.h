////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorChain.h
//  SndKit
//
//  Created by skot on Tues Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@class SndAudioBuffer;
@class SndAudioProcessor;

@interface SndAudioProcessorChain : NSObject {
    NSMutableArray    *audioProcessorArray;
    BOOL               bBypass;
    SndAudioBuffer    *tempBuffer; 
}

+ audioProcessorChain;
- init;
- (void) dealloc;
- bypassProcessors: (BOOL) b; 
- addAudioProcessor: (SndAudioProcessor*) proc;
- removeAudioProcessor: (SndAudioProcessor*) proc;
- (SndAudioProcessor*) processorAtIndex: (int) index;
- removeAllProcessors;
- processBuffer: (SndAudioBuffer*) buff;
- (int) processorCount; 
- (NSArray*) processorArray;

@end
