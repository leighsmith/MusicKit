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
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.10  2001/09/07 00:14:46  leighsmith
  Corrected @discussion

  Revision 1.9  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

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
/*!
  @class MKInstrument
  @discussion

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

&#183;	An MKInstrument's <b>firstNote:</b> and <b>afterPerformance</b> methods
are invoked as the MKInstrument begins and finishes its performance,
respectively.  These methods can be implemented in a subclass to provide
specialized initialization and post-performance cleanup.

&#183;	Some MKInstrument methods can't be invoked during a performance.  For
example, you can't add or remove MKNoteReceivers while the MKInstrument is
performing.

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


/*!
  @method init
  @result Returns <b>self</b>.
  @discussion Initializes an MKInstrument that was created through
              <b>allocFromZone:</b>.  You never invoke this method directly.  A
              subclass implementation should send [super init] before
              performing its own initialization.  The return value is ignored.
*/
- init; 

/*!
  @method realizeNote:fromNoteReceiver:
  @param  aNote is an id.
  @param  aNoteReceiver is an id.
  @result Returns an id.
  @discussion You implement this method in a subclass to define the manner in
              which the subclass realizes MKNotes.  <i>aNote</i> is the MKNote
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
  @method firstNote:
  @param  aNote is an id.
  @result Returns an id.
  @discussion You never invoke this method; it's invoked just before the
              MKInstrument realizes its first MKNote.  A subclass can implement
              this method to perform pre-realization initialization.  The argument
              is the MKNote that the MKInstrument is about to realize; it's
              provided as a convenience and can be ignored in a subclass
              implementation.  The MKInstrument is considered to be in performance
              after this method returns.  The return value is ignored.
              
              See also: - <b>afterPerformance</b>, - <b>inPerformance</b>
*/
- firstNote: (MKNote *) aNote;

/*!
  @method noteReceivers
  @result Returns an NSArray.
  @discussion Creates and returns an NSArray that contains the MKInstrument's
              MKNoteReceivers. The MKNoteReceivers themselves aren't copied.
              
              See also: - <b>addNoteReceiver</b>, -
              <b>noteReceiver</b>,<b></b> - <b>isNoteReceiverPresent</b>
*/
- (NSArray *) noteReceivers;

/*!
  @method indexOfNoteReceiver:
  @param  aNoteReceiver is an id.
  @result Returns an int.
  @discussion Returns the ordinal index of <i>aNoteReceiver</i> in the
              MKInstrument's MKNoteReceiver NSArray.  Returns -1 if
              <i>aNoteReceiver</i>is not in the NSArray.
*/
- (int) indexOfNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @method isNoteReceiverPresent:
  @param  aNoteReceiver is an MKNoteReceiver.
  @result Returns a BOOL.
  @discussion Returns YES if <i>aNoteReceiver</i> is in the MKInstrument's
              MKNoteReceiver NSArray.  Otherwise returns NO.
              
              See also: - <b>noteReceiver</b>,<b></b> -
              <b>noteReceivers</b>
*/
- (BOOL) isNoteReceiverPresent: (MKNoteReceiver *) aNoteReceiver; 

/*!
  @method addNoteReceiver:
  @param  aNoteReceiver is an id.
  @result Returns an id.
  @discussion Adds <i>aNoteReceiver</i> to the MKInstrument, first removing it
              from its current MKInstrument, if any.  If the receiving
              MKInstrument is in performance, this does nothing and returns
              <b>nil</b>, otherwise returns <i>aNoteReceiver</i>.
              
              See also: - <b>removeNoteReceiver:</b>,<b></b>- <b>noteReceivers</b>,<b> </b> - <b>isNoteReceiverPresent:</b>
*/
- addNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @method removeNoteReceiver:
  @param  aNoteReceiver is an id.
  @result Returns an id.
  @discussion Removes <i>aNoteReceiver</i> from the MKInstrument's MKNoteReceiver
              NSArray, but neither disconnects the MKNoteReceiver from its
              connected MKNoteSenders, nor does it free the MKNoteReceiver.  If
              the MKInstrument is in performance, this does nothing and returns
              <b>nil</b>, otherwise returns <i>aNoteReceiver</i>.
              
              See also: - <b>removeNoteReceivers</b>, - <b>addNoteReceiver</b>, - <b>noteReceivers</b>,<b></b> - <b>isNoteReceiverPresent</b>
*/
- removeNoteReceiver: (MKNoteReceiver *) aNoteReceiver; 

 /* 
  * Sends freeNoteReceivers to self and then frees the receiver.  If the
  * receiver is in performance, does nothing and returns the receiver,
  * otherwise returns nil.  */
