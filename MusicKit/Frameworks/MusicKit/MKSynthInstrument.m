/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/*
  SynthInstrument.m
  Responsibility: David A. Jaffe
  
  DEFINED IN: The Music Kit
  HEADER FILES: musickit.h
  */
/* 
Modification history:

  09/19/89/daj - Changed to use Note C functions for efficiency.
  12/15/89/daj - Changed _noteOffAndScheduleEnd: to noteOff:.
  12/18/89/daj - Added flushTimedMessages to setSynthPatchCount: (to fix 
                 bug (suggestion) 3132)
  12/22/89/daj - Added method forgetUpdates.
  12/22/89/daj - Added more allocation failure recovery logic. In particular,
                 it now tries to use a different template when it's losing.
		 (fix for bug (suggestion) 1617)
  01/09/90/daj - Fixed bug in findAltListRunningPatch
  01/24/90/daj - Changed _MKReplaceSynthPatch to _MKReplaceFinishingPatch.
  03/13/90/daj - Minor changes for new categories for private methods.
  03/17/90/daj - Moved _MKInheritsFrom to _musickit.h.
  03/19/90/daj - Added method to return note update and controllers state.
                 Changed to use MKGetNoteClass().
		 Added retainUpdates methods and instance var. Changed
		 forgetUpdates to clearUpdates.
  03/21/90/daj - Added archiving.
  03/22/90/daj - Changed setSynthPatchClass: to be a little more forgiving.
                 (It'll let you set the synthPatchClass if it's nil.)
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  07/23/90/daj - Added orchestra instance var for hand-allocated multi-DSP
                 allocation.
  08/13/90/daj - Added orchestra instance var init in awake method.
  08/23/90/daj - Changed to zone API.
  11/24/90/daj - Fixed bugs in preemption.
  12/19/90/daj - Fixed leak of _patchLists.
  02/20/91/daj - Made it possible to change synthpatch class during a 
                 performance.  Also added ability to do this and to 
		 change the synthpatch count from a scorefile during a 
		 performance.  Note that the manual/auto distinction still
		 cannot be changed during a performance.
  08/22/91/daj - Changed to new Storage API.
  11/17/92/daj - Added allNotesOff.  Also minor changes to shut up compiler warnings.
  11/28/96/daj - Minor optimization 
*/

#import <objc/Storage.h>
#import <objc/HashTable.h>

#import "_musickit.h"
#import "_error.h"
#import "MKSynthPatch.h" // @requires
#import "MKConductor.h" // @requires
#import "NotePrivate.h" // @requires
#import "OrchestraPrivate.h" // @requires
#import "MKUnitGenerator.h" // @requires

#import "SynthInstrumentPrivate.h"
/*@implementation SynthInstrument:Instrument */	/*sb: moved this declaration to after the other
						 * includes, as OpenStep doesn't seem to like
						 * having it this way.
/* Instances of the SynthInstrument class manage a collection of SynthPatches.
   The principal job of the SynthInstrument is to assign SynthPatches to 
   incoming Notes.

   A SynthInstrument can be in one of two modes, 'manual mode' or 'automatic
   mode'. 
   If the SynthInstrument is in automatic mode, Patches are allocated directly
   from the Orchestra as needed, then returned to the available pool, to be
   shared among all SynthInstruments. This is the default.
   If more Notes arrive than there are synthesizer resources,
   the oldest running Patch of this SynthInstrument is preempted 
   (the SynthPatch is sent the preemptFor:aNote message) 
   and used for the new Note. This behavior can be over-ridden for 
   an alternative "grab" strategy.

   If it is in manual mode,
   a fixed number of Patches are used over and over and you set the
   number of Patches managed. If more Notes arrive than there are Patches
   set aside, the oldest running Patch is preempted (the SynthPatch is 
   sent the preemptFor:aNote message) and used for the new Note. As above,
   this behavior can be over-ridden for an alternative "grab" strategy.   
   You can set the number of patches for each template.
   
   There is also a MK_MIXEDALLOC that allows manual allocation with the
   addition of "auto overflow".

   Each SynthInstrument instance supports patches of a particular SynthPatch 
   subclass. 

   Mutes Notes are ignored by SynthInstruments, with the exception of the
   special parameter synthPatchCount: and synthPatch:.
   */


#import "InstrumentPrivate.h"
/* Set of active SynthPatches but not including those 
   which had no noteTag. Hash from noteTag to patch. */


typedef struct {
	@defs (MKSynthPatch)
} synthPatchStruct;
#import "SynthPatchPrivate.h"

@implementation MKSynthInstrument:MKInstrument /*sb moved to here (see above) */
{
    id synthPatchClass; /* class used to create patches. */
    unsigned short allocMode;  /* One of MK_MANUALALLOC,
                                  MK_AUTOALLOC, or MK_MIXEDALLOC. */
    HashTable * taggedPatches;
    HashTable * controllerTable;
    id updates;
    BOOL retainUpdates;
    id orchestra;
    id _patchLists;
}

#define NEXT(_y) (((synthPatchStruct *)(_y))->_next)
// #define NEXTSP(_x) ((NEXT(_x) != _x) ? _x : nil)
#define NEXTSP(_x) (NEXT(_x))
/* Beware when using this macro! The list may be changed by your operation */

#define WILD (-1)

typedef struct _patchList {
    id idleNewest,idleOldest,activeNewest,activeOldest;
    int idleCount,totalCount,manualCount;
    id template;
} patchList; /* One of these for each template. */

