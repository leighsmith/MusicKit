/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:25:58  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/04/23/90 - Created from _musickit.h 
*/
#ifndef __MK__TuningSystem_H___
#define __MK__TuningSystem_H___

/* Writing frequencies */
extern BOOL _MKFreqPrintfunc();

/* Tuning system functions */
extern void _MKTuningSystemInit();
extern int _MKFindPitchVar(id aVar);



#endif
