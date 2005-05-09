/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKScoreRecorder is a pseudo-MKInstrument that adds MKNotes to the MKParts in
    a given MKScore.  It does this by creating a MKPartRecorder, a true
    MKInstrument, for each of the MKScore's MKPart objects.  A MKScoreRecorder's
    MKScore is set through the setScore: method.  If you add MKParts to or
    remove MKParts from the MKScore after sending the setScore: message, the
    changes will not be seen by the MKScoreRecorder.  For example, if you
    add a MKPart to the MKScore, the MKScoreRecorder won't create an additional
    MKPartRecorder for that MKPart.

    A MKScoreRecorder can access a MKPartRecorder by the name of the MKPart with
    which it's associated.  It can also set the time unit of all its
    MKPartRecorders through a single message, setTimeUnit:.

    A MKScoreRecorder is said to be in performance from the time any of its
    MKPartRecorders receives a MKNote until the performance is finished.

  CF: MKPartRecorder

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.7  2005/05/09 15:52:54  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.6  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.5  2000/11/25 23:01:40  leigh
  Enforced ivar privacy, removed -releasePartRecorders, doco cleanup, correctly typed partRecorderClass to Class

  Revision 1.4  2000/06/09 02:56:02  leigh
  Comment cleanup and correct typing of ivars

  Revision 1.3  2000/04/25 02:08:40  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKScoreRecorder
  @brief

A MKScoreRecorder is a pseudo-MKInstrument that adds MKNotes to the MKParts in a given
MKScore.  It does this by creating a MKPartRecorder, a true MKInstrument, for each of
the MKScore's MKPart objects.  A MKScoreRecorder's MKScore is set through the
<b>setScore:</b> method.  If you add MKParts to or remove MKParts from the MKScore
after sending the <b>setScore:</b> message, the changes will not be seen by the
MKScoreRecorder.  

A MKScoreRecorder can access a MKPartRecorder by the name of the MKPart with which
it's associated.  It can also set the time unit of all its MKPartRecorders through
a single message, <b>setTimeUnit:</b>.

A MKScoreRecorder is said to be in performance from the time any of its
MKPartRecorders receives a MKNote until the performance is finished.

  @see  MKPartRecorder
*/
#ifndef __MK_ScoreRecorder_H___
#define __MK_ScoreRecorder_H___

#import <Foundation/NSObject.h>
#import "MKScore.h"

@interface MKScoreRecorder : NSObject
{
    NSMutableArray *partRecorders; /* The object's collection of MKPartRecorders. */
    MKScore *score;                /* The object's MKScore. */
    MKTimeUnit timeUnit;           // Unit the object's MKPartRecorders use to 
                                   // measure time; one of MK_second or MK_beat.
    Class partRecorderClass;       /* The MKPartRecorder subclass used. */
    BOOL compensatesDeltaT;

@protected
    BOOL _noteSeen;
}

/*!
  @return Returns <b>self</b>
  @brief Inits the receiver; you never invoke this method directly.

  
  A subclass implementation should send <tt>[super init]</tt>
  before performing its own initialization.
*/
- init; 

/*!
  @param  aScore is an id.
  @return Returns an id.
  @brief Removes and frees the receiver's current PartRecorders, sets its
  MKScore to <i>aScore</i>, and then creates and adds a MKPartRecorder for
  each MKPart in the MKScore.

  Subsequent changes to <i>aScore</i> (adding
  or removing MKParts) aren't seen by the receiver.  If the receiver is
  in performance, this does nothing and returns <b>nil</b>, otherwise
  it returns the receiver.
  
  If you want to set the MKScore without freeing the current PartRecorders
  you should send <b>removePartRecorders</b> before invoking this method;
  the PartRecorders are then removed but not freed.
*/
- setScore: (MKScore *) aScore; 

/*!
  @return Returns an MKScore.
  @brief Returns the receiver's MKScore.

  
*/
- (MKScore *) score; 

