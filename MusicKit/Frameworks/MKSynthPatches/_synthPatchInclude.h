/*
  $Id$
  
  Defined In: The MusicKit
  Description:
    (See discussion below)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
Modification history:

  $Log$
  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names


  09/19/89/daj - Changed macros to use Note C-function parameter access.
  10/3/93/daj -  Got rid of some unused macros (FREQ_SCALE, TWO_TO_M_23)
*/
#ifndef __MK__synthPatchInclude_H___
#define __MK__synthPatchInclude_H___

/* Various useful macros for SynthPatches. */

#import <string.h>

/* Global temporary variables */
extern int _MKSPiVal;
extern double _MKSPdVal;
extern id _MKSPoVal;
extern NSString *_MKSPsVal;

/* Macros for checking the validity of parameter values. I return 0 or 1
   so that these expressions can be bitwise-ored as well as used as boolean
   expressions. */

#define iValid(intPar) ((intPar) != MAXINT)
#define dValid(dblPar) (!MKIsNoDVal(dblPar))
#define oValid(objPar) ((objPar) != nil)
#define sValid(strPar) ((strPar) && [((NSString *)strPar) length])

/* Macros for retrieving parameter values */

#define doublePar(note,par,default) \
  (dValid (_MKSPdVal=MKGetNoteParAsDouble(note,par)) ? _MKSPdVal : default)
#define intPar(note,par,default) \
  (iValid (_MKSPiVal=MKGetNoteParAsInt(note,par)) ? _MKSPiVal : default)
#define envPar(note,par,default) \
  (oValid (_MKSPoVal=MKGetNoteParAsEnvelope(note,par)) ? _MKSPoVal : default)
#define wavePar(note,par,default) \
  (oValid (_MKSPoVal=MKGetNoteParAsWaveTable(note,par)) ? _MKSPoVal : default)
#define stringParNoCopy(note,par,default) \
  (sValid (_MKSPsVal=MKGetNoteParAsStringNoCopy(note,par)) ? _MKSPsVal : default)

/* The following macros first check if a parameter is present in the note.
   If so, they update a variable and return true. If not, they leave the
   variable alone and return false. */

#define updateDoublePar(note, par, var) \
  (dValid (dValid (_MKSPdVal=MKGetNoteParAsDouble(note,par)) ? (var=_MKSPdVal) : MK_NODVAL))
#define updateIntPar(note, par, var) \
  (iValid (iValid (_MKSPiVal=MKGetNoteParAsInt(note,par)) ? (var=_MKSPiVal) : MAXINT))
#define updateEnvPar(note, par, var) \
  (oValid (oValid (_MKSPoVal=MKGetNoteParAsEnvelope(note,par)) ? (var=_MKSPoVal) : nil))
#define updateWavePar(note, par, var) \
  (oValid (oValid (_MKSPoVal=MKGetNoteParAsWaveTable(note,par)) ? (var=_MKSPoVal) : nil))
#define updateStringParNoCopy(note, par, var) \
  (sValid (sValid (_MKSPsVal=MKGetNoteParAsStringNoCopy(note,par)) ? (var=_MKSPsVal) : @""))

#define updateFreq(note, var) \
  (dValid (dValid (_MKSPdVal=[note freq]) ? (var=_MKSPdVal) : MK_NODVAL))

#define volumeToAmp(vol) pow(10.,((double)vol-127.0)/64.0)

#endif
