#ifndef __MK_PlaySound_H___
#define __MK_PlaySound_H___
/* Obsolete.  Replaced by SamplerInstrument */

#import <musickit/Instrument.h>
#import "SoundPerformer.h"

@interface PlaySound:Instrument
{
    id  document;			/* The document */
    id  fileDisplayer;		/* The sound file name displayer */
    id  window;				/* the original IB window */
    id  view;				/* the content view */
    id  keyDisplayer;		/* The key number displayer */
    id  bearingDisplayer;
    id  ampDisplayer;
    id  pitchBendDisplayer;
    id  voiceCountDisplayer;
    int keyNum, testKey;	/* The current key number */
    BOOL damperOn;			/* State of damper pedal */
    float amp, bearing, volume, pitchBend;
	id conductor;
    MKMsgStruct *startMessage, *stopMessage;
    char *directory;
	id fileTable;
	id soundTable;
	int keyMap[128];
    SoundPerformer *performers[128];
    BOOL sustained[128];
    BOOL diatonic;
    BOOL tieRepeats;
    double pitchBendSensitivity;
    int voiceCount;
	int activeVoices;
    id parametersWindow;
    double velocitySensitivity;
	id velocityDisplayer;
}

- takeKeyFrom:sender;
- takeBearingFrom:sender;
- takeAmpFrom:sender;
- takePatchCountFrom:sender;
- takePitchBendFrom:sender;
- takeVelocityFrom:sender;
- takeDiatonicFrom:sender;
- takeTiesFrom:sender;
- addFile:sender;
- removeFile:sender;
- clearAll:sender;
- clearKey:sender;
- showParameters:sender;

@end


#endif
