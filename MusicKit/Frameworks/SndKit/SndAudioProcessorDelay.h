////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORDELAY_H__
#define __SNDKIT_SNDAUDIOPROCESSORDELAY_H__

#import <Foundation/Foundation.h>
#import "SndAudioProcessor.h"

/*!
  @enum SndDelayParam
  @abstract Parameter keys
  @constant dlyLength Length
  @constant dlyFeedback Feedback amount 
  @constant dlyNumParams Number of parameters
*/
enum SndDelayParam {
  dlyLength    = 0, 
  dlyFeedback  = 1,
  dlyNumParams = 2
};

////////////////////////////////////////////////////////////////////////////////

/*!
  @class SndAudioProcessorDelay
  @abstract A delay processor
  @discussion To come - see base class.
*/
@interface SndAudioProcessorDelay : SndAudioProcessor {
/*! @var  chanL temporary delay buffer (left channel) */
  float  *chanL;
/*! @var  chanR temporary delay buffer (right channel) */
  float  *chanR;
/*! @var  feedback The normalised amount of signal summed from earlier time. */
  float   feedback;
/*! @var  length Delay length in samples. */
  long    length;
/*! @var  readPos The delayed sample to next read from. */
  long    readPos;
/*! @var  writePos The delay sample to save. */
  long    writePos;
/*! @var  processingLock So we can't resize the delay lines whilst using them!*/
  NSLock *processingLock;
}

/*!
    @method   delayWithLength:feedback:
    @abstract   Factory method
    @param      nSams
    @param      fFB
    @result     A Freshly initialized, autoreleased  delay processor.
    @discussion
*/
+ delayWithLength: (const long) nSams feedback: (const float) fFB;

/*!
    @method setLength:feedback:
    @abstract 
    @param nSams
    @param fFB
    @result 
    @discussion
*/
- setLength: (const long) nSams andFeedback: (const float) fFB;

/*!
    @method     freemem
    @abstract 
    @param      nSams
    @param      fFB
    @result self
    @discussion
*/
- freemem;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
