/*
  $Id$
  Defined In: The MusicKit

  Description: 
    The MKMidi object provides MIDI input/output access. It emulates some of the
    behavior of a MKPerformer: It contains a NSMutableArray of MKNoteSenders, one per MIDI
    channel (as well as an extra one for MIDI system and channel mode messages).
    You can receive MKNotes derived from MIDI input by connecting an Instrument's
    MKNoteReceivers to the MKNoteSenders of a MKMidi instance.
   
    Similarly, MKMidi emulates some of the behavior of an MKInstrument: It contains
    an array of MKNoteReceivers, one per MIDI channel (as well as the extra one).
    You can send MKNotes to MIDI output by connecting a MKPerformer's MKNoteSenders
    to the MKNoteReceivers of a MKMidi instance.
   
    However, the MKMidi object is unlike a MKPerformer in that it represents a 
    real-time  device. In this manner, MKMidi is somewhat like MKOrchestra, 
    which represents the DSP. The protocol for controlling Midi is the same 
    as that for the MKOrchestra. This protocol is described in the file 
    <MusicKit/MKDeviceStatus.h>.
    
    The conversion between Music Kit and MIDI semantics is described in the
    Music Kit documentation.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University
  Portions (Time code extensions) Copyright (c) 1993 Pinnacle Research
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
@class MKConductor;

/*!
  @class MKMidi
  @brief

A MKMidi object lets you communicate with a MIDI synthesizer (attached
to a serial port at the back of a NeXT computer, to a MPU-401
compatible card installed in a P.C., to a MIDI device defined within 
Microsoft Windows DirectMusic or to a MIDI device defined within Apple
MacOS CoreMIDI) by providing a simple interface
to the MIDI device driver.  The MKMidi class also provides a mechanism
that automatically converts MIDI messages into MKNote objects and vice
versa, allowing you to incorporate MIDI data into a MusicKit
application with a minimum of effort.

While inheriting neither from MKPerformer nor MKInstrument, the MKMidi
class emulates both of them: Like a MKPerformer, it contains a NSArray
of MKNoteSenders, and, like an MKInstrument, it contains a NSArray of
MKNoteReceivers.  A newly created MKMidi object contains 17
MKNoteSenders and 17 MKNoteReceivers, one for each of the 16 Voice
Channels and one for the Basic Channel.  (Note, however, that the
method <b>setMergeInput:</b> allows the option of all messages to be
sent via MKNoteSender 0.  Similarly, if a MKNote is sent to
MKNoteReceiver 0, the MK_midiChan parameter of that MKNote determines
on which MIDI channel it is sent.)

Before a MKMidi object can receive messages from or send messages to
an external synthesizer, it must be sent the <b>open</b> and
<b>run</b> messages:

<ul>
<li>	<b>open</b> establishes communication between the object and the MIDI driver. 
<li>	<b>run</b> starts the driver's clock ticking.  
</ul>

Balancing these two methods are <b>stop</b> and <b>close</b>:

<ul>
<li>	<b>stop</b> stops the driver's clock.
<li>	<b>close</b> breaks communication between the object and the MIDI driver.
</ul>

The state of a MKMidi object with respect to the foregoing methods is
described in its <b>deviceStatus</b> instance variable:

<ul>
<li>	MK_devOpen.  The MKMidi object is open but not running.  
<li>	MK_devRunning.  The object is open and running.  
<li>	MK_devStopped.  The object has been running, but is now stopped.  
<li>	MK_devClosed.  The object is closed.
</ul>

(Note that these are the same methods and MKDeviceStatus values used
to control and describe the status of an MKOrchestra object.)

The MIDI driver has its own clock that's generally more regular and
steadfast than the MKConductor's clock.  To take advantage of this,
the MKConductor is, by default, synched to incoming MIDI messages:
When a MIDI message arrives, the MKConductor's clock is set to the
time stated in the message timestamp.  You can disable this feature
by sending <b>setUseInputTimeStamps: NO</b> to a MKMidi object.

On the other side, as a MKMidi object initiates an outgoing MIDI
message, it gives the message a timestamp that indicates when the
message should be performed by the external MIDI device.  By default,
the MIDI driver looks at the timestamp and waits until the appropriate
time (as determined by its own clock) to send the message on to the
synthesizer.  By sending <b>setOutputTimed: NO</b> to a MKMidi object,
you can specify that the driver is to ignore the timestamps and send
all messages as soon as it receives them.

Note that in all cases the MKConductor that's overseeing the MusicKit 
performance must be clocked if you want to use a MKMidi object.

As MKMidi receives MIDI messages it creates MKNote objects following these rules:

<ul>
<li>	For each MIDI message that has a Note Number, a MKNote object is created and
  given a noteTag that corresponds to the combination of the message's Channel 
  Number and Note Number.

<li>	If multiple Note Offs are received (for a particular Channel/Note number) without
  intervening Note Ons, only the first Note Off is converted into a MKNote object. 
  The others are suppressed.

<li>	A Note On message with a MIDI Velocity of 0 is turned into a MKNote object of type noteOff.

<li>	If a Note Off message has a MIDI Release Velocity of 0, the MK_releaseVelocity parameter in
  the corresponding MKNote object is omitted.
</ul>
 
In sending messages to an external synthesizer, MKMidi converts MKNote objects to MIDI messages:

<ul>
<li>	If two successive noteOns have the same noteTag and the same MK_keyNum value, a Note Off
  is generated on the same channel and with the same Key Number as those for the Note Ons.

<li>	If two successive noteOns have the same noteTag but different MK_keyNum values, the second
  Note On message is followed by a Note Off with the Key Number of the first Note On.  
  This is to accommodate MIDI Mono Mode.

<li>	A noteOff with no MK_relVelocity parameter is converted to a Note On with a Velocity of 0.
</ul>

A number of parameters are provided to accommodate MIDI messages.  These are described in
<a href=http://www.musickit.org/MusicKitConcepts/representationofmidi.html>
the section titled Representation of MIDI in the MusicKit
</a>.

A MKMidi object can be used to synchronize a performance to incoming
MIDI time code.  To do so, send a MKConductor the message
<b>setMTCSynch:</b>, with a MKMidi object as the argument.  For
further information on MIDI time code, see 
<a href=http://www.musickit.org/MusicKitConcepts/miditimecode.html>
the appendix titled MIDI Time Code in the MusicKit
</a>.

USING MIDI ON NeXT HARDWARE

See <b>Administration/MidiHardwareInfo.rtf</b>

*/
#ifndef __MK_Midi_H___
#define __MK_Midi_H___

