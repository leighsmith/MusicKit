#ifndef __MK__SynthInstrument_H___
#define __MK__SynthInstrument_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import "MKSynthInstrument.h"

@interface MKSynthInstrument(Private)

-_repositionInActiveList:synthPatch template:patchTemplate;
-_deallocSynthPatch:aSynthPatch template:aTemplate tag:(int)noteTag;

@end



#endif
