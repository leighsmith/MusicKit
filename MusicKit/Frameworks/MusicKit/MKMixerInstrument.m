/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    See MKMixerInstrument.h for details.
 
    To make your own custom version of MKMixerInstrument, add code where indicated
    below by "###"

  Original Author: David A. Jaffe, with Michael McNabb adding the
    enveloping and pitch transposition, the latter based on code
    provided by Julius Smith. Incorporation into the MusicKit framework, conversion
    to OpenStep and the SndKit by Leigh M. Smith.

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2004 The MusicKit Project.
*/

#import "_musickit.h"
#import <SndKit/SndKit.h>
#import "MKMixerInstrument.h"

// Dear WinNT doesn't know about PI, stolen from MacOSX math.h definition
#ifndef M_PI
#define M_PI            3.14159265358979323846  /* pi */
#endif

@implementation MKMixerInstrument /* See MKMixerInstrument.h for instance variables */

#define BUFFERSIZE (unsigned) (BUFSIZ * 8)   /* size (in samples per frame) of temporary mixing buffer */

static int timeScalePar = 0, timeOffsetPar = 0;
/* ### If you add a parameter, put in a declaration here */

enum { applyEnvBefore = 0, applyEnvAfter = 1, scaleEnvToFit = 2};

+ (void) initialize
{
    timeOffsetPar = [MKNote parTagForName: @"timeOffset"];
    timeScalePar  = [MKNote parTagForName: @"ampEnvTimeScale"];
    /* ### Add a par int initialization statement here. */
}

-init
{
    [super init];
    defaultAmp = 1.0;
    defaultFreq0 = 440;
    defaultFreq1 = 440;
    defaultEnvelope = nil;
    defaultTimeScale = applyEnvBefore;
    /* ### Add instance variables in MixInstrument.h and put in initialization
     *     here
     */
    // The default output sound format.
    soundFormat.dataFormat = SND_FORMAT_FLOAT;
    soundFormat.channelCount = 2;
    soundFormat.sampleRate = 44100.0;
    curOutSamp = 0;
    /* array of MKSamples, one for each active file. */
    samplesToMix = [[NSMutableArray alloc] init];
    [self addNoteReceiver: [[MKNoteReceiver alloc] init]]; /* Need one NoteReceiver */ 
    return self;
}

- (void) dealloc
{
    [samplesToMix release];
    samplesToMix = nil;
    [sound release]; // when sound is being allocated we should release this
    sound = nil;
    [mixedProcessorChain release]; // ditto any signal processing we apply to it.
    mixedProcessorChain = nil;
    [defaultFile release];	      /* default sound file name */
    defaultFile = nil;
    [super dealloc];
}

// Typically invoked once before performance. 
- (void) setSamplingRate: (double) aSrate
{
    if (![self inPerformance])
	soundFormat.sampleRate = aSrate;
}

// Typically invoked once before performance. 
- (void) setChannelCount: (int) chans
{
    if (![self inPerformance])
	soundFormat.channelCount = chans;
}

// This is invoked when first note is received during performance.
// The sound generated can be retrieved after the performance.
- firstNote: (MKNote *) aNote 
{
    [sound release];
    sound = [[Snd alloc] initWithFormat: soundFormat.dataFormat channelCount: soundFormat.channelCount frames: 0 samplingRate: soundFormat.sampleRate];
    [mixedProcessorChain release];
    mixedProcessorChain = [[SndAudioProcessorChain audioProcessorChain] retain];
    // NSLog(@"called firstNote:, sound is %@\n", sound);
    curOutSamp = 0;
    return self;
}

// Can we use an existing Snd method?
static long secondsToFrames(Snd *s, double time)
{
    return (long) ([s samplingRate] * time + .5);
}

