/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$

  Defined In: The MusicKit
*/
/*
  $Log$
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
- freeNotes; 
- freeSelfOnly; 
- firstTimeTag:(double)firstTimeTag lastTimeTag:(double)lastTimeTag;
- addNote:aNote; 
- addNoteCopy:aNote; 
- removeNote:aNote; 
- removeNotes:aList; 
- addNoteCopies:aList timeShift:(double )shift; 
- addNotes:aList timeShift:(double )shift; 
- (void)removeAllObjects; 
- shiftTime:(double )shift; 
-(unsigned ) noteCount;
-(BOOL ) containsNote:aNote; 
-(BOOL ) isEmpty; 
- atTime:(double )timeTag; 
- atOrAfterTime:(double )timeTag; 
- nth:(unsigned )n; 
- atOrAfterTime:(double )timeTag nth:(unsigned )n; 
- atTime:(double )timeTag nth:(unsigned )n; 
- next:aNote; 
- copyWithZone:(NSZone *)zone; 
- copy;
- notes;
- score; 
- (MKNote *) infoNote; 
- setInfo:aNote; 
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
//- awake;

 /* Obsolete methods: */
+ new; 
//- (void)initialize;

@end

#endif
