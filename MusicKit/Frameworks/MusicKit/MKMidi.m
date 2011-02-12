/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    MKMidi is made to look somewhat like a MKPerformer. It differs from a
    performer, however, in that it responds not to messages sent by a
    conductor, but by MIDI input which arrives through the serial port.

    Note that the MKConductor must be clocked to use MKMidi.

    The elaborate support here for shared ownership stems from the fact that, 
    unlike with DSP drivers, the MIDI driver is also a time base.  That means
    that it must be shared among all instances.
    This complicates matters if we ever have more than one driver (as opposed to
    multiple instances of one driver.)  For now, I'm going to punt on that. If
    the situation ever comes up, we may have to factor the time stuff out of the
    driver and make a separate time server, which will be hard, seeing how MIDI
    time code must be parsed, etc.

    There is another subtle difference between MIDI and DSP handling.
    In the case of MIDI, we are perfectly happy to allocate objects for bogus
    midi objects.  We don't find out they're bogus until we try to open them.

    Note that the support for MIDI devices on different hosts is currently disabled.
    Hence if the host machine (the one the MusicKit app is running on) is a non-NeXT
    machine, we ignore the hostName.

    Also, if a NeXT host tries to access a MIDI driver on an Intel machine, it
    will fail because there's no device "midiN" on Intel.

    Explanation of MIDI driver support:

    For Win32, Linux and MacOS X, the MKPerformSndMIDI framework interfacing to
    DirectMusic, portmusic or CoreMIDI will return a list of "drivers", which can be hardware MIDI
    interfaces, PCM ROM playback engines on soundcards, software sound synthesisers
    etc. The device name can be either a driver and port description string (exactly matching one of
    the driverNames), or can be "midiX" i.e. the soft form described above, where X is the
    0 base index referring to a driver.

    For NeXTStep/OpenStep Intel:

    On the DSP, we use "soft" integers to map to "hard" driver/unit pairs.
    Here, we pass in a device 'name' in the form "midiN", where N is an integer.
    On the NeXT hardware, "midi" is a "hard" driver name and "N" is a hard unit
    number.  So, to maintain backward compatibility, we keep this interface, but
    we consider "midi" to be a signal to use soft numbering.

    Therefore, the algorithm is:

    If we're running on a non-NeXT machine,
    look at root of name (everything up to the final integer).
    If it's "midi", assume the final number is "soft".
    Otherwise, accept anything that's not "midi" as a hard driver name.

    There are two different schemes of management of interface to the MKMD functions.
    To achieve maximum portablity, we assume a Mach port is nothing more than an integer
    and functions as a handle with which to refer to a MIDI driver. It is only when receiving
    data do we need to actually behave as a Mach port. This is conditionally compiled using
    MKMD_RECEPTION_USING_PORTS defined in MKPerformSndMIDI/PerformMIDI.h. The alternative
    is to use a call back function. Therefore, while we do need a NSPort or NSMachPort,
    their support can be minimal and we are not enforced to run on a Mach type operating system.

  Original Author: David A. Jaffe
  Substantially rewritten: Leigh M. Smith

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/*
Modification history prior to commit to CVS:

  09/19/89/daj - Change to accomodate new way of doing parameters (structs 
                 rather than objects).
  01/06/90/daj - Added mergeInput option. Flushed flase cond comp.
                 Added some comments. 
  01/31/90/daj - Changed mergeInput to be an "extra var" and changed 
                 midiPorts struct to be a generic "extra var" struct. This
		 all in the interest of 1.0 backward header file compatability.
  02/25/90/daj - Moved putSysExclByte to writeMidi.
                 Changes to accomodate new way of doing midiFiles.
  03/13/90/daj - Added import of _NoteSender.h to accomodate new compiler.
  03/18/90/daj - Fixed bug in _open (needed DPSAddPort)		 
  03/19/90/daj - Changed to use MKGetNoteClass()
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/23/90/daj - Changes to make it a shlib and to make header files more
                 modular.
  07/24/90/daj - Changed to use _MKSprintf and _MKVsprintf for thread-safety
                 in a multi-threaded Music Kit performance.
  08/25/90/daj - Added error for "can't become owner".
  03/29/91/daj - Added awaitMidiOutDone() after allNotesOff in close and abort
  04/16/91/daj - Changed to buffer up incoming sys excl and then convert it 
                 into a string.
  04/24/91/daj - Removed (!) allNotesOff from close and abort (mmcnabb thinks
                 they should be orthogonal). Since the allNotesOff feature was
		 added only for 2.1 and wasn't documented, and since Music 
		 Prose probably isn't going to ship until 3.0, this is ok.
		 Fixed bug in awaiting for output queue to empty -- if the
		 driver was paused (we're in stopped or open mode and we've
		 sent something), the Music Kit hangs.
  08/26/91/daj - Internationalized strings.
  08/30/91/daj - Changed to set time tag of incoming notes.
                 Flushed superfluous setting of timeTag when creating MKNote
		 in sysex method.
  09/06/91/daj - Switched to new driver.  Need to release unit and driver.
  01/07/92/daj - Added break out of midi_data_reply when the response
                 to the incoming MKNote is to abort.
  06/04/92/daj - Added settable conductor.
  10/20/92/daj - Set table name to _MK_ERRTAB so that localization will work.
  10/31/92/daj - Got rid of bad free of NXAtom hostname.
  11/16/92/daj - Changes for Midi time code.
  11/17/92/daj - Changes to flush warnings.
  06/30/93/daj - Added timeout to awaitMidiOutDone and such.  This is to work
                 around a (possible??) driver bug whereby MIDIAwaitReply() 
		 never returns.  I don't know what's wrong.  Maybe the driver
		 never sends the bytes or maybe the queue is available and
		 the driver doesn't tell us for some reason.  Or maybe the
		 message gets dropped on the floor, though I don't see how this
		 could happen!
  07/1/93/daj -  Added an arg to machErr for more descriptive error reporting.
  03/16/94/daj - Hacked to work around NEXTSTEP 3.2 libmididriver bug.
  09/7/94/daj -  Updated to not use libsys functions.
  10/31/98/lms - Major reorganization for OpenStep conventions, allocation and classes.
*/
#import <Foundation/NSUserDefaults.h>

/* MusicKit include files */
#import "_musickit.h"
#import "tokens.h"
#import "_error.h"
#import "_ParName.h"
#import "_midi.h"
#import "_time.h"
#import "ConductorPrivate.h"
#import "MidiPrivate.h"

@implementation MKMidi

#define MIDIINPTR(midiobj) (((MKMidi *)(midiobj))->_pIn)
#define MIDIOUTPTR(midiobj) ((midiobj)->_pOut)

#define INPUTENABLED(_x) ((_x) != MKMidiOutputOnly)
#define OUTPUTENABLED(_x) ((_x) != MKMidiInputOnly)

#define MSG_LEN_IS_VARIABLE 3

#define UNAVAIL_DRIVER_ERROR \
NSLocalizedStringFromTableInBundle(@"MIDI driver is unavailable. Perhaps another application is using it", _MK_ERRTAB, _MKErrorBundle(), "")

#define UNAVAIL_UNIT_ERROR \
NSLocalizedStringFromTableInBundle(@"MIDI port is unavailable. Perhaps another application is using the port", _MK_ERRTAB, _MKErrorBundle(), "")

