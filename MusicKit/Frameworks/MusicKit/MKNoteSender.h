/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:47  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_NoteSender_H___
#define __MK_NoteSender_H___

#import <Foundation/NSObject.h>

@interface MKNoteSender : NSObject 
/* 
 * During a Music Kit performance, Performer objects perform Notes by
 * sending them to one or more Instrument objects.  The MKNoteSender class
 * defines the Note-sending mechanism used by Performers; each MKNoteSender
 * object acts as a Note output for a Performer.  Closely related to
 * MKNoteSender is the NoteReceiver class, which defines the Note-receiving
 * mechanism used by Instruments.  By separating these mechanisms into
 * distinct classes, any Performer can have multiple outputs and any
 * Instrument, multiple inputs.
 * 
 * A MKNoteSender is added to a Performer through the latter's
 * addNoteSender: method.  While you can create and add NoteSenders
 * yourself, this is typically done automatically by the Performer when
 * it's created.  You can retrieve the object to which a MKNoteSender has
 * been added by invoking MKNoteSender's owner method.
 * 
 * To send Notes from a MKNoteSender to a NoteReceiver, the two objects must be
 * connected.  This is done through the connect: method:
 * 
 *	[aNoteSender connect:aNoteReceiver]
 * 
 * Every MKNoteSender and NoteReceiver contains a list of connections.  The
 * connect: method adds either object to the other's list; in other
 * words, the NoteReceiver is added to the MKNoteSender's list and the
 * MKNoteSender is added to the NoteReceiver's list.  Both NoteReceiver and
 * MKNoteSender implement connect: as well as disconnect: and disconnect,
 * methods used to sever connections.  A NoteReceiver can be connected to
 * any number of NoteSenders.  Connections can be established and severed
 * during a performance.
 * 
 * MKNoteSender's sendNote: method defines the Note-sending mechanism.
 * When a MKNoteSender receives the message sendNote:aNote, it forwards the
 * Note object argument to its NoteReceivers by sending each of them the
 * message receiveNote:aNote.  sendNote: is invoked when the MKNoteSender's
 * owner performs (or, for NoteFilter, when it realizes) a Note.  You can
 * toggle a MKNoteSender's Note-sending capability through the squelch and
 * unsquelch methods; a MKNoteSender won't send any Notes while it's
 * squelched.  A newly created MKNoteSender is unsquelched.
 * 
 * CF:  NoteReceiver, Performer, NoteFilter
 */ 
{
    NSMutableArray *noteReceivers;   /* Array of connected NoteReceivers. */
    BOOL isSquelched;    /* YES if the object is squelched. */
    id owner;            /* Performer (or NoteFilter) that owns this object. */

    /* The following are for internal use only */
    void *_myData;
    BOOL _ownerIsAPerformer;
    short isSending;
}

- owner; 
 /* 
 * Returns the Performer (or NoteFilter) that owns the receiver.
 */

- disconnect:aNoteReceiver; 
 /* 
 * Disconnects aNoteReceiver from the receiver.  Returns the receiver.
 */

-(BOOL ) isConnected:aNoteReceiver; 
 /* 
 * Returns YES if aNoteReceiver is connected to the receiver,
 * otherwise returns NO.
 */

- connect:aNoteReceiver; 
 /* 
 * Connects aNoteReceiver to the receiver if aNoteReceiver 
 * isKindOf:NoteReceiver. Returns the receiver.
 */

- squelch; 
 /* 
 * Squelches the receiver.  While a receiver is squelched it can't send
 * Notes.  Returns the receiver.
 */

- unsquelch; 
 /* 
 * Enables the receiver's Note-sending capability, undoing the effect of 
 * a previous squelch message.  Returns the receiver.
 */

-(BOOL ) isSquelched; 
 /* 
 * Returns YES if the receiver is squelched, otherwise returns NO.
 */

-(unsigned)connectionCount;
 /* 
 * Returns the number of NoteReceivers connected to the receiver. 
 */

- connections;
 /* 
 * Creates and returns a List containing the NoteReceivers that are connected
 * to the receiver.  It's the caller's responsibility to free the
 * List.
 */

- (void)dealloc; 
 /* 
 * Disconnects and frees the receiver.  You can't free a MKNoteSender that's in 
 * the process of sending a Note.	
 */

- init;
 /* 
  * Initializes object. Subclass should send [super init] when overriding
    this method */

- disconnect; 
 /* 
 * Disconnects all the NoteReceivers connected to the receiver.
 * Returns the receiver.
 */

-sendAndFreeNote:aNote atTime:(double)time;
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * sendAndFreeNote:aNote to be sent to the receiver at time
 * time, measured in beats from the beginning of the
 * performance.  Returns the receiver.
 */

-sendAndFreeNote:aNote withDelay:(double)beats;
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * sendAndFreeNote:aNote to be sent to the receiver at time
 * delayTime measured in beats from the time this message is received.
 * Returns the receiver.
 */

-sendAndFreeNote:aNote;
 /* 
 * Sends the message sendNote:aNote
 * to the receiver and then frees aNote,
 * If the receiver is squelched, aNote isn't sent but it is freed.
 * Returns the receiver.
 */

- sendNote:aNote atTime:(double )time; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * sendNote:aNote to be sent to the receiver at time
 * time, measured in beats from the beginning of the performance.
 * Returns the receiver.
 */

- sendNote:aNote withDelay:(double )delayTime; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * sendNote:aNote to be sent to the receiver at time
 * delayTime measured in beats from the time this message is received.
 * Returns the receiver.
 */

- sendNote:aNote; 
 /* 
 * Sends the message receiveNote:aNote
 * to each NoteReceiver currently connected to the receiver.
 * If the receiver is squelched, the message isn't sent. 
 * Returns the receiver.
 */

//- copy; 
 /* 
    Same as [self copyFromZone:[self zone]] 
  */

- copyWithZone:(NSZone *)zone; 
 /* 
 * Creates and returns a new MKNoteSender with the same
 * connections as the receiver.
 */

- (void)encodeWithCoder:(NSCoder *)aCoder;
 /* 
    You never send this message directly.  
    Should be invoked with NXWriteRootObject(). 
    Archives isSquelched and object name, if any. 
    Also optionally archives NoteReceiver List and owner using 
    NXWriteObjectReference(). */

- (id)initWithCoder:(NSCoder *)aDecoder;
 /* 
    You never send this message directly.  
    Should be invoked via NXReadObject(). 
    See write:. */

+ new; 
 /* Obsolete */

@end

@interface MKNoteSender(Private)

/* Sets the owner (an Instrument or NoteFilter). In most cases,
   only the owner itself sends this message.
   */
-_setOwner:obj;
/* Facility for associating arbitrary data with a NoteReceiver */
-(void)_setData:(void *)anObj;
-(void *)_getData;
-(void)_setPerformer:aPerformer;

@end

#endif
