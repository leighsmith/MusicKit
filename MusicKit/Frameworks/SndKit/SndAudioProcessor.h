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
    @discussion
    @param (SndAudioBuffer*) inB
    @param (SndAudioBuffer*) outB
    @result self.
*/
- processReplacingInputBuffer: (SndAudioBuffer*) inB 
                 outputBuffer: (SndAudioBuffer*) outB;

@end

#endif
