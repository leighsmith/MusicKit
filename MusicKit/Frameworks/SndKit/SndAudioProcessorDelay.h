////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorDelay.h
//  SndKit
//
//  Created by skot on Wed Mar 28 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
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
#import "SndAudioBuffer.h"

/*!
    @enum     SndDelayParam
    @constant dlyLength  
    @constant dlyFeedback 
    @constant dlyNumParams 
*/
enum {
  dlyLength    = 0, // in samples!
  dlyFeedback  = 1,
  dlyNumParams = 2
};

////////////////////////////////////////////////////////////////////////////////

/*! 
    @class      SndAudioProcessorDelay
    @abstract   A delay processor
    @discussion To come
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
- init;
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
/*!
    @method dealloc
    @abstract 
    @result
    @discussion
*/
- (void) dealloc;
/*!
    @method paramValue:
    @abstract 
    @param index
    @result Parameter value in the range [0,1]
    @discussion
*/
- (float) paramValue: (const int) index;
/*!
    @method paramName
    @abstract 
    @param index
    @result parameter name
    @discussion
*/
- (NSString*) paramName: (const int) index;
/*!
    @method setParam:toValue:
    @abstract 
    @param index
    @param v
    @result self
    @discussion
*/
- setParam: (const int) index toValue: (const float) v;
/*!
    @method processReplacingInputBuffer:outputBuffer:
    @abstract 
    @discussion
    @param      inB
    @param      outB
    @result     TRUE if outB contains processed data 
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                        outputBuffer: (SndAudioBuffer*) outB;
@end

////////////////////////////////////////////////////////////////////////////////

#endif
