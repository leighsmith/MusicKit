#ifndef __MK_DBWave2vi_H___
#define __MK_DBWave2vi_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	DBWave2vi.h 

	This class is part of the Music Kit MKSynthPatch Library.
*/
#import <MusicKit/MKSynthPatch.h>
@interface DBWave2vi:MKSynthPatch

{
  double amp0, amp1, ampAtt, ampRel, freq0, freq1, freqAtt, freqRel,
         bearing, phase, portamento, svibAmp0, svibAmp1, rvibAmp,
         svibFreq0, svibFreq1, velocitySensitivity, panSensitivity,
         waveformAtt, waveformRel, pitchbendSensitivity;
  id ampEnv, freqEnv, waveform0, waveform1, waveformEnv;
  int wavelen, volume, velocity, modwheel, pan, pitchbend;
  void *_ugNums;
}

+patchTemplateFor:aNote;
   

-noteOnSelf:aNote;
 

-noteUpdateSelf:aNote;
 

-(double)noteOffSelf:aNote;
 

-noteEndSelf;
 

@end

#endif
