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

enum {
  dlyLength    = 0, // in samples!
  dlyFeedback  = 1,
  dlyNumParams = 2
};

/*!
    @class
    @abstract 
    @discussion To come
    @var
    @var
    @var
*/
@interface SndAudioProcessorDelay : SndAudioProcessor {
  float  *chanL;
  float  *chanR;
  float   feedback;
  long    length;
  long    readPos;
  long    writePos;
  NSLock *lock; // so we can't resize the delay lines whilst using them!
}

+ delayWithLength: (long) nSams feedback: (float) fFB;
- initWithLength: (long) nSams feedback: (float) fFB;
- freemem;
- (void) dealloc;
- (int) paramCount;
- (float) paramValue: (int) index;
- (NSString*) paramName: (int) index;
- setParam: (int) index toValue: (float) v;

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                        outputBuffer: (SndAudioBuffer*) outB;


@end
