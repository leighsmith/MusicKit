/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$

  Defined In: The MusicKit
*/
/*
  $Log$
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
#import "MKNote.h"
#import "MKScore.h"

@interface MKPart : NSObject
{
    MKScore *score; /* The score to which this Part belongs. */
    NSMutableArray *notes; /* List of Notes. */
    MKNote *info; /* A Note used to store an arbitrary collection of info associated with the Part. */

    int noteCount; /* Number of Notes in the Part. */
    BOOL isSorted; /* YES if the receiver is sorted. */

            /* The following for internal use only */
    id _aNoteSender; /* Used only by ScorefilePerformers. */
    id _activePerformanceObjs;
    int _highestOrderTag; /* For disambiguating binary search on identical time tagged Notes. */
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
