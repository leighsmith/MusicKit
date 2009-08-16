/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file factored out of MKConductor.m for purposes of separate copyright and
    to isolate MIDI time code functions.
    This file contains the MTCPrivate category of MKConductor.

  Original Author: David Jaffe

  Copyright (c) Pinnacle Research, 1993
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2004 The MusicKit Project.
*/
#import <Foundation/Foundation.h>

#if _MK_ONLY_ONE_MTC_SUPPORTED

static MKMidi *mtcMidi = nil;

// LMS TODO these will no longer be called due to the change to handleMachMessage. We should call them from the handler or 
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
    if (r != MKMD_SUCCESS)
        MKErrorCode(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r), "_time");
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
            MKMDRequestAlarm(devicePort, ownerPort, MKMD_PORT_NULL, 0);
	self->alarmTimeValid = NO;
	self->alarmPending = NO;
	return self;
    }
    newIntTime = requestedTime * _MK_MIDI_QUANTUM;
    if (deviceStatus == MK_devRunning) {
	if (!self->alarmPending || 
	    self->intAlarmTime != newIntTime) {
            MKMDRequestAlarm(devicePort, 
			     ownerPort,
			     (MKMDReplyPort) [alarmPort machPort], newIntTime);
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
	mtcMidiObj = self;
	synchConductor = aCond;
	mtcMidi = self;
    }
    else {
	if (mtcMidi == self) { 
	    mtcMidiObj = nil;
	    synchConductor = aCond;
	    mtcMidi = nil;
	}
    }
    if (deviceStatus == MK_devClosed) /* We'll set up later */
      return self;
    if (aCond) {
	[self setUpMTC];
	if (deviceStatus == MK_devRunning)
	  resumeMidiClock(self);
    }
    else
	[self tearDownMTC];
    return self;
}

- (BOOL) setUpMTC
{
    exceptionPort = [[NSPort port] retain];
    if (exceptionPort == nil) {
	MKErrorCode(MK_machErr,OPEN_ERROR, @"Unable to open exceptionPort", @"setUpMTC");
	return NO;
    }
    alarmPort = [[NSPort port] retain];
    if (alarmPort == nil) {
        MKErrorCode(MK_machErr,OPEN_ERROR, @"Unable to open alarmPort", @"setUpMTC");
        return NO;
    }
    alarmTimeValid = NO;
    alarmPending = NO;
    addedPortsCount += 2;
    return YES;
}

- (BOOL) tearDownMTC
{
    MKMDRequestExceptions(devicePort, ownerPort, MKMD_PORT_NULL);
    [exceptionPort release];
    /* Could call MKMDStopClock here? */
    MKMDRequestAlarm(devicePort, ownerPort, MKMD_PORT_NULL, 0);
    alarmPending = NO;
    alarmTimeValid = NO;
    [alarmPort release];
    return YES;
}

@end

//static int resumeMidiClock(extraInstanceVars *ivars); /* Forward decl */


