/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    See MKMixerInstrument.h for details.
 
  Author: 
    First version written by David A. Jaffe, with Michael McNabb adding the
    enveloping and pitch transposition, the latter based on code
    provided by Julius Smith. 

    Totally rewritten for V2.0 (with no vestiges of earlier version) for incorporation
    into the MusicKit framework, conversion to OpenStep and the SndKit
    by Leigh M. Smith.

  Copyright (c) 1999-2004 The MusicKit Project.
*/

#import "_musickit.h"
#import <SndKit/SndKit.h>
#import "MKMixerInstrument.h"

// Dear WinNT doesn't know about PI, duplicated from MacOSX math.h definition
#ifndef M_PI
#define M_PI            3.14159265358979323846  // pi
#endif

@implementation MKMixerInstrument

// size (in samples per frame) of temporary mixing buffer. Can't be too big or SndAudioUnitProcessor will complain.
#define MIXING_BUFFER_SIZE 1024   

// parameters used in mixing
static int beginMixingAtParam = 0;
static int loopingParam = 0;

+ (void) initialize
{
    [super initialize];
    beginMixingAtParam = [MKNote parTagForName: @"timeOffset"]; 
    loopingParam = [MKNote parTagForName: @"looping"];
}

- init
{
    self = [super init];
    if(self != nil) {
	defaultAmplitude = 1.0; // Maximum volume.
	defaultBearing = 0.0;  // Centre position.
	defaultNewFrequency = 440;
	defaultOriginalFrequency = 440;
	currentlyLooping = NO;
	
	// The default output sound format.
	soundFormat.dataFormat = SND_FORMAT_FLOAT;
	soundFormat.channelCount = 2;
	soundFormat.sampleRate = 44100.0;
	currentMixFrame = 0;
	// dictionary of MKSamples, one for each active file, keyed by noteTag.
	samplesToMix = [[NSMutableDictionary dictionaryWithCapacity: 5] retain];
	// Use a single MKNoteReceiver to receive all mixing notes.
	[self addNoteReceiver: [[MKNoteReceiver alloc] init]]; 	
    }
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
    [defaultFile release];
    defaultFile = nil;
    [super dealloc];
}

// Typically called once before performance. 
- (void) setSamplingRate: (double) aSrate
{
    if (![self inPerformance])
	soundFormat.sampleRate = aSrate;
}

// Typically called once before performance. 
- (void) setChannelCount: (int) chans
{
    if (![self inPerformance])
	soundFormat.channelCount = chans;
}

// This is called when first note is received during performance.
// The sound generated can be retrieved after the performance.
- firstNote: (MKNote *) ignoredNote 
{
    [sound release];
    sound = [[Snd alloc] initWithFormat: soundFormat.dataFormat
			   channelCount: soundFormat.channelCount
				 frames: 0
			   samplingRate: soundFormat.sampleRate];
    [mixedProcessorChain release];
    mixedProcessorChain = [[SndAudioProcessorChain audioProcessorChain] retain];
    // NSLog(@"called firstNote:, sound is %@\n", sound);
    currentMixFrame = 0;
    return self;
}

// Can we use an existing Snd method?
static long secondsToFrames(Snd *s, double time)
{
    return (long) ([s samplingRate] * time + .5);
}