- copyWithZone:(NSZone *)zone; 
 /* 
  * Creates and returns a MKScoreRecorder as a copy of the receiver.  The
  * new object has the same MKScore as the receiver, but contains its own
  * set of MKPartRecorders.
  */


/*!
  @return Returns an id.
  @brief Creates and returns a MKScoreRecorder as a copy of the receiver.

  The
  new object has the same MKScore as the receiver, but contains its own
  set of PartRecorders.  Same as [self copyFromZone:[self zone]];
*/
-copy;

/*!
  @return Returns an id.
  @brief Removes the receiver's MKPartRecorders and sets its MKScore to
  <b>nil</b>.

  (The MKPartRecorder objects aren't freed.)  Returns the
  receiver.
*/
- removePartRecorders; 

- (void)dealloc; 
 /* 
  * Frees the receiver and its MKPartRecorders.  You never directly invoke this method. 
  */

/*!
  @return Returns a MKTimeUnit.
  @brief Returns the receiver's time unit, either MK_second, MK_timeTag or
  MK_beat.

  
*/
- (MKTimeUnit) timeUnit;

/*!
  @param  aTimeUnit is a MKTimeUnit.
  @return Returns an id.
  @brief Sets the receiver's time unit to <i>aTimeUnit</i>, one of MK_beat,
  MK_timeTag and MK_second, and forwards the 
  <b>setTimeUnit:</b><i>aTimeUnit</i> message to the receiver's PartRecorders.

  
  If the receiver is in performance, this does nothing and returns <b>nil</b>.
  Otherwise returns the receiver.
*/
- setTimeUnit:(MKTimeUnit) aTimeUnit;

/*!
  @return Returns an id.
  @brief Returns a NSArray object that contains the receiver's MKPartRecorders.

  
*/
- partRecorders; 

/*!
  @return Returns a BOOL.
  @brief Returns YES if the receiver is in performance, otherwise returns
  NO.

  
*/
- (BOOL) inPerformance;

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief You never invoke this method; it's invoked automatically when the
  first MKNote is received by any of the receiver's MKPartRecorders.

  The
  default does nothing; a subclass can implement this method for
  performance initialization.  The returns value is
  ignored.
*/
- firstNote:aNote; 

/*!
  @return Returns an id.
  @brief You never invoke this method; it's invoked automatically at the end
  of the performance.

  The default does nothing; a subclass can
  implement this method for post-performance cleanup.  A subclass
  version should always invoke <b>[super afterPerformance]</b>.  The
  return value is ignored.
*/
- afterPerformance; 

/*!
  @return Returns an id.
  @brief Returns a NSArray object that contains the receiver's MKNoteReceivers.

  
  It's the sender's responsibility to free the NSArray.
*/
- noteReceivers; 

/*!
  @param  aPart is an id.
  @return Returns an id.
  @brief Returns the receiver's MKPartRecorder for <i>aPart</i>, or <b>nil</b>
  if not found.

  
*/
- partRecorderForPart:aPart; 

/*!
  @param  aPartRecorderSubclass is an id.
  @return Returns an id.
  @brief Normally, MKScoreRecorders create instances of the MKPartRecorder class.

  
  This method allows you to specify that instances of some
  MKPartRecorder subclass be created instead.  If 
  <i>aPartRecorderSubclass</i> is not a subclass of MKPartRecorder
  (or MKPartRecorder itself), this method has no effect and returns nil.
  Otherwise, it returns self.
*/
-setPartRecorderClass:aPartRecorderSubclass;

/*! 
  @return Returns a Class.
  @brief Returns the class used for MKPartRecorders, as set by 
  <b>setPartRecorderClass:</b>.

  The default is MKPartRecorder itself. 
*/
-partRecorderClass;

  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives partRecorders, timeUnit and partRecorderClass.
     Also optionally archives score using NXWriteObjectReference().
     */
- (void)encodeWithCoder:(NSCoder *)aCoder;

  /* 
     You never send this message directly.  
     Should be invoked with NXReadObject(). 
     */
- (id)initWithCoder:(NSCoder *)aDecoder;
   
@end

#endif
