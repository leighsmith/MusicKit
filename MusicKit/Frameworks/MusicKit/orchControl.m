/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is imported as source by MKOrchestra.m.
    It contains the methods -open, -stop, -run, -close and -abort:

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.15  2001/12/07 20:13:04  skotmcdonald
  Dealt with a minor typing warning

  Revision 1.14  2001/11/07 13:02:47  sbrandon
  removed unnecessary prototype for _DSPError1

  Revision 1.13  2001/09/12 14:00:44  sbrandon
  changed -cString to -fileSystemRepresentation

  Revision 1.12  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.11  2001/05/12 09:35:19  sbrandon
  - GNUSTEP: don't import mach headers

  Revision 1.10  2000/04/26 01:19:24  leigh
  outputCommandsFile now an NSString

  Revision 1.9  2000/04/07 18:44:51  leigh
  Upgraded logging to NSLog

  Revision 1.8  2000/04/01 01:13:56  leigh
  Converted to NSPort operation

  Revision 1.7  2000/03/31 00:07:48  leigh
  Added SBs notes

  Revision 1.6  2000/03/07 18:19:17  leigh
  Removed redundant getTime function (using NSDate nowdays)

  Revision 1.5  2000/02/03 19:12:22  leigh
  Renamed for MKDSP framework

  Revision 1.4  2000/01/27 19:01:47  leigh
  updated Mach port to NSPorts (even though the code is currently commented out

  Revision 1.3  2000/01/19 19:55:07  leigh
  Replaced mach port based millisecond timing with NSThread approach

  Revision 1.2  1999/07/29 01:26:13  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  01/30/90/daj - Created from MKOrchestra.m.
  01/31/90/daj - Changed select() to msg_receive() for uniformity with 
                 the rest of the Music Kit.
  02/15/90/daj - Changed order of events in re-open in -open. 
                 Removed wait for IDLE. 
                 Added reset of time to 0.
                 Added SOFTREOPEN compile switch
  02/16/90/daj - Changed -close to insert less 0s at the end of write data
                 (and soundout). Previously, we inserted many 0s because we 
                 had a libdsp bug in write data, but Julius says this is fixed.
                 Both cases (write data and sound out) need to be tested!
                 TESTME
  03/21/90/daj - Added work-around for pause/resume driver bug. But did not
                 enable the work-around. Set USEFREEZE to 0 to enable 
                 work-around.
  03/23/90/mtm - Added support for DSP commands file in -open and -close.
  03/26/90/mtm - -close no longer sends abort host message when closing
                 DSP commands file.
  03/28/90/mtm - outputDSPCommandsSoundfile -> outputCommandsFile
  03/30/90/mtm - Close commandsfile in -abort.
  03/30/90/daj - Added further support for USEFREEZE == 0
  03/28/90/daj - Added read data API support. 
  03/27/90/mmm - Added adjustOrchTE to this version
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/23/90/daj - Changed callse to _pause to be _pause: to fix bug in 
                 _OrchloopbeginUG.
  04/25/90/daj - Changed arg order in calls to DSPWriteValue, to conform
                 with new libdsp api.
  04/27/90/daj - Added call to DSPEnableErrorFile() conditional upon -DDEBUG.
  04/05/90/daj - Replaced call to DSPMemoryClear() with 
                 DSPMKClearDSPSoundOutBufferTimed(). Replaced call to
                 DSPMKWriteLong() with DSPMKSetTime(). 
		 Added setting of new instance variables 
		 _bottomOfExternalMemory and _topOfExternalMemory as well as 
		 the argument partition sizes.
                 Substituted DSPMKGetClipCountAddress() for DSPMK_X_NCLIP. 
		 Renamed ORCHSYSLOC to ORCHLOOPLOC.
  06/10/90/daj - Changed USEFREEZE to 0
  08/17/90/daj - Added more conditional compilation code to make it so
                 if the pause/resume driver bug gets fixed, then the
		 MKOrchestra will correctly start on a dime with its buffers
		 full.
  09/26/90/daj - For dsp-18, need to change DSPMKGetClipCountAddress() to 
                 DSPMKGetClipCountXAddress() to correspond to new libdsp
		 API. Changed USEFREEZE to 1.

  10/04/90/daj - Changed USEFREEZE to 0 because pause of sound out causes panic.
  12/19/90/daj - Fixed endTime calculation in -close.
  02/08/91/daj - Put in kludge to fix bug in libdsp (disable this for dsp-18).
  07/10/91/daj - Changed to make synchToConductor: safer.
  09/26/90/daj - For dsp-18, changed DSPMKGetClipCountAddress() (see above)
  11/30/92/jos - Change to awaitEndOfTime() to fix possible deadlock.
  12/16/92/daj - Changes to support serialSoundOut.
   2/13/93/daj - Added 1/2 srate support, put in hooks for quad.
   2/28/93/daj - Added quint board support.  Note:  Moved DSPMKStartAtAddress
                 to after DSPMKResumeOrchestra.
   3/18/93/daj - Removed usage of DSPMKInit().
   7/23/93/daj - Changed SOFTREOPEN to 0 again, since it doesn't seem to work!
   10/12/93/daj - Changes for QP. Got rid of LIBDSP_ENDOFTIME_BUG (made it 
                  always that way!)
   2/7/94/daj - Added support for non-overlaid memory.
   6/27/94/jos - Added support for .lod files in app wrapper
   6/29/94/daj - Fixed /usr/local/lib/dsp/monitor file search.
   11/19/94/daj - Added DSPSetTimedZeroAutoflush()
   11/29/94/daj - Changed to call DSPSetTimedZeroAutoflush(1) on !isTimed only
    7/12/95/daj - Added outputPadding and inputPadding methods to support
                  Frankenstein box
   8/7/95/lms  - Added Serial Port muting and closing down invocations.
  1/1/96/daj -   Added sound delegate
   6/25/97/daj - Added support for X/P overlaied, Y not overlaid
  */

#ifndef GNUSTEP
# import <mach/message.h>
# import <mach/mach_error.h>
#endif
#import <MKDSP/dsp_memory_map.h>
#import <Foundation/NSDate.h>
#import "MKOrchestra.h" /*these 2 added by sb */


#define SOFTREOPEN 0  /* Set to 1 to NOT do a DSPClose/MKInit on re-open. */

#define USEFREEZE 0 /* Set to 0 if driver bug not fixed for 2.0 */

#if USEFREEZE
/* The following will eventually go in libdsp: */
static int DSPMKPauseSoundOut(void);
static int DSPMKResumeSoundOut(void);
#endif

// Once we figure out the use of static vars
// @implementation MKOrchestra(Control)

#if 1

#define TSTAMPS 100
static NSDate *tstamps[TSTAMPS]; /*sb: was double... */
static char *msgs[TSTAMPS];
static int tstampCnt = 0;

void TSTAMP(char *msg) {
    if (tstamps[tstampCnt] != nil) [tstamps[tstampCnt] autorelease];
    tstamps[tstampCnt] = [[NSDate date] retain]; //sb: was getTime();
    msgs[tstampCnt++] = msg;
    if (tstampCnt == TSTAMPS)
        tstampCnt = 0;
}

void PRINTSTAMPS(void) {
  int i;
  NSDate * prevStamp = tstamps[0]; //sb: was double
  for (i=0; i<TSTAMPS; i++) {
//      printf("%f: [%f] %s\n",tstamps[i],tstamps[i]-prevStamp,msgs[i]);
      printf("%s: [%f] %s\n",[[tstamps[i] descriptionWithCalendarFormat:@"%H:%M:%S:%F" timeZone:nil locale:nil] cString],
             [tstamps[i] timeIntervalSinceDate:prevStamp],
             msgs[i]);
    prevStamp = tstamps[i];
  }
}
#endif


#define DMA_OR_SERIAL_SOUND_OUT(_self) (_self->hostSoundOut || _self->serialSoundOut)

/* FIXME */
#define IS_QP_HUB(self)  (self->orchIndex == 5)
#define IS_QP_SAT(self)  (self->orchIndex <= 4 && self->orchIndex >=1)

static void setupSerialPort(MKOrchestra *self)
{
    if (self->serialPortDevice)
      [self->serialPortDevice setUpSerialPort:self];
    else {
	DSPWriteValue(0x0302,DSP_MS_X,0xFFF0); /* SCR */
	DSPWriteValue(0x0018,DSP_MS_X,0xFFF2); /* SCCR */
	DSPWriteValue(0x4100,DSP_MS_X,0xFFEC); /* CRA */
	DSPWriteValue(0x0a00,DSP_MS_X,0xFFED); /* CRB */
	DSPWriteValue(0x1f7,DSP_MS_X,0xFFE1); /* PCC */
    }
}

-setUpDSP
{
    return self;
}

static void startSoundAndFillBuffers(MKOrchestra *self)
    /* There are 35 DSP buffers needed to fill up sound out. Each takes 3.2 ms,
       as measured. Thus, the total time to wait is about .1 second.
       */
{
#   define TIMETOWAIT 100 /* milliseconds */
    /* Copied from sleep.c. */
    enum {before,after,notAtAll} doSerialSetup;
#if USEFREEZE
    DSPMKPauseSoundOut();
#endif
    [self setUpDSP];
    if (self->serialSoundOut || self->serialSoundIn) 
      /* We let the serial port device decide if it wants to "setUp"
	 before or after sound is "started".  Some DSP monitors configure
	 codecs themselves and they use info passed in by the serialPortDevice
	 object */
      if (self->serialPortDevice && 
	  [self->serialPortDevice setUpAfterStartingSoundOut])
	doSerialSetup = after;
      else doSerialSetup = before;
    else doSerialSetup = notAtAll;
    if (doSerialSetup == before)
      setupSerialPort(self);
    if (DMA_OR_SERIAL_SOUND_OUT(self))
      DSPMKStartSoundOut();
    if (doSerialSetup == after)
      setupSerialPort(self);
    if ([self startSoundWhenOpening]) {
	/* This crock is for paranoia.  I'm afraid to change anything in the
	 * order of setting things up in the case of the NeXT DSP, for fear
	 * of introducing some new hanging bug. 
	 */
	DSPStartAtAddress(ORCHLOOPLOC); /* Starts orchloop running, but without
					   time advancing */
	/*
	 * In at least one case, we have to unmute the serial port device
	 * _after_ we have started up the DSP sending samples properly. LMS.
	 */
	if (self->serialSoundOut || self->serialSoundIn) 
	    [self->serialPortDevice unMuteSerialPort: self]; 
    }
    if (self->hostSoundOut) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(TIMETOWAIT)/1000.0]];
    }
}

