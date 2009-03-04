/*
 $Id$
 Defined In: The MusicKit

 Original Author: David A. Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2003, The MusicKit Project.
 */
/*
Modification history now in CVS at musickit.org

 pre-CVS history:
 01/24/90/daj - Fixed bug in removeNote:.
 03/19/90/daj - Added MKSetPartClass() and MKGetPartClass().
 03/21/90/daj - Added archiving support.
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 04/28/90/daj - Flushed scoreClass optimization, now that we're a shlib.
 08/14/90/daj - Fixed bug in addNote:. It wasn't checking to make sure notes exists.
 08/23/90/daj - Changed to zone API.
 10/04/90/daj - freeNotes now creates a new notes List.
 */

#import <stdlib.h>
#import "_musickit.h"
#import "ScorePrivate.h"
#import "NotePrivate.h"
#import "PartPrivate.h"

#define VERSION2 2

static id theSubclass = nil;

BOOL MKSetPartClass(id aClass)
{
  if (!_MKInheritsFrom(aClass, [MKPart class]))
    return NO;
  theSubclass = aClass;
  return YES;
}

id MKGetPartClass(void)
{
  if (!theSubclass)
    theSubclass = [MKPart class];
  return theSubclass;
}

@implementation MKPart

+ (void) initialize
{
    if (self == [MKPart class]) {
	[MKPart setVersion: VERSION2];
    }
}

+new
    /* Override default to return instance of theSubclass, if nec. */
{
    return [[MKGetPartClass() alloc] init];
}

+ (MKPart *) part
{
    return [[[MKGetPartClass() alloc] init] autorelease]; 
}

+ partWithName: (NSString *) partName
{
    MKPart *newPart = [self part];
    
    [newPart setPartName: partName];
    return newPart;
}

/* Format conversion methods. ---------------------------------------------*/


