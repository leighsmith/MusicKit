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
/*!
  @class MKScoreRecorder
  @brief A MKScoreRecorder is a pseudo-MKInstrument that adds MKNotes to the MKParts in a given MKScore.  
 
It does this by creating a MKPartRecorder, a true MKInstrument, for each of
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
    /*! @var partRecorders The object's collection of MKPartRecorders. */
    NSMutableArray *partRecorders;
    /*! @var score The object's MKScore. */
    MKScore *score;
    /*! @var timeUnit The unit the object's MKPartRecorders use to measure time; one of MK_second or MK_beat. */
    MKTimeUnit timeUnit;
    /*! @var partRecorderClass The MKPartRecorder subclass used. */
    Class partRecorderClass;
    BOOL compensatesDeltaT;

@protected
    BOOL _noteSeen;
}

/*!
  @brief Inits the receiver; you never invoke this method directly.

  A subclass implementation should send <tt>[super init]</tt>
  before performing its own initialization.
  @return Returns <b>self</b>
*/
- init; 

/*!
  @brief Removes and frees the receiver's current MKPartRecorders, sets its
  MKScore to <i>aScore</i>, and then creates and adds a MKPartRecorder for
  each MKPart in the MKScore.

  Subsequent changes to <i>aScore</i> (adding or removing MKParts) aren't seen by the receiver.
  If the receiver is in performance, this does nothing and returns <b>nil</b>, otherwise
  it returns the receiver.
  
  If you want to set the MKScore without freeing the current MKPartRecorders
  you should send <b>removePartRecorders</b> before invoking this method;
  the MKPartRecorders are then removed but not freed.
  @param  aScore is an MKScore instance.
  @return Returns an id.
*/
- setScore: (MKScore *) aScore; 

/*!
  @brief Returns the receiver's MKScore.
  @return Returns an MKScore.
*/
- (MKScore *) score; 

/*!
  @brief Creates and returns a MKScoreRecorder as a copy of the receiver.
 
  The new object has the same MKScore as the receiver, but contains its own set of MKPartRecorders.
 */
- copyWithZone: (NSZone *) zone; 

/*!
  @brief Removes the receiver's MKPartRecorders and sets its MKScore to <b>nil</b>.

  The MKPartRecorder objects aren't freed.
  @return Returns the receiver.
*/
- removePartRecorders; 

/*!
  @return Returns a MKTimeUnit.
  @brief Returns the receiver's time unit, either MK_second, MK_timeTag or MK_beat.
*/
- (MKTimeUnit) timeUnit;

/*!
  @brief Sets the receiver's time unit to <i>aTimeUnit</i>, one of MK_beat,
  MK_timeTag and MK_second, and forwards the 
  <b>setTimeUnit:</b><i>aTimeUnit</i> message to the receiver's MKPartRecorders.
  
  If the receiver is in performance, this does nothing and returns <b>nil</b>.
  Otherwise returns the receiver.
  @param  aTimeUnit is a MKTimeUnit.
  @return Returns an id.
*/
- setTimeUnit: (MKTimeUnit) aTimeUnit;

/*!
  @brief Returns a NSArray object that contains the receiver's MKPartRecorders.
  @return Returns an NSArray instance.
*/
- (NSArray *) partRecorders; 

/*!
  @brief Returns YES if the receiver is in performance, otherwise returns NO.
  @return Returns a BOOL.  
*/
- (BOOL) inPerformance;

/*!
  @brief You never invoke this method; it's invoked automatically when the
  first MKNote is received by any of the receiver's MKPartRecorders.

  The default does nothing; a subclass can implement this method for
  performance initialization.  The returns value is
  ignored.
  @param  aNote is an MKNote instance.
  @return Returns an id.
*/
- firstNote: (MKNote *) aNote; 

/*!
  @brief You never invoke this method; it's invoked automatically at the end
  of the performance.

  The default does nothing; a subclass can
  implement this method for post-performance cleanup.  A subclass
  version should always invoke <b>[super afterPerformance]</b>.  The
  return value is ignored.
  @return Returns an id.
*/
- afterPerformance; 

/*!
  @brief Returns a NSArray object that contains the receiver's MKNoteReceivers.
  @return Returns an NSArray.
*/
- (NSArray *) noteReceivers; 

/*!
  @brief Returns the receiver's MKPartRecorder for <i>aPart</i>, or <b>nil</b> if not found.
  @param  aPart is an MKPart instance.
  @return Returns an MKPartRecorder instance.
*/
- (MKPartRecorder *) partRecorderForPart: (MKPart *) aPart; 

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
- setPartRecorderClass: (Class) aPartRecorderSubclass;

/*! 
  @brief Returns the class used for MKPartRecorders, as set by <b>setPartRecorderClass:</b>.

  The default is MKPartRecorder itself. 
  @return Returns a Class.
*/
- (Class) partRecorderClass;

/* 
  You never send this message directly.  
  Archives partRecorders, timeUnit and partRecorderClass.
  Also optionally archives score.
 */
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* 
  You never send this message directly.  
 */
- (id) initWithCoder: (NSCoder *) aDecoder;
   
@end

#endif
