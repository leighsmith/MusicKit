/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    MKMidi is made to look somewhat like a MKPerformer. It differs from a
    performer, however, in that it responds not to messages sent by a
    conductor, but by MIDI input which arrives through the serial port.

    Note that the MKConductor must be clocked to use MKMidi.

    Explanation of NeXTStep/OpenStep Intel support (not Win32):

    On the DSP, we use "soft" integers to map to "hard" driver/unit pairs.
    Here, we pass in a device 'name' in the form "midiN", where N is an integer.
    On the NeXT hardware, "midi" is a "hard" driver name and "N" is a hard unit
    number.  So, to maintain backward compatibility, we keep this interface, but
    we consider "midi" to be a signal to use soft numbering.

    Therefore, the algorithm is:

    If we're running on an Intel machine,
    look at root of name (everything up to the final integer).
    If it's "midi", assume the final number is "soft".
    Otherwise, if name is "Mididriver", use root of the name as driver and int as unit.
    (Currently, we actually accept anything that's not "midi" as equivalent
    to "Mididriver")

    Note: For now, we can just support the "soft" form.

    Further discussion:  The elaborate support here for shared ownership stems
    from the fact that, unlike with DSP drivers, the MIDI driver is also a time
    base.  That means that it must be shared among all instances.
    This complicates matters if we ever have more than one driver (as opposed to
    multiple instances of one driver.)  For now, I'm going to punt on that. If
    the situation ever comes up, we may have to factor the time stuff out of the
    driver and make a separate time server, which will be hard, seeing how MIDI
    time code must be parsed, etc.

    There is another subtle difference between MIDI and DSP handling.
    In the case of MIDI, we are perfectly happy to allocate objects for bogus
    midi objects.  We don't find out they're bogus until we try to open them.

    Note that the support for MIDI devices on different hosts will not work for
    Intel machines.  Hence if the host machine (the one the MusicKit app
    is running on) is an Intel machine, we ignore the hostName.

    Also, if a NeXT host tries to access a MIDI driver on an Intel machine, it
    will fail because there's no device "midiN" on Intel.

    For Win32, the "driver" within the MKPerformSndMIDI framework interfacing to
    DirectMusic will return a list of DirectMusic "ports", which can be hardware MIDI
    interfaces, PCM ROM playback engines on soundcards, the Microsoft DLS Sound Synthesiser
    etc. The device name can be either a port description string (exactly matching one of
    the driverNames), or can be "midiX" i.e. the soft form described above, where X is the
    0 base index referring to a driver.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.24  2000/07/22 00:32:20  leigh
  Minor doco and typing cleanups.

  Revision 1.23  2000/06/23 20:30:30  leigh
  Added fixes for OpenStep MIDI

  Revision 1.22  2000/06/15 01:10:28  leigh
  Added possibly more correct search for the Midi driver for MOX/DP4

  Revision 1.21  2000/05/06 02:36:42  leigh
  Made Win32 declare regression class types also

  Revision 1.20  2000/04/26 01:24:25  leigh
  Removed use of HashTable, fixed memory leak in factory methods

  Revision 1.19  2000/04/22 20:15:25  leigh
  user defaults standardised to MK prefix

  Revision 1.18  2000/04/16 04:19:42  leigh
  Removed assignment in condition warning

  Revision 1.17  2000/04/07 18:15:14  leigh
  Fixed incoming MIDI distribution

  Revision 1.16  2000/04/01 01:18:48  leigh
  Removed redundant imports, defined around for MacOsX (temporarily)

  Revision 1.15  2000/03/31 00:15:33  leigh
  Removed redundant include files

  Revision 1.14  2000/02/08 04:37:48  leigh
  Added check to downloadDLS: to ensure the MIDI device is open

  Revision 1.13  2000/02/03 19:14:56  leigh
  Removed extraneous header imports

  Revision 1.12  2000/01/27 19:05:59  leigh
  Now using NSPort replacing C Mach port API

  Revision 1.11  2000/01/20 17:15:36  leigh
  Replaced sleepMs with OpenStep NSThread delay

  Revision 1.10  1999/11/14 21:33:53  leigh
  Corrected _MKErrorf arguments to be NSStrings, properly return error codes from initOnDevice, fixed hardnamed device initialisation.

  Revision 1.9  1999/11/09 02:18:36  leigh
  Enabled Win32 driver selection with default driver automatically selected

  Revision 1.8  1999/10/28 01:40:52  leigh
  driver names and units now returned by separate class methods, renamed ivars, Win32 driver naming

  Revision 1.7  1999/09/28 03:05:29  leigh
  Cleaned up warnings

  Revision 1.6  1999/09/24 17:05:36  leigh
  downloadDLS method added, MKPerformSndMIDI framework now used

  Revision 1.5  1999/09/04 22:02:17  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.4  1999/08/26 19:54:54  leigh
  Code cleanup, Win32 clock support

  Revision 1.3  1999/08/08 01:59:22  leigh
  Removed extraVars cruft

  Revision 1.2  1999/07/29 01:16:37  leigh
  Added Win32 compatibility, CVS logs, SBs changes

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
                 Flushed superfluous setting of timeTag when creating Note
		 in sysex method.
  09/06/91/daj - Switched to new driver.  Need to release unit and driver.
  01/07/92/daj - Added break out of my_data_reply when the response
                 to the incoming Note is to abort.
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
#import <mach/mach_error.h>
#import <Foundation/NSUserDefaults.h>

#import <MKPerformSndMIDI/midi_driver.h>

#if openstep_i386
#import <driverkit/IOConfigTable.h>
#import <driverkit/IODeviceMaster.h>
#import <driverkit/IODevice.h>
#endif

/* MusicKit include files */
#import "_musickit.h"
#import "tokens.h"
#import "_error.h"
#import "_ParName.h"
#import "_midi.h"
#import "_time.h"
#import "ConductorPrivate.h"
#import "NoteReceiverPrivate.h"
#import "MidiPrivate.h"

@implementation MKMidi: NSObject

#define MIDIINPTR(midiobj) ((_MKMidiInStruct *)((MKMidi *)(midiobj))->_pIn)
#define MIDIOUTPTR(midiobj) ((_MKMidiOutStruct *)(midiobj)->_pOut)

#define INPUTENABLED(_x) (_x != 'o')
#define OUTPUTENABLED(_x) (_x != 'i')

#define MSG_LEN_IS_VARIABLE 3

#define UNAVAIL_DRIVER_ERROR \
NSLocalizedStringFromTableInBundle(@"MIDI driver is unavailable. Perhaps another application is using it", _MK_ERRTAB, _MKErrorBundle(), "")

#define UNAVAIL_UNIT_ERROR \
NSLocalizedStringFromTableInBundle(@"MIDI port is unavailable. Perhaps another application is using the port", _MK_ERRTAB, _MKErrorBundle(), "")

