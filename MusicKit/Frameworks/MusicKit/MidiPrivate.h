/*
  $Id$
  Defined In: The MusicKit

  Description:
    Methods that never see the light of day.
    
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.3  2000/11/13 23:26:25  leigh
  Better documentation of _MK_MIDI_QUANTUM

  Revision 1.2  1999/07/29 01:25:53  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__Midi_H___
#define __MK__Midi_H___

#import "MKMidi.h"

#define _MK_MIDI_QUANTUM 1000 /* clock quantum ticks per 1 ms */
#define _MK_MIDI_QUANTUM_PERIOD ((double)(1.0/((double)_MK_MIDI_QUANTUM)))

@interface MKMidi(Private)

-_alarm:(double)requestedTime;   
-_setSynchConductor:aCond;
+(BOOL)_disableThreadChange;
-_setMTCOffset:(double)offset;
-(double)_time;

@end


#endif
