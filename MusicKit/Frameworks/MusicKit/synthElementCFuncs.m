/*
  $Id$
  Defined In: The MusicKit

  Description: Included by MKUnitGenerator.m
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:17  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  11/20/89/daj - Minor change to do lazy garbage collection of synth data. 
  04/21/90/daj - Changes to make compiler happy with -W switches on.
*/
#import "MKUnitGenerator.h" /* these 2 added by sb */
#import <objc/objc.h>

#define SynthElement MKUnitGenerator 
/* It's actually either MKUnitGenerator or MKSynthData, but this makes compiler 
   happy */

id _MKSetSynthElementSynthPatchLoc(SynthElement *synthEl,unsigned short loc)
    /* Used for cross-ref into SynthPatch location. */
{
    synthEl->_synthPatchLoc = loc;
    return synthEl;
}

unsigned _MKGetSynthElementSynthPatchLoc(SynthElement *synthEl)
    /* Used for cross-ref into SynthPatch location */
{
    return synthEl->_synthPatchLoc;
}

void _MKProtectSynthElement(SynthElement *synthEl,BOOL protectIt)
{
    synthEl->_protected = protectIt;
}    

static void doDealloc(SynthElement *synthEl,BOOL shouldIdle)
{
    if (shouldIdle)
      [synthEl idle];
    synthEl->synthPatch = nil;
    if (_MK_ORCHTRACE(synthEl->orchestra,MK_TRACEORCHALLOC))
        _MKOrchTrace(synthEl->orchestra,MK_TRACEORCHALLOC,"Deallocating %s", [[NSStringFromClass([synthEl class]) stringByAppendingFormat:@" 0x%x",synthEl] cString]);
		    /* [[synthEl name] cString]); */
    _MKOrchResetPreviousLosingTemplate(synthEl->orchestra);
    [synthEl _deallocAndAddToList];
}

void _MKDeallocSynthElementSafe(SynthElement *synthEl,BOOL lazy)
  /* Deallocates receiver and frees synthpatch of which it's a member, if any. 
   */
{
    if ((![synthEl isAllocated]) || (synthEl->_protected))
      return;
    if (synthEl->_sharedKey) {
	if (_MKReleaseSharedSynthClaim(synthEl->_sharedKey,lazy))
	  return;
	else synthEl->_sharedKey = nil;
    }
    if (synthEl->synthPatch) {
	if (![synthEl->synthPatch isFreeable])
	  return;
        else {
            [synthEl->synthPatch _free];
            [synthEl->synthPatch release];
            synthEl->synthPatch = nil;
        }
    }
    else {
	doDealloc(synthEl,YES);
    }
    return;
}


void _MKDeallocSynthElement(SynthElement *synthEl,BOOL shouldIdle)
  /* Deallocate a SynthElement. The SynthElement is not unloaded
     but is slated for possible garbage collection. */
{
    if (![synthEl isAllocated])
      return;
    doDealloc(synthEl,shouldIdle);
}

