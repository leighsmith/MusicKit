////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//     MuLaw and ALaw functions taken from
//     libst.c - portable sound tools library more commonly known as Sox.
//
//  Original Author:
//    Craig Reese: IDA/Supercomputing Research Center
//
//
//  Copyright accompanying libst.h - include file for portable sound tools library
//
//  Copyright (C) 1989 by Jef Poskanzer.
//
//  Permission to use, copy, modify, and distribute this software and its
//  documentation for any purpose and without fee is hereby granted, provided
//  that the above copyright notice appear in all copies and that both that
//  copyright notice and this permission notice appear in supporting
//  documentation.  This software is provided "as is" without express or
//  implied warranty.
//
//  Portions Copyright (c) 1999, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#if HAVE_CONFIG_H
# include "SndKitConfig.h"
#endif

#define MINLIN -32768
#define MAXLIN 32767
#define LINCLIP(x) do { if ( x < MINLIN ) x = MINLIN ; else if ( x > MAXLIN ) x = MAXLIN; } while ( 0 )

/* These do not round data.  Caller must round appropriately. */


#ifdef FAST_ULAW_CONVERSION
extern int ulaw_exp_table[256];
extern unsigned char ulaw_comp_table[16384];
#define SndMuLawToLinear(ulawbyte) ulaw_exp_table[ulawbyte]
#define SndLinearToMuLaw(linearword) ulaw_comp_table[(linearword / 4) & 0x3fff]
#else

/*!
  @function SndLinearToMuLaw
  @abstract Converts a linear value to a uLaw compressed signal.
  @param linearValue
  @result
 */
SNDKIT_API unsigned char SndLinearToMuLaw(short linearValue);

/*!
  @function SndMuLawToLinear
  @abstract Converts a uLaw compressed signal to a linear value.
  @param mulawValue
  @result
 */
SNDKIT_API short SndMuLawToLinear(unsigned char mulawValue);

#endif

#ifdef FAST_ALAW_CONVERSION
extern int Alaw_exp_table[256];
extern unsigned char Alaw_comp_table[16384];
#define SndALawToLinear(Alawbyte) Alaw_exp_table[Alawbyte]
#define SndLinearToALaw(linearword) Alaw_comp_table[(linearword / 4) & 0x3fff]
#else

/*!
  @function SndLinearToALaw
  @abstract Converts a linear value to an ALaw compressed signal.
  @param linearValue
  @result
 */
SNDKIT_API unsigned char SndLinearToALaw(short linearValue);

/*!
  @function SndALawToLinear
  @abstract Converts an ALaw compressed signal to a linear value.
  @param alawbyte
  @result
 */
SNDKIT_API short SndALawToLinear(unsigned char alawbyte);

#endif
