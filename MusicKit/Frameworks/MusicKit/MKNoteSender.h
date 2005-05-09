/*
  $Id$
  Defined In: The MusicKit

  Description:
    During a MusicKit performance, MKPerformer objects perform MKNotes by
    sending them to one or more MKInstrument objects.  The MKNoteSender class
    defines the MKNote-sending mechanism used by MKPerformers; each MKNoteSender
    object acts as a MKNote output for a MKPerformer.  Closely related to
    MKNoteSender is the MKNoteReceiver class, which defines the MKNote-receiving
    mechanism used by MKInstruments.  By separating these mechanisms into
    distinct classes, any MKPerformer can have multiple outputs and any
    MKInstrument, multiple inputs.

    A MKNoteSender is added to a MKPerformer through the latter's
    addNoteSender: method.  While you can create and add MKNoteSenders
    yourself, this is typically done automatically by the MKPerformer when
    it's created.  You can retrieve the object to which a MKNoteSender has
    been added by invoking MKNoteSender's owner method.

    To send MKNotes from a MKNoteSender to a MKNoteReceiver, the two objects must be
    connected.  This is done through the connect: method:
   
   	[aNoteSender connect: aNoteReceiver]

    Every MKNoteSender and MKNoteReceiver contains a list of connections.  The
    connect: method adds either object to the other's list; in other
    words, the MKNoteReceiver is added to the MKNoteSender's list and the
    MKNoteSender is added to the MKNoteReceiver's list.  Both MKNoteReceiver and
    MKNoteSender implement connect: as well as disconnect: and disconnectAllReceivers,
    methods used to sever connections.  A MKNoteReceiver can be connected to
    any number of MKNoteSenders.  Connections can be established and severed
    during a performance.

    MKNoteSender's sendNote: method defines the MKNote-sending mechanism.
    When a MKNoteSender receives the message sendNote:aNote, it forwards the
    MKNote object argument to its MKNoteReceivers by sending each of them the
    message receiveNote:aNote.  sendNote: is invoked when the MKNoteSender's
    owner performs (or, for MKNoteFilter, when it realizes) a MKNote.  You can
    toggle a MKNoteSender's MKNote-sending capability through the squelch and
    unsquelch methods; a MKNoteSender won't send any MKNotes while it's
    squelched.  A newly created MKNoteSender is unsquelched.
   
    CF:  MKNoteReceiver, MKPerformer, MKNoteFilter

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
@class MKNoteReceiver;
@class MKNote;

/*!
  @class MKNoteSender
  @brief

MKNoteSender is an auxilliary class that completes the implementation of
MKPerformer.  Instances are created and owned by MKPerformer objects, normally
when the MKPerformer itself is created or initialized.  A MKNoteSender object
performs two functions:

<ul>
<li>It's part of the link between a MKPerformer and an MKInstrument. 
MKNoteSender's <b>connect:</b> method connects a MKNoteSender to a
MKNoteReceiver, which is owned by an MKInstrument in much the same way that a
MKNoteSender is owned by a MKPerformer. By connecting a MKNoteSender to a
MKNoteReceiver, their respective owners are said to be connected.  
MKNoteReceiver defines an equivalent <b>connect:</b> method - it doesn't matter
which of the two objects is the receiver and which is the argument when sending
a <b>connect:</b> message.</li>

<li>MKNoteSender's <b>sendNote:</b> method defines the mechanism by which a
MKPerformer relays a MKNote to a set of MKInstruments.  When a MKNoteSender
receives a <b>sendNote:</b> message, it sends <b>receiveNote:</b> to its
connected MKNoteReceivers which, in turn, send <b>realizeNote:fromNoteReceiver:</b>
to their owners (MKInstrument objects).  You can toggle a MKNoteSender's ability
to send MKNotes through the <b>squelch</b> and <b>unsquelch</b> methods; a
MKNoteSender won't send <b>receiveNote:</b> messages while it's squelched.</li>
</ul>

There's a fundamental difference between these two tasks in that while you
connect MKNoteSenders to MKNoteReceivers from your application, sending MKNotes
is a MKPerformer's responsibility: Subclasses of MKPerformer should invoke
<b>sendNote:</b> as part of their implementations of the <b>perform</b> 
method.

Keep in mind that while you can create MKNoteSenders and add them to
MKPerformers through messages sent by your application (a MKNoteSender is added
to a MKPerformer through the latter's <b>addNoteSender:</b> method), they're
designed to be created and added by the MKPerformers themselves.  Before adding
your own MKNoteSenders to a MKPerformer, you should check the description of the
MKPerformer subclass that you're using to ensure that your MKNoteSenders will be
recognized.

A MKNoteSender can be owned by only one MKPerformer at a time; however, it can
be connected to any number of MKNoteReceivers. In addition, two different
MKNoteSenders can be connected to the same MKNoteReceiver. Thus the connections
between MKPerformers and MKInstruments can describe an arbitrarily complicated
network. To retrieve the MKNoteSenders that are owned by a particular
MKPerformer - to connect them to MKNoteReceivers, or to squelch and unsquelch
them - you invoke the MKPerformer's <b>noteSender</b> or <b>noteSenders</b>
method.

MKNoteSenders are also created, owned, and used by instances of MKNoteFilter and
MKMidi - neither of which are actual MKPerformers - as part of their assumptions
of the role of MKPerformer. A MKNoteFilter subclass should send
<b>sendNote:</b> to its MKNoteSenders as part of its implementation of
<b>realizeNote:fromNoteSender:</b>. It isn't anticipated that MKMidi will be
subclassed (at least not to override its <b>sendNote</b>: invocation).
*/
#ifndef __MK_NoteSender_H___
#define __MK_NoteSender_H___