#define INPUT_ERROR \
NSLocalizedStringFromTableInBundle(@"Problem receiving MIDI from the MIDI device driver port", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an error is received from the Mach MIDI driver when receiving MIDI data.")

#define OUTPUT_ERROR \
NSLocalizedStringFromTableInBundle(@"Problem sending MIDI to the MIDI device driver port", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an error is received from the MIDI driver when sending MIDI data.")

#define OWNER_ERROR \
NSLocalizedStringFromTableInBundle(@"Can't become owner of MIDI driver", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an attempt to become owner of the MIDI driver fails.")

#define OPEN_ERROR \
NSLocalizedStringFromTableInBundle(@"Problem setting up MIDI device driver", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when a Mach error occurs in the course of setting up access to the MIDI device driver.")

#define NETNAME_ERROR \
NSLocalizedStringFromTableInBundle(@"Problem finding MIDI device driver", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when the MIDI device driver cannot be found.")

#define CLOCK_ERROR \
NSLocalizedStringFromTableInBundle(@"Problem communicating with MIDI device driver clock", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when a Mach error occurs in the course of communicating between the Music Kit and the MIDI device driver clock.")

/* Defines for system ignores. */
#define IGNORE_CLOCK	 0x0100
#define IGNORE_START	 0x0400
#define IGNORE_CONTINUE	 0x0800
#define IGNORE_STOP	 0x1000
#define IGNORE_ACTIVE	 0x4000
#define IGNORE_RESET	 0x8000
/* All of the above */
#define IGNORE_REAL_TIME (IGNORE_CLOCK + IGNORE_START + IGNORE_CONTINUE + IGNORE_STOP + IGNORE_ACTIVE + IGNORE_RESET)

// TODO This should be able to be removed.
#define FCC_DID_NOT_APPROVE_DRIVER_CHANGE 1 

#define DEFAULT_SOFT_NAME @"midi0" // TODO This should be changed to "midi" or "midiDefault"

#define NO_UNIT (-1)

#define DEFAULT_SYSEX_MSGLEN 256

// class variables
static int addedPortsCount = 0; // For MTC.
// Maps driver names to MKMidi instances. This is a slight misnomer since instances are added when 
// they are initialised, not when they are opened, yet they are removed when they are closed, not deallocated.
static NSMutableDictionary *openDrivers = nil;  
static NSMutableArray *bidirectionalDriverNames = nil;
static NSMutableArray *inputDriverNames = nil;
static NSMutableArray *outputDriverNames = nil;
static unsigned int systemDefaultDriverNum;   // index into the midiDriverNames and units that the operating system has nominated as default
static double mtcTimeOffset = 0;    // TODO should this be an ivar?

/* Some forward decls */
static void midi_data_reply(void *receivingMidiPtr, short unit, MKMDRawEvent *events, unsigned int count);

/* TYPE: Archiving; Writes object.
 You never send this message directly.  
 Archives the note senders and receivers, device and host names, the ports used as handles
 for communication to the performance framework, conductors, timing, I/O mode, queue sizes, status etc.
 */
- (void) encodeWithCoder: (NSCoder *) aCoder
{
    if([aCoder allowsKeyedCoding]) {
	[aCoder encodeObject: midiDevName forKey: @"MKMidi_midiDevName"];
	[aCoder encodeObject: hostname forKey: @"MKMidi_hostname"];
	[aCoder encodeObject: noteSenders forKey: @"MKMidi_noteSenders"];
	[aCoder encodeObject: noteReceivers forKey: @"MKMidi_noteReceivers"];
	
	[aCoder encodeInt: devicePort forKey: @"MKMidi_devicePort"];
	[aCoder encodeInt: ownerPort forKey: @"MKMidi_ownerPort"];
	[aCoder encodeInt: recvPort forKey: @"MKMidi_recvPort"];
	[aCoder encodeInt: queuePort forKey: @"MKMidi_queuePort"];
	[aCoder encodeConditionalObject: conductor forKey: @"MKMidi_conductor"];
	[aCoder encodeConditionalObject: synchConductor forKey: @"MKMidi_synchConductor"];
	[aCoder encodeConditionalObject: exceptionPort forKey: @"MKMidi_exceptionPort"];
	[aCoder encodeConditionalObject: alarmPort forKey: @"MKMidi_alarmPort"];
	[aCoder encodeConditionalObject: mtcMidiObj forKey: @"MKMidi_mtcMidiObj"];
	
	[aCoder encodeDouble: localDeltaT forKey: @"MKMidi_localDeltaT"];
	[aCoder encodeDouble: timeOffset forKey: @"MKMidi_timeOffset"];
	[aCoder encodeBool: useInputTimeStamps forKey: @"MKMidi_useInputTimeStamps"];
	[aCoder encodeBool: outputIsTimed forKey: @"MKMidi_outputIsTimed"];
	[aCoder encodeInt: ioMode forKey: @"MKMidi_ioMode"];
	[aCoder encodeInt: deviceStatus forKey: @"MKMidi_deviceStatus"];
	[aCoder encodeBool: isOwner forKey: @"MKMidi_isOwner"];
	[aCoder encodeBool: mergeInput forKey: @"MKMidi_mergeInput"];
	
	[aCoder encodeInt: inputUnit forKey: @"MKMidi_inputUnit"];
	[aCoder encodeInt: outputUnit forKey: @"MKMidi_outputUnit"];
	[aCoder encodeInt: queueSize forKey: @"MKMidi_queueSize"];
	[aCoder encodeDouble: alarmTime forKey: @"MKMidi_alarmTime"];
	[aCoder encodeInt: intAlarmTime forKey: @"MKMidi_intAlarmTime"];
	[aCoder encodeBool: alarmTimeValid forKey: @"MKMidi_alarmTimeValid"];
	[aCoder encodeBool: alarmPending forKey: @"MKMidi_alarmPending"];
	[aCoder encodeInt: systemIgnoreBits forKey: @"MKMidi_ignoreBits"];
    }
    else {
	[aCoder encodeObject: midiDevName];
	[aCoder encodeObject: hostname];
	[aCoder encodeObject: noteSenders];
	[aCoder encodeObject: noteReceivers];

	[aCoder encodeValuesOfObjCTypes: "iiii", &devicePort, &ownerPort, &recvPort, &queuePort];
	[aCoder encodeConditionalObject: conductor];
	[aCoder encodeConditionalObject: synchConductor];
	[aCoder encodeConditionalObject: exceptionPort];
	[aCoder encodeConditionalObject: alarmPort];
	[aCoder encodeConditionalObject: mtcMidiObj];

	[aCoder encodeValuesOfObjCTypes: "ddcccccc", &localDeltaT, &timeOffset, &useInputTimeStamps,
	    &outputIsTimed, &ioMode, &deviceStatus, &isOwner, &mergeInput];
	[aCoder encodeValuesOfObjCTypes: "iidiccI", &outputUnit, &queueSize, &alarmTime,
	    &intAlarmTime, &alarmTimeValid, &alarmPending, &systemIgnoreBits];
    }
    //_MKMidiInStruct *_pIn;                  // TODO perhaps we can get away without archiving
    //_MKMidiOutStruct *_pOut;                // TODO perhaps we can get away without archiving
    
    NSLog(@"encodeWithCoder: queueSize = %d\n", queueSize);	
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    if([aDecoder allowsKeyedCoding]) {
	midiDevName = [aDecoder decodeObjectForKey: @"MKMidi_midiDevName"];
	hostname = [aDecoder decodeObjectForKey: @"MKMidi_hostname"];
	noteSenders = [aDecoder decodeObjectForKey: @"MKMidi_noteSenders"];
	noteReceivers = [aDecoder decodeObjectForKey: @"MKMidi_noteReceivers"];
	
	devicePort = [aDecoder decodeIntForKey: @"MKMidi_devicePort"];
	ownerPort = [aDecoder decodeIntForKey: @"MKMidi_ownerPort"];
	recvPort = [aDecoder decodeIntForKey: @"MKMidi_recvPort"];
	queuePort = [aDecoder decodeIntForKey: @"MKMidi_queuePort"];
	conductor = [aDecoder decodeObjectForKey: @"MKMidi_conductor"];
	synchConductor = [aDecoder decodeObjectForKey: @"MKMidi_synchConductor"];
	exceptionPort = [aDecoder decodeObjectForKey: @"MKMidi_exceptionPort"];
	alarmPort = [aDecoder decodeObjectForKey: @"MKMidi_alarmPort"];
	mtcMidiObj = [aDecoder decodeObjectForKey: @"MKMidi_mtcMidiObj"];
	
	localDeltaT = [aDecoder decodeDoubleForKey: @"MKMidi_localDeltaT"];
	timeOffset = [aDecoder decodeDoubleForKey: @"MKMidi_timeOffset"];
	useInputTimeStamps = [aDecoder decodeBoolForKey: @"MKMidi_useInputTimeStamps"];
	outputIsTimed = [aDecoder decodeBoolForKey: @"MKMidi_outputIsTimed"];
	ioMode = [aDecoder decodeIntForKey: @"MKMidi_ioMode"];
	deviceStatus = [aDecoder decodeIntForKey: @"MKMidi_deviceStatus"];
	isOwner = [aDecoder decodeBoolForKey: @"MKMidi_isOwner"];
	mergeInput = [aDecoder decodeBoolForKey: @"MKMidi_mergeInput"];
	
	inputUnit = [aDecoder decodeIntForKey: @"MKMidi_inputUnit"];
	outputUnit = [aDecoder decodeIntForKey: @"MKMidi_outputUnit"];
	queueSize = [aDecoder decodeIntForKey: @"MKMidi_queueSize"];
	alarmTime = [aDecoder decodeDoubleForKey: @"MKMidi_alarmTime"];
	intAlarmTime = [aDecoder decodeIntForKey: @"MKMidi_intAlarmTime"];
	alarmTimeValid = [aDecoder decodeBoolForKey: @"MKMidi_alarmTimeValid"];
	alarmPending = [aDecoder decodeBoolForKey: @"MKMidi_alarmPending"];
	systemIgnoreBits = [aDecoder decodeIntForKey: @"MKMidi_ignoreBits"];
    }
    else {	
	if ([aDecoder versionForClassName: @"MKMidi"] == 1) {
	    midiDevName = [[aDecoder decodeObject] retain];
	    hostname = [[aDecoder decodeObject] retain];
	    noteSenders = [[aDecoder decodeObject] retain];
	    noteReceivers = [[aDecoder decodeObject] retain];
	    
	    [aDecoder decodeValuesOfObjCTypes: "iiii", &devicePort, &ownerPort, &recvPort, &queuePort];
	    conductor = [[aDecoder decodeObject] retain];
	    synchConductor = [[aDecoder decodeObject] retain];
	    exceptionPort = [[aDecoder decodeObject] retain];
	    alarmPort = [[aDecoder decodeObject] retain];
	    mtcMidiObj = [[aDecoder decodeObject] retain];

	    [aDecoder decodeValuesOfObjCTypes: "ddcccccc", &localDeltaT, &timeOffset, &useInputTimeStamps,
		&outputIsTimed, &ioMode, &deviceStatus, &isOwner, &mergeInput];
	    [aDecoder decodeValuesOfObjCTypes: "iidiccI", &outputUnit, &queueSize, &alarmTime,
		&intAlarmTime, &alarmTimeValid, &alarmPending, &systemIgnoreBits];
	}
    }
    NSLog(@"initWithCoder: queueSize = %d\n", queueSize);
    return self;
}

NSString *midiDriverErrorString(int errorCode)
{
    return [NSString stringWithUTF8String: MKMDErrorString(errorCode)];
}

- (BOOL) unitHasMTC
{
    return (synchConductor && mtcMidiObj == self);
}

// This method searches for any other open MKMidi instances on hostname NOT matching the specified unit.
+ (NSMutableArray *) midisOnHost: (NSString *) midiHostname
	      otherThanInputUnit: (int) midiInputUnit
		    orOutputUnit: (int) midiOutputUnit
{
    MKMidi *midiObj;
    NSMutableArray *midisNotMatching = [NSMutableArray array];
    // This is inefficient, once we can do better compares we should retrieve the objectsForKeys:notFoundMarker:.
    // which has the port as the key
    NSEnumerator *enumerator = [openDrivers objectEnumerator];
    
    while ((midiObj = [enumerator nextObject])) {
        if ([midiObj->hostname isEqualToString: midiHostname] && 
	    ((midiObj->inputUnit != midiInputUnit) || (midiObj->outputUnit != midiOutputUnit)))
            [midisNotMatching addObject: midiObj];
    }
    return midisNotMatching;
}

// Returns YES if we closed the MIDI device correctly
- (BOOL) closeMidiDevice
{
    BOOL somebodyElseHasOwnership = NO;
    NSMutableArray *otherMidis = nil;

    if (!ownerPort)
	return YES;
    otherMidis = [MKMidi midisOnHost: hostname otherThanInputUnit: inputUnit orOutputUnit: outputUnit];
    
    if (INPUTENABLED(ioMode)) {
	if(MKMDReleaseUnit(YES, devicePort, ownerPort, inputUnit, (void *) self) != MKMD_SUCCESS)
	    NSLog(@"Unable to release input unit %d, was not claimed.", inputUnit);
    }
    if (OUTPUTENABLED(ioMode)) {
	if(MKMDReleaseUnit(NO, devicePort, ownerPort, outputUnit, (void *) self) != MKMD_SUCCESS)
	    NSLog(@"Unable to release output unit %d, was not claimed.", outputUnit);
    }
    if ([self unitHasMTC])
        [self tearDownMTC];
    if ([otherMidis count] == 0) 
        somebodyElseHasOwnership = NO;
    else {
	MKMidi *aMidi;
	int i, cnt = [otherMidis count];
	for (i = 0; i < cnt && !somebodyElseHasOwnership; i++) {
	    aMidi = [otherMidis objectAtIndex: i];
	    if (aMidi->ownerPort) 
                somebodyElseHasOwnership = YES;
	}
    }
    if (!somebodyElseHasOwnership) {
	MKMDReleaseOwnership(devicePort, ownerPort);
    } 
    ownerPort = MKMD_PORT_NULL;
    // Release our device port, reset all ports to nil to guard against reuse. Better no output than crashing, well maybe...
    devicePort = MKMD_PORT_NULL;
    recvPort = MKMD_PORT_NULL;
    queuePort = MKMD_PORT_NULL;
    // This is actually a bit too early to remove ourselves from the port table, since we were added during initOnDevice:hostname:.
    // However we can not do this in dealloc since removeObjectForKey: will release the object causing a dealloc infinite loop.
    // This is almost the right place to remove it, since it is now closed and cannot receive further MIDI.
    [openDrivers removeObjectForKey: midiDevName];
    return YES;
}

/* "Opens". If the device represented by devicePortName is already 
   accessed by this task, uses the ownerPort currently accessed.
   Otherwise, if ownerPort is nil, allocates a new
   port. Otherwise, uses ownerPort as specified. 
   To make the device truly public, you can pass the device port as the
   owner port. Returns the MIDI driver MKMDReturn status, MKMD_SUCCESS 
   if the device was successfully opened.
   */
- (MKMDReturn) openMidiDevice
{
    MKMDReturn r;
    NSMutableArray *otherMidis = nil;
    MKMDPort driverDevicePort;

    // We know that midiDevName has already been mapped to a hard device since it is done when this instance is initialised.
    if (INPUTENABLED(ioMode))
	inputUnit = [inputDriverNames indexOfObject: midiDevName];
    if (OUTPUTENABLED(ioMode))
	outputUnit = [outputDriverNames indexOfObject: midiDevName];
    
    driverDevicePort = MKMDGetMIDIDeviceOnHost([hostname UTF8String]);

    if (driverDevicePort == (MKMDPort) NULL) {
        MKErrorCode(MK_machErr, NETNAME_ERROR, @"Unable to find devicePort", @"MIDI Port Server lookup");
        return !MKMD_SUCCESS;
    }
    devicePort = driverDevicePort;
    otherMidis = [MKMidi midisOnHost: hostname otherThanInputUnit: inputUnit orOutputUnit: outputUnit];
    if ([otherMidis count]) {
        int unitIndex;
        int unitCount = [otherMidis count];
	
        for (unitIndex = 0; unitIndex < unitCount; unitIndex++) {
	    MKMidi *aMidi = [otherMidis objectAtIndex: unitIndex];
	    
            /* Should be the first one, but just in case... */
            if (aMidi->ownerPort != MKMD_PORT_NULL) {
                ownerPort = aMidi->ownerPort;
                break;
            }
        }
    }
    if (!ownerPort) {
	/* Tells driver funcs to call: */ 
	// TODO MKMDReplyFunctions recvStruct = { midi_data_reply, my_alarm_reply, my_exception_reply, 0};
	MKMDReplyFunctions recvStruct = { midi_data_reply, NULL, NULL, NULL};
	
        ownerPort++;
	r = MKMDBecomeOwner(devicePort, ownerPort, &recvStruct);
	if (r != MKMD_SUCCESS) {
	    isOwner = NO;
	    MKErrorCode(MK_musicKitErr, UNAVAIL_DRIVER_ERROR);
	    [self closeMidiDevice];
	    return r;
	}
    }
    if (INPUTENABLED(ioMode)) {
	r = MKMDClaimUnit(YES, devicePort, ownerPort, inputUnit, (void *) self);
	if (r != MKMD_SUCCESS) {
	    MKErrorCode(MK_musicKitErr, UNAVAIL_UNIT_ERROR);
	    [self closeMidiDevice];
	    return r;
	}
    }
    if (OUTPUTENABLED(ioMode)) {
	r = MKMDClaimUnit(NO, devicePort, ownerPort, outputUnit, (void *) self);
	if (r != MKMD_SUCCESS) {
	    MKErrorCode(MK_musicKitErr, UNAVAIL_UNIT_ERROR);
	    [self closeMidiDevice];
	    return r;
	}	
    }

    r = MKMDSetClockQuantum(devicePort, ownerPort, _MK_MIDI_QUANTUM);
    if (r != MKMD_SUCCESS) {
	MKErrorCode(MK_musicKitErr, OPEN_ERROR);
	[self closeMidiDevice];
	return r;
    }

    r = MKMDSetClockMode(devicePort, ownerPort, -1, MKMD_CLOCK_MODE_INTERNAL);
    if (r != MKMD_SUCCESS) {
	MKErrorCode(MK_musicKitErr,OPEN_ERROR);
	[self closeMidiDevice];
	return r;
    }

    /* Input */
    if (INPUTENABLED(ioMode)) {
        recvPort++;
    }
    if (OUTPUTENABLED(ioMode)) {
        queuePort++;
	r = MKMDGetAvailableQueueSize(devicePort, ownerPort, outputUnit, &queueSize);
	if (r != MKMD_SUCCESS) {
            MKErrorCode(MK_machErr, OPEN_ERROR, midiDriverErrorString(r), @"MKMDGetAvailableQueueSize");
	    [self closeMidiDevice];
	    return r;
	}
    }
    if ([self unitHasMTC])
	[self setUpMTC];
    return MKMD_SUCCESS;
}    

// At the moment this is really just a stub for determining time from a host
- (void) getTimeInfoFromHost: (NSString *) timeInfoHostname
{
    static NSMutableDictionary *timeInfoTable = nil;
    NSData *timeVarsEncoded;

    if (!timeInfoTable) /* Mapping from hostname to tvs pointer */
        timeInfoTable = [[NSMutableDictionary dictionary] retain];
    if ((timeVarsEncoded = [timeInfoTable objectForKey: timeInfoHostname]) != nil) {
        // TODO Assign ivars from [timeVarsEncoded bytes] or somesuch if timeVarsEncoded changes to be an object.
    }
    else { // initialise MTC ivars
        synchConductor = nil;                // If non-nil, time mode is MTC Synch
        exceptionPort =  nil;                // Exception port.  Only one unit per device may have one
        alarmPort =  nil;                    // Alarm port.  Only one unit per device may have one
        mtcMidiObj = nil;                    // No unit is receiving MTC.
        alarmTime = 0.0;
        intAlarmTime = 0;
        alarmTimeValid = NO;
        alarmPending = NO;
        // TODO assign MTC ivars into NSData or object and use the following to save it.
        // [timeInfoTable setObject: [NSData dataWithBytes: ?] forKey: hostname];
    }
}

static void waitForRoom(MKMidi *self, int elements, int timeOut)
{
    MKMDReplyFunctions recvStruct = {0};
    MKMDReturn r = MKMDRequestQueueNotification(self->devicePort, self->ownerPort, self->outputUnit, self->queuePort, elements);

    if (r != MKMD_SUCCESS)
        MKErrorCode(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"waitForRoom queue notification request");
    r = MKMDAwaitReply(self->queuePort, &recvStruct, timeOut); // THIS BLOCKS!
    if (r != MKMD_SUCCESS) 
	MKErrorCode(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"waitForRoom MKMDAwaitReply");
}

/* Wait until Midi is done and then return */
static void awaitMidiOutDone(MKMidi *self, int timeOut)
{
    // NSLog(@"waiting for room of %d, with timeOut = %d\n", self->queueSize, timeOut);
    waitForRoom(self, self->queueSize, timeOut);
}

- (int) stopMidiClock
{
    MKMDReturn r;
    
    if (synchConductor) {
	r = MKMDRequestExceptions(devicePort, ownerPort, MKMD_PORT_NULL);
	if (r != MKMD_SUCCESS)
	    MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"stopMidiClock MKMDRequestExceptions");
	r = MKMDSetClockMode(devicePort, ownerPort, inputUnit, MKMD_CLOCK_MODE_INTERNAL);
	if (r != MKMD_SUCCESS)
	    MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"stopMidiClock MKMDSetClockMode");
        r = MKMDRequestAlarm(devicePort, ownerPort, MKMD_PORT_NULL, 0);
	if (r != MKMD_SUCCESS)
	    MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"stopMidiClock MKMDRequestAlarm");
	alarmPending = NO;
	return r;
    }
    r = MKMDStopClock(devicePort, ownerPort);
    if (r != MKMD_SUCCESS)
	MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"stopMidiClock MKMDStopClock");
    return r;
}

static int resumeMidiClock(MKMidi *self)
{
    MKMDReturn r;
    
    if (self->synchConductor) {
	r = MKMDRequestExceptions(self->devicePort, self->ownerPort, (MKMDReplyPort) [self->exceptionPort machPort]);
	if (r != MKMD_SUCCESS)
	    MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"resumeMidiClock MKMDRequestExceptions");
	r = MKMDSetClockMode(self->devicePort, self->ownerPort, self->inputUnit, MKMD_CLOCK_MODE_MTC_SYNC);
	if (r != MKMD_SUCCESS)
	    MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"resumeMidiClock MKMDSetClockMode");
	if (self->alarmTimeValid) {
	    r = MKMDRequestAlarm(self->devicePort, self->ownerPort, (MKMDReplyPort) [self->alarmPort machPort], self->alarmTime);
	    self->alarmPending = YES;
	    if (r != MKMD_SUCCESS)
		MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"resumeMidiClock MKMDRequestAlarm");
	}
	return r;
    }
    r = MKMDStartClock(self->devicePort, self->ownerPort);
    if (r != MKMD_SUCCESS)
	MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"resumeMidiClock MKMDStartClock");
    return r;
}

