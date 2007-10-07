/*
  $Id$
  Defined In: The MusicKit

  Description:
    Each MKSamplePlayerInstrument holds a collection of sound files indexed by noteTag.
    A MKNote has a MK_filename parameter which is the soundfile to be played, together with any
    particular tuning deviation to be applied to it using a keynumber or frequency which forms a ratio
    from the unity key number located in the (AIFF or ?WAV?). That does imply being able to load the file
    immediately (within the Delta) for playback. But then, we should be spooling from disk anyway.

  Original Author: Leigh M. Smith <leigh@tomandandy.com>

  Copyright (c) 1999 tomandandy, Inc.
  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
#ifndef __MK_SamplerInstrument_H___
#define __MK_SamplerInstrument_H___

#import <SndKit/SndKit.h>
#import "MKInstrument.h"

@interface MKSamplePlayerInstrument: MKInstrument
{
@private
    double volume;
    double pitchBend;
    double pbSensitivity;
    BOOL preloadingEnabled;

    // TODO these are suspiciously GUI controls...
    id  preloadingSwitch;
    id  tieNotesSwitch;
    id  modeButtons;
    
    
    MKMsgStruct *startMessage, *stopMessage;
    char *directory;

    NSMutableDictionary *playingNotes;
    NSMutableArray *nameTable;
    BOOL sustained[128];
    int activeVoices;
    double amp;
    double bearing;
    int testKey;
    double pitchbendSensitivity;
    id soundOutDevice;
    BOOL damperOn;
    double velocitySensitivity;

    int voiceCount;
    int keyNum;					/* The current key number */
    BOOL diatonic;
    BOOL tieRepeats;
    float linearAmp;
	
    BOOL recordMode;
    int recordModeController;
    id recordModeInterface;
    int recordKey;
    int recordTag;
    Snd *recorder;
}

- init;
- abort;

/*!
  @return returns self
  @brief Stop any playing (i.e. sounding) notes.
*/
- allNotesOff;

- reset;
- prepareSoundWithNote: (MKNote *) aNote;
- (void) removePreparedSounds;
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

// Snd delegate methods
- (void) didPlay: (Snd *) sound duringPerformance: (SndPerformance *) performance;
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) decoder;
- performerDidDeactivate: (id) sender;
- performerDidActivate: (id) sender;

@end


#endif
