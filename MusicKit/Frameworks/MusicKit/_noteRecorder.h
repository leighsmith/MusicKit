/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:02  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/04/23/90 - Created from _musickit.h 
*/
#ifndef __MK__noteRecorder_H___
#define __MK__noteRecorder_H___

/* note recorder functions */
extern double _MKTimeTagForTimeUnit(id aNote,MKTimeUnit timeUnit,
				    BOOL compensateForDeltT);
extern double _MKDurForTimeUnit(id aNoteDur,MKTimeUnit timeUnit);



#endif
