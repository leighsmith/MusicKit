/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: musickit.h

  Description:
    MKMidi is made to look somewhat like a MKPerformer. It differs from a
    performer, however, in that it responds not to messages sent by a
    conductor, but by midi input which arives through the serial port.

    Note that the Conductor must be clocked to use MKMidi.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
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
  07/1/93/daj -  Added an arg to machErr for more descritptive error reporting.
  03/16/94/daj - Hacked to work around NEXTSTEP 3.2 libmididriver bug.
  09/7/94/daj -  Updated to not use libsys functions.
  10/31/98/lms - Major reorganization for OpenStep conventions, allocation and classes.
*/
/*sb: moved these to here from inside Midi class definition */
#import <objc/HashTable.h>
#import <mach/mach_error.h>
#import <servers/netname.h>
#import <ctype.h>  /* For isdigit() */
#import <Foundation/NSUserDefaults.h>

#if !m68k && !WIN32
#import <driverkit/IOConfigTable.h>
#import <driverkit/IODeviceMaster.h>
#import <driverkit/IODevice.h>
#endif
/* end sb move */

#import <mach/mach_init.h>
// #import <midi_driver_compatability.h> // LMS obsolete
#import "midi_driver.h"   
#import <AppKit/dpsclient.h>
#import <AppKit/NSDPSContext.h>

/* Music Kit include files */
#import "_musickit.h"
#import "tokens.h"
#import "_error.h"
#import "_ParName.h"
//#import "_NoteSender.h" TODO redundant as it's in MKNoteSender.h
#import "_midi.h"
#import "_time.h"
#import "ConductorPrivate.h"

#import "MidiPrivate.h"

@implementation MKMidi:NSObject

#define DEFAULT_SOFT_NAME @"midi0"

#define MIDIINPTR(midiobj) ((_MKMidiInStruct *)((MKMidi *)(midiobj))->_pIn)
#define MIDIOUTPTR(midiobj) ((_MKMidiOutStruct *)(midiobj)->_pOut)

#define VARIABLE 3

#define UNAVAIL_DRIVER_ERROR \
NSLocalizedStringFromTableInBundle(@"MIDI driver is unavailable. Perhaps another application is using it", _MK_ERRTAB, _MKErrorBundle(), "")

#define UNAVAIL_UNIT_ERROR \
NSLocalizedStringFromTableInBundle(@"MIDI serial port is unavailable. Perhaps another application is using the serial port", _MK_ERRTAB, _MKErrorBundle(), "")

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

/* Mach stuff */

/* Explanation of Intel support:

   On the DSP, we use "soft" integers to map to "hard" driver/unit pairs.
   Here, we pass in a device 'name' in the form "midiN", where N is an integer.
   On the NeXT hardware, "midi" is a "hard" driver name and "N" is a hard unit
   number.  So, to maintain backward compatibility, we keep this interface, but
   we consider "midi" to be a signal to use soft numbering.

   Therefore, the algorithm is:

   If we're running on an Intel machine, 
   look at root of name (everything up to the final integer).
   If it's "midi", assume the final number is "soft".
   Otherwise, if name is "Mididriver", use root as driver and int as unit.
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
   Intel machines.  Hence if the host machine (the one the Music Kit app 
   is running on) is an Intel machine, we ignore the hostName.  

   Also, if a NeXT host tries to access a MIDI driver on an intel machine, it
   will fail because there's no device "midiN" on Intel.
*/   

//sb: removed the following (now = method)
//static void midiIn(msg_header_t *msg,void *self); /* Forward ref */

static int deallocPort(portP)
    port_name_t *portP;
{
    int ec;
    if (*portP != PORT_NULL) {
	ec = port_deallocate(task_self(), *portP);
	if (ec != KERN_SUCCESS) {
	    return ec;
	}
	*portP  = PORT_NULL;
    }
    return KERN_SUCCESS;
}

static int addedPortsCount = 0;

static NSMutableDictionary *portTable = nil; // class variable

#define INPUTENABLED(_x) (_x != 'o')
#define OUTPUTENABLED(_x) (_x != 'i')

- (BOOL) unitHasMTC
{
    return (self->tvs->synchConductor && self->tvs->midiObj == self) ;
}

static char *midiDriverErrorString(int errorCode)
{
    return mach_error_string(errorCode);
}

/* Some mtc forward decls */
static double mtcTimeOffset = 0;
static int tearDownMTC(MKMidi *self);
static int setUpMTC(MKMidi *self);

+ (NSMutableArray *) midisOnHost: (NSString *) hostname otherThanUnit: (int) unit
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
        if ([midiObj->hostname isEqualToString: hostname] && (midiObj->unit != unit))
            [aList addObject:midiObj];
    }
    return aList;
}

