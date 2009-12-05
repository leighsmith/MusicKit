/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.3  2006/02/05 17:57:10  leighsmith
  Cleaned up prototypes for Xcode 2.2 as it is much more strict about mixing id with a defined type

  Revision 1.2  1999/07/29 01:25:54  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__Note_H___
#define __MK__Note_H___

#import "MKNote.h"

#import "_MKParameter.h"

/* Note functions */
extern void _MKSetNoteType(MKNote *aNote, MKNoteType aType);
extern void _MKSetNoteTag(MKNote *aNote, int aTag);
extern void _MKSetNoteDur(MKNote *aNote, double dur);
extern int  _MKGetPar(NSString *aName, id *aPar);
extern id   _MKWriteNote2(MKNote *aNote, id aPart, _MKScoreOutStruct *p);
extern int  _MKNoteCompare(const void *el1, const void *el2);
extern void _MKMakePlaceHolder(MKNote *aNote);
extern BOOL _MKNoteIsPlaceHolder(MKNote *aNote);
extern void _MKWriteParameters(MKNote *aNote, NSMutableData *aStream, _MKScoreOutStruct *p);
extern void _MKNoteAddParameter(id aNote, _MKParameter *aPar);
extern void _MKNoteSetMatchTimeTag(id aNote, BOOL yesOrNo);
extern void _MKNoteShiftTimeTag(MKNote *aNote, double timeShift);

@interface MKNote(Private)

-_unionWith:aNote;
-_splitNoteDurNoCopy;
-(void)_setPerformer:anObj;
- _setPartLink:aPart order:(int)theOrder;
-_noteOffForNoteDur;

@end

#endif