- (void)dealloc; 

/*!
  @method disconnectNoteReceivers
  @result Returns an id.
  @discussion Disconnects the object's MKNoteReceivers.
*/
-disconnectNoteReceivers;

/*!
  @method removeFromPerformance
  @result Returns an id.
  @discussion Removes the object from the performance by disconnecting its
              MKNoteReceivers and invokes the <b>-afterPerformance</b> method. 
              This method is needed in order to be able to free a MKNoteFilter or
              MKInstrument during a performance. If the receiver is not in performance,
              does nothing and returns <b>nil</b>.
*/
-removeFromPerformance;

/*!
  @method releaseNoteReceivers
  @result Returns <b>self</b>.
  @discussion Disconnects, removes, and frees the MKInstrument's MKNoteReceivers. 
              No checking is done to determine if the MKInstrument is in
              performance.  
              
              See also: - <b>removeNoteReceivers:</b>
*/
- releaseNoteReceivers;

/*!
  @method removeNoteReceivers
  @result Returns <b>self</b>.
  @discussion Removes all the MKInstrument's MKNoteReceivers but neither
              disconnects nor frees them. 
              
              See also: - <b>removeNoteReceiver</b>, - <b>addNoteReceiver</b>, - <b>noteReceivers</b>,<b> </b>- <b>isNoteReceiverPresent</b>
*/
- removeNoteReceivers; 

/*!
  @method inPerformance
  @result Returns a BOOL.
  @discussion Returns YES if the MKInstrument is in performance.  Otherwise
              returns NO.  An MKInstrument is considered to be in performance from
              the time that one of its MKNoteReceivers invokes
              <b>realizNote:fromNoteReceiver:</b>, until the time that the
              MKConductor class receives <b>finishPerformance.</b>
                            
              See also: - <b>firstNote:</b>, - <b>afterPerformance</b>
*/
-(BOOL) inPerformance;

/*!
  @method afterPerformance
  @result Returns an id.
  @discussion You never invoke this method; it's automatically invoked when the
              performance is finished.  A subclass can implement this method to do
              post-performance cleanup.  The default implementation does nothing;
              the return value is ignored.
              
              See also: - <b>firstNote:</b>, - <b>inPerformance</b>
*/
- afterPerformance; 

/*!
  @method copy
  @result Returns an id.
  @discussion Creates and returns a new MKInstrument as a copy of the receiving
              MKInstrument.  The new object has its own MKNoteReceiver collection
              that contains copies of the MKInstrument's MKNoteReceivers.  The new
              MKNoteReceivers' connections (see the MKNoteReceiver class) are
              copied from the MKNoteReceivers in the receiving
              MKInstrument.
              
              See also: - <b>copyWithZone:</b>
*/
- copy; 

/*!
  @method copyWithZone:
  @param  zone is a NSZone.
  @result Returns an id.
  @discussion This is the same as <b>copy</b>, but the new object is allocated
              from <i>zone</i>.
              
              See also: - <b>copy</b>
*/
- copyWithZone: (NSZone *) zone; 

/*!
  @method noteReceiver
  @result Returns an MKNoteReceiver.
  @discussion Returns the first MKNoteReceiver in the MKInstrument's
              MKNoteReceiver NSArray.  This is useful if you want to send a MKNote
              directly to an MKInstrument, but you don't care which MKNoteReceiver
              does the receiving:
              	
              <tt>[[anInstrument noteReceiver] receiveNote:aNote]
              </tt>
              
              If there are currently no MKNoteReceivers, this method
              creates and adds a MKNoteReceiver.
              
              See also: - <b>addNoteReceiver</b>, -
              <b>noteReceivers</b>,<b></b> - <b>isNoteReceiverPresent</b>
*/
- (MKNoteReceiver *) noteReceiver; 

 /* 
  * You never send this message directly.  Should be invoked with
  * NXWriteRootObject().  Archives noteReceiver List. */
- (void)encodeWithCoder: (NSCoder *) aCoder;

 /* 
  * You never send this message directly.  
  * Should be invoked via NXReadObject(). 
  * Note that -init is not sent to newly unarchived objects.
  * See write:. */
- (id)initWithCoder: (NSCoder *) aDecoder;

/*!
    @method allNotesOff
    @discussion Immediately stops playing any sounding notes. The default
                behaviour is to do nothing.
                Subclasses may implement specific behaviour appropriate to the synthesis method.
*/
- allNotesOff;

 /* Obsolete methods: */
+ new; 

@end

#endif