/* Private method used to mix up to the current time (untilTime) */
- mixToTime: (double) untilTime
{
    MKSamples *sampleToMix;      /* Pointer to current sample to mix */
    unsigned int soundNum;       /* Sample to mix index */
    int currentBufferSize;       /* Number of frames we're computing */
    long untilFrame;             /* We're mixing until this output sample */
    BOOL inLastBufferOfSound;    /* Is this the last buffer for current sound? */
    int inSoundLastLocation;     /* Index of last usable sample in cur file */
    SndAudioBuffer *mixInBuffer; /* buffer of BUFFERSIZE frames used in mixing */
    // SndAudioFader *mixAudioFader = [mixedProcessorChain postFader]; // get the fader for "mastering" volume.
    
    if (untilTime != MK_ENDOFTIME)
	untilFrame = (long) (untilTime * soundFormat.sampleRate + .5);
    else { /* We're at the end of time. Find sound with longest duration */
	untilFrame = curOutSamp;  
	for (soundNum = 0; soundNum < [samplesToMix count]; soundNum++) {
	    sampleToMix = (MKSamples *) [samplesToMix objectAtIndex: soundNum];
	    untilFrame = MAX([sampleToMix processingEndSample] - [sampleToMix currentSample] + curOutSamp, untilFrame);
	}
    }
    mixInBuffer = [[SndAudioBuffer alloc] initWithDataFormat: soundFormat.dataFormat
						channelCount: soundFormat.channelCount
						samplingRate: soundFormat.sampleRate
						  frameCount: BUFFERSIZE];

    // Progress across the time line, in buffer region increments.
    // NSLog(@"curOutSamp = %d, untilFrame = %d\n", curOutSamp, untilFrame);
    while (curOutSamp < untilFrame) {
	[mixInBuffer zero]; // Clear out buffer since we reuse it on each iteration.
	currentBufferSize = MIN(untilFrame - curOutSamp, BUFFERSIZE);
	
	// Retrieve each sound assigned to be mixed.
	for (soundNum = 0; soundNum < [samplesToMix count]; soundNum++) {
	    SndAudioBuffer *inBuffer;
	    NSRange inSoundRange;
	    long framesMixed;
	    SndAudioProcessorChain *soundProcessorChain;
	    SndAudioFader *premixAudioFader;
	    
	    sampleToMix = (MKSamples *) [samplesToMix objectAtIndex: soundNum];
	    soundProcessorChain = [sampleToMix audioProcessorChain];
	    
	    inSoundLastLocation = [sampleToMix processingEndSample];
	    inSoundRange.location = [sampleToMix currentSample];
	    // Size of remaining input data, capped at the maximum buffer size.
	    // inSoundRange.length = MIN(inSoundLastLocation - inSoundRange.location, currentBufferSize);
	    inSoundRange.length = inSoundLastLocation - inSoundRange.location;
	    // NSLog(@"sampleToMix %@ inSoundRange = (%d,%d)\n", sampleToMix, inSoundRange.location, inSoundRange.length);
	    
	    inBuffer = [[sampleToMix sound] audioBufferForSamplesInRange: inSoundRange];
	    // Apply any signal processing, including amplitude envelopes to the buffer before mixing.
	    premixAudioFader = [soundProcessorChain postFader];
	    [premixAudioFader setAmp: [sampleToMix amplitude] clearingEnvelope: NO];
	    // [premixAudioFader setBalance: balance clearingEnvelope: NO];
	    [soundProcessorChain processBuffer: inBuffer forTime: untilTime];

	    // Now mix in the buffer.
	    framesMixed = [mixInBuffer mixWithBuffer: inBuffer];

#if 0
	    // Do any audio processing on the mix for example, the final or "mastering" volume.
	    [mixAudioFader setAmp: amplitude clearingEnvelope: NO];
	    [mixAudioFader setBalance: balance clearingEnvelope: NO];

	    [mixedProcessorChain processBuffer: framesMixed forTime: untilTime];
#endif	    
	    
	    inLastBufferOfSound = inSoundRange.length < currentBufferSize;
	    
	    if (inLastBufferOfSound) {      /* This sound's done. */
		[samplesToMix removeObjectAtIndex: soundNum--]; 
	    }
	    else
                [sampleToMix setCurrentSample: [sampleToMix currentSample] + ((inLastBufferOfSound) ? inSoundRange.length : currentBufferSize)];
	}
	// save away the mix to our final sound.
	// TODO, there could be scope to use SndExpt aka SndDiskBased to directly write the file.
	[sound appendAudioBuffer: mixInBuffer];
	curOutSamp += currentBufferSize;
    }
    if (mixInBuffer) {
	[mixInBuffer release];
	mixInBuffer = nil;
    }
    return self;
}

