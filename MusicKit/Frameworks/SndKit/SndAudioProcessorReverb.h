////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorReverb.h
//  SndKit
//
//  Created by skot on Wed Mar 28 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
//  FreeVerb-based
//  FreeVerb originally written by Jezar at Dreampoint, June 2000
//  http://www.dreampoint.co.uk
//
//  TODO: make the ObjC to C++ bridge unnecessary!!
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/SndAudioBuffer.h>
#import <SndKit/SndAudioProcessor.h>

enum {
  rvrbRoomSize  = 0,
  rvrbDamp      = 1,
  rvrbWet       = 2,
  rvrbDry       = 3,
  rvrbWidth     = 4,
  rvrbMode      = 5, 
  rvrbNumParams = 6
};

@interface SndAudioProcessorReverb : SndAudioProcessor {
  void* cppFreeReverbObj; // stores c++ object pointer for the FreeVerb model
}

+ reverb;
- init;
- processReplacingInputBuffer: (SndAudioBuffer*) inB 
                 outputBuffer: (SndAudioBuffer*) outB;

- (int) paramCount;
- (float) paramValue: (int) index;
- (NSString*) paramName: (int) index;
- setParam: (int) index toValue: (float) v;

                 
@end