#import <Foundation/NSObject.h>
#import <MKPerformSndMIDI/PerformMIDI.h>
#import "MKDeviceStatus.h"
#import "params.h"
#import "_midi.h"  // for _MKMidiInStruct and _MKMidiOutStruct definitions

/* sbrandon: 10/05/2001
 * get around the fact that GNUstep does not have NSMach ports, but does respond to -machPort
 * and +portWithMachPort
 */
#ifdef GNUSTEP
#define NSMachPort NSPort
#endif

@interface MKMidi: NSObject
{
    NSMutableArray *noteSenders;         /*! @var noteSenders The object's collection of MKNoteSenders. */
    NSMutableArray *noteReceivers;       /*! @var noteReceivers The object's collection of MKNoteReceivers. */
    MKDeviceStatus deviceStatus;         /*! @var deviceStatus See MKDeviceStatus.h */
    NSString *midiDevName;               /*! @var midiDevName Midi device port name. */
    BOOL useInputTimeStamps;             /*! @var useInputTimeStamps YES if MKConductor's time updated from driver's time stamps. */
    BOOL outputIsTimed;                  /*! @var outputIsTimed YES if the driver's clock is used for output */
    double localDeltaT;                  /*! @var localDeltaT Offset added to MIDI-out time stamps.(see below) */

@private
    /* systemIgnoreBits A bit map indicating which MIDI system messages to ignore from input */
    unsigned int systemIgnoreBits;
    _MKMidiInStruct *_pIn;               // determines input source
    _MKMidiOutStruct *_pOut;             // determines output sink
    double timeOffset;
    enum MKMidiDirection {MKMidiInputOnly, MKMidiOutputOnly, MKMidiInputOutput} ioMode; 
    BOOL isOwner;
    // These are handles used to identify the MIDI communication channel.
    // We pretend they are Mach ports even though they function only as references.
    NSMachPort *devicePort;      // Device port
    NSMachPort *ownerPort;       // Owner port, as for the device port.
    NSMachPort *recvPort;        // Port on which we receive midiIn messages
    NSMachPort *queuePort;       // Port on which we notify when there is space on the playback queue.
    BOOL mergeInput;
    NSString *hostname;          // for MIDI communicated across hosts.
    /*! @var inputUnit The index into the input drivers list */
    int inputUnit;
    /*! @var outputUnit The index into the output drivers list */
    int outputUnit;
    int queueSize;
    /*! @var conductor Holds a weak reference to the MKConductor controlled by and controlling MIDI I/O. */
    MKConductor *conductor;      // Used by conductor and setConductor: methods
    /*! @var synchConductor If non-nil, time mode is synchronise to MIDI Time Code (MTC). */
    MKConductor *synchConductor;
    NSMachPort *exceptionPort;   // Exception port.  Only one unit per device may have one.
    NSMachPort *alarmPort;       // Alarm port.  Only one unit per device may have one.
    /*! @var mtcMidiObj Which unit is receiving MTC. */
    MKMidi *mtcMidiObj;
    /*! @var displayReceivedMIDI Controls display of debugging information. */
    BOOL displayReceivedMIDI;
    double alarmTime;
    int intAlarmTime;
    BOOL alarmTimeValid;
    BOOL alarmPending;
}

