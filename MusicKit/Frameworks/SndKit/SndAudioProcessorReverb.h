////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorReverb.h
//  SndKit
//
//  Created by skot on Wed Mar 28 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
//  FreeVerb-based
//  FreeVerb originally written by Jezar at Dreampoint, June 2000
//  http://www.dreampoint.co.uk
//
//  TODO: make the ObjC to C++ bridge unnecessary!!
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORREVERB_H__
#define __SNDKIT_SNDAUDIOPROCESSORREVERB_H__

#import <Foundation/Foundation.h>
#import "SndAudioBuffer.h"
#import "SndAudioProcessor.h"

/*!
    @enum     SndReverbParam
    @constant rvrbRoomSize  
    @constant rvrbDamp      
    @constant rvrbWet       
    @constant rvrbDry       
    @constant rvrbWidth     
    @constant rvrbMode       
    @constant rvrbNumParams 
*/
enum {
  rvrbRoomSize  = 0,
  rvrbDamp      = 1,
  rvrbWet       = 2,
  rvrbDry       = 3,
  rvrbWidth     = 4,
  rvrbMode      = 5, 
  rvrbNumParams = 6
};

////////////////////////////////////////////////////////////////////////////////

/*! 
    @class      SndAudioProcessorReverb
    @abstract   A reverb processor
    @discussion To come.
*/
@interface SndAudioProcessorReverb : SndAudioProcessor {
@private  
/*! @var cppFreeReverbObj C++ object pointer for the FreeVerb model */
  void* cppFreeReverbObj; 
}

/*!
  @method init
  @result self
  @discussion Initializes the CPP reverb model.
*/
- init;
/*!
  @method dealloc
  @discussion Destructor.
*/
- (void) dealloc;
/*!
  @method processReplacingInputBuffer:outputBuffer:
  @param  inB  inputBuffer
  @param  outB outputBuffer
  @result self 
  @discussion Main FX processing function - automatically called by the host SndAudioProcessorChain.
              See discussion in SndAudioProcessor.
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                 outputBuffer: (SndAudioBuffer*) outB;
/*!
  @method paramValue:
  @param  index Parameter index
  @result A parameter value in the range [0..1] 
  @discussion See discussion in SndAudioProcessor 
*/
- (float) paramValue: (const int) index;
/*!
  @method paramName:
  @param  index Parameter index
  @result An NSString containing the name of the parameter referred to by index. 
  @discussion See discussion in SndAudioProcessor 
*/
- (NSString*) paramName: (const int) index;
/*!
  @method setParam:toValue:
  @param  index Parameter index
  @param  v     New value for the indexed parameter, in the range [0..1]
  @result self
  @discussion  See discussion in SndAudioProcessor
*/
- setParam: (const int) index toValue: (const float) v;

@end

#endif