#import <Foundation/NSObject.h>

@interface MKNoteSender: NSObject <NSCoding>
{
    /*! @var noteReceivers Array of connected MKNoteReceivers. */
    NSMutableArray *noteReceivers;
    /*! @var isSquelched YES if the object is squelched. */
    BOOL isSquelched;
    /* MKPerformer (or MKNoteFilter) that owns this object. */
    id owner;

@private
    id dataObject;
    BOOL _ownerIsAPerformer;
    short isSending;
}

/*!
  @return Returns an id.
  @brief Returns the MKPerformer (or MKNoteFilter or MKMidi object) that owns
  the MKNoteSender.

  
  
  @see - <b>addNoteSender:</b> (MKPerformer, MKNoteFilter, MKMidi)
*/
- owner; 

/*!
  @param  aNoteReceiver is an MKNoteReceiver instance.
  @return Returns <b>self</b>.
  @brief Severs the connection between the MKNoteSender and
  <i>aNoteReceiver</i>; if the MKNoteReceiver isn't connected, this
  does nothing.

  
  
  @see - <b>disconnectAllReceivers</b>, - <b>connect:</b>, - <b>isConnected:</b>, - <b>connections</b> 
*/
- disconnect: (MKNoteReceiver *) aNoteReceiver; 

/*!
  @param  aNoteReceiver is an MKNoteReceiver instance.
  @return Returns a BOOL.
  @brief Returns YES if <i>aNoteReceiver</i> is connected to the
  MKNoteSender, otherwise returns NO.

  
  
  @see -<b>connect</b>, -<b>disconnectAllReceivers</b>, -<b>connections</b>, -<b>connectionCount</b>,  
*/
- (BOOL) isConnected: (MKNoteReceiver *) aNoteReceiver; 

/*!
  @param  aNoteReceiver is an MKNoteReceiver instance.
  @return Returns <b>self</b>.
  @brief Connects <i>aNoteReceiver</i> to the MKNoteSender; if the argument
  isn't a MKNoteReceiver, the connection isn't made.

  
  
  @see - <b>disconnect:</b>, - <b>isConnected</b>, - <b>connections</b>
*/
- connect: (MKNoteReceiver *) aNoteReceiver; 

