////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorReverb.m
//  SndKit
//
//  Created by SKoT McDonald on Wed Mar 28 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
//  Based on / uses FreeVerb
//  FreeVerb originally written by Jezar at Dreampoint, June 2000
//  http://www.dreampoint.co.uk
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessorReverb.h"
#import "reverbBridge.h"

@implementation SndAudioProcessorReverb

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  [super init];
  numParams = rvrbNumParams;
  cppFreeReverbObj = reverbCreate();
  NSLog(@"[Freeverb] cpp object created!");
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  reverbDestroy(cppFreeReverbObj);
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer: (SndAudioBuffer*) inB 
//                outputBuffer: (SndAudioBuffer*) outB 
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                        outputBuffer: (SndAudioBuffer*) outB
{
  if ([outB lengthInSamples] == [inB lengthInSamples] &&
      [outB channelCount]    == [inB channelCount]    &&
      [outB dataFormat]      == [inB dataFormat]      &&
      [inB dataFormat]       == SND_FORMAT_FLOAT      &&
      [inB channelCount]     == 2) {
      
      float *inD  = (float*) [inB  data];
      float *outD = (float*) [outB data];
      long   len  = [inB  lengthInSamples];

      reverbProcessReplacing(cppFreeReverbObj,inD,inD+1,outD,outD+1,len,2);
  }
  else
    printf("SndAudioProcessorReverb::processreplacing: ERR: Buffers have different formats\n");
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (int) index
{
  float r;
  switch (index) {
  case rvrbRoomSize: r = getRoomSize(cppFreeReverbObj); break;
  case rvrbDamp:     r = getDamp(cppFreeReverbObj);     break;
  case rvrbWet:      r = getWet(cppFreeReverbObj);      break;
  case rvrbDry:      r = getDry(cppFreeReverbObj);      break;
  case rvrbWidth:    r = getWidth(cppFreeReverbObj);    break;
  case rvrbMode:     r = getMode(cppFreeReverbObj);     break; 
  default:           r = 0.0f;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (int) index
{
  NSString *r = nil;
  switch (index) {
  case rvrbRoomSize: r = @"RoomSize"; break;
  case rvrbDamp:     r = @"Damp";     break;
  case rvrbWet:      r = @"Wet";      break;
  case rvrbDry:      r = @"Dry";      break;
  case rvrbWidth:    r = @"Width";    break;
  case rvrbMode:     r = @"Mode";     break; 
  default:           r = nil;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// setParam:toValue:
//
// TODO: it's a bit screwy setting a long length to a float value, but for a VST
// look-and-feel, all params are set by floats, and return as floats. Rethink. 
////////////////////////////////////////////////////////////////////////////////

- setParam: (int) index toValue: (float) v;
{
  if (v < 0.0f || v > 1.0f) {
      NSLog(@"SndAudioProcessorReverb::setParam: ERR: value must be in [0,1]");
  }
  else {
    switch (index) {
    case rvrbRoomSize: setRoomSize(cppFreeReverbObj,v); break;
    case rvrbDamp:     setDamp(cppFreeReverbObj,v);     break;
    case rvrbWet:      setWet(cppFreeReverbObj,v);      break;
    case rvrbDry:      setDry(cppFreeReverbObj,v);      break;
    case rvrbWidth:    setWidth(cppFreeReverbObj,v);    break;
    case rvrbMode:     setMode(cppFreeReverbObj,v);     break; 
    }
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