static MKMidi *getMidiFromRecvPort(port_t aPort)
{
    MKMidi *midiObj;
    // This is inefficient, once we can do better compares we should use a search mechanism.
    // which has the port as the key
    NSEnumerator *enumerator = [portTable objectEnumerator];
    while ((midiObj = [enumerator nextObject])) {
        if (midiObj->recvPort == aPort)
            return midiObj;
    }
    return nil;
}

static int closeMidiDev(MKMidi *self)
{
    int somebodyElseHasOwnership = 0;
    NSMutableArray *otherUnits;

    if (!self->ownerPort)
	return KERN_SUCCESS;
    otherUnits = [MKMidi midisOnHost: self->hostname otherThanUnit: self->unit];
    MIDIReleaseUnit(self->devicePort,self->ownerPort,self->unit);
    if (INPUTENABLED(self->_mode)) {
	if (self->recvPort) {
	    _MKRemovePort(self->recvPort);
	    addedPortsCount--;
	    deallocPort(&self->recvPort);
	}
    }
    if (OUTPUTENABLED(self->_mode))  
	deallocPort(&self->queuePort);
    if ([self unitHasMTC])
      tearDownMTC(self);
    if ([otherUnits count] == 0) 
      somebodyElseHasOwnership = 0;
    else {
	MKMidi *aMidi;
	int i,cnt = [otherUnits count];
	for (i=0; i<cnt && !somebodyElseHasOwnership; i++) {
	    aMidi = [otherUnits objectAtIndex:i];
	    if (aMidi->ownerPort) 
	      somebodyElseHasOwnership = 1;
	}
    }
    if (somebodyElseHasOwnership)
      self->ownerPort = PORT_NULL;
    else {
	MIDIReleaseOwnership(self->devicePort,self->ownerPort);
	deallocPort(&self->ownerPort);
    } 
    [otherUnits release];
    /* Just being paranoic: */
    self->devicePort = PORT_NULL;
    self->recvPort = PORT_NULL;
    self->queuePort = PORT_NULL;
    return KERN_SUCCESS;
}

#define NO_UNIT (-1)

static int getNumSuffix(const char *s,BOOL *isSoftDev)
    /* Assumes s is valid string. Returns -1 if no final number found or if 
     * entire string is one number. Otherwise, returns number. */
{
    char *s2;
    int l = strlen(s);
    s2 = s+l-1;  /* Set to point to final char */
    while (isdigit(*s2) && (s2 != s))
      s2--;
    if (s2++ == s) {
	*isSoftDev = NO;
	return NO_UNIT;
    }
    *isSoftDev = (!strncmp("midi",s,4));
    return atoi(s2);
}

#if m68k
#define DRIVER_NAME @"mididriver"
#else
#define DRIVER_NAME @"Mididriver"   /* MD_NAME */
#endif