#if 0
// TODO obsolete, remove once balance used.

/* These methods do pre-mix processing */
/* ### Add your own processing methods here */

-_position:(int)bearing inSound: (Snd *) inSound outSound: (Snd *) outSound 
 startSamp:(int)startSamp sampCount:(int)sampCount amp:(double)amp
 alreadySwapped:(BOOL)alreadySwapped
{
    /* Left-right panning */
    short *inData = &(((short *)[inSound data])[startSamp]);
    short *inDataEnd = inData + sampCount;
    short *outData = (short *)[outSound data];
    double bearingD,leftAmpD,rightAmpD;
    int leftSample,rightSample,leftAmp,rightAmp;

#define bearingFun1(theta)    fabs(cos(theta))
#define bearingFun2(theta)    fabs(sin(theta))

    bearingD = bearing * M_PI/180.0 + M_PI/4.0;
    leftAmpD = amp * bearingFun1(bearingD);
    leftAmp = leftAmpD * MAXSHORT;
    rightAmpD = amp * bearingFun2(bearingD);
    rightAmp = rightAmpD * MAXSHORT;
    while (inData < inDataEnd) {
        leftSample = rightSample = (signed short int) (alreadySwapped ? *inData : NSSwapBigShortToHost(*inData));
        leftSample *= leftAmp;   /* Do fixed point multiply */
        leftSample >>= 15;       /* intAmp has only 15 bits of magnitude */
        *outData++ = (short) leftSample;
        rightSample *= rightAmp; /* Do fixed point multiply */
        rightSample >>= 15;      /* intAmp has only 15 bits of magnitude */
        *outData++ = (short) rightSample;
        inData++;
    }
    return self; 
}

// TODO obsolete, remove once SndEnvelopes used.
- _applyEnvelope:envelope to:(MKSamples *) info scaleToFit:(BOOL)scaleToFit
{
    /* Put an envelope on a signal. */
    int n;
    short *end, *segend;
    short *data = (short *)[[info sound] data] + [info currentSample];
    int intamp;
    double amp, inc;
    int nchans = [[info sound] channelCount];
    int arrCount;
    double factor;
    double *xarr;
    double *yarr;
    double *arrEnd;
    double dt;
	
    if (!envelope)
      return self;
    arrCount = [envelope pointCount];
    xarr = [envelope xArray]; /* Assumes xarr is valid */
    yarr = [envelope yArray];
    arrEnd = xarr+arrCount;
    end = data + [info processingEndSample] - [info currentSample];
    if (scaleToFit) {
	factor = ((((end-data)/(double)[[info sound] samplingRate])/nchans)/
		  (xarr[arrCount-1]-xarr[0]));
    }
    else factor = 1;
    while (data<end) {
	if (xarr < (arrEnd-1)) {
	    dt = (*(xarr+1)-*xarr) * factor;
	    n = (int)(dt*[[info sound] samplingRate] + .5);
	    segend = MIN(data+n*nchans,end);
	    amp = *yarr * 32768.0;
	    inc = (*(yarr+1)-*yarr) * 32768.0/(double)n;
	}
	else {
	    segend = end;
	    amp = *yarr * 32768.0;
	    inc = 0;
	}
	if (nchans==1) {
            while (data<segend) {
                *data = (short)(((int)*data * (int)amp)>>15);
		data++;
                amp += inc;
            }
	}
	else {
            while (data<segend) {
                intamp = (int)amp;
                *data = (short)(((int)*data * intamp)>>15);
		data++;
                *data = (short)(((int)*data * intamp)>>15);
		data++;
                amp += inc;
            }
	}
	xarr++;
	yarr++;
    }
    return self;
}
#endif