#define PLISTSIZE	(sizeof(patchList))
#define PLISTDESCR @"{@@@@ii@}" 

static void CONSISTENCY_CHECK(patchList *aPatchList) {
    if (!((aPatchList->totalCount >= 0) && 
	  (aPatchList->totalCount >= aPatchList->manualCount) && 
	  (aPatchList->manualCount >= aPatchList->idleCount))) 
	fprintf(stderr,"SynthInstrument accounting problem.");
}

static patchList *getList(MKSynthInstrument *self,id template)
    /* Returns list matching template, else NULL. */
{
    /* Skip over the orphan list. */
    register patchList *tmp = (patchList *)[self->_patchLists elementAt:1];
    register patchList *last = tmp + [self->_patchLists count] - 1;
    while (tmp < last)
      if (tmp->template == template)
	return tmp;
      else tmp++;
    return NULL;
}

static patchList *addList(MKSynthInstrument *self,id template)
    /* adds list. Assumes it's not there. */
{
    patchList p = {nil,nil,nil,nil,0,0};
    p.template = template;
    [self->_patchLists insertElement:(char *)&p at:[self->_patchLists count]];
    return (patchList *)[self->_patchLists elementAt:
			 [self->_patchLists count]-1];
}

static patchList *findListWithIdlePatch(MKSynthInstrument *self)
{
    /* Skip orphan list */
    register patchList *tmp = (patchList *)[self->_patchLists elementAt:1];
    register patchList *last = tmp + [self->_patchLists count] - 1;
    while (tmp < last)
      if (tmp->idleOldest) 
	return tmp;
      else tmp++;
    return NULL;
}


#define VERSION2 2

static NSZone *zone; /* Cache zone for copying notes. */

#warning sb: "if subclass overrides this method, it must sent [super initialize]"