static int openMidiDev(MKMidi *self)
    /* "Opens". If the device represented by devicePortName is already 
       accessed by this task, uses the ownerPort currently accessed.
       Otherwise, if ownerPort is PORT_NULL, allocates a new
       port. Otherwise, uses ownerPort as specified. 
       To make the device truly public, you can pass the device port as the
       owner port.
       */
{
    int r;
    BOOL b;
    NSMutableArray *otherUnits;
    self->unit = getNumSuffix([self->midiDev cString],&b);
    r = netname_look_up(name_server_port, [self->hostname cString], [DRIVER_NAME cString],
			&(self->devicePort));
    if (r != KERN_SUCCESS) {
	self->devicePort = PORT_NULL;
	_MKErrorf(MK_machErr,NETNAME_ERROR,mach_error_string( r),"netname_look_up");
	return r;
    }
    otherUnits = [MKMidi midisOnHost: self->hostname otherThanUnit: self->unit];
    if ([otherUnits count]) {
	MKMidi *aMidi;
	int i;
        int cnt = [otherUnits count];
	for (i=0; i<cnt; i++) {
	    aMidi = [otherUnits objectAtIndex:i];
	    /* Should be the first one, but just in case... */
	    if (aMidi->ownerPort != PORT_NULL) {
            self->ownerPort = aMidi->ownerPort;
		break;
	    }
	}
    }
    [otherUnits release];
    if (!self->ownerPort) {
	r = port_allocate(task_self(), &self->ownerPort);
	if (r != KERN_SUCCESS) {
	    _MKErrorf(MK_machErr,OWNER_ERROR, mach_error_string( r),"openMidiDev owner port_allocate");
	    return r;
	}
	r = MIDIBecomeOwner(self->devicePort, self->ownerPort);
	if (r != KERN_SUCCESS) {
	    self->isOwner = NO;
	    _MKErrorf(MK_musicKitErr,UNAVAIL_DRIVER_ERROR);
	    closeMidiDev(self);
	    return r;
	}
    }
    r = MIDIClaimUnit(self->devicePort, self->ownerPort, self->unit);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_musicKitErr,UNAVAIL_UNIT_ERROR);
	closeMidiDev(self);
	return r;
    }

    r = MIDISetClockQuantum(self->devicePort, self->ownerPort, _MK_MIDI_QUANTUM);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_musicKitErr,OPEN_ERROR);
	closeMidiDev(self);
	return r;
    }

    r = MIDISetClockMode(self->devicePort, self->ownerPort, -1,
			 MIDI_CLOCK_MODE_INTERNAL);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_musicKitErr,OPEN_ERROR);
	closeMidiDev(self);
	return r;
    }

    /* Input */
    if (INPUTENABLED(self->_mode)) {
	r = port_allocate(task_self(), &self->recvPort);
	if (r != KERN_SUCCESS) {
	    _MKErrorf(MK_machErr,OPEN_ERROR,mach_error_string( r),
		      "openMidiDev recv port_allocate");
	    closeMidiDev(self);
	    return r;
	}
        _MKAddPort(self->recvPort,self,MSG_SIZE_MAX,self, /*sb: first self was midiIn. Changed to self
            						    * because 'self' responds to -handleMachMessage
            						    */
		   _MK_DPSPRIORITY);
//sb: if this is in main thread, NSRunLoop looks after incoming messages (see _MKAddPort). If it is not in the main thread, the port is added to the port set. From there, messages are caught by separateThreadLoop() (in lock.m). From there, they are sent as plain old objC messages. After all, we assume that if both this function AND the conductor are in the other thread, it's ok to send normal objC messages between them.

	addedPortsCount++;
    }
    if (OUTPUTENABLED(self->_mode)) {
	r = port_allocate(task_self(), &self->queuePort);
	if (r != KERN_SUCCESS) {
	    _MKErrorf(MK_machErr,OPEN_ERROR,mach_error_string( r),
		      "openMidiDev queue port_allocate");
	    closeMidiDev(self);
	    return r;
	}
	r = MIDIGetAvailableQueueSize(self->devicePort,
				      self->ownerPort,
				      self->unit,
				      &(self->queueSize));
	if (r != KERN_SUCCESS) {
	    _MKErrorf(MK_machErr,OPEN_ERROR,mach_error_string( r),
		      "MIDIGetAvailableQueueSize");
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
    static id timeInfoTable = nil;
    timeVars *p;
    if (!timeInfoTable) /* Mapping from hostname to tvs pointer */
      timeInfoTable = [HashTable newKeyDesc:"*" valueDesc:"!"];  // TODO convert to NSDictionary LMS
    if (p = [timeInfoTable valueForKey:(void *) [hostname cString]])
      return p;
    _MK_CALLOC(p,timeVars,1);
    return p;
}


static void waitForRoom(MKMidi *self,int elements,int timeOut)
{
    int r;
    MIDIReplyFunctions recvStruct = {0};
    r = MIDIRequestQueueNotification(self->devicePort,
				     self->ownerPort,
				     self->unit,
				     self->queuePort,
				     elements);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr,OUTPUT_ERROR,midiDriverErrorString(r),
		"waitForRoom queue notification request");
    r = MIDIAwaitReply(self->queuePort,&recvStruct,timeOut);
    /* THIS BLOCKS! */
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr,OUTPUT_ERROR,midiDriverErrorString(r),
		  "waitForRoom MIDIAwaitReply");
}

static void awaitMidiOutDone(MKMidi *self,int timeOut)
    /* Wait until Midi is done and then return */
{
    waitForRoom(self,self->queueSize,timeOut);
}

static int stopMidiClock(MKMidi *self)
{
    int r;
    if (self->tvs->synchConductor) {
	r = MIDIRequestExceptions(self->devicePort,self->ownerPort,
				  PORT_NULL);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		    "stopMidiClock MIDIRequestExceptions");
	r = MIDISetClockMode(self->devicePort,self->ownerPort,self->unit,
			     MIDI_CLOCK_MODE_INTERNAL);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		    "stopMidiClock MIDISetClockMode");
	r = MIDIRequestAlarm(self->devicePort,self->ownerPort,PORT_NULL,0);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		    "stopMidiClock MIDIRequestAlarm");
	self->tvs->alarmPending = NO;
	return r;
    }
    r = MIDIStopClock(self->devicePort,self->ownerPort);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		"stopMidiClock MIDIStopClock");
    return r;
}