static int resetAndStopMidiClock(MKMidi *self)
{
    MKMDReturn r;
    
    [self stopMidiClock];
    r = MKMDSetClockTime(self->devicePort, self->ownerPort, 0);
    if (r != MKMD_SUCCESS)
      MKErrorCode(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"resetAndStopMidiClock");
    return r;
}

/* Get rid of enqueued outgoing midi messages */
static int emptyMidi(MKMidi *self)
{
    MKMDReturn r;
    r = MKMDClearQueue(self->devicePort, self->ownerPort, self->outputUnit);
    if (r != MKMD_SUCCESS)
        MKErrorCode(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"emptyMidi");
    // NSLog(@"emptying the enqued MIDI messages\n");
    return r;
}

/* Tell driver to ignore particular incoming MIDI system messages */
static int setMidiSysIgnore(MKMidi *self,unsigned bits)
{
#if FCC_DID_NOT_APPROVE_DRIVER_CHANGE
    int r = MKMDSetSystemIgnores(self->devicePort, self->ownerPort, self->inputUnit, bits);
#else 
    int r = 0;
    r |= MKMDFilterMessage(devicePort, self->ownerPort, self->inputUnit, MIDI_CLOCK, bits & IGNORE_CLOCK);
    r |= MKMDFilterMessage(devicePort, self->ownerPort, self->inputUnit, MIDI_START, bits & IGNORE_START);
    r |= MKMDFilterMessage(devicePort, self->ownerPort, self->inputUnit, MIDI_CONTINUE, bits & IGNORE_CONTINUE);
    r |= MKMDFilterMessage(devicePort, self->ownerPort, self->inputUnit, MIDI_STOP, bits & IGNORE_STOP);
    r |= MKMDFilterMessage(devicePort, self->ownerPort, self->inputUnit, MIDI_ACTIVE, bits & IGNORE_ACTIVE);
    r |= MKMDFilterMessage(devicePort, self->ownerPort, self->inputUnit, MIDI_RESET, bits & IGNORE_RESET);
#endif
    if (r != MKMD_SUCCESS) 
	MKErrorCode(MK_machErr, INPUT_ERROR, midiDriverErrorString(r), @"");
    return r;
}


