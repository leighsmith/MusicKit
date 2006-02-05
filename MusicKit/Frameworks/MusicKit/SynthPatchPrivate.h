/*
  $Id$
  Defined In: The MusicKit

  Description:

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/

#ifndef __MK__SynthPatch_H___
#define __MK__SynthPatch_H___

#import "MKSynthPatch.h"

/* MKSynthPatch functions and defines */
extern id _MKSynthPatchPreempt(MKSynthPatch *aPatch, id aNote, id controllers);
extern id _MKAddPatchToList(MKSynthPatch *synthP, MKSynthPatch **headP, MKSynthPatch **tailP, unsigned short listFlag);
extern id _MKSynthPatchSetInfo(MKSynthPatch *synthP, int aNoteTag, id synthIns);
extern id _MKSynthPatchNoteDur(MKSynthPatch *synthP, id aNoteDur, BOOL noTag);
extern void _MKSynthPatchScheduleNoteEnd(id synthP, double releaseDur);
extern id _MKRemoveSynthPatch(MKSynthPatch *synthP, MKSynthPatch **headP, MKSynthPatch **tailP, unsigned short listFlag);
extern void _MKReplaceFinishingPatch(MKSynthPatch *synthP, MKSynthPatch **headP, MKSynthPatch **tailP, unsigned short listFlag);
extern id _MKSynthPatchCmp();


#define _MK_IDLELIST 1
#define _MK_ACTIVELIST 2
#define _MK_ORCHTMPLIST 3
#define _MK_ORPHANLIST 4

@interface MKSynthPatch(Private)

+ _newWithTemplate: (id) aTemplate
 inOrch: (id) anOrch index: (int) whichDSP;
- _free;
- _preemptNoteOn: aNote controllers: controllers;
- _remove: aUG;
- _add: aUG;
- _prepareToFree: (MKSynthPatch **) headP : (MKSynthPatch **) tailP;
- _freeList: (MKSynthPatch *) head;
- (void) _freeList2;
- (void) _setShared: aSharedKey;
- (void) _addSharedSynthClaim;
- _connectContents;
- (void) _allocate;
- _deallocate;
- (BOOL) _usesEMem: (MKOrchMemSegment) segment;

@end

#endif