static int resumeMidiClock(MKMidi *self)
{
    int r; 
    if (self->tvs->synchConductor) {
	r = MIDIRequestExceptions(self->devicePort,self->ownerPort,
				  self->tvs->exceptionPort);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		    "resumeMidiClock MIDIRequestExceptions");
	r = MIDISetClockMode(self->devicePort,self->ownerPort,self->unit,
			     MIDI_CLOCK_MODE_MTC_SYNC);
	if (r != KERN_SUCCESS)
	  _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		    "resumeMidiClock MIDISetClockMode");
	if (self->tvs->alarmTimeValid) {
	    r = MIDIRequestAlarm(self->devicePort,self->ownerPort,self->tvs->alarmPort,
				 self->tvs->alarmTime);
	    self->tvs->alarmPending = YES;
	    if (r != KERN_SUCCESS)
	      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
			"resumeMidiClock MIDIRequestAlarm");
	}
	return r;
    }
    r = MIDIStartClock(self->devicePort,self->ownerPort);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr,CLOCK_ERROR,
		midiDriverErrorString(r),"resumeMidiClock MIDIStartClock");
    return r;
}

static int resetAndStopMidiClock(MKMidi *self)
{
    int r;
    stopMidiClock(self);
    r = MIDISetClockTime(self->devicePort,self->ownerPort,0);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr,CLOCK_ERROR,
		midiDriverErrorString(r),"resetAndStopMidiClock");
    return r;
}

static int emptyMidi(MKMidi *self)
    /* Get rid of enqueued outgoing midi messages */
{
    int r;
    r = MIDIClearQueue(self->devicePort,self->ownerPort,self->unit);
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr,OUTPUT_ERROR,midiDriverErrorString(r),
		"emptyMidi");
    return r;
}

/* Defines for system ignores. */
#define IGNORE_CLOCK	 0x0100
#define IGNORE_START	 0x0400
#define IGNORE_CONTINUE	 0x0800
#define IGNORE_STOP	 0x1000
#define IGNORE_ACTIVE	 0x4000
#define IGNORE_RESET	 0x8000
#define IGNORE_REAL_TIME    0xdd00  /* All of the above */

#define FCC_DID_NOT_APPROVE_DRIVER_CHANGE 1 // TODO LMS

static int setMidiSysIgnore(MKMidi *self,unsigned bits)
    /* Tell driver to ignore particular incoming MIDI system messages */
{
#   if FCC_DID_NOT_APPROVE_DRIVER_CHANGE
    int r = MIDISetSystemIgnores(self->devicePort, self->ownerPort,
				 self->unit,bits);
#   else 
    int r = 0;
    r |= MIDIFilterMessage(self->devicePort, self->ownerPort, self->unit, 
			   MIDI_CLOCK, bits & IGNORE_CLOCK);
    r |= MIDIFilterMessage(self->devicePort, self->ownerPort, self->unit, 
			   MIDI_START, bits & IGNORE_START);
    r |= MIDIFilterMessage(self->devicePort, self->ownerPort, self->unit, 
			   MIDI_CONTINUE, bits & IGNORE_CONTINUE);
    r |= MIDIFilterMessage(self->devicePort, self->ownerPort, self->unit, 
			   MIDI_STOP, bits & IGNORE_STOP);
    r |= MIDIFilterMessage(self->devicePort, self->ownerPort, self->unit, 
			   MIDI_ACTIVE, bits & IGNORE_ACTIVE);
    r |= MIDIFilterMessage(self->devicePort, self->ownerPort, self->unit, 
			   MIDI_RESET, bits & IGNORE_RESET);
#   endif
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,INPUT_ERROR,
		midiDriverErrorString( r),"");
    return r;
}


/* Low-level output routines */

/* We currently use MIDI "raw" mode. Perhaps cooked mode would be more
   efficient? */

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
//    extraInstanceVars *ivars;
    MKMidi *midiObj;
    int nBytes;
    nBytes = bufPtr - &(midiBuf[0]);
    if (nBytes == 0)
	return;
    midiObj = ((MKMidi *)ptr->_owner);
