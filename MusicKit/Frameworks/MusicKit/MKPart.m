/*
 $Id$
 Defined In: The MusicKit

 Original Author: David A. Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2000, The MusicKit Project.
 */
/*
Modification history:

 Now in CVS - musickit.sourceforge.net

 $Log$
 Revision 1.24  2002/03/14 00:08:55  leighsmith
 Removed warning on redefining OBJECTATINDEX macro by using single version

 Revision 1.23  2002/03/12 22:59:03  sbrandon
 Added -hash and -isEqual methods so that MKPart objects can be used
 successfully as keys in NSMutableDictionaries. Previously this failed and
 this caused various bugs including one in saving/loading binary scorefiles.

 Revision 1.22  2002/03/06 09:48:58  skotmcdonald
 Added not-nil checks around ivar releases in dealloc

 Revision 1.21  2002/01/24 14:49:43  sbrandon
 fixed typo in addNotes:timeShift:, and removed unused variable in
 -combineNotes

 Revision 1.20  2002/01/24 13:31:03  sbrandon
 +new and +part create instances of theSubclass, if set, instead of MKPart
 +part now returns an autoreleased object
 compact(): fixed bug where compacted notelist would autorelease; also
     tightened up noteCount handling; cached IMP for objectAtIndex
 -combineNotes: removed old cruft; now operate on "notes" array directly
     instead of on deep copy; cached IMP for objectAtIndex; don't bother
     to check for nils in NSArrays (they cannot exist); went back to use
     of placeholders in note lists during element deletion (then compact
     afterwards) as it's much more efficient
 -splitNotes: cached IMP for objectAtIndex
 -initialize: removed old crufty method
 (fixed a number of comments to reflect current situation)
 -dealloc: now log a comment if dealloc method is called while
     _activePerformanceObjs exists (should never happen?). We go ahead
     and do the dealloc anyway.
 unsetPartLinks(): fixed crasher (going off end of NSArray); cached IMP
     for objectAtIndex
 -releaseSelfOnly: marked as deprecated
 sortIfNeeded(): removed cruft
 findNote(): removed totally rubbish function. What was I thinking of when
     I did the original OpenStep conversion? :-(
 findNoteIndex(): fixed comments
 -addNote: retain and release notes internally while swapping between parts
     to prevent possible deallocation during processing.
 -addNoteCopy: now autoreleases the note returned (was leaking before)
 removeNote(): removed pointless use of findNote()
 -removeNotes: cached IMP for objectAtIndex
 -addNoteCopies: released leaking copies of notes during processing
 -addNotes: removed old cruft; added IMP caching; fixed bug where parts
     would not be compacted after having notes removed from them
 -shiftTime: only take lightweight copy of notes instead of deep copy
 -scaleTime: only take lightweight copy of notes instead of deep copy;
     cached IMP for objectAtIndex; remembered to release copied array
     of notes
 -firstTimeTag:lastTimeTag: remembered to always return autoreleased objects
 -hasSoundingNotes: cached IMP for objectAtIndex; only make 1 -noteType
     call instead of 2
 -atOrAfterTime:nth: simplified logic (what was I thinking???)
 -atTime:nth: don't bother to retain/autorelease the return value a second
     time
 -next: removed crufty comments
 -notesNoCopy: fixed comment
 -notes: now implement in terms of unambiguous _MKDeepMutableArrayCopy()
     function instead of -mutableCopy, which was not the same on GNUstep.
     Eventually I think -notes should return a shallow copy, but I am
     leaving it as Leigh last left it for now. Returns an autoreleased
     deep copy.
 -infoNote: now returns autoreleased object
 -description: now returns autoreleased NSString
 -_setNoteSender: simplified


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

@implementation MKPart: NSObject

+ (void)initialize
{
  if (self != [MKPart class]) {
    return;
  }
  [MKPart setVersion:VERSION2];
  return;
}

+new
  /* Override default to return instance of theSubclass, if nec. */
{
  return [[MKGetPartClass() alloc] init];
}