/* Low-level output routines */

/* We currently use MIDI "raw" mode. Perhaps cooked mode would be more efficient? */

#define MIDIBUFSIZE MKMD_MAX_EVENT

static MKMDRawEvent midiBuf[MIDIBUFSIZE];
static MKMDRawEvent *bufPtr = midiBuf;

static void putTimedByte(unsigned curTime, unsigned char aByte)
    /* output a MIDI byte */
{
    bufPtr->time = curTime;
    bufPtr->byte = aByte;
    bufPtr++;
}

static void sendBufferedData(struct __MKMidiOutStruct *ptr)
    /* Send any buffered bytes and reset pointer to start of buffer */
{
    MKMDReturn r;
    MKMidi *midiObj;
    int nBytes = bufPtr - midiBuf;
    
    if (nBytes == 0)
	return;
    midiObj = ((MKMidi *) ptr->_owner);
    for (; ;) {
	r = MKMDSendData(midiObj->devicePort, midiObj->ownerPort, midiObj->outputUnit, midiBuf, nBytes);
	if (r == MKMD_ERROR_QUEUE_FULL) 
	    waitForRoom(midiObj, nBytes, MKMD_NO_TIMEOUT);
	else
            break;
    }
    if (r != MKMD_SUCCESS) 
	MKErrorCode(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"sendBufferedData");
    bufPtr = midiBuf;
}

/* Same as putMidi, but checks for full buffer */
static void putTimedByteWithCheck(struct __MKMidiOutStruct *ptr, unsigned curTime, unsigned char aByte)
{
    if (midiBuf + MIDIBUFSIZE == bufPtr) 
        sendBufferedData(ptr);
    putTimedByte(curTime, aByte);
}

/* Adds a complete MIDI message to the output buffer */
static void putMidi(struct __MKMidiOutStruct *ptr)
{
    unsigned int curTime = .5 + ptr->_timeTag * _MK_MIDI_QUANTUM;
    
    if ((midiBuf + MIDIBUFSIZE - bufPtr) < ptr->_outBytes)
	sendBufferedData(ptr);
    putTimedByte(curTime, ptr->_bytes[0]);
    if (ptr->_outBytes >= 2)
	putTimedByte(curTime, ptr->_bytes[1]);
    if (ptr->_outBytes == 3)
	putTimedByte(curTime, ptr->_bytes[2]);
}

/* sysExStr is a string. The string consists of system exclusive bytes
 * separated by any non-digit delimiter. The musickit uses the 
 * delimiter ','. E.g. "f8,13,f7".  This function converts each ASCII
 * byte into the corresponding number and sends it to serial port.
 * Note that if you want to give each sysex byte a different
 * delay, you need to do a separate call to this function.
 * On a higher level, this means that you need to put each
 * byte in a different MKNote object. 
 * The string may but need not begin with MIDI_SYSEXCL and end with MIDI_EOX. 
*/
static void putSysExcl(struct __MKMidiOutStruct *ptr, NSString *sysExclString)
{
    /* note we cast to char* not const char* because although we're not
     * going to alter the contents of the string, we are going to need to
     * alter the *sysExclStr pointer (in _MKGetSysExByte).
     */
    const char *sysExclStr = [sysExclString UTF8String];
    unsigned char c;
    unsigned int curTime = .5 + ptr->_timeTag * _MK_MIDI_QUANTUM;
    
    sendBufferedData(ptr);
    c = _MKGetSysExByte(&sysExclStr);
    if (c == MIDI_EOX)
        return;
    if (c != MIDI_SYSEXCL) 
        putTimedByteWithCheck(ptr, curTime, MIDI_SYSEXCL);
    putTimedByteWithCheck(ptr, curTime, c);
    while (*sysExclStr) {
        c = _MKGetSysExByte(&sysExclStr);
	putTimedByteWithCheck(ptr, curTime, c);
        // Add an inter-byte delay of 300mS to avoid overflow problems in slow synthesisers.
        // TODO this should actually be a note parameter: MK_interByteDelay
        curTime += 300 * _MK_MIDI_QUANTUM;
//        curTime += 300;
    }
    if (c != MIDI_EOX) 
        putTimedByteWithCheck(ptr, curTime, MIDI_EOX);  /* Terminate it properly */
}

/* Midi parsing. */

/* Currently we use raw input mode. That means we have to parse the MIDI
   ourselves. Perhaps it'd be more efficient to let the driver do the
   parsing (i.e. use the driver's "cooked" mode). But for 1.0, the driver 
   was finished so late, I was afraid to trust its hardly-debugged code. -
   DAJ */

static unsigned char parseMidiStatusByte(unsigned char statusByte, _MKMidiInStruct *ptr)
    /* This is called when a status byte is found. Returns YES if the status
       byte is a system real time or system exclusive message. */
{
    switch (MIDI_OP(statusByte)) {
      case MIDI_PROGRAM: 
      case MIDI_CHANPRES:
	ptr->_statusByte = ptr->_runningStatus = statusByte;
	ptr->_dataBytes = 1;
	return 0;
      case MIDI_NOTEON:
      case MIDI_NOTEOFF:
      case MIDI_POLYPRES:
      case MIDI_CONTROL:
      case MIDI_PITCH:
	ptr->_statusByte = ptr->_runningStatus = statusByte;
	ptr->_dataBytes = 2;
	ptr->_firstDataByteSeen = NO;
	return 0;
      case MIDI_SYSTEM:
	if (!(statusByte & MIDI_SYSRTBIT)) {
	    ptr->_runningStatus = 0;
	    ptr->_statusByte = statusByte;
	    switch (statusByte) {
	      case MIDI_SONGPOS:
		ptr->_dataBytes = 2;
		ptr->_firstDataByteSeen = NO;
		return 0;
	      case MIDI_TIMECODEQUARTER:
	      case MIDI_SONGSEL:
		ptr->_dataBytes = 1;
		return 0;
	      case MIDI_SYSEXCL:
		ptr->_dataBytes = MSG_LEN_IS_VARIABLE;
		return MIDI_SYSEXCL;
	      case MIDI_TUNEREQ:         
		ptr->_dataBytes = 0;
		return MIDI_TUNEREQ;
	      case MIDI_EOX: {          
		  BOOL isInSysEx = (ptr->_dataBytes == MSG_LEN_IS_VARIABLE);
		  ptr->_dataBytes = 0;
		  return (isInSysEx) ? MIDI_SYSEXCL : 0;
	      }
	    }
	}
	else switch (statusByte) {
	  case MIDI_CLOCK:            /* System real time messages. */
	  case MIDI_START:
	  case MIDI_STOP:
	  case MIDI_ACTIVE:
	  case MIDI_RESET:
	  case MIDI_CONTINUE:
	    return statusByte; /* Doesn't affect running status. */
	                       /* Also doesn't affect _dataBytes. This
				  is because real-time messages may occur
				  anywhere, even in a system exclusive 
				  message. */
	  default:             /* Omit unrecognized status. */
	    return 0;         
	}                      
      default:                 /* Garbage */
	ptr->_dataBytes = 0;
	return 0;             
    }   
}