// Mix until the given time in seconds.
- mixToTime: (double) untilTime
{
    MKSamples *sampleToMix;      // The current sample to mix
    unsigned int soundNum;       // Sample to mix index
    int currentBufferSize;       // The buffer size in frames that we're computing
    long untilFrame;             // mix until this frame.
    BOOL inLastBufferOfSound;    // Is this the last buffer for current sound?
    int inSoundLastLocation;     // Index of last usable sample in cur file
    SndAudioBuffer *mixInBuffer; // buffer of MIXING_BUFFER_SIZE frames used in mixing
    // SndAudioFader *mixAudioFader = [mixedProcessorChain postFader]; // get the fader for "mastering" volume.
    
    if (untilTime != MK_ENDOFTIME)
	untilFrame = (long) (untilTime * soundFormat.sampleRate + .5);
    else { /* We're at the end of time. Find sound with longest duration */
	NSEnumerator *sampleEnumerator = [samplesToMix objectEnumerator];

	untilFrame = currentMixFrame;
	while ((sampleToMix = [sampleEnumerator nextObject])) {
	    untilFrame = MAX([sampleToMix processingEndSample] - [sampleToMix currentSample] + currentMixFrame, untilFrame);
	}
	untilTime = untilFrame / soundFormat.sampleRate; // reassign untilTime.
    }

    // Progress across the time line, in buffer region increments.
    // NSLog(@"currentMixFrame = %d, untilFrame = %d\n", currentMixFrame, untilFrame);
    while (currentMixFrame < untilFrame) {
	NSArray *noteTagsList = [samplesToMix allKeys];
	double currentMixTime = currentMixFrame / soundFormat.sampleRate;
	
	currentBufferSize = MIN(untilFrame - currentMixFrame, MIXING_BUFFER_SIZE);
	mixInBuffer = [[SndAudioBuffer alloc] initWithDataFormat: soundFormat.dataFormat
						    channelCount: soundFormat.channelCount
						    samplingRate: soundFormat.sampleRate
						      frameCount: currentBufferSize];
	
	// Retrieve each sound assigned to be mixed.
	for (soundNum = 0; soundNum < [noteTagsList count]; soundNum++) {
	    Snd *soundBeingMixed;
	    SndAudioBuffer *inBuffer;
	    NSRange inSoundRange; // where to retrieve a buffers worth *within* the sound.
	    long framesMixed;
	    SndAudioProcessorChain *soundProcessorChain;
	    SndAudioFader *premixAudioFader;
	    long soundDuration;
	    NSNumber *noteTagNumber = [noteTagsList objectAtIndex: soundNum];
	    
	    sampleToMix = (MKSamples *) [samplesToMix objectForKey: noteTagNumber];
	    soundBeingMixed = [sampleToMix sound];
	    soundProcessorChain = [sampleToMix audioProcessorChain];
	    
	    inSoundLastLocation = [sampleToMix processingEndSample];
	    soundDuration = inSoundLastLocation - [sampleToMix currentSample];
	    // Bound the sample of the Snd instance to read from within the sound's loop length.
	    inSoundRange.location = [sampleToMix currentSample] % [soundBeingMixed loopEndIndex];
	    // Size of remaining input data, capped at the maximum buffer size.
	    inSoundRange.length = MIN(soundDuration, currentBufferSize);
	    inLastBufferOfSound = inSoundRange.length < currentBufferSize;
	    // NSLog(@"sampleToMix %@ inSoundRange = (%d,%d)\n", sampleToMix, inSoundRange.location, inSoundRange.length);

	    inBuffer = [soundBeingMixed audioBufferForSamplesInRange: inSoundRange
							     looping: [soundBeingMixed loopWhenPlaying]];
	    
	    // Apply any signal processing, including amplitude envelopes to the buffer before mixing.
	    premixAudioFader = [soundProcessorChain postFader];
	    [premixAudioFader setAmp: [sampleToMix amplitude] clearingEnvelope: NO];
	    // Convert the bearing to a bipolar normalized balance between left and right channels.
	    [premixAudioFader setBalance: [sampleToMix panBearing] / 45.0 clearingEnvelope: NO];
	    [soundProcessorChain processBuffer: inBuffer forTime: currentMixTime];

	    // Now mix in the buffer.
	    framesMixed = [mixInBuffer mixWithBuffer: inBuffer];

#if 0
	    // Do any audio processing on the mix for example, the final or "mastering" volume.
	    [mixAudioFader setAmp: amplitude clearingEnvelope: NO];
	    [mixAudioFader setBalance: balance clearingEnvelope: NO];

	    [mixedProcessorChain processBuffer: mixInBuffer forTime: currentMixTime];
#endif	    
	    
	    if (inLastBufferOfSound) {      /* This sound's done. */
		[samplesToMix removeObjectForKey: noteTagNumber]; 
	    }
	    else
                [sampleToMix setCurrentSample: [sampleToMix currentSample] + ((inLastBufferOfSound) ? inSoundRange.length : currentBufferSize)];
	}
	// save away the mix to our final sound.
	// TODO, there could be scope to use SndExpt aka SndDiskBased to directly write the file.
	[sound appendAudioBuffer: mixInBuffer];
	currentMixFrame += currentBufferSize;
	[mixInBuffer release];
    }
    return self;
}

