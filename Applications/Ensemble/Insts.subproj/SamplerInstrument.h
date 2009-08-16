#ifndef __MK_SamplerInstrument_H___
#define __MK_SamplerInstrument_H___
#import "EnsembleIns.h"
#import <musickit/Conductor.h>
#import "SoundPerformer.h"

@interface SamplerInstrument:EnsembleIns
    /* Plays sound files according to MIDI key numbers. */
{
	id  conductor;
    double volume;
	double pitchBend;
	double pbSensitivity;
	BOOL preloadingEnabled;
    id  voiceCountField;
    id  filenameField;			/* The sound file name displayer */
    id  keyInterface;				/* The key number displayer */
	id  preloadingSwitch;
	id  tieNotesSwitch;
	id  modeButtons;
    MKMsgStruct *startMessage, *stopMessage;
    char *directory;

	id soundTable;
	int keyMap[128];
    SoundPerformer *performers[128];
    BOOL sustained[128];
	int activeVoices;
@public
    int voiceCount;
    int keyNum;					/* The current key number */
	id fileTable;	
    BOOL diatonic;
    BOOL tieRepeats;
	float linearAmp;
	
	BOOL recordMode;
	int recordModeController;
	id recordModeInterface;
	int recordKey, recordTag;
	id recorder;
}

- abort;
- reset;
- takeKeyFrom:sender;
- takePatchCountFrom:sender;
- (int)patchCount;
- displayPatchCount;
- takeDiatonicFrom:sender;
- takePreloadingFrom:sender;
- takeTiesFrom:sender;
- setFile:(char *)filePath forKey:(int)key;
- mapKey:(int)key from:(int)minKey to:(int)maxKey;
- addFile:sender;
- fill:sender;
- removeFile:sender;
- clearAll:sender;
- clearKey:sender;
- initSoundTable;
- initPerformers;
- freeSounds;
- takeRecordControllerFrom:sender;

@end


#endif