static BOOL sysExists(MKOrchestra *self,int *prevSys,NSString *name)
{
  int i;
  MKOrchestra *orch;
  FOREACHORCH(i) {
      if (i != self->orchIndex && [[orchs[i] monitorFileName] isEqualToString:name]) {//sb: was strcmp([orchs[i] monitorFileName],name)==0
      orch = orchs[i];
      if (orch->mkSys) {
	*prevSys = i;
	DSPSetCurrentDSP(self->orchIndex); /* monitorFileName can change it */
	return YES;
      }
    }
  }
  DSPSetCurrentDSP(self->orchIndex);
  return NO;
}

static int myDSPMKInit(MKOrchestra *self)
{
    int ec;
    BOOL reboot;
    if (!self->mkSys) {                   /* First time */
        int prevSys;
	NSString *searchDSP = nil;//sb: was: char searchDSP[MAXPATHLEN+1];
	NSString ** foundFile = NULL;//sb: was: char foundFile[MAXPATHLEN+1];
        NSString *foundFile2;
	NSString *searchLOD = nil;
	NSString *s = (NSString *)[self monitorFileName];
	if (!s)                           /* Memory-sensing program failed */
            return DSP_EMISC;
        if (![s length])
            return DSP_EMISC;
	if (sysExists(self,&prevSys,s)) {
	  reboot = YES;
	  DSPCopyLoadSpec(&self->mkSys,
			  ((MKOrchestra *)[MKOrchestra nthOrchestra:prevSys])->mkSys);
	}
	else {
	  reboot = NO;
            if ([s isAbsolutePath])    /* s[0] == '/' */              /* Account for convention of libdsp */
                searchDSP = [s substringFromIndex:1];//strcpy(searchDSP,&(s[1]));
            else searchDSP = [[s copy] autorelease];//strcpy(searchDSP,s);

            if (!_MKFindAppWrapperFile(searchDSP,foundFile)) {
	    /* Now try looking for the .lod version */ /*sb: I think this is what was intended */
                searchLOD = [[searchDSP stringByDeletingPathExtension] stringByAppendingPathExtension:@"lod"];
//                strcpy(searchLOD,s);
//                strcpy(searchLOD+strlen(searchLOD)-3,"lod");
                if (!_MKFindAppWrapperFile(searchLOD,foundFile)) {
	      /* Now try looking for version on /usr/local/lib/dsp/monitor */
                    foundFile2 = [NSString stringWithFormat:@"%@%@",@"/usr/local/lib/dsp/monitor/",searchDSP];
                    foundFile = &foundFile2;
                    }
//sprintf(foundFile,"%s%s","/usr/local/lib/dsp/monitor/",searchDSP);
	  }
	  ec = DSPReadFile(&self->mkSys,[*foundFile fileSystemRepresentation]);
	  if(ec)                            /* Can't open file */
	    return _DSPError1(ec,"DSPMKInit: Could not read music system '%s' "
			      "for booting the DSP", (char *)[s cString]);
	  if (_MK_ORCHTRACE(self,MK_TRACEDSP))
	    NSLog(@"Music Kit: Loaded DSP monitor %s\n",	
		    [*foundFile cString]);
	}
      } else reboot = YES;
    if (self->serialSoundIn || self->serialSoundOut)
       [self->serialPortDevice adjustMonitor:self->mkSys forOrchestra:self];
    if (reboot)
      ec = DSPReboot(self->mkSys);
    else ec = DSPBoot(self->mkSys);
    if(ec)
      return(_DSPError(ec,"DSPMKInit: Could not boot DSP"));
#if m68k
    DSPSetHostMessageMode();
#endif
    return(ec);
}

