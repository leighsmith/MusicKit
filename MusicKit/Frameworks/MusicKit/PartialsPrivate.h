#ifndef __MK__Partials_H___
#define __MK__Partials_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
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