//    ivars = midiObj->_extraVars;
    for (; ;) {
	r = MIDISendData(midiObj->devicePort,midiObj->ownerPort,midiObj->unit,
			 &(midiBuf[0]),nBytes);
	if (r == MIDI_ERROR_QUEUE_FULL) 
	    waitForRoom(midiObj,nBytes,MIDI_NO_TIMEOUT);
	else break;
    }
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr,OUTPUT_ERROR,midiDriverErrorString(r),
		  "sendBufferedData");
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
		ptr->_dataBytes = VARIABLE;
		return MIDI_SYSEXCL;
	      case MIDI_TUNEREQ:         
		ptr->_dataBytes = 0;
		return MIDI_TUNEREQ;
	      case MIDI_EOX: {          
		  BOOL isInSysEx = (ptr->_dataBytes == VARIABLE);
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
      case VARIABLE:
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

static void sendIncomingNote(short chan,id aNote,MKMidi *sendingMidi,int quanta)
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

static void my_data_reply(port_t reply_port, short unit, MIDIRawEvent *events, unsigned int count) {
    MKMidi *receivingMidi = getMidiFromRecvPort(reply_port);
    _MKMidiInStruct *ptr = MIDIINPTR(receivingMidi);
    id aNote;
    unsigned char statusByte;
    incomingDataCount = count; 
    for (; incomingDataCount--; events++) {
	if (statusByte = parseMidiByte(events->byte, ptr)) {
	    if (statusByte == MIDI_SYSEXCL) 
	      aNote = handleSysExclbyte(ptr,events->byte);
	    else 
	      aNote = _MKMidiToMusicKit(ptr,statusByte);
	    if (aNote) {
                sendIncomingNote(ptr->chan,aNote,receivingMidi,events->time);
		/* sending the Note can have unknown side-effects, since the
		 * user defines the behavior here.  For example, the Midi obj 
		 * could be aborted or re-opened. It could even be freed!
		 * So when we abort, we clear incomingDataCount.  This 
		 * guarantees that we won't be left in a bad state */
	    }
	}
    }
}

#if 0  // To remove LMS
static void midiIn(msg_header_t *msg,void *self)
    /* Called by driver when midi input occurs. */
{
    int r;
    MIDIReplyFunctions recvStruct =  
	{ /* Tells driver funcs to call */ my_data_reply,0,0,0};
//    extraInstanceVars *ivars = ((Midi *)self)->_extraVars;
    r = MIDIHandleReply(msg,&recvStruct);        /* This gets data */
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,INPUT_ERROR,
		midiDriverErrorString(r),"midiIn");
} 
#endif

/*sb: added the following method to handle mach messages. This replaces the function
 * above, because instead of DPSAddPort specifying a function,
 * DPSAddPort() replaced with:
 * [[NSPort portWithMachPort:] retain]
 * [nsport setDelegate:]
 * [nsrunLoop addPort:forMode:]
 *
 * The delegate has to repond to selector -handleMachMessage or -handlePortMessage
 */

- (void)handleMachMessage:(void *)machMessage
{
    msg_header_t *msg = (msg_header_t *)machMessage;
    int r;
    MIDIReplyFunctions recvStruct =
        { /* Tells driver funcs to call */ my_data_reply,0,0,0};
//    extraInstanceVars *ivars = ((Midi *)self)->_extraVars;
    r = MIDIHandleReply(msg,&recvStruct);        /* This gets data */
    if (r != KERN_SUCCESS)
      _MKErrorf(MK_machErr,INPUT_ERROR,
                midiDriverErrorString(r),"midiIn");
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
//#   define CONDUCTOR (((extraInstanceVars *)_extraVars)->conductor)    
#   define CONDUCTOR (self->conductor)    
    return CONDUCTOR ? CONDUCTOR : [_MKClassConductor() clockConductor];
}

