////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See headerdoc description in SndAudioProcessorDelay.h for description.
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

+ delayWithLength: (const long) nSams feedback: (const float) newFeedback
{
    SndAudioProcessorDelay* delay = [[SndAudioProcessorDelay alloc] init];
    
    [delay setLength: nSams andFeedback: newFeedback];
    return [delay autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
  if (processingLock == nil) {
    [super initWithParamCount: dlyNumParams name: @"Delay"];
    processingLock = [[NSLock alloc] init];
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
  [processingLock release];
  [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
// initWithLength
////////////////////////////////////////////////////////////////////////////////

- setLength: (const long) nSams andFeedback: (const float) fFB
{
    [processingLock lock];
    
    [self freemem];
    feedback = fFB;
    chanL = (float*) calloc(nSams, sizeof(float *));
    chanR = (float*) calloc(nSams, sizeof(float *));
    readPos  = 1;
    writePos = 0;
    length = nSams;
    // NSLog(@"Delay init with length: %li and feedback: %f\n", length, feedback);
    
    [processingLock unlock];
    
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

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB 
                        outputBuffer: (SndAudioBuffer *) outB
{
    [processingLock lock];
    
    // no processing? copy data!
    //TODO [outB hasSameFormatAsBuffer: inB] checks sample rate also.
    if ([outB lengthInSampleFrames] == [inB lengthInSampleFrames] &&
	[outB channelCount]         == [inB channelCount]    &&
	[outB dataFormat]           == [inB dataFormat]      &&
	[inB dataFormat]            == SND_FORMAT_FLOAT      &&
	[inB channelCount]          == 2) {
	
	float *inD  = (float*) [inB  bytes];
	float *outD = (float*) [outB bytes];
	long lengthInFrames  = [inB  lengthInSampleFrames], sampleIndex;
	
	// NSLog(@"in SndAudioProcessorDelay processReplacingInputBuffer:\n");
	
	for (sampleIndex = 0; sampleIndex < lengthInFrames * 2; sampleIndex += 2) {
	    outD[sampleIndex]   = inD[sampleIndex]   + chanL[readPos];
	    outD[sampleIndex+1] = inD[sampleIndex+1] + chanR[readPos];
	    
	    chanL[writePos] = outD[sampleIndex]   * feedback; 
	    chanR[writePos] = outD[sampleIndex+1] * feedback; 
	    //NSLog(@"chanL[%d] %f, chanR[] %f\n", writePos, chanL[writePos], chanR[writePos]);
	    
	    if ((++writePos) >= length)
		writePos = 0;
	    if ((++readPos)  >= length)
		readPos  = 0;
	}
	[processingLock unlock];
	return TRUE;
    }
    [processingLock unlock];
    NSLog(@"SndAudioProcessorDelay::processreplacing: ERR: Buffers have different formats\n");
    return FALSE;
}

////////////////////////////////////////////////////////////////////////////////

@end