static unsigned char parseMidiByte(unsigned char aByte, _MKMidiInStruct *ptr)
    /* Takes an incoming byte and parses it */
{
    if (MIDI_STATUSBIT & aByte)  
      return parseMidiStatusByte(aByte,ptr);
    switch (ptr->_dataBytes) {
      case 0:                      /* Running status or garbage */
	if (!ptr->_runningStatus)  /* Garbage */
	  return 0;
	parseMidiStatusByte(ptr->_runningStatus,ptr);
	return parseMidiByte(aByte,ptr);
      case 1:                      /* One-argument midi message. */
	ptr->_dataByte1 = aByte;
	ptr->_dataBytes = 0;  /* Reset */
	return ptr->_statusByte;
      case 2:                      /* Two-argument midi message. */
	if (ptr->_firstDataByteSeen) {
	    ptr->_dataByte2 = aByte;
	    ptr->_dataBytes = 0;
	    return ptr->_statusByte;
	}
	ptr->_dataByte1 = aByte;
	ptr->_firstDataByteSeen = YES;
	return 0;
      case MSG_LEN_IS_VARIABLE:
	return MIDI_SYSEXCL;
      default:
	return 0;
    }
}

static id handleSysExclbyte(_MKMidiInStruct *ptr,unsigned char midiByte)
    /* Parsing routine for incoming system exclusive */
    /* We don't return an autoreleased object - just the raw
     * MKNote because there's only one place where this is called
     * and we know we don't need the autorelease
     */
{
    if (midiByte == MIDI_SYSEXCL) {  /* It's a new one. */
	if (!ptr->_sysExBuf) {
	    _MK_MALLOC(ptr->_sysExBuf,unsigned char,DEFAULT_SYSEX_MSGLEN);
	    ptr->_sysExSize = DEFAULT_SYSEX_MSGLEN;
	} 
	ptr->_endOfSysExBuf = ptr->_sysExBuf + ptr->_sysExSize;
	ptr->_sysExP = ptr->_sysExBuf;
	*ptr->_sysExP++ = midiByte;
    }
    else {
	if (ptr->_sysExP >= ptr->_endOfSysExBuf) { 
	    int offset = ptr->_sysExP - ptr->_sysExBuf; 
	    ptr->_sysExSize *= 2;
	    _MK_REALLOC(ptr->_sysExBuf,unsigned char,ptr->_sysExSize);
	    ptr->_endOfSysExBuf = ptr->_sysExBuf + ptr->_sysExSize;
	    ptr->_sysExP = ptr->_sysExBuf + offset;
	}
	*ptr->_sysExP++ = midiByte;
    }
    if (midiByte == MIDI_EOX) {
	unsigned char *p;
	NSString *sysExString;

	[ptr->_note release]; /* Free old note. */ 
	ptr->_note = [MKGetNoteClass() new];
	p = ptr->_sysExBuf;
        sysExString = [NSString stringWithFormat: @"%-2x", (unsigned) *p++]; /* First byte */
	while (p < ptr->_sysExP) {
            sysExString = [sysExString stringByAppendingFormat: @",%-2x", (unsigned) *p++];
	}
	[ptr->_note setPar: MK_sysExclusive toString: sysExString];
	/* We might want to use a special setPar: that doesn't turn the
	   thing into an NXAtom.  This would involve introducing a
	   noCopy type into Note.m.  FIXME */
	ptr->chan = _MK_MIDISYS; 	
	return (id)ptr->_note;
    }
    return nil; /* We're not done yet. */
} 

static void sendIncomingNote(short chan, MKNote *aNote, MKMidi *sendingMidi, int quanta)
{
    if (aNote) {
	MKConductor *synchCond = sendingMidi->synchConductor;
	double t = (((double) quanta) * _MK_MIDI_QUANTUM_PERIOD + sendingMidi->timeOffset);
	
	if (MKGetDeltaTMode() == MK_DELTAT_SCHEDULER_ADVANCE) 
	    t += MKGetDeltaT();
	if (synchCond)
	    t -= mtcTimeOffset;
	[aNote setTimeTag: t];
        if (sendingMidi->useInputTimeStamps) 
	    if (synchCond)
		[synchCond _setMTCTime: (double) t];
	    else 
		_MKAdjustTime(t); /* Use input time stamp time */
	else 
	    [_MKClassConductor() adjustTime]; 
	if (sendingMidi->mergeInput) { /* Send all on one MKNoteSender? */
	    MKSetNoteParToInt(aNote, MK_midiChan, chan);
            [[sendingMidi->noteSenders objectAtIndex: 0] sendNote: aNote];
	}
        else {
            [[sendingMidi->noteSenders objectAtIndex: chan] sendNote: aNote];
        }
	[_MKClassOrchestra() flushTimedMessages]; /* Off to the DSP */
    }
}

/* We use a static here to allow us to break out of midi_data_reply.  Note that
 * midi_data_reply can never be called recursively so there's no danger in doing this. 
 */
static int incomingDataCount = 0; 

// midi_data_reply manages the incoming MIDI events. It is called from MKMDHandleReply.
// It may be called multiple times successively with events from the MKMDHandleReply mechanism.
static void midi_data_reply(void *receivingMidiPtr, short unit, MKMDRawEvent *events, unsigned int eventCount) {
    _MKMidiInStruct *ptr;
    MKNote *aNote;
    unsigned char statusByte;
    MKMidi *receivingMidi = (MKMidi *) receivingMidiPtr;
    // since the callback is coming in from the cold harsh world of C, not cozy ObjC:
    NSAutoreleasePool *handlerPool = [[NSAutoreleasePool alloc] init]; 

    // check we assigned this in handleMachMessage and it survives the driver.
    if(receivingMidi) {
	ptr = MIDIINPTR(receivingMidi);
	// NSLog(@"receivingMIDI %@ events %p ptr = %p\n", receivingMidi, events, ptr);
	if(receivingMidi->displayReceivedMIDI)
	    NSLog(@"%@ received %d bytes: first is %02X\n", receivingMidi, eventCount, events->byte);
	for (incomingDataCount = eventCount; incomingDataCount--; events++) {
	    if ((statusByte = parseMidiByte(events->byte, ptr))) {
		if (statusByte == MIDI_SYSEXCL)
		    aNote = handleSysExclbyte(ptr, events->byte); /* not retained or autoreleased */
		else
		    aNote = _MKMidiToMusicKit(ptr, statusByte); /* autoreleased */
		if (aNote) {
		    sendIncomingNote(ptr->chan, aNote, receivingMidi, events->time);
		    /* sending the MKNote can have unknown side-effects, since the
		     * user defines the behavior here.  For example, the MKMidi obj 
		     * could be aborted or re-opened. It could even be freed!
		     * So when we abort, we clear incomingDataCount.  This 
		     * guarantees that we won't be left in a bad state */
		}
	    }
	}
    }
    else {
	MKErrorCode(MK_musicKitErr, @"Internal error, receiving MKMidi has not been assigned");
    }
    [handlerPool release];
}

/*sb: added the following method to handle mach messages. This replaces the earlier function
 * because instead of DPSAddPort specifying a function,
 * DPSAddPort() replaced with:
 * [[NSPort portWithMachPort:] retain]
 * [NSPort setDelegate:]
 * [NSRunLoop addPort:forMode:]
 *
 * The delegate has to repond to selector -handleMachMessage or -handlePortMessage
 */

- (void) handleMachMessage: (void *) machMessage
{
    msg_header_t *msg = (msg_header_t *) machMessage;
    NSString *errorMessage;
    MKMDReturn r;
    /* Tells driver funcs to call: */ 
    // MKMDReplyFunctions recvStruct = { midi_data_reply, my_alarm_reply, my_exception_reply, 0};
    MKMDReplyFunctions recvStruct = { midi_data_reply, 0, 0, 0};

    // determine what the port is that called this method, then set the appropriate my_*_reply function
    // and error message.
    // if the error is from midiAlarm or Exception, CLOCK_ERROR rather than INPUT_ERROR should be used.
    errorMessage = INPUT_ERROR;

    // Eventually MKMDHandleReply should be unnecessary, when we receive the MIDI data direct into handlePortMessage
    // Then we can merge this method and midi_data_reply into a single handlePortMessage. 
    // TODO we should indicate which MKMidi instance we are talking to by passing in self instead of msg.
    r = MKMDHandleReply(msg, &recvStruct);        /* This gets data */
    if (r != MKMD_SUCCESS) {
      MKErrorCode(MK_machErr, errorMessage, midiDriverErrorString(r), @"midiIn");
    }
}

/* Input configuration */

- setUseInputTimeStamps: (BOOL) yesOrNo
{
    if (deviceStatus != MK_devClosed)
      return nil;
    useInputTimeStamps = yesOrNo;
    return self;
}

- (BOOL) useInputTimeStamps
{
    return useInputTimeStamps;
}

 
static unsigned ignoreBit(unsigned param)
{
    switch (param) {
      case MK_sysActiveSensing:
	return IGNORE_ACTIVE;
      case MK_sysClock:
	return IGNORE_CLOCK;
      case MK_sysStart:
	return IGNORE_START;
      case MK_sysContinue:
	return IGNORE_CONTINUE;
      case MK_sysStop:
	return IGNORE_STOP;
      default:
	break;
    }
    return 0;
}

- ignoreSys: (MKMidiParVal) param
{
    systemIgnoreBits |= ignoreBit(param);
    if (deviceStatus != MK_devClosed)
	setMidiSysIgnore(self, systemIgnoreBits);
    return self;
} 

- acceptSys: (MKMidiParVal) param 
{
    systemIgnoreBits &= ~(ignoreBit(param));
    if (deviceStatus != MK_devClosed)
	setMidiSysIgnore(self, systemIgnoreBits);
    return self;
}

/* MKPerformer-like methods. */

- (MKConductor *) conductor
{
    return conductor ? conductor : (MKConductor *) [_MKClassConductor() clockConductor];
}