-(int)outputChannelOffset
  /* Offset in DSP sound output buffer of the second channel */
{
    return ((serialPortDevice && serialSoundOut) ? 
	    ([serialPortDevice outputSampleSkip] + 1) : 1);
}

-(int)inputChannelOffset
  /* Offset in DSP sound input buffer of the second channel */
{
    return ((serialPortDevice && serialSoundIn) ? 
	    ([serialPortDevice inputSampleSkip] + 1) : 1);
}


-(int)outputPadding
  /* Additional padding of output sample frame after data samples */
{
    return ((serialPortDevice && serialSoundOut) ? 
	    [serialPortDevice outputPadding] : 0);
}

-(int)inputPadding
  /* Additional padding of output sample frame after data samples */
{
    return ((serialPortDevice && serialSoundOut) ? 
	    [serialPortDevice inputPadding] : 0);
}

-(int)outputChannelCount
  /* Number of output channels. Derived from serialPortDevice */
{
    return ((serialPortDevice && serialSoundOut) ?
	    [serialPortDevice outputChannelCount] : 2);
}	    

-(BOOL)upSamplingOutput
  /* Returns YES if we are upsampling the sound before sending it to its
   * output location. 
   */
{
    if (serialSoundOut)
      if (serialPortDevice)
	return [serialPortDevice supportsHalfSamplingRate:samplingRate];
      else return EQU([self defaultSamplingRate],samplingRate);
    else return NO;
}

-(int)outputInitialOffset
  /* Initial sample offset in DSP sound output buffers. Used to 
   * implement Singular Solutios AD64x 
   */
{
    return ((serialPortDevice && serialSoundOut) ? 
	    ([serialPortDevice outputInitialSampleSkip]) : 0);
}

-(BOOL)startSoundWhenOpening {
    return YES;
}

#define MSGTYPE_VM 2

typedef struct _vmMsg {
    int dspNum; // NSNumber?
    void *data;  // NSData
    int dataCount;
    int vmCount; // NSNumber?
} vmMsg;

#if 0 /* In case we want to pass it to a different thread. */
static NSPort *vmMsgPort = nil; /* For messages with vm data from libdsp */

static void 
  myWriteDataFunc(short *data,int dataCount,unsigned int vmCount,unsigned int dspNum)
/* Invoked by libdsp.  Sends a message to our (musicKit) thread */
{
    /* Sends a Mach message */
      NSPortMessage *msg = [[NSPortMessage alloc] initWithSendPort: vmMsgPort
                                                       receivePort: nil // this might be breaking the rules.
                                                        components: [NSArray arrayWithObject: [NSData data]]];
    /* Now the type-specific fields */
    vmMsg.dspNum = dspNum;
    vmMsg.data = data;
    vmMsg.dataCount = dataCount;
    vmMsg.vmCount = vmCount;
    [msg sendBeforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.020]];  //20mSec's *should* be plenty.
    [msg release];
}

