#ifndef __MK_Simp_H___
#define __MK_Simp_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	Simp.h 

	This class is part of the Music Kit MKSynthPatch Library.
*/
#import <MusicKit/MKSynthPatch.h>
@interface Simp:MKSynthPatch
{
  double amp, freq, bearing, phase, velocitySensitivity;
  id waveform;
  int wavelen, volume, velocity;
  int pitchbend;
  double pitchbendSensitivity;  
}

+patchTemplateFor:aNote;
 

-noteOnSelf:aNote;
 

-noteUpdateSelf:aNote;
 

-(double)noteOffSelf:aNote;
 

-noteEndSelf;
 

@end

#endif