-setConductor:aConductor
{
//    (((extraInstanceVars *)_extraVars)->conductor) = aConductor;
    self->conductor = aConductor;
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
 */

static NSString **midiDriverNames = NULL;
static int *midiDriverUnits = NULL;
static int midiDriverCount = 0;

// Return YES if able to initialise for the driverKit MIDI driver,
// NO if there was no MIDI driver found. 
static BOOL initDriverKitBasedMIDIs(void)
{
    char *s;
    const char *familyStr;
#ifndef WIN32
    List *installedDrivers;
#endif
    NSMutableArray *midiDriverList;
    id aConfigTable;
    int i;
    static BOOL driverInfoInitialized = NO;

    if (driverInfoInitialized) { /* Already initialized */
	return YES;
    }
    else
        driverInfoInitialized = YES;
#if  i386  && !WIN32
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
    for (i=0; i < [installedDrivers count]; i++) {
        aConfigTable = [installedDrivers objectAt:i]; 	/* Each driver */
        familyStr = [aConfigTable valueForStringKey:"Family"];
//        fprintf(stderr, "%s\n", [aConfigTable valueForStringKey: "Driver Name"]);
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
    midiDriverNames = (NSString **) malloc(sizeof(NSString *) * midiDriverCount);
    midiDriverUnits = (int *) malloc(sizeof(int) * midiDriverCount);
    for (i=0; i < midiDriverCount; i++) {
	/* Or "Server Name"? */
	aConfigTable = [midiDriverList objectAtIndex:i];
        midiDriverNames[i] = [[NSString stringWithCString:(char *)[aConfigTable valueForStringKey:"Class Names"]] retain];
	s = (char *)[aConfigTable valueForStringKey:"Instance"];
	midiDriverUnits[i] = s ? atoi(s) : 0;
    }
#elif ppc
    // hardwire this for MOXS1.0 until tablesForInstalledDrivers gives us what we expect
    midiDriverCount = 1;
    midiDriverNames = (NSString **) malloc(sizeof(NSString *) * midiDriverCount);
    midiDriverUnits = (int *) malloc(sizeof(int) * midiDriverCount);
    for (i=0; i < midiDriverCount; i++) {
        midiDriverNames[i] = @"Mididriver";
        midiDriverUnits[i] = 0;
    }
#endif
    return YES;
}

static NSDictionary *MKMIDIDefaults = nil;

static BOOL mapSoftNameToDriverNameAndUnit(NSString *devName,NSString **midiDevStrArr)
    /* Maps a name of the form "midi0" to a name of the form "Mididriver2".
     * See above long explanation.  Returns copy of hard name.
     */
{
    NSString *midiNumStrArr;
    static int defaultsInitialized = 0;
    int i;
    BOOL isSoft;
    NSString *defaultsValue;
    int num = getNumSuffix([devName cString], &isSoft);
    NSUserDefaults *ourDefaults = [NSUserDefaults standardUserDefaults];
    if (MKMIDIDefaults == nil) MKMIDIDefaults = [[NSDictionary dictionaryWithObjectsAndKeys:
        @"",@"MIDI0",
        @"",@"MIDI1",
        @"",@"MIDI2",
        @"",@"MIDI3",
        @"",@"MIDI4",
        @"",@"MIDI5",
        @"",@"MIDI6",
        @"",@"MIDI7",
        @"",@"MIDI8",
        @"",@"MIDI9",
        @"",@"MIDI10",
        @"",@"MIDI11",
        @"",@"MIDI12",
        @"",@"MIDI13",
        @"",@"MIDI14",
        @"",@"MIDI15",
        NULL,NULL] retain];

    if (isSoft) {
        midiNumStrArr = [NSString stringWithFormat:@"MIDI%d",num];
            
//#error DefaultsConversion: NXRegisterDefaults() is obsolete. Construct a dictionary of default registrations and use the NSUserDefaults 'registerDefaults:' method
//	  NXRegisterDefaults("MusicKit", MKMIDIDefaults);
// LMS - Unfortunately, this is the case, as the owner will be whatever application links against this framework.
        if (!defaultsInitialized)
            [ourDefaults registerDefaults:MKMIDIDefaults];//stick these in the temporary area that is searched last.

	defaultsInitialized = 1;
//#warning DefaultsConversion: This used to be a call to NXGetDefaultValue with the owner "MusicKit".  If the owner was different from your applications name, you may need to modify this code.
// LMS - Unfortunately, this is the case, as the owner will be whatever application links against this framework.
	defaultsValue =
            (NSString *)[ourDefaults objectForKey:midiNumStrArr];
	if ([defaultsValue length]) 
	  num = getNumSuffix([defaultsValue cString], &isSoft);
	else if (num == 0) { /* Just use any one we can find */
            *midiDevStrArr = [[NSString stringWithFormat:@"%@0",DRIVER_NAME] retain];
	  return YES;
	}
    }
    /* Otherwise, just use soft number as a hard number */
    *midiDevStrArr = [NSString stringWithFormat:@"%@%d",DRIVER_NAME,num];

    initDriverKitBasedMIDIs();
    for (i=0; i < midiDriverCount; i++) {
        if (([DRIVER_NAME isEqualToString:midiDriverNames[i]]) && 
	    (midiDriverUnits[i] == num))
	  return YES;
    }
    return NO;
}

+(int)getDriverNames:(NSString ***)driverNames units:(int **)driverUnits
  /* Creates new arrays and copies driverNames and units into them.
   * Returns size of array.
   * sb: err, no. Just returns by reference the addresses at which the
   * info is stored. Doesn't allocate more space or copy anything.
   */
{
    initDriverKitBasedMIDIs();
    *driverNames = midiDriverNames;
    *driverUnits = midiDriverUnits;
    return midiDriverCount;
}


#if 0
+(int)getInUseDriverNames:(char ***)driverNames units:(int **)driverUnits
  /* Creates new arrays and copies driverNames and units into them.
   * Returns size of array.
   */
{
    initDriverKitBasedMIDIs();
    *driverNames = inUseDriverNames;
    *driverUnits = inUseDriverUnits;
    return MK_MAXMIDIS;
}
#endif

#endif

-(NSString *)driverName 
{
    return midiDev;
}

-(int)driverUnit
{
    return self->unit;
}

// Here we initialize our class variables.
+ (void) initialize
{
   portTable = [NSMutableDictionary dictionary];
   [portTable retain];
}

// This is where all the initialisation is performed.
- initOnDevice:(NSString *) devName hostName:(NSString *) hostName
{
#if !m68k
    NSString *midiDevStrArr;
#endif
    MKMidi *obj;
    NSString *hostAndDevName;
    id aNoteSender,aNoteReceiver;
    int i;
    _MKParameter *aParam;

#if !m68k
    hostName = @""; /* See extensive comment above */
    if (!mapSoftNameToDriverNameAndUnit(devName,&midiDevStrArr))
      return nil;
    devName = midiDevStrArr;
#endif
    hostAndDevName = [hostName stringByAppendingString: devName];
    if ((obj = [portTable objectForKey: hostAndDevName]) == nil) {         // Doesn't already exist
//        _MK_CALLOC(self->_extraVars,extraInstanceVars,1);
        self->hostname = [hostName copy];
        self->tvs = getTimeInfoFromHost(hostName);
        self->midiDev = [devName retain];
        [portTable setObject:self forKey: hostAndDevName]; 
    }

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
                        to use Midi without Notes. (?) FIXME */
     _MKClassOrchestra(); /* Force find-class here */
     _mode = 'a';
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
    self = [self alloc]; // Problem? LMS [Midi alloc]??
    [self initOnDevice: devName hostName: hostName];
    return self;
}

+ midiOnDevice:(NSString *) devName
{
    self = [self alloc]; // Problem? LMS [Midi alloc]??
    [self initOnDevice:devName];
    return self;
}

+ midi
{
    return [self midiOnDevice: DEFAULT_SOFT_NAME];
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
    int i,size = [noteReceivers count];
    [self abort];
    if ([self unitHasMTC]) 
      [self->tvs->synchConductor _setMTCSynch:nil];
    [self _setSynchConductor:nil];
    for (i=0; i<size; i++)
        _MKFreeParameter([[noteReceivers objectAtIndex:i] _getData]);
    [noteReceivers makeObjectsPerformSelector:@selector(disconnect)];
    [noteReceivers removeAllObjects];  
    [noteReceivers release];
    [noteSenders makeObjectsPerformSelector:@selector(disconnect)];
    [noteSenders removeAllObjects];  
    [noteSenders release];
    [portTable removeObjectForKey:midiDev];
//    free(_extraVars);
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
    if (INPUTENABLED(self->_mode))
      if (!(self->_pIn = (void *)_MKInitMidiIn()))
	return nil;
      else setMidiSysIgnore(self,self->_ignoreBits);
    if (OUTPUTENABLED(self->_mode)) {
	if (!(self->_pOut = (void *)_MKInitMidiOut()))
	  return nil;
	{
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

static void sleepMs(int ms) {
    port_t aPort;
    struct {
	msg_header_t header;
    } null_msg;
    if (port_allocate(task_self(),&aPort) != KERN_SUCCESS)
      return;
    null_msg.header.msg_local_port = aPort;
    null_msg.header.msg_size = sizeof(null_msg);
    (void)msg_receive((msg_header_t *)&null_msg, RCV_TIMEOUT, ms);
    (void)port_deallocate(task_self(),aPort);
}

-allNotesOff
   /* This is a conservative version of allNotesOff.  It only sends
    * noteOffs for notes if those notes are sounding.
    * The notes are sent immediately (but will be
    * queued behind any notes that have already been queued up.)
    */
{
    id aList;
    int i,cnt,j;
    if (!MIDIOUTPTR(self) || deviceStatus != MK_devRunning)
      return nil;
    MIDIFlushQueue(self->devicePort,self->ownerPort,self->unit);
    /* Not ClearQueue, which can leave MIDI devices confused. */
    for (i=1; i<=MIDI_NUMCHANS; i++) {
	aList = _MKGetNoteOns(MIDIOUTPTR(self),i);
	for (j=0, cnt = [aList count]; j<cnt; j++)
            _MKWriteMidiOut([aList objectAtIndex:j],0,i,MIDIOUTPTR(self),
			  [self channelNoteReceiver:i]);
	MIDIFlushQueue(self->devicePort,self->ownerPort,self->unit);
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
    if (deviceStatus == MK_devClosed || !OUTPUTENABLED(_mode))
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
    MIDIFlushQueue(self->devicePort,self->ownerPort,self->unit);
    /* Not ClearQueue, which can leave MIDI devices confused. */
    for (i=0; i<16; i++) {       
	int j,k;
	chan = i;
	tmpMidiBuf[0].time = 0;
	tmpMidiBuf[0].byte = MIDI_NOTEOFF | chan;
	for (j=0; j < 257; j += MIDI_MAX_EVENT) {
	    k = 257 - j;
	    for (; ;) {
		r = MIDISendData(self->devicePort,self->ownerPort,
				 self->unit,&(tmpMidiBuf[j]),
				 MIN(MIDI_MAX_EVENT,k));
	        if (r != MIDI_ERROR_QUEUE_FULL)
		    break;
		sleepMs(k/3);   /* MIDI goes at a rate of a byte every 1/3 ms */
	    }
	    MIDIFlushQueue(self->devicePort,self->ownerPort,self->unit);
	    sleepMs(_MKAllNotesOffPause);   /* Slow it down so synths don't freak out */
	}
	MIDIFlushQueue(self->devicePort,self->ownerPort,self->unit);
	if (r != KERN_SUCCESS) {
	    _MKErrorf(MK_machErr,OUTPUT_ERROR,
		      midiDriverErrorString(r),"allNotesOffBlast");
	    return nil;
	}
    }
    awaitMidiOutDone(self,5000);
    return self;
}

static void listenToMIDI(MKMidi *self,BOOL flg)
{
    int r;
    r = MIDIRequestData(self->devicePort,self->ownerPort,self->unit,
			(flg) ? self->recvPort : PORT_NULL);
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr,INPUT_ERROR,midiDriverErrorString(r),
		  "listenToMIDI");
}

static void cancelQueueReq(MKMidi *self)
{
    int r;
    r = MIDIRequestQueueNotification(self->devicePort,self->ownerPort,
				     self->unit,PORT_NULL,0);
    if (r != KERN_SUCCESS) 
	_MKErrorf(MK_machErr,INPUT_ERROR,midiDriverErrorString(r),
		  "cancelQueueReq");
}

-_open
{
    switch (deviceStatus) {
      case MK_devClosed: /* Need to open it */
	return openMidi(self);
      case MK_devOpen:
	break;
      case MK_devRunning:
	if (INPUTENABLED(_mode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(_mode)) 
	    cancelQueueReq(self);
	/* no break here */
      case MK_devStopped:
	if (OUTPUTENABLED(_mode))
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
    if ((deviceStatus != MK_devClosed) && (_mode != 'o'))
      [self close];
    _mode = 'o';
    return [self _open];
}

-openInputOnly
{
    if ((deviceStatus != MK_devClosed) && (_mode != 'i'))
      [self close];
    _mode = 'i';
    return [self _open];
}

-open
  /* Opens device if not already open.
     If already open, flushes output queue. 
     Sets deviceStatus to MK_devOpen. 
     Returns nil if failure.
     */
{
    if ((deviceStatus != MK_devClosed) && (_mode != 'a'))
      [self close];
    _mode = 'a';
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
	if (INPUTENABLED(_mode)) 
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
	if (INPUTENABLED(_mode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(_mode)) 
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
	if (INPUTENABLED(_mode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(_mode)) 
	    cancelQueueReq(self);
	/* No break here */
      case MK_devStopped:
      case MK_devOpen:
	if (OUTPUTENABLED(_mode)) {
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

- (void)close
  /* Need to ask for a message when queue is empty and wait for that message.
     */
{
    switch (deviceStatus) {
      case MK_devClosed:
	break;
      case MK_devRunning:
	if (INPUTENABLED(_mode)) 
	    listenToMIDI(self,NO);
	if (OUTPUTENABLED(_mode)) 
	    cancelQueueReq(self);
	/* No break here */
      case MK_devStopped:
      case MK_devOpen:
	if (INPUTENABLED(_mode)) {
	    _pIn = (void *)_MKFinishMidiIn(MIDIINPTR(self));
	    incomingDataCount = 0;
	}
	if (OUTPUTENABLED(_mode)) {
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
  /* TYPE: Querying; Returns the receiver's first NoteReceiver.
   * Returns the first NoteReceiver in the receiver's List.
   * This is particularly useful for Instruments that have only
   * one NoteReceiver.
   */
{
    return [noteReceivers objectAtIndex:0];
}

-setMergeInput:(BOOL)yesOrNo
{
    self->mergeInput = yesOrNo;
    return self;
}

#import "mtcMidi.m"

@end

#import "mtcMidiPrivate.m"

