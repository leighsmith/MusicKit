/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file factored out of MKConductor.m for purposes of separate copyright and
    to isolate MIDI time code functions.
    This file contains the MTCPrivate category of Conductor.

  Original Author: David Jaffe

  Copyright (c) Pinnacle Research, 1993
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.7  2000/06/09 14:51:53  leigh
  Removed objc.h

  Revision 1.6  2000/04/01 01:15:12  leigh
  Removed redundant MSG_SIZE_MAX definitions (which have gone under MacOsX)

  Revision 1.5  2000/01/27 19:03:36  leigh
  Now using NSPort replacing C Mach port API

  Revision 1.4  1999/11/14 21:30:49  leigh
  Corrected _MKErrorf arguments to be NSStrings

  Revision 1.3  1999/08/08 01:59:22  leigh
  Removed extraVars cruft

  Revision 1.2  1999/07/29 01:26:10  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#import <Foundation/Foundation.h>

#if _MK_ONLY_ONE_MTC_SUPPORTED

static MKMidi *mtcMidi = nil;

// LMS these will no longer be called due to the change to handleMachMessage. We should call them from the handler or 
// incorporate their functionality into the handler.
#if 0
static void my_alarm_reply(mach_port_t replyPort, int requestedTime, int actualTime)
{
    MKMidi *self = mtcMidi;
    if (!self)
	return;
    if (!self->tvs->alarmTimeValid || 
	self->tvs->intAlarmTime != requestedTime) 
      /* Filter out old messages. E.g. it's possible that a message will have been
       * sent to the port and at the same time, we try to cancel it. */
      return;
    self->tvs->alarmPending = NO;
    self->tvs->alarmTimeValid = NO;
    [self->tvs->synchConductor _runMTC:self->tvs->alarmTime :actualTime * _MK_MIDI_QUANTUM_PERIOD];
}

static void my_exception_reply(mach_port_t replyPort, int exception)
{
    MKMidi *self = mtcMidi;
    if (!self)
	return;
    [self->tvs->synchConductor _MTCException:exception];
}
#endif

#else
#warning "Incomplete implementation of multiple MTC conductors."
#endif

// LMS these will no longer be called due to the change to handleMachMessage. We should incorporate their functionality
// into the handler.
#if 0
static void midiAlarm(msg_header_t *msg,void *self)
   /* Called by driver when midi alarm occurs. */
{
    int r;
    MIDIReplyFunctions recvStruct = {0,my_alarm_reply,0,0};
    r = MIDIHandleReply(msg,&recvStruct); 
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"midiAlarm");
} 

static void midiException(msg_header_t *msg,void *self)
   /* Called by driver when midi exception occurs. */
{
    int r;
    MIDIReplyFunctions recvStruct = {0,0,my_exception_reply,0};
    r = MIDIHandleReply(msg,&recvStruct); 
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr, CLOCK_ERROR, midiDriverErrorString(r), @"midiException");
} 
#endif

@implementation MKMidi(Private)

+(BOOL)_disableThreadChange
{
    return addedPortsCount != 0;
}

-_setMTCOffset:(double)offset
  /* Time offset is the MTC time that corresponds with 0 clockTime.
   * E.g. offset 10 means that MTC is assumed to start at 10 seconds. 
   */
{
    mtcTimeOffset = offset;
    return self;
}

-(double)_time
  /* Same as -time, but doesn't add in deltaT in SCHEDULER_ADVANCE mode */
{
    int theTime;
    int r; 
    double t;
    if (deviceStatus == MK_devClosed)
      return 0;
    r = MIDIGetClockTime([self->devicePort machPort], [self->ownerPort machPort], &theTime);
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r), "_time");
    t = theTime * _MK_MIDI_QUANTUM_PERIOD;
    if (self->tvs->synchConductor)
      t -= mtcTimeOffset;
    return t;
}

