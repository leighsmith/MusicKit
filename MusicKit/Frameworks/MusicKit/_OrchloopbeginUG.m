/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/*
  $Id$
  Original Author: David A. Jaffe
  
  Defined In: The MusicKit
  HEADER FILES: musickit.h
*/
/* 
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:00  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  11/10/89/daj - In order to implement filling up the sound out buffers
                 before starting to play, did the following:
		 Recompiled orchloopbeginIncludeUG.m. 
		 Added looper: argument to _setXArgsAddr:y:l:looper.
		 Added _unpause method. 
  03/13/90/daj - Changed name to _OrchloopbeginUG.
  04/23/90/daj - Got rid of instance variable and added arg to _pause:
                 to fix bug.
  04/25/90/daj - Changed arg order in calls to DSPWriteValue, to conform
                 with no libdsp api.
  05/01/90/jos - Removed "r" prefix from rData and rWordCount
  07/17/91/daj - Added setting of address of DSP_HM_SYSTEM_TICK_UPDATES;
*/
#import "_musickit.h"
#import "_OrchloopbeginUG.h"

@implementation _OrchloopbeginUG:MKUnitGenerator 
  /* See beg_orcl in dsp/smsrc/beginend.asm.  */ 

#import "orchloopbeginUGInclude.m"

#define LOOPER_JUMP(_arrSize) (_arrSize - 1)

+_setXArgsAddr:(int)xArgsAddr y:(int)yArgsAddr l:(int)lArgsAddr 
 looper:(int)looperWord
{
    MKLeafUGStruct *info = [self classInfo]; 
    DSPDataRecord *dRec = info->data[(int)DSP_LC_P]; 
    int *pData = dRec->data;         /* The data array */
    int arrSize = dRec->wordCount;   

#   define ADDR(_x) (_x << 8)
#   define UPDATE_SUBR_ADDR arrSize - 8
#   define XARG_ADDR arrSize - 6
#   define YARG_ADDR arrSize - 4
#   define LARG_MOVE arrSize - 3
#   define LMOVEOP ((unsigned)0x350000) /* Move of ADDR to register R_I2 (register 5) */

    /* Set location of tick subroutine */
    pData[UPDATE_SUBR_ADDR] = DSP_HM_SYSTEM_TICK_UPDATES;
    /* Fix up arg pointers */
    pData[XARG_ADDR] = xArgsAddr; 
    pData[YARG_ADDR] = yArgsAddr;

    pData[LARG_MOVE] = LMOVEOP | ADDR(lArgsAddr); 

    pData[LOOPER_JUMP(arrSize)] = looperWord; /* always loop back. */
    return self;
}

-_unpause
{
    MKLeafUGStruct *info = [self classInfo]; 
    DSPDataRecord *dRec = info->data[(int)DSP_LC_P]; 
    int arrSize = dRec->wordCount;   
    int address = LOOPER_JUMP(arrSize) + relocation.pLoop;
#   define NOOP 0x0      
    DSPWriteValue(NOOP,DSP_MS_P,address);
    return self;
}

-_pause:(int)looperWord
{
    MKLeafUGStruct *info = [self classInfo]; 
    DSPDataRecord *dRec = info->data[(int)DSP_LC_P]; 
    int arrSize = dRec->wordCount;   
    int address = LOOPER_JUMP(arrSize) + relocation.pLoop;
    DSPWriteValue(looperWord,DSP_MS_P,address);
    return self;
}

@end

