#ifndef __MK_NoteFilter_H___
#define __MK_NoteFilter_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  MKNoteFilter.h
  DEFINED IN: The Music Kit
*/

#import "MKInstrument.h"

@interface MKNoteFilter : MKInstrument
/*
 * NoteFilter is an abstract class that combines the functionality it
 * inherits from Instrument with the protocol defined in the Performer
 * class.  NoteFilter objects can both receive and send Notes; they're
 * interposed between Performers and Instruments to create a Note
 * processing pipeline.  The subclass responsibility
 * realizeNote:fromNoteReceiver: is passed on to NoteFilter subclasses.
 * Keep in mind that notes must be copied on write or store.  
 */
{
	id noteSenders;     /* Collection of NoteSenders. */
}

- init;
 /* Creates NoteSenders and sends [super init]. */

- noteSenders; 
 /* 
  * Returns a copy of the receiver's List of NoteSenders.  It is the sender's
  * responsibility to free the List.  
  */

-(BOOL ) isNoteSenderPresent:aNoteSender; 
 /* 
  * Returns YES if aNoteSender is one of the receiver's NoteSenders.
  * Otherwise returns NO.
  */

- copyWithZone:(NSZone *)zone;
 /* 
  * Creates and returns a NoteFilter as a copy of the receiver.
  * The new object contains copies of the receiver's NoteSenders and
  * NoteReceivers. CF superclass copy
  */

- freeNoteSenders; 
 /* 
  * Removes and frees the receiver's NoteSenders.
  * Returns the receiver.
  */

- removeNoteSenders; 
 /* 
  * Removes all the receiver's NoteSenders.  Returns the receiver.
  */

- noteSender; 
 /* 
  * Returns the receiver's first MKNoteSender.  This is method should only
  * by invoked if the receiver only contains one MKNoteSender or if you
  * don't care which MKNoteSender you get.
  */

- addNoteSender:aNoteSender; 
 /* 
  * Removes aNoteSender from its present owner (if any) and adds it to the
  * receiver.  Returns aNoteSender.  If the receiver is in performance, or if
  * aNoteSender is already a member of the receiver, does nothing and returns
  * nil.  
  */

- removeNoteSender:aNoteSender; 
 /* 
  * Removes aNoteSender from the receiver's List of NoteSenders.
  * Returns aNoteSender.
  * If the receiver is in a performance, does nothing and returns nil.
  */

- (void)dealloc; 
 /* 
  * Sends freeNoteSenders and freeNoteReceivers to the receiver
  * then frees the receiver.
  */

- (void)encodeWithCoder:(NSCoder *)aCoder;
   /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives noteSener List. */
- (id)initWithCoder:(NSCoder *)aDecoder;
   /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */

@end



#endif
