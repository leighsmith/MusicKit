/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.5  2006/02/05 17:57:10  leighsmith
  Cleaned up prototypes for Xcode 2.2 as it is much more strict about mixing id with a defined type

  Revision 1.4  2005/04/15 04:18:25  leighsmith
  Cleaned up for gcc 4.0's more stringent checking of ObjC types

  Revision 1.3  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.2  1999/07/29 01:25:58  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__UnitGenerator_H___
#define __MK__UnitGenerator_H___

#import "MKUnitGenerator.h"

/* Unit Generator functions */
extern id _MKFixupUG(MKUnitGenerator *self, DSPFix48 *ts);
extern void _MKRerelocUG(MKUnitGenerator *self, MKOrchMemStruct *newReloc);
extern void _MKBeginUGBlock(id anOrch, BOOL adjustIt);
extern void _MKEndUGBlock(void);
extern void _MKAdjustTimeIfNecessary(void);

/* Synth Element functions (defined in MKUnitGenerator) */
extern void _MKDeallocSynthElement(SynthElement *synthEl, BOOL shouldReset);
extern void _MKDeallocSynthElementSafe(SynthElement *synthEl, BOOL lazy);
extern void _MKProtectSynthElement(SynthElement *dataObj, BOOL protectIt);
extern id _MKSetSynthElementSynthPatchLoc(SynthElement *synthEl, unsigned short loc);
extern unsigned _MKGetSynthElementSynthPatchLoc(SynthElement *synthEl);

@interface MKUnitGenerator(Private)

- (MKOrchMemStruct *) _getRelocAndClassInfo: (MKLeafUGStruct **) classInfoPtr;
- (MKOrchMemStruct *) _resources;
+ _allocFromList: (unsigned short) index;
+ _allocFirstAfter: (MKUnitGenerator *) anObj list: (unsigned short) index;
+ _allocFirstBefore: (MKUnitGenerator *) anObj list: (unsigned short) index;
+ _allocFirstAfter: (MKUnitGenerator *) anObj before: (MKUnitGenerator *) anObj2 list: (unsigned short) index;
+ (id) _newInOrch: (id) anOrch
	    index: (unsigned short) whichDSP 
            reloc: (MKOrchMemStruct *) reloc
	   looper: (unsigned int) looper;
- _free;
- _deallocAndAddToList;
- (MKOrchMemStruct *) _setSynthPatch: aSynthPatch;
- (void) _setShared: aSharedKey;
- (void) _addSharedSynthClaim;

@end



#endif
