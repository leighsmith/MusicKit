/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKPart is a time-ordered collection of MKNotes that can be edited,
    performed, and realized.
   
    One or more MKParts can be grouped together in a MKScore.
   
    Editing a MKPart refers generally to adding and removing MKNotes,
    not to changing the contents of the MKNotes themselves (although
    some methods do both; see splitNotes and combineNotes).
    MKNotes are ordered within the MKPart by their timeTag values.
    To move a MKNote within a MKPart, you simply change its timeTag by
    sending it the appropriate message (see the Note class).
    This effectively removes the MKNote from its MKPart, changes the timeTag,
    and then adds it back to its MKPart.
   
    A MKPart can be performed using a MKPartPerformer and can 'record' notes
    by using a MKPartRecorder. You must not free a MKPart or any of the MKNotes
    in a MKPart while there are any MKPartPerformers using the MKPart. It is ok
    to record to a part and perform that part at the same time because the
    MKPartPerformer takes a snap-shot of the MKPart when the MKPartPerformer
    is activated.

    The MKNotes in a MKPart are stored in a NSArray object. The NSArray is only sorted
    when necessary. In particular, the NSArray is sorted, if necessary, when an
    access method is invoked. The access methods are:
   
      - firstTimeTag:(double)firstTimeTag lastTimeTag:(double)lastTimeTag;
      - atTime:(double )timeTag;
      - atOrAfterTime:(double )timeTag;
      - nth:(unsigned )n;
      - atOrAfterTime:(double )timeTag nth:(unsigned )n;
      - atTime:(double )timeTag nth:(unsigned )n;
      - next:aNote;
      - notes;
   
    Other methods that cause a sort, if necessary, are:
   
      - combineNotes;
      - removeNotes:aList;
      - removeNote:aNote;

    Methods that may alter the List such that its MKNotes are no longer sorted are
    the following:
   
      - addNoteCopies:aList timeShift:(double )shift;
      - addNotes:aList timeShift:(double )shift;
      - addNote:aNote;
      - addNoteCopy:aNote;
      - splitNotes
   
    This scheme works well for most cases. However, there are situations where
    it can be problematic. For example:
   
      for (i=0; i<100; i++) {
        [aPart addNote:anArray[i]];
        [aPart removeNote:anotherArray[i]];
      }

    In this case, the MKPart will be sorted each time removeNote: is called,
    causing N-squared behavior. You can get around this by first adding all the
    notes using addNotes: and then removing all the notes using removeNotes:.
   
    In some cases, you may find it most convenient to
    remove the MKNotes from the MKPart, modify them in your own
    data structure, and then reinsert them into the MKPart.
   
    You can explicitly trigger a sort (if needed) by sending the -sort message.
    This is useful if you ever subclass MKPart.
   
    To get a sorted copy of the List of notes use the -notes method.
    To get the List of notes itself, use the -notesNoCopy method.
      -notesNoCopy does not guarantee the MKNotes are sorted.
    If you want to examine the MKNotes in-place sorted, first send -sort, then
      -notesNoCopy.
   
    You can find out if the List is currently sorted by the -isSorted method.
   
  Original Author: David A. Jaffe
  
  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.12  2000/07/22 00:32:21  leigh
  Minor doco and typing cleanups.

  Revision 1.11  2000/05/27 19:15:10  leigh
  Code cleanup

  Revision 1.10  2000/05/06 01:12:14  leigh
  Typed parameters to reduce warnings

  Revision 1.9  2000/05/06 00:31:25  leigh
  Converted tagTable to NSMutableDictionary

  Revision 1.8  2000/04/25 02:11:02  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.7  2000/04/10 18:04:01  leigh
  Fixed overrun bug in splitNotes

  Revision 1.6  2000/04/04 00:12:27  leigh
  Added info note display in description

  Revision 1.5  2000/03/31 00:10:33  leigh
  Cleaned up splitNotes

  Revision 1.4  1999/09/20 03:15:48  leigh
  Added description method, removed disabled awake method

  Revision 1.3  1999/09/04 22:02:18  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.2  1999/07/29 01:16:39  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  01/24/90/daj - Fixed bug in removeNote:. 
  03/19/90/daj - Added MKSetPartClass() and MKGetPartClass().
  03/21/90/daj - Added archiving support.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/28/90/daj - Flushed scoreClass optimization, now that we're a shlib.
  08/14/90/daj - Fixed bug in addNote:. It wasn't checking to make sure notes exists.
  08/23/90/daj - Changed to zone API.
  10/04/90/daj - freeNotes now creates a new notes List.