// LMS replaced the function with a delegate method
#if 0
static void vmProc( msg_header_t *msg, void *userData)
{
    MKOrchestra *self;
    vmMsg *myMsg = (vmMsg *)msg; /* Coerce it */
    self = dspNumToOrch[myMsg->dspNum];
    [[self outputSoundDelegate] orchestra:self
     didRecordData:myMsg->data size:myMsg->dataCount];
    /* It's up to the user method to call vm_deallocate(). */
}
#else
- (void) handlePortMessage: (NSPortMessage *) portMessage
{
    MKOrchestra *orchForDSP;
    vmMsg *myMsg = [portMessage ]; /* FIXME Coerce it */
    orchForDSP = dspNumToOrch[myMsg->dspNum];
    [[orchForDSP outputSoundDelegate] orchestra: orchForDSP
     didRecordData: myMsg->data size: myMsg->dataCount];
    /* It's up to the user method to call vm_deallocate(). */
}
#endif
#endif

static void 
  myWriteDataFunc(short *data,int dataCount,unsigned int dspNum)
{
    MKOrchestra *self;
    self = dspNumToOrch[dspNum];
    [[self outputSoundDelegate] orchestra:self
     didRecordData:data size:dataCount];
}

-open
  /* Opens device if not already open. 
     Resets orchestra loop if not already reset, freeing all Unit Generators 
     and Synth Patches. Sets deviceStatus to MK_devOpen. Returns nil if some
     problem occurs, else self. Note: In release 0.9, it will not work
     to send open to an already opened, running or stopped MKOrchestra. 
     */
{
    int outputSampleFrameW,outputSampleFrameR,outputChannelCount;
    int outputInitialOffset,outputTickSamps,outputChannelOffset,outputPadding;
    BOOL upSamplingOutput;
#ifdef DEBUG
    DSPEnableErrorFile("/dev/tty");
#endif
    DSPSetCurrentDSP(orchIndex);
    DSPMKSetSamplingRate(samplingRate);
    switch (deviceStatus) {
      case MK_devClosed: /* Need to open it */
	[self _clearNotification];
	/* For some reason, calling this function if we're timed causes	
	   delays sez Nick */
	DSPSetTimedZeroNoFlush(!isTimed);
        if (hostSoundOut)
          DSPMKEnableSoundOut();
        if (serialSoundOut)
          DSPMKEnableSSISoundOut();     /* sound out to serial port */
        if (serialSoundIn)
          DSPMKEnableSSIReadData();     /* sound out from serial port */
        if (fastResponse)
          DSPMKEnableSmallBuffers();
        if (outputSoundfile) 
	  DSPMKSetWriteDataFile([outputSoundfile fileSystemRepresentation]); /* Must be before enable */
	if (outputSoundDelegate) {
#if 0
	    if (!vmMsgPort) { /* One vmMsgPort for all orchestras */
		/* We just do this once and never remove it */
                vmMsgPort = [NSPort port];
                if (vmMsgPort == nil) 
		  return nil;
                [vmMsgPort retain];
		_MKAddPort(vmMsgPort,self,MSG_SIZE_MAX,self,_MK_DPSPRIORITY);
	    }
#endif
	    DSPMKSetUserWriteDataFunc((DSPMKWriteDataUserFunc)myWriteDataFunc);
	}
	if (outputSoundfile || outputSoundDelegate)
	  DSPMKEnableWriteData();
        if (inputSoundfile) { /* READ DATA */
            DSPMKSetReadDataFile([inputSoundfile fileSystemRepresentation]); /* Must be before enable */
            DSPMKEnableReadData();
        }
        if (outputCommandsFile)
          DSPOpenCommandsFile([outputCommandsFile fileSystemRepresentation]);
        if (useDSP) {
            if (myDSPMKInit(self)) {
                DSPClose();
                return nil;
            }
        }
	if (DSP_YLE_USR == DSP_PLE_USR) {
	    if (DSP_PLE_USR == DSP_XLE_USR)
	      _overlaidEMem = MK_orchEmemNonOverlaid;
	    else _overlaidEMem = MK_orchEmemOverlaidPX;
	} else _overlaidEMem = MK_orchEmemOverlaidXYP;
	switch (_overlaidEMem) {
	  case MK_orchEmemOverlaidXYP: {
            int memSize;
	    _topOfExternalMemory[O_EMEM] = 
	      _topOfExternalMemory[X_EMEM] = 
		_topOfExternalMemory[Y_EMEM] = 
		  _topOfExternalMemory[P_EMEM] = DSPGetHighestExternalUserAddress();
	    _bottomOfExternalMemory[O_EMEM] = 
	      _bottomOfExternalMemory[X_EMEM] = 
		_bottomOfExternalMemory[Y_EMEM] = 
		  _bottomOfExternalMemory[P_EMEM] =DSPGetLowestExternalUserAddress();
	    memSize = (_topOfExternalMemory[O_EMEM] - 
		       _bottomOfExternalMemory[O_EMEM]);
            if (memSize < 0) {
                _topOfExternalMemory[O_EMEM] = _bottomOfExternalMemory[O_EMEM];
                memSize = 0;
            }
            _numXArgs = _xArgPercentage * memSize; /* Implicit floor() here */
            _numYArgs = _yArgPercentage * memSize; /* Implicit floor() here */ 
	    break;
	  }
	  case MK_orchEmemOverlaidPX: {
            int memSize;
	    _topOfExternalMemory[O_EMEM] = 
	      _topOfExternalMemory[X_EMEM] = 
		_topOfExternalMemory[P_EMEM] = DSPGetHighestExternalUserXAddress();
	    _bottomOfExternalMemory[O_EMEM] = 
	      _bottomOfExternalMemory[X_EMEM] = 
		_bottomOfExternalMemory[P_EMEM] =DSPGetLowestExternalUserPAddress();
	    memSize = (_topOfExternalMemory[O_EMEM] - 
		       _bottomOfExternalMemory[O_EMEM]);
            if (memSize < 0) {
                _topOfExternalMemory[O_EMEM] = _bottomOfExternalMemory[O_EMEM];
                memSize = 0;
            }
            _numXArgs = _xArgPercentage * memSize; /* Implicit floor() here */
	    _bottomOfExternalMemory[Y_EMEM] = DSPGetLowestExternalUserYAddress();
	    _topOfExternalMemory[Y_EMEM] = (DSPGetHighestExternalUserYAddress() - 
					    extraRoomAtTopOfOffchipMemory);
	    memSize = _topOfExternalMemory[Y_EMEM] - _bottomOfExternalMemory[Y_EMEM];
	    if (memSize < 0) {
                _topOfExternalMemory[Y_EMEM] = _bottomOfExternalMemory[Y_EMEM];
		memSize = 0;
	    }
            _numYArgs = _yArgPercentage * memSize; /* Implicit floor() here */ 
	    break;
	  }
	  case MK_orchEmemNonOverlaid: {
	    int memSize;
	    _bottomOfExternalMemory[X_EMEM] = DSPGetLowestExternalUserXAddress();
	    _topOfExternalMemory[X_EMEM] = (DSPGetHighestExternalUserXAddress() - 
					    extraRoomAtTopOfOffchipMemory);
	    _bottomOfExternalMemory[Y_EMEM] = DSPGetLowestExternalUserYAddress();
	    _topOfExternalMemory[Y_EMEM] = (DSPGetHighestExternalUserYAddress() - 
					    extraRoomAtTopOfOffchipMemory);
	    _bottomOfExternalMemory[P_EMEM] = DSPGetLowestExternalUserPAddress();
	    _topOfExternalMemory[P_EMEM] = (DSPGetHighestExternalUserPAddress() - 
					    extraRoomAtTopOfOffchipMemory);
	    memSize = _topOfExternalMemory[P_EMEM] - _bottomOfExternalMemory[P_EMEM];
	    if (memSize < 0) {
                _topOfExternalMemory[P_EMEM] = _bottomOfExternalMemory[P_EMEM];
		memSize = 0;
	    }
	    memSize = _topOfExternalMemory[X_EMEM] - _bottomOfExternalMemory[X_EMEM];
	    if (memSize < 0) {
                _topOfExternalMemory[X_EMEM] = _bottomOfExternalMemory[X_EMEM];
		memSize = 0;
	    }
            _numXArgs = _xArgPercentage * memSize; /* Implicit floor() here */
	    memSize = _topOfExternalMemory[Y_EMEM] - _bottomOfExternalMemory[Y_EMEM];
	    if (memSize < 0) {
                _topOfExternalMemory[Y_EMEM] = _bottomOfExternalMemory[Y_EMEM];
		memSize = 0;
	    }
            _numYArgs = _yArgPercentage * memSize; /* Implicit floor() here */ 
	    break;
	  }
	}
	if (simulatorFile) {
	DSPOpenSimulatorFile(simulatorFile);
            /* start simulator file AFTER bootstrap */
            _simFP = DSPGetSimulatorFP();
        }
        if ((outputSoundfile || outputSoundDelegate) && !serialSoundIn) 
          DSPMKEnableBlockingOnTMQEmptyTimed(DSPMK_UNTIMED);
        /* loadOrchLoop sets devStatus to MK_devOpen if it succeeds.
           If it fails, it does a DSPClose() and sets devStatus to 
           MK_devClosed. */
	outputChannelCount =  [self outputChannelCount];
	outputChannelOffset = [self outputChannelOffset];
	outputPadding = [self outputPadding];
	outputSampleFrameR = (outputChannelOffset * outputChannelCount + 
			      outputPadding);
	upSamplingOutput = [self upSamplingOutput];
	outputInitialOffset = [self outputInitialOffset];
	outputTickSamps = outputChannelCount;
	outputSampleFrameW = outputSampleFrameR;
	if (upSamplingOutput) {
	    DSPHostMessage(DSP_HM_HALF_SRATE);
	    outputSampleFrameW *= 2;
	    outputTickSamps *= 2;
	} 
	outputTickSamps *= DSPMK_I_NTICK;
	DSPWriteValue(outputTickSamps,DSP_MS_X,DSP_X_O_TICK_SAMPS);
	DSPWriteValue(outputInitialOffset,DSP_MS_X,DSP_X_OUT_INITIAL_SKIP);
	DSPWriteValue(outputChannelOffset,DSP_MS_X,DSP_X_O_CHAN_OFFSET);
	DSPWriteValue(outputSampleFrameW,DSP_MS_X,DSP_X_O_SFRAME_W);
	DSPWriteValue(outputSampleFrameR,DSP_MS_X,DSP_X_O_SFRAME_R);
	DSPWriteValue(outputPadding,DSP_MS_X,DSP_X_O_PADDING);
	if (serialSoundIn) {
	    BOOL downSampleInput;
	    int inputSampleFrameW,inputSampleFrameR,inputChannelCount,inputChanOffset;
	    int inputInitialSkip;
	    int sbufs; /* "start buffs" -- number of buffs SSI input waits before
			* starting.  This is needed so that the driver doesn't 
			* underrun a lot on start-up. 
			*/
	    if (serialPortDevice) {
		inputChanOffset = [serialPortDevice inputSampleSkip]+1;
		inputChannelCount = [serialPortDevice inputChannelCount];
		inputSampleFrameW = ((inputChanOffset * inputChannelCount) + 
				     [self inputPadding]);

		downSampleInput = [serialPortDevice supportsHalfSamplingRate:samplingRate];
		inputInitialSkip = [serialPortDevice inputInitialSampleSkip];
	    } else {
		inputChannelCount = inputSampleFrameW = 2;
		inputChanOffset = 1;
		downSampleInput = EQU(samplingRate,[self defaultSamplingRate]); 
		inputInitialSkip = 0;
	    }
	    inputSampleFrameR = inputSampleFrameW;
	    if (downSampleInput) 
	      inputSampleFrameR *= 2;
	    DSPWriteValue(inputInitialSkip,DSP_MS_X,DSP_X_IN_INITIAL_SKIP);
	    DSPWriteValue(inputChanOffset,DSP_MS_X,DSP_X_I_CHAN_OFFSET);
	    DSPWriteValue(inputSampleFrameR,DSP_MS_X,DSP_X_I_SFRAME_R);
	    DSPWriteValue(inputSampleFrameW,DSP_MS_X,DSP_X_I_SFRAME_W);
	    sbufs = ((((fastResponse) ? _DSP_SND_BUFFER_SIZE : _BIG_SND_BUFFER_SIZE) * 
		      (_SND_BUFF_COUNT - 1))/ 
		     ((_DSP_SND_BUFFER_SIZE / 2) / inputSampleFrameR));
	    /* We set sbufs to correspond to 1 less than the number of driver buffers.
	     * We don't want it to equal the number of driver buffers because then
	     * SSI input may be overrunning if its clock is slightly faster than
	     * the NeXT DAC's clock.
	     */
	    DSPWriteValue(sbufs,DSP_MS_X,DSP_X_SSI_SBUFS_GOAL);
	}
        if (!loadOrchLoop(self))  
          return nil;
#if i386
        DSPSetHostMessageMode();
#endif
	if (serialSoundIn)
	  DSPMKStartSSIReadData();
	if ([self startSoundWhenOpening]) {
	    if (DMA_OR_SERIAL_SOUND_OUT(self))
	      startSoundAndFillBuffers(self);
	    else if (serialSoundIn) {
		setupSerialPort(self);
		/* We do the DSPStartAtAddress() in run for this case and
		 * for write data. 
		 */
	    }
	}
	break;
      case MK_devStopped:
      case MK_devRunning:
        /* All of the following is an attempt to avoid doing a 
           DSPClose/DSPMKInit. Perhaps this is silly! */
	[self _adjustOrchTE:NO reset:YES];
#if SOFTREOPEN
        /* Reset orchestra loop without doing a DSPClose() first. */
        DSPHostMessage(DSP_HM_IDLE);    /* Jump to infinite loop */
        /* Don't wait for idle. This causes infinite hang if we're in dma 
           mode. On the other hand, if we stop sound out first, the message
           gets stuck behind dma requests (or something like that). In either
           case, we hang infinitely. */ 
        if (DMA_OR_SERIAL_SOUND_OUT(self))
          DSPMKStopSoundOut();          /* Stop sending sound-out buffers */
//        if (serialSoundOut)   /* This is done by DSPMKStopSoundOut */
//          DSPMKStopSSISoundOut();
        if ((outputSoundfile || outputSoundDelegate)) {
            DSPMKStopWriteData();
            DSPMKRewindWriteData();
        }
        if (inputSoundfile) { /* READ DATA */
            DSPMKStopReadData();
            DSPMKRewindReadData();
        }
	if (serialSoundIn)
	  DSPMKStopSSIReadData();
        /* Clear sound-out buffers so junk doesn't go out at start of play */
        DSPMKClearDSPSoundOutBufferTimed(DSPMK_UNTIMED);
//      DSPMemoryClear(DSP_MS_Y,DSPMK_YB_DMA_W,DSPMK_NB_DMA_W); 
        freeUGs(self); /* Frees _OrchSysUG as well. */
        /* loadOrchLoop sets devStatus to MK_devOpen if it succeeds.
           If it fails, it does a DSPClose() and sets devStatus to 
           MK_devClosed. */
        if (!loadOrchLoop(self))         
          return nil;
        {   /* Reset time. */
            DSPFix48 zero = {0,0}; 
            DSPMKSetTime(&zero);
        }
	if (serialSoundIn)
	  DSPMKStartSSIReadData();
	if ([self startSoundWhenOpening]) {
	    if (DMA_OR_SERIAL_SOUND_OUT(self))
	      startSoundAndFillBuffers(self);
	    else if (serialSoundIn) {
		setupSerialPort(self);
		/* We do the DSPStartAtAddress() in run */
	    }
	}
        break;
#else
        [self abort];
        return [self open];
#endif
      case MK_devOpen:
      default:
        break;
    }
    return self;
}

