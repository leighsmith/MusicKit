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

#ifndef __SNDAUDIOPROCESSORCHAIN_H__
#define __SNDAUDIOPROCESSORCHAIN_H__

#import <Foundation/Foundation.h>

@class SndAudioBuffer;
@class SndAudioProcessor;
@class SndAudioFader;

/*!
    @class
    @abstract 
    @discussion To come
    @var
    @var
    @var
*/
@interface SndAudioProcessorChain : NSObject {
    NSMutableArray    *audioProcessorArray;
    BOOL               bBypass;
    SndAudioBuffer    *tempBuffer;
    SndAudioFader     *postFader;
    double             nowTime;
}

/*!
    @method audioProcessorChain
    @abstract Factory method
    @discussion
    @result
*/
+ audioProcessorChain;

/*!
    @method init
    @abstract Initializer
    @discussion
    @result self
*/
- init;

/*!
    @method dealloc
    @abstract Destructor
    @discussion
*/
- (void) dealloc;

/*!
    @method bypassProcessors:
    @abstract
    @discussion
    @param (BOOL) b
    @result self.
*/
- bypassProcessors: (BOOL) b; 

/*!
    @method addAudioProcessor:
    @abstract
    @discussion
    @param (SndAudioProcessor*) proc
    @result
*/
- addAudioProcessor: (SndAudioProcessor*) proc;

/*!
    @method removeAudioProcessor:
    @abstract
    @discussion
    @param (SndAudioProcessor*) proc
    @result self
*/
- removeAudioProcessor: (SndAudioProcessor*) proc;

/*!
    @method processorAtIndex:
    @abstract
    @discussion
    @param (int) index
    @result Reference to an SndAudioProcessor
*/
- (SndAudioProcessor*) processorAtIndex: (int) index;

/*!
    @method removeAllProcessors
    @abstract
    @discussion
    @result self
*/
- removeAllProcessors;

/*!
    @method processBuffer:forTime:
    @abstract
    @discussion The t parameter tells the processor chain at what time
                the buffer is destined to start to be played. This
                matches up with the time the SndStreamClients were given
                for generating this same buffer.
    @param (SndAudioBuffer*) buff
    @param (double) t
    @result self.
*/
- processBuffer: (SndAudioBuffer*) buff forTime:(double) t;

/*!
    @method processorCount
    @abstract
    @discussion
    @result (int) number of processors in the processor chain.
*/
- (int) processorCount; 

/*!
    @method processorArray
    @abstract Accessor to the internal processor array
    @discussion provided for speed
    @result NSArray containing the processors (in order)
*/
- (NSArray*) processorArray;

/*!
    @method isBypassingFX
    @abstract
    @discussion
    @result Boolean indicating whether FX are being bypassed
*/
- (BOOL) isBypassingFX;

/*!
    @method setBypass:
    @abstract
    @discussion
    @param (BOOL) b
*/
- (void) setBypass: (BOOL) b;

/*!
    @method postFader
    @abstract
    @discussion
    @result id of the postFader object at the end of the chain
*/
- (SndAudioFader *) postFader;

/*!
    @method nowTime
    @abstract
    @discussion
    @result double indicating the start time of the buffer being
            processed.
*/
- (double) nowTime;

@end

#endif
