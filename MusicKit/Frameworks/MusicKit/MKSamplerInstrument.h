#ifndef __MK_SamplerInstrument_H___
#define __MK_SamplerInstrument_H___
#import <MusicKit/MKInstrument.h>
#import <MusicKit/MKConductor.h>
#import <SndKit/Snd.h>
// #import "PlayingSound.h"

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
    Snd *recorder;
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
- (void) encodeWithCoder:(NSCoder *) coder;
- (id)initWithCoder:(NSCoder *) decoder;
@end


#endif