- run
  /* If not open, does a [self open].
     If not already running, starts DSP clock. 
     Sets deviceStatus to MK_devRunning. */
{
    switch (deviceStatus) {
      case MK_devClosed:
        if (![self open])
          return nil;
      case MK_devOpen:
        DSPSetCurrentDSP(orchIndex);
	if (![self startSoundWhenOpening])
	  startSoundAndFillBuffers(self);
        [_sysUG _unpause]; /* Poke orchloopbegin to continue on */
	/* The difference between my _sysUG pause mode and Julius'	
	   freeze mode is that the former generates 0s and the latter does 
	   nothing. */
        /* If we're just doing write data, we haven't done a startAtAddress
           yet. */
        DSPMKResumeOrchestra(); /* Start time advancing */
        if ((!DMA_OR_SERIAL_SOUND_OUT(self)) || ![self startSoundWhenOpening])
	  /* Write data starts late so it doesn't write tons of zeros.
	   * Also, for non-NeXT DSP, we want to do things "right", which
	   * means starting the DSP at the end (after the resume.)
	   * For the NeXT DSP, I'm afraid of changing anything that might
	   * cause unforseen hanging bugs, hence the crock of multiple ways
	   * of starting things up.
	   * Otherwise, done by startSoundAndFillBuffers().
	   */
          DSPStartAtAddress(ORCHLOOPLOC);
#if USEFREEZE
	else DSPMKResumeSoundOut();
#endif
        deviceStatus = MK_devRunning;
        if ((outputSoundfile || outputSoundDelegate))
          DSPMKStartWriteDataTimed(_MKCurSample(self));
        if (inputSoundfile) /* READ DATA */
          DSPMKStartReadDataTimed(_MKCurSample(self));
        /* We do it timed because we don't want to write out the deltaT at
           the beginning. */
	/* This is done by DSPMKStartSoundOut()! */
//        if (serialSoundOut)
//          DSPMKStartSSISoundOut();
        /* We don't know of any devices that can start instantaneously so
           we give them deltaT's worth of 0s. */
	[self _adjustOrchTE:YES reset:YES];
        break;
      case MK_devStopped:
#if USEFREEZE
	DSPMKThawOrchestra(); 
        if (hostSoundOut)
         DSPMKResumeSoundOut();
#else
        [_sysUG _unpause]; /* Poke orchloopbegin to continue on */
        if (!DMA_OR_SERIAL_SOUND_OUT(self))
          DSPMKThawOrchestra();
        else DSPMKResumeOrchestra();
#endif
	[self _adjustOrchTE:YES reset:NO];
        deviceStatus = MK_devRunning;
        break;
      case MK_devRunning:
      default:
        break;
    }
    return self;
}

