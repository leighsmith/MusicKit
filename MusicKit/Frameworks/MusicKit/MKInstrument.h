/*
  $Id$
  Defined In: The MusicKit

 Description: 
   MKInstrument is an abstract class that defines the general mechanism for
   obtaining and realizing MKNotes during a MusicKit performance.  Each
   subclass of MKInstrument defines its particular manner of realization by
   implementing realizeNote:fromNoteReceiver:.
  
   Every MKInstrument contains a NSMutableArray of MKNoteReceivers, objects
   that receive MKNotes during a performance.  Each subclass of MKInstrument
   should implement its init method to automatically create and add
   some number of MKNoteReceivers to a newly created instance.  When a
   MKNoteReceiver receives a MKNote (through the receiveNote: method), it
   causes realizeNote:fromNoteReceiver: to be sent to its MKInstrument with
   the MKNote as the first argument and the MKNoteReceiver's id as the second
   argument.
  
   An MKInstrument is considered to be in performance from the time it
   realizes its first MKNote until the peformance is over.
  
   The MKInstrument subclasses provided by the MusicKit are:
  
   Subclass             Realization
   --------             -----------
   MKNoteFilter         Processes the MKNote and sends it on.
   MKNoteRecorder       Adds the MKNote to a MKPart or writes it to a file.
   MKSynthInstrument    Synthesizes a musical sound on the DSP.
  
   CF: MKNoteReceiver

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.8  2001/08/27 19:59:09  leighsmith
  Added allNotesOff as a abstract instance method (since nearly all instruments implemented this anyway) and this provides a mechanism to shut off any sounding notes when a MKNoteReceiver is squelched

  Revision 1.7  2000/11/25 22:52:14  leigh
  Enforced ivar privacy

  Revision 1.6  2000/05/13 17:22:09  leigh
  Added indexOfNoteReciever method

  Revision 1.5  2000/04/25 02:11:02  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.4  2000/04/16 04:16:53  leigh
  class typing

  Revision 1.3  1999/09/20 03:06:50  leigh
  Cleaned up documentation.

  Revision 1.2  1999/07/29 01:25:45  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Instrument_H___
#define __MK_Instrument_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import "MKNote.h"
#import "MKNoteReceiver.h"

@interface MKInstrument: NSObject
{
    NSMutableArray *noteReceivers; /* The object's array of MKNoteReceivers. */

@protected
    BOOL _noteSeen;
    void *_afterPerfMsgPtr;
}

- init; 
 /* 
  * Initializes the receiver.  You never invoke this method directly.  A
  * subclass implementation should send [super init] before
  * performing its own initialization.  The return value is ignored.  */

- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;
 /* 
  * Realizes aNote in the manner defined by the subclass.  aNoteReceiver
  * is the NoteReceiver that received aNote.  The default implementation
  * does nothing.  You never invoke this method; it's automatically
  * invoked as the receiver's NoteReceivers receive Notes.  The return
  * value is ignored.  Keep in mind that notes must be copied on write or
  * store.  */

- firstNote: (MKNote *) aNote;
 /* 
  * You never invoke this method; it's invoked just before the receiver
  * realizes its first Note.  A subclass can implement this method to
  * perform pre-realization initialization.  aNote, the Note that the
  * Instrument is about to realize, is provided as a convenience and can
  * be ignored in a subclass implementation.  The receiver is considered
  * to be in performance after this method returns.  The return value is
  * ignored.  */

- (NSArray *) noteReceivers;
 /* 
  * Returns a copy of the receiver's NSArray of NoteReceivers.  The
  * NoteReceivers themselves aren't copied.  It's the sender's
  * responsibility to free the NSArray.  */

- (int) indexOfNoteReceiver: (MKNoteReceiver *) aNoteReceiver;
  /*
   * Returns the ordinal index of aNoteReceiver in the MKInstrument's
   * MKNoteReceiver NSArray.  Returns -1 if aNoteReceiver is not in the NSArray. */

- (BOOL) isNoteReceiverPresent: (MKNoteReceiver *) aNoteReceiver; 
 /* 
  * Returns YES if aNoteReceiver is in the receiver's NoteReceiver List.
  * Otherwise returns NO.  */

- addNoteReceiver: (MKNoteReceiver *) aNoteReceiver;
 /* 
  * Adds aNoteReceiver to the receiver, first removing it from it's
  * current Instrument, if any.  If the receiver is in performance, does
  * nothing and returns nil, otherwise returns aNoteReceiver.  */

- removeNoteReceiver: (MKNoteReceiver *) aNoteReceiver; 
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

- releaseNoteReceivers; 
 /* 
  * Disconnects, removes, and frees the receiver's NoteReceivers.  Returns
  * the receiver.  */

- removeNoteReceivers; 
 /* 
  * Removes all the receiver's NoteReceivers but neither disconnects nor
  * frees them. Returns the receiver.  */

-(BOOL) inPerformance;
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

- copyWithZone: (NSZone *) zone; 
 /* 
  * Creates and returns a new Instrument as a copy of the receiver.  The
  * new object has its own NoteReceiver collection that contains copies of
  * the receiver's NoteReceivers.  The new NoteReceivers' connections (see
  * the NoteReceiver class) are copied from the NoteReceivers in the
  * receiver.  */

- (MKNoteReceiver *) noteReceiver; 
 /* 
  * Returns the first NoteReceiver in the receiver's List.  This is useful
  * for Instruments that have only one NoteReceiver.  */

- (void)encodeWithCoder: (NSCoder *) aCoder;
 /* 
  * You never send this message directly.  Should be invoked with
  * NXWriteRootObject().  Archives noteReceiver List. */

- (id)initWithCoder: (NSCoder *) aDecoder;
 /* 
  * You never send this message directly.  
  * Should be invoked via NXReadObject(). 
  * Note that -init is not sent to newly unarchived objects.
  * See write:. */

/*!
    @method allNotesOff
    @description Immeditately stops playing any sounding notes. The default behaviour is to do nothing.
                 Subclasses may implement specific behaviour appropriate to the synthesis method.
*/
- allNotesOff;

 /* Obsolete methods: */
+ new; 

@end



#endif