#define INPUT_ERROR \
NSLocalizedStringFromTableInBundle(@"Problem receiving MIDI from serial port", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an error is received from the Mach MIDI driver when receiving MIDI data.")

#define OUTPUT_ERROR \
NSLocalizedStringFromTableInBundle(@"Problem sending MIDI to serial port", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an error is received from the Mach MIDI driver when sending MIDI data.")

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
#define IGNORE_REAL_TIME 0xdd00  /* All of the above */

#define FCC_DID_NOT_APPROVE_DRIVER_CHANGE 1 // FIXME LMS

#define DEFAULT_SOFT_NAME @"midi0"
#if m68k
#define DRIVER_NAME @"mididriver"
#else
#define DRIVER_NAME @"Mididriver"   /* MD_NAME */
#endif

#define NO_UNIT (-1)

// class variables
static int addedPortsCount = 0;
static NSMutableDictionary *portTable = nil;
static MKMidi *receivingMidi = nil;           // the instance that has received the MIDI driver NSPort machMessage
static NSMutableArray *midiDriverNames = nil; // This and midiDriverUnits will have the same number of elements.
static NSMutableArray *midiDriverUnits = nil;
#if WIN32 || macosx
static unsigned int systemDefaultDriverNum;   // index into the midiDriverNames and units that the operating system has nominated as default
#endif

/* Some mtc forward decls */
static double mtcTimeOffset = 0;
static BOOL tearDownMTC(MKMidi *self);
static BOOL setUpMTC(MKMidi *self);

NSString *midiDriverErrorString(int errorCode)
{
    return [NSString stringWithCString: mach_error_string(errorCode)];
}

- (BOOL) unitHasMTC
{
    return (tvs->synchConductor && tvs->midiObj == self) ;
}

+ (NSMutableArray *) midisOnHost: (NSString *) midiHostname otherThanUnit: (int) midiUnit
    /* This method searches for any other Midi objects on hostname
     * NOT matching the specified unit.
     */
{
    MKMidi *midiObj;
    NSMutableArray *aList = [[NSMutableArray alloc] init];
    // This is inefficient, once we can do better compares we should retrieve the objectsForKeys:notFoundMarker:.
    // which has the port as the key
    NSEnumerator *enumerator = [portTable objectEnumerator];
    while ((midiObj = [enumerator nextObject])) {
        if ([midiObj->hostname isEqualToString: midiHostname] && (midiObj->unit != midiUnit))
            [aList addObject:midiObj];
    }
    return aList;
}

static int closeMidiDev(MKMidi *self)
{
    BOOL somebodyElseHasOwnership = NO;
    NSMutableArray *otherUnits;

    if (!self->ownerPort)
	return KERN_SUCCESS;
    otherUnits = [MKMidi midisOnHost: self->hostname otherThanUnit: self->unit];
    MIDIReleaseUnit([self->devicePort machPort], [self->ownerPort machPort], self->unit);
    if (INPUTENABLED(self->ioMode)) {
	if (self->recvPort) {
	    _MKRemovePort(self->recvPort);
	    addedPortsCount--;
	    [self->recvPort release];
	}
    }
    if (OUTPUTENABLED(self->ioMode))  
	[self->queuePort release];
    if ([self unitHasMTC])
      tearDownMTC(self);
    if ([otherUnits count] == 0) 
      somebodyElseHasOwnership = NO;
    else {
	MKMidi *aMidi;
	int i,cnt = [otherUnits count];
	for (i=0; i<cnt && !somebodyElseHasOwnership; i++) {
	    aMidi = [otherUnits objectAtIndex:i];
	    if (aMidi->ownerPort) 
	      somebodyElseHasOwnership = YES;
	}
    }
    if (somebodyElseHasOwnership)
      self->ownerPort = nil;
    else {
	MIDIReleaseOwnership([self->devicePort machPort], [self->ownerPort machPort]);
	[self->ownerPort release];
    } 
    [otherUnits release];
    /* Just being paranoid: */
    self->devicePort = nil;
    self->recvPort = nil;
    self->queuePort = nil;
    return KERN_SUCCESS;
}

static int getNumSuffix(NSString *s, BOOL *isSoftDev)
    /* Assumes s is valid string. Returns -1 if no final number found or if 
     * entire string is one number. Otherwise, returns number. */
{
    NSScanner *scanner = [NSScanner scannerWithString: s];
    int unitNum;
    BOOL gotInt;
    NSRange softDevPrefixRange = {0, 4};

    [scanner scanUpToCharactersFromSet: [NSCharacterSet decimalDigitCharacterSet] intoString: NULL]; 
    gotInt = [scanner scanInt: &unitNum];
    if(!gotInt || ![scanner isAtEnd] || [scanner scanLocation] == 0) {
        *isSoftDev = NO;
        return NO_UNIT;
    }
    else {
        *isSoftDev = [s compare: @"midi" 
                        options: NSAnchoredSearch
                        range:   softDevPrefixRange] == NSOrderedSame;
	return unitNum;
    }
}

static int openMidiDev(MKMidi *self)
    /* "Opens". If the device represented by devicePortName is already 
       accessed by this task, uses the ownerPort currently accessed.
       Otherwise, if ownerPort is nil, allocates a new
       port. Otherwise, uses ownerPort as specified. 
       To make the device truly public, you can pass the device port as the
       owner port.
       */
{
    int r;
    BOOL isSoftDevice;
    NSMutableArray *otherUnits;
#if macosx
    self->unit = getNumSuffix(self->midiDevName, &isSoftDevice);
    // for some bizarre reason (most probably a copy/paste oversight),
    // [NSMachBootstrapServer portForName] returns a NSPort, so we cast things to keep the compiler happy.
    self->devicePort = (NSMachPort *) [[NSMachBootstrapServer systemDefaultPortNameServer] portForName: DRIVER_NAME host: self->hostname];

    if (self->devicePort == nil) {
        _MKErrorf(MK_machErr, NETNAME_ERROR, @"Unable to find devicePort", @"MIDI Port Server lookup");
        return !KERN_SUCCESS;
    }
    [self->devicePort retain];
    otherUnits = [MKMidi midisOnHost: self->hostname otherThanUnit: self->unit];
    if ([otherUnits count]) {
        MKMidi *aMidi;
        int i;
        int cnt = [otherUnits count];
        for (i=0; i<cnt; i++) {
            aMidi = [otherUnits objectAtIndex:i];
            /* Should be the first one, but just in case... */
            if (aMidi->ownerPort != nil) {
                self->ownerPort = aMidi->ownerPort;
                break;
            }
        }
    }
    [otherUnits release];
#elif macosx_server
    self->unit = getNumSuffix(self->midiDevName, &isSoftDevice);
    self->devicePort = [[NSPortNameServer defaultPortNameServer] portForName: DRIVER_NAME onHost: self->hostname];

    if (self->devicePort == nil) {
        _MKErrorf(MK_machErr, NETNAME_ERROR, @"Unable to find devicePort", @"MIDI Port Server lookup");
	return !KERN_SUCCESS;
    }
    [self->devicePort retain];
    otherUnits = [MKMidi midisOnHost: self->hostname otherThanUnit: self->unit];
    if ([otherUnits count]) {
	MKMidi *aMidi;
	int i;
        int cnt = [otherUnits count];
	for (i=0; i<cnt; i++) {
	    aMidi = [otherUnits objectAtIndex:i];
	    /* Should be the first one, but just in case... */
	    if (aMidi->ownerPort != nil) {
                self->ownerPort = aMidi->ownerPort;
		break;
	    }
	}
    }
    [otherUnits release];
#else
    self->devicePort = [[NSPort port] retain]; // kludge it so it seems initialised
    self->ownerPort = nil;
    self->unit = [[midiDriverUnits objectAtIndex: [midiDriverNames indexOfObject: self->midiDevName]] intValue]; // kludged FIXME midiDriverUnits
#endif
    if (!self->ownerPort) {
        self->ownerPort = [[NSPort port] retain];
        if (self->ownerPort == nil) {
            _MKErrorf(MK_machErr, OWNER_ERROR, @"Unable to create ownerPort", @"openMidiDev owner NSPort allocate");
	    return !KERN_SUCCESS;
	}
	r = MIDIBecomeOwner([self->devicePort machPort], [self->ownerPort machPort]);
	if (r != KERN_SUCCESS) {
	    self->isOwner = NO;
	    _MKErrorf(MK_musicKitErr, UNAVAIL_DRIVER_ERROR);
	    closeMidiDev(self);
	    return r;
	}
    }
    r = MIDIClaimUnit([self->devicePort machPort], [self->ownerPort machPort], self->unit);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_musicKitErr,UNAVAIL_UNIT_ERROR);
	closeMidiDev(self);
	return r;
    }

    r = MIDISetClockQuantum([self->devicePort machPort], [self->ownerPort machPort], _MK_MIDI_QUANTUM);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_musicKitErr,OPEN_ERROR);
	closeMidiDev(self);
	return r;
    }

    r = MIDISetClockMode([self->devicePort machPort], [self->ownerPort machPort], -1, MIDI_CLOCK_MODE_INTERNAL);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_musicKitErr,OPEN_ERROR);
	closeMidiDev(self);
	return r;
    }

    /* Input */
    if (INPUTENABLED(self->ioMode)) {
        self->recvPort = [[NSPort port] retain];
        if (self->recvPort == nil) {
            _MKErrorf(MK_machErr, OPEN_ERROR, @"Unable to create recvPort", @"openMidiDev recv NSPort allocate");
	    closeMidiDev(self);
	    return !KERN_SUCCESS;
	}
        /* sb: first self was midiIn. Changed to self because 'self' responds to -handleMachMessage */
        _MKAddPort(self->recvPort,self, 0, self, _MK_DPSPRIORITY);
	addedPortsCount++;
    }
    if (OUTPUTENABLED(self->ioMode)) {
        self->queuePort = [[NSPort port] retain];
        if (self->queuePort == nil) {
            _MKErrorf(MK_machErr, OPEN_ERROR, @"Unable to create queuePort", @"openMidiDev queue NSPort allocate");
	    closeMidiDev(self);
            return !KERN_SUCCESS;
	}
	r = MIDIGetAvailableQueueSize([self->devicePort machPort],
				      [self->ownerPort machPort],
				      self->unit,
				      &(self->queueSize));
	if (r != KERN_SUCCESS) {
            _MKErrorf(MK_machErr, OPEN_ERROR, midiDriverErrorString(r), @"MIDIGetAvailableQueueSize");
	    closeMidiDev(self);
	    return r;
	}
    }
    if ([self unitHasMTC])
      setUpMTC(self);
    return KERN_SUCCESS;
}    

