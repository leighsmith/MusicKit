/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    See the headerdoc description below.

  Original Author: David A. Jaffe, with Michael McNabb adding the
    enveloping and pitch transposition, the latter based on code
    provided by Julius Smith. Incorporation into the MusicKit framework, conversion
    to OpenStep and the SndKit by Leigh M. Smith.

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2004 The MusicKit Project.
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
    The more files you mix, the longer it will take the program to run.
    Note also that if you mix many large files, you will need a fair degree of swap
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
    /*! @var samplesToMix Dictionary of MKSamples to mix, keyed by noteTags */
    NSMutableDictionary *samplesToMix;
    /*! @var currentMixFrame Index of current output sample. */
    unsigned int currentMixFrame;
    /*! @var soundFormat The format for the final sound, (sample rate, channels, sample format). */
    SndFormat soundFormat;
    /*! @var sound Output sound */
    Snd *sound;                       
    /*! @var mixedProcessorChain A chain of SndAudioProcessing instances, including fader, applied after mixing all sounds. */
    SndAudioProcessorChain *mixedProcessorChain;
    /*! @var defaultAmplitude Default amplitude (set at the start of a MK_noteDur and modified with MK_noteUpdate) */
    double defaultAmplitude;
    /*! @var defaultBearing Default bearing in +/- degrees (set at the start of a MK_noteDur and modified with MK_noteUpdate) */
    double defaultBearing;
    /*! @var defaultNewFrequency Default resampling factor numerator. What the new frequency of the sample is desired to be. */
    double defaultNewFrequency;
    /*! @var defaultOriginalFrequency Default resampling factor denominator. What the original frequency of the sample is. */
    double defaultOriginalFrequency;
    /*! @var defaultFile Default sound file name */
    NSString *defaultFile;
    /*! @var defaultEnvelope Default amplitude envelope */
    id defaultEnvelope;
    /*! @var defaultTimeScale See README */
    int defaultTimeScale;
    /*! @var currentlyLooping Loop the sound if the duration exceeds the sounds length. */
    BOOL currentlyLooping;
}

/*!
  @method setSamplingRate:
  @abstract Sets the sampling rate to be used when mixing sounds.
  @discussion This method should be invoked once before performance is started. 
  @param  aSrate is a double.
 */
- (void) setSamplingRate: (double) aSrate;

/*!
  @method setChannelCount:
  @abstract Sets the number of audio channels to be used when mixing sounds.
  @discussion This method should be invoked once before performance is started. 
  @param  chans is an int.
 */
- (void) setChannelCount: (int) chans;

/*!
  @method mixedSound
  @abstract Returns the sound that has been mixed.
  @result Returns a Snd instance.
 */
- (Snd *) mixedSound;

/*!
  @method init
  @abstract Initializes the instance to 44.1KHz, 16 bit stereo file output.
 */
- init;

- (void) dealloc;

/*!
  @method firstNote:
  @param  aNote is an MKNote.
  @result Returns <b>self</b>.
  @discussion You do not normally call this method explictly. 
              It is invoked when first note is received during performance.
*/
- firstNote: (MKNote *) aNote;

/*!
  @method mixNewNote:
  @abstract Internal method to manage the reception of a new note.
  @discussion This method is not normally called, but may be overloaded by a subclass.
  @param thisNote An MKNote instance.
 */
- (BOOL) mixNewNote: (MKNote *) thisNote;

/*!
  @method mixNoteUpdate:
  @abstract Internal method to manage the reception of an update MKNote.
  @discussion This method is not normally called, but may be overloaded by a subclass.
  @param thisNote An MKNote instance.
 */
- (BOOL) mixNoteUpdate: (MKNote *) thisNote;

/*!
  @method realizeNote:fromNoteReceiver:
  @param  aNote is an MKNote.
  @param  aNoteReceiver is an MKNoteReceiver.
  @discussion This is invoked when a new MKNote is received during performance to perform the mixing.
              You do not normally call this method explictly. Each note is converted to a common format.
*/
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @method afterPerformance
  @result Returns <b>self</b>.
  @discussion You do not normally call this method explictly. 
              It is invoked when performance is over. 
*/
- afterPerformance;

@end

#endif