+ part
{
  return [[[MKGetPartClass() alloc] init] autorelease]; 
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

static void removeNote(MKPart *self,id aNote);

-combineNotes
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
  id noteOn,aNote;
  int noteTag,listSize;
  register int i,j;
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
              removeNote(self,aNote);           /* Remove aNote from us by tagging as _MKMakePlaceHolder */
              [noteOn setDur:([aNote timeTag] - [noteOn timeTag])];
              [noteOn _unionWith:aNote];        /* Ah... love. */
                                                /* No break; here */
            case MK_noteOn:                     /* We don't search on     */
            case MK_noteDur:                    /*   if we find on or dur */
              j = listSize;                     /* Force abort. No break; */
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
  NSArray *aList;
  MKNote *noteOff;
  int noteIndex, matchIndex;
  BOOL matchFound;
  double timeTag;
  int noteTag;
  int originalNoteCount = noteCount;  // noteCount is updated by addNote:
  SEL oaiSel = @selector(objectAtIndex:);
  IMP objectAtIndex;
# define OBJECTATINDEX(x)  (*objectAtIndex)(aList, oaiSel, (x))

  if (!noteCount)
    return self;
  aList = [self notes]; /* local copy of list (autoreleased) */
  objectAtIndex = [aList methodForSelector: oaiSel];
  
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


-_setInfo:aInfo
  /* Needed by scorefile parser  */
{
  if (!info)
    info = [aInfo copy];
  else
    [info copyParsFrom:aInfo];
  return self;
}

/* MKScore Interface. ------------------------------------------------------- */


-addToScore:(id)newScore
 /* TYPE: Modifying
  * Removes the receiver from its present MKScore, if any, and adds it
  * to newScore.
  */
{
  return [newScore addPart:self];
}

-removeFromScore
  /* TYPE: Modifying
  * Removes the receiver from its present MKScore.
  * Returns the receiver, or nil if it isn't part of a MKScore.
  * (Implemented as [score removePart:self].)
  */
{
  return [score removePart:self];
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
  if (self) {
    notes = [[NSMutableArray alloc] init];
    isSorted = YES;
  }
  return self;
}

/* Freeing. ------------------------------------------------------------- */

- (void)dealloc
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
  MKRemoveObjectName(self);
  if (score)
    [score removePart:self];  // moved over from releaseSelfOnly
  if (notes)
    [notes release];
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
    unsigned i,count;
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
    
    for (i = 0 ; i < count ; i++) {
        if (![OBJECTATINDEX(notes,i) isEqual:OBJECTATINDEX(notes,i)]) {
            return NO;
        }
    }
    return YES;
}

static void unsetPartLinks(MKPart *aPart)
{
  id notes = aPart->notes;
  int i,count;

  if (notes) {
    SEL oaiSel = @selector(objectAtIndex:);
    IMP objectAtIndex = [notes methodForSelector: oaiSel];
    count = [notes count];
    for (i = 0 ; i < count ; i++) {
      [OBJECTATINDEX(notes, i) _setPartLink:nil order:0];
    }
  }
}

# undef OBJECTATINDEX

-releaseNotes
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
    unsetPartLinks(self);
    [notes removeAllObjects];
    noteCount = 0;
  }
  return self;
}

// DEPRECATED - should remove (sbrandon, 01/2002)

-releaseSelfOnly
  /* TYPE: Creating and freeing a MKPart
  * Frees the receiver but not their MKNotes.
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

static id sortIfNeeded(MKPart *self)
{
  if (!self->isSorted) {
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

-addNoteCopy: (MKNote *) aNote
     /* TYPE: Editing
  * Adds a copy of aNote
  * to the receiver.
  * Returns the new MKNote.
  */
{
  MKNote *newNote = [aNote copyWithZone:NSDefaultMallocZone()];
  [self addNote:newNote];
  /* we were holding an extra retain from the copyWithZone */
  return [newNote autorelease];
}

static BOOL suspendCompaction = NO;

static void removeNote(MKPart *self, MKNote *aNote)
{
  if ([self->notes containsObject:aNote])  /* MKNote in MKPart? */
    _MKMakePlaceHolder(aNote); /* Mark it as 'to be removed' */
}

-removeNote:aNote
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
  * Removes from the receiver all MKNotes common to the receiver and aList.
  * Returns the receiver.
  */
{
  int i,count;
  SEL oaiSel = @selector(objectAtIndex:);
  IMP objectAtIndex;
# define OBJECTATINDEX(x)  (*objectAtIndex)(aList, oaiSel, (x))
  if (!aList)
    return self;
  objectAtIndex = [aList methodForSelector: oaiSel];
  
  [self->notes removeObjectsInArray:aList];
  count = [aList count];
  /* now unset partlink for each note, in case the notes are used in other
   * parts
   */
  for (i=0;i<count;i++) {
    [OBJECTATINDEX(i) _setPartLink:nil order:0];
  }
  return self;
# undef OBJECTATINDEX
}

