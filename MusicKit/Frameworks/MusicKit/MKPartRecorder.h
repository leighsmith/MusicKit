/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:48  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_PartRecorder_H___
#define __MK_PartRecorder_H___

#import "MKInstrument.h"
#import "timeunits.h"

@interface MKPartRecorder : MKInstrument
/* 
 * 
 * A PartRecorder is an Instrument that realizes Notes by adding copies
 * of them to a Part.  A PartRecorder's Part is set through the setPart:
 * method.  If the Part already contains Notes, the old Notes aren't
 * removed or otherwise affected by recording into the Part -- the
 * recorded Notes are merged in.
 * 
 * Each PartRecorder contains a single NoteReceiver object.  During a
 * performance, a PartPerformer receives Notes from its NoteReceiver,
 * copies them, and then adds them to its Part object.  The PartRecorder
 * gives each Note a new timeTag and, if it's a noteDur, a new duration.
 * The new timeTag reflects the time in the performance that the Note was
 * received by the object.  The timeTag and the duration are computed
 * as beats or seconds.  (Additionally, if the timeunit is "MK_timeTag", 
 * the Note's timeTag is used verbatim.)
 * 
 * You can create PartRecorders yourself, or you can use a ScoreRecorder
 * object to create a group of them for you.
 * 
 * CF: ScoreRecorder, Part
 * 
 */
{
    MKTimeUnit timeUnit;   /* How time is interpreted. */
    id noteReceiver;       /* The object's single NoteReceiver. */
    id part;               /* The object's Part. */
    BOOL compensatesDeltaT;

    /* The following for internal use only */
    id _scoreRecorder;
    BOOL _reservedPartRecorder2;
}

- init; 
 /* 
  * Inits the receiver by creating and adding its single
  * NoteReceiver.  You never invoke this method directly.  A subclass
  * implementation should send [super init] before performing its
  * own initialization.  The return value is ignored.  */

-setTimeUnit:(MKTimeUnit)aTimeUnit;
 /* See timeunits.h */
-(MKTimeUnit)timeUnit;
 /* See timeunits.h */

- setPart:aPart; 
 /* 
  * Sets aPart as the receiver's Part.  Returns the receiver.  
  */

- part; 
 /* Returns the receiver's Part object. */

- realizeNote:aNote fromNoteReceiver:aNoteReceiver; 
 /* 
  * Copies aNote, computes and sets the new Note's timeTag (and duration
  * if it's a noteDur), and then adds the new Note to the receiver's Part.
  * aNoteReceiver is ignored.  The timeTag and duration computations use
  * the makeTimeTag: and makeDur: methods defined in NoteRecorder.
  * Returns the receiver.  */

- copyWithZone:(NSZone *)zone; 
 /* 
  * Creates and returns a new PartRecorder as a copy of the
  * receiver.  The new object has its own NoteReciever object but adds
  * Notes to the same Part as the receiver.  */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives timeUnit. 
     Optionally archives part using NXWriteObjectReference().
     */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     Note that -init is not sent to newly unarchived objects.
     See write:. */
//- awake;
 /* Gets object ready for use. */

- setDeltaTCompensation:(BOOL)yesOrNo; /* default is NO */
- (BOOL)compensatesDeltaT;

@end



#endif
