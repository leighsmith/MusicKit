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
    MKInstrument subclass to "realize MKNotes" in some novel fashion. In this
    case, MKNotes are soundfile mix specifications. They are "realized" by
    being mixed into the output file.

  Original Author: David A. Jaffe, with Michael McNabb adding the
    enveloping and pitch transposition, the latter based on code
    provided by Julius Smith. Incorporation into the MusicKit framework, conversion
    to OpenStep and the SndKit by Leigh M. Smith.

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001 The MusicKit Project.
*/
/*
Modification history:

 $Log$
 Revision 1.5  2001/09/20 01:41:55  leighsmith
 Typed parameters and added headerdoc comments

 Revision 1.4  2001/09/06 21:27:47  leighsmith
 Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

 Revision 1.3  2000/04/26 01:23:19  leigh
 Renamed to more meaningful samplesToMix ivar

 Revision 1.2  2000/04/20 21:34:53  leigh
 Replaced SFInfoStruct with expanded MKSamples, plugged memory leaks

 Revision 1.1  2000/04/16 21:18:36  leigh
 First version using SndKit incorporated into the MusicKit framework

*/
/*!
  @class MKMixerInstrument
  @abstract MKMixerInstrument mixes soundfiles based on a score description of the mix.
  @discussion
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
    MKInstrument subclass to "realize MKNotes" in some novel fashion. In this
    case, MKNotes are soundfile mix specifications. They are "realized" by
    being mixed into the output file.
*/
#ifndef __MK_MixerInstrument_H___
#define __MK_MixerInstrument_H___
#import "MKInstrument.h"
#import <SndKit/SndKit.h>

@interface MKMixerInstrument: MKInstrument
{
    NSMutableArray *samplesToMix;     /* Array of MKSamples to mix */
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

/*!
  @method setSamplingRate:channelCount:writingToStream:
  @param  aSrate is a double.
  @param  chans is an int.
  @param  aStream is an NSMutableData.
  @result Returns <b>self</b>.
  @discussion This method sets the sampling rate, number of audio channels and destination NSMutableData object
              to be used when mixing sounds. It should be invoked once before performance is started. 
*/
-setSamplingRate: (double) aSrate
    channelCount: (int) chans
 writingToStream: (NSMutableData *) aStream;

-init;

- (void) dealloc;

/*!
  @method firstNote:
  @param  aNote is an MKNote.
  @result Returns <b>self</b>.
  @discussion You do not normally call this method explictly. 
              It is invoked when first note is received during performance.
*/
-firstNote: (MKNote *) aNote;

/*!
  @method realizeNote:fromNoteReceiver:
  @param  aNote is an MKNote.
  @param  aNoteReceiver is an MKNoteReceiver.
  @discussion This is invoked when a new MKNote is received during performance to perform the mixing.
              You do not normally call this method explictly.
*/
-realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @method afterPerformance
  @result Returns <b>self</b>.
  @discussion You do not normally call this method explictly. 
              It is invoked when performance is over. 
*/
-afterPerformance;

/* All other methods are private */

@end

#endif