- addNoteCopies:aList timeShift:(double) shift
 /* TYPE: Editing
  * Copies the MKNotes in aList, shifts the copies'
  * timeTags by shift beats, and then adds them
  * to the receiver.  aList isn't altered.
  * aList should contain only MKNotes.
  * Returns the receiver.
  */
{
  int noteIndex, alc;
  double tTag;
  //    register id element, copyElement;
  NSZone *zone = NSDefaultMallocZone();
  IMP selfAddNote;
  MKNote *element,*copyElement;

  if (aList == nil)
    return nil;
  selfAddNote = [self methodForSelector:@selector(addNote:)];
#   define SELFADDNOTE(x) (*selfAddNote)(self, @selector(addNote:), (x))

  alc = [aList count];
  for (noteIndex = 0; noteIndex < alc; noteIndex++) {
    element = [aList objectAtIndex: noteIndex];
    copyElement = [element copyWithZone:zone];
    tTag = [element timeTag];
    if (tTag < (MK_ENDOFTIME-1))
      [copyElement setTimeTag:tTag + shift];
    SELFADDNOTE(copyElement);
    [copyElement release]; /* we're holding extra retain from "copyWithZone" */
  }
#   undef SELFADDNOTE
  return self;
}

-addNotes: (NSArray *) aList timeShift:(double) shift
  /* TYPE: Editing
  * aList should contain only MKNotes.
  * For each MKNote in aList, removes the MKNote
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
  if (aList == nil)
    return self;
  {
    id aPart;
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    int noteIndex;
    int partsIndex, alc, pc;

    IMP objectAtIndex = [aList methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(aList, oaiSel, (x))
    IMP addPart = [parts methodForSelector:@selector(addObject:)];
# define ADDPART(x) (*addPart)(parts, @selector(addObject:), (x))
    IMP partsIndexOfObjectIdenticalTo = 
       [parts methodForSelector:@selector(indexOfObjectIdenticalTo:)];
# define PARTSCONTAINSOBJECT(x) ( (int)((*partsIndexOfObjectIdenticalTo)\
       (parts, @selector(indexOfObjectIdenticalTo:), (x))) != NSNotFound )

    suspendCompaction = YES;
    alc = [aList count];
    for (noteIndex = 0; noteIndex < alc; noteIndex++) {
      el = OBJECTATINDEX(noteIndex);
      aPart = [el part];
      if (aPart) {
        if (!PARTSCONTAINSOBJECT(aPart)) ADDPART(aPart);
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
    IMP objectAtIndex = [aList methodForSelector: oaiSel];
# define SELFADDNOTE(x) (*selfAddNote)(self, @selector(addNote:), (x))
    alc = [aList count];
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

- (void)removeAllObjects
 /* TYPE: Editing
  * Removes the receiver's MKNotes which may free them.
  * Returns the receiver.
  */
{
  unsetPartLinks(self);
  [notes removeAllObjects];
  noteCount = 0;
  return;
}


- shiftTime: (double) shift
 /* TYPE: Editing
  * Shift is added to the timeTags of all notes in the MKPart.
  * Implemented in terms of addNotes:timeShift:.
  */
{
  id aList = _MKLightweightArrayCopy(notes);
  id ret = [self addNotes:aList timeShift:shift];
  [aList release];
  return ret;
}

