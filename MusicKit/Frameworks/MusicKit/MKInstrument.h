/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:45  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Instrument_H___
#define __MK_Instrument_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import "MKNoteReceiver.h"

@interface MKInstrument : NSObject
/* 
 * 
 * Instrument is an abstract class that defines the general mechanism for
 * obtaining and realizing Notes during a Music Kit performance.  Each
 * subclass of Instrument defines its particular manner of realization by
 * implementing realizeNote:fromNoteReceiver:.
 * 
 * Every Instrument contains a List of NoteReceivers, objects that
 * receive Notes during a performance.  Each subclass of Instrument
 * should implement its init method to automatically create and add
 * some number of NoteReceivers to a newly created instance.  When a
 * NoteReceiver receives a Note (through the receiveNote: method), it
 * causes realizeNote:fromNoteReceiver: to be sent to its Instrument with
 * the Note as the first argument and the NoteReceiver's id as the second
 * argument.
 * 
 * An Instrument is considered to be in performance from the time it
 * realizes its first Note until the peformance is over.
 * 
 * The Instrument subclasses provided by the Music Kit are:
 * 
 * Subclass                    Realization
 * 
 * NoteFilter           Processes the Note and sends it on.
 * NoteRecorder         Adds the Note to a Part or writes it to a file. 
 * SynthInstrument      Synthesizes a musical sound on the DSP.    
 *
 * CF:  NoteReceiver
 */
{
    NSMutableArray *noteReceivers; /* The object's List of NoteReceivers. */

    /* The following for internal use only */
    BOOL _noteSeen;
    void *_afterPerfMsgPtr;
}

- init; 
 /* 
  * Initializes the receiver.  You never invoke this method directly.  A
  * subclass implementation should send [super init] before
  * performing its own initialization.  The return value is ignored.  */

- realizeNote:aNote fromNoteReceiver:aNoteReceiver; 
 /* 
  * Realizes aNote in the manner defined by the subclass.  aNoteReceiver
  * is the NoteReceiver that received aNote.  The default implementation
  * does nothing.  You never invoke this method; it's automatically
  * invoked as the receiver's NoteReceivers receive Notes.  The return
  * value is ignored.  Keep in mind that notes must be copied on write or
  * store.  */
 
- firstNote:aNote; 
 /* 
  * You never invoke this method; it's invoked just before the receiver
  * realizes its first Note.  A subclass can implement this method to
  * perform pre-realization initialization.  aNote, the Note that the
  * Instrument is about to realize, is provided as a convenience and can
  * be ignored in a subclass implementation.  The receiver is considered
  * to be in performance after this method returns.  The return value is
  * ignored.  */

- noteReceivers; 
 /* 
  * Returns a copy of the receiver's List of NoteReceivers.  The
  * NoteReceivers themselves aren't copied.  It's the sender's
  * responsibility to free the List.  */

-(BOOL ) isNoteReceiverPresent:aNoteReceiver; 
 /* 
  * Returns YES if aNoteReceiver is in the receiver's NoteReceiver List.
  * Otherwise returns NO.  */

- addNoteReceiver:aNoteReceiver; 
 /* 
  * Adds aNoteReceiver to the receiver, first removing it from it's
  * current Instrument, if any.  If the receiver is in performance, does
  * nothing and returns nil, otherwise returns aNoteReceiver.  */

- removeNoteReceiver:aNoteReceiver; 
 /* 
  * Removes aNoteReceiver from the receiver's NoteReceiver List.  If the
  * receiver is in performance, does nothing and returns nil, otherwise
  * returns aNoteReceiver.  */

- (void)dealloc; 
 /* 
  * Sends freeNoteReceivers to self and then frees the receiver.  If the
  * receiver is in performance, does nothing and returns the receiver,
  * otherwise returns nil.  */

-disconnectNoteReceivers;
 /* 
  * Sends disconnect to each of the receiver's NoteReceivers.
  */

-removeFromPerformance;
 /* 
  * This method is used to remove an Instrument from a performance that is
  * in progress and is continuing.
  * Sends [self disconnectNoteReceivers] and invokes the afterPerformance 
  * method and returns self.  
  * If the receiver is not in performance, does nothing and returns nil.
  */

- freeNoteReceivers; 
 /* 
  * Disconnects, removes, and frees the receiver's NoteReceivers.  Returns
  * the receiver.  */

- removeNoteReceivers; 
 /* 
  * Removes all the receiver's NoteReceivers but neither disconnects nor
  * frees them. Returns the receiver.  */

-(BOOL ) inPerformance;
 /* 
  * Returns YES if the receiver is in performance (it has received its first
  * Note).  Otherwise returns NO.  
  */

- afterPerformance; 
 /* 
  * You never invoke this method; it's automatically invoked when the
  * performance is finished.  A subclass can implement this method to do
  * post-performance cleanup.  The default implementation does nothing;
  * the return value is ignored.  */

- copy; 
 /* 
    Same as [self copyFromZone:[self zone]] 
  */

- copyWithZone:(NSZone *)zone; 
 /* 
  * Creates and returns a new Instrument as a copy of the receiver.  The
  * new object has its own NoteReceiver collection that contains copies of
  * the receiver's NoteReceivers.  The new NoteReceivers' connections (see
  * the NoteReceiver class) are copied from the NoteReceivers in the
  * receiver.  */

- noteReceiver; 
 /* 
  * Returns the first NoteReceiver in the receiver's List.  This is useful
  * for Instruments that have only one NoteReceiver.  */

- (void)encodeWithCoder:(NSCoder *)aCoder;
 /* 
  * You never send this message directly.  Should be invoked with
  * NXWriteRootObject().  Archives noteReceiver List. */

- (id)initWithCoder:(NSCoder *)aDecoder;
 /* 
  * You never send this message directly.  
  * Should be invoked via NXReadObject(). 
  * Note that -init is not sent to newly unarchived objects.
  * See write:. */

 /* Obsolete methods: */
+ new; 
//- (void)initialize;

@end



#endif
