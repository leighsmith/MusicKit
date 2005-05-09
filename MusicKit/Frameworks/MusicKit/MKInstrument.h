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
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/*!
  @class MKInstrument
  @brief

MKInstrument is an abstract class that defines the general mechanism for
receiving and realizing MKNotes during a MusicKit performance.  An MKInstrument
receives MKNotes through its MKNoteReceivers, auxilliary objects that are
typically connected to a MKPerformer's MKNoteSenders.  The manner in which an
MKInstrument realizes MKNotes is defined in its implementation of
<b>realizeNote:fromNoteReceiver:</b>.  This method is automatically invoked by
an MKInstrument's MKNoteReceivers, when such objects receive 
<b>receiveNote:</b> messages.  

An MKInstrument is considered to be in performance from the time that one of its
MKNoteReceivers invokes the <b>realizeNote:fromNoteReceiver:</b> method until
the MKConductor class receives the <b>finishPerformance</b> message.  There are
two implications regarding an MKInstrument's involvement in a
performance:

<ul>
<li>An MKInstrument's <b>firstNote:</b> and <b>afterPerformance</b> methods
are invoked as the MKInstrument begins and finishes its performance,
respectively.  These methods can be implemented in a subclass to provide
specialized initialization and post-performance cleanup.</li>

<li>Some MKInstrument methods can't be invoked during a performance.  For
example, you can't add or remove MKNoteReceivers while the MKInstrument is
performing.</li>
</ul>

Creating and adding MKNoteReceivers to an MKInstrument object is generally the
obligation of the MKInstrument subclass; most subclasses dispose of this duty in
their <b>init</b> methods.  However, instances of some subclasses are born with
no MKNoteReceivers - they expect these objects to be added by your application. 
You should visit the class description of the MKInstrument subclass that you're
using to determine just what sort of varmint you're dealing with.

The MusicKit defines a number of MKInstrument subclasses.  Notable among these
are: MKSynthInstrument, which synthesizes MKNotes on the DSP; MKPartRecorder
adds MKNotes to a designated MKPart; MKScorefileWriter writes them to a
scorefile; and MKNoteFilter, an abstract class that acts as a MKNote conduit,
altering the MKNotes that it receives before passing them on to other
MKInstruments.  In addition, the MKMidi class can be used as an MKInstrument to
realize MKNotes on an external MIDI synthesizer.
*/
#ifndef __MK_Instrument_H___
#define __MK_Instrument_H___

#import <Foundation/Foundation.h>
//#import <Foundation/NSObject.h>
//#import <Foundation/NSArray.h>
#import "MKNote.h"
#import "MKNoteReceiver.h"

@interface MKInstrument: NSObject <NSCoding>
{
    NSMutableArray *noteReceivers; /* The object's array of MKNoteReceivers. */

@protected
    BOOL noteSeen;
    void *_afterPerfMsgPtr;
}


/*!
  @return Returns <b>self</b>.
  @brief Initializes an MKInstrument that was created through
  <b>allocFromZone:</b>.

  You never invoke this method directly.  A
  subclass implementation should send [super init] before
  performing its own initialization.  The return value is ignored.
*/
- init; 

/*!
  @param  aNote is an id.
  @param  aNoteReceiver is an id.
  @return Returns an id.
  @brief You implement this method in a subclass to define the manner in
  which the subclass realizes MKNotes.

  <i>aNote</i> is the MKNote
  that's to be realized; <i>aNoteReceiver</i> is the MKNoteReceiver
  that received it.  The default implementation does nothing; the
  return value is ignored. Keep in mind that notes must be copied on write or store.
  
  You never invoke this method from your application; it should only
  be invoked by the MKInstrument's MKNoteReceivers as they are sent
  <b>receiveNote:</b> messages.  Keep in mind that you can send
  <b>receiveNote:</b> directly to a MKNoteReceiver for diagnostic
  or other untimed reception purposes. 
*/
- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief You never invoke this method; it's invoked just before the
  MKInstrument realizes its first MKNote.

  A subclass can implement
  this method to perform pre-realization initialization.  The argument
  is the MKNote that the MKInstrument is about to realize; it's
  provided as a convenience and can be ignored in a subclass
  implementation.  The MKInstrument is considered to be in performance
  after this method returns.  The return value is ignored.
  
  @see - <b>afterPerformance</b>, - <b>inPerformance</b>
*/
- firstNote: (MKNote *) aNote;

/*!
  @return Returns an NSArray.
  @brief Creates and returns an NSArray that contains the MKInstrument's
  MKNoteReceivers.

  The MKNoteReceivers themselves aren't copied.
  
  @see - <b>addNoteReceiver</b>, -
  <b>noteReceiver</b>,<b></b> - <b>isNoteReceiverPresent</b>
*/
- (NSArray *) noteReceivers;

/*!
  @param  aNoteReceiver is an id.
  @return Returns an int.
  @brief Returns the ordinal index of <i>aNoteReceiver</i> in the
  MKInstrument's MKNoteReceiver NSArray.

  Returns -1 if
  <i>aNoteReceiver</i>is not in the NSArray.
*/
- (int) indexOfNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @param  aNoteReceiver is an MKNoteReceiver.
  @return Returns a BOOL.
  @brief Returns YES if <i>aNoteReceiver</i> is in the MKInstrument's
  MKNoteReceiver NSArray.

  Otherwise returns NO.
  
  @see - <b>noteReceiver</b>, - <b>noteReceivers</b>