- setConductor: (MKConductor *) aConductor
{
    conductor = aConductor;
    return self;
}

/* Creation */

/* This mechanism is more general than we need, because the rest of this
   object currently assumes that there's only one MIDI driver called 
   MK_NAME.  However, in case we ever support others, I want to support
   the general API.  And since this code was already written for the DSP
   case, I thought I'd just grab it from there.
   LMS: The day has arrived where we need all of David's functionality
   with Win32 named ports, MacOS X CoreMIDI USB devices etc.
 */

// This retrieves MIDI drivers via MKPerformSndMIDI framework based drivers.
// Return YES if able to retrieve lists of names of input, output and bidirectional MIDI drivers.
// A driver is considered here to be a named service providing 16 channels of MIDI in or out.
// Bidirectional drivers are determined to be those drivers which are the intersection of the input and 
// output lists. If the MKPerformSndMIDI framework for a given platform does not distinguish between
// input and output drivers (for example the original NeXT hardware assumes bidirectionality of all drivers
// returned), all three driver name lists will be the same.
// Returns NO if there was no MIDI driver found. 
+ (BOOL) getAllAvailableMidiDevices
{
    int systemInputDriverIndex = 0;
    int systemOutputDriverIndex = 0;
    const char **systemInputDriverNames;
    const char **systemOutputDriverNames;

    [inputDriverNames release];
    inputDriverNames = [[NSMutableArray array] retain];
    // Use the cross-platform means to obtain the available input drivers.
    systemInputDriverNames = MKMDGetAvailableDrivers(YES, &systemDefaultDriverNum);
    for(systemInputDriverIndex = 0; systemInputDriverNames[systemInputDriverIndex] != NULL; systemInputDriverIndex++) {
        [inputDriverNames addObject: [NSString stringWithUTF8String: systemInputDriverNames[systemInputDriverIndex]]];
	// NSLog(@"getAllAvailableMidiDevices input[%d] = %s\n", systemInputDriverIndex, systemInputDriverNames[systemInputDriverIndex]);
    }
    
    [outputDriverNames release];
    outputDriverNames = [[NSMutableArray array] retain];
    // Use the cross-platform means to obtain the available output drivers.
    systemOutputDriverNames = MKMDGetAvailableDrivers(NO, &systemDefaultDriverNum);
    for(systemOutputDriverIndex = 0; systemOutputDriverNames[systemOutputDriverIndex] != NULL; systemOutputDriverIndex++) {
        [outputDriverNames addObject: [NSString stringWithUTF8String: systemOutputDriverNames[systemOutputDriverIndex]]];
	// NSLog(@"getAllAvailableMidiDevices output[%d] = %s\n", systemOutputDriverIndex, systemOutputDriverNames[systemOutputDriverIndex]);
    }
    
    [bidirectionalDriverNames release];
    bidirectionalDriverNames = [NSMutableArray array];
    
    {
	int inputDriverIndex = 0;
	int outputDriverIndex = 0;
	
	// Ideally we should be eliminating chosen names from a copy of the outputDriverNames list to reduce the
	// search from O(n^2), but the lists are usually very small n typically < 8. 
	for(inputDriverIndex = 0; inputDriverIndex < [inputDriverNames count]; inputDriverIndex++) {
	    for(outputDriverIndex = 0; outputDriverIndex < [outputDriverNames count]; outputDriverIndex++) {
		NSString *inputDriverName = [inputDriverNames objectAtIndex: inputDriverIndex];
		
		if([inputDriverName isEqualToString: [outputDriverNames objectAtIndex: outputDriverIndex]]) {
		    [bidirectionalDriverNames addObject: inputDriverName];
		}
	    }
	}
    }
    
    if([bidirectionalDriverNames count] == 0) {
        bidirectionalDriverNames = nil; /* ensure we don't have stale pointers around */
        return NO;
    }
    // NSLog(@"input drivers %@ output drivers %@ bidirectional drivers %@\n", inputDriverNames, outputDriverNames, bidirectionalDriverNames);
    [bidirectionalDriverNames retain];
    // Return YES if there was at least one driver.
    return YES;
}

/* Assumes deviceName is valid string. Returns NO if no final number found or if 
* entire string is one number. Otherwise, returns number in unitNum and YES. */
static BOOL isSoftDevice(NSString *deviceName, int *unitNum)
{
    NSScanner *scanner = [NSScanner scannerWithString: deviceName];
    BOOL gotInt;
    
    [scanner scanUpToCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet] intoString: NULL]; 
    gotInt = [scanner scanInt: unitNum];
    if(!gotInt || ![scanner isAtEnd] || [scanner scanLocation] == 0) {
	*unitNum = NO_UNIT;
        return NO;
    }
    else {
        return [deviceName hasPrefix: @"midi"];
    }
}

/* Maps a name of the form "midi0" to a name of the form "Mididriver2".
 * See above long explanation.
 */
+ (NSString *) mapSoftNameToDriverName: (NSString *) devName
{
    NSString *midiNumStrArr;
    unsigned int deviceIndex;
    NSString *defaultsValue;
    int deviceNumber = 0;
    BOOL isSoft;
    NSMutableArray *unionOfDrivers = [NSMutableArray arrayWithCapacity: [inputDriverNames count] + [outputDriverNames count]];

    // assigns the separate lists of driver names for input, output and bidirectional devices.
    if(![[self class] getAllAvailableMidiDevices])
        return nil;
    if(devName == nil || [devName length] == 0)
	return nil;
    // devName can be of the soft form "midi0", or the hard driver name "Mididriver0" or "SB Live! MIDI Out 1"
    if (isSoftDevice(devName, &deviceNumber)) {
        midiNumStrArr = [NSString stringWithFormat: @"MKMIDI%d", deviceNumber];

        // The owner will be whatever application links against this framework. 
        // This is what we want to allow for different applications to use different MIDI
        // devices if necessary.
        defaultsValue = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey: midiNumStrArr];
	if ([defaultsValue length]) {
            isSoft = isSoftDevice(defaultsValue, &deviceNumber);
	}
	else if (deviceNumber == 0) { 
            // Use the system default MIDI driver for midi0, not necessarily the first entry.
            // TODO this should probably be changed to allow "midiDefault" as a device name,
            // or consign midi0 to be the default, midi1 as [midiDriverNames objectAtIndex: 0], etc.
            return [bidirectionalDriverNames objectAtIndex: systemDefaultDriverNum];
	}
	return [bidirectionalDriverNames objectAtIndex: deviceNumber];
    }
    // Here we assume if we didn't have a soft device name, we are referring to a described device.
    // Ensure the driver was on the legitimate list, which we form by a redundant union of input and output devices.
    // Note we don't check if the direction is being used correctly.
    [unionOfDrivers addObjectsFromArray: inputDriverNames];
    [unionOfDrivers addObjectsFromArray: outputDriverNames];
    for (deviceIndex = 0; deviceIndex < [unionOfDrivers count]; deviceIndex++) {
        if ([devName isEqualToString: [unionOfDrivers objectAtIndex: deviceIndex]]) {
	    return devName;
	}
    }
    return nil;
}

// Returns autoreleased copies of all available input driver names as an NSArray
+ (NSArray *) getDriverNamesForInput
{
    return [[self class] getAllAvailableMidiDevices] ? [[inputDriverNames copy] autorelease] : nil;
}

// Returns autoreleased copies of all available output driver names as an NSArray
+ (NSArray *) getDriverNamesForOutput
{
    return [[self class] getAllAvailableMidiDevices] ? [[outputDriverNames copy] autorelease] : nil;
}

// Just return the bidirectional drivers for applications which only want those drivers (ports) which are both
// input and output.
+ (NSArray *) getDriverNames
{
    return [[self class] getAllAvailableMidiDevices] ? [[bidirectionalDriverNames copy] autorelease] : nil;
}

- (NSString *) driverName 
{
    return [[midiDevName copy] autorelease];
}

- (NSString *) description
{
    NSString *hostnameDisplay = [hostname length] ? [NSString stringWithFormat: @"host %@", hostname] : @"local host";
    
    return [NSString stringWithFormat: @"%@ %s %@, unit %d, on %@", [super description],
      ioMode == MKMidiInputOnly ? "Input from" : ioMode == MKMidiOutputOnly ? "Output to" : "I/O from/to",
	midiDevName, ioMode == MKMidiInputOnly ? inputUnit : outputUnit, hostnameDisplay];
}

// Here we initialize our class variables.
+ (void) initialize
{
    NSDictionary *MKMIDIDefaults;

    if (self != [MKMidi class])
        return;

    openDrivers = [[NSMutableDictionary dictionary] retain];
    MKMIDIDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
        @"", @"MKMIDI0",
        @"", @"MKMIDI1",
        @"", @"MKMIDI2",
        @"", @"MKMIDI3",
        @"", @"MKMIDI4",
        @"", @"MKMIDI5",
        @"", @"MKMIDI6",
        @"", @"MKMIDI7",
        @"", @"MKMIDI8",
        @"", @"MKMIDI9",
        @"", @"MKMIDI10",
        @"", @"MKMIDI11",
        @"", @"MKMIDI12",
        @"", @"MKMIDI13",
        @"", @"MKMIDI14",
        @"", @"MKMIDI15",
       NULL, NULL];
    // insert these in the temporary defaults that are searched last.
    [[NSUserDefaults standardUserDefaults] registerDefaults: MKMIDIDefaults];  
}

