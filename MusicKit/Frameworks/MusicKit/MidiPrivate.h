#ifndef __MK__Midi_H___
#define __MK__Midi_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import "MKMidi.h"

#define _MK_MIDI_QUANTUM 1000 /* 1 ms */
#define _MK_MIDI_QUANTUM_PERIOD ((double)(1.0/((double)_MK_MIDI_QUANTUM)))

@interface MKMidi(Private)

-_alarm:(double)requestedTime;   
-_setSynchConductor:aCond;
+(BOOL)_disableThreadChange;
-_setMTCOffset:(double)offset;
-(double)_time;

@end


#endif
