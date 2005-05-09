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
/*!
  @class MKPartRecorder
  @brief

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

  @see  MKScoreRecorder, MKPart
*/
#ifndef __MK_PartRecorder_H___
#define __MK_PartRecorder_H___

#import "MKInstrument.h"
#import "timeunits.h"

@interface MKPartRecorder : MKInstrument
{
    /*! @var timeUnit Enumerates possible methods of how time is interpreted. */
    MKTimeUnit timeUnit;                
    /*! @var noteReceiver The object's single NoteReceiver. */
    MKNoteReceiver *noteReceiver;
    /*! @var part The MKPartRecorder instance's MKPart. */
    MKPart *part; 
    BOOL compensatesDeltaT;

@private
    id _scoreRecorder;
}

/*!
  @return Returns an id.
  @brief Initializes the receiver by creating and adding its single
  MKNoteReceiver.

  You must invoke this method when creating a new
  object.  A subclass implementation should send <b>[super init]</b>
  before performing its own initialization.  
*/
- init; 

/*!
  @param  aTimeUnit is a MKTimeUnit.
  @return Returns an id.
  @brief Sets the receiver's <b>timeUnit</b> instance variable to
  <i>aTimeUnit</i>, one of <b>MK_second</b>, <b>MK_beat</b> or <b>MK_timeTag</b>.

  The
  default is <b>MK_second</b>.

	  See timeunits.h
 */
- setTimeUnit: (MKTimeUnit) aTimeUnit;

/*!
  @return Returns a MKTimeUnit.
  @brief Returns the receiver's <b>timeUnit</b>, either MK_second,
  MK_timeTag, or MK_beat.

  

  See timeunits.h
 */
- (MKTimeUnit) timeUnit;

/*!
  @param  aPart is an MKPart instance.
  @brief Sets <i>aPart</i> as the receiver's MKPart.

  Returns the
  receiver.
*/
- (void) setPart: (MKPart *) aPart; 

/*!
  @return Returns an MKPart instance.
  @brief Returns the receiver's MKPart object.

  
*/
- (MKPart *) part; 

/*!
  @param  aNote is an MKNote instance.
  @param  aNoteReceiver is an MKNoteReceiver instance.
  @return Returns an id.
  @brief Copies <i>aNote</i>, computes and sets the new MKNote's timeTag (and
  duration if it's a noteDur), and then adds the new MKNote to the
  receiver's MKPart.

  <i>aNoteReceiver</i> is ignored. The timeTag
  and duration computations use the <tt>makeTimeTag:</tt> and <tt>makeDur:</tt>
  methods defined in NoteRecorder. Returns the receiver.
*/
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver; 

/*!
  @param  zone is an NSZone.
  @return Returns an id.
  @brief Creates and returns a new MKPartRecorder as a copy of the
  receiver.

  The new object has its own MKNoteReceiver object but adds
  MKNotes to the same MKPart as the receiver.
*/
- copyWithZone: (NSZone *) zone; 

/* 
  You never send this message directly.  
  Should be invoked with NXWriteRootObject(). 
  Invokes superclass write: then archives timeUnit. 
  Optionally archives part using NXWriteObjectReference().
 */
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* 
 You never send this message directly.  
 Note that -init is not sent to newly unarchived objects.
 See write:. 
*/
- (id) initWithCoder: (NSCoder *) aDecoder;

/*!
  @brief Assigns whether to use time compensation.
  @param yesOrNo
  
  Default is NO. 
 */
- setDeltaTCompensation: (BOOL) yesOrNo;

/*!
  @brief Returns whether to use time compensation.
  
  Default is NO. 
 */
- (BOOL) compensatesDeltaT;

@end

#endif