#if 0
- run
  /* If not open, does a [self open].
     If not already running, starts DSP clock. 
     Sets deviceStatus to MK_devRunning. */
{
    switch (deviceStatus) {
      case MK_devClosed:
        if (![self open])
          return nil;
      case MK_devOpen:
        DSPSetCurrentDSP(orchIndex);
	if (IS_QP_HUB(self) || IS_QP_SAT(self))
	  if (DMA_OR_SERIAL_SOUND_OUT(self) || IS_QP_SAT(self))
	    startSoundAndFillBuffers(self);
	  else if (serialSoundIn) {
	      setupSerialPort(self);
	  }
        [_sysUG _unpause]; /* Poke orchloopbegin to continue on */
	/* The difference between my _sysUG pause mode and Julius'	
	   freeze mode is that the former generates 0s and the latter does 
	   nothing. */
        /* If we're just doing write data, we haven't done a startAtAddress
           yet. */
        DSPMKResumeOrchestra(); /* Start time advancing */
        if ((!DMA_OR_SERIAL_SOUND_OUT(self)) || IS_QP_SAT(self) || IS_QP_HUB(self))
	  /* Otherwise, done by startSoundAndFillBuffers() */
          DSPStartAtAddress(ORCHLOOPLOC);
#if USEFREEZE
	else DSPMKResumeSoundOut();
#endif
        deviceStatus = MK_devRunning;
        if ((outputSoundfile || outputSoundDelegate))
          DSPMKStartWriteDataTimed(_MKCurSample(self));
        if (inputSoundfile) /* READ DATA */
          DSPMKStartReadDataTimed(_MKCurSample(self));
        /* We do it timed because we don't want to write out the deltaT at
           the beginning. */
	/* This is done by DSPMKStartSoundOut()! */
//        if (serialSoundOut)
//          DSPMKStartSSISoundOut();
        /* We don't know of any devices that can start instantaneously so
           we give them deltaT's worth of 0s. */
	[self _adjustOrchTE:YES reset:YES];
        break;
      case MK_devStopped:
#if USEFREEZE
	DSPMKThawOrchestra(); 
        if (hostSoundOut)
         DSPMKResumeSoundOut();
#else
        [_sysUG _unpause]; /* Poke orchloopbegin to continue on */
        if (DMA_OR_SERIAL_SOUND_OUT(self))
          DSPMKThawOrchestra();
        else DSPMKResumeOrchestra();
#endif
	[self _adjustOrchTE:YES reset:NO];
        deviceStatus = MK_devRunning;
        break;
      case MK_devRunning:
      default:
        break;
    }
    return self;
}
#endif