*/
- (BOOL) isNoteReceiverPresent: (MKNoteReceiver *) aNoteReceiver; 

/*!
  @param  aNoteReceiver is an id.
  @return Returns an id.
  @brief Adds <i>aNoteReceiver</i> to the MKInstrument, first removing it
  from its current MKInstrument, if any.

  If the receiving
  MKInstrument is in performance, this does nothing and returns
  <b>nil</b>, otherwise returns <i>aNoteReceiver</i>.
  
  @see - <b>removeNoteReceiver:</b>, - <b>noteReceivers</b>, - <b>isNoteReceiverPresent:</b>
*/
- addNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @param  aNoteReceiver is an id.
  @return Returns an id.
  @brief Removes <i>aNoteReceiver</i> from the MKInstrument's MKNoteReceiver
  NSArray, but neither disconnects the MKNoteReceiver from its
  connected MKNoteSenders, nor does it free the MKNoteReceiver.

  If
  the MKInstrument is in performance, this does nothing and returns
  <b>nil</b>, otherwise returns <i>aNoteReceiver</i>.
  
  @see - <b>removeNoteReceivers</b>, - <b>addNoteReceiver</b>, - <b>noteReceivers</b>, - <b>isNoteReceiverPresent</b>
*/
- removeNoteReceiver: (MKNoteReceiver *) aNoteReceiver; 

/*!
  @brief Disconnects, removes, and releases ivars.

  If the receiver is in performance, does not release the MKInstrument's MKNoteReceivers. 
 
  @see - <b>removeNoteReceivers:</b>
 */
- (void) dealloc; 

/*!
  @return Returns an id.
  @brief Disconnects the object's MKNoteReceivers.

  
*/
- disconnectNoteReceivers;

/*!
  @return Returns an id.
  @brief Removes the object from the performance by disconnecting its
  MKNoteReceivers and invokes the <b>-afterPerformance</b> method.

  
  This method is needed in order to be able to free a MKNoteFilter or
  MKInstrument during a performance. If the receiver is not in performance,
  does nothing and returns <b>nil</b>.
*/
- removeFromPerformance;

/*!
  @return Returns <b>self</b>.
  @brief Removes all the MKInstrument's MKNoteReceivers but neither
  disconnects nor frees them.

  
  
  @see - <b>removeNoteReceiver</b>, - <b>addNoteReceiver</b>, - <b>noteReceivers</b>, - <b>isNoteReceiverPresent</b>
*/
- removeNoteReceivers; 

/*!
  @return Returns a BOOL.
  @brief Returns YES if the MKInstrument is in performance.

  Otherwise
  returns NO.  An MKInstrument is considered to be in performance from
  the time that one of its MKNoteReceivers invokes
  <b>realizNote:fromNoteReceiver:</b>, until the time that the
  MKConductor class receives <b>finishPerformance.</b>
  
  @see - <b>firstNote:</b>, - <b>afterPerformance</b>
*/
- (BOOL) inPerformance;

/*!
  @return Returns an id.
  @brief You never invoke this method; it's automatically invoked when the
  performance is finished.

  A subclass can implement this method to do
  post-performance cleanup.  The default implementation does nothing;
  the return value is ignored.
  
  @see - <b>firstNote:</b>, - <b>inPerformance</b>
*/
- afterPerformance; 

/*!
  @param  zone is a NSZone.
  @return Returns an id.
  @brief Creates and returns a new MKInstrument as a copy of the receiving
  MKInstrument allocated from <i>zone</i>.

  The new object has its own
  MKNoteReceiver collection that contains copies of the MKInstrument's
  MKNoteReceivers. The new MKNoteReceivers' connections (see the 
	  MKNoteReceiver class) are copied from the MKNoteReceivers in the receiving
  MKInstrument.
*/
- copyWithZone: (NSZone *) zone; 

/*!
  @return Returns an MKNoteReceiver.
  @brief Returns the first MKNoteReceiver in the MKInstrument's
  MKNoteReceiver NSArray.

  This is useful if you want to send a MKNote
  directly to an MKInstrument, but you don't care which MKNoteReceiver
  does the receiving:
  	
  <tt>[[anInstrument noteReceiver] receiveNote: aNote]</tt>
  
  If there are currently no MKNoteReceivers, this method
  creates and adds a MKNoteReceiver.
  
  @see - <b>addNoteReceiver</b>, - <b>noteReceivers</b>, - <b>isNoteReceiverPresent</b>
*/
- (MKNoteReceiver *) noteReceiver; 

 /* 
  * You never send this message directly.  Archives noteReceiver Array.
  */
- (void) encodeWithCoder: (NSCoder *) aCoder;

 /* 
  * You never send this message directly.  
  * Note that -init is not sent to newly unarchived objects.
  * See write:. 
  */
- (id) initWithCoder: (NSCoder *) aDecoder;

/*!
  @brief Immediately stops playing any sounding notes.

  The default
  behaviour is to do nothing.
  Subclasses may implement specific behaviour appropriate to the synthesis method.
*/
- allNotesOff;

@end

#endif