+ (void)initialize
{
    if (self != [MKSynthInstrument class])
      return;
    [MKSynthInstrument setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    zone = NSDefaultMallocZone();
    return;
}


static id initPatchLists(id oldLists)
    /* Frees oldLists and creates a new object to hold the lists. 
       Copies orphans if oldLists is non-nil. */
{
    /* Give them value to shut up compiler warning  */
    id activeOldest = NULL,activeNewest = NULL; 
    patchList p = {nil,nil,nil,nil,0,0};
    id newLists;
    if (oldLists) {
	patchList *orphanList;
	orphanList = (patchList *)[oldLists elementAt:0];
	activeOldest = orphanList->activeOldest;
	activeNewest = orphanList->activeNewest;
    } 
    [oldLists release];           /* Flush patch lists */
    newLists = 
	[Storage newCount:0 elementSize:PLISTSIZE description:[PLISTDESCR cString]];
    if (oldLists) {
	p.activeNewest = activeNewest;
	p.activeOldest = activeOldest;
    }
    [newLists insertElement:(char *)&p at:0];
    return newLists;
}
-retain
{ return [super retain];
}
-(oneway void)release
{
      /* Frees the receiver. It is illegal to send this message to a
         SynthInstrument which is in performance. Returns self in this case,
         otherwise nil. */
       /*  sb: here, this was a -free method. Had to jump through hoops to get
    the object to dealloc, since a retain is held by an array by MKOrchestra.
    */

    if (_noteSeen) /*sb: this is a problem. there's no good way to signal that we don't want to release. FIXME */
        return;
    if ([self retainCount] == 2) {
        [self abort];
        [updates release];
        [controllerTable free];//sb: free these 2 because they are old-style hashtables
        [taggedPatches free];
        [_patchLists release];
        [super release]; /* release the "alloc" copy */
        _MKOrchRemoveSynthIns(self); /* release the "array" copy, which will now dealloc */
    }
    else [super release];
}

-init
  /* Does instance initialization. Sent by superclass on creation. 
     If subclass overrides this method, it must send [super initialize]
     before setting its own defaults. */
{
    _MKLinkUnreferencedClasses([MKSynthPatch class]);
    [super init];
    _patchLists = initPatchLists(nil);
    taggedPatches = [HashTable newKeyDesc:"i"];
    controllerTable = [HashTable newKeyDesc:"i" valueDesc:"i"];
    [self addNoteReceiver:[MKNoteReceiver new]];
    updates = [MKGetNoteClass() new];  /* For remembering partUpdate 
				parameter values on this channel. */
    [updates setNoteType:MK_noteUpdate];
    _MKOrchAddSynthIns(self);
    orchestra = _MKClassOrchestra();
    return self;
}

- copyWithZone:(NSZone *)zone
  /* Returns a copy of the receiver. The copy has the same connections but
     has no synth patches allocated. */
{
    MKSynthInstrument *newObj = [super copyWithZone:zone];
    newObj->_patchLists = 
      [Storage newCount:0 elementSize:PLISTSIZE description:[PLISTDESCR cString]];
    newObj->taggedPatches = [HashTable newKeyDesc:"i"];
    newObj->controllerTable = [HashTable newKeyDesc:"i" valueDesc:"i"];
    newObj->updates = [MKGetNoteClass() new];  
    /* For remembering no-tag noteUpdate parameter values on this channel. */
    [newObj->updates setNoteType:MK_noteUpdate];
    _MKOrchAddSynthIns(newObj);
    return newObj;
}

-setRetainUpdates:(BOOL)yesOrNo
{
    retainUpdates = yesOrNo;
    return self;
}

-(BOOL)doesRetainUpdates
{
    return retainUpdates;
}

-preemptSynthPatchFor:aNote patches:firstPatch
  /* You never send this message. Rather, 
     this method is invoked when we are in manual allocation mode and 
     all SynthPatches are in use or we are in auto allocation mode
     and no more DSP resources are available. The default implementation
     returns the Patch with the appropriate template whose phrase began the 
     earliest  (This is the same value returned by the method -activeSynthPatches:.)

     You may override this method to provide a different scheme for 
     determining which Patch to grab. For example, you might want to
     grab the quietest Patch. To do this, you need to examine the currently
     running patches and choose one. (see -activeSynthPatches: below).
     The subclass may return nil to signal that the new Note should be
     omitted. It is illegal to return a patch which is not a member of the
     active patch list.
     
     The subclass should not send the 
     preemptFor: message to the patch. This is done automatically for you.
     */	
{
    return firstPatch;
}

-activeSynthPatches:aTemplate
  /* Returns the first in the list of patches currently sounding with the
     specified template. If aTemplate is nil, 
     [synthPatchClass defaultPatchTemplate] is used.
     The list is ordered by when the phrase began, from the earliest to
     the latest. In addition, all finishing SynthPatches are before all
     running ones. You step down the list by sending the -next message to
     each patch. Returns nil if there are no patches sounding with that
     template. */
{
    patchList *p;
    if (!aTemplate)
      aTemplate = [synthPatchClass defaultPatchTemplate];
    p = getList(self,aTemplate);
    if (p)
      return p->activeOldest;
    return nil;
}

-mute:aMute
  /* This method is invoked when a Note of type mute is received.
     Notes of type mute are not sent to SynthPatches because they do not deal 
     directly with sound production. The default implementation does
     nothing. A subclass may implement this 
     method to look at the parameters of aMute and perform some appropriate
     action. 

     */
{
    return self;
}

static NSString *tagStr(int noteTag)
{
    if (noteTag == MAXINT)
      return @"<none>";
    return _MKIntToStringNoCopy(noteTag);
}

static id adjustRunningPatch(MKSynthInstrument *self,int newNoteTag,id aNote,
			     id *currentPatch,patchList *aPatchList,
			     MKPhraseStatus *phraseStatus)
    /* This function returns self almost all the time. The exception is 
       when the preemption happens right now and the SynthPatch noteOn
       method aborts. */
/* RETURNS RETAINED *currentPatch OBJECT */
{
    int oldNoteTag = [*currentPatch noteTag];
    id tempPatch;
    [*currentPatch retain]; /* so we don't lose it in next line */
    /* we keep it retained, and return it that way */
    _MKRemoveSynthPatch(*currentPatch, 
			&aPatchList->activeNewest,
			&aPatchList->activeOldest,
			_MK_ACTIVELIST);
    if (oldNoteTag != MAXINT) 
      [self->taggedPatches removeKey:(const void *)oldNoteTag];
    _MKSynthPatchSetInfo(*currentPatch,newNoteTag,self);
    /* This function returns self almost all the time. The exception is 
       when the preemption happens right now and the SynthPatch noteOn
       method aborts. */
    tempPatch = *currentPatch;
    if (!(*currentPatch = _MKSynthPatchPreempt(*currentPatch,aNote,self->controllerTable))) {
        [tempPatch release]; /* I release the old one here if I can't preempt. Maybe bug */
	return nil;
    }

    if (MKIsTraced(MK_TRACESYNTHINS) ||
	MKIsTraced(MK_TRACEPREEMPT))
      fprintf(stderr,
	      "SynthInstrument preempts patch %d at time %f "
	      "for tag %s.\n",
	      (int)*currentPatch,MKGetTime(),[tagStr(newNoteTag) cString]);
    *phraseStatus = MK_phraseOnPreempt;
    return self;
}

static id findAltListRunningPatch(MKSynthInstrument *self,id aNote,patchList **aPatchList)
{
    /* Skip orphan list */
    register patchList *tmp = (patchList *)[self->_patchLists elementAt:1];
    register patchList *last = tmp + [self->_patchLists count] - 1;
    id currentPatch;
    while (tmp < last) {
	if (tmp != *aPatchList)
	  if (tmp->activeOldest) { /* don't bother if there's no patches */
	      currentPatch = [self preemptSynthPatchFor:aNote patches:
			      tmp->activeOldest];
	      if (currentPatch) {
		  *aPatchList = tmp;
		  return currentPatch;
	      } 
	  }
	tmp++;
    }
    return nil;
}

static id adjustIdlePatch(patchList *aPatchList,int noteTag)
/*NB RETURNS RETAINED OBJECT*/
{
    id currentPatch = aPatchList->idleOldest;
    if (!currentPatch) 
      return nil;
    [currentPatch retain];
    _MKRemoveSynthPatch(currentPatch,
			&aPatchList->idleNewest,
			&aPatchList->idleOldest,
			_MK_IDLELIST);
    aPatchList->idleCount--;
    CONSISTENCY_CHECK(aPatchList);
    if (MKIsTraced(MK_TRACESYNTHINS))
      fprintf(stderr,
	      "SynthInstrument uses patch %d at time %f "
	      "for tag %s.\n",
	      (int)currentPatch,MKGetTime(),[tagStr(noteTag) cString]);
    return currentPatch;
}

static void alternatePatchMsg(void)
{
    fprintf(stderr,"(No patch of requested template"
	    "was available. Using alternative template.");
}

-realizeNote:aNote fromNoteReceiver:aNoteReceiver
  /* Does SynthPatch allocation. 
     
     The entire algorithm is given below. The new steps are so-indicated:
     
     MANUAL:
     1m	Look for idle patch of correct template.
     2m	Else try and preempt patch of correct template.
     3m	Else look for idle patch of incorrect template.
     4m	Else try and preempt patch of incorrect template.
     5m	Else give up.
     
     AUTO
     1a	Try to alloc a new patch of correct template.
     2a	Else try and preempt patch of correct template.
     3a	Else try and preempt patch of incorrect template.
     4a	Else give up.

     MIXED
     Same as MANUAL, except for the insertion of step 1m+ after 1m:
     1m+ Try to alloc a new patch of correct template.

     */
{
    int noteTag;
    id currentPatch;
    MKNoteType curNoteType;
    if (!aNote)
      return nil;
    noteTag = [aNote noteTag];
    curNoteType = [aNote noteType];

    if (noteTag != MAXINT)       
      currentPatch =  (id)[taggedPatches valueForKey:(const void *)noteTag];
    else switch(curNoteType) {
      case MK_noteDur:
      case MK_noteUpdate:
 	currentPatch = nil;
	break;
      case MK_mute:
	if (MKIsTraced(MK_TRACESYNTHINS))
	  fprintf(stderr,
		  "SynthInstrument receives mute Note at time %f.\n",
		  MKGetTime());
	if (MKIsNoteParPresent(aNote,MK_synthPatch)) {
	    NSString *sp = [aNote parAsStringNoCopy:MK_synthPatch];
//	    if (*sp != '\0') {
	    if (sp != nil) {
                if ([sp length]) {
                    id aClass = [MKSynthPatch findSynthPatchClass:sp];
                    if (aClass)
                        [self setSynthPatchClass:aClass];
                    }
	    }
	}
	if (MKIsNoteParPresent(aNote,MK_synthPatchCount)) 
	    [self setSynthPatchCount:[aNote parAsInt:MK_synthPatchCount]
	     patchTemplate:[synthPatchClass patchTemplateFor:aNote]];
 	[self mute:aNote];
	/* no break here. */
      default:       /* NoteOn or noteOff with no tag or a mute (ignored) */
	return nil;
    }

    switch (curNoteType) {
      case MK_noteDur:
      case MK_noteOn: {
	  MKPhraseStatus phraseStatus;
	  if (currentPatch) {/* We have an active patch already for this tag */
	      phraseStatus = MK_phraseRearticulate;
	      if (MKIsTraced(MK_TRACESYNTHINS))
		fprintf(stderr,
			"SynthInstrument receives note for active notetag "
			"stream %s at time %f.\n",[tagStr(noteTag) cString],MKGetTime());
	  }
	  else {  /* It is a new phrase. */
	      id aTemplate;
	      patchList *aPatchList;
	      phraseStatus = MK_phraseOn;
	      aNote = [aNote copyWithZone:zone];
	      /* Copy common updates into aNote. */
	      aNote = [aNote _unionWith:updates];
	      aTemplate = [synthPatchClass patchTemplateFor:aNote];
	      aPatchList = getList(self,aTemplate);
	      if (!aPatchList)
		aPatchList = addList(self,aTemplate);
              if (MKIsTraced(MK_TRACESYNTHINS))
		fprintf(stderr,
			"SynthInstrument receives note for new notetag stream "
			"%s at time %f ",[tagStr(noteTag) cString],MKGetTime());
	      switch (allocMode) {
		case MK_MIXEDALLOC:
		  currentPatch = adjustIdlePatch(aPatchList,noteTag);
                    /*NB RETURNS RETAINED OBJECT*/
		  if (currentPatch)
		      break;
		  /* else fall through here. */
		case MK_AUTOALLOC: 
		  currentPatch = 
		      [orchestra allocSynthPatch:
		       synthPatchClass patchTemplate:aTemplate];
		  if (currentPatch) {
		      aPatchList->totalCount++;
		      CONSISTENCY_CHECK(aPatchList);
		      if (MKIsTraced(MK_TRACESYNTHINS))
			  fprintf(stderr,
				  "SynthInstrument assigns patch %d at "
				  "time %f for tag %s.\n",
				  (int)currentPatch,MKGetTime(),[tagStr(noteTag) cString]);
		  }
		  break;
		case MK_MANUALALLOC:
		  currentPatch = adjustIdlePatch(aPatchList,noteTag);
                    /*NB RETURNS RETAINED OBJECT*/
		  break;
	      }
	      if (currentPatch)
		  _MKSynthPatchSetInfo(currentPatch,noteTag,self);
	      else  { /* Allocation failure */
		  /* Find a preemption candidate */
		  currentPatch = [self preemptSynthPatchFor:aNote patches:
				  aPatchList->activeOldest]; /* not retained yet */
		  /* Try to preempt */
		  if (!(currentPatch && 
			adjustRunningPatch(self,noteTag,aNote,&currentPatch,
					   aPatchList,&phraseStatus))) {
                      /* RETURNS RETAINED *currentPatch OBJECT */
		      /* Try and use a patch of a different template */
		      if (allocMode != MK_AUTOALLOC) {
			  aPatchList = findListWithIdlePatch(self);
			  if (aPatchList) {
			      currentPatch = adjustIdlePatch(aPatchList,
							     noteTag);
                              /*NB RETURNS RETAINED OBJECT*/
			      if (currentPatch) {
				  if (MKIsTraced(MK_TRACESYNTHINS))
				      alternatePatchMsg();
				  _MKSynthPatchSetInfo(currentPatch,noteTag,
						       self);
			      }
			  }
		      }
		      /* CurrentPatch can be nil if allocMode is AUTO or
			 if there was no idle patch */
		      if (!currentPatch) { /* Keep trying */
			  currentPatch =
                             findAltListRunningPatch(self,aNote,&aPatchList);/* not retained yet */
			  if (currentPatch &&
			      adjustRunningPatch(self,noteTag,aNote,
						 &currentPatch,
						 aPatchList,
						 &phraseStatus)) {
                              /* RETURNS RETAINED *currentPatch OBJECT */
			      if (MKIsTraced(MK_TRACESYNTHINS))
				  alternatePatchMsg();
			  }
			  else { /* Now we give up. */
			      if (MKIsTraced(MK_TRACESYNTHINS) ||
				  MKIsTraced(MK_TRACEPREEMPT)) 
				  fprintf(stderr,
					  "SynthInstrument omits note at time %f "
					  "for tag %s.\n",
					  MKGetTime(),[tagStr(noteTag) cString]);
			      _MKErrorf(MK_synthInsOmitNoteErr,MKGetTime());
			      [aNote release];
			      return nil;
			  }
		      }
                  } /* currentPatch should be valid and retained by now */
	      }
	      /* We're ok if we made it to here. */
	      _MKAddPatchToList(currentPatch,&aPatchList->activeNewest,
				&aPatchList->activeOldest,_MK_ACTIVELIST);
    		[currentPatch release]; /* since we had received a retained patch */
	      /* Add to taggedPatchSet. */
	      if (noteTag != MAXINT) 
		[taggedPatches insertKey:(const void *)noteTag value:
		 (void *)currentPatch];
	      if (phraseStatus == MK_phraseOnPreempt)
		return self;
	      [currentPatch controllerValues:controllerTable];
	  } 
	  if (![currentPatch noteOn:aNote]) { /* Synthpatch abort? */
	      if (phraseStatus == MK_phraseOn)
		[aNote release];
	      return nil;
	  }
	  if (curNoteType == MK_noteDur) 
	    _MKSynthPatchNoteDur(currentPatch,aNote,
				 (noteTag == MAXINT) ? YES : NO);
	      /* If noteTag is MAXINT, the patch is not addressable. 
		 Therefore, the SynthPatch need not go through the
		 SynthInstrument for it's auto-generated noteOff and 
		 can handle the noteOff: message itself. */
	  if (phraseStatus == MK_phraseOn)
	    [aNote release];
	  return self;
      }
      case MK_noteUpdate:
	if (noteTag == MAXINT) { /* It's a broadcast */ 
	    register patchList *tmp;
	    register patchList *last;
	    for (tmp  = (patchList *)[_patchLists elementAt:0],

		 last = tmp + [_patchLists count];
		 (tmp < last);
		 tmp++) {
		currentPatch = tmp->activeOldest;
		if (currentPatch) 
		  do {
		      [currentPatch noteUpdate:aNote];
		  } while(currentPatch = NEXTSP(currentPatch)); 
	    }
	    /* Now save the parameters in a note in updates so 
	       that new  notes on this channel can be inited properly. */
	    [updates copyParsFrom:aNote];
	    {
		/* Control change has to be handled separately, since there
		   can be several values that all need to be maintained. Sigh.
		   */
		int controller = MKGetNoteParAsInt(updates,MK_controlChange);
		int controlVal;
		if (controller != MAXINT) {
		    controlVal = MKGetNoteParAsInt(updates,MK_controlVal);
		    [updates removePar:MK_controlChange];
		    if (controlVal != MAXINT)  {
			[controllerTable insertKey:(const void *)controller 
		         value:(void *)controlVal];
			[updates removePar:MK_controlVal];
		    }
		}
	    }
	    return self;
	}
	else { /* It's an ordinary note update. */
	    if (!currentPatch)
	      return nil;
	    [currentPatch noteUpdate:aNote];
	    return self;
	}
      case MK_noteOff:
	if (!currentPatch) 
	  return nil;
        [currentPatch noteOff:aNote];
	return self;
      default:
	break;
    }
#if _MK_MAKECOMPILERHAPPY
    return self; /* This can never happen */
#endif
}

-orchestra
{
    return orchestra ? orchestra : _MKClassOrchestra();
}


static void releaseIdlePatch(id aPatch,patchList *aPatchList)
{
    [aPatch retain]; /* until put on list by _deallocate */
    _MKRemoveSynthPatch(aPatch, &(aPatchList->idleNewest),
			&(aPatchList->idleOldest),_MK_IDLELIST);
    [aPatch _deallocate];
    [aPatch release];
    aPatchList->totalCount--;
    aPatchList->manualCount--;
    aPatchList->idleCount--;
    CONSISTENCY_CHECK(aPatchList);
}

static void deallocIdleVoices(MKSynthInstrument *self,id orch)
    /* Deallocates all idle voices using orch. If orch is nil, it's a wild
       card. */
{
    register id aPatch,nextPatch;
    register patchList *aPatchList;
    register patchList *last;
    /* Skip orphan list */
    for (aPatchList  = (patchList *)[self->_patchLists elementAt:1],
	 last = aPatchList + [self->_patchLists count] - 1;
	 (aPatchList < last);
	 aPatchList++) {
	for (aPatch = aPatchList->idleOldest; aPatch; aPatch = nextPatch) {
	    nextPatch = NEXTSP(aPatch);  
	    if ((!orch) || ([aPatch orchestra] == orch)) 
	      releaseIdlePatch(aPatch,aPatchList);
	}
    }
}

static void orphanRunningVoices(MKSynthInstrument *self)
    /* Moves running SynthPatches to orphan list. Doesn't stop them 
       from running, however. */
{
    register id aPatch;
    register patchList *aPatchList,*orphanList;
    register patchList *last;
    orphanList =  (patchList *)[self->_patchLists elementAt:0];
    for (aPatchList  = (patchList *)[self->_patchLists elementAt:1],
	 last = aPatchList + [self->_patchLists count] - 1;
	 (aPatchList < last);
	 aPatchList++) {
	while (aPatchList->activeOldest)  {
            [aPatchList->activeOldest retain];
	    aPatch = _MKRemoveSynthPatch(aPatchList->activeOldest,
					 &(aPatchList->activeNewest),
					 &(aPatchList->activeOldest),
					 _MK_ACTIVELIST);
	    _MKAddPatchToList(aPatch,
			      &(orphanList->activeNewest),
			      &(orphanList->activeOldest),
			      _MK_ORPHANLIST);
            [aPatch release];
	}
    }
}

static void reinstallOrphans(MKSynthInstrument *self,id newClass)
{
    id aPatch,nextPatch;
    patchList *orphanList,*aPatchList;
    MKPatchTemplate *aTemplate;
    orphanList =  (patchList *)[self->_patchLists elementAt:0];
    for (aPatch = orphanList->activeOldest; aPatch; aPatch = nextPatch) {
	nextPatch = NEXTSP(aPatch);  
	if ([aPatch class] == newClass) {
            [orphanList->activeOldest retain];
	    aPatch = _MKRemoveSynthPatch(orphanList->activeOldest,
					 &(orphanList->activeNewest),
					 &(orphanList->activeOldest),
					 _MK_ORPHANLIST);
	    aTemplate = [aPatch patchTemplate];
	    aPatchList = getList(self,aTemplate);
	    if (!aPatchList)
		aPatchList = addList(self,aTemplate);
	    aPatchList->totalCount++;
	    _MKAddPatchToList(aPatch,
			      &(aPatchList->activeNewest),
			      &(aPatchList->activeOldest),
			      _MK_ACTIVELIST);
	    CONSISTENCY_CHECK(aPatchList);
            [aPatch release];
	}
    }
}

/* Forward decls */
static void deallocRunningVoices(MKSynthInstrument *self,id orch);

-_disconnectOnOrch:anOrch
{
    if (anOrch == _MKClassOrchestra())
	anOrch = nil;
    deallocRunningVoices(self,anOrch); /* Must be first. Makes them all on
					  idle list. */
    deallocIdleVoices(self,anOrch);    /* Releases idle voices. */
    return self;
}

-setSynthPatchClass:aSynthPatchClass orchestra:anOrch
  /* Set synthPatchClass as specified. If aSynthPatchClass doesn't inherit 
     from SynthPatch, does nothing and returns nil. Otherwise, returns self.
     Note: This does NOT allow you to supply a different synthPatchClass for
     each orchestra!  Rather, it's a way of setting two independent variables:
     orchestra and synthpatchClass. */
{
    if (aSynthPatchClass == synthPatchClass) /* Avoid needless thrashing */
	return self;
    if (!_MKInheritsFrom(aSynthPatchClass,[MKSynthPatch class]))
	return nil;
    if (!anOrch)
      anOrch = [aSynthPatchClass orchestraClass];
    if (anOrch != orchestra)                 /* Changing orchestra? */
	[self _disconnectOnOrch:orchestra];  /* Hard reset */
    else {
	deallocIdleVoices(self,nil);    /* Release idle patches of old type. */
	orphanRunningVoices(self);      /* Put still-running patches on orphan
					   list. */
	_patchLists = initPatchLists(_patchLists);
	reinstallOrphans(self,aSynthPatchClass);
    } 
    allocMode = MK_AUTOALLOC;
    synthPatchClass = aSynthPatchClass;
#warning sb: initialize method seems to be used here. What does it refer to?
    [synthPatchClass initialize]; /* Make sure PartialsDatabase is inited */
    orchestra = anOrch;
    return self;
}

-setSynthPatchClass:aSynthPatchClass
{
    return [self setSynthPatchClass:aSynthPatchClass
	  orchestra:nil];
}

-synthPatchClass
  /* Returns synthPatchClass */
{
    return synthPatchClass;
}

-allNotesOff
    /* Broadcasts 'noteOff' to all running voices on given orch. (nil orch
       is wild card) Includes orphan patches. */
{
    register id aPatch,nextPatch;
    register patchList *aPatchList;
    register patchList *last;
    id aNote = [[MKNote allocWithZone:[self zone]] init];
    for (aPatchList  = (patchList *)[self->_patchLists elementAt:0],
	 last = aPatchList + [self->_patchLists count];
	 (aPatchList < last);
	 aPatchList++) {
	for (aPatch = aPatchList->activeOldest; aPatch; aPatch = nextPatch) {
	    nextPatch = NEXTSP(aPatch);  
	    if ([aPatch status] == MK_running)
	      [aPatch noteOff:aNote];
	}
    }
    return self;
}

static void deallocRunningVoices(MKSynthInstrument *self,id orch)
    /* Broadcasts 'noteEnd' to all running voices on given orch. (nil orch
       is wild card) Includes orphan patches. */
{
    register id aPatch,nextPatch;
    register patchList *aPatchList;
    register patchList *last;
    for (aPatchList  = (patchList *)[self->_patchLists elementAt:0],
	 last = aPatchList + [self->_patchLists count];
	 (aPatchList < last);
	 aPatchList++) {
	for (aPatch = aPatchList->activeOldest; aPatch; aPatch = nextPatch) {
	    nextPatch = NEXTSP(aPatch);  
	    if ((!orch) || ([aPatch orchestra] == orch)) 
	      [aPatch noteEnd];
	}
    }
}

-abort
  /* Sends the noteEnd message to all running (or finishing) synthPatches 
     managed by this SynthInstrument. This is used only for aborting in 
     emergencies. */
{
    deallocRunningVoices(self,nil); /* Must be first */
    return self;
}

-clearUpdates
/* Causes the SynthInstrument to forget any noteUpdate state it has accumulated
   as a result of receiving noteUpdates without noteTags.
   The effect is not felt by the SynthPatches until the next phrase. Also
   clears controller info.
 */
{
//    [controllerTable removeAllObjects];
    [controllerTable empty];//sb: empty instead of removeAllObjects cos it's a HashTable
    [updates release];
    updates = [MKGetNoteClass() new];  
    [updates setNoteType:MK_noteUpdate];
    return self;
}

-afterPerformance
{
    if (!retainUpdates)
	[self clearUpdates];
    return self;
}

-autoAlloc
  /* Sets allocation mode to MK_AUTOALLOC and releases any manually 
     allocated patches. Otherwise, returns self. */
{
    deallocIdleVoices(self,nil); /* Frees up all idle voices. */
    allocMode = MK_AUTOALLOC;    
    return self;
}

-(unsigned short)allocMode
{
    return allocMode;
}

-(int)synthPatchCountForPatchTemplate:aTemplate
  /* Returns number of manually-allocated voices for the specified template. 
     If the receiver is in automatic allocation mode, returns 0. */
{
    patchList *aPatchList;
    if (allocMode == MK_AUTOALLOC) 
      return 0;
    if (!aTemplate)
      aTemplate = [synthPatchClass defaultPatchTemplate];
    aPatchList = getList(self,aTemplate);
    if (!aPatchList)
      return 0;
    return aPatchList->manualCount;
}

-(int)synthPatchCount
  /* Returns number of manually-allocated voices for the default template. */
{
    return [self synthPatchCountForPatchTemplate:nil];
}

-(int)setSynthPatchCount:(int)voices
  /* Same as setSynthPatchCount:voices template:nil. */
{
    return [self setSynthPatchCount:voices patchTemplate:nil];
}

-(int)setSynthPatchCount:(int)voices patchTemplate:aTemplate
  /* Sets the synthPatchCount for the given template.
     This message may only be sent when the Orchestra is open.
     If aTemplate is nil, the value returned by
     [synthPatchClass defaultPatchTemplate] is used. Returns the number of 
     voices for the given template. If the number of voices is decreased,
     the extra voices are allowed to finish in the normal manner. */
{
    id aPatch,nextPatch;
    int i,j;
    patchList *aPatchList;
    if (!synthPatchClass)
	return 0;
    if (!aTemplate)
      aTemplate = [synthPatchClass defaultPatchTemplate];
    aPatchList = getList(self,aTemplate);
    if (!aPatchList)
      aPatchList = addList(self,aTemplate);
    if (voices < 0) {
	voices = -voices;
	allocMode = MK_MIXEDALLOC;
    } else allocMode = MK_MANUALALLOC;
    if (voices == aPatchList->manualCount) 
	return voices;
    if (voices < aPatchList->manualCount) { /* Releasing some */
	/* First release the idle ones. */
	j = aPatchList->manualCount - voices;
	for (i = 0, aPatch = aPatchList->idleOldest; 
	     (aPatch && (i < j));
	     aPatch = nextPatch, i++)  {
	    nextPatch = NEXTSP(aPatch);
	    releaseIdlePatch(aPatch,aPatchList);
	}
	/* Now we explicitly set manualCount to be the number we 
	   want (so that the _dealloc method will release the active ones for 
	   us). */
	aPatchList->manualCount = voices;
	return voices;
    }
    /* Copy the total count, to take into account any stray voices that
       are still running. */
    aPatchList->manualCount = MIN(aPatchList->totalCount,voices);
    while (aPatchList->manualCount < voices) {
	aPatch = [orchestra
		allocSynthPatch:synthPatchClass patchTemplate:aTemplate];
	if (!aPatch)
	  break;
	if (MKIsTraced(MK_TRACESYNTHINS))
	  fprintf(stderr,"SynthInstrument allocates patch %d from orchestra %d.\n",(int)aPatch,(int)[aPatch orchestra]);
	aPatchList->manualCount++;  
	aPatchList->totalCount++;  
	aPatchList->idleCount++;
	_MKSynthPatchSetInfo(aPatch, MAXINT, self);
	_MKAddPatchToList(aPatch,&aPatchList->idleNewest,
			  &aPatchList->idleOldest,_MK_IDLELIST);
	CONSISTENCY_CHECK(aPatchList);
        [aPatch release]; /* we don't want to hold a retain ourselves -- leave that to the above list */
    }
    [_MKClassOrchestra() flushTimedMessages];
    return aPatchList->manualCount;
}

-getUpdates:(MKNote **)aNoteUpdate controllerValues:(HashTable **)controllers
/* Returns by reference the NoteUpdate used to store the accumulated 
   noteUpdate state. Also returns by reference the HashTable used to 
   store the state of the controllers. Any alterations to the returned
   objects will effect future phrases. The returned objects must not
   be freed. */
{
    *aNoteUpdate = updates;
    *controllers = controllerTable;
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: method. Also archives allocMode, retainUpdates 
     and, if retainUpdates is YES, the controllerTable and updates. */
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes:"#sc",&synthPatchClass,&allocMode,
		 &retainUpdates];
    if (retainUpdates) 
      [aCoder encodeValuesOfObjCTypes:"@@",&controllerTable,&updates];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    [super initWithCoder:aDecoder];
    if ([aDecoder versionForClassName:@"SynthInstrument"] == VERSION2){
	[aDecoder decodeValuesOfObjCTypes:"#sc",&synthPatchClass,&allocMode,
		    &retainUpdates];
	if (retainUpdates) 
	  [aDecoder decodeValuesOfObjCTypes:"@@",&controllerTable,&updates];
    }
    /* from awake (sb) */
    _patchLists = initPatchLists(nil);
    taggedPatches = [HashTable newKeyDesc:"i"];
    if (!controllerTable)
      controllerTable = [HashTable newKeyDesc:"i" valueDesc:"i"];
    if (!updates) {
        updates = [MKGetNoteClass() new];
        [updates setNoteType:MK_noteUpdate];
    }
    orchestra = _MKClassOrchestra();
    _MKOrchAddSynthIns(self);
/****/
    return self;
}