static id compact(MKPart *self)
{
  NSMutableArray *newList = [[NSMutableArray alloc] initWithCapacity:self->noteCount];
  IMP addObjectImp = [newList methodForSelector:@selector(addObject:)];
# define ADDNEW(x) (*addObjectImp)(newList, @selector(addObject:),x)
  int noteIndex, nc = [self->notes count];
  MKNote *aNote;
  SEL oaiSel = @selector(objectAtIndex:);
  IMP objectAtIndex = [self->notes methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(self->notes, oaiSel, (x))
  
  for (noteIndex = 0; noteIndex < nc; noteIndex++) {
    aNote = OBJECTATINDEX( noteIndex );
    if (_MKNoteIsPlaceHolder(aNote)) {
      [aNote _setPartLink:nil order:0];
    }
    else {
      ADDNEW(aNote);
    }
  }
  [self->notes release];
  self->notes = newList;
  self->noteCount = [newList count];
  return self;
# undef ADDNEW
# undef OBJECTATINDEX
}

static void removeNote(MKPart *self, MKNote *aNote);

- combineNotes
  /* TYPE: Editing
    * Attempts to minimize the number of MKNotes by creating
    * a single noteDur for every noteOn/noteOff pair
    * (see the MKNote class).  A noteOn is paired with the
    * earliest subsequent noteOff that has a matching noteTag. However,
    * if an intervening noteOn or noteDur is found, the noteOn is not
    * converted to a noteDur.
    * If a match isn't found, the MKNote is unaffected.
    * Returns the receiver.
    */
{
    MKNote *noteOn, *aNote;
    int noteTag, listSize;
    register int i, j;
    SEL oaiSel = @selector(objectAtIndex:);
    IMP objectAtIndex = [notes methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(notes, oaiSel, (x))
    
    if (!noteCount)
	return self;
    listSize = [notes count];
    
    for (i = 0; i < listSize; i++) {			/* For each note... */
	if ([(noteOn = OBJECTATINDEX(i)) noteType] == MK_noteOn) {
	    noteTag = [noteOn noteTag];			/* We got a noteOn */
	    if (noteTag == MAXINT)			/* Malformed MKPart. */
		continue;
	    for (j = i + 1; (j < listSize); j++) {	/* Search forward */
		if ([(aNote=OBJECTATINDEX(j)) noteTag] == noteTag) {	/* A hit ? */
		    switch ([aNote noteType]) {           /* Ok. What is it? */
			case MK_noteOff:
			    removeNote(self, aNote);           /* Remove aNote from us by tagging as _MKMakePlaceHolder */
			    [noteOn setDur: ([aNote timeTag] - [noteOn timeTag])];
			    [noteOn _unionWith: aNote];        /* Ah... love. */
			    /* No break; here */
			case MK_noteOn:                     /* We don't search on     */
			case MK_noteDur:                    /*   if we find on or dur */
			    j = listSize;                   /* Force abort. No break; */
			default:
			    break;
		    }                           /* End of switch */
		}
	    }                                   /* End of search forward */
	}                                       /* End of if noteOn */
    }

    compact(self); /* drops all notes that are PlaceHolder and remakes list without them */
    return self;
}
# undef OBJECTATINDEX

-splitNotes
  /* TYPE: Editing
    * Splits all noteDurs into a noteOn/noteOff pair.
    * This is done by changing the noteType of the noteDur to noteOn
    * and creating a noteOff with timeTag equal to the
    * timeTag of the original MKNote plus its duration.
    * However, if an intervening noteOn or noteDur of the same tag
    * appears, the noteOff is not added (the noteDur is still converted
					 * to a noteOn in this case).
    * Returns the receiver, or nil if the receiver contains no MKNotes.
    */
{
    NSArray *noteList;
    MKNote *noteOff;
    int noteIndex, matchIndex;
    BOOL matchFound;
    double timeTag;
    int noteTag;
    int originalNoteCount = noteCount;  // noteCount is updated by addNote:
    SEL oaiSel = @selector(objectAtIndex:);
    IMP objectAtIndex;
# define OBJECTATINDEX(x)  (*objectAtIndex)(noteList, oaiSel, (x))
    
    if (!noteCount)
	return self;
    noteList = [self notes]; /* local copy of list (autoreleased) */
    objectAtIndex = [noteList methodForSelector: oaiSel];
    
    for (noteIndex = 0; noteIndex < originalNoteCount; noteIndex++) {
	MKNote *note = OBJECTATINDEX(noteIndex);
	if ([note noteType] == MK_noteDur) {
	    noteOff = [note _splitNoteDurNoCopy];  // Split all noteDurs.
	    noteTag = [noteOff noteTag];
	    if (noteTag == MAXINT) {               // Add noteOff if no tag.
		[self addNote: noteOff];
	    }
	    else {                                 // Need to check for intervening MKNote.
		matchFound = NO;
		timeTag = [noteOff timeTag];
		// search for matching noteTag in the subsequent notes before the noteOff.
		// since addNote: adds noteoffs at the end of the array, we can just search to the original length.
		for (matchIndex = noteIndex + 1; (matchIndex < originalNoteCount) && !matchFound; matchIndex++) {
		    MKNote *candidateNote = OBJECTATINDEX(matchIndex);
		    if ([candidateNote timeTag] > timeTag)
			break;
		    if ([candidateNote noteTag] == noteTag) {
			switch ([candidateNote noteType]) {
			    case MK_noteOn:
				// we treat noteOns as a special case. An intervening noteOn with a matching noteTag is
				// a rearticulation of the current sounding note which can have an acoustic outcome different
				// from a noteOff, then noteOn. Therefore we simply let this one go past and keep searching.
				break;
			    case MK_noteOff:
			    case MK_noteDur:
				matchFound = YES;          // Forget it.
				break;
			    default:
				break;
			}
		    }
		}
		if (!matchFound) {                  /* No intervening notes. */
		    [self addNote: noteOff];
		}
	    }
	}
    }
    return self;
}
#undef OBJECTATINDEX

/* Reading and Writing files. ------------------------------------ */

// TODO should be able to be replaced with setInfoNote:
- _setInfo: (MKNote *) aInfo
    /* Needed by scorefile parser  */
{
    if (!info)
	info = [aInfo copy];
    else
	[info copyParsFrom:aInfo];
    return self;
}

/* MKScore Interface. ------------------------------------------------------- */


- addToScore: (MKScore *) newScore
     /* TYPE: Modifying
    * Removes the receiver from its present MKScore, if any, and adds it
    * to newScore.
    */
{
    return [newScore addPart: self];
}

-removeFromScore
  /* TYPE: Modifying
    * Removes the receiver from its present MKScore.
    * Returns the receiver, or nil if it isn't part of a MKScore.
    * (Implemented as [score removePart:self].)
    */
{
    return [score removePart: self];
}

/* Creation. ------------------------------------------------------------ */

-init
 /* TYPE: Creating and freeing a MKPart
  * Initializes the receiver:
    *
    * Sent by the superclass upon creation;
    * You never invoke this method directly.
    * An overriding subclass method should send [super initialize]
    * before setting its own defaults.
    */
{
    self = [super init];
    if (self != nil) {
	notes    = [NSMutableArray new];
	isSorted = YES;
    }
    return self;
}

/* Freeing. ------------------------------------------------------------- */

- (void) dealloc
 /* TYPE: Creating and freeing a MKPart
    * Frees the receiver and its MKNotes, including the info note, if any.
    * Also removes the name, if any, from the name table.
    * Illegal while the receiver is being performed (and should not
    * happen in this case).
    */
{
    if (![self releaseNotes]) {
	NSLog(@"MusicKit MKPart object: deallocation attempt while _activePerformanceObjs (should not happen). Ignoring.\n");
	//return;
    }
    if (score != nil)
	[score removePart: self];
    if (notes != nil) {
	[notes release];
	notes = nil;
    }
    MKRemoveObjectName(self);
    [super dealloc];
    // Changed on K. Hamels suggestion, used to message to releaseSelfOnly but this would cause a dealloc loop.
}

- (unsigned) hash
{
    unsigned val = 0;
    if (info) {
        val += 1000 * [info noteTag];
    }
    if (notes) {
        val += [notes count];
    }
    return val;
}

#define OBJECTATINDEX(_o,_x)  (*objectAtIndex)((_o), oaiSel, (_x))

- (BOOL) isEqual:(MKPart *) anObject
{
    unsigned noteIndex,count;
    SEL oaiSel;
    IMP objectAtIndex;
    id othernotes;
    
    if (!anObject)                           return NO;
    if (self == anObject)                    return YES;
    if ([self class] != [anObject class])    return NO;
    if ([anObject noteCount] != noteCount)   return NO;
    if (![[anObject infoNote] isEqual:info]) return NO;
    count = [notes count];
    othernotes = [anObject notes];

    oaiSel = @selector(objectAtIndex:);
    objectAtIndex = [notes methodForSelector: oaiSel];
    
    for (noteIndex = 0 ; noteIndex < count ; noteIndex++) {
        if (![OBJECTATINDEX(notes,noteIndex) isEqual:OBJECTATINDEX(notes,noteIndex)]) {
            return NO;
        }
    }
    return YES;
}

static void unsetPartLinks(MKPart *aPart)
{
  id notes = aPart->notes;
  int noteIndex,count;

  if (notes) {
    SEL oaiSel = @selector(objectAtIndex:);
    IMP objectAtIndex = [notes methodForSelector: oaiSel];
    count = [notes count];
    for (noteIndex = 0 ; noteIndex < count ; noteIndex++) {
      [OBJECTATINDEX(notes, noteIndex) _setPartLink:nil order:0];
    }
  }
}

# undef OBJECTATINDEX

- releaseNotes
  /* TYPE: Editing
    * Removes and frees all MKNotes from the receiver including the info
    * note, if any.
    * Doesn't free the receiver.
    * Returns the receiver.
    */
{
    if (_activePerformanceObjs)
	return nil;
    [info release];
    info = nil;
    if (notes) {
	[self removeAllNotes];
    }
    return self;
}

// DEPRECATED - should remove (sbrandon, 01/2002)

-releaseSelfOnly
  /* TYPE: Creating and freeing a MKPart
    * Frees the receiver but not their MKNotes.
    * Returns the receiver. */
{
    [score removePart: self];
    [super release];
    return nil; /*sb: to match old behaviour of "free" */
}

/* Compaction and sorting ---------------------------------------- */

static id sortIfNeeded(MKPart *self)
{
    if (!self->isSorted) {
	[self->notes sortUsingSelector: @selector(compare:)];
	self->isSorted = YES;
	return self;
    }
    return nil;
}

- (BOOL) isSorted
{
    return isSorted;
}

- sort
    /* If the receiver needs to be sorted, sorts and returns self. Else
    returns nil. */
{
    return sortIfNeeded(self);
}

static int findNoteIndex(MKPart *self, MKNote *aNote)
{
    int matchedNote;
    if ((matchedNote = [self->notes indexOfObjectIdenticalTo:aNote]) != NSNotFound)
	return matchedNote;
    return -1;
}

static int findAux(MKPart *self,double timeTag)
{
    /* This function returns:
    If no elements in list, -1
    If the timeTag equals that of the first MKNote or the timeTag is less
    than that of the first MKNote, the index of the first MKNote.
    Otherwise, the index of the last MKNote with timeTag less than the one
    specified. */
    
    register int low = 0;
    register int high = low + self->noteCount;
    register int tmp = low + ((unsigned)((high - low) >> 1));
    
    if (self->noteCount == 0)
	return -1;
    while (low + 1 < high) {
	tmp = low + ((unsigned)((high - low) >> 1));
	if (timeTag > [[self->notes objectAtIndex:tmp] timeTag])
	    low = tmp;
	else high = tmp;
    }
    return low;
}

static int findAtOrAfterTime(MKPart *self, double firstTimeTag) /* sb did the change from id to int return */
{
    int el = findAux(self, firstTimeTag);

    if (el == -1)
	return -1;
    if ([[self->notes objectAtIndex: el] timeTag] >= firstTimeTag)
	return el;
    if ((unsigned) ++el < self->noteCount)
	return el;
    return -1;
}

static int findAtOrBeforeTime(MKPart *self, double lastTimeTag)
{
    int el = findAux(self, lastTimeTag);
    
    if (el == -1)
	return -1;
    
    if ((unsigned) ++el < self->noteCount)
	if ([[self->notes objectAtIndex: el] timeTag] <= lastTimeTag)
	    return el;
    el--;
    
    if (el < 0)
	return -1;
    if ([[self->notes objectAtIndex:el] timeTag] > lastTimeTag)
	return -1;
    return el;
}

/* Basic editing operations. ---------------------------------------  */

- (MKPart *) addNote: (MKNote *) aNote
 /* TYPE: Editing
    * Removes aNote from its present MKPart, if any, and adds it to the end of the receiver.
    * aNote must be a MKNote. Returns the old MKPart, if any.
    */
{
    id oldPart;
    if (!aNote)
	return nil;
    [aNote retain]; /* so the next statement does not dealloc it */
    [oldPart = [aNote part] removeNote:aNote];
    [aNote _setPartLink:self order:++_highestOrderTag];
    if ((noteCount++) && (isSorted)) {
	MKNote *lastObj = [notes lastObject];
	if (_MKNoteCompare(&aNote, &lastObj) == NSOrderedAscending)
	    isSorted = NO;
    }
    [notes addObject:aNote];
    [aNote release]; /* since "notes" holds the retain now */
    return oldPart;
}

- (MKNote *) addNoteCopy: (MKNote *) aNote
     /* TYPE: Editing
    * Adds a copy of aNote
    * to the receiver.
    * Returns the new MKNote.
    */
{
    MKNote *newNote = [aNote copyWithZone: NSDefaultMallocZone()];
    [self addNote: newNote];
    /* we were holding an extra retain from the copyWithZone */
    return [newNote autorelease];
}

static BOOL suspendCompaction = NO;

static void removeNote(MKPart *self, MKNote *aNote)
{
    if ([self->notes containsObject:aNote])  /* MKNote in MKPart? */
	_MKMakePlaceHolder(aNote); /* Mark it as 'to be removed' */
}

- (MKNote *) removeNote: (MKNote *) aNote
    /* TYPE: Editing
    * Removes aNote from the receiver.
    * Returns the removed MKNote or nil if not found.
    * You shouldn't free the removed MKNote if
    * there are any active Performers using the receiver.
    *
    * Keep in mind that if you have to remove a large number of MKNotes,
  * it is more efficient to put them in a List and then use removeNotes:.
    */
{
    int where;
    if (!aNote)
	return nil;
    sortIfNeeded(self);
    if (suspendCompaction)
	removeNote(self, aNote);
    else {
	where = findNoteIndex(self,aNote);
	if (where > -1) {
	    noteCount--;
	    /*sb: reversed following 2 lines. If the removal does not immediately
	    * dealloc the note, it needs to be invalidated for any other Performers
	    * using the receiver (see above)
	    */
	    [aNote _setPartLink: nil order: 0]; /* Added Jan 24, 90 */
	    [notes removeObjectAtIndex: where];
	}
    }
    return nil;
}

/* Contents editing operations. ----------------------------------------- */


- removeNotes: (NSArray *) noteList
   /* TYPE: Editing
    * Removes from the receiver all MKNotes common to the receiver and noteList.
    * Returns the receiver.
    */
{
    int noteIndex, numOfNotes;
    SEL oaiSel = @selector(objectAtIndex:);
    IMP objectAtIndex;
# define OBJECTATINDEX(x)  (*objectAtIndex)(noteList, oaiSel, (x))
    if (!noteList)
	return self;
    objectAtIndex = [noteList methodForSelector: oaiSel];
    
    [self->notes removeObjectsInArray: noteList];
    numOfNotes = [noteList count];
    /* now unset partlink for each note, in case the notes are used in other
	* parts
	*/
    for (noteIndex = 0; noteIndex < numOfNotes; noteIndex++) {
	[OBJECTATINDEX(noteIndex) _setPartLink: nil order: 0];
    }
    return self;
# undef OBJECTATINDEX
}

- addNoteCopies: (NSArray *) noteList timeShift: (double) shift
   /* TYPE: Editing
    * Copies the MKNotes in noteList, shifts the copies'
    * timeTags by shift beats, and then adds them
    * to the receiver.  noteList isn't altered.
    * noteList should contain only MKNotes.
    * Returns the receiver.
    */
{
    int noteIndex, alc;
    double tTag;
    //    register id element, copyElement;
    NSZone *zone = NSDefaultMallocZone();
    IMP selfAddNote;
    MKNote *element, *copyElement;
    
    if (noteList == nil)
	return nil;
    selfAddNote = [self methodForSelector: @selector(addNote:)];
#   define SELFADDNOTE(x) (*selfAddNote)(self, @selector(addNote:), (x))
    
    alc = [noteList count];
    for (noteIndex = 0; noteIndex < alc; noteIndex++) {
	element = [noteList objectAtIndex: noteIndex];
	copyElement = [element copyWithZone: zone];
	tTag = [element timeTag];
	if (tTag < (MK_ENDOFTIME - 1))
	    [copyElement setTimeTag: tTag + shift];
	SELFADDNOTE(copyElement);
	[copyElement release]; /* we're holding extra retain from "copyWithZone" */
    }
#   undef SELFADDNOTE
    return self;
}

- addNotes: (NSArray *) noteList timeShift: (double) shift
  /* TYPE: Editing
    * noteList should contain only MKNotes.
    * For each MKNote in noteList, removes the MKNote
    * from its present MKPart, if any, shifts its timeTag by
    * shift beats, and adds it to the receiver.
    *
    * Returns the receiver.
    */
{
    /* In order to optimize the common case of moving notes from one
    MKPart to another, we do the following.
    
    First we go through the List, removing the MKNotes from their MKParts,
    with the suspendCompaction set. We also keep track of which MKParts we've
    seen.
    
    Then we compact each of the MKParts.
    
    Finally, we add the MKNotes. */
    
    register MKNote *el;
    MKPart *elPart;
    SEL oaiSel = @selector(objectAtIndex:);
    
    if (noteList == nil)
	return self;
    {
	id aPart;
	NSMutableArray *parts = [[NSMutableArray alloc] init];
	int noteIndex;
	int partsIndex, alc, pc;
	
	IMP objectAtIndex = [noteList methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(noteList, oaiSel, (x))
	IMP addPart = [parts methodForSelector:@selector(addObject:)];
# define ADDPART(x) (*addPart)(parts, @selector(addObject:), (x))
	IMP partsIndexOfObjectIdenticalTo = [parts methodForSelector: @selector(indexOfObjectIdenticalTo:)];
# define PARTSCONTAINSOBJECT(x) ( (int)((*partsIndexOfObjectIdenticalTo)\
					(parts, @selector(indexOfObjectIdenticalTo:), (x))) != NSNotFound )
					    
	suspendCompaction = YES;
	alc = [noteList count];
	for (noteIndex = 0; noteIndex < alc; noteIndex++) {
	    el = OBJECTATINDEX(noteIndex);
	    aPart = [el part];
	    if (aPart) {
		if (!PARTSCONTAINSOBJECT(aPart))
		    ADDPART(aPart);
		removeNote(aPart, el);
	    }
	}
	suspendCompaction = NO;
	pc = [parts count];
	for(partsIndex = 0; partsIndex < pc; partsIndex++) {
	    elPart = [parts objectAtIndex: partsIndex];
	    compact(elPart);
	}
	[parts release];
    }
    {
	double tTag;
	int noteIndex, alc;
	IMP selfAddNote = [self methodForSelector:@selector(addNote:)];
	IMP objectAtIndex = [noteList methodForSelector: oaiSel];
# define SELFADDNOTE(x) (*selfAddNote)(self, @selector(addNote:), (x))
	alc = [noteList count];
	for (noteIndex = 0; noteIndex < alc; noteIndex++) {
	    el = OBJECTATINDEX(noteIndex);
	    tTag = [el timeTag];
	    if (tTag < (MK_ENDOFTIME-1))
		[el setTimeTag:tTag + shift];
	    /* adding the note also gives it a positive ordertag, thus resetting
		* the "placeholder" status given it above
		*/
	    SELFADDNOTE(el);
	}
# undef SELFADDNOTE
# undef OBJECTATINDEX
# undef ADDPART
# undef PARTSCONTAINSOBJECT
    }
    return self;
}

- (void) removeAllNotes
 /* TYPE: Editing
    * Removes the receiver's MKNotes which may free them.
    * Returns the receiver.
    */
{
    unsetPartLinks(self);
    [notes removeAllObjects];
    noteCount = 0;
}

- shiftTime: (double) shift
    /* TYPE: Editing
    * Shift is added to the timeTags of all notes in the MKPart.
  * Implemented in terms of addNotes:timeShift:.
    */
{
    NSArray *noteList = _MKLightweightArrayCopy(notes);
    id ret = [self addNotes: noteList timeShift: shift];
    [noteList release];
    return ret;
}

- scaleTime: (double) scale
 /* TYPE: Editing
  * Shift is added to the timeTags of all notes in the MKPart.
  * Implemented in terms of addNotes:timeShift:.
  */
{
    NSArray *noteList = _MKLightweightArrayCopy(notes);
    MKNote  *mkn;
    SEL oaiSel = @selector(objectAtIndex:);
    IMP objectAtIndex = [noteList methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(noteList, oaiSel, (x))
    int noteIndex, numOfNotes = [noteList count];
    
    for (noteIndex = 0 ; noteIndex < numOfNotes; noteIndex++) {
	mkn = OBJECTATINDEX(noteIndex);
	[mkn setTimeTag:  [mkn timeTag]  * scale];
	if ([mkn noteType] == MK_noteDur)
	    [mkn setDur: [mkn dur] * scale];
    }
    [noteList release];
    return self;
}
# undef OBJECTATINDEX

/* Accessing ------------------------------------------------------------- */

- firstTimeTag: (double) firstTimeTag lastTimeTag: (double) lastTimeTag
       /* TYPE: Querying the object
    * Creates and returns a List containing the receiver's MKNotes
    * between firstTimeTag and lastTimeTag in time order.
    * The notes are not copied. This method is useful in conjunction with
    * addNotes:timeShift:, removeNotes:, etc.
    */
{
    NSMutableArray *anArray;
    int firstEl, lastEl;
    
    if (!noteCount)
	return [[[NSMutableArray alloc] init] autorelease];
    sortIfNeeded(self);
    firstEl = findAtOrAfterTime(self, firstTimeTag);
    lastEl = findAtOrBeforeTime(self, lastTimeTag);
    if (firstEl == -1 || lastEl == -1 || firstEl > lastEl) {
	return [[[NSMutableArray alloc] init] autorelease];
    }
    anArray = [NSMutableArray arrayWithCapacity: (unsigned)(lastEl - firstEl) + 1];
    [anArray replaceObjectsInRange: NSMakeRange(0,0)
	      withObjectsFromArray: self->notes
			     range: NSMakeRange(firstEl, (lastEl - firstEl) + 1)];
    return anArray;
}

- (unsigned) noteCount
 /* TYPE: Querying
    * Return the number of MKNotes in the receiver.
    */
{
    return noteCount;
}

- (BOOL) containsNote: (MKNote *) aNote
 /* TYPE: Querying
  * Returns YES if the receiver contains aNote.
 */
{
    return [aNote part] == self;
}

- (BOOL) hasSoundingNotes
{
    int  noteIndex, numOfNotes;
    BOOL bFound = FALSE;
    SEL oaiSel = @selector(objectAtIndex:);
    IMP objectAtIndex = [notes methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(notes, oaiSel, (x))
    
    numOfNotes = [notes count];
    for (noteIndex = 0; noteIndex < numOfNotes; noteIndex++) {
	MKNote *aNote = OBJECTATINDEX(noteIndex);
	MKNoteType t = [aNote noteType];
	if (t == MK_noteDur || t == MK_noteOn) {
	    bFound = TRUE;
	    break;
	}
    }
    return bFound;
}
# undef OBJECTATINDEX


- (BOOL) isEmpty
 /* TYPE: Querying
  * Returns YES if the receiver contains no MKNotes.
  */
{
    return (noteCount == 0);
}

- (MKNote *) atTime: (double) timeTag
 /* TYPE: Accessing MKNotes
    * Returns the first MKNote found at time timeTag, or nil if
    * no such MKNote.
    * Doesn't copy the MKNote.
    */
{
    MKNote *el;
    int elReturned;
    
    sortIfNeeded(self);
    elReturned = findAtOrAfterTime(self, timeTag);
    if (elReturned == -1)
	return nil;
    el = [self->notes objectAtIndex: elReturned];
    if ([el timeTag] != timeTag)
	return nil;
    return [[el retain] autorelease];
}

- (MKNote *) atOrAfterTime: (double) timeTag
   /* TYPE: Accessing MKNotes
    * Returns the first MKNote found at or after time timeTag,
    * or nil if no such MKNote.
    * Doesn't copy the MKNote.
    */
{
    int elReturned;
    
    sortIfNeeded(self);
    elReturned = findAtOrAfterTime(self, timeTag);
    if (elReturned == -1) 
	return nil;
    return [[[self->notes objectAtIndex: elReturned] retain] autorelease];
}

- (MKNote *) atOrBeforeTime: (double) timeTag
   /* TYPE: Accessing MKNotes
    * Returns the first MKNote found at or after time timeTag,
    * or nil if no such MKNote.
    * Doesn't copy the MKNote.
    */
{
    int elReturned;
    
    sortIfNeeded(self);
    elReturned = findAtOrBeforeTime(self, timeTag);
    if (elReturned == -1)
	return nil;
    return [[[self->notes objectAtIndex: elReturned] retain] autorelease];
}

- (MKNote *) nth: (unsigned) n
 /* TYPE: Accessing MKNotes
    * Returns the nth MKNote (0-based), or nil if no such MKNote.
    * Doesn't copy the MKNote. */
{
    sortIfNeeded(self);
    return [[[notes objectAtIndex: n] retain] autorelease];
}

- (MKNote *) atOrAfterTime: (double) timeTag nth: (unsigned) n
       /* TYPE: Accessing MKNotes
    * Returns the nth MKNote (0-based) at or after time timeTag,
    * or nil if no such MKNote.
    * Doesn't copy the MKNote.
    */
{
    unsigned int arrEnd;
    int elReturned;
    
    sortIfNeeded(self);
    elReturned = findAtOrAfterTime(self, timeTag);
    if (elReturned == -1)
	return nil;
    
    arrEnd = [notes count];
    if (elReturned + n >= arrEnd) {
	return nil;
    }
    return [[[notes objectAtIndex: elReturned + n] retain] autorelease];
}

- (MKNote *) atTime: (double) timeTag nth: (unsigned) n
   /* TYPE: Accessing MKNotes
    * Returns the nth MKNote (0-based) at time timeTag,
    * or nil if no such MKNote.
    * Doesn't copy the MKNote.
    */
{
    MKNote *aNote = [self atOrAfterTime: timeTag nth: n];
    
    if (!aNote)
	return nil;
    if ([aNote timeTag] == timeTag)
	return aNote;
    return nil;
}

- (MKNote *) next: (MKNote *) aNote
 /* TYPE: Accessing MKNotes
    * Returns the MKNote immediately following aNote, or nil
    * if no such MKNote.
    */
{
    int elReturned;
    
    if (!aNote)
	return nil;
    sortIfNeeded(self);
    elReturned = findNoteIndex(self, aNote);
    if (elReturned == -1)
	return nil;
    
    if ((unsigned) ++elReturned == noteCount)
	return nil;
    return [[[self->notes objectAtIndex: elReturned] retain] autorelease];
}

// Return the time of the first note.
- (double) earliestNoteTime
{
    if([notes count] > 0) {
	MKNote *earliestNote = [notes objectAtIndex: 0];
	return [earliestNote timeTag];	
    }
    else
	return 0.0;
}

/* Querying --------------------------------------------------- */

- copyWithZone: (NSZone *) zone
   /* TYPE: Creating a MKPart
    * Creates and returns a new MKPart that contains
    * a copy of the contents of the receiver. The info is copied as well.
    */
{
    MKPart *rtn = [MKPart allocWithZone: zone];
    [rtn init];
    [rtn addNoteCopies: notes timeShift: 0];
    rtn->info = [info copy];
    return rtn;
}

- copy
{
    return [self copyWithZone: [self zone]];
}

- (NSMutableArray *) notesNoCopy
{
    return [[notes retain] autorelease];
}

- (NSArray *) notes
{
    sortIfNeeded(self);
    //    return _MKLightweightArrayCopy(notes);
    // Joerg reports [notes mutableCopy] is needed to produce a mutable deep
    // copy, but this does not appear to be the case on GNUStep. Thus the MK
    // defines its own explicit deep array copy mechanism.
    return [NSArray arrayWithArray: _MKDeepMutableArrayCopy(notes)];
}

- (MKScore *) score
  /* TYPE: Querying
  * Returns the MKScore of the receiver's owner.
  */
{
    return [[score retain] autorelease];
}

- (MKNote *) infoNote
  /* Returns 'header note', a collection of info associated with each MKPart,
  which may be used by the App in any way it wants. */
{
    return [[info retain] autorelease];
}

/* Sets 'header note', a collection of info associated with each MKPart,
  which may be used by the App in any way it wants. aNote is copied.
  The old info, if any, is freed. */
- (void) setInfoNote: (MKNote *) aNote
{
    [info release];
    info = [aNote copy];
}

- (NSString *) partName
{
    return MKGetObjectName(self);
}

- (void) setPartName: (NSString *) newPartName
{
    MKNameObject(newPartName, self);    
}

- (void) encodeWithCoder: (NSCoder *) aCoder
    /* You never send this message directly.
    Archives MKNotes and info. Also archives MKScore using
    NXWriteObjectReference(). */
{
    NSString *partName = [self partName];
    
    sortIfNeeded(self);
    [aCoder encodeConditionalObject: score];
    [aCoder encodeValuesOfObjCTypes:"@@ic@i", &notes, &info, &noteCount, &isSorted, &partName, &_highestOrderTag];
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    NSString *str;
    NSMutableDictionary *tagTable;
    
    self = [super init];
    if (self != nil) {	
	if ([aDecoder versionForClassName: @"MKPart"] == VERSION2) {
	    score = [[aDecoder decodeObject] retain];
	    [aDecoder decodeValuesOfObjCTypes:"@@ic@i", &notes, &info, &noteCount, &isSorted, &str, &_highestOrderTag];
	    if (str) {
		[self setPartName: str];
	    }
	}
	/* from awake (sb) */
	if ([MKScore _isUnarchiving])
	    return self;
	tagTable = [NSMutableDictionary dictionary];
	[self _mapTags: tagTable];
    }
    return self;
}

// for debugging, just return the concatenation of the note descriptions (which have newlines).
- (NSString *) description
{
    int noteIndex, numOfNotes;
    NSMutableString *partDescription = [[NSMutableString alloc] initWithFormat: @"%@ containing MKNotes:\n", [super description]];
    NSArray *noteList = [self notes];
    MKNote *aNote;
    
    numOfNotes = [noteList count];
    for(noteIndex = 0; noteIndex < numOfNotes; noteIndex++) {
	aNote = [noteList objectAtIndex: noteIndex];
	[partDescription appendString: [aNote description]];
    }
    [partDescription appendFormat: @"With MKPart info note:\n%@", [[self infoNote] description]];
    
    return [partDescription autorelease];
}

@end

@implementation MKPart(Private)

- (void) _mapTags: (NSMutableDictionary *) hashTable
    /* Must be method to avoid loading MKScore. hashTable is a NSMutableDictionary object
    that maps ints to ints. */
{
    int oldTag;
    unsigned nc;
    MKNote *el;
    NSNumber *newTagNum;
    NSNumber *oldTagNum;
    unsigned noteIndex;

    sortIfNeeded(self);
    nc = [notes count];
    for (noteIndex = 0; noteIndex < nc; noteIndex++) {
	el = [notes objectAtIndex: noteIndex];
	oldTag = [el noteTag];
	if (oldTag != MAXINT) { /* Ignore unset tags */
	    oldTagNum = [NSNumber numberWithInt: oldTag];
	    newTagNum = [hashTable objectForKey: oldTagNum];
	    if (!newTagNum) {
		newTagNum = [NSNumber numberWithInt: MKNoteTag()];
		[hashTable setObject: newTagNum forKey: oldTagNum];
	    }
	    [el setNoteTag: [newTagNum intValue]];
	}
    }
}

- (void) _setNoteSender: (MKNoteSender *) aNS
    /* Private. Used only by scorefilePerformers. */
{
    [_aNoteSender release];
    _aNoteSender = [aNS retain];
}

- (MKNoteSender *) _noteSender
    /* Private. Used only by scorefilePerformers. */
{
    // we didn't allocate it, so we don't autorelease it.
    return _aNoteSender;
}

- _addPerformanceObj: (MKPerformer *) aPerformer
{
    if (!_activePerformanceObjs)
	_activePerformanceObjs = [[NSMutableArray alloc] init];
    if (![_activePerformanceObjs containsObject: aPerformer])
	[_activePerformanceObjs addObject:aPerformer];
    return self;
}

- _removePerformanceObj: (MKPerformer *) aPerformer
{
    if (!_activePerformanceObjs)
	return nil;
    [_activePerformanceObjs removeObject: aPerformer];
    if ([_activePerformanceObjs count] == 0) {
	[_activePerformanceObjs release];
	_activePerformanceObjs = nil;
    }
    return self;
}

- (void) _unsetScore
    /* Private method. Sets score to nil.
    Here we have the classic retain cycle in that the MKPart is retained by
    it's MKScore (indirectly by MKScore retaining the NSArray of MKParts).
    The solution is that we don't release the score. */
{
    score = nil;
}

- (MKScore *) _setScore: (MKScore *) newScore
    /* Removes receiver from the score it is a part of, if any. Does not
    add the receiver to newScore; just sets instance variable. It
    is illegal to remove an active performer.
    Here we have the classic retain cycle in that the MKPart is retained by
    it's MKScore (indirectly by MKScore retaining the NSArray of MKParts).
    The solution is that we don't retain the score. */
{
    id oldScore = score;
    if (score)
	[score removePart: self];
    score = newScore;
    return oldScore;
}

@end