static timeVars *getTimeInfoFromHost(NSString *hostname)
{
    static NSMutableDictionary *timeInfoTable = nil;
    timeVars *p;
    NSData *timeVarsEncoded;

    if (!timeInfoTable) /* Mapping from hostname to tvs pointer */
        timeInfoTable = [[NSMutableDictionary dictionary] retain];
    if ((timeVarsEncoded = [timeInfoTable objectForKey: hostname]))
        return (timeVars *) [timeVarsEncoded bytes];
    _MK_CALLOC(p,timeVars,1);
    // [timeInfoTable setObject: p forKey: hostname];
    return p;
}


static void waitForRoom(MKMidi *self,int elements,int timeOut)
{
    int r;
    MIDIReplyFunctions recvStruct = {0};
    r = MIDIRequestQueueNotification([self->devicePort machPort],
				     [self->ownerPort machPort],
				     self->unit,
				     [self->queuePort machPort],
				     elements);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r),
		@"waitForRoom queue notification request");
    r = MIDIAwaitReply([self->queuePort machPort], &recvStruct, timeOut);
    /* THIS BLOCKS! */
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r),
		  @"waitForRoom MIDIAwaitReply");
}

static void awaitMidiOutDone(MKMidi *self,int timeOut)
    /* Wait until Midi is done and then return */
{
    waitForRoom(self, self->queueSize, timeOut);
}

static int stopMidiClock(MKMidi *self)
{
    int r;
    if (self->tvs->synchConductor) {
	r = MIDIRequestExceptions([self->devicePort machPort], [self->ownerPort machPort], PORT_NULL);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r), @"stopMidiClock MIDIRequestExceptions");
	r = MIDISetClockMode([self->devicePort machPort], [self->ownerPort machPort], self->unit, MIDI_CLOCK_MODE_INTERNAL);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r), @"stopMidiClock MIDISetClockMode");
	r = MIDIRequestAlarm([self->devicePort machPort], [self->ownerPort machPort], PORT_NULL, 0);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r), @"stopMidiClock MIDIRequestAlarm");
	self->tvs->alarmPending = NO;
	return r;
    }
    r = MIDIStopClock([self->devicePort machPort], [self->ownerPort machPort]);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r), @"stopMidiClock MIDIStopClock");
    return r;
}

static int resumeMidiClock(MKMidi *self)
{
    int r; 
    if (self->tvs->synchConductor) {
	r = MIDIRequestExceptions([self->devicePort machPort], [self->ownerPort machPort],
				  [self->tvs->exceptionPort machPort]);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r),
		    @"resumeMidiClock MIDIRequestExceptions");
	r = MIDISetClockMode([self->devicePort machPort], [self->ownerPort machPort], self->unit,
			     MIDI_CLOCK_MODE_MTC_SYNC);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r),
		    @"resumeMidiClock MIDISetClockMode");
	if (self->tvs->alarmTimeValid) {
	    r = MIDIRequestAlarm([self->devicePort machPort], [self->ownerPort machPort], [self->tvs->alarmPort machPort],
				 self->tvs->alarmTime);
	    self->tvs->alarmPending = YES;
	    if (r != KERN_SUCCESS)
	      _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r),
			@"resumeMidiClock MIDIRequestAlarm");
	}
	return r;
    }
    r = MIDIStartClock([self->devicePort machPort], [self->ownerPort machPort]);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"resumeMidiClock MIDIStartClock");
    return r;
}