-stop
  /* If not open, does a [self open].
     Otherwise, stops DSP clock and sets deviceStatus to MK_devStopped.
     */
{
    switch (deviceStatus) {
      case MK_devClosed:
        return [self open];
      case MK_devOpen:
      case MK_devStopped:
        return self;
      case MK_devRunning:
        DSPSetCurrentDSP(orchIndex);
#if USEFREEZE
	if (hostSoundOut)
	  DSPMKPauseSoundOut();
	DSPMKFreezeOrchestra();
#else
        [_sysUG _pause:self->_looper]; /* Poke orchloop to hardwire jump */
	if (!DMA_OR_SERIAL_SOUND_OUT(self))
          DSPMKFreezeOrchestra();
        else DSPMKPauseOrchestra();
#endif
	[self _adjustOrchTE:NO reset:NO];
        deviceStatus = MK_devStopped; 
        return self;
      default:
        break;
    }
    return self;
}

-abort
  /* Closes the receiver immediately, without waiting for all enqueued DSP 
     commands to be executed. This involves freeing all
     unit generators in its unit generator stack, clearing all
     synthpatch allocation lists and releasing the DSP. It is an error
     to free an orchestra with non-idle synthPatches or allocated unit
     generators which are not members of a synthPatch. An attempt to
     do so generates an error. 
     Returns self unless there's some problem
     closing the DSP, in which case, returns nil.
     Closes the commands file (if open) at the current time.
     */
{
    DSPFix48 curTimeStamp;
    
    if (deviceStatus != MK_devClosed) {
        DSPSetCurrentDSP(orchIndex); /* Was after freeUGs--Moved March 7, 1993-DAJ */
	[self _adjustOrchTE:NO reset:YES];
	/* sshhh the serial port device LMS July 15, 1995 */
	if (serialPortDevice && serialSoundOut)
	    [serialPortDevice closeDownSerialPort:self];
        freeUGs(self);
        if (_simFP) {
            DSPCloseSimulatorFile();
            _simFP = NULL;
        }
        if (outputCommandsFile && DSPIsSavingCommands()) {
            DSPMKReadTime(&curTimeStamp);
            DSPCloseCommandsFile(&curTimeStamp);
        }
        if (!useDSP) 
          return self;
        if (DSPClose()) 
          return nil;
        return self;
    }
    return self;
}

