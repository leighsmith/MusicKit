/*
  $Id$
  Defined In: The MusicKit

  Description: 
    The MKMidi object provides Midi input/output access. It emulates some of the
    behavior of a Performer: It contains a NSMutableArray of MKNoteSenders, one per MIDI
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
    as that for the Orchestra. This protocol is described in the file 
    <MusicKit/MKDeviceStatus.h>.
    
    The conversion between Music Kit and MIDI semantics is described in the
    Music Kit documentation.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University
  Portions (Time code extensions) Copyright (c) 1993 Pinnacle Research
*/
/*
  $Log$
  Revision 1.9  2000/01/27 19:06:12  leigh
  Now using NSPort replacing C Mach port API

  Revision 1.8  2000/01/24 22:31:28  leigh
  Comment improvements

  Revision 1.7  1999/10/28 01:37:14  leigh
  driver names and units now returned by separate class methods, renamed ivar

  Revision 1.6  1999/09/24 17:06:26  leigh
  added downloadDLS method prototype

  Revision 1.5  1999/09/04 22:02:17  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.4  1999/08/26 19:55:21  leigh
  extra documentation

  Revision 1.3  1999/08/08 01:59:22  leigh
  Removed extraVars cruft

  Revision 1.2  1999/07/29 01:25:45  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Midi_H___
#define __MK_Midi_H___

#import <Foundation/NSObject.h>
#import "MKDeviceStatus.h"
#import "params.h"

// this is a private structure that now has to live in a public header after the ivar freeze,
// but it will become an object one day anyway.

typedef struct _timeVars {
    id synchConductor;         /* If non-nil, time mode is MTC Synch */
    NSPort *exceptionPort; /* Exception port.  Only one unit per device may have one */
    NSPort *alarmPort;     /* Alarm port.  Only one unit per device may have one */
    id midiObj;                /* Which unit is receiving MTC. */
    double alarmTime;
    int intAlarmTime;
    BOOL alarmTimeValid;
    BOOL alarmPending;
} timeVars;

@interface MKMidi:NSObject
{
    NSMutableArray * noteSenders;        /* The object's collection of NoteSenders. */
    NSMutableArray * noteReceivers;      /* The object's collection of NoteReceivers */
    MKDeviceStatus deviceStatus;         /* See MKDeviceStatus.h */
    NSString *midiDevName;               /* Midi device port name. */
    BOOL useInputTimeStamps;             /* YES if Conductor's time updated from driver's time stamps.*/
    BOOL outputIsTimed;                  /* YES if the driver's clock is used for output */
    double localDeltaT;                  /* Offset added to MIDI-out time stamps.(see below)*/

    /* The following are for internal use only.  */
    unsigned _ignoreBits;
    void *_pIn;  // should be _MKMidiInStruct *
    void *_pOut; // should be _MKMidiOutStruct *
    double _timeOffset;
    char ioMode; // should be an enumerated type. 'i' = MKMidiInputOnly 'o' = MKMidiOutputOnly 'a' = MKMidiIO
    BOOL isOwner;
    NSPort *devicePort; // Device port
    NSPort *ownerPort;
    NSPort *recvPort;   // Port on which we receive midiIn messages
    NSPort *queuePort;  // Queues.
    BOOL mergeInput;
    NSString *hostname;
    int unit;
    int queueSize;
    id conductor;       // Used by conductor and setConductor: methods
    timeVars *tvs;      // MIDI Time Code (MTC) additions
}

#define MK_MAXMIDIS 16  /* Maximum number of Intel-based Midi objects */

-conductor;
 /* Returns the conductor that the Notes originating with Midi will return
  * when sent the -conductor message.  
  * By default, returns the defaultConductor, if the Conductor class is 
  * loaded, else nil. */

-setConductor:aConductor;
 /* Sets the Conductor that the Notes originating with Midi will return
  * when sent the -conductor message. 
  */

+midiOnDevice:(NSString *) devName host:(NSString *) hostName;
 /* Allocates and initializes a new object, if one doesn't exist already, for
    specified device and host. */

+midiOnDevice:(NSString *) devName;
 /* Allocates and initializes a new object, if one doesn't exist already, for
    specified device. 
    For the NeXT hardware, "midi1" is serial port B and "midi0" is port A.
    For Intel hardware, "midi0" corresponds to MIDI0 in the defaults
    data base, "midi1" corresponds to MIDI1, etc.  You may also specify the
    driver/unit name explicitly as "Mididriver0", "Mididriver1", etc., in 
    which case no indirection via the defaults data base is done.
  */

+midi;
 /* Allocates and initializes a new object, if one doesn't exist already, for
    default device (serial port A (aka "midi0") on NeXT hardware, 
    "midi0" on Intel hardware). */

- initOnDevice: (NSString *) devName hostName: (NSString *) hostName;
- initOnDevice: (NSString *) devName;
- init;
  /* theme and variations of initialising an allocated instance */

- (void)dealloc;
  /* free object, closing device if it is not already closed. */

-(MKDeviceStatus)deviceStatus;
  /* Returns MKDeviceStatus of receiver. */

-open;
  /* Opens device if not already open.
   * If already open, flushes input and output queues. 
   * Sets deviceStatus to MK_devOpen. 
   * Returns nil if failure.
   */