static int resetAndStopMidiClock(MKMidi *self)
{
    int r;
    stopMidiClock(self);
    r = MIDISetClockTime([self->devicePort machPort], [self->ownerPort machPort], 0);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"resetAndStopMidiClock");
    return r;
}

static int emptyMidi(MKMidi *self)
    /* Get rid of enqueued outgoing midi messages */
{
    int r;
    r = MIDIClearQueue([self->devicePort machPort], [self->ownerPort machPort], self->unit);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"emptyMidi");
    return r;
}

static int setMidiSysIgnore(MKMidi *self,unsigned bits)
    /* Tell driver to ignore particular incoming MIDI system messages */
{
#   if FCC_DID_NOT_APPROVE_DRIVER_CHANGE
    int r = MIDISetSystemIgnores([self->devicePort machPort], [self->ownerPort machPort],
				 self->unit,bits);
#   else 
    int r = 0;
    r |= MIDIFilterMessage([self->devicePort machPort], [self->ownerPort machPort], self->unit, 
			   MIDI_CLOCK, bits & IGNORE_CLOCK);
    r |= MIDIFilterMessage([self->devicePort machPort], [self->ownerPort machPort], self->unit, 
			   MIDI_START, bits & IGNORE_START);
    r |= MIDIFilterMessage([self->devicePort machPort], [self->ownerPort machPort], self->unit, 
			   MIDI_CONTINUE, bits & IGNORE_CONTINUE);
    r |= MIDIFilterMessage([self->devicePort machPort], [self->ownerPort machPort], self->unit, 
			   MIDI_STOP, bits & IGNORE_STOP);
    r |= MIDIFilterMessage([self->devicePort machPort], [self->ownerPort machPort], self->unit, 
			   MIDI_ACTIVE, bits & IGNORE_ACTIVE);
    r |= MIDIFilterMessage([self->devicePort machPort], [self->ownerPort machPort], self->unit, 
			   MIDI_RESET, bits & IGNORE_RESET);
#   endif
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr, INPUT_ERROR, midiDriverErrorString(r), @"");
    return r;
}


/* Low-level output routines */

/* We currently use MIDI "raw" mode. Perhaps cooked mode would be more efficient? */

#define MIDIBUFSIZE MIDI_MAX_EVENT

static MIDIRawEvent midiBuf[MIDIBUFSIZE];
static MIDIRawEvent *bufPtr = &(midiBuf[0]);

static void putTimedByte(unsigned curTime,unsigned char aByte)
    /* output a MIDI byte */
{
    bufPtr->time = curTime;
    bufPtr->byte = aByte;
    bufPtr++;
}

static void sendBufferedData(struct __MKMidiOutStruct *ptr); /* forward decl*/

static void putTimedByteWithCheck(struct __MKMidiOutStruct *ptr,
				  unsigned curTime,unsigned char aByte)
    /* Same as above, but checks for full buffer */
{
    if ((&(midiBuf[MIDIBUFSIZE])) == bufPtr) 
      sendBufferedData(ptr);
    putTimedByte(curTime,aByte);
}

static void sendBufferedData(struct __MKMidiOutStruct *ptr)
    /* Send any buffered bytes and reset pointer to start of buffer */
{
    int r;
    MKMidi *midiObj;
    int nBytes;
    nBytes = bufPtr - &(midiBuf[0]);
    if (nBytes == 0)
	return;
    midiObj = ((MKMidi *)ptr->_owner);
    for (; ;) {
	r = MIDISendData([midiObj->devicePort machPort], [midiObj->ownerPort machPort], midiObj->unit, &(midiBuf[0]), nBytes);
	if (r == MIDI_ERROR_QUEUE_FULL) 
	    waitForRoom(midiObj,nBytes,MIDI_NO_TIMEOUT);
	else break;
    }
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"sendBufferedData");
    bufPtr = &(midiBuf[0]);
}

static void putMidi(struct __MKMidiOutStruct *ptr)
    /* Adds a complete MIDI message to the output buffer */
{
    unsigned int curTime = .5 + ptr->_timeTag * _MK_MIDI_QUANTUM;
    if (((&(midiBuf[MIDIBUFSIZE])) - bufPtr) < ptr->_outBytes)
      sendBufferedData(ptr);
    putTimedByte(curTime,ptr->_bytes[0]);
    if (ptr->_outBytes >= 2)
      putTimedByte(curTime,ptr->_bytes[1]);
    if (ptr->_outBytes == 3)
      putTimedByte(curTime,ptr->_bytes[2]);
}

