#ifndef __MK_Preferences_H___
#define __MK_Preferences_H___
#import <appkit/Panel.h>

@interface Preferences:Panel
{
    const char *samplingRate;	/* Default sampling rate for new docs */
    const char *headroom;	/* Default orchestra headroom for new docs */
    const char *preemption;	/* Note preepmtion time for synthpatches */
    const char *deltaT;		/* Normal Music Kit deltaT */
    const char *fileDeltaT;	/* DeltaT when playing back files */
    const char *serialPort;	/* Serial port used for MIDI */
    const char *retainDSP;	/* Retain DSP when app is not the active app */
    const char *leader;		/* Time before first noteOn in score */
    const char *channel;        /* Channel for receiving program changes */
    const char *docDirectory;	/* Default document directory */
    const char *midiInit;	/* SysEx message sent when midi initialized */
    const char *multiThreaded;  /* Run multi-threaded */
    const char *midiTimedOutput;
    const char *soundBuffers;
    const char *scoresToMIDI;
	const char *sendRealTimeNotes;
	const char *soundOut;
	const char *serialDevice;
	const char *soundMax;
    id srateDisplayer;		/* Interface objects */
    id headroomDisplayer;
    id preemptionDisplayer;
    id deltaTDisplayer;
    id serialPortDisplayer;
    id retainDSPDisplayer;
    id leaderDisplayer;
    id channelDisplayer;
    id directoryDisplayer;
    id midiInitDisplayer;
    id multiThreadDisplayer;
    id midiTimedDisplayer;
    id buffersDisplayer;
    id scoresToMIDIDisplayer;
	id realTimeNotesDisplayer;
	id deviceDisplayer;
	id soundOutDisplayer;
	id soundMaxDisplayer;
}

- takeSamplingRateFrom:sender;
- takeHeadroomFrom:sender;
- takePreemptionTimeFrom:sender;
- takeDeltaTFrom:sender;
- takeSerialPortFrom:sender;
- takeRetainDSPFrom:sender;
- takeLeaderFrom:sender;
- takeChannelFrom:sender;
- takeDocDirectoryFrom:sender;
- takeMidiInitFrom:sender;
- takeMultiThreadedFrom:sender;
- takeMidiTimedFrom:sender;
- takeSoundBuffersFrom:sender;
- takeScoresToMIDIFrom:sender;
- takeRealTimeNotesFrom:sender;
- takeSerialDeviceFrom:sender;
- takeSoundOutFrom:sender;
- takeSoundMaxFrom:sender;

- (double)samplingRate;
- (double)headroom;
- (double)preemption;
- (double)deltaT;
- (double)fileDeltaT;
- (const char *)serialPort;
- (BOOL)retainDSP;
- (double)leader;
- (int)channel;
- (const char *)docDirectory;
- (const char *)midiInit;
- (BOOL)multiThreaded;
- (BOOL)midiTimedOutput;
- (BOOL)bigBuffers;
- (BOOL)scoresToMIDI;
- (BOOL)sendRealTimeNotes;
- (int)serialDevice;
- (BOOL)serialSoundOut;
- (int)soundMax;

- runModal:sender;
- ok:sender;
- cancel:sender;
- setSerialDevice;
@end


#endif