-openInputOnly;
-openOutputOnly;
 /* These are like -open but enable only input or output, respectively. */ 

- run;
 /* If not open, does a [self open].
  * If not already running, starts clock. 
  * Sets deviceStatus to MK_devRunning. Returns nil if failure. */

-stop;
 /* If not open, does a [self open].
  * Otherwise, stops MidiIn clock and sets deviceStatus to MK_devPaused.
  */

- (void)close;
 /* Closes the device, after waiting for the output queue to empty.
  * Releases the device port. This method blocks until the output queue
  * is empty.
  */

-abort;
 /* Closes the device, without waiting for the output queue to empty. */

-setOutputTimed:(BOOL)yesOrNo;
-(BOOL)outputIsTimed;
 /* If setOutputTimed:YES is sent, events are sent to the driver with time
  * stamps equal to the Conductor's time plus "deltaT". (See MKSetDeltaT()).
  * If setOutputTimed:NO is sent, events are sent to the driver with a time
  * stamp of 0, indicating they are to be played as soon as they are received.
  * Default is YES.
  */

-channelNoteSender:(unsigned)n;
 /* Returns the MKNoteSender corresponding to the specified channel or nil
  * if none. If n is 0, returns the MKNoteSender used for Notes fasioned
  * from MIDI channel mode and system messages. */

-channelNoteReceiver:(unsigned)n;
 /* Returns the NoteReceiver corresponding to the specified channel or nil
  * if none. The NoteReceiver corresponding to 0 is special. It uses
  * the MK_midiChan parameter of the note, if any, to determine which
  * midi channel to send the note on. If no MK_midiChan parameter is present,
  * the default is channel 1. This NoteReceiver is also commonly used
  * for MIDI channel mode and system messages. */

-noteReceiver;
 /* Returns the defualt NoteReceiver. */
-noteReceivers;
 /* Returns a List containing the receiver's NoteReceivers. The List may be
  * freed by the caller, although its contents should not. */
-noteSender;
 /* Returns the defualt MKNoteSender. */
-noteSenders;
 /* Returns a List containing the receiver's NoteSenders. The List may be
  * freed by the caller, although its contents should not. */
- (void)handleMachMessage:(void *)machMessage;
 /*sb: added 30/6/98 to replace MidiIn function */

-setUseInputTimeStamps:(BOOL)yesOrNo;
-(BOOL)useInputTimeStamps;
 /* By default, Conductor's time is adjusted to that of the Midi input 
  * clock (useInputTimeStamps == YES). 
  * This is desirable when recording the Notes (e.g. with a 
  * PartRecorder). However, for real-time MIDI processing, it is preferable
  * to use the Conductor's time (useInputTimeStamps == NO). 
  * setUseInputTimeStamps: and useInputTimeStamps set and get, respectively, 
  * this flag. 
  *
  * Note that even with setUseInputTimeStamps:YES, the Conductor's clock is 
  * not slave to the MIDI input clock. Rather, fine adjustment of 
  * the Conductor's clock is made to match that of MIDI input. (Future releases
  * of the Music Kit may provide the ability to use the MIDI clock as the
  * primary source of time.)
  *
  * It is the application's responsibility to insure that Midi is stopped
  * when the performance is paused and that Midi is run when the performance
  * is resumed.
  */

-ignoreSys:(MKMidiParVal)param;
-acceptSys:(MKMidiParVal)param;
 /* By default, Midi input ignores MIDI messages that set the MK_sysRealTime
  * parameter to the following MKMidiParVals:
  * MK_sysClock, MK_sysStart, MK_sysContinue, MK_sysStop, 
  * MK_sysActiveSensing. These are currently the only MIDI messges that
  * can be ignored. You enable or disable this feature using the 
  * ignoreSys: and acceptSys: methods. For example, to receive 
  * MK_sysActiveSensing, send [aMidiObj acceptSys:MK_activeSensing]. */

-(double)localDeltaT;
-setLocalDeltaT:(double)value;
 /* Sets and retrieves the value of localDeltaT. LocalDeltaT is added to time 
  * stamps sent to MIDI-out. 
  * This is in addition to the deltaT set with MKSetDeltaT(). 
  * Has no effect if the receiver is not in outputIsTimed mode. Default is 
  * 0. 
  */

-setMergeInput:(BOOL)yesOrNo;
 /* If set to YES, the Notes fashioned from the incoming MIDI stream are all
  * sent to MKNoteSender 0 (the one that normally gets only system messages).
  * In addition, a MK_midiChan is added so that the stream can be split up
  * again later.
  */

 /* -read: and -write: 
  * Note that archiving is not yet supported in the Midi object. To archive
  * the connections of a Midi object, archive the individual NoteSenders and
  * NoteReceivers. 
  */

-awaitQueueDrain;
- allNotesOffBlast;
-allNotesOff;
-(double)time;
- getMTCFormat:(short *)format hours:(short*)h min:(short *)m sec:(short *)s
 frames:(short *)f;
-synchConductor;

// Returns NSArrays of all available driver names and their unit numbers
+ (NSArray *) getDriverNames;
+ (NSArray *) getDriverUnits;

-(NSString *)driverName;
-(int)driverUnit;

// download MMA DownLoadable Sounds with patch numbers provided.
- (void) downloadDLS: (NSArray *) dlsPatches;

@end
#endif
