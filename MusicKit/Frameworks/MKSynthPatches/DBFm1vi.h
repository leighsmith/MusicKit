#ifndef __MK_DBFm1vi_H___
#define __MK_DBFm1vi_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* 
	DBFm1vi.h 

	This class is part of the Music Kit MKSynthPatch Library.
*/
#import "Fm1vi.h"
#import <MusicKit/MKSynthData.h>

@interface DBFm1vi:Fm1vi
{
  double panSensitivity;
  double balanceSensitivity;
  MKWaveTable *waveform0;
  MKWaveTable *waveform1;
  int pan;
  int balance;
  MKSynthData *_synthData;
  DSPDatum *table;
  DSPDatum *_localTable;
}

/* All methods are inherited. */

@end

#endif
