/* Copyright Pinnacle Research, 1993, Stanford University */
#import "MKMidi.h" /*sb...*/

static double mangleTime(MKMidi *self,double driverTime)
{
    if (XVARS(self)->tvs->synchConductor)
      driverTime -= mtcTimeOffset;
    if (MKGetDeltaTMode() == MK_DELTAT_SCHEDULER_ADVANCE)
      driverTime += MKGetDeltaT();
    return driverTime;
}

- getMTCFormat:(short *)format hours:(short*)h min:(short *)m sec:(short *)s 
 frames:(short *)f;
	/* This only works if the receiver is in MTC synch mode.  Unlike 
	 * most of the Music Kit time methods and functions, this one gets the
	 * current time, whether or not [Conductor adjustTime] or 
	 * [Conductor lockPerformacne] was done.  if SCHEDULER_ADVANCE mode
	 * has been set, this time has deltaT added to it. 
	 */
{
    int r = MIDIGetMTCTime(XVARS(self)->devicePort,XVARS(self)->ownerPort,format,h,m,s,f);
    double seconds;
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		"getMTCFormat:");
    seconds = MKConvertMTCToSeconds(*format,*h,*m,*s,*f);
    seconds = mangleTime(self,seconds);
    MKConvertSecondsToMTC(seconds,*format,h,m,s,f);
    return self;
}

-(double)time
  /* Returns time according to the MIDI driver.  If deltaT mode is 
   * MK_DELTAT_SCHEDULER_ADVANCE, deltaT is added to this time.
   * If the receiver is providing time code for a Conductor, that 
   * Conductor's time offset is reflected in the time returned by this method.
   */
{
    int theTime;
    int r; 
    double t;
    if (deviceStatus == MK_devClosed)
      return 0;
    r = MIDIGetClockTime(XVARS(self)->devicePort,XVARS(self)->ownerPort,&theTime);
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		"time");
    t = theTime * _MK_MIDI_QUANTUM_PERIOD;
    return mangleTime(self,t);
}

-synchConductor
{
    return XVARS(self)->tvs->synchConductor;
}
