/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKScoreRecorder is a pseudo-Instrument that adds MKNotes to the MKParts in
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
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2000/11/25 23:01:40  leigh
  Enforced ivar privacy, removed -releasePartRecorders, doco cleanup, correctly typed partRecorderClass to Class

  Revision 1.4  2000/06/09 02:56:02  leigh
  Comment cleanup and correct typing of ivars

  Revision 1.3  2000/04/25 02:08:40  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

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

- init; 
 /* 
  * Inits the receiver; you never invoke this method directly.
  * A subclass implementation
  * should send [super init] before performing its own initialization.
  * The return value is ignored.  
  */

- setScore: (MKScore *) aScore; 
 /* 
  * Removes and frees the receiver's current MKPartRecorders, sets its MKScore
  * to aScore, and then creates and adds a MKPartRecorder for each MKPart in
  * the MKScore.  Subsequent changes to aScore (adding or removing Parts)
  * aren't seen by the receiver.  If the receiver is in performance, this
  * does nothing and returns nil, otherwise it returns the receiver.
  * 
  * If you want to set the MKScore without freeing the current MKPartRecorders you
  * should send removePartRecorders before invoking this method; the
  * MKPartRecorders are then removed but not freed.  
  */

- (MKScore *) score; 
 /* Returns the receiver's MKScore. */

- copyWithZone:(NSZone *)zone; 
 /* 
  * Creates and returns a MKScoreRecorder as a copy of the receiver.  The
  * new object has the same MKScore as the receiver, but contains its own
  * set of MKPartRecorders.
  */

-copy;
 /* Same as [self copyFromZone:[self zone]]; */

- removePartRecorders; 
 /* 
  * Removes the receiver's MKPartRecorders and sets its MKScore to nil.  (The
  * MKPartRecorder objects aren't freed.)  Returns the receiver.  
  */

- (void)dealloc; 
 /* 
  * Frees the receiver and its MKPartRecorders.  You never directly invoke this method. 
  */

- (MKTimeUnit)timeUnit;
 /* Returns the receiver's time unit, either MK_second or MK_beat. */

- setTimeUnit:(MKTimeUnit)aTimeUnit;
 /* 
  * Sets the receiver's time unit to aTimeUnit, one of MK_beat and
  * MK_second, and forwards the setTimeUnit:aTimeUnit message to the
  * receiver's MKPartRecorders.  If the receiver is in performance, this
  * does nothing and returns nil.  Otherwise returns the receiver.
  */

- partRecorders; 
 /* 
  * Returns a NSArray object that contains the receiver's MKPartRecorders.
  * It's the sender's responsibility to free the NSArray.
  */

- (BOOL )inPerformance;
 /* 
  * Returns YES if the receiver is in performance, otherwise returns NO.
  */

- firstNote:aNote; 
 /* 
  * You never invoke this method; it's invoked automatically when the
  * first MKNote is received by any of the receiver's MKPartRecorders.  The
  * default does nothing; a subclass can implement this method for
  * performance initialization.  The returns value is ignored.
  */

- afterPerformance; 
 /* 
  * You never invoke this method; it's invoked automatically at the end of
  * the performance.  The default does nothing; a subclass can implement
  * this method for post-performance cleanup.  A subclass version should
  * always invoke [super afterPerformance].  The return value is ignored.
  */

- noteReceivers; 
 /* 
  * Returns a NSArray object that contains the receiver's MKNoteReceivers.  You
  * must free the NSArray yourself when you're done with it.
  */

- partRecorderForPart:aPart; 
 /* 
  * Returns the receiver's MKPartRecorder for aPart, or nil if not found.
  */ 

-setPartRecorderClass:aPartRecorderSubclass;
 /* Normally, ScoreRecorders create instances of the MKPartRecorder class.
   This method allows you to specify that instances of some MKPartRecorder
   subclass be created instead. If aPartRecorderSubclass is not 
   a subclass of MKPartRecorder (or MKPartRecorder itself), this method has 
   no effect and returns nil. Otherwise, it returns self.
  */
-partRecorderClass;
 /* Returns the class used for MKPartRecorders, as set by 
   setPartRecorderClass:. The default is MKPartRecorder itself. */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives partRecorders, timeUnit and partRecorderClass.
     Also optionally archives score using NXWriteObjectReference().
     */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXReadObject(). 
     */

//+ new; 
 /* Obsolete */
   
@end



#endif
