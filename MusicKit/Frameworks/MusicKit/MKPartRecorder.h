/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKPartRecorder is an MKInstrument that realizes MKNotes by adding copies
    of them to a MKPart.  A MKPartRecorder's MKPart is set through the setPart:
    method.  If the MKPart already contains MKNotes, the old MKNotes aren't
    removed or otherwise affected by recording into the MKPart -- the
    recorded MKNotes are merged in.
  
    Each MKPartRecorder contains a single MKNoteReceiver object.  During a
    performance, a MKPartPerformer receives MKNotes from its MKNoteReceiver,
    copies them, and then adds them to its MKPart object.  The MKPartRecorder
    gives each MKNote a new timeTag and, if it's a noteDur, a new duration.
    The new timeTag reflects the time in the performance that the MKNote was
    received by the object.  The timeTag and the duration are computed
    as beats or seconds.  (Additionally, if the timeunit is "MK_timeTag",
    the MKNote's timeTag is used verbatim.)
  
    You can create MKPartRecorders yourself, or you can use a MKScoreRecorder
    object to create a group of them for you.
  
    CF: MKScoreRecorder, MKPart

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.4  2000/11/25 22:56:48  leigh
  Enforced ivar privacy

  Revision 1.3  2000/03/29 02:57:04  leigh
  Cleaned up doco and ivar declarations

  Revision 1.2  1999/07/29 01:25:48  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_PartRecorder_H___
#define __MK_PartRecorder_H___

#import "MKInstrument.h"
#import "timeunits.h"

@interface MKPartRecorder : MKInstrument
{
    MKTimeUnit timeUnit;                /* How time is interpreted. */
    MKNoteReceiver *noteReceiver;       /* The object's single NoteReceiver. */
    MKPart *part;                       /* The object's Part. */
    BOOL compensatesDeltaT;

@private
    id _scoreRecorder;
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
