/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    MKMixerInstrument mixes soundfiles based on a score description of the mix. 
    It allows setting the amplitude scaling of each soundfile and to
    change that scaling over time by applying an amplitude envelope. It
    allows resampling (change the pitch of) a file.  It also allows
    you to specify that only a portion of a file be used in the mix.
    There is no limit to the number of soundfiles that may be mixed
    together. Also, the same soundfile may be mixed several times and may
    overlap with itself.  The soundfiles may have different sampling rates
    and different formats.  However, the output must be 16 bit linear.
    The mix is done on the main CPU, rather than the DSP.  The more files
    you mix, the longer it will take the program to run.  Note also that
    if you mix many large files, you will need a fair degree of swap
    space--keep some room free on the disk off of which you booted.

    MKMixerInstrument is also an illustration of how to make your own MusicKit
    MKInstrument subclass to "realize Notes" in some novel fashion. In this
    case, MKNotes are soundfile mix specifications. They are "realized" by
    being mixed into the output file.

  Original Author: David A. Jaffe, with Michael McNabb adding the
    enveloping and pitch transposition, the latter based on code
    provided by Julius Smith. Incorporation into the MusicKit framework, conversion
    to OpenStep and the SndKit by Leigh M. Smith.

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

 $Log$
 Revision 1.2  2000/04/20 21:34:53  leigh
 Replaced SFInfoStruct with expanded MKSamples, plugged memory leaks

 Revision 1.1  2000/04/16 21:18:36  leigh
 First version using SndKit incorporated into the MusicKit framework

*/
#ifndef __MK_MixerInstrument_H___
#define __MK_MixerInstrument_H___
#import "MKInstrument.h"
#import <SndKit/SndKit.h>

@interface MKMixerInstrument: MKInstrument
{
    NSMutableArray *SFInfoStorage;    /* Array of SFInfo structs each saved in an NSData instance */
    unsigned int curOutSamp;          /* Index of current output sample */
    double samplingRate;              /* Output sampling rate */
    int channelCount;                 /* Number of channels */
    SndSoundStruct *outSoundStruct;   /* Output file SndSoundStruct */
    Snd *sound;                       /* Output sound */
    NSMutableData *stream;            /* Output data stream (formatted as a .snd) */
    double defaultAmp;                /* Default amplitude (set with no-tag noteUpdate) */
    double defaultFreq0;	      /* default resampling factor numerator */
    double defaultFreq1;	      /* default resampling factor denominator */
    NSString *defaultFile;	      /* default sound file name */
    id defaultEnvelope;               /* default amplitude envelope */
    int defaultTimeScale;             /* See README */
}

/* To be invoked once before performance. */
-setSamplingRate: (double) aSrate
    channelCount: (int) chans
 writingToStream: (NSMutableData *) aStream;

-init;

- (void) dealloc;

-firstNote:aNote;
  /* This is invoked when first note is received during performance */

-realizeNote:aNote fromNoteReceiver:aNoteReceiver;
  /* This is invoked when a new Note is received during performance */

-afterPerformance;
  /* This is invoked when performance is over. */

/* All other methods are private */

@end

#endif
