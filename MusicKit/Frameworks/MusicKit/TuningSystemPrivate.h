/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.3  2000/10/01 06:55:48  leigh
  Properly typed function prototypes, added _MKKeyNumPrintfunc prototype.

  Revision 1.2  1999/07/29 01:25:58  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/04/23/90 - Created from _musickit.h 
*/
#ifndef __MK__TuningSystem_H___
#define __MK__TuningSystem_H___

/* Tuning system functions */
extern void _MKTuningSystemInit(void);
extern int _MKFindPitchVar(id aVar);

/* Writing frequencies */
extern BOOL _MKFreqPrintfunc(_MKParameter *param, NSMutableData *aStream, _MKScoreOutStruct *p);

// Writing keynumbers
extern BOOL _MKKeyNumPrintfunc(_MKParameter *param, NSMutableData *aStream, _MKScoreOutStruct *p);

#endif