//- awake
  /* Makes unarchived object ready for use. */
//{
    /* See initialize above. */
//#warning DONE ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
//    [super awake];
/*
    _patchLists = initPatchLists(nil);
    taggedPatches = [HashTable newKeyDesc:"i"];
    if (!controllerTable)
      controllerTable = [HashTable newKeyDesc:"i" valueDesc:"i"];
    if (!updates) {
	updates = [MKGetNoteClass() new];
	[updates setNoteType:MK_noteUpdate];
    }
    orchestra = _MKClassOrchestra();
    _MKOrchAddSynthIns(self);
 */
//    return self;
//}

@end


@implementation MKSynthInstrument(Private)

-_repositionInActiveList:synthPatch template:patchTemplate
  /* -activeSynthPatches used to list patches in the order of their noteOns.
     Now it lists all patches that are finishing first, in the order of their 
     noteOffs, then all other active patches, in the order of their noteOns.
     */
{
    patchList *aPatchList = getList(self,patchTemplate);
    if (!aPatchList) /* Should never happen. */
      return nil;
    _MKReplaceFinishingPatch(synthPatch,
			     &aPatchList->activeNewest,
			     &aPatchList->activeOldest,
			     _MK_ACTIVELIST);
    return self;
}

-_deallocSynthPatch:aSynthPatch template:aTemplate tag:(int)noteTag
    /* Removes SynthPatch from active list, possibly adding it to idle list. 
       Returns nil if the SynthPatch is being deallocated, else self. */
{
    patchList *aPatchList = getList(self,aTemplate);
    if (noteTag != MAXINT)
      [taggedPatches removeKey:(void *)noteTag];
    if (!aPatchList) {            /* This happens if the synthPatchClass is 
				     changed. */
	patchList *orphanList = (patchList *)[_patchLists elementAt:0];
        [aSynthPatch retain]; /* so we don't lose it too soon */
	_MKRemoveSynthPatch(aSynthPatch,
			    &(orphanList->activeNewest),
			    &(orphanList->activeOldest),
			    _MK_ORPHANLIST);
	[aSynthPatch _deallocate]; /* sticks it on the "deallocated" list */
        [aSynthPatch release];/* resigns our ownership */
	return nil;
    }
    [aSynthPatch retain]; /* so we don't lose it too soon */
    _MKRemoveSynthPatch(aSynthPatch, &aPatchList->activeNewest, 
			&aPatchList->activeOldest,_MK_ACTIVELIST);
    /* The check of manualCount below guarantees that idleCount 
       doesn't exceed manualCount. This takes care of several
       cases, such as when the synthPatchCount is reduced leaving more
       total voices than there are manually allocated voices. */
    if (aPatchList->manualCount == aPatchList->idleCount) {
	/* A released one or we're in auto mode */
        [aSynthPatch _deallocate]; /* sticks it on the "deallocated" list */
        [aSynthPatch release];/* resigns our ownership */
	aPatchList->totalCount--;
	CONSISTENCY_CHECK(aPatchList);
	return nil;
    }
    aPatchList->idleCount++;
    CONSISTENCY_CHECK(aPatchList);
    _MKAddPatchToList(aSynthPatch,&aPatchList->idleNewest,
		      &aPatchList->idleOldest,_MK_IDLELIST);
    [aSynthPatch release];/* resigns our ownership */
    return self;
}

@end

