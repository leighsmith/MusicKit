/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:56  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__Partials_H___
#define __MK__Partials_H___

#import "MKPartials.h"

@interface MKPartials(Private)

-_writeBinaryScorefileStream:(NSMutableData *)aStream;
- _setPartialNoCopyCount: (int)howMany
  freqRatios: (short *)fRatios
  ampRatios: (float *)aRatios
  phases: (double *)phs
  orDefaultPhase: (double)defPhase;
- _normalize;

@end



#endif
