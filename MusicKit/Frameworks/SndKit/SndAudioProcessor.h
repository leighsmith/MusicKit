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
@class SndAudioProcessorChain;

/*!
    @class
    @abstract 
    @discussion To come
    @var
    @var
    @var
*/
@interface SndAudioProcessor : NSObject {
    int   numParams;
    SndAudioProcessorChain *audioProcessorChain;
}

/*!
    @method audioProcessor
    @abstract Factory method
    @discussion
    @result
*/
+ audioProcessor;

/*!
    @method init
    @abstract Initialization method
    @discussion
    @result self.
*/
- init;

/*!
    @method reset
    @abstract
    @discussion
    @result self.
*/
- reset;

/*!
    @method paramCount
    @abstract
    @discussion
    @result (int) number of parameters
*/
- (int) paramCount;

/*!
    @method paramValue:
    @abstract
    @discussion
    @param (int) index
    @result (float) parameter value
*/
- (float) paramValue: (int) index;

/*!
    @method paramName:
    @abstract
    @discussion
    @param (int) index
    @result NSString with parameter name
*/
- (NSString*) paramName: (int) index;

/*!
    @method setParam:toValue:
    @abstract
    @discussion
    @param (int) index
    @param (float) v
    @result self.
*/
- setParam: (int) index toValue: (float) v;

/*!
    @method processReplacingInputBuffer:outputBuffer:
    @abstract
    @discussion The returned BOOL indicates whether the output is
            held in outB (TRUE), or inB (false). Means that processors
            that decide not to touch their data at all don't need to
            spend time copying between buffers
    @param (SndAudioBuffer*) inB
    @param (SndAudioBuffer*) outB
    @result BOOL
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB
                        outputBuffer: (SndAudioBuffer*) outB;

/*!
    @method setAudioProcessorChain:
    @abstract
    @discussion (Internal SndKit use only) Individual processors may want
                to query their enclosing processor chain, for example to
                get the time at the start of the buffer (nowTime). This
                method gets called when a processor gets added to the chain,
                with the id of the chain.
    @param (SndAudioProcessorChain*) inChain
    @result void.
*/
- (void) setAudioProcessorChain:(SndAudioProcessorChain*)inChain;

/*!
    @method audioProcessorChain
    @abstract Returns the SndAudioProcessorChain to which the processor is
              attached
    @discussion
    @result SndAudioProcessorChain*
*/
- (SndAudioProcessorChain*) audioProcessorChain;


@end

#endif
