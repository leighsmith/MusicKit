////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorDelay.h
//  SndKit
//
//  Created by skot on Wed Mar 28 2001. <skot@tomandandy.com>
//  Copyright (c) 2001 tomandandy music inc.
//
//  Permission is granted to use and modify this code for commercial and non-commercial
//  purposes so long as the author attribution and copyright messages remain intact and
//  accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

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
} SndDelayParam;

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
    @function   delayWithLength:feedback:
    @abstract   Factory method
    @discussion
    @param      nSams
    @param      fFB
    @result     A Freshly initialized, autoreleased  delay processor.
*/
+ delayWithLength: (long) nSams feedback: (float) fFB;
/*!
    @function intWithLength:feedback:
    @abstract 
    @discussion
    @param nSams
    @param fFB
    @result 
*/
- initWithLength: (long) nSams feedback: (float) fFB;
/*!
    @function freemem
    @abstract 
    @discussion
    @param nSams
    @param fFB
    @result self
*/
- freemem;
/*!
    @function dealloc
    @abstract 
    @discussion
    @result
*/
- (void) dealloc;
/*!
    @function paramCount
    @abstract 
    @discussion
    @result
*/
- (int) paramCount;
/*!
    @function paramValue:
    @abstract 
    @discussion
    @param index
    @result Parameter value in the range [0,1]
*/
- (float) paramValue: (int) index;
/*!
    @function paramName
    @abstract 
    @discussion
    @param index
    @result parameter name
*/
- (NSString*) paramName: (int) index;
/*!
    @function setParam:toValue:
    @abstract 
    @discussion
    @param index
    @param v
    @result self
*/
- setParam: (int) index toValue: (float) v;

/*!
    @function processReplacingInputBuffer:outputBuffer:
    @abstract 
    @discussion
    @param      inB
    @param      outB
    @result     TRUE if outB contains processed data 
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                        outputBuffer: (SndAudioBuffer*) outB;

@end