- (Snd *) mixedSound
{
    return [[sound retain] autorelease];
}

/* This is invoked when performance is over. */
- afterPerformance 
{
    if (sound == nil)  /* Did we ever receive any notes? */
	return self;
    [self mixToTime: MK_ENDOFTIME];
    return self;
}

/* This is invoked when a new MKNote is received during performance */
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    MKNoteType type;
    double amp = defaultAmp;
    int timeScale = defaultTimeScale;
    
    [self mixToTime: MKGetTime()]; /* Update mix. */
    if (!aNote)
	return self;
    switch (type = [aNote noteType]) {
    case MK_noteDur: { /* NoteDur means new file with duration. We convert the format to match the output file. */
	MKSamples *newSoundFileSamples = [[MKSamples alloc] init];
	double dur, timeOffset;
	NSString *file = [aNote parAsStringNoCopy: MK_filename];
	Snd *newSound;
	double resamplingFactor = 1.0;
	
	if (file == nil || ![file length]) { /* Parameter not present? */
	    file = defaultFile;
	    NSLog(@"No input sound file specified, using default: %@.\n", file);
	    break;
	}
	// TODO there is scope for optimization using SndTable names to look up existing (converted once sounds), rather than reading in each time.
        [newSoundFileSamples readSoundfile: file];
	// Establish an audio processing chain (including a fader) for signal processing each sound.
	[newSoundFileSamples setAudioProcessorChain: [SndAudioProcessorChain audioProcessorChain]];

	newSound = [newSoundFileSamples sound];
	if (!newSound) {
	    NSLog(@"Can't find file %@.\n", file);
	    break;
	}
	// NSLog(@"realize %@ at time %f ", aNote, MKGetTime());		// Give user feedback
		  
	if ([aNote isParPresent: MK_amp])
	    amp = [aNote parAsDouble: MK_amp];
	if ([aNote isParPresent: MK_velocity])
	    amp *= MKMidiToAmpAttenuation([aNote parAsInt: MK_velocity]);
	[newSoundFileSamples setAmplitude: [aNote isParPresent: MK_amp] ? amp : defaultAmp];

	// Assign the current sample.
	if ([aNote isParPresent: timeOffsetPar]) {
	    timeOffset = [aNote parAsDouble: timeOffsetPar];
	    [newSoundFileSamples setCurrentSample: secondsToFrames(newSound, timeOffset)];
	}
	else
	    [newSoundFileSamples setCurrentSample: 0];
	
	// Assign the last sample processed.
	dur = [aNote dur];
	if (!MKIsNoDVal(dur)) {
	    if (dur != 0) {
		unsigned int lastLoc = secondsToFrames(newSound, dur) + [newSoundFileSamples currentSample];
		
		[newSoundFileSamples setProcessingEndSample: MIN([newSound lengthInSampleFrames], lastLoc)];		
	    }
	    else
		[newSoundFileSamples setProcessingEndSample: [newSound lengthInSampleFrames]];
	}
	if ([newSoundFileSamples currentSample] > [newSoundFileSamples processingEndSample] || dur < 0 ) {
	    NSLog(@"Warning: no samples to mix for this file.\n");
	    break;
	}
#if 0
	// Retrieves a bearing, being the pan (in degrees) of a mono sound from an idealised listener position, triangulated between two speakers.
	int bearing = [aNote isParPresent: MK_bearing] ? [aNote parAsInt: MK_bearing] : 0);
#endif	      

	if ([aNote isParPresent: timeScalePar])
	    timeScale = [aNote parAsInt: timeScalePar];
	if (timeScale == applyEnvBefore || timeScale == scaleEnvToFit) {
	    if ([aNote isParPresent: MK_ampEnv] || defaultEnvelope) {
		MKEnvelope *ampEnv = [aNote parAsEnvelope: MK_ampEnv];

		if (!ampEnv) 
		    ampEnv = defaultEnvelope;
		//[self _applyEnvelope: ampEnv to: newSoundFileSamples scaleToFit: timeScale == 2];
	    }
	}

	/* ### Add your processing modules here, if you want them to apply
	*     before pitch-shifting. 
	*/

	/* freq0 is assumed old freq. freq1 is new freq. */
	if ([aNote isParPresent: MK_freq1] || [aNote isParPresent: MK_freq0] ||
	    [aNote isParPresent: MK_keyNum] || defaultFreq1 || defaultFreq0 ||
	    ([newSound samplingRate] != soundFormat.sampleRate)) {
	    double f0 = (([aNote isParPresent: MK_freq0]) ? [aNote parAsDouble: MK_freq0] : defaultFreq0);
	    double f1 = (([aNote isParPresent: MK_freq1]) ? [aNote parAsDouble: MK_freq1] :
			(([aNote isParPresent: MK_keyNum]) ? [aNote freq] : defaultFreq1));

	    if ((f0 != 0.0 && f1 == 0.0) || (f1 != 0.0 && f0 == 0.0))
		NSLog(@"Warning: Must specify both Freq0 and Freq1 if either are specified.\n");
	    resamplingFactor = ((f1 && f0) ? (f0 / f1) : 1.0) * (soundFormat.sampleRate / [newSound samplingRate]);
	    if ((resamplingFactor > 32) || (resamplingFactor < .03125))
		NSLog(@"Warning: resampling more than 5 octaves.\n");
	}
	[newSound setConversionQuality: SndConvertHighQuality];
	[newSound convertToFormat: soundFormat.dataFormat
		     samplingRate: (fabs(resamplingFactor - 1.0) > 0.0001) ? [newSound samplingRate] * resamplingFactor : [newSound samplingRate]
		     channelCount: soundFormat.channelCount];
	      
	if (timeScale == applyEnvAfter) {
	    if ([aNote isParPresent: MK_ampEnv] || defaultEnvelope) {
		MKEnvelope *ampEnv = [aNote parAsEnvelope: MK_ampEnv];

		if (!ampEnv) 
		    ampEnv = defaultEnvelope;
		//[self _applyEnvelope: ampEnv to: newSoundFileSamples scaleToFit: 0];
	    }
	}
	/* ### Add your processing modules here, if you want them to apply
	 *     after pitch-shifting. 
	 */
	[samplesToMix addObject: newSoundFileSamples];
	[newSoundFileSamples autorelease]; // we are through with it, the samplesToMix will retain it as it needs.
	break;
    }
    case MK_noteUpdate: { /* Only no-tag NoteUpdates are recognized */
	if ([aNote noteTag] != MAXINT)
	    break;        /* Ignore noteUpdates with note tags */
	if ([aNote isParPresent: MK_amp]) 
	    defaultAmp = [aNote parAsDouble: MK_amp]; 
	if ([aNote isParPresent: MK_filename])
	    defaultFile = [aNote parAsStringNoCopy: MK_filename];
	if ([aNote isParPresent: MK_freq1])
	    defaultFreq1 =[aNote parAsDouble: MK_freq1];
	if ([aNote isParPresent: MK_freq0])
	    defaultFreq0 =[aNote parAsDouble: MK_freq0];
	if ([aNote isParPresent: MK_ampEnv])
	    defaultEnvelope =[aNote parAsEnvelope: MK_ampEnv];
	if ([aNote isParPresent: timeScalePar])
	    defaultTimeScale =[aNote parAsInt: timeScalePar];
	break;
    }
    default: /* Ignore all other notes */
	break;
    }
    return self;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ samplesToMix: %@, output sound %@, mixed processor chain %@",
	[super description], samplesToMix, sound, mixedProcessorChain];
}

@end

