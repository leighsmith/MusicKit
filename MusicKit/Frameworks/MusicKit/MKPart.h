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
   
    To get a sorted copy of the NSArray of notes use the -notes method.
    To get the NSArray of notes itself, use the -notesNoCopy method.
      -notesNoCopy does not guarantee the MKNotes are sorted.
    If you want to examine the MKNotes in-place sorted, first send -sort, then
      -notesNoCopy.
   
    You can find out if the NSArray is currently sorted by the -isSorted method.
   
  Original Author: David A. Jaffe
  
  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.8  2000/11/25 22:55:56  leigh
  Enforced ivar privacy

  Revision 1.7  2000/05/06 00:31:59  leigh
  Converted tagTable to NSMutableDictionary

  Revision 1.6  2000/04/25 02:11:01  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.5  2000/04/10 18:05:01  leigh
  Typed parameters to methods to reduce warnings for client applications

  Revision 1.4  1999/09/20 02:46:53  leigh
  Added description method

  Revision 1.3  1999/09/04 22:02:18  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.2  1999/07/29 01:25:47  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Part_H___
#define __MK_Part_H___

#import <Foundation/NSObject.h>

@class MKNote;
@class MKScore;
@class MKNoteSender;

@interface MKPart : NSObject
{
    MKScore *score;         /* The score to which this MKPart belongs. */
    NSMutableArray *notes;  /* NSArray of MKNotes. */
    MKNote *info;           /* A MKNote used to store an arbitrary collection of info associated with the MKPart. */
    int noteCount;          /* Number of MKNotes in the MKPart. */
    BOOL isSorted;          /* YES if the receiver is sorted. */

@private
    MKNoteSender *_aNoteSender; /* Used only by MKScorefilePerformers. */
    NSMutableArray *_activePerformanceObjs;
    int _highestOrderTag;       /* For disambiguating binary search on identical time tagged MKNotes. */
}
 
- sort;
- (BOOL)isSorted;
- notesNoCopy;
- combineNotes; 
- splitNotes; 
- addToScore:newScore; 
- removeFromScore; 
- init; 
- (void)dealloc;
- releaseNotes;
- releaseSelfOnly; 
- firstTimeTag:(double)firstTimeTag lastTimeTag:(double)lastTimeTag;
- addNote: (MKNote *) aNote;
- addNoteCopy: (MKNote *) aNote;
- removeNote: (MKNote *) aNote; 
- removeNotes: (NSArray *) aList;
- addNoteCopies: (NSArray *) aList timeShift:(double) shift;
- addNotes: (NSArray *) aList timeShift:(double) shift; 
- (void)removeAllObjects; 
- shiftTime:(double) shift; 
-(unsigned) noteCount;
-(BOOL) containsNote:aNote; 
-(BOOL) isEmpty; 
- atTime:(double )timeTag; 
- atOrAfterTime:(double )timeTag; 
- nth:(unsigned )n; 
- atOrAfterTime:(double )timeTag nth:(unsigned )n; 
- atTime:(double )timeTag nth:(unsigned )n;
- next: (MKNote *) aNote; 
- copyWithZone:(NSZone *)zone; 
- copy;
- (NSMutableArray *) notes;
- (MKScore *) score; 
- (MKNote *) infoNote; 
- setInfoNote:(MKNote *) aNote;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (NSString *) description;

 /* Obsolete methods: */
+ new; 
//- (void)initialize;

@end

#endif
