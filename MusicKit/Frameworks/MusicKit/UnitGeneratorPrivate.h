#ifndef __MK__UnitGenerator_H___
#define __MK__UnitGenerator_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import "MKUnitGenerator.h"

/* Unit Generator functions */
extern id _MKFixupUG(id self,DSPFix48 *ts);
extern void _MKRerelocUG(id self,MKOrchMemStruct *newReloc);
extern void _MKBeginUGBlock(id anOrch,BOOL adjustIt);
extern void _MKEndUGBlock(void);
extern void _MKAdjustTimeIfNecessary(void);

/* Synth Element functions (defined in UnitGenerator) */
extern void _MKDeallocSynthElement(id synthEl,BOOL shouldReset);
extern void _MKDeallocSynthElementSafe(id synthEl,BOOL lazy);
extern void _MKProtectSynthElement(id dataObj,BOOL protectIt);
extern id _MKSetSynthElementSynthPatchLoc(id synthEl,unsigned short loc);
extern unsigned _MKGetSynthElementSynthPatchLoc(id synthEl);

@interface MKUnitGenerator(Private)
-(MKOrchMemStruct *) _getRelocAndClassInfo:(MKLeafUGStruct **)classInfoPtr;
-(MKOrchMemStruct *) _resources;
+_allocFromList:(unsigned short)index;
+_allocFirstAfter:anObj list:(unsigned short)index;
+_allocFirstBefore:anObj list:(unsigned short)index;
+_allocFirstAfter:anObj before:anObj2 list:(unsigned short)index;
+(id)_newInOrch:(id)anOrch index:(unsigned short)whichDSP 
 reloc:(MKOrchMemStruct *)reloc looper:(unsigned int)looper;
-_free;
-_deallocAndAddToList;
-(MKOrchMemStruct *)_setSynthPatch:aSynthPatch;
-(void)_setShared:aSharedKey;
-(void)_addSharedSynthClaim;

@end



#endif