- scaleTime: (double) scale
 /* TYPE: Editing
  * Shift is added to the timeTags of all notes in the MKPart.
  * Implemented in terms of addNotes:timeShift:.
  */
{
  NSArray *aList = _MKLightweightArrayCopy(notes);
  MKNote  *mkn;
  SEL oaiSel = @selector(objectAtIndex:);
  IMP objectAtIndex = [aList methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(aList, oaiSel, (x))
  int i,n = [aList count];
  for (i = 0 ; i < n; i++) {
    mkn = OBJECTATINDEX(i);
    [mkn setTimeTag:  [mkn timeTag]  * scale];
    if ([mkn noteType] == MK_noteDur)
      [mkn setDur: [mkn dur] * scale];
  }
  [aList release];
  return self;
}
# undef OBJECTATINDEX

/* Accessing ------------------------------------------------------------- */

- firstTimeTag:(double) firstTimeTag lastTimeTag:(double) lastTimeTag
 /* TYPE: Querying the object
  * Creates and returns a List containing the receiver's MKNotes
  * between firstTimeTag and lastTimeTag in time order.
  * The notes are not copied. This method is useful in conjunction with
  * addNotes:timeShift:, removeNotes:, etc.
  */
{
  NSMutableArray *anArray;
  int firstEl,lastEl;
  if (!noteCount)
    return [[[NSMutableArray alloc] init] autorelease];
  sortIfNeeded(self);
  firstEl = findAtOrAfterTime(self,firstTimeTag);
  lastEl = findAtOrBeforeTime(self,lastTimeTag);
  if (firstEl == -1 || lastEl == -1 || firstEl > lastEl) {
    return [[[NSMutableArray alloc] init] autorelease];
  }
  anArray = [NSMutableArray arrayWithCapacity:(unsigned)(lastEl - firstEl) + 1];
  [anArray replaceObjectsInRange:NSMakeRange(0,0)
            withObjectsFromArray:self->notes
                           range:NSMakeRange(firstEl,(lastEl - firstEl) + 1)];
  return anArray;
}

-(unsigned)noteCount
 /* TYPE: Querying
  * Return the number of MKNotes in the receiver.
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

- (BOOL) hasSoundingNotes
{
  int  j, c;
  BOOL bFound = FALSE;
  SEL oaiSel = @selector(objectAtIndex:);
  IMP objectAtIndex = [notes methodForSelector: oaiSel];
# define OBJECTATINDEX(x)  (*objectAtIndex)(notes, oaiSel, (x))
  c = [notes count];
  for (j = 0; j < c; j++) {
    MKNote *aNote = OBJECTATINDEX(j);
	MKNoteType t = [aNote noteType];
    if (t == MK_noteDur || t == MK_noteOn) {
      bFound = TRUE;
      break;
    }
  }
  return bFound;
}
# undef OBJECTATINDEX


-(BOOL)isEmpty
 /* TYPE: Querying
  * Returns YES if the receiver contains no MKNotes.
  */
{
  return (noteCount == 0);
}

- atTime:(double) timeTag
 /* TYPE: Accessing MKNotes
  * Returns the first MKNote found at time timeTag, or nil if
  * no such MKNote.
  * Doesn't copy the MKNote.
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
       /* TYPE: Accessing MKNotes
  * Returns the first MKNote found at or after time timeTag,
  * or nil if no such MKNote.
  * Doesn't copy the MKNote.
  */
{
  int elReturned;
  sortIfNeeded(self);
  elReturned = findAtOrAfterTime(self,timeTag);
  if (elReturned == -1) return nil;
  return [[[self->notes objectAtIndex:elReturned] retain] autorelease];
}

- nth:(unsigned) n
 /* TYPE: Accessing MKNotes
  * Returns the nth MKNote (0-based), or nil if no such MKNote.
  * Doesn't copy the MKNote. */
{
  sortIfNeeded(self);
  return [[[notes objectAtIndex:n] retain] autorelease];
}

-atOrAfterTime:(double)timeTag nth:(unsigned) n
 /* TYPE: Accessing MKNotes
  * Returns the nth MKNote (0-based) at or after time timeTag,
  * or nil if no such MKNote.
  * Doesn't copy the MKNote.
  */
{
  int arrEnd;
  int el;
  sortIfNeeded(self);
  el = findAtOrAfterTime(self,timeTag);
  if (el == -1)
    return nil;

  arrEnd = [notes count];
  if (el + n >= arrEnd) {
    return nil;
  }
  return [[[notes objectAtIndex:el+n] retain] autorelease];
}

-atTime:(double)timeTag nth:(unsigned) n
 /* TYPE: Accessing MKNotes
  * Returns the nth MKNote (0-based) at time timeTag,
  * or nil if no such MKNote.
  * Doesn't copy the MKNote.
  */
{
  id aNote = [self atOrAfterTime:timeTag nth:n];
  if (!aNote)
    return nil;
  if ([aNote timeTag] == timeTag)
    return aNote;
  return nil;
}

-next:aNote
 /* TYPE: Accessing MKNotes
  * Returns the MKNote immediately following aNote, or nil
  * if no such MKNote.
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
 /* TYPE: Creating a MKPart
  * Creates and returns a new MKPart that contains
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
  /* TYPE: Accessing MKNotes
   * Returns the actual NSMutableArray of MKNotes in the receiver.
   * The MKNotes are not copied.
   * The NSMutableArray is not copied and is not guaranteed to be sorted.
   */
{
  return [[notes retain] autorelease];
}

- (NSMutableArray *) notes
  /* TYPE: Accessing MKNotes
  * Returns a Array of the MKNotes in the receiver, in time order.
  * The MKNotes *are* copied. (for the moment, but ideally not)
  * The list is autoreleased and should be retained if required.
  */
{
  sortIfNeeded(self);
  //    return _MKLightweightArrayCopy(notes); // LMS this should be (I think) the final version.
  // Joerg reports [notes mutableCopy] is needed to produce a mutable deep
  // copy, but this does not appear to be the case on GNUStep. Thus the MK
  // defines its own explicit deep array copy mechanism.
  return [_MKDeepMutableArrayCopy(notes) autorelease]; 
}

- (MKScore *) score
  /* TYPE: Querying
  * Returns the MKScore of the receiver's owner.
  */
{
  // we didn't allocate it, so we don't autorelease it.
  return score;
}

- (MKNote *) infoNote
  /* Returns 'header note', a collection of info associated with each MKPart,
  which may be used by the App in any way it wants. */
{
  return [[info retain] autorelease];
}

-setInfoNote:(MKNote *) aNote
  /* Sets 'header note', a collection of info associated with each MKPart,
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
  Archives MKNotes and info. Also archives MKScore using
  NXWriteObjectReference(). */
{
  NSString *str;
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
  NSMutableDictionary *tagTable;

  if ([aDecoder versionForClassName:@"MKPart"] == VERSION2) {
    score = [[aDecoder decodeObject] retain];
    [aDecoder decodeValuesOfObjCTypes:"@@ic@i",&notes,&info,&noteCount,&isSorted,
      &str,&_highestOrderTag];
    if (str) {
      MKNameObject(str,self);
      //            free(str);
    }
  }
  /* from awake (sb) */
  if ([MKScore _isUnarchiving])
    return self;
  tagTable = [NSMutableDictionary dictionary];
  [self _mapTags: tagTable];
  return self;
}

// for debugging, just return the concatenation of the note descriptions (which have newlines).
- (NSString *) description
{
  int i, nlc;
  NSMutableString *partDescription = [[NSMutableString alloc] initWithString: @"MKPart containing MKNotes:\n"];
  NSMutableArray *noteList = [self notes];
  MKNote *aNote;

  nlc = [noteList count];
  for(i = 0; i < nlc; i++) {
    aNote = [noteList objectAtIndex: i];
    [partDescription appendString: [aNote description]];
  }
  [partDescription appendFormat: @"With MKPart info note:\n%@", [[self infoNote] description]];

  return [partDescription autorelease];
}

@end

@implementation MKPart(Private)

-(void) _mapTags: (NSMutableDictionary *) hashTable
  /* Must be method to avoid loading MKScore. hashTable is a NSMutableDictionary object
  that maps ints to ints. */
{
  int oldTag,nc;
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

-(void)_setNoteSender: (MKNoteSender *) aNS
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

-(void)_unsetScore
  /* Private method. Sets score to nil.
  Here we have the classic retain cycle in that the MKPart is retained by
  it's MKScore (indirectly by MKScore retaining the NSArray of MKParts).
  The solution is that we don't release the score. */
{
  score = nil;
}

-_setScore:(id)newScore
  /* Removes receiver from the score it is a part of, if any. Does not
  add the receiver to newScore; just sets instance variable. It
  is illegal to remove an active performer.
  Here we have the classic retain cycle in that the MKPart is retained by
  it's MKScore (indirectly by MKScore retaining the NSArray of MKParts).
  The solution is that we don't retain the score. */
{
  id oldScore = score;
  if (score)
    [score removePart:self];
  score = newScore;
  return oldScore;
}

@end