static void putSysExcl(struct __MKMidiOutStruct *ptr,NSString *sysExclString)
{
    /* sysExStr is a string. The string consists of system exclusive bytes
	separated by any non-digit delimiter. The musickit uses the 
	delimiter ','. E.g. "f8,13,f7".  This function converts each ASCII
	byte into the corresponding number and sends it to serial port.
       Note that if you want to give each sysex byte a different
       delay, you need to do a separate call to this function.
       On a higher level, this means that you need to put each
       byte in a different Note object. 
	The string may but need not begin with MIDI_SYSEXCL and end with
	MIDI_EOX. 
       */
    const char *sysExclStr = [sysExclString cString];
    unsigned char c;
    unsigned int curTime = .5 + ptr->_timeTag * _MK_MIDI_QUANTUM;
    sendBufferedData(ptr);
    c = _MKGetSysExByte(&sysExclStr);
    if (c == MIDI_EOX)
      return;
    if (c != MIDI_SYSEXCL) 
      putTimedByte(curTime,MIDI_SYSEXCL);
    putTimedByte(curTime,c);
    while (*sysExclStr) {
	c = _MKGetSysExByte(&sysExclStr);
	putTimedByteWithCheck(ptr,curTime,c);
    }
    if (c != MIDI_EOX) 
      putTimedByteWithCheck(ptr,curTime,MIDI_EOX);  /* Terminate it properly */
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
    /* Paresing routine for incoming system exclusive */
{
#   define DEFAULTLEN 256
    if (midiByte == MIDI_SYSEXCL) {  /* It's a new one. */
	if (!ptr->_sysExBuf) {
	    _MK_MALLOC(ptr->_sysExBuf,unsigned char,DEFAULTLEN);
	    ptr->_sysExSize = DEFAULTLEN;
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
	double t;
	id synchCond = sendingMidi->tvs->synchConductor;
        t = (((double)quanta) * _MK_MIDI_QUANTUM_PERIOD + sendingMidi->_timeOffset);
	if (MKGetDeltaTMode() == MK_DELTAT_SCHEDULER_ADVANCE) 
	  t += MKGetDeltaT();
	if (synchCond)
	  t -= mtcTimeOffset;
	[aNote setTimeTag:t];
        if (sendingMidi->useInputTimeStamps) 
	  if (synchCond)
	    [synchCond _setMTCTime:(double)t];
	  else _MKAdjustTime(t); /* Use input time stamp time */
	else [_MKClassConductor() adjustTime]; 
	if (sendingMidi->mergeInput) { /* Send all on one MKNoteSender? */
	    MKSetNoteParToInt(aNote,MK_midiChan,chan);
            [[sendingMidi->noteSenders objectAtIndex:0] sendNote:aNote];
	}
        else {
            [[sendingMidi->noteSenders objectAtIndex:chan] sendNote:aNote];
        }
	[_MKClassOrchestra() flushTimedMessages]; /* Off to the DSP */
    }
}

static int incomingDataCount = 0; /* We use a static here to allow us to
				   * break out of my_data_reply.  Note that
				   * my_data_reply can never be called
				   * recursively so there's no danger in doing
				   * this. 
				   */

// my_data_reply is called direct from the MIDI Reply routine, so the Mach port needs to be defined rather than
// an NSPort for the first parameter.
static void my_data_reply(mach_port_t reply_port, short unit, MIDIRawEvent *events, unsigned int count) {
    _MKMidiInStruct *ptr;
    MKNote *aNote;
    unsigned char statusByte;

    if(receivingMidi == nil) { // check we assigned this in handleMachMessage
        _MKErrorf(MK_musicKitErr, @"Internal error, receiving MKMidi has not been assigned\n");
        return;
    }
    ptr = MIDIINPTR(receivingMidi);
    for (incomingDataCount = count; incomingDataCount--; events++) {
	if ((statusByte = parseMidiByte(events->byte, ptr))) {
	    if (statusByte == MIDI_SYSEXCL)
                aNote = handleSysExclbyte(ptr, events->byte);
	    else
                aNote = _MKMidiToMusicKit(ptr, statusByte);
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
    receivingMidi = nil; // to rigourously check handleMachMessage does its job, prevents spurious wrong messages being sent.
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

- (void)handleMachMessage:(void *)machMessage
{
    msg_header_t *msg = (msg_header_t *)machMessage;
    int r;
    MIDIReplyFunctions recvStruct = { /* Tells driver funcs to call */ my_data_reply,0,0,0};

    receivingMidi = self;
    // Eventually MIDIHandleReply should be unnecessary, when we receive the MIDI data direct into handlePortMessage
    // Then we can merge this method and my_data_reply into a single handlePortMessage. 
    r = MIDIHandleReply(msg,&recvStruct);        /* This gets data */
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr, INPUT_ERROR, midiDriverErrorString(r), @"midiIn");
}

/* Input configuration */



-setUseInputTimeStamps:(BOOL)yesOrNo
{
    if (deviceStatus != MK_devClosed)
      return nil;
    useInputTimeStamps = yesOrNo;
    return self;
}

-(BOOL)useInputTimeStamps
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

- ignoreSys:(MKMidiParVal)param
{
    _ignoreBits |= ignoreBit(param);
    if (deviceStatus != MK_devClosed)
      setMidiSysIgnore(self,_ignoreBits);
    return self;
} 

- acceptSys:(MKMidiParVal)param 
{
    _ignoreBits &= ~(ignoreBit(param));
    if (deviceStatus != MK_devClosed)
      setMidiSysIgnore(self,_ignoreBits);
    return self;
}

/* Performer-like methods. */

-conductor
{
    return conductor ? conductor : [_MKClassConductor() clockConductor];
}

-setConductor:aConductor
{
    conductor = aConductor;
    return self;
}

/* Creation */

-_free
  /* Needed below */
{
//    [super release];
    return nil; //sb: I assume this is what [super free] used to return...
}

#if !m68k

/* This mechanism is more general than we need, because the rest of this
   object currently assumes that there's only one MIDI driver called 
   MK_NAME.  However, in case we ever support others, I want to support
   the general API.  And since this code was already written for the DSP
   case, I thought I'd just grab it from there.
   LMS: The day is rapidly approaching when we need all of David's functionality
   with Win32 named ports, MOXS USB MIDI devices etc.
 */

// Return YES if able to initialise for the MIDI driver which registers available MIDI output ports.
// This includes DriverKit based MIDI drivers and Windows DirectMusic (MKPerformSndMIDI) based drivers.
// Returns NO if there was no MIDI driver found. 
static BOOL getAvailableMidiDevices(void)
{
#if openstep_i386
    char *s;
    const char *familyStr;
    List *installedDrivers;
    NSMutableArray *midiDriverList;
    id aConfigTable;
    int midiDriverCount;
    int i;
#elif WIN32 || macosx
    const char **systemDriverNames;
    int i;
#endif
    static BOOL driverInfoInitialized = NO;

    if (driverInfoInitialized) { /* Already initialized */
	return YES;
    }
    else
        driverInfoInitialized = YES;
#if WIN32 || macosx
    // Windows98/NT YellowBox/NT, WebObjects or OpenStep Enterprise using the MKPerformSndMIDI framework
    // In future, this should become the cross-platform means to obtain the available drivers, the others below
    // are legacy.
    systemDriverNames = MIDIGetAvailableDrivers(&systemDefaultDriverNum);
    midiDriverNames = [NSMutableArray array];
    midiDriverUnits = [NSMutableArray array];
    for(i = 0; systemDriverNames[i] != NULL; i++) {
        [midiDriverNames insertObject: [NSString stringWithCString: systemDriverNames[i]] atIndex: i];
        [midiDriverUnits insertObject: [NSNumber numberWithInt: i] atIndex: i];
    }
    if([midiDriverNames count] == 0)
        return NO;
#elif openstep_i386 
    // RDR2/Intel or OpenStep 4.X/Intel using DriverKit
    // The IOConfigTable access should become part of the MKPerformSndMIDI framework (suitably #if i386'd)
    installedDrivers = [IOConfigTable tablesForInstalledDrivers];
    /* Creates, if necessary, and returns IOConfigTables, one for each
       device that has been loaded into the system.  This method knows only
       about those devices that are specified with the system configuration
       table's InUse Drivers and Boot Drivers keys.  It does not detect
       drivers that were loaded due to user action at boot time.  To get 
       the IOConfigTables for those drivers, you can use 
       tablesForBootDrivers. 
       */
    midiDriverList = [[NSMutableArray alloc] init];
    /* Get MIDI drivers */
    for (i = 0; i < [installedDrivers count]; i++) {
        aConfigTable = [installedDrivers objectAt:i]; 	/* Each driver */
        familyStr = [aConfigTable valueForStringKey:"Family"];
//        NSLog(@"%s\n", [aConfigTable valueForStringKey: "Driver Name"]);
        if(familyStr != NULL) {
          if (!strcmp(familyStr,"MIDI"))
	    [midiDriverList addObject:aConfigTable];
        }
    }
    midiDriverCount = [midiDriverList count];
    if (midiDriverCount == 0) {
	/* This is almost certainly an error */
	[midiDriverList release];
	return NO;
    }
    midiDriverNames = [NSMutableArray arrayWithCapacity: midiDriverCount];
    midiDriverUnits = [NSMutableArray arrayWithCapacity: midiDriverCount];
    for (i=0; i < midiDriverCount; i++) {
	/* Or "Server Name"? */
	aConfigTable = [midiDriverList objectAtIndex:i];
        [midiDriverNames insertObject: [NSString stringWithCString:(char *)[aConfigTable valueForStringKey:"Class Names"]]
	                 atIndex: i];
	s = (char *)[aConfigTable valueForStringKey:"Instance"];
        [midiDriverUnits insertObject: s ? [NSNumber numberWithInt: atoi(s)] : [NSNumber numberWithInt: 0] atIndex: i];
    }
#elif macosx_server
    // hardwire this for MOXS1.0 until tablesForInstalledDrivers gives us what we expect
    midiDriverNames = [NSMutableArray arrayWithObject: [NSString stringWithFormat:@"%@0",DRIVER_NAME]];
    midiDriverUnits = [NSMutableArray arrayWithObject: [NSNumber numberWithInt: 0]];
#endif
    // NSLog([midiDriverNames description]);
    [midiDriverNames retain];
    [midiDriverUnits retain];
    return YES;
}

static BOOL mapSoftNameToDriverNameAndUnit(NSString *devName, NSString **midiDevStrArr)
    /* Maps a name of the form "midi0" to a name of the form "Mididriver2".
     * See above long explanation.  Returns copy of hard name.
     */
{
    NSString *midiNumStrArr;
    int i;
    BOOL isSoft;
    NSString *defaultsValue;
    int num = getNumSuffix(devName, &isSoft);

    getAvailableMidiDevices(); // assigns midiDriverNames and midiDriverUnits
    // devName can be of the soft form "midi0", or the hard description "Mididriver0" or "SB Live! MIDI Out"
    if (isSoft) {
        midiNumStrArr = [NSString stringWithFormat:@"MKMIDI%d",num];

        // The owner will be whatever application links against this framework. This is what we want to allow for
        // different applications to use different MIDI devices if necessary.
        defaultsValue = (NSString *) [[NSUserDefaults standardUserDefaults] objectForKey: midiNumStrArr];
	if ([defaultsValue length]) 
	  num = getNumSuffix(defaultsValue, &isSoft);
	else if (num == 0) { 
#if WIN32 || macosx
          // Use the system default MIDI driver
	  *midiDevStrArr = [[midiDriverNames objectAtIndex: systemDefaultDriverNum] copy];
#else
          /* Just use any one we can find */
          *midiDevStrArr = [[NSString stringWithFormat:@"%@0",DRIVER_NAME] retain];
#endif
	  return YES;
	}
    }
#if WIN32 || macosx
    // here we assume if we didn't have a soft device name, we are referring to a described device.
    *midiDevStrArr = [[devName copy] retain];
#else
    /* Otherwise, just use soft number as a hard number */
    // LMS this overrides the actual hard name which was passed in, and doesn't seem correct
    *midiDevStrArr = [NSString stringWithFormat:@"%@%d",DRIVER_NAME,num];
#endif

    // ensure the driver was on the legitimate list
    for (i=0; i < [midiDriverNames count]; i++) {
        if ([*midiDevStrArr isEqualToString: [midiDriverNames objectAtIndex:i]]) {
	    // num will be NO_UNIT if there was no conversion from soft to hard driver names
	    // LMS: Disabled unit check as getNumSuffix() will report MPU-401 as the 401st unit!
            // The check was really doing very little since we have verified the name is correct anyway.
            // If the driver name included a numeric suffix i.e Mididriver0 then the match above
            // has verified correctly.
	    // if ((num == NO_UNIT) || ([[midiDriverUnits objectAtIndex: i] intValue] == num)) 
		return YES;
	}
    }
    return NO;
}

// Returns autoreleased copies of all available driverNames as an NSArray
+ (NSArray *) getDriverNames
{
    getAvailableMidiDevices();
    return [[midiDriverNames copy] autorelease];
}

// Returns autoreleased copies of all available driverUnits
+ (NSArray *) getDriverUnits
{
    getAvailableMidiDevices();
    return [[midiDriverUnits copy] autorelease];
}

#endif

- (NSString *) driverName 
{
    return midiDevName;
}

- (int) driverUnit
{
    return unit;
}

// Here we initialize our class variables.
+ (void) initialize
{
    NSDictionary *MKMIDIDefaults;

    portTable = [NSMutableDictionary dictionary];
    [portTable retain];
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
- initOnDevice:(NSString *) devName hostName:(NSString *) hostName
{
#if !m68k
    NSString *midiDevStrArr;
#endif
    MKMidi *obj;
    NSString *hostAndDevName;
    MKNoteSender *aNoteSender;
    MKNoteReceiver *aNoteReceiver;
    int i;
    _MKParameter *aParam;

#if !m68k
    hostName = @""; /* Only on local host, see extensive comment above */
    if (!mapSoftNameToDriverNameAndUnit(devName,&midiDevStrArr))
      return nil;
    devName = midiDevStrArr;
#endif
    hostAndDevName = [hostName stringByAppendingString: devName];
    if ((obj = [portTable objectForKey: hostAndDevName]) == nil) {         // Doesn't already exist
        tvs = getTimeInfoFromHost(hostName);
        [portTable setObject:self forKey: hostAndDevName]; 
    }
    // even if the device is in the portTable, we still need to set the device and host name
    hostname = [hostName copy];
    midiDevName = [devName retain];

    if (noteSenders != nil) /* Already initialized */
        return nil;
    outputIsTimed = YES;               /* Default is outputIsTimed */
    noteSenders = [NSMutableArray arrayWithCapacity:_MK_MIDINOTEPORTS];
    [noteSenders retain];
    noteReceivers = [NSMutableArray arrayWithCapacity:_MK_MIDINOTEPORTS];
    [noteReceivers retain];
    for (i = 0; i < _MK_MIDINOTEPORTS; i++) {
        aNoteReceiver = [MKNoteReceiver new];
        [noteReceivers addObject:aNoteReceiver];
        [aNoteReceiver _setOwner:self];
        [aNoteReceiver _setData:aParam = _MKNewIntPar(0,MK_noPar)];
        _MKSetIntPar(aParam,i);
        aNoteSender = [MKNoteSender new];
        [noteSenders addObject:aNoteSender];
        [aNoteSender _setPerformer:self];
        [aNoteReceiver release];
        [aNoteSender release]; /*sb: retains are held in arrays */
     }
     useInputTimeStamps = YES;
     _timeOffset = 0;
     _ignoreBits = (IGNORE_ACTIVE |
                    IGNORE_CLOCK |
                    IGNORE_START |
                    IGNORE_CONTINUE |
                    IGNORE_STOP);
     deviceStatus = MK_devClosed;
     _MKCheckInit(); /* Maybe we don't want this here, in case we ever want
                        to use MKMidi without MKNotes. (?) FIXME */
     _MKClassOrchestra(); /* Force find-class here */
     ioMode = 'a';
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

+ midiOnDevice:(NSString *) devName host:(NSString *) hostName
{
    self = [MKMidi alloc];
    return [[self initOnDevice: devName hostName: hostName] autorelease];
}

+ midiOnDevice:(NSString *) devName
{
    self = [MKMidi alloc];
    return [[self initOnDevice:devName] autorelease];
}

+ midi
{
    return [[self midiOnDevice: DEFAULT_SOFT_NAME] autorelease];
}

- copyWithZone:(NSZone *)zone
  /* Overridden to return self. */
{
    return self;
}

-copy
  /* Overridden to return self. */
{
    return self;
}

- (void)dealloc
  /* Aborts and frees the receiver. */
{
    int i;
    int size = [noteReceivers count];
    [self abort];
    if ([self unitHasMTC]) 
      [tvs->synchConductor _setMTCSynch:nil];
    [self _setSynchConductor:nil];
    for (i=0; i<size; i++)
        _MKFreeParameter([[noteReceivers objectAtIndex:i] _getData]);
    [noteReceivers makeObjectsPerformSelector:@selector(disconnect)];
    [noteReceivers removeAllObjects];  
    [noteReceivers release];
    [noteSenders makeObjectsPerformSelector:@selector(disconnect)];
    [noteSenders removeAllObjects];  
    [noteSenders release];
    NSLog(@"removing the object");
    [portTable removeObjectForKey:midiDevName];
    [super dealloc];
}
/* Control of device */

-(MKDeviceStatus)deviceStatus
  /* Returns MKDeviceStatus of receiver. */
{
    return deviceStatus;
}

static id openMidi(MKMidi *self)
{
    if (openMidiDev(self) != KERN_SUCCESS)
        return nil;
    if (INPUTENABLED(self->ioMode)) {
        if (!(self->_pIn = (void *)_MKInitMidiIn()))
            return nil;
        else
            setMidiSysIgnore(self,self->_ignoreBits);
    }
    if (OUTPUTENABLED(self->ioMode)) {
	if (!(self->_pOut = (void *)_MKInitMidiOut()))
            return nil;
	else {
	    _MKMidiOutStruct *p = self->_pOut;
	    p->_owner = self;
	    p->_putSysMidi = putMidi;
	    p->_putChanMidi = putMidi;
	    p->_putSysExcl = putSysExcl;
	    p->_sendBufferedData = sendBufferedData;
	}
    }
    resetAndStopMidiClock(self);
    self->deviceStatus = MK_devOpen;
    return self;
}

-allNotesOff
   /* This is a conservative version of allNotesOff.  It only sends
    * noteOffs for notes if those notes are sounding.
    * The notes are sent immediately (but will be
    * queued behind any notes that have already been queued up.)
    */
{
    NSMutableArray *aList;
    int i,cnt,j;
    if (!MIDIOUTPTR(self) || deviceStatus != MK_devRunning)
      return nil;
    MIDIFlushQueue([self->devicePort machPort], [self->ownerPort machPort], self->unit);
    /* Not ClearQueue, which can leave MIDI devices confused. */
    for (i=1; i<=MIDI_NUMCHANS; i++) {
	aList = _MKGetNoteOns(MIDIOUTPTR(self),i);
	for (j=0, cnt = [aList count]; j<cnt; j++)
            _MKWriteMidiOut([aList objectAtIndex:j],0,i,MIDIOUTPTR(self),
			  [self channelNoteReceiver:i]);
	MIDIFlushQueue([self->devicePort machPort], [self->ownerPort machPort], self->unit);
	[aList removeAllObjects];
	[aList release];
    }
    awaitMidiOutDone(self,1000); /* Timeout to work around driver (?) bug */
    return self;
}

int _MKAllNotesOffPause = 500; /* ms between MIDI channel blasts 
				* This is a temporary hack and should
				* not be depended on!  It may change in 
				* the future.
				*/

-allNotesOffBlast
    /* If object is open for output, sends noteOff on every keyNum/channel.
       Note that this object assumes we're NOT encoding running status.
       (Currently, it is, indeed, the case that we're not encoding
       running status.) */
{
    MIDIRawEvent tmpMidiBuf[257];  
                                    /* 1 for "noteOff",256 for keyNum/chan */
    MIDIRawEvent *tmpBufPtr = &(tmpMidiBuf[1]);
    unsigned char chan;
    int i,r;
    if (deviceStatus == MK_devClosed || !OUTPUTENABLED(ioMode))
	return nil;
    for (i=0; i<128; i++) {
	tmpBufPtr->time = 0; 
	tmpBufPtr++->byte = i;   /* Keynum */
	tmpBufPtr->time = 0; 
	tmpBufPtr++->byte = 0;   /* Velocity */
    }
    /* FIXME Need to slow this down to prevent sound-out underrun during
     * barrage of outgoing MIDI data and so that external synthesizers have
     * time to respond.  Need to insert rests between channel resets. 
     */
    MIDIFlushQueue([devicePort machPort], [ownerPort machPort], unit);
    /* Not ClearQueue, which can leave MIDI devices confused. */
    for (i=0; i<16; i++) {       
	int j,k;
	chan = i;
	tmpMidiBuf[0].time = 0;
	tmpMidiBuf[0].byte = MIDI_NOTEOFF | chan;
	for (j=0; j < 257; j += MIDI_MAX_EVENT) {
	    k = 257 - j;
	    for (; ;) {
		r = MIDISendData([devicePort machPort], [ownerPort machPort], unit, &(tmpMidiBuf[j]), MIN(MIDI_MAX_EVENT,k));
	        if (r != MIDI_ERROR_QUEUE_FULL)
		    break;
		/* MIDI goes at a rate of a byte every 1/3 ms */
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(k/3)/1000.0]];
	    }
	    MIDIFlushQueue([devicePort machPort], [ownerPort machPort], unit);
	    /* Slow it down so synths don't freak out */
            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(_MKAllNotesOffPause)/1000.0]];
	}
	MIDIFlushQueue([devicePort machPort], [ownerPort machPort], unit);
	if (r != KERN_SUCCESS) {
	    _MKErrorf(MK_machErr, OUTPUT_ERROR, midiDriverErrorString(r), @"allNotesOffBlast");
	    return nil;
	}
    }
    awaitMidiOutDone(self,5000);
    return self;
}

static void listenToMIDI(MKMidi *self,BOOL flg)
{
    int r;
    r = MIDIRequestData([self->devicePort machPort], [self->ownerPort machPort], self->unit,
			(flg) ? [self->recvPort machPort] : PORT_NULL);
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr, INPUT_ERROR, midiDriverErrorString(r), @"listenToMIDI");
}

static void cancelQueueReq(MKMidi *self)
{
    int r;
    r = MIDIRequestQueueNotification([self->devicePort machPort], [self->ownerPort machPort],
				     self->unit, PORT_NULL, 0);
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr, INPUT_ERROR, midiDriverErrorString(r), @"cancelQueueReq");
}

