#ifndef __MK_Pluck_H___
#define __MK_Pluck_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Pluck.h 

	This class is part of the Music Kit MKSynthPatch Library.
*/
#import <MusicKit/MKSynthPatch.h>

@interface Pluck:MKSynthPatch
{
    /* Here are the parameters. */
    double freq;                  /* Frequency.   */
    double sustain;               /* Sustain parameter value */
    double ampRel;                /* AmpRel parameter value.*/
    double decay;                 /* Decay parameter value. */
    double bright;                /* Brightness parameter value */
    double amp;                   /* Amplitude parameter value.   */
    double bearing;               /* Bearing parameter value. */
    double baseFreq;              /* Frequency, not including pitch bend  */
    int pitchBend;                /* Modifies freq. */
    double pitchBendSensitivity;  /* How much effect pitch bend has. */
    double velocitySensitivity;   /* How much effect velocity has. */
    int velocity;                 /* Velocity scales bright. */
    int volume;                   /* Midi volume pedal */
    id _reservedPluck1;
    id _reservedPluck2;
    int _reservedPluck3;
    void * _reservedPluck4;
}

+patchTemplateFor:currentNote;
-init;
-noteOnSelf:aNote;
-noteUpdateSelf:aNote;
-(double)noteOffSelf:aNote;
-noteEndSelf;
-preemptFor:aNote;

@end

#endif
