/*
  $Id$
  Defined In: The MusicKit

  Description:
    Each MKSamplerInstrument holds a collection of sound files indexed by noteTag.
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
/*
  $Log$
  Revision 1.3  2000/03/11 01:16:21  leigh
  Now using NSSound to replace Snd

  Revision 1.2  1999/09/24 17:03:05  leigh
  Added documentation

*/
#ifndef __MK_SamplerInstrument_H___
#define __MK_SamplerInstrument_H___
#import <AppKit/NSSound.h>
#import "MKInstrument.h"
#import "MKConductor.h"

@interface MKSamplerInstrument: MKInstrument
    /* Plays sound files according to MIDI key numbers. */
{
    MKConductor *conductor;
    double volume;
    double pitchBend;
    double pbSensitivity;
    BOOL preloadingEnabled;
    id  preloadingSwitch;
    id  tieNotesSwitch;
    id  modeButtons;
    MKMsgStruct *startMessage, *stopMessage;
    char *directory;

    NSMutableDictionary *soundTable;
    int keyMap[128];
//    PlayingSound *playingSamples[128];
//    PlayingSound *playingSample;
    BOOL sustained[128];
    int activeVoices;
    double amp;
    double bearing;
    int testKey;
    double pitchbendSensitivity;
    id soundOutDevice;
    BOOL damperOn;
    double velocitySensitivity;

@public
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
    NSSound *recorder;
}

- init;
- abort;
- reset;
- (int) voiceCount;
- (void) setVoiceCount: (int) newVoiceCount;
- clearAll:sender;
- releaseSounds;
- prepareSound: (MKNote *) aNote;
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;
- (void) sound:(NSSound *) sound didFinishPlaying:(BOOL)aBool;
- (void) encodeWithCoder:(NSCoder *) coder;
- (id)initWithCoder:(NSCoder *) decoder;
@end


#endif
