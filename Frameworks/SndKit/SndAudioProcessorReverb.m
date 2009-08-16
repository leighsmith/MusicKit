////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    FreeVerb-based
//    FreeVerb originally written by Jezar at Dreampoint, June 2000
//    http://www.dreampoint.co.uk
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//  Rewritten by Leigh M. Smith <leigh@leighsmith.com>
//
//  Jezar's code described as "This code is public domain"
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndAudioProcessorReverb.h"
#import "SndReverbCombFilter.h"
#import "SndReverbAllpassFilter.h"
#import "tuning.h"

@implementation SndAudioProcessorReverb

////////////////////////////////////////////////////////////////////////////////
// init
////////////////////////////////////////////////////////////////////////////////

- init
{
    self = [super initWithParamCount: rvrbNumParams name: @"Reverb"];
    if (self != nil) {
	int combIndex;
	int allPassIndex;
	int channelIndex;

	bufferLength = 0;
	inputMix     = NULL;
	outputAccumL = NULL;
	outputAccumR = NULL;

	// Initialise the combs and allpass components.
	for(combIndex = 0; combIndex < NUMCOMBS; combIndex++) {
	    for(channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
		comb[channelIndex][combIndex] = [[SndReverbCombFilter alloc] initWithLength: combtuning[channelIndex][combIndex]];
	    }
	}

	for(allPassIndex = 0; allPassIndex < NUMALLPASSES; allPassIndex++) {
	    for(channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
		allpass[channelIndex][allPassIndex] = [[SndReverbAllpassFilter alloc] initWithLength: allpasstuning[channelIndex][allPassIndex]];
		// Set default values
		[allpass[channelIndex][allPassIndex] setFeedback: 0.5f];
	    }
	}

	[self setWet: initialwet];
	[self setRoomSize: initialroom];
	[self setDry: initialdry];
	[self setDamp: initialdamp];
	[self setWidth: initialwidth];
	[self setMode: initialmode];

	// Buffers will be full of rubbish - so we MUST mute them
	[self mute];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////
// dealloc
////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
    int combIndex;
    int allPassIndex;
    int channelIndex;

    for (combIndex = 0; combIndex < NUMCOMBS; combIndex++) {
	for (channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
	    [comb[channelIndex][combIndex] release];
	}
    }
    for (allPassIndex = 0; allPassIndex < NUMALLPASSES; allPassIndex++) {
	for (channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
	    [allpass[channelIndex][allPassIndex] release];
	}
    }
    
    [super dealloc];
}

- (void) mute
{
    int combIndex;
    int allPassIndex;
    int channelIndex;

    if ([self getMode] >= freezemode)
	return;
    
    for (combIndex = 0; combIndex < NUMCOMBS; combIndex++) {
	for (channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
	    [comb[channelIndex][combIndex] mute];
	}
    }
    for (allPassIndex = 0; allPassIndex < NUMALLPASSES; allPassIndex++) {
	for (channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
	    [allpass[channelIndex][allPassIndex] mute];
	}
    }
}

////////////////////////////////////////////////////////////////////////////////
// processReplacingInputBuffer: (SndAudioBuffer*) inB 
//                outputBuffer: (SndAudioBuffer*) outB 
////////////////////////////////////////////////////////////////////////////////

- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB 
                        outputBuffer: (SndAudioBuffer *) outB
{
    if ([outB hasSameFormatAsBuffer: inB]      &&
	[inB dataFormat]   == SND_FORMAT_FLOAT &&
	[inB channelCount] == NUMCHANNELS) {
	
	float *inD  = (float*) [inB  bytes];
	float *outD = (float*) [outB bytes];
	long   numsamples = [inB lengthInSampleFrames];
	float *inputL = inD;
	float *inputR = inD + 1; 
	float *outputL = outD; 
	float *outputR = outD + 1; 
	int skip = NUMCHANNELS;
	
	while(numsamples-- > 0) {
	    float outL = 0;
	    float outR = 0;
	    float input = (*inputL + *inputR) * gain;
	    int combIndex;
	    int allpassIndex;

	    // Accumulate comb filters in parallel
	    for(combIndex = 0; combIndex < NUMCOMBS; combIndex++) {
		// TODO expand for multiple channels.
		// for(int channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
		    outL += [comb[0][combIndex] process: input];
		    outR += [comb[1][combIndex] process: input];
		// }
	    }
	    
	    // Feed through allpasses in series
	    for(allpassIndex = 0; allpassIndex < NUMALLPASSES; allpassIndex++) {
		outL = [allpass[0][allpassIndex] process: outL];
		outR = [allpass[1][allpassIndex] process: outR];
	    }
	    
	    // Calculate output REPLACING with anything already there
	    *outputL = outL * wet1 + outR * wet2 + *inputL * dry;
	    *outputR = outR * wet1 + outL * wet2 + *inputR * dry;
	    
	    // Increment sample pointers, allowing for interleave (if any)
	    outputL += skip;
	    outputR += skip;
	    inputL  += skip;
	    inputR  += skip;
	}
    }
    else
	NSLog(@"SndAudioProcessorReverb processReplacingInputBuffer:outputBuffer: ERR: Buffers have different formats\n");
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// paramValue:
////////////////////////////////////////////////////////////////////////////////

- (float) paramValue: (const int) index
{
    float r;

    switch (index) {
    case rvrbRoomSize: r = [self getRoomSize]; break;
    case rvrbDamp:     r = [self getDamp];     break;
    case rvrbWet:      r = [self getWet];      break;
    case rvrbDry:      r = [self getDry];      break;
    case rvrbWidth:    r = [self getWidth];    break;
    case rvrbMode:     r = [self getMode];     break; 
    default:           r = 0.0f;
    }
    return r;
}

////////////////////////////////////////////////////////////////////////////////
// paramName:
////////////////////////////////////////////////////////////////////////////////

- (NSString *) paramName: (const int) index
{
    NSString *r = nil;

    switch (index) {
    case rvrbRoomSize: r = @"RoomSize"; break;
    case rvrbDamp:     r = @"Damp";     break;
    case rvrbWet:      r = @"Wet";      break;
    case rvrbDry:      r = @"Dry";      break;
    case rvrbWidth:    r = @"Width";    break;
    case rvrbMode:     r = @"Mode";     break; 
    default:           r = nil;
    }
    return r;
}

////////////////////////////////////////////////////////////////////////////////
// setParam:toValue:
//
// TODO: it's a bit screwy setting a long length to a float value, but for a VST
// look-and-feel, all params are set by floats, and return as floats. Rethink. 
////////////////////////////////////////////////////////////////////////////////

- (void) setParam: (const int) index toValue: (const float) v;
{
    if (v < 0.0f || v > 1.0f) {
	NSLog(@"SndAudioProcessorReverb::setParam: ERR: value must be in [0,1]");
    }
    else {
	switch (index) {
	case rvrbRoomSize: [self setRoomSize: v]; break;
	case rvrbDamp:     [self setDamp: v];     break;
	case rvrbWet:      [self setWet: v];      break;
	case rvrbDry:      [self setDry: v];      break;
	case rvrbWidth:    [self setWidth: v];    break;
	case rvrbMode:     [self setMode: v];     break; 
	}
    }
}

// Recalculate internal values after parameter change
- (void) update
{
    int combIndex;
    int channelIndex;

    wet1 = wet * (width / 2 + 0.5f);
    wet2 = wet * ((1 - width) / 2);
    
    if (mode >= freezemode) {
	roomsize1 = 1;
	damp1 = 0;
	gain = muted;
    }
    else {
	roomsize1 = roomsize;
	damp1 = damp;
	gain = fixedgain;
    }

    for(combIndex = 0; combIndex < NUMCOMBS; combIndex++) {
	for(channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
	    [comb[channelIndex][combIndex] setFeedback: roomsize1];
	}
    }

    for(combIndex = 0; combIndex < NUMCOMBS; combIndex++) {
	for(channelIndex = 0; channelIndex < NUMCHANNELS; channelIndex++) {
	    [comb[channelIndex][combIndex] setDamp: damp1];
	}
    }
}

// The following get/set functions are not inlined, because
// speed is never an issue when calling them, and also
// because as you develop the reverb model, you may
// wish to take dynamic action when they are called.

- (void) setRoomSize: (float) value
{
    roomsize = (value * scaleroom) + offsetroom;
    [self update];
}

- (float) getRoomSize
{
    return (roomsize - offsetroom) / scaleroom;
}

- (void) setDamp: (float) value
{
    damp = value*scaledamp;
    [self update];
}

- (float) getDamp
{
    return damp / scaledamp;
}

- (void) setWet: (float) value
{
    wet = value * scalewet;
    [self update];
}

- (float) getWet
{
    return wet / scalewet;
}

- (void) setDry: (float) value
{
    dry = value * scaledry;
}

- (float) getDry
{
    return dry / scaledry;
}

- (void) setWidth: (float) value
{
    width = value;
    [self update];
}

- (float) getWidth
{
    return width;
}

- (void) setMode: (float) value
{
    mode = value;
    [self update];
}

- (float) getMode
{
    if (mode >= freezemode)
	return 1;
    else
	return 0;
}

////////////////////////////////////////////////////////////////////////////////

@end