/*!
  @return Returns <b>self</b>.
  @brief Disables the MKNoteSender's ability to send <b>receiveNote:</b> to
  its MKNoteReceivers.

  While a receiver is squelched it can't send MKNotes. 
  
  @see - <b>isSquelched</b>, - <b>unsquelch</b>
*/
- squelch; 

/*!
  @return Returns <b>self</b>.
  @brief Enables the MKNoteSender ability to send MKNotes, undoing the effect
  of a previous <b>squelch message.

  
  
  @see - <b>isSquelched</b>,- <b>squelch</b>
*/
- unsquelch; 

/*!
  @return Returns a BOOL.
  @brief Returns YES if the MKNoteSender is squelched (its MKNote-sending
  ability is disabled), otherwise returns NO.

  
  
  @see - <b>squelch</b>, - <b>unsquelch</b>
*/
- (BOOL) isSquelched; 

/*!
  @return Returns an unsigned int.
  @brief Returns the number of MKNoteReceivers that are connected to the
  MKNoteSender.

  
  
  @see -<b>connect:</b>, -<b>disconnect:</b>, -<b>isConnected</b>, -<b>connections</b>
*/
- (unsigned) connectionCount;

/*!
  @return Returns an id.
  @brief Creates and returns a NSArray of the MKNoteReceivers that are connected
  to the MKNoteSender.

  
  
  @see -<b>connect:</b>, -<b>disconnect:</b>, -<b>isConnected</b>
*/
- (NSArray *) connections;

/*!
  @brief Disconnects and frees the receiver.
  
  You can't free a MKNoteSender that's in the process of sending a MKNote.	
 */
- (void) dealloc; 

/*!
  @return Returns <b>self</b>.
  @brief Initializes a MKNoteSender that was created through
  <b>allocFromZone:</b>.

  Subclasses should send 
  <tt>[super init]</tt> when overriding this method.
  The new MKNoteSender is unsquelched and unowned.  
*/
- init;

/*!
  @brief Severs the connections between the MKNoteSender and all the
  MKNoteReceivers it's connected to.

  
  
  @see -<b>disconnect:</b>, -<b>connect:</b>, -<b>isConnected:</b>, -<b>connections</b> 
*/
- (void) disconnectAllReceivers; 

/*!
  @param  aNote is an MKNote instance.
  @param  beatsSinceStart is a double.
  @return Returns <b>self</b>.
  @brief Enqueues, with the appropriate MKConductor, a request for
  <b>sendAndFreeNote:</b><i>aNote</i> to be sent to <b>self</b> at
  time <i>beatsSinceStart</i>, measured in beats from the beginning of
  the MKConductor's performance.

  See <b>sendNote:atTime:</b> for a
  description of the MKConductor that's used.  
  
  @see -<b>sendNote:</b>, -<b>sendAndFreeNote:</b>, -<b>sendAndFreeNote:withDelay:</b>
*/
- sendAndFreeNote: (MKNote *) aNote atTime: (double) beatsSinceStart;

/*!
  @param  aNote is an MKNote instance.
  @param  delayBeats is a double.
  @return Returns <b>self</b>.
  @brief Enqueues, with the appropriate Conductor, a request for
  <b>sendAndFreeNote:</b><i>aNote</i> to be sent to <b>self</b> after
  <i>delayBeats</i>.

  See <b>sendNote:atTime:</b> for a description of
  the MKConductor that's used.  
  
  @see - <b>sendNote:</b>, - <b>sendAndFreeNote:</b>, - <b>sendAndFreeNote:atTime:</b>,
*/
- sendAndFreeNote: (MKNote *) aNote withDelay: (double) delayBeats;

/*!
  @param  aNote is an MKNote instance.
  @return Returns <b>self</b>.
  @brief Sends the message <b>sendNote:</b><i>aNote</i> to <b>self</b> and
  then frees <i>aNote</i>.

  If the receiver is squelched, aNote isn't
  sent but it is freed.
  
  @see -<b>sendNote:</b>, -<b>sendAndFreeNote:atTime:</b>, -<b>sendAndFreeNote:withDelay:</b>
*/
- sendAndFreeNote: (MKNote *) aNote;

