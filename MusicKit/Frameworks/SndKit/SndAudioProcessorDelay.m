////////////////////////////////////////////////////////////////////////////////
//
//  SndAudioProcessorDelay.m
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

#import "SndAudioProcessorDelay.h"

@implementation SndAudioProcessorDelay

////////////////////////////////////////////////////////////////////////////////
// delayWithLength:feedback:
////////////////////////////////////////////////////////////////////////////////

+ delayWithLength: (long) nSams feedback: (float) fFB
{
  SndAudioProcessorDelay* delay = [SndAudioProcessorDelay new];
  [delay initWithLength: nSams feedback: fFB];
  return [delay autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  [super init];
  
  if (lock == nil)
    lock    = [[NSLock new] retain];
   length   = 0;
   feedback = 0;
   chanL    = NULL;
   chanR    = NULL; 
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// freemem
////////////////////////////////////////////////////////////////////////////////

- freemem
{
  if (chanL != NULL)
    free(chanL);
  chanL  = NULL;
  if (chanR != NULL)
    free(chanR);  
  chanR  = NULL;
  length = 0;
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc 
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
  [self freemem];
  [lock release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// initWithLength
////////////////////////////////////////////////////////////////////////////////

- initWithLength: (long) nSams feedback: (float) fFB
{
  [lock lock];
  
  [self freemem];
  feedback = fFB;
  chanL = (float*) malloc(sizeof(float*)*nSams);
  chanR = (float*) malloc(sizeof(float*)*nSams);
  memset(chanL,0,sizeof(float*)*nSams);
  memset(chanR,0,sizeof(float*)*nSams);
  readPos  = 1;
  writePos = 0;
//  printf("Delay init with length: %li and feedback: %f\n",length,feedback);

  [lock unlock];

  return self;
}

////////////////////////////////////////////////////////////////////////////////
// paramCount
////////////////////////////////////////////////////////////////////////////////

- (int) paramCount
{
  return dlyNumParams;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (int) index
{
  float r = 0.0f;
  switch (index) {
  case dlyLength:   r = length;   break;
  case dlyFeedback: r = feedback; break;
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// paramName
////////////////////////////////////////////////////////////////////////////////

- (NSString*) paramName: (int) index
{
  NSString *r = nil;
  
  switch (index) {
  case dlyLength:   r = @"Length";   break;
  case dlyFeedback: r = @"Feedback"; break;
  }
  return r;  
}

////////////////////////////////////////////////////////////////////////////////
// setParam 
////////////////////////////////////////////////////////////////////////////////

- setParam: (int) index toValue: (float) v
{
  switch (index) {
    case dlyLength:   
      length = v;   
      [self initWithLength: length feedback: feedback];
      break;
    case dlyFeedback: 
      v = v > 1.0 ? 1.0 : (v < 0.0 ? 0.0 : v);
      feedback = v; 
      break;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer: (SndAudioBuffer*) inB 
//                 outputBuffer: (SndAudioBuffer*) outB
////////////////////////////////////////////////////////////////////////////////

- processReplacingInputBuffer: (SndAudioBuffer*) inB 
                 outputBuffer: (SndAudioBuffer*) outB
{
  [lock lock];

    // no processing? copy data!
  if ([outB lengthInSamples] == [inB lengthInSamples] &&
      [outB channelCount]    == [inB channelCount]    &&
      [outB dataFormat]      == [inB dataFormat]      &&
      [inB dataFormat]       == SND_FORMAT_FLOAT      &&
      [inB channelCount]     == 2) {
      
      float *inD  = (float*) [inB  data];
      float *outD = (float*) [outB data];
      long   len  = [inB  lengthInSamples], i;
      
      for (i=0;i<len*2;i+=2) {
        outD[i]   = inD[i]   + chanL[readPos];
        outD[i+1] = inD[i+1] + chanR[readPos];
        
        chanL[writePos] = outD[i]   * feedback; 
        chanR[writePos] = outD[i+1] * feedback; 
        
        if ((++writePos) >= length) writePos = 0;
        if ((++readPos)  >= length) readPos  = 0;
      }
  }
  else
    printf("SndAudioProcessorDelay::processreplacing: ERR: Buffers have different formats\n");
      
  [lock unlock];

  return self;
}

////////////////////////////////////////////////////////////////////////////////

@end