#define MK_MAXMIDIS 16  /* Maximum number of Intel-based Midi objects */

/*!
  @return Returns an MKConductor.
  @brief Returns the conductor that the MKNotes originating with MKMidi will
  return when sent the -<b>conductor</b> message.

  By default, returns
  the defaultConductor, if the MKConductor class is loaded, else nil.
  
*/
- (MKConductor *) conductor;

/*!
  @param  aConductor is an MKConductor.
  @return Returns an id.
  @brief Sets the MKConductor that the MKNotes originating with MKMidi will
  return when sent the <b>-conductor</b> message.

  
*/
- setConductor: (MKConductor *) aConductor;

/*!
  @param  devName is a NSString *.
  @param  hostName is a NSString *.
  @return Returns an id.
  @brief If a MKMidi object for the device <i>devName</i> on host
  <i>hostName</i> doesn't already exist, this creates such an object
  and creates and adds to it a full complement of MKNoteSenders and
  MKNoteReceivers.

  Otherwise, returns the existing object.  <i></i>
  This enables an application to access another machine's MIDI
  ports.  
  
  &lt;&lt;On Non-NeXT hardware, <i>hostName</i> is currently ignored - thus,
  you may not open a MIDI device on a network-based device when running on white hardware.&gt;&gt;
*/
+ midiOnDevice: (NSString *) devName host: (NSString *) hostName;

/*!
  @param  devName is a NSString *.
  @return Returns an id.
  @brief If a MKMidi object for the device <i>devName</i> doesn't already
  exist, this creates such an object and creates and adds to it a full
  complement of MKNoteSenders and MKNoteReceivers.

  Otherwise, returns
  the existing object.  <i>devName</i>, for the NeXT (black) hardware,
  is "midi0" for serial port A or "midi1" for serial port B.    On
  white hardware "midi0" corresponds to the value of the defaults data
  base variable <i>MIDI0</i>, owned by <i>MIDI</i>.  (See the NeXT
  documentation on <b>dwrite</b> for more information about the
  defaults data base.)   Alternatively, <i>devName</i> may be the
  direct driverName/unit combination, e.g. "Mididriver2." 
  
*/
+ midiOnDevice: (NSString *) devName;
 /* Allocates and initializes a new object, if one doesn't exist already, for
    specified device. 
    For the NeXT hardware, "midi1" is serial port B and "midi0" is port A.
    For Intel hardware, "midi0" corresponds to MIDI0 in the defaults
    data base, "midi1" corresponds to MIDI1, etc.  You may also specify the
    driver/unit name explicitly as "Mididriver0", "Mididriver1", etc., in 
    which case no indirection via the defaults data base is done.
  */


/*!
  @return Returns an id.
  @brief If a MKMidi object for the device &ldquo;midi0&ldquo; doesn't already
  exist, this creates such an object and creates and adds to it a full
  complement of MKNoteSenders and MKNoteReceivers.

  Otherwise, returns
  the existing object.  &ldquo;midi0&rdquo; corresponds to serial port A on the
  NeXT (black) hardware, the default MIDI port on other platforms.  
*/
+ midi;

/*!
  @brief Initialises an allocated instance for a named MIDI device on a named host.
  @param devName An NSString naming the device. This should be that obtained from +<b>getDriverNames</b>.
  @param hostName An NSString naming the host machine that is running the MIDI device. Currently unused.
  @return Returns an initialised instance.
 */
