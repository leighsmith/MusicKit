////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
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
  @class SndAudioProcessorChain
  @abstract Holds a collection of serially "chained" SndAudioProcessors with a final SndAudioFader at the end of the chain.
  @discussion To come
*/
@interface SndAudioProcessorChain : NSObject {
/*! @var   audioProcessorArray */
    NSMutableArray *audioProcessorArray;
/*! @var   bBypass */
    BOOL   bBypass;
/*! @var   tempBuffer */
    SndAudioBuffer *tempBuffer; 
/*! @var   postFader */
    SndAudioFader *postFader;
/*! @var   nowTime */
    double nowTime;
}

/*!
    @method     audioProcessorChain
    @abstract   Factory method
    @result     A freshly initialized, autoreleased SndAudioProcessorChain.
*/
+ audioProcessorChain;
/*!
    @method     init
    @abstract   Initializes SndAudioProcessorChain instance.
    @discussion Creates an active SndAudioFader instance as the post effects fader.
    @result     Self
*/
- init;
/*!
    @method     dealloc
    @abstract   Destructor
*/
- (void) dealloc;
/*!
    @method     bypassProcessors:
    @abstract   Sets the internal FX bypass flag
    @param      b Bypass flag - TRUE if bypass is to be enabled
    @result     self.
*/
- bypassProcessors: (BOOL) b; 
/*!
    @method     addAudioProcessor:
    @abstract   Adds an SndAudioProcessor to the FX chain
    @discussion
    @param      proc The SndAudioProcessor to be added to the FX chain
    @result     Self
*/
- addAudioProcessor: (SndAudioProcessor*) proc;
/*!
    @method     removeAudioProcessor:
    @abstract   Removes an SndAudioProcesor from the FX chain
    @discussion
    @param      proc SndAudioProcessor to be removed from the FX chain
    @result     self
*/
- removeAudioProcessor: (SndAudioProcessor*) proc;
/*!
    @method     processorAtIndex:
    @abstract   Get the processor at a certain index
    @discussion
    @param      index
    @result     Reference to an SndAudioProcessor
*/
- (SndAudioProcessor*) processorAtIndex: (int) index;
/*!
    @method     removeAllProcessors
    @abstract   Removes all processors from the processor chain.
    @result     self
*/
- removeAllProcessors;
/*!
    @method     processBuffer:
    @abstract
    @discussion The t parameter tells the processor chain at what time
                the buffer is destined to start to be played. This
                matches up with the time the SndStreamClients were given
                for generating this same buffer.
    @param      buff
    @result     self.
*/
- processBuffer: (SndAudioBuffer*) buff forTime:(double) t;
/*!
    @method     processorCount
    @abstract
    @discussion
    @result     number of processors in the processor chain.
*/
- (int) processorCount; 
/*!
    @method     processorArray
    @abstract   Accessor to the internal processor array
    @discussion Provided for speed
    @result     NSArray containing the processors (in order)
*/
- (NSArray*) processorArray;
/*!
    @method     isBypassingFX
    @abstract
    @discussion
    @result     TRUE is FX chain is being bypassed
*/
- (BOOL) isBypassingFX;
/*!
    @method     setBypass:
    @abstract
    @discussion
    @param      b Bypass flag - TRUE to enable bypass 
*/
- (void) setBypass: (BOOL) b;
/*!
    @method     postFader
    @abstract   Returns the SndAudioFader which is the last effect at the end of this SndAudioProcessorChain instance.
    @discussion
    @result     id of the postFader object at the end of the chain
*/
- (SndAudioFader *) postFader;
/*!
    @method     nowTime
    @abstract
    @discussion
    @result     double indicating the start time of the buffer being
                processed.
*/
- (double) nowTime;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