*/

#import "_musickit.h"  
#import "ScorePrivate.h"
#import "NotePrivate.h"
#import "PartPrivate.h"


@implementation MKPart: NSObject

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKPart class])
      return;
    [MKPart setVersion:VERSION2];//sb: suggested by Stone conversion guide
    return;
}

+new
  /* Create a new instance and sends [self init]. */
{
    self = [self allocWithZone:NSDefaultMallocZone()];
    [self init];
    return self;
}

static id theSubclass = nil;

BOOL MKSetPartClass(id aClass)
{
    if (!_MKInheritsFrom(aClass,[MKPart class]))
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

/* Format conversion methods. ---------------------------------------------*/


static id compact(MKPart *self)
{
//    id *el,*endEl;
    id newList = [NSMutableArray arrayWithCapacity:self->noteCount];
    IMP addObjectImp;
#   define ADDNEW(x) (*addObjectImp)(newList, @selector(addObject:),x)
    addObjectImp = [newList methodForSelector:@selector(addObject:)];
    {
	int noteIndex;
        MKNote *aNote;
        for (noteIndex = 0; noteIndex < [self->notes count]; noteIndex++) {
            aNote = [self->notes objectAtIndex: noteIndex];
            if (_MKNoteIsPlaceHolder(aNote)) {
                [aNote _setPartLink:nil order:0];
		self->noteCount--;
            }
            else ADDNEW(aNote);
        }
        [self->notes release]; /*sb: I am concerned about this, as the new Array class will release
            			* all contents as it is released itself. FIXME SOON
            			*/
        self->notes = newList;
        return self;
        }
    }

/*
    el = NX_ADDRESS(self->notes); 
    endEl = el + self->noteCount; 
    while (el < endEl) {
        if (_MKNoteIsPlaceHolder(*el)) {
	    [*el++ _setPartLink:nil order:0];
            self->noteCount--; 
        }
        else ADDNEW(*el++);
    }
    [self->notes release];
    self->notes = newList;
    return self;
}
 */

static void removeNote(MKPart *self,id aNote);

-combineNotes
  /* TYPE: Editing 
   * Attempts to minimize the number of Notes by creating
   * a single noteDur for every noteOn/noteOff pair
   * (see the Note class).  A noteOn is paired with the 
   * earliest subsequent noteOff that has a matching noteTag. However,
   * if an intervening noteOn or noteDur is found, the noteOn is not 
   * converted to a noteDur.
   * If a match isn't found, the Note is unaffected.
   * Returns the receiver.
   */
{
    id aList,noteOn,aNote;
    int noteTag,listSize;
    register int i,j;
    if (!noteCount)
      return self;
    aList = [self notes]; /* a copy of the list, but sharing note ids. */
    listSize = noteCount;

//#   define REMOVEAT(x) *(NX_ADDRESS(aList) + x) = nil
//#   define AT(x) NX_ADDRESS(aList)[x]
//#   define AT(x) 
    for (i = 0; i < listSize; i++) {			/* For each note... */
        if ([(noteOn = [aList objectAtIndex: i]) noteType] == MK_noteOn) {
            noteTag = [noteOn noteTag];			/* We got a noteOn */
            if (noteTag == MAXINT)			/* Malformed Part. */
                continue;
            for (j = i + 1; (j < listSize); j++) {	/* Search forward */
                if ((aNote = [aList objectAtIndex: j]) &&			/* Watch out for nils */
                    ([aNote noteTag] == noteTag)) {	/* A hit ? */
                    switch ([aNote noteType]) {		/* Ok. What is it? */
                    case MK_noteOff:
                        /* following not really necessary, as we can release the note
                              * and reclaim space in the array automatically */
                        //removeNote(self,aNote);	/* Remove aNote from us */ /*sb: by tagging as _MKMakePlaceHolder */
                        [noteOn setDur:([aNote timeTag] - [noteOn timeTag])];
                        [noteOn _unionWith:aNote];	/* Ah... love. */
                        /* sb: instead of this style of removal, I will use the official one. */
                        [aList removeObjectAtIndex:j];	 /* closes up this list, but will not release note 'til... */
                        [self->notes removeObjectAtIndex:j]; /* this releases the note and closes up the official list */
                        listSize--;
                        self->noteCount--;
                        /* REMOVEAT(j); */		/* Remove from aList */
                        /* [aNote release];	*/	/* No break; here */ /*sb: releases the actual note, not a copy */
                    case MK_noteOn:			/* We don't search on     */
                    case MK_noteDur:		/*   if we find on or dur */
                        j = listSize;		/* Force abort. No break; */
                    default:
                        break;
                    }                           /* End of switch */
                }
            }                                   /* End of search forward */
        }                                       /* End of if noteOn */
    }

//    [aList release];/*sb: this is just my local copy of the list, not the real thing UNNECESSARY NOW */
/*sb: don't need to compact, as this method now self-compacting */
//    compact(self); /* drops all notes that are PlaceHolder and remakes list without them */
    return self;
}

-splitNotes
  /* TYPE: Editing
   * Splits all noteDurs into a noteOn/noteOff pair.
   * This is done by changing the noteType of the noteDur to noteOn
   * and creating a noteOff with timeTag equal to the 
   * timeTag of the original Note plus its duration.
   * However, if an intervening noteOn or noteDur of the same tag
   * appears, the noteOff is not added (the noteDur is still converted
   * to a noteOn in this case).
   * Returns the receiver, or nil if the receiver contains no Notes.
   */
{
    NSArray *aList;
    MKNote *noteOff;
    int noteIndex, matchIndex;
    BOOL matchFound;
    double timeTag;
    int noteTag;
    int originalNoteCount = noteCount;  // noteCount is updated by addNote:
    if (!noteCount)
        return self;
    aList = [self notes]; /* local copy of list (autoreleased) */

    for (noteIndex = 0; noteIndex < originalNoteCount; noteIndex++) {
        MKNote *note = [aList objectAtIndex: noteIndex];
        if ([note noteType] == MK_noteDur) {
            noteOff = [note _splitNoteDurNoCopy];  // Split all noteDurs.
            noteTag = [noteOff noteTag];
            if (noteTag == MAXINT) {               // Add noteOff if no tag.
                [self addNote: noteOff];
            }
            else {                                 // Need to check for intervening Note.
                matchFound = NO;
                timeTag = [noteOff timeTag];
		// search for matching noteTag in the subsequent notes before the noteOff.
                // since addNote: adds noteoffs at the end of the array, we can just search to the original length.
                for (matchIndex = noteIndex + 1; (matchIndex < originalNoteCount) && !matchFound; matchIndex++) {
                    MKNote *candidateNote = [aList objectAtIndex: matchIndex];
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
                            [noteOff release];
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

/* Reading and Writing files. ------------------------------------ */


-_setInfo:aInfo
  /* Needed by scorefile parser  */
{
    if (!info)
      info = [aInfo copy];
    else 
      [info copyParsFrom:aInfo];
    return self;
}

/* Score Interface. ------------------------------------------------------- */


-addToScore:(id)newScore
  /* TYPE: Modifying
   * Removes the receiver from its present Score, if any, and adds it
   * to newScore.  
   */
{
    return [newScore addPart:self];
}

-removeFromScore
  /* TYPE: Modifying
   * Removes the receiver from its present Score.
   * Returns the receiver, or nil if it isn't part of a Score.
   * (Implemented as [score removePart:self].)
   */
{
    return [score removePart:self];
}

/* Creation. ------------------------------------------------------------ */

#if 0
- (void)initialize 
  /* For backwards compatibility */
{ 
    
} 
#endif

-init
  /* TYPE: Creating and freeing a Part
   * Initializes the receiver:
   *
   * Sent by the superclass upon creation;
   * You never invoke this method directly.
   * An overriding subclass method should send [super initialize]
   * before setting its own defaults. 
   */
{
    notes = [[NSMutableArray alloc] init];
    isSorted = YES;
    return self;                        
}

/* Freeing. ------------------------------------------------------------- */

- (void)dealloc
  /* TYPE: Creating and freeing a Part
   * Frees the receiver and its Notes, including the info note, if any.
   * Also removes the name, if any, from the name table.
   * Illegal while the receiver is being performed. In this case, does not
   * free the receiver and returns self. Otherwise returns nil.
   */
{
    if (![self releaseNotes])
      return;
    MKRemoveObjectName(self);
    [score removePart:self];  // moved over from releaseSelfOnly
    [super dealloc];
    // Changed on K. Hamels suggestion, used to message to freeSelfOnly but this would cause a dealloc loop.
}

static void unsetPartLinks(MKPart *aPart)
{
//    Note **el;
    unsigned n;
   /*
   for (n = [aPart->notes count], el = (Note **)NX_ADDRESS(aPart->notes); 
	   n--;
	   )
	[*el++ _setPartLink:nil order:0];
    */
    if (aPart->notes)
        for (n=[aPart->notes count];n--;)
            [[aPart->notes objectAtIndex:n] _setPartLink:nil order:0];
}

-releaseNotes
  /* TYPE: Editing
   * Removes and frees all Notes from the receiver including the info 
   * note, if any.
   * Doesn't free the receiver.
   * Returns the receiver.
   */
{
    if (_activePerformanceObjs)
      return nil;
    /*info = */[info release]; /*sb FIXME should this be autorelease? set to nil? */
    if (notes) {
	unsetPartLinks(self);
	[notes removeAllObjects];
	[notes release];
	notes = [[NSMutableArray alloc] init];
	noteCount = 0;
    }
    return self;
}

-releaseSelfOnly
  /* TYPE: Creating and freeing a Part
   * Frees the receiver but not their Notes.
   * Returns the receiver. */
{
    [score removePart:self];
    // [notes removeAllObjects]; // LMS removed on K. Hamel's recommendation, now matches method doco
    // [notes release];
    // notes = nil;
    [super release];
    return nil; /*sb: to match old behaviour of "free" */
}

/* Compaction and sorting ---------------------------------------- */

#import <stdlib.h>

static id sortIfNeeded(MKPart *self)
{
    if (!self->isSorted) {

/*        qsort((void *)NX_ADDRESS(self->notes),(size_t)self->noteCount,
              (size_t)sizeof(id),_MKNoteCompare);
 */
        [self->notes sortUsingSelector:@selector(compare:)];
        self->isSorted = YES;
        return self;
    }
    return nil;
}

-(BOOL)isSorted
{
    return isSorted;
}

-sort
  /* If the receiver needs to be sorted, sorts and returns self. Else
     returns nil. */
{
    return sortIfNeeded(self);
}

static id findNote(MKPart *self, MKNote *aNote)
{       
/*
    return bsearch((void *)&aNote,(void *)NX_ADDRESS(self->notes),
                   (size_t)self->noteCount,(size_t)sizeof(id),_MKNoteCompare);
 */
    /*sb: first try at this a bit long winded. Realised that _MKNoteCompare only returns 0 (equal) iff ids match. 
     * also changed function to return actual note, rather than address within list.
     */
/*
    NSEnumerator *enumerator = [self->notes objectEnumerator];
    Note *anObject;

    while ((anObject = [enumerator nextObject])) {
        if (_MKNoteCompare(&anObject,&aNote) == NSOrderedSame) return anObject;
        }
    return nil;
 */
    int matchedNote;
    if ((matchedNote = [self->notes indexOfObjectIdenticalTo:aNote]) != NSNotFound)
        return [self->notes objectAtIndex:matchedNote];
    return nil;
}    

static int findNoteIndex(MKPart *self, MKNote *aNote)
{       
/*sb: New function for OpenStep compliant kit. Returns the index in the 
 *    notelist, rather than the note itself. findNote is fine sometimes, but
 *    if we want to use the returned note as a basis to find other notes in the list,
 *    then we can no longer use NX_ADDRESS on the returned value. The index is better.
 */
    int matchedNote;
    if ((matchedNote = [self->notes indexOfObjectIdenticalTo:aNote]) != NSNotFound)
        return matchedNote;
    return -1;
}    

static int findAux(MKPart *self,double timeTag)
{       
    /* This function returns:
       If no elements in list, NULL. sb: -1
       If the timeTag equals that of the first Note or the timeTag is less 
       than that of the first Note, a pointer to the first Note.
       Otherwise, a pointer to the last Note with timeTag less than the one
       specified. */
    /*sb: changed to returning index to note rather than pointer. -1 = notFound. */
    register int low = 0;//NX_ADDRESS(self->notes); 
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

static int findAtOrAfterTime(MKPart *self,double firstTimeTag) /* sb did the change from id to int return */
{
    int el = findAux(self,firstTimeTag);
    if (el == -1)
      return -1;
    if ([[self->notes objectAtIndex:el] timeTag] >= firstTimeTag)
      return el;
    if (++el < self->noteCount)
      return el;
    return -1;
}

static int findAtOrBeforeTime(MKPart *self,double lastTimeTag)
{
    int el = findAux(self,lastTimeTag);
    if (el == -1)
      return -1;

    if (++el < self->noteCount)
        if ([[self->notes objectAtIndex:el] timeTag] <= lastTimeTag)
        return el;
    el--;

    if (el < 0)
      return -1;
    if ([[self->notes objectAtIndex:el] timeTag] > lastTimeTag)
      return -1;
    return el;
}

 /* Basic editing operations. ---------------------------------------  */

-addNote: (MKNote *) aNote
/* TYPE: Editing
 * Removes aNote from its present MKPart, if any, and adds it to the end of the receiver.
 * aNote must be a MKNote. Returns the old MKPart, if any.
 */
{
    id oldPart;
    if (!aNote)
      return nil;
    [oldPart = [aNote part] removeNote:aNote];
    [aNote _setPartLink:self order:++_highestOrderTag];
    if ((noteCount++) && (isSorted)) {
        MKNote *lastObj = [notes lastObject];
        if (_MKNoteCompare(&aNote, &lastObj) == NSOrderedAscending)
          isSorted = NO;
    }
    [notes addObject:aNote];
    return oldPart;
}

-addNoteCopy: (MKNote *) aNote
  /* TYPE: Editing
   * Adds a copy of aNote
   * to the receiver.  
   * Returns the new Note.
   */
{
    id newNote = [aNote copyWithZone:NSDefaultMallocZone()];
    [self addNote:newNote];
    return newNote;
}

static BOOL suspendCompaction = NO;

static void removeNote(MKPart *self, MKNote *aNote)
{
    MKNote *where = findNote(self,aNote); /*sb: returns the note, not the address in the list */
    if (where)  /* Note in Part? */
      _MKMakePlaceHolder(aNote); /* Mark it as 'to be removed' */
}

-removeNote:aNote
  /* TYPE: Editing
   * Removes aNote from the receiver.
   * Returns the removed Note or nil if not found.
   * You shouldn't free the removed Note if
   * there are any active Performers using the receiver.
   * 
   * Keep in mind that if you have to remove a large number of Notes,
   * it is more efficient to put them in a List and then use removeNotes:.
   */
{
    int where;
    if (!aNote)
      return nil;
    sortIfNeeded(self);
    if (suspendCompaction) 
      removeNote(self,aNote);
    else {
        where = findNoteIndex(self,aNote);
        if (where > -1) {
            noteCount--;
            /*sb: reversed following 2 lines. If the removal does not immediately
             * dealloc the note, it needs to be invalidated for any other Performers
             * using the receiver (see above)
             */
            [aNote _setPartLink:nil order:0]; /* Added Jan 24, 90 */
            [notes removeObjectAtIndex:where];
        }
    }
    return nil;
}

/* Contents editing operations. ----------------------------------------- */


- removeNotes:aList
  /* TYPE: Editing
   * Removes from the receiver all Notes common to the receiver
   * and aList. 
   * Returns the receiver.
   */
{ 
//    register id *el;
//    unsigned n;
    if (!aList)
      return self;
/*sb: ahhh, OpenStep! */
/*    
    for (el = NX_ADDRESS(aList), n = [aList count]; n--; el++)
      removeNote(self,*el);
 */
    [self->notes removeObjectsInArray:aList];
//    compact(self); /*sb: remove placeholders (now unnecessary)*/
    return self;
}

- addNoteCopies:aList timeShift:(double) shift     
  /* TYPE: Editing
   * Copies the Notes in aList, shifts the copies'
   * timeTags by shift beats, and then adds them
   * to the receiver.  aList isn't altered.
   * aList should contain only Notes.
   * Returns the receiver.
   */
{ 
    int noteIndex;
    double tTag;
//    register id element, copyElement;
    NSZone *zone = NSDefaultMallocZone();
    IMP selfAddNote;
    MKNote *element,*copyElement;

    if (aList == nil)
      return nil;
    selfAddNote = [self methodForSelector:@selector(addNote:)];
#   define SELFADDNOTE(x) (*selfAddNote)(self, @selector(addNote:), (x))

    for (noteIndex = 0; noteIndex < [aList count]; noteIndex++) {
      element = [aList objectAtIndex: noteIndex];
      copyElement = [element copyWithZone:zone];
      tTag = [element timeTag];
      if (tTag < (MK_ENDOFTIME-1))
         [copyElement setTimeTag:tTag + shift];
      SELFADDNOTE(copyElement);     
    }
#   undef SELFADDNOTE
    return self;
}

-addNotes: (NSArray *) aList timeShift:(double) shift
  /* TYPE: Editing
   * aList should contain only Notes.
   * For each Note in aList, removes the Note
   * from its present Part, if any, shifts its timeTag by
   * shift beats, and adds it to the receiver.
   * 
   * Returns the receiver. 
   */
{ 
    /* In order to optimize the common case of moving notes from one
       Part to another, we do the following.

       First we go through the List, removing the Notes from their Parts,
       with the suspendCompaction set. We also keep track of which Parts we've
       seen. 

       Then we compact each of the Parts.
       
       Finally, we add the Notes. */

    register MKNote *el;
    MKPart *elPart;
//    unsigned n;
    if (aList == nil)
      return self;
    {
        id aPart;
        NSMutableArray *parts = [[NSMutableArray alloc] init];
	int noteIndex;
        int partsIndex;
        /*sb: the following are fairly obselete. addObjectIfAbsent is obselete, and must
            be performed in 2 stages.
         */
//        IMP addPart = [parts methodForSelector:@selector(addObjectIfAbsent:)];
//#       define ADDPART(x) (*addPart)(parts, @selector(addObjectIfAbsent:), (x))
        suspendCompaction = YES;
        /*sb:
            removeObject
            */

        for (noteIndex = 0; noteIndex < [aList count]; noteIndex++) {
            el = [aList objectAtIndex: noteIndex];
            aPart = [el part];
            if (aPart) {
//                ADDPART(aPart);
                /*sb: do it manually... 
                 */
                if ([parts containsObject:aPart]) [parts addObject:aPart];
                [aPart removeNote:el]; 
            }
        }
        suspendCompaction = NO;
        for(partsIndex = 0; partsIndex < [parts count]; partsIndex++) {
            elPart = [parts objectAtIndex: partsIndex];
            compact(elPart);
        }
        [parts release];
    }
    {
        double tTag;
        int noteIndex;
        IMP selfAddNote;
        selfAddNote = [self methodForSelector:@selector(addNote:)];
#       define SELFADDNOTE(x) (*selfAddNote)(self, @selector(addNote:), (x))
        for (noteIndex = 0; noteIndex < [aList count]; noteIndex++) {
            el = [aList objectAtIndex: noteIndex];
            tTag = [el timeTag];
            if (tTag < (MK_ENDOFTIME-1))
              [el setTimeTag:tTag + shift];
            SELFADDNOTE(el);
        }
#       undef SELFADDNOTE
    }
    return self;
}

- (void)removeAllObjects
  /* TYPE: Editing
   * Removes the receiver's Notes but doesn't free them, except for 
   * placeHolder notes, which are freed.
   * Returns the receiver. 
   */
{
    unsetPartLinks(self);
    [notes removeAllObjects];
    noteCount = 0;
    return;
}


-shiftTime:(double)shift
  /* TYPE: Editing
   * Shift is added to the timeTags of all notes in the Part. 
   * Implemented in terms of addNotes:timeShift:.
   */
{
    id aList = [self notes];
    id rtn = [self addNotes:aList timeShift:shift];
//    [aList release]; /*sb: unnecessary. It's autoreleased */
    return rtn;
}

/* Accessing ------------------------------------------------------------- */

- firstTimeTag:(double) firstTimeTag lastTimeTag:(double) lastTimeTag 
  /* TYPE: Querying the object
   * Creates and returns a List containing the receiver's Notes
   * between firstTimeTag and lastTimeTag in time order.
   * The notes are not copied. This method is useful in conjunction with
   * addNotes:timeShift:, removeNotes:, etc.
   */
{
    id aList;
//    id *firstEl,*lastEl;
    int firstEl,lastEl;
    if (!noteCount)
      return [[NSMutableArray alloc] init];
    sortIfNeeded(self);
    firstEl = findAtOrAfterTime(self,firstTimeTag);
    lastEl = findAtOrBeforeTime(self,lastTimeTag);
    if (firstEl == -1 || lastEl == -1 || firstEl > lastEl) /*sb change el from returning ids to ints */
      return [[NSMutableArray alloc] init];
    aList = [NSMutableArray arrayWithCapacity:(unsigned)(lastEl - firstEl) + 1];
    [aList replaceObjectsInRange:NSMakeRange(0,0) withObjectsFromArray:self->notes
                           range:NSMakeRange(firstEl,(lastEl - firstEl) + 1)];
/*    while (firstEl <= lastEl)
      [aList addObject:*firstEl++];
 */
    return aList;
}

-(unsigned)noteCount
  /* TYPE: Querying
   * Return the number of Notes in the receiver.
   */
{
    return noteCount;
}

-(BOOL)containsNote:aNote
  /* TYPE: Querying
   * Returns YES if the receiver contains aNote.
   */
{
    return [aNote part] == self;
}

-(BOOL)isEmpty
  /* TYPE: Querying
   * Returns YES if the receiver contains no Notes.
   */
{
    return (noteCount == 0);
}

- atTime:(double) timeTag
  /* TYPE: Accessing Notes
   * Returns the first Note found at time timeTag, or nil if 
   * no such Note.
   * Doesn't copy the Note.
   */
{
    MKNote *el;
    int elReturned;
    sortIfNeeded(self);
    elReturned = findAtOrAfterTime(self,timeTag);
    if (elReturned == -1)
      return nil;
    if ([(el=[self->notes objectAtIndex:elReturned]) timeTag] != timeTag)
      return nil;
    return [[el retain] autorelease];
}

-atOrAfterTime:(double)timeTag
  /* TYPE: Accessing Notes
   * Returns the first Note found at or after time timeTag, 
   * or nil if no such Note. 
   * Doesn't copy the Note.
   */
{
    int elReturned;
    sortIfNeeded(self);
    elReturned = findAtOrAfterTime(self,timeTag);
    if (elReturned == -1) return nil;
    return [[[self->notes objectAtIndex:elReturned] retain] autorelease];
}

- nth:(unsigned) n
  /* TYPE: Accessing Notes
   * Returns the nth Note (0-based), or nil if no such Note.
   * Doesn't copy the Note. */
{
    sortIfNeeded(self);
    return [[[notes objectAtIndex:n] retain] autorelease];
}

-atOrAfterTime:(double)timeTag nth:(unsigned) n 
  /* TYPE: Accessing Notes
   * Returns the nth Note (0-based) at or after time timeTag,
   * or nil if no such Note. 
   * Doesn't copy the Note.
   */
{
    int arrEnd;
    int el;
    sortIfNeeded(self);
    el = findAtOrAfterTime(self,timeTag);
    if (el == -1)
      return nil;

    arrEnd = noteCount;
    if (n == 0)
        return [self->notes objectAtIndex:el];
    while (n--) {
        if (++el >= arrEnd)
          return nil;
    }
    return [[[self->notes objectAtIndex:el]retain] autorelease];
}

-atTime:(double)timeTag nth:(unsigned) n
  /* TYPE: Accessing Notes
   * Returns the nth Note (0-based) at time timeTag,
   * or nil if no such Note. 
   * Doesn't copy the Note.
   */
{
    id aNote = [self atOrAfterTime:timeTag nth:n];
    if (!aNote)
      return nil;
    if ([aNote timeTag] == timeTag)
        return [[aNote retain] autorelease];
    return nil;
}

-next:aNote  
  /* TYPE: Accessing Notes
   * Returns the Note immediately following aNote, or nil
   * if no such Note.  (A more efficient procedure is to create a
   * List with notes and then step down the List using NX_ADDRESS().
   */
/* sb: returns note that is retained and autoreleased, so the receiving method
 * does not have to dispose of it. If it needs to  keep a copy, it must take
 * an explicit copy. This should be the same for all methods returning a note.
 */
{
    int el;
    if (!aNote)
      return nil;
    sortIfNeeded(self);
    el = findNoteIndex(self,aNote);
    if (el == -1)
      return nil;

    if (++el == noteCount)
      return nil;
    return [[[self->notes objectAtIndex:el] retain] autorelease];
}

/* Querying --------------------------------------------------- */

- copyWithZone:(NSZone *)zone
  /* TYPE: Creating a Part
   * Creates and returns a new Part that contains
   * a copy of the contents of the receiver. The info is copied as well.
   */
{
    MKPart *rtn = [MKPart allocWithZone:zone];
    [rtn init];
    [rtn addNoteCopies:notes timeShift:0];
    rtn->info = [info copy];
    return rtn;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

-notesNoCopy
  /* TYPE: Accessing Notes
   * Returns a List of the Notes in the receiver, in time order. 
   * The Notes are not copied. 
   * The List is not copied and is not guaranteed to be sorted.
   */
{
    return [[notes retain] autorelease];
}

- (NSMutableArray *) notes
  /* TYPE: Accessing Notes
   * Returns a Array of the Notes in the receiver, in time order. 
   * The Notes *are* copied. 
//   * It is the sender's responsibility to free the List.
//   * sb: NOT TRUE. List will be autoreleased.
   */
{
    sortIfNeeded(self);
//    return [notes copy];  // LMS at the moment this stops problems with overly freed objects.
//    return _MKLightweightArrayCopy(notes); // LMS this should be (I think) the final version.
    return [notes mutableCopy];  // Joerg reports this is needed to produce a mutable deep copy.
}

- (MKScore *) score  
  /* TYPE: Querying
   * Returns the Score of the receiver's owner.
   */
{
    return score;
}

- (MKNote *) infoNote
  /* Returns 'header note', a collection of info associated with each Part,
     which may be used by the App in any way it wants. */ 
{
//    return [[info retain] autorelease];
//    return [info retain];
    return info;
}

-setInfoNote:(MKNote *) aNote
  /* Sets 'header note', a collection of info associated with each Part,
     which may be used by the App in any way it wants. aNote is copied. 
     The old info, if any, is freed. */ 
{
    [info release];
    info = [aNote copy]; 
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives Notes and info. Also archives Score using 
     NXWriteObjectReference(). */
{
    NSString *str;
    /* [super encodeWithCoder:aCoder];*/ /*sb: unnec */
    sortIfNeeded(self);
    str = MKGetObjectName(self);
    [aCoder encodeConditionalObject:score];
    [aCoder encodeValuesOfObjCTypes:"@@ic@i",&notes,&info,&noteCount,&isSorted,
                 &str,&_highestOrderTag];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    NSString *str;
    /*[super initWithCoder:aDecoder];*/ /*sb: unnec */
    if ([aDecoder versionForClassName:@"MKPart"] == VERSION2) {
        score = [[aDecoder decodeObject] retain];
        [aDecoder decodeValuesOfObjCTypes:"@@ic@i",&notes,&info,&noteCount,&isSorted,
                    &str,&_highestOrderTag];
        if (str) {
            MKNameObject(str,self);
//            free(str);
        }
    }
    return self;
    /* from awake (sb) */
    {
        NSMutableDictionary *tagTable;
        if ([MKScore _isUnarchiving])
          return self;
        tagTable = [NSMutableDictionary dictionary];
        [self _mapTags: tagTable];
    }
}

// for debugging, just return the concatenation of the note descriptions (which have newlines).
- (NSString *) description
{
    int i;
    NSMutableString *partDescription = [[NSMutableString alloc] initWithString: @"MKPart containing MKNotes:\n"];
    NSMutableArray *noteList = [self notes];
    MKNote *aNote;

    for(i = 0; i < [noteList count]; i++) {
        aNote = [noteList objectAtIndex: i];
        [partDescription appendString: [aNote description]];
    }
    [partDescription appendFormat: @"With MKPart info note:\n%@", [[self infoNote] description]];

    return partDescription;
}

@end

@implementation MKPart(Private)

-(void) _mapTags: (NSMutableDictionary *) hashTable
    /* Must be method to avoid loading Score. hashTable is a NSMutableDictionary object
     that maps ints to ints. */
{
    int oldTag;
    MKNote *el;
    NSNumber *newTagNum;
    NSNumber *oldTagNum;
    unsigned noteIndex;

    sortIfNeeded(self);
    for (noteIndex = 0; noteIndex < [notes count]; noteIndex++) {
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

-(void)_setNoteSender: (MKNoteSender *) aNS
  /* Private. Used only by scorefilePerformers. */
{
// LMS where the problem is
    if(_aNoteSender)
	[_aNoteSender release];
// _aNoteSender = [[aNS copy] retain];
    _aNoteSender = aNS;
    [_aNoteSender retain];
}

- (MKNoteSender *) _noteSender
  /* Private. Used only by scorefilePerformers. */
{
//    return [_aNoteSender autorelease];  // no, we didn't allocate it, so we don't autorelease it.
    return _aNoteSender;
}

-(void)_unsetScore
    /* Private method. Sets score to nil. */
{
    score = nil;
}
 
-_addPerformanceObj:aPerformer
{
    if (!_activePerformanceObjs)
      _activePerformanceObjs = [[NSMutableArray alloc] init];
    if (![_activePerformanceObjs containsObject:aPerformer]) [_activePerformanceObjs addObject:aPerformer];
    return self;
}

-_removePerformanceObj:aPerformer
{
     if (!_activePerformanceObjs)
      return nil;
     [_activePerformanceObjs removeObject:aPerformer];
     if ([_activePerformanceObjs count] == 0) {
         [_activePerformanceObjs release];
         _activePerformanceObjs = nil;
     }
    return self;
}

-_setScore:(id)newScore
    /* Removes receiver from the score it is a part of, if any. Does not
       add the receiver to newScore; just sets instance variable. It
       is illegal to remove an active performer. */
{
    id oldScore = score;
    if (score) 
      [score removePart:self];
    score = newScore;
    return oldScore;
}

@end

