#ifdef SHLIB
#include "shlib.h"
#endif

/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:10  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  01/08/90/daj - Added comments.
  30/08/91/daj - Added timeTag time unit support.
*/
#import "_musickit.h"
#import "timeunits.h"

/* This file implements the "NoteRecorder" functionality. Originally this
   was a class (subclass of Instrument) but since it does so little, it's
   now just a couple of functions. 

   The idea of this is to support both tempo-evaluated file writing and
   tempo-unevaluated file writing. Which is used depends on the value of
   an MKTimeUnit variable. See timeunits.h. */

double _MKTimeTagForTimeUnit(id aNote,MKTimeUnit timeUnit,BOOL compensateForDeltaT)
  /* Return value depends on the time unit. If time unit is MK_second, 
     returns [Conductor time]. Otherwise, returns [[aNote conductor] time].
     */
{
    double t;
    switch (timeUnit) {
      default:
      case MK_second: 
	t = MKGetTime();
	break;
      case MK_beat: {
	  id cond; 
	  cond = [aNote conductor];
	  if (cond) {
	      t = [cond time];
	      if (compensateForDeltaT)
		t -= MKGetDeltaT()/[cond beatSize]; 
	      /* This is only really correct if the tempo was constant during the
	       * last deltaT seconds. 
	       */
	      return t;
	  }
	  else t = MKGetTime();
      }
      case MK_timeTag:
	t = [aNote timeTag];
	break;
    }
    if (compensateForDeltaT)
      t -= MKGetDeltaT();
    return t;
}

double _MKDurForTimeUnit(id aNoteDur,MKTimeUnit timeUnit)
  /* Return value depends on the time unit. If time unit is MK_beat,
     this is the same as [aNoteDur dur]. Otherwise, returns 
     the dur predicted by aNoteDur's conductor. If aNoteDur is not of 
     type MK_noteDur, returns 0. */
{
    id aCond;
    double dur = [aNoteDur dur];
    if ([aNoteDur noteType] != MK_noteDur)
      return 0;
    if (timeUnit != MK_second)
      return dur;
    aCond = [aNoteDur conductor];
    if (!aCond)  
      return dur;
    return [aCond predictTime:[aCond time] + dur] - MKGetTime();
}

