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
  Portions Copyright (c) 1994 Stanford University.  
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2000/11/25 22:56:48  leigh
  Enforced ivar privacy

  Revision 1.3  2000/03/29 02:57:04  leigh
  Cleaned up doco and ivar declarations

  Revision 1.2  1999/07/29 01:25:48  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKPartRecorder
  @discussion

A MKPartRecorder is an MKInstrument that realizes MKNotes by adding copies of
them to a MKPart.  A MKPartRecorder's MKPart is set through the <b>setPart:</b>
method.  If the MKPart already contains MKNotes, the old MKNotes aren't removed
or otherwise affected by recording into the MKPart - the recorded MKNotes are
merged in.

Each MKPartRecorder contains a single MKNoteReceiver object.  During a
performance, a MKPartPerformer receives MKNotes from its MKNoteReceiver, copies
them, and then adds them to its MKPart object.  Each MKNote is given a new (but
not necessarily different) timeTag; if the MKNote is a noteDur, it's also given
a new duration.  The timeTag and duration are computed either as beats or as
seconds, depending on the value of the <b>timeUnit</b> instance variable.  If
<b>timeUnit</b> is set to MK_second, the default, the new values are in seconds
from the beginning of the performance.  If it's set to MK_beat, they're computed
as beats.  If it's set to MK_timeTag, the new values are derived from the
timeTag value in the MKNote itself.  For example, when recording from MKMidi, you
may want to use MK_timeTag.

You can create MKPartRecorders yourself, or you can use a MKScoreRecorder object
to create a group of them for you.

See also:  MKScoreRecorder, MKPart
*/
#ifndef __MK_PartRecorder_H___
#define __MK_PartRecorder_H___

#import "MKInstrument.h"
#import "timeunits.h"

@interface MKPartRecorder : MKInstrument
{
    MKTimeUnit timeUnit;                /* How time is interpreted. */
    MKNoteReceiver *noteReceiver;       /* The object's single NoteReceiver. */
    MKPart *part;                       /* The object's MKPart. */
    BOOL compensatesDeltaT;

@private
    id _scoreRecorder;
}

/*!
  @method init
  @result Returns an id.
  @discussion Initializes the receiver by creating and adding its single
              MKNoteReceiver.  You must invoke this method when creating a new
              object.  A subclass implementation should send <b>[super init]</b>
              before performing its own initialization.  
*/
- init; 

/*!
  @method setTimeUnit:
  @param  aTimeUnit is a MKTimeUnit.
  @result Returns an id.
  @discussion Sets the receiver's <b>timeUnit</b>instance variable to
              <i>aTimeUnit, </i> one of MK_second, MK_beat or MK_timeTag.  The
              default is MK_second.
*/
-setTimeUnit:(MKTimeUnit) aTimeUnit;
 /* See timeunits.h */

/*!
  @method timeUnit
  @result Returns a MKTimeUnit.
  @discussion Returns the receiver's <b>timeUnit</b>, either MK_second,
              MK_timeTag, or MK_beat.
*/
-(MKTimeUnit)timeUnit;
 /* See timeunits.h */

/*!
  @method setPart:
  @param  aPart is an id.
  @result Returns an id.
  @discussion Sets <i>aPart</i> as the receiver's MKPart.  Returns the
              receiver.
*/
- setPart:aPart; 

/*!
  @method part
  @result Returns an id.
  @discussion Returns the receiver's MKPart object.
*/
- part; 

/*!
  @method realizeNote:fromNoteReceiver:
  @param  aNote is an id.
  @param  aNoteReceiver is an id.
  @result Returns an id.
  @discussion Copies <i>aNote</i>, computes and sets the new MKNote's timeTag (and
              duration if it's a noteDur), and then adds the new MKNote to the
              receiver's MKPart.  <i>aNoteReceiver</i> is ignored. The timeTag
              and duration computations use the <tt>makeTimeTag:</tt> and <tt>makeDur:</tt>
              methods defined in NoteRecorder. Returns the receiver.
*/
- realizeNote:aNote fromNoteReceiver:aNoteReceiver; 

/*!
  @method copyWithZone:
  @param  zone is an NSZone.
  @result Returns an id.
  @discussion Creates and returns a new MKPartRecorder as a copy of the
              receiver.  The new object has its own MKNoteReceiver object but adds
              MKNotes to the same MKPart as the receiver.
*/
- copyWithZone:(NSZone *)zone; 

  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives timeUnit. 
     Optionally archives part using NXWriteObjectReference().
     */
- (void)encodeWithCoder:(NSCoder *)aCoder;

  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     Note that -init is not sent to newly unarchived objects.
     See write:. */
- (id)initWithCoder:(NSCoder *)aDecoder;

- setDeltaTCompensation:(BOOL)yesOrNo; /* default is NO */
- (BOOL)compensatesDeltaT;

@end



#endif
