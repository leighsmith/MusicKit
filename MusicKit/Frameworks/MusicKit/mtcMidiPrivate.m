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
  Revision 1.9  2000/11/26 00:23:27  leigh
  Removed redundant functions midiAlarm and midiException

  Revision 1.8  2000/11/13 23:16:25  leigh
  Integrated tvs structure into MKMidi ivars

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
    if (!self->alarmTimeValid || 
	self->intAlarmTime != requestedTime) 
      /* Filter out old messages. E.g. it's possible that a message will have been
       * sent to the port and at the same time, we try to cancel it. */
      return;
    self->alarmPending = NO;
    self->alarmTimeValid = NO;
    [self->synchConductor _runMTC:self->alarmTime :actualTime * _MK_MIDI_QUANTUM_PERIOD];
}

static void my_exception_reply(mach_port_t replyPort, int exception)
{
    MKMidi *self = mtcMidi;
    if (!self)
	return;
    [self->synchConductor _MTCException:exception];
}
#endif

#else
#warning "Incomplete implementation of multiple MTC conductors."
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
    r = MKMDGetClockTime(devicePort, ownerPort, &theTime);
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r), "_time");
    t = theTime * _MK_MIDI_QUANTUM_PERIOD;
    if (self->synchConductor)
      t -= mtcTimeOffset;
    return t;
}

-_alarm:(double)requestedTime   
{
    int newIntTime;
    #define ISENDOFTIME(_x) (_x > (MK_ENDOFTIME - 1.0))
    if (ISENDOFTIME(requestedTime)) {
	if (deviceStatus == MK_devRunning) 
            MKMDRequestAlarm(devicePort, ownerPort, PORT_NULL, 0);
	self->alarmTimeValid = NO;
	self->alarmPending = NO;
	return self;
    }
    newIntTime = requestedTime * _MK_MIDI_QUANTUM;
    if (deviceStatus == MK_devRunning) {
	if (!self->alarmPending || 
	    self->intAlarmTime != newIntTime) {
	    MKMDRequestAlarm(devicePort, ownerPort, alarmPort, newIntTime);
	    self->alarmPending = YES;
	}
    }
    self->alarmTimeValid = YES;
    self->intAlarmTime = newIntTime;
    self->alarmTime = requestedTime;
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
	self->mtcMidiObj = self;
	self->synchConductor = aCond;
	mtcMidi = self;
    } else {
	if (mtcMidi == self) { 
	    self->mtcMidiObj = nil;
	    self->synchConductor = aCond;
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
    self->exceptionPort = [[NSPort port] retain];
    if (self->exceptionPort == nil) {
	_MKErrorf(MK_machErr,OPEN_ERROR, "Unable to open exceptionPort", "setUpMTC");
	return NO;
    }
    self->alarmPort = [[NSPort port] retain];
    if (self->alarmPort == nil) {
        _MKErrorf(MK_machErr,OPEN_ERROR, "Unable to open alarmPort", "setUpMTC");
        return NO;
    }
    self->alarmTimeValid = NO;
    self->alarmPending = NO;
    // 2nd arg was midiAlarm, changed to self as it handleMachMessage - LMS
    _MKAddPort(self->alarmPort, self, 0, self, _MK_DPSPRIORITY);
    // 2nd arg was midiException, changed to self as it handleMachMessage - LMS
    _MKAddPort(self->exceptionPort, self, 0, self, _MK_DPSPRIORITY);
    addedPortsCount += 2;
    return YES;
}

static BOOL tearDownMTC(MKMidi *self)
{
    MKMDRequestExceptions(self->devicePort, self->ownerPort, PORT_NULL);
    _MKRemovePort(self->exceptionPort);
    [self->exceptionPort release];
    /* Could call MKMDStopClock here? */
    MKMDRequestAlarm(self->devicePort, self->ownerPort, PORT_NULL, 0);
    self->alarmPending = NO;
    self->alarmTimeValid = NO;
    _MKRemovePort(self->alarmPort);
    addedPortsCount -= 2;
    [self->alarmPort release];
    return YES;
}

//static int resumeMidiClock(extraInstanceVars *ivars); /* Forward decl */


