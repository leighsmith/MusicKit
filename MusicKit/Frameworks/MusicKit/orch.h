/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.6  2001/09/08 21:53:16  leighsmith
  Prefixed MK for UnitGenerators and SynthPatches

  Revision 1.5  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2001/07/02 16:59:08  sbrandon
  - commented out cruft after endif

  Revision 1.3  2000/02/03 19:12:23  leigh
  Renamed for MKDSP framework

  Revision 1.2  1999/07/29 01:26:12  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_orch_H___
#define __MK_orch_H___

#ifndef MK_ORCH_H
#define MK_ORCH_H

#import <MKDSP/dsp.h>             /* Contains DSPAddress, etc. */

typedef enum _MKOrchMemSegment { /* Memory segments for MKOrchestra */
    /* Memory segments may be on or off chip unless otherwise indicated */
    MK_noSegment = 0,            /* Illegal segment. */
    MK_pLoop,                    /* MKOrchestra loop P memory. */
    MK_pSubr,                    /* P subroutine memory (off-chip only) */
    MK_xArg,                     /* X argument memory. 
                                    (currently only on-chip) */
    MK_yArg,                     /* Y argument memory. 
                                    (currently only on-chip) */
    MK_lArg,                     /* L argument memory. (on-chip only) */
    MK_xData,                    /* X data memory (off-chip only) */
    MK_yData,                    /* Y data memory (off-chip only, except sin
                                    table rom) */
    MK_lData,                    /* L data memory (currently unused). */
    MK_xPatch,                   /* X patchpoints */
    MK_yPatch,                   /* Y patchpoints */
    MK_lPatch,                   /* L patchpoints (currently unused). */
    MK_numOrchMemSegments        /* End marker */ 
  } MKOrchMemSegment;

typedef struct _MKOrchMemStruct { /* Used to represent relocation as well
                     as memory usage of MKUnitGenerators. */ 
    unsigned xArg;   /* x unit generator memory arguments */
    unsigned yArg;   /* y */
    unsigned lArg;   /* l */
    unsigned pLoop;  /* program memory that's part of the main orch loop */
    unsigned pSubr;  /* program memory subroutines */ 
    unsigned xData;  /* Also used for xPatch memory */
    unsigned yData;  /* Also used for yPatch memory */
    unsigned lData;  /* Currently unused. */
} MKOrchMemStruct;

typedef struct _MKOrchAddrStruct { /* Used to represent orchestra addresses. */
    DSPAddress address;            /* Absolute address of symbol. */
    DSPMemorySpace memSpace;       /* In low-level DSP terms. */
    MKOrchMemSegment memSegment;   /* In higher-level MKOrchestra terms. */
    int orchIndex;                 /* Which DSP. */
} MKOrchAddrStruct;

typedef enum _MKSynthStatus { /* Status for MKSynthPatches and MKUnitGenerators. */
    MK_idle,                  /* Writing to sink (nowhere). */ 
    MK_running,               /* The meaning of this is defined by the ug */
    MK_finishing,             /* The meaning of this is defined by the ug */
  } MKSynthStatus;

#endif /* MK_ORCH_H */



#endif
