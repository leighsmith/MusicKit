/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

#import <MusicKit/MusicKit.h>
#import <unitgenerators/unitgenerators.h>
#import "DBWave1v.h"
#import "_Wave1i.h"

@implementation DBWave1v
  /* Identical to DBWave1vi, but using non-interpolating oscillator
     See comments in DBWave1vi.h 

     Modification history:

     08/28/90/daj - Changed initialize to init.
     10/07/91/daj - Fixed possible bug in patchTemplateFor:

*/

WAVEDECL(allVibTemplate,allVibUgs);
WAVEDECL(sinVibTemplate,sinVibUgs);
WAVEDECL(ranVibTemplate,ranVibUgs);
WAVEDECL(noVibTemplate,noVibUgs);

+patchTemplateFor:aNote
    /* Creates and returns a patchTemplate which specifies the
       UnitGenerators and Patchpoints to be used and how they are
       to be interconnected when one of these synthPatches is
       instantiated.  Note that this method only creates the
       specification.  It does not actually instantiate anything.
    This MKSynthPatch has only one template, but could have variations
       which are returned according to the note parameter values.  */
{
  id oscClass = [OscgafUGxxyy class];
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
	allVibTemplate =_MKSPGetWaveAllVibTemplate(&allVibUgs,oscClass);
      return allVibTemplate;
    }
    else if (rvibpc) {
      if (!ranVibTemplate)
	ranVibTemplate = _MKSPGetWaveRanVibTemplate(&ranVibUgs,oscClass);
      return ranVibTemplate;
    }
    else if (svibpc) {
      if (!sinVibTemplate)
	sinVibTemplate = _MKSPGetWaveSinVibTemplate(&sinVibUgs,oscClass);
      return sinVibTemplate;
    }
    else {
      if (!noVibTemplate)
	noVibTemplate = _MKSPGetWaveNoVibTemplate(&noVibUgs,oscClass);
      return noVibTemplate;
    }
  }
  else {
    if (!allVibTemplate)
      allVibTemplate = _MKSPGetWaveAllVibTemplate(&allVibUgs,oscClass);
    return allVibTemplate;
  }
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
  else if (patchTemplate == noVibTemplate)
    _ugNums = &noVibUgs;
  return self;
}

@end

