/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/* This class is just like Wave1vi but overrides the interpolating osc
   with a non-interpolating osc. */

/* Modification history:

   08/28/90/daj - Changed initialize to init.
   10/07/91/daj - Fixed possible bug in patchTemplateFor:
*/

#import <MusicKit/MusicKit.h>
#import <MusicKit/midi_spec.h>
#import <MKUnitGenerators/MKUnitGenerators.h>
#import "Wave1v.h"
#import "_Wave1i.h"
  
@implementation Wave1v

WAVEDECL(allVibTemplate,allVibUgs);
WAVEDECL(sinVibTemplate,sinVibUgs);
WAVEDECL(ranVibTemplate,ranVibUgs);
WAVEDECL(noVibTemplate,noVibUgs);

+patchTemplateFor:aNote
{
    if (aNote) {
        #define NON_ZERO_NUMBER 1
	double svibpc = (MKIsNoteParPresent(aNote,MK_svibAmp) ? 
			 MKGetNoteParAsDouble(aNote, MK_svibAmp) :
			 NON_ZERO_NUMBER);
	double rvibpc = (MKIsNoteParPresent(aNote,MK_rvibAmp) ? 
			 MKGetNoteParAsDouble(aNote, MK_rvibAmp) : 
			 NON_ZERO_NUMBER);
	if (svibpc && rvibpc) {
	    if (!allVibTemplate)
	      allVibTemplate = _MKSPGetWaveAllVibTemplate(&allVibUgs,
						      [OscgafUGxxyy class]);
	    return allVibTemplate;
	}
	else if (rvibpc) {
	    if (!ranVibTemplate)
	      ranVibTemplate = _MKSPGetWaveRanVibTemplate(&ranVibUgs,
						      [OscgafUGxxyy class]);
	    return ranVibTemplate;
	}
	else if (svibpc) {
	    if (!sinVibTemplate)
	      sinVibTemplate = _MKSPGetWaveSinVibTemplate(&sinVibUgs,
						      [OscgafUGxxyy class]);
	    return sinVibTemplate;
	}
	else {
	    if (!noVibTemplate)
 	      noVibTemplate = _MKSPGetWaveNoVibTemplate(&noVibUgs,
						      [OscgafUGxxyy class]);
	    return noVibTemplate;
	    
	}
    }
    if (!allVibTemplate)
      allVibTemplate = _MKSPGetWaveAllVibTemplate(&allVibUgs,
						[OscgafUGxxyy class]);
    return allVibTemplate;
}

-init
  /* Sent by this class on object creation and reset. */
{
    [super init];
    if (patchTemplate == allVibTemplate)
      _ugNums = &allVibUgs;
    else if (patchTemplate == ranVibTemplate)
      _ugNums = &ranVibUgs;
    else if (patchTemplate == sinVibTemplate)
      _ugNums = &sinVibUgs;
    else _ugNums = &noVibUgs;
    return self;
}

@end

