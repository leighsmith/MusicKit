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

#import "SndAudioProcessorDelay.h" 

@implementation SndAudioProcessorDelay

////////////////////////////////////////////////////////////////////////////////
// delayWithLength:feedback:
////////////////////////////////////////////////////////////////////////////////

+ delayWithLength: (const long) nSams feedback: (const float) fFB
{
  SndAudioProcessorDelay* delay = [[SndAudioProcessorDelay alloc] init];
  [delay setLength: nSams andFeedback: fFB];
  return [delay autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  if (lock == nil) {
    [super initWithParamCount: dlyNumParams name: @"Delay"];
    lock = [[NSLock alloc] init];
  }
  [self setLength: 11025 andFeedback: 0.25];
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

- setLength: (const long) nSams andFeedback: (const float) fFB
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
// paramValue
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (const int) index
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

- (NSString*) paramName: (const int) index
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

- setParam: (const int) index toValue: (const float) v
{
  switch (index) {
    case dlyLength:   
      length = v;   
      [self setLength: length andFeedback: feedback];
      break;
    case dlyFeedback: 
      feedback = v > 1.0 ? 1.0 : (v < 0.0 ? 0.0 : v);
      break;
  }
  return self;
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer: (SndAudioBuffer*) inB 
//                outputBuffer: (SndAudioBuffer*) outB
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer*) inB 
                        outputBuffer: (SndAudioBuffer*) outB
{
  [lock lock];

    // no processing? copy data!
  if ([outB lengthInSampleFrames] == [inB lengthInSampleFrames] &&
      [outB channelCount]    == [inB channelCount]    &&
      [outB dataFormat]      == [inB dataFormat]      &&
      [inB dataFormat]       == SND_FORMAT_FLOAT      &&
      [inB channelCount]     == 2) {
      
      float *inD  = (float*) [inB  bytes];
      float *outD = (float*) [outB bytes];
      long   len  = [inB  lengthInSampleFrames], i;
      
      for (i=0;i<len*2;i+=2) {
        outD[i]   = inD[i]   + chanL[readPos];
        outD[i+1] = inD[i+1] + chanR[readPos];
        
        chanL[writePos] = outD[i]   * feedback; 
        chanR[writePos] = outD[i+1] * feedback; 
        
        if ((++writePos) >= length) writePos = 0;
        if ((++readPos)  >= length) readPos  = 0;
      }
      [lock unlock];
      return TRUE;
    }
  [lock unlock];
  NSLog(@"SndAudioProcessorDelay::processreplacing: ERR: Buffers have different formats\n");
  return FALSE;
}

////////////////////////////////////////////////////////////////////////////////

@end