- initOnDevice: (NSString *) devName hostName: (NSString *) hostName;

/*!
  @brief Initialises an allocated instance for a named MIDI device on the local host.
  @param devName An NSString naming the device. This should be that obtained from +<b>getDriverNames</b>.
  @return Returns an initialised instance.
 */
- initOnDevice: (NSString *) devName;

/*!
  @brief Initialises an allocated instance on the default MIDI device on the local host.
  @return Returns an initialised instance.
 */
- init;

/*!
  @brief free object, closing device if it is not already closed. 
 */
- (void) dealloc;

/*!
  @return Returns a MKDeviceStatus.
  @brief Returns the receiver's MKDeviceStatus device status.

  
*/
- (MKDeviceStatus) deviceStatus;

/*!
  @return Returns an id.
  @brief Opens the receiver, thus enabling two-way communication with the
  MIDI device it represents.

  The receiver's status is set to
  MK_devOpen.  If the receiver is already open, its input and output
  message queues are flushed.  Returns the receiver, or <b>nil</b> if
  it couldn't be opened.
*/
- open;

/*!
  @return Returns an id.
  @brief Opens the receiver for input from the MIDI device it represents.

  If
  the receiver is already open, its input message queue is flushed. 
  Returns the receiver, or <b>nil</b> if it couldn't be
  opened.
*/
- openInputOnly;

/*!
  @return Returns an id.
  @brief Opens the receiver for output to the MIDI device it represents.

  If
  the receiver is already open, its output message queue is flushed. 
  Returns the receiver, or <b>nil</b> if it couldn't be
  opened.
*/
- openOutputOnly;

/*!
  @return Returns an id.
  @brief Starts the receiver's clock, first opening the receiver if
  necessary, and sets the receiver's status to MK_devRunning.

  Returns
  the receiver, or <b>nil</b> if it's closed and can't be
  opened.
*/
- run;

/*!
  @return Returns an id.
  @brief Stops the receiver's clock and sets the receiver's status to
  MK_devStopped; opens the receiver if it isn't already open.

  Returns
  the receiver, or <b>nil</b> if it's closed and can't be
  opened.
*/
- stop;

/*!
  @brief Waits for the receiver's output queue to empty and then closes the
  receiver, sets its status to MK_devClosed, and releases the device
  port.

  
*/
- (void) close;

/*!
  @return Returns an id.
  @brief Immediately closes the receiver without waiting for the output queue to empty,
  sets its status to MK_devClosed, and releases the device port.

  Returns the receiver.
*/
- abort;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief Establishes whether MIDI messages are sent timed or untimed, as
  <i>yesOrNo</i> is YES or NO.

  If the receiver is timed, messages are
  stamped with the MKConductor's notion of the current time (plus the
  global and local delta times).  If it's untimed, the timestamps are
  always 0, indicating, to the MIDI driver, that the messages should
  be sent immediately.  The default is timed.
*/
- setOutputTimed: (BOOL) yesOrNo;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the receiver is timed, otherwise returns NO.

  The
  default is YES.
  
  If setOutputTimed:YES is sent, events are sent to the driver with time
  stamps equal to the MKConductor's time plus "deltaT". (See MKSetDeltaT()).
  If setOutputTimed:NO is sent, events are sent to the driver with a time
  stamp of 0, indicating they are to be played as soon as they are received.

  @see  -<b>setOutputTimed:</b>
*/
- (BOOL) outputIsTimed;

/*!
  @param  channel is an unsigned MIDI channel.
  @return Returns an MKNoteSender instance.
  @brief Returns the MKNoteSender corresponding to channel <i>n</i>, or
  <b>nil</b> if none.

  A MKMidi object's MKNoteSenders are
  numbered such that 0 is the MKNoteSender that processes
  system/channel mode messages and 1 through 16 are the MKNoteSenders
  for the MIDI channels. The MKNoteSender corresponding to 0 is
  special. It uses the MK_midiChan parameter of the note, if any, to
  determine which midi channel to send the note on. If no MK_midiChan
  parameter is present,  the default is channel 1. This MKNoteReceiver
  is also commonly used for MIDI channel mode and system messages.
  
*/
- (MKNoteSender *) channelNoteSender: (unsigned) n;

