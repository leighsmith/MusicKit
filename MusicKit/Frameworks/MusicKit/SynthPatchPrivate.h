/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/* 
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:25:58  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  1/24/90/daj - Flushed _preempted and _noteDurOff instance variables. 
  03/13/90/daj - Added private category.
*/
#ifndef __MK__SynthPatch_H___
#define __MK__SynthPatch_H___

#ifndef __SYNTHPATCH_H
#define __SYNTHPATCH_H

#import "MKSynthPatch.h"

/* SynthPatch functions and defines */
extern id _MKSynthPatchPreempt(id aPatch,id aNote,id controllers);
extern id _MKAddPatchToList(id self,id *headP,id *tailP,unsigned short listFlag);
extern id _MKSynthPatchSetInfo(id synthP, int aNoteTag, id synthIns);
extern id _MKSynthPatchNoteDur(id synthP,id aNoteDur,BOOL noTag);
extern void _MKSynthPatchScheduleNoteEnd(id synthP,double releaseDur);
extern id _MKRemoveSynthPatch(id synthP,id *headP,id *tailP,
			      unsigned short listFlag);
extern void _MKReplaceFinishingPatch(id synthP,id *headP,id *tailP,
				     unsigned short listFlag);
extern id _MKSynthPatchCmp();


#define _MK_IDLELIST 1
#define _MK_ACTIVELIST 2
#define _MK_ORCHTMPLIST 3
#define _MK_ORPHANLIST 4

@interface MKSynthPatch(Private)

+_newWithTemplate:(id)aTemplate
 inOrch:(id)anOrch index:(int)whichDSP;
-_free;
-_preemptNoteOn:aNote controllers:controllers;
-_remove:aUG;
-_add:aUG;
-_prepareToFree:(id *)headP :(id *)tailP;
-_freeList:head;
-(void)_freeList2;
-(void)_setShared:aSharedKey;
-(void)_addSharedSynthClaim;
-_connectContents;
-(void)_allocate;
-_deallocate;
-(BOOL)_usesEMem:(MKOrchMemSegment) segment;

@end

#endif



#endif