- close
  /* Closes the receiver after waiting for all enqueued DSP commands to be
     executed. This involves freeing all
     unit generators in its unit generator stack, clearing all
     synthpatch allocation lists and releasing the DSP. It is an error
     to free an orchestra with non-idle synthPatches or allocated unit
     generators which are not members of a synthPatch. An attempt to
     do so generates an error. 
     Returns self unless there's some problem
     closing the DSP, in which case, returns nil.

     SB's MKNotes: bufferTime is absolute in seconds.
     */
{
    if (deviceStatus == MK_devRunning) { /* If not, can't wait for end of time */ 
        /* Wait for end of time */
        DSPFix48 endTimeStamp;
        double endTime;
        int nclip = 0; /* Init to make compiler happy */
        
#       define FOREVER 0
#       define TIMEOUT (FOREVER) /* in seconds */
        
        /* There was a bug: We had to pad the end much too much when doing               
           write data. 
           
           It SHOULD work like this:
           
           The DSP has a buffer, the driver in write data mode has 16 buffers.
           Theoretically the delay is 17 buffers, 512 words of data 
           (256 stereo samples). But there's an extra buffer in the DSP and an
           extra 16 buffers in the driver. So the maximum time needed should be
           35 buffers of stereo samples (35 * 512).
           
           So at 22khz, the delay is .407 seconds and at 44 khz, the delay is
            .204 seconds.
           
           For write data, .05 seconds at 22 khz or .025 at 44 khz
           */
        
        double bufferTime;
        if (!isTimed) {
            DSPSetCurrentDSP(orchIndex);
            DSPMKDisableBlockingOnTMQEmptyTimed(DSPMK_UNTIMED);
        } else {
#if 0       /* See comment above. */
            bufferTime = ((outputSoundfile || outputSoundDelegate)) ? 1.5 : .5;
#else
            bufferTime = ((((outputSoundfile || outputSoundDelegate)) ? .05 : .407)* 
                          (22050.0/samplingRate));
#endif
            endTime = (_MKLastTime() + bufferTime + timeOffset +
                       self->localDeltaT); 
            doubleIntToFix48UseArg(endTime * samplingRate, &endTimeStamp);
            if (_simFP) 
              if (_MK_ORCHTRACE(self,MK_TRACEDSP))
                _MKOrchTrace(self,MK_TRACEDSP,"End of timed messages queue."
                             "Do timed read of clips.\n");
            DSPSetCurrentDSP(orchIndex);
            DSPMKDisableBlockingOnTMQEmptyTimed(&endTimeStamp);
	    DSPMKStopMsgReader(); /* Stop msg reader thread.  We're going 
				   * to take over that roll. 
				   */
            if (![self awaitEndOfTime:endTime timeStamp:&endTimeStamp ])
              if (_MK_ORCHTRACE(self,MK_TRACEDSP))
                _MKOrchTrace(self,MK_TRACEDSP,
                             "Could not send timed peek to orchestra.");
            if (nclip)
              if (_MK_ORCHTRACE(self,MK_TRACEDSP))
                _MKOrchTrace(self,MK_TRACEDSP,
                             "Clipping detected for %d ticks.\n",nclip);
            
            if (outputCommandsFile) {
                if (DSPMKCallTimedV(&endTimeStamp,DSP_HM_HOST_WD_OFF,1,1))
                  if (_MK_ORCHTRACE(self,MK_TRACEDSP))
                    _MKOrchTrace(self,MK_TRACEDSP,
                                 "Could not send timed write data off to orchestra.");
                DSPMKFlushTimedMessages();
                DSPCloseCommandsFile(&endTimeStamp);
            }
        }
    }
    return [self abort];
}

-pauseInputSoundfile
{
    DSPSetCurrentDSP(orchIndex);
    DSPMKPauseReadDataTimed(_MKCurSample(self));
    return self;
}

-resumeInputSoundfile
{
    DSPSetCurrentDSP(orchIndex);
    DSPMKResumeReadDataTimed(_MKCurSample(self));
    return self;
}

#if USEFREEZE
/* The following will eventually go in libdsp */
#import <sound/sounddriver.h>

static int DSPMKPauseSoundOut(void)
{
    snddriver_stream_control(DSPMKGetWriteDataStreamPort(),
			     0,SNDDRIVER_PAUSE_STREAM);
}

static int DSPMKResumeSoundOut(void)
{
    snddriver_stream_control(DSPMKGetWriteDataStreamPort(),
			     0,SNDDRIVER_RESUME_STREAM);
}
#endif

/* JOS says (Dec. 7, 1993):
   
   Yes, you should be able to use DSPReadValue().  It should have worked
   before also to awaken the driver.  For the end of time, you have to do
   a timed read, and to avoid driver narcolepsy, you had to set a
   time-out like you do now.  Since driver wake-ups should no longer be
   necessary, thanks to the KERNEL_ACK "errors", you should be able to go
   back to the simple code:
   
   DSPMKRetValueTimed(&endTimeStamp,DSP_MS_X,
   DSPMKGetClipCountXAddress(),&nclip);
   
   
   */

static int awaitEndOfTime(DSPTimeStamp *aTimeStampP,id self)
/*
 * Await end of time by sending a "timed peek" of the
 * clip count (which is then ignored).
 */
{
    if (DSPMKAwaitEndOfTime(aTimeStampP) == DSP_EABORT)
      [self _notifyAbort];
    return 0;			/* success */
}

-awaitEndOfTime:(double)endOfTime timeStamp:(DSPTimeStamp *)aTimeStampP
  /* Subclass may override this method. 
     endOfTime should be the last message scheduled.
     aTimeStampP should be the same thing, but multiplied by the sampling rate. */
{
    if (awaitEndOfTime(aTimeStampP,self))
      return nil;
    return self;
}

//@end
