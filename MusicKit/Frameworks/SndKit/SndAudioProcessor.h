////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessor.h
//  SndKit
//
//  Created by skot on Tues Mar 27 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
//  Heavily inspired by Steinberg's VST effects plugins for the moment
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SND_AUDIO_PROCESSOR_H__
#define __SND_AUDIO_PROCESSOR_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;
@class SndAudioProcessorChain;

/*! 
    @class      SndAudioProcessor
    @abstract   A VST-like audio FX processing module base class.
    @discussion To come
*/
@interface SndAudioProcessor : NSObject {
/*! @var  numParams Number of parameters in the audio processor */
    int   numParams;
/*! @var  audioProcessorChain The SndAudioProcessorChain hosting this processor */
    SndAudioProcessorChain *audioProcessorChain;
/*! @var  bActive */    
    BOOL  bActive;
}

/*!
    @method     audioProcessor
    @abstract   Factory method
    @discussion
    @result     Returns a freshly initialized, autoreleased SndAudioProcessor
*/
+ audioProcessor;

/*!
    @method     init
    @abstract   Initialization method
    @result     Self.
*/
- init;

/*!
    @method      reset
    @abstract    Message sent when host determines the SndAudioProcessor should reinitialize
                 its processing state. Eg, a delay processor would zero its z-buffers.
    @result      self
*/
- reset;

/*!
    @method     paramCount
    @abstract   Gets the number of parameters
    @result     number of parameters
*/
- (int) paramCount;

/*!
    @method     paramValue:
    @abstract   Gets the value of the indexed parameter. 
    @discussion Following the VST convention, this should be in the range [0,1]. No enforcement at the present time.
    @param      index Index of the parameter
    @result     parameter value
*/
- (float) paramValue: (int) index;

/*!
    @method   paramName:
    @abstract   Gets the name of indexed parameter.
    @param      index Parameter index
    @result     NSString with parameter name
*/
- (NSString*) paramName: (int) index;

/*!
    @method   setParam:toValue:
    @abstract   Sets the indexed parameter to the value v.
    @discussion By VST convention, the argument v should be in the range [0,1]. If the
                internal parameter has a different range, this should be mapped internally.
    @param      index Index of the parameter to be set 
    @param      v Value in the range [0,1]
    @result     Self.
*/
- setParam: (int) index toValue: (float) v;

/*!
    @method   processReplacingInputBuffer:outputBuffer:
    @abstract   process the inputBuffer, and replace the results in the output buffer
    @discussion Overide this method with your own FX processing routines.
                There is nothing to stop inB and outB referring to the same buffer -  
                be warned that replacing the output values in outB may change inB in 
                these cases.
    @param      inB The input buffer
    @param      outB The output buffer
    @result     BOOL indicates whether the output is held in outB (TRUE), or inB (false). 
                Means that processors that decide not to touch their data at all don't 
                need to spend time copying between buffers.
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;

/*!
    @method    setAudioProcessorChain:
    @abstract
    @discussion (Internal SndKit use only) Individual processors may want
                to query their enclosing processor chain, for example to
                get the time at the start of the buffer (nowTime). This
                method gets called when a processor gets added to the chain,
                with the id of the chain.
    @param  inChain
    @result void.
*/
- (void) setAudioProcessorChain:(SndAudioProcessorChain*)inChain;

/*!
    @method     audioProcessorChain
    @abstract   Returns the SndAudioProcessorChain to which the processor is
                attached
    @discussion
    @result     id of the SndAudioProcessorChain
*/
- (SndAudioProcessorChain*) audioProcessorChain;

/*!
    @method     isActive
    @abstract   Processor activity status query method
    @result     Returns TRUE if the processor is active, ie whether the host processor 
                chain should pass the audio stream through this processor.
*/
- (BOOL) isActive;

/*!
    @method     setActive
    @abstract   Sets the active status of the processor.
    @param      b TRUE if the processor is to be made active.
    @result     self
*/
- setActive: (BOOL) b;

@end

#endif