// This is where all the initialisation is performed.
- initOnDevice: (NSString *) devName hostName: (NSString *) hostName
{
    self = [super init];
    if(self != nil) {
	MKMidi *obj;
	NSString *hostAndDevName;
	int notePortIndex;
	NSString *driverName = [[self class] mapSoftNameToDriverName: devName];
	
	if (driverName == nil)
	    return nil;
	devName = driverName;
#if !m68k
	hostName = @""; /* Only on local host, see extensive comment above */
#endif
	hostAndDevName = [hostName stringByAppendingString: devName];
	if ((obj = [openDrivers objectForKey: hostAndDevName]) == nil) {         // Doesn't already exist
	    [self getTimeInfoFromHost: hostName];
	    [openDrivers setObject: self forKey: hostAndDevName]; 
	}
	// even if the device is in the openDrivers, we still need to set the device and host name
	hostname = [hostName retain];
	midiDevName = [devName retain];
	
	if (noteSenders != nil) /* Already initialized */
	    return nil;
	outputIsTimed = YES;               /* Default is outputIsTimed */
	noteSenders = [NSMutableArray arrayWithCapacity: _MK_MIDINOTEPORTS];
	[noteSenders retain];
	noteReceivers = [NSMutableArray arrayWithCapacity: _MK_MIDINOTEPORTS];
	[noteReceivers retain];
	for (notePortIndex = 0; notePortIndex < _MK_MIDINOTEPORTS; notePortIndex++) {
	    MKNoteSender *aNoteSender = [MKNoteSender new];
	    MKNoteReceiver *aNoteReceiver = [MKNoteReceiver new];
	    
	    [noteReceivers addObject: aNoteReceiver];
	    [aNoteReceiver _setOwner: self];
	    [aNoteReceiver _setData: [NSNumber numberWithInt: notePortIndex]]; // Encode the note channel.

	    [noteSenders addObject: aNoteSender];
	    [aNoteSender _setPerformer: self];
	    [aNoteReceiver release];
	    [aNoteSender release]; /*sb: retains are held in arrays */
	}
	useInputTimeStamps = YES;
	timeOffset = 0;
	systemIgnoreBits = (IGNORE_ACTIVE |
			    IGNORE_CLOCK |
			    IGNORE_START |
			    IGNORE_CONTINUE |
			    IGNORE_STOP);
	deviceStatus = MK_devClosed;
	// TODO Maybe we don't want this here, in case we ever want to use MKMidi without MKNotes.
	_MKCheckInit(); 
	_MKClassOrchestra(); /* Force find-class here */
	ioMode = MKMidiInputOutput;
	displayReceivedMIDI = [[NSUserDefaults standardUserDefaults] boolForKey: @"MKDisplayReceivedMIDI"];
    }
    return self;
}

- initOnDevice: (NSString *) devName
{
    return [self initOnDevice: devName hostName: @""];
}

- init
{
    return [self initOnDevice: DEFAULT_SOFT_NAME];
}

+ midiOnDevice: (NSString *) devName host: (NSString *) hostName
{
    return [[[MKMidi alloc] initOnDevice: devName hostName: hostName] autorelease];
}

+ midiOnDevice: (NSString *) devName
{
    return [[[MKMidi alloc] initOnDevice: devName] autorelease];
}

+ midi
{
    return [self midiOnDevice: DEFAULT_SOFT_NAME];
}

- copyWithZone: (NSZone *) zone
  /* Overridden to return self. */
{
    return self;
}

/* Overridden to return self. */
- copy
{
    return self;
}

/* Aborts and frees the receiver. */
- (void) dealloc
{    
    [self abort];
    if ([self unitHasMTC]) 
        [synchConductor _setMTCSynch: nil];
    [self _setSynchConductor: nil];
    // Debugging:
#if 0
    NSLog(@"disconnecting noteReceivers %@\n", noteReceivers);
    id firstNoteReceiver = [noteReceivers objectAtIndex: 0];
    NSLog(@"retain count of first noteReceiver %p is %d\n", firstNoteReceiver, [firstNoteReceiver retainCount]);
#endif
    [noteReceivers makeObjectsPerformSelector: @selector(disconnect)];
    
#if 0
    NSLog(@"noteSenders remaining after disconnecting noteReceivers %@\n", noteSenders);
    MKNoteSender *firstNoteSender = [noteSenders objectAtIndex: 0];
    id firstNoteSendersReceiver = [firstNoteSender->noteReceivers objectAtIndex: 0];
    NSLog(@"retain count of first firstNoteSendersReceiver %@ is %d\n", firstNoteSendersReceiver, [firstNoteSendersReceiver retainCount]);
#endif
    [noteSenders makeObjectsPerformSelector: @selector(disconnectAllReceivers)];
    
    // Now we can release in the usual fashion.
    // NSLog(@"releasing noteReceivers and noteSenders\n");
    [noteReceivers release];
    noteReceivers = nil;
    [noteSenders release];
    noteSenders = nil;
    [super dealloc];
}
/* Control of device */

/* Returns MKDeviceStatus of receiver. */
- (MKDeviceStatus) deviceStatus
{
    return deviceStatus;
}

// After opening the MIDI device, assigns the MIDI parser system ignores, and output structure.
- openMidi
{
    if ([self openMidiDevice] != MKMD_SUCCESS)
        return nil;
    if (INPUTENABLED(ioMode)) {
        if (!(_pIn = (void *)_MKInitMidiIn()))
            return nil;
        else
            setMidiSysIgnore(self, systemIgnoreBits);
    }
    if (OUTPUTENABLED(ioMode)) {
	if (!(_pOut = (void *) _MKInitMidiOut()))
            return nil;
	else {
	    _MKMidiOutStruct *p = _pOut;
	    p->_owner = self;
	    p->_putSysMidi = putMidi;
	    p->_putChanMidi = putMidi;
	    p->_putSysExcl = putSysExcl;
	    p->_sendBufferedData = sendBufferedData;
	}
    }
    resetAndStopMidiClock(self);
    deviceStatus = MK_devOpen;
    return self;
}

/* This is a conservative version of allNotesOff.  It only sends
 * noteOffs for notes if those notes are sounding.
 * The notes are sent immediately (but will be
 * queued behind any notes that have already been queued up).
 */
- allNotesOff
{
    int i, cnt, j, r;
    
    if (!MIDIOUTPTR(self) || deviceStatus != MK_devRunning)
	return nil;
    /* MKMDFlushQueue not MKMDClearQueue, which can leave MIDI devices confused. */
    if ((r = MKMDFlushQueue(devicePort, ownerPort, outputUnit)) != MKMD_SUCCESS) {
	MKErrorCode(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"allNotesOff");
    }
    // Update our sense of time so that when we write out note-offs at time 0 we mean "now"!
    if ((r = MKMDSetClockTime(devicePort, ownerPort, 0)) != MKMD_SUCCESS) {
	MKErrorCode(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"allNotesOff");
    }
    for (i = 1; i <= MIDI_NUMCHANS; i++) {
	NSMutableArray *noteOffsForSoundingNotes = _MKGetNoteOns(MIDIOUTPTR(self), i);
	
	for (j = 0, cnt = [noteOffsForSoundingNotes count]; j < cnt; j++) {
	    // We need to wait a considerable amount of time for the note offs to be received. I think this is mostly to do with flushing
	    // the queue not really working on MacOS X.
            _MKWriteMidiOut([noteOffsForSoundingNotes objectAtIndex: j], 0.8, i, MIDIOUTPTR(self), [self channelNoteReceiver: i]);
	}
        // MKMDFlushQueue(devicePort, ownerPort, outputUnit);
	[noteOffsForSoundingNotes removeAllObjects];
	[noteOffsForSoundingNotes release];
    }
    awaitMidiOutDone(self, 1000); /* Timeout to work around driver (?) bug */
    return self;
}

int _MKAllNotesOffPause = 500; /* mSec between MIDI channel blasts 
				* This is a temporary hack and should
				* not be depended on!  It may change in 
				* the future.
				*/

- allNotesOffBlast
    /* If object is open for output, sends noteOff on every keyNum/channel.
       Note that this object assumes we're NOT encoding running status.
       (Currently, it is, indeed, the case that we're not encoding
       running status.) */
{
    MKMDRawEvent tmpMidiBuf[257];                     /* 1 for "noteOff", 256 for keyNum/chan */
    MKMDRawEvent *tmpBufPtr = &(tmpMidiBuf[1]);
    unsigned char chan;
    int i, r;
    if (deviceStatus == MK_devClosed || !OUTPUTENABLED(ioMode))
	return nil;
    for (i = 0; i < 128; i++) {
	tmpBufPtr->time = 0; 
	tmpBufPtr++->byte = i;   /* Keynum */
	tmpBufPtr->time = 0; 
	tmpBufPtr++->byte = 0;   /* Velocity */
    }
    /* FIXME Need to slow this down to prevent sound-out underrun during
     * barrage of outgoing MIDI data and so that external synthesizers have
     * time to respond.  Need to insert rests between channel resets. 
     */
    MKMDFlushQueue(devicePort, ownerPort, outputUnit);
    /* Not ClearQueue, which can leave MIDI devices confused. */
    for (i = 0; i < 16; i++) {       
	int j, k;
	
	chan = i;
	tmpMidiBuf[0].time = 0;
	tmpMidiBuf[0].byte = MIDI_NOTEOFF | chan;
	for (j = 0; j < 257; j += MKMD_MAX_EVENT) {
	    k = 257 - j;
	    for (; ;) {
		r = MKMDSendData(devicePort, ownerPort, outputUnit, &(tmpMidiBuf[j]), MIN(MKMD_MAX_EVENT, k));
	        if (r != MKMD_ERROR_QUEUE_FULL)
		    break;
		/* MIDI goes at a rate of a byte every 1/3 ms */
                [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: (k / 3) / 1000.0]];
	    }
	    MKMDFlushQueue(devicePort, ownerPort, outputUnit);
	    /* Slow it down so synths don't freak out */
            [NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: (_MKAllNotesOffPause) / 1000.0]];
	}
	MKMDFlushQueue(devicePort, ownerPort, outputUnit);
	if (r != MKMD_SUCCESS) {
	    MKErrorCode(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"allNotesOffBlast");
	    return nil;
	}
    }
    awaitMidiOutDone(self, 5000);
    return self;
}

