/*
  $Id$
  
  Defined In: The MusicKit
  Description:

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
#ifndef __MK__Fm1i_H___
#define __MK__Fm1i_H___

#import "Fm1i.h"

typedef struct __MKSPFMNums {
  short ampUG, incUG, indUG, modUG, oscUG, outUG, svibUG, nvibUG, onepUG,
      vibAddUG, fmAddUG, mulUG, xsig, ysig;
} _MKSPFMNums;

/* Don't bother with prefix for macros since they're only in compile-time
   address space. */

#define FMDECL(_template,_struct) \
  static id _template = nil;\
  static _MKSPFMNums _struct = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}

#define FMNUM(ugname) (((_MKSPFMNums *)(_ugNums))->ugname)
//#define FMUG(ugname) NX_ADDRESS(synthElements)[FMNUM(ugname)]
#define FMUG(ugname) [synthElements objectAtIndex:FMNUM(ugname)]
#define _ugNums _reservedFm1i
#define MIDIVAL(midiControllerValue) \
  ((double)midiControllerValue)/((double)MIDI_MAXDATA)

extern id _MKSPGetFmNoVibTemplate(_MKSPFMNums *ugs,id oscClass);
extern id _MKSPGetFmAllVibTemplate(_MKSPFMNums *ugs,id oscClass);
extern id _MKSPGetFmRanVibTemplate(_MKSPFMNums *ugs,id oscClass);
extern id _MKSPGetFmSinVibTemplate(_MKSPFMNums *ugs,id oscClass);

@interface Fm1i(Private)

-(void)_setModWheel:(int)val;
-(void)_setSvibFreq0:(double)val;
-(void)_setSvibFreq1:(double)val;
-(void)_setSvibAmp0:(double)val;
-(void)_setSvibAmp1:(double)val;
-(void)_setRvibAmp:(double)val;
-(void)_setVibWaveform:(id)obj;
-(void)_setVib:(BOOL)setVibWaveform :(BOOL)setVibFreq :(BOOL)setVibAmp 
  :(BOOL)setRandomVib :(BOOL)newPhrase;
-_updateParameters:aNote;
-_setDefaults;

@end

#endif
