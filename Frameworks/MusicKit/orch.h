/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005, The MusicKit Project.
*/
#ifndef __MK_orch_H___
#define __MK_orch_H___

#ifndef MK_ORCH_H
#define MK_ORCH_H

#import <MKDSP/dsp.h>             /* Contains DSPAddress, etc. */

/*!
  @file orch.h
 */

/*!
  @brief This enumeration specifies the memory segments supported by the
  MusicKit.  These memory segments are not necessarily contiguous on the
  DSP -- they are "logical" rather than "physical".
  Memory segments may be on or off chip unless otherwise indicated. 
 */
typedef enum _MKOrchMemSegment {
    MK_noSegment = 0,            /*!< Illegal segment. */
    MK_pLoop,                    /*!< MKOrchestra loop P memory. */
    MK_pSubr,                    /*!< P subroutine memory (off-chip only). */
    MK_xArg,                     /*!< X argument memory. (currently only on-chip) */
    MK_yArg,                     /*!< Y argument memory. (currently only on-chip) */
    MK_lArg,                     /*!< L argument memory. (on-chip only) */
    MK_xData,                    /*!< X data memory (off-chip only) */
    MK_yData,                    /*!< Y data memory (off-chip only, except sine table ROM) */
    MK_lData,                    /*!< L data memory (currently unused). */
    MK_xPatch,                   /*!< X patchpoints */
    MK_yPatch,                   /*!< Y patchpoints */
    MK_lPatch,                   /*!< L patchpoints (currently unused). */
    MK_numOrchMemSegments        /*!< End marker. */ 
} MKOrchMemSegment;

/*!
  @brief This struct specifies the memory segments required for a
  MKUnitGenerator.  It is also used to specify the relocation of a
  MKUnitGenerator.  The fields are as follows:
 */
typedef struct _MKOrchMemStruct {
    unsigned xArg;   /*!< X unit generator memory arguments */
    unsigned yArg;   /*!< Y unit generator memory arguments */
    unsigned lArg;   /*!< L unit generator memory arguments */
    unsigned pLoop;  /*!< Program memory that's part of the main orchestra loop. */
    unsigned pSubr;  /*!< Program memory subroutines (offchip). */ 
    unsigned xData;  /*!< X data memory. Also used for xPatch memory. */
    unsigned yData;  /*!< Y data memory.  Also used for yPatch memory. */
    unsigned lData;  /*!< Currently unused. */
} MKOrchMemStruct;

/*!
  @brief This struct fully-specifies an MKOrchestra (DSP) memory address.
 */
typedef struct _MKOrchAddrStruct {
    DSPAddress address;            /*!< Absolute address of symbol. */
    DSPMemorySpace memSpace;       /*!< Memory space, in low-level DSP terms. */
    MKOrchMemSegment memSegment;   /*!< Logical memory segment, in higher-level MKOrchestra terms. */
    int orchIndex;                 /*!< Which MKOrchestra (DSP). */
} MKOrchAddrStruct;

/*!
  @brief This enumeration specifies the status of MKUnitGenerator or MKSynthPatch objects.
  There are three possible values:
*/
typedef enum _MKSynthStatus {
    /*! Not in use.  Writing to sink (nowhere). */
    MK_idle,
    /*! In use.  Has not yet received <b>finish</b> or <b>noteOff</b> message. */
    MK_running,               /* The meaning of this is defined by the ug */
    /*! In final phase of operation, if any. Has received <b>finish</b> or <b>noteOff</b> message. */
    MK_finishing,             /* The meaning of this is defined by the ug */
} MKSynthStatus;

#endif /* MK_ORCH_H */

#endif
