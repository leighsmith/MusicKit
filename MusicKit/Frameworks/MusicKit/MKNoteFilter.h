/*
  $Id$
  Defined In: The MusicKit

  Description:
    See class description below for description.    

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/*!
  @class MKNoteFilter
  @abstract MKNoteFilter is an abstract class that combines the functionality it inherits
            from MKInstrument with the protocol defined in the MKPerformer class. 

  @discussion
    MKNoteFilter is an abstract class that combines the functionality it inherits
    from MKInstrument with the protocol defined in the MKPerformer class. 
    MKNoteFilter objects can both receive and send MKNotes; they're interposed
    between MKPerformers and MKInstruments to create a MKNote processing pipeline. 
    The subclass responsibility <b>realizeNote:fromNoteReceiver:</b> is passed on to
    MKNoteFilter subclasses. Keep in mind that notes must be copied on write or store.
*/
#ifndef __MK_NoteFilter_H___
#define __MK_NoteFilter_H___

#import "MKInstrument.h"

@interface MKNoteFilter : MKInstrument
{
    NSMutableArray *noteSenders;     /* Collection of MKNoteSenders. */
}

/*!
  @method init
  @result Returns a newly initialized MKNoteFilter.
  @discussion Creates MKNoteSenders and sends [super init].
*/
- init;

/*!
  @method noteSenders
  @result Returns an NSArray instance.
  @discussion Returns a copy of the receiver's NSArray of MKNoteSenders.
*/
- (NSArray *) noteSenders;

/*!
  @method isNoteSenderPresent:
  @param  aNoteSender is an MKNoteSender instance.
  @result Returns a BOOL.
  @discussion Returns YES if <i>aNoteSender</i> is one of the receiver's
              MKNoteSenders.  Otherwise returns NO.
*/
- (BOOL) isNoteSenderPresent: (MKNoteSender *) aNoteSender; 

/*!
  @method copyWithZone:
  @param  zone is a NSZone.
  @result Returns an id.
  @discussion Creates and returns a MKNoteFilter as a copy of the receiver.  The
              new object contains copies of the receiver's MKNoteSenders and
              MKNoteReceivers.
*/
- copyWithZone: (NSZone *) zone;

/*!
  @method releaseNoteSenders
  @result Returns an id.
  @discussion Removes and frees the receiver's MKNoteSenders. Returns the receiver.
*/
- releaseNoteSenders;

/*!
  @method removeNoteSenders
  @result Returns an id.
  @discussion Removes all the receiver's MKNoteSenders. Returns the receiver.
*/
- removeNoteSenders;

/*!
  @method noteSender
  @result Returns an MKNoteSender instance.
  @discussion Returns the receiver's first MKNoteSender.  This is method should
              only by invoked if the receiver only contains one MKNoteSender or if
              you don't care which MKNoteSender you get.  If there are currently
              no MKNoteSenders, this method creates and adds a MKNoteSender.
*/
- (MKNoteSender *) noteSender;

/*!
  @method addNoteSender:
  @param  aNoteSender is an MKNoteSender instance.
  @result Returns an id.
  @discussion Removes <i>aNoteSender</i> from its present owner (if any) and adds
              it to the receiver.  Returns <i>aNoteSender</i>.  If the receiver is
              in performance, or if <i>aNoteSender</i> is already a member of the
              receiver, does nothing and returns <b>nil</b>.
*/
- addNoteSender: (MKNoteSender *) aNoteSender; 

/*!
  @method removeNoteSender:
  @param  aNoteSender is an MKNoteSender instance.
  @result Returns an id.
  @discussion Removes aNoteSender from the receiver's NSArray of MKNoteSenders. 
              Returns <i>aNoteSender</i>.  If the receiver is in a performance,
              does nothing and returns <b>nil</b>.
*/
- removeNoteSender: (MKNoteSender *) aNoteSender; 

/*!
  @method dealloc
  @discussion Sends releaseNoteSenders to the receiver then releases the receivers ivars.
 */
- (void) dealloc; 

/* 
  You never send this message directly. Archives noteSender Array. 
 */
- (void) encodeWithCoder: (NSCoder *) aCoder;

- (id)initWithCoder:(NSCoder *)aDecoder;

@end

#endif