-_open
{
    switch (deviceStatus) {
      case MK_devClosed: /* Need to open it */
	return openMidi(self);
      case MK_devOpen:
	break;
      case MK_devRunning:
	if (INPUTENABLED(ioMode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(ioMode)) 
	    cancelQueueReq(self);
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

-openOutputOnly
  /* Same as open but does not enable output. */
{
    if ((deviceStatus != MK_devClosed) && (ioMode != 'o'))
      [self close];
    ioMode = 'o';
    return [self _open];
}

-openInputOnly
{
    if ((deviceStatus != MK_devClosed) && (ioMode != 'i'))
      [self close];
    ioMode = 'i';
    return [self _open];
}

-open
  /* Opens device if not already open.
     If already open, flushes output queue. 
     Sets deviceStatus to MK_devOpen. 
     Returns nil if failure.
     */
{
    if ((deviceStatus != MK_devClosed) && (ioMode != 'a'))
      [self close];
    ioMode = 'a';
    return [self _open];
}

-(double)localDeltaT
{
    return localDeltaT;
}

-setLocalDeltaT:(double)value
{
    localDeltaT = value;
    return self;
}

- run
{
    switch (deviceStatus) {
      case MK_devClosed:
	if (!openMidi(self))
	  return nil;
	/* no break here */
      case MK_devOpen:
/*	doDeltaT(self);  Needed if we'd ever use relative time to the driver */
	_timeOffset = MKGetTime(); /* This is needed by MidiOut. */
	/* no break here */
      case MK_devStopped:
	if (INPUTENABLED(ioMode)) 
	  listenToMIDI(self,YES);
	resumeMidiClock(self);
	deviceStatus = MK_devRunning;
      default:
	break;
    }
    return self;
}

-stop
{
    switch (deviceStatus) {
      case MK_devClosed:
	return [self open];
      case MK_devOpen:
      case MK_devStopped:
	return self;
      case MK_devRunning:
	stopMidiClock(self);
	if (INPUTENABLED(ioMode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(ioMode)) 
	    cancelQueueReq(self);
	deviceStatus = MK_devStopped;
      default:
	break;
    }
    return self;
}

-abort
{
    switch (deviceStatus) {
      case MK_devClosed:
	break;
      case MK_devRunning:
	if (INPUTENABLED(ioMode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(ioMode)) 
	    cancelQueueReq(self);
	/* No break here */
      case MK_devStopped:
      case MK_devOpen:
	if (OUTPUTENABLED(ioMode)) {
	    emptyMidi(self);
	}
	_pIn = (void *)_MKFinishMidiIn(MIDIINPTR(self));
	incomingDataCount = 0;
	_pOut = (void *)_MKFinishMidiOut(MIDIOUTPTR(self));
	closeMidiDev(self);
	deviceStatus = MK_devClosed;
    }
    return self;
}

- (void) close
  /* Need to ask for a message when queue is empty and wait for that message.
     */
{
    switch (deviceStatus) {
      case MK_devClosed:
	break;
      case MK_devRunning:
	if (INPUTENABLED(ioMode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(ioMode)) 
	    cancelQueueReq(self);
	/* No break here */
      case MK_devStopped:
      case MK_devOpen:
	if (INPUTENABLED(ioMode)) {
	    _pIn = (void *)_MKFinishMidiIn(MIDIINPTR(self));
	    incomingDataCount = 0;
	}
	if (OUTPUTENABLED(ioMode)) {
	    if (deviceStatus == MK_devRunning) 
		awaitMidiOutDone(self,MIDI_NO_TIMEOUT);
	    emptyMidi(self);
	    _pOut = (void *)_MKFinishMidiOut(MIDIOUTPTR(self));
	}
	closeMidiDev(self);
	deviceStatus = MK_devClosed;
    }
}

-awaitQueueDrain {
    if (deviceStatus == MK_devRunning) 
      awaitMidiOutDone(self,MIDI_NO_TIMEOUT);
    return self;
}

/* output configuration */

-setOutputTimed:(BOOL)yesOrNo
/* Controls whether MIDI commands are sent timed or untimed. The default
   is timed. It is permitted to change
   from timed to untimed during a performance. */
{
    outputIsTimed = yesOrNo;
    return self;
}

-(BOOL)outputIsTimed
  /* Returns whether MIDI commands are sent timed. */
{
    return outputIsTimed;
}


/* Receiving notes */

-_realizeNote:aNote fromNoteReceiver:aNoteReceiver
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
	if (self->tvs->synchConductor) {
	    t = ([self->tvs->synchConductor clockTime] - _timeOffset + localDeltaT + 
		 mtcTimeOffset);
	    if (MKGetDeltaTMode() == MK_DELTAT_DEVICE_LAG) 
	      t += MKGetDeltaT();
	}
	else 
	  t = MKGetDeltaTTime() - _timeOffset + localDeltaT;
    }
    else t = 0;
    chan = _MKParAsInt([aNoteReceiver _getData]);
    _MKWriteMidiOut(aNote,t,chan,MIDIOUTPTR(self),aNoteReceiver);
    return self;
}

/* Accessing NoteSenders and NoteReceivers */

-channelNoteSender:(unsigned)n
  /* Returns the MKNoteSender corresponding to the specified channel or nil
     if none. If n is 0, returns the MKNoteSender used for Notes fasioned
     from midi channel mode and system messages. */
{ 
    return (n > MIDI_NUMCHANS) ? nil : [noteSenders objectAtIndex:n];
}

-channelNoteReceiver:(unsigned)n
  /* Returns the NoteReceiver corresponding to the specified channel or nil
     if none. If n is 0, returns the NoteReceiver used for Notes fasioned
     from midi channel mode and system messages. */
{ 
    return (n > MIDI_NUMCHANS) ? nil : [noteReceivers objectAtIndex:n];
}

-noteSenders
  /* TYPE: Processing 
   * Returns a copy of the receiver's MKNoteSender List. 
   */
{
    return _MKLightweightArrayCopy(noteSenders);
//    return [[noteSenders copy] autorelease];  // Cause of problem?? LMS
}


-noteSender
  /* Returns the default MKNoteSender. This is used when you don't care
     which MKNoteSender you get. */
{
    return [noteSenders objectAtIndex:0];
}

- noteReceivers	
  /* TYPE: Querying; Returns a copy of the List of NoteReceivers.
   * Returns a copy of the List of NoteReceivers. The NoteReceivers themselves
   * are not copied.	
   */
{
    return _MKLightweightArrayCopy(noteReceivers);
}

-noteReceiver
  /* TYPE: Querying; Returns the receiver's first MKNoteReceiver.
   * Returns the first MKNoteReceiver in the receiver's NSArray.
   * This is particularly useful for MKInstruments that have only
   * one MKNoteReceiver.
   */
{
    return [noteReceivers objectAtIndex:0];
}

-setMergeInput:(BOOL)yesOrNo
{
    self->mergeInput = yesOrNo;
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
    int i;

    if (OUTPUTENABLED(ioMode) && deviceStatus != MK_devClosed) {
        _MK_MALLOC(dlsPatchArray, unsigned int, [dlsPatches count]);
        for(i = 0; i < [dlsPatches count]; i++)
            dlsPatchArray[i] = [[dlsPatches objectAtIndex: i] unsignedIntValue];
        MIDIDownloadDLSInstruments(dlsPatchArray, [dlsPatches count]);
        free(dlsPatchArray);
    }
}

#import "mtcMidi.m"

@end

#import "mtcMidiPrivate.m"

