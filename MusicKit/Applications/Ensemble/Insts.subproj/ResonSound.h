#ifndef __MK_ResonSound_H___
#define __MK_ResonSound_H___
#import <musickit/SynthPatch.h>

@interface ResonSound:SynthPatch
{
    /* Parameters to which this patch responds */
    double bearing;
    double amp1,amp0,ampAtt,ampRel;
    id ampEnv;
    double freq;
    id delayMem;
    double feedbackGain;
	double brightness;
	double inputGain;
    int velocity;     		/* MIDI velocity. Scaler on amplitude. */
    int pitchbend;    		/* MIDI pitchBend. Raises or lowers pitch. */
	int modwheel;	 		/* MIDI modwheel. Scaler on feedbackGain. */
	int aftertouch;	  		/* MIDI expression. Scaler on brightness. */
    int volume;       		/* MIDI volume pedal. Scaler on amplitude. */
    double velocitySensitivity;
    double pitchbendSensitivity;
    double modwheelSensitivity;
    double aftertouchSensitivity;
}

@end
#endif
