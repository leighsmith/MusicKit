#ifndef __MK_NoteReceiver_H___
#define __MK_NoteReceiver_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  MKNoteReceiver.h
  DEFINED IN: The Music Kit
*/

#import <Foundation/NSObject.h>

@interface MKNoteReceiver: NSObject
/* 
 * During a Music Kit performance, Instrument objects realize Notes that
 * are sent to them from Performer objects.  The NoteReceiver class
 * defines the Note-receiving mechanism used by Instruments; each
 * NoteReceiver object acts as a Note input for an Instrument.  Closely
 * related to NoteReceiver is the MKNoteSender class, which defines the
 * Note-sending mechanism used by Performers.  By separating these
 * mechanisms into distinct classes, any Instrument can have multiple
 * inputs and any Performer, multiple outputs.
 * 
 * A NoteReceiver is added to an Instrument through the latter's
 * addNoteReceiver: method.  While an application can create NoteReceivers
 * and add them to an Instrument, this is typically done by the Instrument itself
 * when it's created.  You can retrieve the object to which a NoteReceiver has
 * been added by invoking NoteReceiver's owner method.
 * 
 * To send Notes from a MKNoteSender to a NoteReceiver, the two objects must be
 * connected.  This is done through the connect: method:
 *
 * 	[aNoteReceiver connect:aNoteSender]
 *
 * Every NoteReceiver and MKNoteSender contains a list of connections.  The
 * connect: method adds either object to the other's list; in other
 * words, the NoteReceiver is added to the MKNoteSender's list and the
 * MKNoteSender is added to the NoteReceiver's list.  Both NoteReceiver and
 * MKNoteSender implement connect: as well as disconnect: and disconnect,
 * methods used to sever connections.  A NoteReceiver can be connected to
 * any number of NoteSenders.  Connections can be established and severed
 * during a performance.
 *
 * The Note-receiving mechanism is defined in the receiveNote: method.
 * When a NoteReceiver receives the message receiveNote: it sends the
 * message realizeNote:fromNoteReceiver: to its owner, with the received
 * Note as the first argument and its own id as the second.  receiveNote:
 * is automatically invoked when a connected MKNoteSender sends a Note.
 * You can toggle a NoteReceiver's Note-forwarding capability through the
 * squelch and unsquelch methods; a NoteReceiver ignores the Notes it
 * receives while it's squelched.  A newly created NoteReceiver is
 * unsquelched.
 * 
 * CF:  MKNoteSender, Instrument
 */
{
    id noteSenders;       /* List of connected NoteSenders. */
    BOOL isSquelched;     /* YES if the object is squelched. */
    id owner;             /* Instrument that owns NoteReceiver. */

    /* The following is for internal use only.  */
    void *_myData;
//    void *_reservedNoteReceiver2;
}
 
- owner; 
 /* 
  * Returns the Instrument that owns the receiver.
  */

- init;
 /* 
  * Initializes object. Subclass should send [super init] when overriding
    this method */

- (void)dealloc; 
 /* 
  * Disconnects and frees the receiver.
  */

- disconnect:aNoteSender; 
 /* 
  * Disconnects aNoteSender from the receiver.  
  * Returns the receiver.
  */

- disconnect; 
 /* 
 * Disconnects all the NoteSenders connected to the receiver.
 * Returns the receiver.
 */

-(BOOL ) isConnected:aNoteSender; 
 /* 
 * Returns YES if aNoteSender is connected to the receiver,
 * otherwise returns NO.
 */

- connect:aNoteSender; 
 /* 
 * Connects a aNoteSender to the receiver if aNoteSender isKindOf:
 * MKNoteSender. Returns the receiver.
 */

- squelch; 
 /* 
 * Squelches the receiver.  While a receiver is squelched it can't send
 * the realizeNote:fromNoteReceiver: message to its owner.
 * Returns the receiver.
 */

- unsquelch; 
 /* 
 * Enables the receiver's Note-forwarding capability, undoing
 * the effect of a previous squelch message. 
 * Returns the receiver.
 */

-(BOOL ) isSquelched; 
 /* 
 * Returns YES if the receiver is squelched, otherwise returns NO.
 */

//- copy; 
 /* 
    Same as [self copyFromZone:[self zone]] 
  */

- copyWithZone:(NSZone *)zone; 
 /* 
 * Creates and returns a new NoteReceiver with the same
 * connections as the receiver.
 */

-(unsigned)connectionCount;
 /* 
 * Returns the number of NoteSenders connected to the receiver. 
 */

- connections;
 /* 
 * Creates and returns a List containing the NoteSenders that are connected
 * to the receiver.  It's the caller's responsibility to free the
 * List.
 */

- receiveNote:aNote; 
 /* 
 * If the receiver isn't squelched, this sends the message
 * 
 * [owner realizeNote:aNote fromNoteReceiver:self];
 *
 * thereby causing aNote to be realized by the receiver's owner.
 * You never send receiveNote: directly to a NoteReceiver;
 * it's sent as part of a MKNoteSender's sendNote: method.
 * Returns the receiver, or nil if the receiver is squelched.
 */

- receiveNote:aNote atTime:(double )time; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * receiveNote:aNote to be sent to the receiver at time
 * time, measured in beats from the beginning of the
 * performance.  Returns the receiver.
 */

- receiveNote:aNote withDelay:(double )delayTime; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * receiveNote:aNote to be sent to the receiver at time
 * delayTime, measured in beats from the time this message
 * is received.  Returns the receiver.
 */

- receiveAndFreeNote:aNote withDelay:(double )delayTime; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * receiveAndFreeNote:aNote to be sent to the receiver at time
 * delayTime, measured in beats from the time this message
 * is received.  Returns the receiver.
 */

- receiveAndFreeNote:aNote; 
 /* 
 * Sends the message receiveNote:aNote to the receiver and
 * then frees the Note.
 * Returns the receiver.
 */

- receiveAndFreeNote:aNote atTime:(double )time; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * receiveAndFreeNote:aNote to be sent to the receiver at time
 * time, measured in beats from the beginning of the perfromance.
 * Returns the receiver.
 */

- (void)encodeWithCoder:(NSCoder *)aCoder;
 /* 
    You never send this message directly.  
    Should be invoked with NXWriteRootObject(). 
    Archives isSquelched and object name, if any. 
    Also optionally archives elements of MKNoteSender List and owner using 
    NXWriteObjectReference(). */
- (id)initWithCoder:(NSCoder *)aDecoder;
 /* 
    You never send this message directly.  
    Should be invoked via NXReadObject(). 
    See write:. */

+ new; 
 /* Obsolete */

@end



#endif