- (Snd *) mixedSound
{
    return [[sound retain] autorelease];
}

// This is called when performance is over.
- afterPerformance 
{
    if (sound == nil)  /* Did we ever receive any notes? */
	return self;
    [self mixToTime: MK_ENDOFTIME];
    return self;
}

- (BOOL) mixNewNote: (MKNote *) thisNote
{
    MKSamples *newSoundFileSamples = [[MKSamples alloc] init];
    double noteDuration, timeOffset;
    NSString *file = [thisNote parAsStringNoCopy: MK_filename];
    Snd *newSound;
    double resamplingFactor = 1.0;
    BOOL looping = currentlyLooping;
    double amp = defaultAmplitude;
    
    if (file == nil || ![file length]) { // Use default filename if not given as a parameter.
	file = defaultFile;
	NSLog(@"No input sound file specified, using default: %@.\n", file);
	return NO;
    }
    // TODO there is scope for optimization using SndTable names to look up existing (converted once sounds), rather than reading in each time.
    [newSoundFileSamples readSoundfile: file];
    // Establish an audio processing chain (including a fader) for signal processing each sound.
    [newSoundFileSamples setAudioProcessorChain: [SndAudioProcessorChain audioProcessorChain]];

    newSound = [newSoundFileSamples sound];
    if (!newSound) {
	NSLog(@"Can't find file %@.\n", file);
	return NO;
    }
    // NSLog(@"realize %@ at time %f ", thisNote, MKGetTime());

    if ([thisNote isParPresent: MK_amp])
	amp = [thisNote parAsDouble: MK_amp];
    if ([thisNote isParPresent: MK_velocity])
	amp *= MKMidiToAmpAttenuation([thisNote parAsInt: MK_velocity]);
    [newSoundFileSamples setAmplitude: [thisNote isParPresent: MK_amp] ? amp : defaultAmplitude];

    // Assign the current sample.
    if ([thisNote isParPresent: beginMixingAtParam]) {
	timeOffset = [thisNote parAsDouble: beginMixingAtParam];
	[newSoundFileSamples setCurrentSample: secondsToFrames(newSound, timeOffset)];
    }
    else
	[newSoundFileSamples setCurrentSample: 0];

    // Determine if this sound is to loop.
    if ([thisNote isParPresent: loopingParam])
	looping = [thisNote parAsInt: loopingParam];
    [newSound setLoopWhenPlaying: looping];
    
    // Assign the last sample processed.
    noteDuration = [thisNote dur];
    if (!MKIsNoDVal(noteDuration) && noteDuration != 0) {
	unsigned int noteDurationInFrames = secondsToFrames(newSound, noteDuration) + [newSoundFileSamples currentSample];
	unsigned int lastLocation = looping ? noteDurationInFrames : MIN([newSound lengthInSampleFrames], noteDurationInFrames);
	
	[newSoundFileSamples setProcessingEndSample: lastLocation];		
    }
    else
	[newSoundFileSamples setProcessingEndSample: [newSound lengthInSampleFrames]];
    if ([newSoundFileSamples currentSample] > [newSoundFileSamples processingEndSample] || noteDuration < 0 ) {
	NSLog(@"Warning: no samples to mix for this file.\n");
	return NO;
    }

    // Retrieves a bearing, being the pan (in degrees) of a mono sound from an idealised listener position, triangulated between two speakers.
    [newSoundFileSamples setPanBearing: [thisNote isParPresent: MK_bearing] ? [thisNote parAsDouble: MK_bearing] : defaultBearing];

    // freq0 is assumed old freq. freq1 is new freq.
    if ([thisNote isParPresent: MK_freq1] || [thisNote isParPresent: MK_freq0] ||
	[thisNote isParPresent: MK_keyNum] || defaultOriginalFrequency || defaultNewFrequency ||
	([newSound samplingRate] != soundFormat.sampleRate)) {
	double f0 = (([thisNote isParPresent: MK_freq0]) ? [thisNote parAsDouble: MK_freq0] : defaultNewFrequency);
	double f1 = (([thisNote isParPresent: MK_freq1]) ? [thisNote parAsDouble: MK_freq1] :
		     (([thisNote isParPresent: MK_keyNum]) ? [thisNote freq] : defaultOriginalFrequency));
	
	if ((f0 != 0.0 && f1 == 0.0) || (f1 != 0.0 && f0 == 0.0))
	    NSLog(@"Warning: Must specify both MK_freq0 and MK_freq1 if either are specified.\n");
	resamplingFactor = ((f1 && f0) ? (f0 / f1) : 1.0) * (soundFormat.sampleRate / [newSound samplingRate]);
	if ((resamplingFactor > 32) || (resamplingFactor < .03125))
	    NSLog(@"Warning: resampling more than 5 octaves.\n");
    }
    [newSound setConversionQuality: SndConvertHighQuality];
    [newSound convertToSampleFormat: soundFormat.dataFormat
		 samplingRate: (fabs(resamplingFactor - 1.0) > 0.0001) ? [newSound samplingRate] * resamplingFactor : [newSound samplingRate]
		 channelCount: soundFormat.channelCount];

    [samplesToMix setObject: newSoundFileSamples forKey: [NSNumber numberWithInt: [thisNote noteTag]]]; 
    [newSoundFileSamples autorelease]; // we are through with it, the samplesToMix will retain it as it needs.
    return YES;
}