-_alarm:(double)requestedTime   
{
    int newIntTime;
    #define ISENDOFTIME(_x) (_x > (MK_ENDOFTIME - 1.0))
    if (ISENDOFTIME(requestedTime)) {
	if (deviceStatus == MK_devRunning) 
	  MIDIRequestAlarm([self->devicePort machPort], [self->ownerPort machPort], PORT_NULL, 0);
	self->tvs->alarmTimeValid = NO;
	self->tvs->alarmPending = NO;
	return self;
    }
    newIntTime = requestedTime * _MK_MIDI_QUANTUM;
    if (deviceStatus == MK_devRunning) {
	if (!self->tvs->alarmPending || 
	    self->tvs->intAlarmTime != newIntTime) {
	    MIDIRequestAlarm([self->devicePort machPort], [self->ownerPort machPort],
			     [self->tvs->alarmPort machPort], newIntTime);
	    self->tvs->alarmPending = YES;
	}
    }
    self->tvs->alarmTimeValid = YES;
    self->tvs->intAlarmTime = newIntTime;
    self->tvs->alarmTime = requestedTime;
    return self;
}

- _setSynchConductor:aCond
  /* If status is closed, just store synchConductor.  
   * Otherwise set up alarm and exception ports.
   * The Conductor method that calls this ensures that
   * _setSynchConductor:nil is sent to anyone holding
   * the synch before _setSynchConductor:<non-nil> is sent.
   * Hence, we don't need to worry about that here.
   *
   * But MIDI's free can also call this with nil, so 
   * we have to be slightly more careful in this case
   * (i.e. we can't assume that we have the synch)
   */
{
    /* References to mtcMidi below will change if we ever support more than one synch */
    if (aCond) {
	self->tvs->midiObj = self;
	self->tvs->synchConductor = aCond;
	mtcMidi = self;
    } else {
	if (mtcMidi == self) { 
	    self->tvs->midiObj = nil;
	    self->tvs->synchConductor = aCond;
	    mtcMidi = nil;
	}
    }
    if (deviceStatus == MK_devClosed) /* We'll set up later */
      return self;
    if (aCond) {
	setUpMTC(self);
	if (deviceStatus == MK_devRunning)
	  resumeMidiClock(self);
    }
    else tearDownMTC(self);
    return self;
}

@end

static BOOL setUpMTC(MKMidi *self)
{
    self->tvs->exceptionPort = [[NSPort port] retain];
    if (self->tvs->exceptionPort == nil) {
	_MKErrorf(MK_machErr,OPEN_ERROR, "Unable to open exceptionPort", "setUpMTC");
	return NO;
    }
    self->tvs->alarmPort = [[NSPort port] retain];
    if (self->tvs->alarmPort == nil) {
        _MKErrorf(MK_machErr,OPEN_ERROR, "Unable to open alarmPort", "setUpMTC");
        return NO;
    }
    self->tvs->alarmTimeValid = NO;
    self->tvs->alarmPending = NO;
    // 2nd arg was midiAlarm, changed to self as it handleMachMessage - LMS
    _MKAddPort(self->tvs->alarmPort, self, 0, self, _MK_DPSPRIORITY);
    // 2nd arg was midiException, changed to self as it handleMachMessage - LMS
    _MKAddPort(self->tvs->exceptionPort, self, 0, self, _MK_DPSPRIORITY);
    addedPortsCount += 2;
    return YES;
}

static BOOL tearDownMTC(MKMidi *self)
{
    MIDIRequestExceptions([self->devicePort machPort], [self->ownerPort machPort], PORT_NULL);
    _MKRemovePort(self->tvs->exceptionPort);
    [self->tvs->exceptionPort release];
    /* Could call MIDIStopClock here? */
    MIDIRequestAlarm([self->devicePort machPort], [self->ownerPort machPort], PORT_NULL, 0);
    self->tvs->alarmPending = NO;
    self->tvs->alarmTimeValid = NO;
    _MKRemovePort(self->tvs->alarmPort);
    addedPortsCount -= 2;
    [self->tvs->alarmPort release];
    return YES;
}

//static int resumeMidiClock(extraInstanceVars *ivars); /* Forward decl */


