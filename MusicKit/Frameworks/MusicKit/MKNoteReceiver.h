/*
  $Id$
  Defined In: The MusicKit

  Description:
    During a MusicKit performance, MKInstrument objects realize MKNotes that
    are sent to them from MKPerformer objects.  The MKNoteReceiver class
    defines the MKNote-receiving mechanism used by MKInstruments; each
    MKNoteReceiver object acts as a MKNote input for an MKInstrument.  Closely
    related to MKNoteReceiver is the MKNoteSender class, which defines the
    MKNote-sending mechanism used by MKPerformers.  By separating these
    mechanisms into distinct classes, any MKInstrument can have multiple
    inputs and any MKPerformer, multiple outputs.
   
    A MKNoteReceiver is added to an MKInstrument through the latter's
    addNoteReceiver: method.  While an application can create MKNoteReceivers
    and add them to an MKInstrument, this is typically done by the MKInstrument itself
    when it's created.  You can retrieve the object to which a MKNoteReceiver has
    been added by invoking MKNoteReceiver's owner method.
   
    To send MKNotes from a MKNoteSender to a MKNoteReceiver, the two objects must be
    connected.  This is done through the connect: method:
   
    	[aNoteReceiver connect:aNoteSender]
   
    Every MKNoteReceiver and MKNoteSender contains a list of connections.  The
    connect: method adds either object to the other's list; in other
    words, the MKNoteReceiver is added to the MKNoteSender's list and the
    MKNoteSender is added to the MKNoteReceiver's list.  Both MKNoteReceiver and
    MKNoteSender implement connect: as well as disconnect: and disconnect,
    methods used to sever connections.  A MKNoteReceiver can be connected to
    any number of MKNoteSenders.  Connections can be established and severed
    during a performance.
   
    The MKNote-receiving mechanism is defined in the receiveNote: method.
    When a MKNoteReceiver receives the message receiveNote: it sends the
    message realizeNote:fromNoteReceiver: to its owner, with the received
    MKNote as the first argument and its own id as the second.  receiveNote:
    is automatically invoked when a connected MKNoteSender sends a Note.
    You can toggle a MKNoteReceiver's MKNote-forwarding capability through the
    squelch and unsquelch methods; a MKNoteReceiver ignores the MKNotes it
    receives while it's squelched.  A newly created MKNoteReceiver is
    unsquelched.
   
    CF:  MKNoteSender, MKInstrument

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.8  2001/04/19 17:10:19  leighsmith
  Removed redundant (given NSObject reference counting) receiveAndFreeNote methods

  Revision 1.7  2001/01/31 21:32:57  leigh
  Typed note parameters

  Revision 1.6  2000/11/25 22:54:46  leigh
  Enforced ivar privacy

  Revision 1.5  2000/05/06 01:15:25  leigh
  Typed ivars to reduce warnings

  Revision 1.4  2000/04/22 20:14:00  leigh
  Properly typed connections returning an NSArray

  Revision 1.3  2000/02/07 23:49:52  leigh
  Comment corrections

  Revision 1.2  1999/07/29 01:25:46  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_NoteReceiver_H___
#define __MK_NoteReceiver_H___

#import <Foundation/NSObject.h>

@class MKInstrument;

@interface MKNoteReceiver: NSObject
{
    NSMutableArray *noteSenders;      /* Array of connected MKNoteSenders. */
    BOOL isSquelched;                 /* YES if the object is currently squelched. */
    MKInstrument *owner;              /* MKInstrument that owns MKNoteReceiver. */

@private
    void *_myData;
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

- (NSArray *) connections;
 /* 
 * Creates and returns a List containing the NoteSenders that are connected
 * to the receiver.  It's the caller's responsibility to free the
 * List.
 */

- receiveNote: (MKNote *) aNote; 
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

- receiveNote: (MKNote *) aNote atTime: (double) time; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * receiveNote:aNote to be sent to the receiver at time
 * time, measured in beats from the beginning of the
 * performance.  Returns the receiver.
 */

- receiveNote: (MKNote *) aNote withDelay:(double) delayTime; 
 /* 
 * Schedules a request (with aNote's Conductor) for 
 * receiveNote:aNote to be sent to the receiver at time
 * delayTime, measured in beats from the time this message
 * is received.  Returns the receiver.
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
