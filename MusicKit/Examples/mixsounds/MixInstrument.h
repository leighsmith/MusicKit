#ifndef __MK_MixInstrument_H___
#define __MK_MixInstrument_H___
#import <musickit/Instrument.h>
#import <sound/soundstruct.h>

@interface MixInstrument:Instrument
{
    id SFInfoStorage;    /* Storage object of SFInfo structs */
    int curOutSamp;      /* Index of current output sample */
    double samplingRate; /* Output sampling rate */
    int channelCount;    /* Number of channels */
    SNDSoundStruct 
	*outSoundStruct; /* Output file SNDSoundStruct */
    NXStream *stream;    /* Output NXStream */
    double defaultAmp;   /* Default amplitude (set with no-tag noteUpdate) */
    double defaultFreq0;	/* default resampling factor numerator */
    double defaultFreq1;	/* default resampling factor denominator */
    char *defaultFile;		/* default sound file name */
    id defaultEnvelope;		/* default amplitude envelope */
    int defaultTimeScale; /* See README */
}

-setSamplingRate:(double)aSrate channelCount:(int)chans 
  stream:(NXStream *)aStream;
  /* Invoked once before performance from mixsounds.m. */

-init;

-firstNote:aNote;
  /* This is invoked when first note is received during performance */

-realizeNote:aNote fromNoteReceiver:aNoteReceiver;
  /* This is invoked when a new Note is received during performance */

-afterPerformance;
  /* This is invoked when performance is over. */

/* All other methods are private */

@end

#endif