- (void) listenToMIDI: (BOOL) receiveOnRecvPort
{
    MKMDReturn r;
    
    r = MKMDRequestData(devicePort, ownerPort, inputUnit,
                        (MKMDReplyPort) (receiveOnRecvPort) ? recvPort : MKMD_PORT_NULL);
    if (r != MKMD_SUCCESS) 
	MKErrorCode(MK_machErr, INPUT_ERROR, midiDriverErrorString(r), @"listenToMIDI");
}

- (void) cancelQueueReq
{
    MKMDReturn r;
    r = MKMDRequestQueueNotification(devicePort, ownerPort,
                                     outputUnit, (MKMDReplyPort) MKMD_PORT_NULL, 0);
    if (r != MKMD_SUCCESS) 
	MKErrorCode(MK_machErr, INPUT_ERROR, midiDriverErrorString(r), @"cancelQueueReq");
}

- openIfNecessary: (enum MKMidiDirection) direction
{
    ioMode = direction;
    switch (deviceStatus) {
    case MK_devClosed: /* Need to open it */
	return [self openMidi];
    case MK_devOpen:
	break;
    case MK_devRunning:
	if (INPUTENABLED(ioMode)) 
	    [self listenToMIDI: NO];
	if (OUTPUTENABLED(ioMode)) 
	    [self cancelQueueReq];
	/* no break here */
    case MK_devStopped:
	if (OUTPUTENABLED(ioMode))
            emptyMidi(self);
	resetAndStopMidiClock(self);
	deviceStatus = MK_devOpen;
	break;
    default:
	break;
    }
    return self;
}

- openOutputOnly
  /* Same as open but does not enable output. */
{
    if ((deviceStatus != MK_devClosed) && (ioMode != MKMidiOutputOnly))
        [self close];
    return [self openIfNecessary: MKMidiOutputOnly];
}

- openInputOnly
{
    if ((deviceStatus != MK_devClosed) && (ioMode != MKMidiInputOnly))
        [self close];
    return [self openIfNecessary: MKMidiInputOnly];
}

- open
  /* Opens device if not already open.
     If already open, flushes output queue. 
     Sets deviceStatus to MK_devOpen. 
     Returns nil if failure.
     */
{
    if ((deviceStatus != MK_devClosed) && (ioMode != MKMidiInputOutput))
        [self close];
    return [self openIfNecessary: MKMidiInputOutput];
}

- (double) localDeltaT
{
    return localDeltaT;
}

- setLocalDeltaT: (double) value
{
    localDeltaT = value;
    return self;
}

- run
{
    switch (deviceStatus) {
    case MK_devClosed:
	if (![self openMidi])
            return nil;
	/* no break here */
    case MK_devOpen:
/*	doDeltaT(self);  Needed if we'd ever use relative time to the driver */
	timeOffset = MKGetTime(); /* This is needed by MidiOut. */
	/* no break here */
    case MK_devStopped:
	if (INPUTENABLED(ioMode)) 
            [self listenToMIDI: YES];
	resumeMidiClock(self);
	deviceStatus = MK_devRunning;
    default:
	break;
    }
    return self;
}

- stop
{
    switch (deviceStatus) {
    case MK_devClosed:
	return [self open];
    case MK_devOpen:
    case MK_devStopped:
	return self;
    case MK_devRunning:
	[self stopMidiClock];
	if (INPUTENABLED(ioMode)) 
	    [self listenToMIDI: NO];
	if (OUTPUTENABLED(ioMode)) 
	    [self cancelQueueReq];
	deviceStatus = MK_devStopped;
    default:
	break;
    }
    return self;
}

- abort
{
    switch (deviceStatus) {
      case MK_devClosed:
	break;
      case MK_devRunning:
	if (INPUTENABLED(ioMode)) 
	    [self listenToMIDI: NO];
	if (OUTPUTENABLED(ioMode)) 
	    [self cancelQueueReq];
	/* No break here */
      case MK_devStopped:
      case MK_devOpen:
	if (OUTPUTENABLED(ioMode)) {
	    emptyMidi(self);
	}
	_pIn = (void *)_MKFinishMidiIn(MIDIINPTR(self));
	incomingDataCount = 0;
	_pOut = (void *)_MKFinishMidiOut(MIDIOUTPTR(self));
	[self closeMidiDevice];
	deviceStatus = MK_devClosed;
    }
    return self;
}

/* Need to ask for a message when queue is empty and wait for that message. */
- (void) close
{
    switch (deviceStatus) {
    case MK_devClosed:
	break;
    case MK_devRunning:
	if (INPUTENABLED(ioMode)) 
	    [self listenToMIDI: NO];
	if (OUTPUTENABLED(ioMode)) 
	    [self cancelQueueReq];
	    /* No break here */
    case MK_devStopped:
    case MK_devOpen:
	if (INPUTENABLED(ioMode)) {
	    _pIn = (void *)_MKFinishMidiIn(MIDIINPTR(self));
	    // NSLog(@"[%@ close]: _pIn = %p\n", self, _pIn);
	    incomingDataCount = 0;
	}
	if (OUTPUTENABLED(ioMode)) {
	    [self awaitQueueDrain];
	    emptyMidi(self);
	    _pOut = (void *)_MKFinishMidiOut(MIDIOUTPTR(self));
	}
	[self closeMidiDevice];
	deviceStatus = MK_devClosed;
    }
}

- awaitQueueDrain
{
    if (deviceStatus == MK_devRunning) 
        awaitMidiOutDone(self, MKMD_NO_TIMEOUT);
    return self;
}
/* output configuration */

- setOutputTimed: (BOOL) yesOrNo
/* Controls whether MIDI commands are sent timed or untimed. The default
   is timed. It is permitted to change
   from timed to untimed during a performance. */
{
    outputIsTimed = yesOrNo;
    return self;
}

- (BOOL) outputIsTimed
  /* Returns whether MIDI commands are sent timed. */
{
    return outputIsTimed;
}

/* Receiving notes */

- _realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
    /* Performs note by converting it to midi and emiting it. 
       Is careful about matching noteOns with noteOffs. For
       notes of type MK_noteDur, schedules up a message to
       self, implementing the noteOff. If the receiver is not in devRunning
       status, aNote is ignored. */
{
    double t;
    int chan;
    if ((!MIDIOUTPTR(self)) || (!aNote) || (deviceStatus != MK_devRunning))
        return nil;
    if (outputIsTimed) {
        if (self->synchConductor) {
	    t = ([self->synchConductor clockTime] - timeOffset + localDeltaT + mtcTimeOffset);
	    if (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG) 
                t += MKGetDeltaT();
	}
	else 
            t = MKGetDeltaTTime() - timeOffset + localDeltaT;
    }
    else
        t = 0;
    chan = [[aNoteReceiver _getData] intValue];
    _MKWriteMidiOut(aNote, t, chan, MIDIOUTPTR(self), aNoteReceiver);
    return self;
}

/* Accessing MKNoteSenders and MKNoteReceivers */

- (MKNoteSender *) channelNoteSender: (unsigned) channel
  /* Returns the MKNoteSender corresponding to the specified channel or nil
     if none. If n is 0, returns the MKNoteSender used for MKNotes fasioned
     from midi channel mode and system messages. */
{ 
    return (channel > MIDI_NUMCHANS) ? nil : [noteSenders objectAtIndex: channel];
}

- (MKNoteReceiver *) channelNoteReceiver: (unsigned) channel
  /* Returns the NoteReceiver corresponding to the specified channel or nil
     if none. If n is 0, returns the MKNoteReceiver used for MKNotes fashioned
     from midi channel mode and system messages. */
{ 
    return (channel > MIDI_NUMCHANS) ? nil : [noteReceivers objectAtIndex: channel];
}

- (NSArray *) noteSenders
  /* TYPE: Processing 
   * Returns a copy of the receiver's MKNoteSender List. 
   */
{
    return _MKLightweightArrayCopy(noteSenders);
    // return [_MKLightweightArrayCopy(noteSenders) autorelease];
}

- (MKNoteSender *) noteSender
  /* Returns the default MKNoteSender. This is used when you don't care
     which MKNoteSender you get. */
{
    return [noteSenders objectAtIndex: 0];
}

- (NSArray *) noteReceivers	
  /* TYPE: Querying; Returns a copy of the List of MKNoteReceivers.
   * Returns a copy of the List of MKNoteReceivers. The MKNoteReceivers themselves
   * are not copied.	
   */
{
    return _MKLightweightArrayCopy(noteReceivers);
    // return [_MKLightweightArrayCopy(noteReceivers) autorelease];
}

- (MKNoteReceiver *) noteReceiver
  /* TYPE: Querying; Returns the receiver's first MKNoteReceiver.
   * Returns the first MKNoteReceiver in the receiver's NSArray.
   * This is particularly useful for MKInstruments that have only
   * one MKNoteReceiver.
   */
{
    return [noteReceivers objectAtIndex: 0];
}

- setMergeInput: (BOOL) yesOrNo
{
    mergeInput = yesOrNo;
    return self;
}

// Download the patch numbers (NSNumbers) supplied in the NSArray as Downloadable Sounds (DLS).
// The patch format per integer follows the Microsoft convention:
// X0000000MMMMMMM0LLLLLLL0PPPPPPP
// X bit 31     = Patch is a DrumKit
// M bits 24-16 = MSB Bank Select(cc=0)
// L bits 15-8  = LSB bank select(cc=32)
// P bits 6-0   = Program Change number 
- (void) downloadDLS: (NSArray *) dlsPatches
{
    unsigned int *dlsPatchArray;
    unsigned int i;

    if (OUTPUTENABLED(ioMode) && deviceStatus != MK_devClosed) {
        _MK_MALLOC(dlsPatchArray, unsigned int, [dlsPatches count]);
        for(i = 0; i < [dlsPatches count]; i++)
            dlsPatchArray[i] = [[dlsPatches objectAtIndex: i] unsignedIntValue];
        MKMDDownloadDLSInstruments(dlsPatchArray, [dlsPatches count]);
        if (dlsPatchArray != NULL) {
          free(dlsPatchArray);
          dlsPatchArray = NULL;
        }
    }
}

#import "mtcMidi.m"

@end

#import "mtcMidiPrivate.m"

