////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorDelay.h
//  SndKit
//
//  Created by skot on Wed Mar 28 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 SndKit project
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
enum {
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
/*! @var  chanL*/
  float  *chanL;
/*! @var  chanR*/
  float  *chanR;
/*! @var  feedback*/
  float   feedback;
/*! @var  length*/
  long    length;
/*! @var  readPos*/
  long    readPos;
/*! @var  writePos*/
  long    writePos;
/*! @var  lock*/
  NSLock *lock; // so we can't resize the delay lines whilst using them!
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
