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
  Revision 1.13  2001/08/27 20:04:52  leighsmith
  Renamed the stop method to allNotesOff since this gives a clearer understanding of its function, better matches the behaviour of other MKInstruments and doesn't confuse against the stop method of MKMidi or MKOrchestra

  Revision 1.12  2001/04/23 21:17:45  leighsmith
  Removed unnecessary @public

  Revision 1.11  2001/04/20 02:53:25  leighsmith
  Revised to use stopInFuture: and SndPerformances for correct stopping and performance management

  Revision 1.10  2001/04/06 19:38:01  leighsmith
  Moved to use the SndKits playInFuture: method

  Revision 1.9  2000/07/22 00:31:17  leigh
  Reassert Snd as the one true way to deal with sound.

  Revision 1.8  2000/05/09 03:12:06  leigh
  Removed NSSound use and fully replaced with SndKit,\
   if necessary, SndKit will just become a wrapper around NSSound

  Revision 1.7  2000/04/22 20:12:42  leigh
  Now correctly checks the notes conductor for tempo

  Revision 1.6  2000/04/20 21:36:50  leigh
  Added removePreparedSounds to stop sound names growing unchecked

  Revision 1.5  2000/04/17 22:52:23  leigh
  Cleaned out some redundant stuff

  Revision 1.4  2000/04/12 00:36:28  leigh
  Hacked to use either SndKit or NSSound, depending on which is more complete on each platform, added uglySamplerTimingHack, hopefully this is only a momentary lapse of reason

  Revision 1.3  2000/03/11 01:16:21  leigh
  Now using NSSound to replace Snd

  Revision 1.2  1999/09/24 17:03:05  leigh
  Added documentation

*/
#ifndef __MK_SamplerInstrument_H___
#define __MK_SamplerInstrument_H___

#import <SndKit/SndKit.h>
#import "MKInstrument.h"

@interface MKSamplerInstrument: MKInstrument
{
@private
    double volume;
    double pitchBend;
    double pbSensitivity;
    BOOL preloadingEnabled;
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
    @method allNotesOff
    @result returns self
    @discussion Stop any playing (i.e. sounding) notes.
*/
- allNotesOff;
- reset;
- prepareSoundWithNote: (MKNote *) aNote;
- (void) removePreparedSounds;
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;
// Snd delegate
- (void) didPlay: (Snd *) sound duringPerformance: (SndPerformance *) performance;
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) decoder;
- performerDidDeactivate: (id) sender;
- performerDidActivate: (id) sender;

@end


#endif