/*!
  @param  channel is an unsigned MIDI channel.
  @return Returns an MKNoteReceiver instance.
  @brief Returns the MKNoteReceiver corresponding to the specified channel <i>n</i>, or
  <b>nil</b> if none.

  A MKMidi object's MKNoteReceivers are numbered
  such that 0 is the MKNoteReceiver that processes system/channel mode
  messages and 1 through 16 are the MKNoteReceivers for the MIDI
  channels.  The MKNoteReceiver corresponding to 0 is special. It uses
  the MK_midiChan parameter of the note, if any, to determine which
  MIDI channel to send the note on. If no MK_midiChan parameter is present,
  the default is channel 1. 
*/
- (MKNoteReceiver *) channelNoteReceiver: (unsigned) channel;

/*!
  @return Returns an MKNoteReceiver instance.
  @brief Returns the default MKNoteReceiver.

  
*/
- (MKNoteReceiver *) noteReceiver;

/*!
  @return Returns an id.
  @brief Returns a NSArray containing the receiver's MKNoteReceivers.

  The
  NSArray object will be autoreleased, although its contents (the
  MKNoteReceiver objects themselves) will not be released.
*/
- (NSArray *) noteReceivers;

/*!
  @return Returns an id.
  @brief Returns the default MKNoteSender
*/
- (MKNoteSender *) noteSender;

/*!
  @return Returns an id.
  @brief Returns a NSArray containing the receiver's MKNoteSenders.

  The
  NSArray object will be autoreleased, although its contents (the
  MKNoteSender objects themselves) will not be released.
*/
- (NSArray *) noteSenders;
  
/* sb: added 30/6/98 to replace MidiIn function */
- (void) handleMachMessage: (void *) machMessage;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i> is <b>YES</b> the MKConductor's clock is synched
  to the MIDI driver's clock whenever the receiver receives a MIDI
  message.

  If the receiver isn't closed, this does nothing and
  returns <b>nil</b>; otherwise returns the receiver.
  
*/
- setUseInputTimeStamps: (BOOL) yesOrNo;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the MKConductor's clock is synched to the MIDI
  driver's clock, otherwise returns NO.

  The default is
  YES.
  
  By default, MKConductor's time is adjusted to that of
  the MKMidi input clock (useInputTimeStamps == YES). This
  is desirable when recording the MKNotes (e.g. with a
  MKPartRecorder). However, for real-time MIDI processing,
  it is preferable to use the MKConductor's time
  (useInputTimeStamps == NO).  setUseInputTimeStamps: and
  useInputTimeStamps set and get, respectively, this flag.
  
  Note that even with setUseInputTimeStamps:YES, the
  MKConductor's clock is not slave to the MIDI input
  clock. Rather, fine adjustment of the MKConductor's
  clock is made to match that of MIDI input. (Future
  releases of the MusicKit may provide the ability to use
  the MIDI clock as the primary source of time.)

  It is the application's responsibility to insure that
  MKMidi is stopped when the performance is paused and
  that Midi is run when the performance is resumed.  
*/
- (BOOL) useInputTimeStamps;


/*!
  @param  param is a MKMidiParVal.
  @return Returns an id.
  @brief Instructs the receiver to ignore messages that set the
  MK_sysRealTime parameter to <i>param</i>.

  The list of values that
  are ignored by default is given in <b>acceptSys:</b>.  Returns the
  receiver.
*/
- ignoreSys: (MKMidiParVal) param;

/*!
  @param  param is a MKMidiParVal.
  @return Returns an id.
  @brief Instructs the receiver to accept in-coming MIDI messages that set
  the MK_sysRealTime parameter to the value specified in <i>param</i>,
  which must be one of the following:
  
  MK_sysClock 
  MK_sysStart 
  MK_sysContinue 
  MK_sysStop
  MK_sysActiveSensing.

  
  
  By default, MIDI messages that set the MK_sysRealTime
  parameter are ignored.  Returns the receiver.  

	  These are currently the only MIDI messges that can be
  ignored. You enable or disable this feature using the
  ignoreSys: and acceptSys: methods. For example, to
  receive MK_sysActiveSensing, send [aMidiObj
  acceptSys:MK_activeSensing].  
*/
- acceptSys: (MKMidiParVal) param;

/*!
  @return Returns a double.
  @brief Returns the receiver's local delta time in seconds
*/
- (double) localDeltaT;