- (BOOL) mixNoteUpdate: (MKNote *) noteReceived
{
    // Update the amplitude, bearing etc of the particular MKSample in the samplesToMix dictionary, using the noteTag as the key.
    MKSamples *sampleToModify = [samplesToMix objectForKey: [NSNumber numberWithInt: [noteReceived noteTag]]];
    
    if ([noteReceived isParPresent: MK_amp]) 
	[sampleToModify setAmplitude: defaultAmplitude = [noteReceived parAsDouble: MK_amp]]; 
    if ([noteReceived isParPresent: MK_bearing]) 
	[sampleToModify setPanBearing: defaultBearing = [noteReceived parAsDouble: MK_bearing]]; 
    if ([noteReceived isParPresent: MK_filename])
	defaultFile = [noteReceived parAsStringNoCopy: MK_filename];
    if ([noteReceived isParPresent: MK_freq1])
	defaultOriginalFrequency = [noteReceived parAsDouble: MK_freq1];
    if ([noteReceived isParPresent: MK_freq0])
	defaultNewFrequency = [noteReceived parAsDouble: MK_freq0];    
    return YES;
}

// Called when a new MKNote is received during performance.
- realizeNote: (MKNote *) noteReceived fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    MKNoteType type = [noteReceived noteType];
    
    [self mixToTime: MKGetTime()]; // Update the mix to the current time.
    if (!noteReceived)
	return self;
    switch (type) {
    case MK_noteOn:  // noteOn means a sound is to play it's full length.
    case MK_noteDur: // noteDur means new file with duration. We convert the format to match the output file.
	[self mixNewNote: noteReceived];
	break;
    case MK_noteUpdate: {
	[self mixNoteUpdate: noteReceived];
	break;
    }
    default: // do nothing with independent note offs
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

