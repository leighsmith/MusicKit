////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessor.h
//  SndKit
//
//  Created by skot on Tues Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
//  Heavily inspired by Steinberg's VST effects plugins for the moment
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_AUDIO_PROCESSOR_H__
#define __SND_AUDIO_PROCESSOR_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;

@interface SndAudioProcessor : NSObject {
    int   numParams;
}

+ audioProcessor;

- init;
- reset;

- (int) paramCount;
- (float) paramValue: (int) index;
- (NSString*) paramName: (int) index;
- setParam: (int) index toValue: (float) v;

- processReplacingInputBuffer: (SndAudioBuffer*) inB 
                 outputBuffer: (SndAudioBuffer*) outB;

@end

#endif
