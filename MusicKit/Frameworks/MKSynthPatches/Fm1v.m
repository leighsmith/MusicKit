/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/* This class is just like Fm1vi but overrides the interpolating osc
   with a non-interpolating osc. 

   Modification history:

   08/28/90/daj - Changed initialize to init.
   10/07/91/daj - Fixed possible bug in patchTemplateFor:
*/

#import <MusicKit/MusicKit.h>
#import <MusicKit/midi_spec.h>
#import <MKUnitGenerators/MKUnitGenerators.h>
#import "Fm1v.h"
#import "_Fm1i.h"
  
@implementation Fm1v

FMDECL(allVibTemplate,allVibUgs);
FMDECL(sinVibTemplate,sinVibUgs);
FMDECL(ranVibTemplate,ranVibUgs);
FMDECL(noVibTemplate,noVibUgs);

+patchTemplateFor: (MKNote *) aNote
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
	      allVibTemplate = _MKSPGetFmAllVibTemplate(&allVibUgs,
							[OscgafUGxxyy class]);
	    return allVibTemplate;
	}
	else if (rvibpc) {
	    if (!ranVibTemplate)
	      ranVibTemplate = _MKSPGetFmRanVibTemplate(&ranVibUgs,
						      [OscgafUGxxyy class]);
	    return ranVibTemplate;
	}
	else if (svibpc) {
	    if (!sinVibTemplate)
	      sinVibTemplate = _MKSPGetFmSinVibTemplate(&sinVibUgs,
						      [OscgafUGxxyy class]);
	    return sinVibTemplate;
	}
	else {
	    if (!noVibTemplate)
 	      noVibTemplate = _MKSPGetFmNoVibTemplate(&noVibUgs,
						      [OscgafUGxxyy class]);
	    return noVibTemplate;
	    
	}
    }
    if (!allVibTemplate)
      allVibTemplate = _MKSPGetFmAllVibTemplate(&allVibUgs,
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