/*!
  @param  aNote is an MKNote instance.
  @param  beatsSinceStart is a double.
  @brief Enqueues, with the MKConductor object described below, a request for
  <b>sendNote:</b><i>aNote</i> to be sent to <b>self</b> at time
  <i>beatsSinceStart</i>, measured in beats from the beginning of the
  MKConductor's performance.

  If <i>beatsSinceStart</i> has already
  passed, the enqueued message is sent immediately.
  
  The request is enqueued with the object that's returned by
  <b>[</b><i>aNote</i> <b>conductor]</b>.  Normally - if the owner is a MKPerformer
  - this is the owner's MKConductor.  However, if the owner is a MKNoteFilter,
  the request is enqueued with the MKConductor of the MKPerformer (or MKMidi) that
  originally sent <i>aNote</i> into the performance (or the defaultConductor if the
  MKNoteFilter itself created the MKNote).
  
  @see -<b>sendNote:</b>, -<b>sendNote:withDelay:</b>
*/
- (void) sendNote: (MKNote *) aNote atTime: (double) time; 

/*!
  @param  aNote is an MKNote instance.
  @param  delayBeats is a double, measuring beats from the time this message is received.
  @brief Enqueues with <i>aNote</i>'s MKConductor, a request for
  <b>sendNote:</b><i>aNote</i> to be sent to <b>self</b> after
  <i>delayBeats</i>.

  See <b>sendNote:atTime:</b> for a description of
  the MKConductor that's used.  
  
  @see -<b>sendNote:</b>, -<b>sendNote:atTime:</b>
*/
- (void) sendNote: (MKNote *) aNote withDelay: (double) delayTime; 

/*!
  @param  aNote is an MKNote instance.
  @return Returns self if successfully sent, nil if squelched.
  @brief Sends the message <b>receiveNote:</b><i>aNote</i> to the
  MKNoteReceivers that are connected to the MKNoteSender.

  If the
  MKNoteSender is squelched, the messages aren't sent.  Normally, this
  method is only invoked by the MKNoteSender's owner. 
  
  @see -<b>sendAndFreeNote:</b>, -<b>sendNote:withDelay:</b>, -<b>sendNote:atTime:</b>
*/
- sendNote: (MKNote *) aNote; 

/*!
  @param  zone is a NSZone.
  @return Returns an id.
  @brief This is the same as <b>copy</b>, but the new object is allocated
  from <i>zone</i>.

  Creates and returns a new MKNoteSender with the
  same connections as the receiver.
  
  @see -<b>copy</b>
*/
- copyWithZone: (NSZone *) zone; 

 /* 
    You never send this message directly.  
    Archives isSquelched and object name, if any. 
    Also conditionally archives MKNoteReceiver List and owner. 
  */
- (void) encodeWithCoder: (NSCoder *) aCoder;

 /* 
    You never send this message directly.  
    See write:. 
  */
- (id) initWithCoder: (NSCoder *) aDecoder;

@end

@interface MKNoteSender(Private)

/* Sets the owner (an MKInstrument or MKNoteFilter). In most cases,
   only the owner itself sends this message.
   */
- _setOwner: obj;

/* Facility for associating arbitrary data with a MKNoteSender */
- (void) _setData: (id) anObj;
- (id) _getData;

/*!
  @brief Sets the receiver's MKPerformer.
  
  Associates a aPerformer with the receiver, such that aPerformer owns the receiver.
  Normally, you only invoke this method if you are implementing a subclass of MKPerformer 
  that creates MKNoteSender instances.
  @return Returns the receiver.
 */
- (void) _setPerformer: aPerformer;

// Connection methods shared between MKNoteSenders and MKNoteReceivers
- _disconnect: (MKNoteReceiver *) aNoteReceiver;
- _connect: (MKNoteReceiver *) aNoteReceiver;

@end

#endif
