#ifndef __MK__noteRecorder_H___
#define __MK__noteRecorder_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*  Modification history:

    daj/04/23/90 - Created from _musickit.h 

*/
/* note recorder functions */
extern double _MKTimeTagForTimeUnit(id aNote,MKTimeUnit timeUnit,
				    BOOL compensateForDeltT);
extern double _MKDurForTimeUnit(id aNoteDur,MKTimeUnit timeUnit);



#endif