/*!
  @param  value is a double.
  @return Returns an the receiver (an id).
  @brief Sets the value of the receiver's local delta time, in seconds.

  This
  has no effect if the receiver isn't timed. 
  LocalDeltaT is added to time stamps sent to MIDI-out. 
  This is in addition to the deltaT set with MKSetDeltaT(). 
  Has no effect if the receiver is not in outputIsTimed mode. 
  The default local delta time is 0.0.
*/
- setLocalDeltaT: (double) value;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If set to YES, the MKNotes fashioned from the incoming MIDI stream
  are all sent to MKNoteSender 0 (the one that normally gets only
  system messages).

  In addition, a MK_midiChan is added so that the
  stream can be split up again later.
*/
- setMergeInput: (BOOL) yesOrNo;

/*!
  @return Returns an id.
  @brief If the receiver is running, blocks until all enqueued MIDI data has
  been sent to the MIDI cable.

  
*/
- awaitQueueDrain;

/*!
  @return Returns an id.
  @brief If the receiver is open for output, sends a MIDI noteOff to the MIDI
  cable on every key number on every MIDI channel.

  Unlike
  <b>allNotesOff</b>, this method sends MIDI noteOffs regardless of
  whether an unmatched MIDI noteOn was previously sent.
*/
- allNotesOffBlast;

/*!
  @return Returns an id.
  @brief If the receiver is open for output, sends a MIDI noteOff to the MIDI
  cable for every key number and MIDI channel for which an unmatched
  MIDI noteOn was previously sent.

  
*/
- allNotesOff;

/*!
  @return Returns a double.
  @brief Returns time according to the MIDI driver.

  If the <i>deltaT</i>
  mode is <b>MK_DELTAT_SCHEDULER_ADVANCE</b>, <i>deltaT</i> is added
  to this time.   If the receiver is providing time code for a
  MKConductor, that MKConductor's <i>timeOffset</i> is reflected in
  the time returned by this method.   Unlike most of the MusicKit time
  methods and functions, this one gets the current time, whether or
  not [MKConductor adjustTime] or  [MKConductor lockPerformacne] was
  invoked.  @see  MKSetDeltaTMode(), MKSetDeltaT() and
  MKConductor.
*/
- (double) time;

/*!
  @param  format is a short *.
  @param  h is a short *.
  @param  m is a short *.
  @param  s is a short *.
  @param  f is a short *.
  @return Returns an id.
  @brief This only works if the receiver is currently providing MIDI time
  code to a MKConductor.

  Returns the current time from the MIDI
  driver.  Unlike most of the MusicKit time methods and functions,
  this one gets the current time, whether or not [MKConductor
  adjustTime] or  [MKConductor lockPerformacne] was invoked.    If the
  <i>deltaT</i> mode is <b>MK_DELTAT_SCHEDULER_ADVANCE</b>, the
  returned value has <i>deltaT</i> added to it. 
*/
- getMTCFormat: (short *) format
	 hours: (short *) h
	   min: (short *) m
	   sec: (short *) s
	frames: (short *) f;

/*!
  @return Returns an id.
  @brief If the receiver has been set to provide MIDI time code to a
  MKConductor, this method returns that MKConductor.

  Otherwise, it
  returns <b>nil</b>.
*/
- synchConductor;

/*!
  @return Returns an NSArray instance.
  @brief Returns an array of all available bidirectional driver names added to the system.
  
  The arrays and strings are copied and autoreleased. Only those drivers which support
  both output and input are returned. To return additional drivers which may support only
  input or output, use +<b>getDriverNamesForInput:</b>.
*/
+ (NSArray *) getDriverNames;

/*!
  @return Returns an NSArray instance.
  @brief Returns an array of all available driver names for input.
  
  This list may include drivers that are also available for output and those drivers which are for input only.
 */
+ (NSArray *) getDriverNamesForInput;

/*!
  @return Returns an NSArray instance.
  @brief Returns an array of all available driver names for output.
  
  This list may include drivers that are also available for input and those drivers which are for output only.
 */
+ (NSArray *) getDriverNamesForOutput;

/*!
  @return Returns an NSString instance.
  @brief Returns the name of the MIDI driver associated with this instance of MKMidi.

  
*/
- (NSString *) driverName;

/*!
  @return Returns an NSString instance.
  @brief Returns description of which device, the unit and the host the MKMidi
  object has been initialised on
*/
- (NSString *) description;

/*!
  @brief Download MMA DownLoadable Sounds with patch numbers provided.

  
*/
- (void) downloadDLS: (NSArray *) dlsPatches;

@end

#endif
