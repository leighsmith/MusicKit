/*
  $Id$
  Defined In: The MusicKit

  Description:
    MKNoteFilter is an abstract class that combines the functionality it
    inherits from MKInstrument with the protocol defined in the MKPerformer
    class.  MKNoteFilter objects can both receive and send MKNotes; they're
    interposed between MKPerformers and MKInstruments to create a MKNote
    processing pipeline.  The subclass responsibility
    realizeNote:fromNoteReceiver: is passed on to MKNoteFilter subclasses.
    Keep in mind that notes must be copied on write or store.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
  $Log$
  Revision 1.4  2000/04/25 02:11:02  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.3  2000/04/02 17:12:08  leigh
  Cleaned up doco

  Revision 1.2  1999/07/29 01:25:46  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_NoteFilter_H___
#define __MK_NoteFilter_H___

#import "MKInstrument.h"

@interface MKNoteFilter : MKInstrument
{
    NSMutableArray *noteSenders;     /* Collection of MKNoteSenders. */
}

- init;
 /* Creates MKNoteSenders and sends [super init]. */

- noteSenders; 
 /* 
  * Returns a copy of the receiver's List of MKNoteSenders.
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

- releaseNoteSenders; 
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
  * Sends releaseNoteSenders and releaseNoteReceivers to the receiver
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
