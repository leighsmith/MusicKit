/*
  $Id Mididriver.m$

  Copyright (C) 1991, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc.
  and reproduced under license from NeXT
  Portions copyright (c) 1994 Stanford University
  Intel-based changes (c) Stanford University, 1994.


  David A. Jaffe 
  (based on original version by Lee Boynton)
  RhapsodyDR2 Intel/MacOsX PPC Server Port by Leigh M. Smith
  <leigh@psychokiller.dialix.oz.au> 1998


  Modification history (all changes made by DAJ, unless noted):
  5/10/91 - Original version created by Lee Boynton.
  5/28/91 - Changed receive (midi in) side to use circular buffer,
            to avoid turning off interrupts in callout routine.
	    Also added xpr support.
  5/28/91 - Changed transmit (midi out) side to use circular buffer,
            to avoid turning off interrupts in user-level routine.
  5/31/91 - Using one thread for both transmit and receive to/from user
            was causing deadlock in midi echo case as one thread would
	    get ahead and its port would block.  Changed to use multiple
	    threads.  By the way, tried using softint_sched instead of
	    kern_server_callout and it caused problems! (Notes stuck, etc.)
  6/10/91 - Changed clear_wait to be thread_terminate in unload function.
            Also got rid of check for thread_result.  
	    (See mididriver_server.save.c for old version.)
  6/17/91 - Added support for second serial port.
  6/18/91 - Added support for synching to external mtc. 
  6/19/91 - Fixed bug in set_time. Wasn't doing a microboot. 
  6/19/91 - Added starting and stopping of the clock.  This introduces an
            inconsistancy -- scheduled events and incoming MD are handled
	    differently when the clock is stopped.   I wonder whether the
	    driver should come up running or stopped?  Currently, setting
	    the mode always sets the clock to stopped.
  6/24/91 - Changed start/stop of clock API.  Added support for exception
            notification. 
  6/24/91 - Flushed support for generation of time code.
  6/25/91 - Changed to only one extra thread for shipping data to user.
            Fixed bug in pendingAlarm mechanism.
  6/26/91 - Changed time to use int consisting of 1/4 milliseconds.  This
            gives 6 days of time.  It's safe to assume that we can tell the
	    difference between something late and something in the future
	    with this time base.  E.g. something is late if it's less than
	    a day in the past and it's "wrap-around" if it's more than a 
	    day in the past.
  7/15/91 - Fixed bug in time increment for 30-frame rate (off by 10x!).
            Changed to check queueAvailableNotify() when clearing queue or
	    requesting notification.
  7/16/91 - Added check of rcvCalloutPending in receive thread loop.
  7/17/91 - Changed thread to be started up at the beginning of time.
  7/29/91 - Changed API.
  7/31/91 - Added wrap-around check, NAK parsing, variable quanta. Changed
            default to 1 ms.
  8/15/91 - Added drop-frame MTC support.
  9/1/91  - Added better-than-8-ms mtc support.
  9/4/91  - Ported to release Warp9B and new API.
  9/12/91 - Fixed bug in output queue full.  Fixed bug in alarmReplyCallout.
            Added notification for time code stopped 0.5 sec after no time
	    code is received.
  9/18/91 - Changed alarm to be part of rcv data thread.
  10/22/91 - Added parsed mode. (On PARSED switch)
  11/14/91/mtm - import architecture.h
  03/13/91/mtm - import from 'mididriver' not 'midi'.
  9/5/94/daj   - Added MPU401 code for Intel.  Renamed functions to MD prefix.
                 Added MIDI as deviceKind.
  10/20/94/daj - Attempt to avoid system panic by changing 0 to 1 in 
		 sleepReceiveReady() and sleepSendReady().  There seems
		 to be a state that the card can get into when it 
		 doesn't respond properly to reset. Note that interrupts
		 are turned off at this point, so that can't be the
		 problem.  Also added check for CLAIMED() in clkInterrupt().
  2/12/95/daj  - Added check for zero clock quantum in MDSetClockQuantum().
  10/7/98/lms  - Decrufted m68k support, us_ converted to ns_ timing functions, 
		 and adopted USE_IO_THREAD in porting to Intel Rhapsody
                 Developer Release 2.
  12/21/98/lms - Port to Rhapsody PowerPC architecture, major reorganization,
                 separated into architecture-specific source files.
  $Log$
  Revision 1.1  1999/12/01 04:53:01  leigh
  Initial revision

*/

/* Notes on Intel implementation:

   Currently we mask interrupts all over the place.  This is a legacy of the 
   NeXT implementation. 

   Probably should change it to "serialize" interrupts using the IO thread.
   That means that calls to ns_abstimeout must be replaced by another thread
   that has a msg_receive that blocks for a given amount of time, then sends
   a Mach message to the IO thread.

   For Intel hardware, we allocate statically, using more memory than is needed.  
   This should be changed to dynamic (object instance variable) allocation. FIXME

 * Units: 
   We have one "master driver" that manages all cards.  Each card is an
   instance of Mididriver.  However there is one owner of the "master
   driver". This has the disadvantage that one app can not use one card
   while another app uses another card (unless there's a "Midi Manager").
   But it has the advantage that time control is global, which
   means that only a single card need listen to MIDI time code
   to provide synchronization.
  
   Therefore, the "unit" in mididriver_server.c becomes the card.
   Some cards have multiple ports.  These we call "sub-units".

 * Bug in MIDI driver
   Date: Mon, 16 Nov 92 15:53:14 -0800
   From: david (David A. Jaffe)
   To: mminnick@next.com
   Cc: r@next.com, david

   Now that I'm actually using the MIDI driver, I've decided that there's
   a bug in it.  The problem is that, when in MIDI time code mode,
   there's no way to know when the time it returns is actually valid.
   For example, I have a tape with some time code recorded.  There are no
   full messages-- the time code just starts running.  It's my suspicion
   (though I can't prove it without a debug kernel) that when I receive
   the "time code started" exception, the driver's idea of the current
   time is "half baked".  This is because the time is not knowable until
   8 quarter frames have gone by.  The problem is that there's no way for
   the user to know when time is valid.  At the moment, I'm just waiting
   a bit before asking the time.  But this is an unreliable work-around
   because time code could have stopped in the mean time.  (I.e. it could
   have given 6 frames and then stopped.)

   We really need a function that returns when time code is valid.  A
   conservative addition to the API would be for MIDIGetMTCTime() to
   return a new error, "MD_TIME_CODE_UNDEFINED", for this case.

   I anticipate it would take me only a couple of hours to implement and test.

 * Notes on conversion to NRW:
   The low-level code is well isolated below and will need to be rewritten
   for NRW DMA architecture.

   Also need to get rid of splmidi()/splx() everywhere.
   Consider initially getting rid of splmidi everywhere except for midi input routine.
   Note that NRW multi-processor architecture may require inserting some locks
   for code that currently runs at splmidi().
   Be sure to include locks where splmidi is currently only assumed.
 */


/* At NeXT, the following two files are grabbed from /LocalDeveloper/Headers/midi,
 * where the libmididriver project leaves them.  At CCRMA, they are part of this
 * project.
 */

#import "mididriver.h"
#import "mididriver_reply.h"

/***** Note:

  If I include kernserv/prototypes.h BEFORE driverkit, it hangs when
  I try to allocate the driver.  If I do it AFTER, I get current_task(),
  and some other functions undefined.

 *****/

#import <bsd/sys/callout.h>
#import <machkit_3.3/NXLock.h> // non-RDR2 header
#import <driverkit/kernelDriver.h>
#import <driverkit/generalFuncs.h>
#import <kernserv/prototypes.h>
#import <driverkit/interruptMsg.h>
#import <kernserv/kern_server_types.h>
#import <kernserv_3.3/printf.h> // non-RDR2 header
#import "Mididriver.h"
// #import <mididriver/midi_spec.h> // this location no longer exists in MOXS
// this is a little tricky as this assumes the MusicKit has been installed to compile the driver
#import <MusicKit/midi_spec.h>
#import <mach/mig_errors.h>
#import <kernserv/ns_timer.h> // ns_timer.h should eventually be replaced by #import <kern/time_stamp.h>
#import <sys/time.h>
#import <sys/callout.h>
#import <kernserv/machine/spl.h>

// Buffer sizes
#define RCV_FIFO_SIZE 2048  // Make this dependent on platform??? Doubled this from 1024 for fast SysEx dumps LMS
#define XMT_FIFO_SIZE 512
#define NONDATA_FIFO_SIZE 16
#define MAX_UNITS 8 	    // should be 2 for PPC, but perhaps this needs rethinking anyway

// Configuration Options
#define USE_IO_THREAD 1     // was 0 in NeXTStep version but this causes link errors with RDR2
#define PARSED 0

typedef struct {
    short type;
    #define QUEUE_EVENT (MD_EXCEPTION_MTC_STARTED_REVERSE+1)
    #define ALARM_EVENT (QUEUE_EVENT+1)
    #define EXCEPTION_EVENT (ALARM_EVENT+1)
    union {
        char exception;
        struct {
            unsigned char unit;
            port_t replyPort;
        } queueNotification;
        struct {
            int requestedTime;
            port_t replyPort;
        } alarm;
    } data;
} nonDataEvent_t;

/* Forward references */
static int checkMTCTimeStopped(void);
static void stopMtcSync(void);
static void deviceReset(short unit);
static void deviceStartXmt(int now,short unit);
static void requestWakeup(int later);
static int clkInterrupt (void);
static inline void checkQueueNotify(short unit);
static void raiseNonDataEvent(nonDataEvent_t *e);
static void raiseException(int ex);
extern boolean_t _MDPortDeath(port_name_t port);

typedef void (*void_fun_t)(void *);

/* Set MIDI interrupt level */
#if i386
#define splmidi() spl3()  /* Doc says higher than 3 is dangerous for non-NeXT
                           * programs. This macro must agree with IPLDEVICE in
                           * /usr/include/kernserv/i386/spl.h
                           */
#endif
#if ppc
#define splmidi() set_priority_level(3)
#endif

static int _MididriverUnit = 0;

static Mididriver *driverObjects[MAX_UNITS] = {nil};

/* -------------------------------------------------------------------------
 * DEBUGGING
 * -------------------------------------------------------------------------
 */

#define DEBUG_NONE 0
#define DEBUG_XPRS 1
#define DEBUG_DDM 2
#define DEBUG_IOLOG 3

//#define DEBUG_METHOD DEBUG_IOLOG /* Set Debug mode here */
#define DEBUG_METHOD DEBUG_NONE /* Set Debug mode here */

#define PRINTF IOLog

#if (DEBUG_METHOD==DEBUG_XPRS)
/* General and important message log */
#define midi_log(msg,arg1,arg2,arg3,arg4,arg5) \
    XPR(XPR_MIDI, (msg, arg1, arg2, arg3, arg4, arg5))

/* Stack log */
#define midi_slog(msg) \
    XPR(XPR_MIDI, (msg, 1,2,3,4,5))

/* Input log */
#define midi_ilog(msg, arg1, arg2, arg3, arg4, arg5) \
    XPR(XPR_MIDI, (msg, arg1, arg2, arg3, arg4, arg5))

/* Input data log */
#define midi_idatalog(msg, arg1, arg2, arg3, arg4, arg5) \
    XPR(XPR_MIDI, (msg, arg1, arg2, arg3, arg4, arg5))

/* Output log */
#define midi_olog(msg, arg1, arg2, arg3, arg4, arg5) \
    XPR(XPR_MIDI, (msg, arg1, arg2, arg3, arg4, arg5))

/* Output log */
#define midi_odatalog(msg, arg1, arg2, arg3, arg4, arg5) \
    XPR(XPR_MIDI, (msg, arg1, arg2, arg3, arg4, arg5))

/* Time log */
#define midi_tlog(msg, arg1, arg2, arg3, arg4, arg5) \
    XPR(XPR_MIDI, (msg, arg1, arg2, arg3, arg4, arg5))

/* Exception log */
#define midi_xlog(msg, arg1, arg2, arg3, arg4, arg5) \
    XPR(XPR_MIDI, (msg, arg1, arg2, arg3, arg4, arg5))

#endif

#if (DEBUG_METHOD==DEBUG_DDM)

#warning DDM_DEBUG stuff may cause arithmetic exception when loading driver.
// Need -DDDM_DEBUG to use this stuff
#import <driverkit/debugging.h>

#define DDM_INDEX 0

#define LOG 0x1
#define SLOG 0x2
#define ILOG 0x4
#define IDATALOG 0x8
#define OLOG 0x10
#define ODATALOG 0x20
#define TLOG 0x40
#define XLOG 0x80

/* General and important message log */
#define midi_log(msg,arg1,arg2,arg3,arg4,arg5) \
    IODEBUG(DDM_INDEX,LOG,msg, arg1, arg2, arg3, arg4, arg5)

/* Stack log */
#define midi_slog(msg) \
    IODEBUG(DDM_INDEX,SLOG,msg, 1,2,3,4,5)

/* Input log */
#define midi_ilog(msg, arg1, arg2, arg3, arg4, arg5) \
    IODEBUG(DDM_INDEX,ILOG,msg, arg1, arg2, arg3, arg4, arg5)

/* Input data log */
#define midi_idatalog(msg, arg1, arg2, arg3, arg4, arg5) \
    IODEBUG(DDM_INDEX, IDATALOG, msg, arg1, arg2, arg3, arg4, arg5)

/* Output log */
#define midi_olog(msg, arg1, arg2, arg3, arg4, arg5) \
    IODEBUG(DDM_INDEX, OLOG, msg, arg1, arg2, arg3, arg4, arg5)

/* Output log */
#define midi_odatalog(msg, arg1, arg2, arg3, arg4, arg5) \
    IODEBUG(DDM_INDEX, ODATALOG, msg, arg1, arg2, arg3, arg4, arg5)

/* Time log */
#define midi_tlog(msg, arg1, arg2, arg3, arg4, arg5) \
    IODEBUG(DDM_INDEX, TLOG, msg, arg1, arg2, arg3, arg4, arg5)

/* Exception log */
#define midi_xlog(msg, arg1, arg2, arg3, arg4, arg5) \
    IODEBUG(DDM_INDEX, XLOG, msg, arg1, arg2, arg3, arg4, arg5)

#endif

#if (DEBUG_METHOD==DEBUG_IOLOG)
/* General and important message log */
#define midi_log(msg,arg1,arg2,arg3,arg4,arg5) \
      IOLog(msg,arg1,arg2,arg3,arg4,arg5)

/* Stack log */
#define midi_slog(msg) \
      IOLog(msg)

/* Input log */
#define midi_ilog(msg, arg1, arg2, arg3, arg4, arg5) \
    IOLog(msg, arg1, arg2, arg3, arg4, arg5)

/* Input data log */
#define midi_idatalog(msg, arg1, arg2, arg3, arg4, arg5) \
    IOLog(msg, arg1, arg2, arg3, arg4, arg5)

/* Output log */
#define midi_olog(msg, arg1, arg2, arg3, arg4, arg5) \
    IOLog(msg, arg1, arg2, arg3, arg4, arg5)

/* Output log */
#define midi_odatalog(msg, arg1, arg2, arg3, arg4, arg5) \
    IOLog(msg, arg1, arg2, arg3, arg4, arg5)

/* Time log */
#define midi_tlog(msg, arg1, arg2, arg3, arg4, arg5) \
    IOLog(msg, arg1, arg2, arg3, arg4, arg5)

/* Exception log */
#define midi_xlog(msg, arg1, arg2, arg3, arg4, arg5) \
    IOLog(msg, arg1, arg2, arg3, arg4, arg5)

#endif

#if (DEBUG_METHOD==DEBUG_NONE)

#define midi_log(msg,arg1,arg2,arg3,arg4,arg5) 
#define midi_slog(msg) 
#define midi_ilog(msg, arg1, arg2, arg3, arg4, arg5) 
#define midi_idatalog(msg, arg1, arg2, arg3, arg4, arg5) 
#define midi_olog(msg, arg1, arg2, arg3, arg4, arg5) 
#define midi_odatalog(msg, arg1, arg2, arg3, arg4, arg5) 
#define midi_tlog(msg, arg1, arg2, arg3, arg4, arg5) 
#define midi_xlog(msg, arg1, arg2, arg3, arg4, arg5) 

#endif

/* -------------------------------------------------------------------------
 * Globals 
 * 
 * All globals for all units are stored in a single structure, as suggested
 * in kern_loader documentation.
 * -------------------------------------------------------------------------
 */

#define unsigned_int int // Can't figure out how to get unsigned int in mig.

typedef struct {
    port_t owner;
    port_t devPort;

    /* Clock variables */
    int clockMode;
    boolean_t clockRunning;
    int clockDirection; 
    int clockPrevDirection;      /* For determining when direction changes */
    #define FORWARD 1
    #define REVERSE (-1)
    #define NO_DIRECTION 0
    #define LONG_TIME_IN_SEC 0xfffff  /* For differentiating late from wrap */
    struct {
        int us;
        int quantaPerSec;
        int wrapThreshInQuanta;
    } quantum;
    struct timeval baseTimeV;        /* microboot time corresponding to 
                                      * user time 0 (in INTERNAL mode) or
                                      * prevMtc (in MTC_SYNC mode). 
                                      */
    int nextClkInt;                  /* Next scheduled event (user time base)*/
    boolean_t nextClkIntValid;       /* TRUE if nextClkInt has valid val */
    boolean_t timeoutPending;        /* TRUE if abstimeout is scheduled. 
                                      * (Note that we can have nextClkIntValid
                                      * and !timeoutPending if we're stopped or
                                      * we're in MTC synch mode and nextClkInt
                                      * is greater than nextMtc. */

    /* Clock variables used only in INTERNAL mode. */
    struct timeval stoppedTimeV;     /* microboot time when time stopped. */


    /* Clock variables used only in CLOCK_MODE_MTC_SYNC */
    #define NO_SYNC (-1)
    #define NO_UNIT (-1)
    int syncUnit; 
    int prevMtc;                     /* Most recent mtc time (user time base)*/
    struct timeval prevMtcV;         /* Same as a timeval. 
                                      * We keep this separately
                                      * to be able to do an accurate 
                                      * implementation of incrementMTC(). */
    int nextMtc;                     /* Expected next mtc time (user time) */
    struct { 
	unsigned char frames,seconds,minutes,hours,type;
    } mtcTime;
    struct {
	unsigned char op;        /* Set for all ops except real-time msgs */
	int lastQNibble;         /* Used to determine direction of time */
        int sysExCount;          /* loc in sys ex msg parse. 0 if no parse */
        int sysExMsgType;        /* Type */
        #define NO_SYSEX 0       /* No relevant sys ex. (May be other sysex)*/
        #define FULL_SYSEX 1
        #define NAK_SYSEX 2
        int usFrameIndex;        /* Used to get accurate us/frame */
        int usIncIndex;          /* Used to get accurate us/quarter frame */
    } mtcParse;

    /* User alarm variables. */
    port_t userAlarmPort;     
    int userAlarmTime;

    /* Exception variables */
    port_t exceptPort;        

    /* Non-data queue */
    nonDataEvent_t nonDataEventFifo[NONDATA_FIFO_SIZE];
    int nonDataInInd,nonDataOutInd;
    boolean_t nonDataOverrun;

    /* User callout variables */
#if !USE_IO_THREAD
    thread_t rcvDataThread;
#else
    IOThread rcvDataThread;
#endif
    NXConditionLock *rcvCalloutLock;
    #define DATA_AVAILABLE 1
    #define NO_DATA 0
    struct {                        /* Variables for each unit */
	#define INVALID(_unit) (_unit >= MAX_UNITS || !driverObjects[_unit])
        boolean_t claimed;
        #define CLAIMED(_unit) (var.u[_unit].claimed == 1)
#if ppc
        struct zsdevice *addr; // TODO is this necessary to be here considering the registers address both channels?
#endif
	/* Receive (MIDI in) variables */
	boolean_t rcvEnabled;
	boolean_t rcvOverrun;
	port_t rcvPort;              /* Port for sending data to user. Converted for use in IOTask. */
	int rcvInInd, rcvOutInd;
	MDRawEvent rcvFifo[RCV_FIFO_SIZE];
	
	/* Transmit (MIDI out) variables */
	boolean_t xmtInProgress;
	int xmtInInd, xmtOutInd;
	MDRawEvent xmtFifo[XMT_FIFO_SIZE];
        int xmtFlushInd;            /* Used when flushing output queue. */
        #define NO_FLUSH (-1)

	int availableNotify;        /* Used for queue notification */
        port_t queuePort;           /* Port for sending notification. Converted for use in IOTask. */
	
	boolean_t ignore[256];

        boolean_t parseInput;
        struct {
          unsigned char runningStat;
          unsigned char status;
          unsigned char data1;
          int dataBytes;
          boolean_t dataByteSeen;
        } parse;
    } u[MAX_UNITS];
} var_t;

/*
 * Class declaration
 */

@implementation Mididriver

static var_t var;
kern_server_t instance;

/* -------------------------------------------------------------------------
 * Misc. cleanup utilities
 * -------------------------------------------------------------------------
 */
static void resetNonDataQueue(void)
{
    var.nonDataOutInd = 0;
    var.nonDataInInd = 0;
    var.exceptPort = PORT_NULL;
    var.nonDataOverrun = FALSE;
}

static inline void cancelTimeouts(void)
{
    if (var.timeoutPending) {
	ns_untimeout((func)clkInterrupt,0);
	var.timeoutPending = FALSE;
    }
    ns_untimeout((func)checkMTCTimeStopped,0); /* Doesn't hurt to do this if
					    it's not scheduled. */
}

static void clearInputQueue(short unit)
{
    int s = splmidi();
    var.u[unit].rcvOutInd = 0;
    var.u[unit].rcvInInd = 0;
    var.u[unit].rcvPort = PORT_NULL;
    var.u[unit].rcvOverrun = FALSE;
    splx(s);
}

static void clearOutputQueue(short unit)
{
    int s = splmidi();
    var.u[unit].xmtInInd = 0;
    var.u[unit].xmtOutInd = 0;
    var.u[unit].xmtFlushInd = NO_FLUSH;
    var.u[unit].queuePort = PORT_NULL;
    // NO: checkQueueNotify(unit);
    splx(s);
}

static void clearOutputQueuesAndAlarm(void)
    /* Clears queue for all units. Also clears user alarm. */
{
    short unit;
    int s = splmidi();
    cancelTimeouts();
    var.clockPrevDirection = NO_DIRECTION;
    for (unit=0; unit<MAX_UNITS; unit++) 
	if (CLAIMED(unit)) 
	    clearOutputQueue(unit);
    var.userAlarmPort = PORT_NULL;
    splx(s);
}

static void cleanUp(void)
    /* Called when driver ownership is relinquished. */
{
    int s = splmidi();
    short unit;
    var.userAlarmPort = PORT_NULL;
    for (unit=0; unit<MAX_UNITS; unit++) 
	if (CLAIMED(unit))
	    deviceReset(unit);
    resetNonDataQueue();
    cancelTimeouts();
    var.clockRunning = FALSE;
    var.owner = PORT_NULL;
    splx(s);
}

/* -------------------------------------------------------------------------
 * Misc. time routines
 * FIXME
 *  Functions for getting and setting clock information:
 *  clock_value(), set_clock(), clock_attributes(). (microboot() and
 *  microtime() are obsolete.)
 * -------------------------------------------------------------------------
 */
static inline void timevalnormalize(struct timeval *t)
{
  while (t->tv_usec > 1000000) {
    t->tv_usec -= 1000000;
    t->tv_sec++;
  }
  while (t->tv_usec < 0) { /* Not needed? */
    t->tv_usec += 1000000;
    t->tv_sec--;
  }
}

static inline void timevaladd(struct timeval *t1,struct timeval *t2)
{
  t1->tv_sec += t2->tv_sec;
  t1->tv_usec += t2->tv_usec;
  timevalnormalize(t1);
}

static inline void timevalsub(struct timeval *t1,struct timeval *t2)
{
  t1->tv_sec -= t2->tv_sec;
  t1->tv_usec -= t2->tv_usec;
  timevalnormalize(t1);
}

static inline void setStoppedTimeV(void)
{
    microboot(&var.stoppedTimeV);
}

static inline void setBaseTimeV(void)
{
    microboot(&var.baseTimeV);
}

static inline void initTime(void)
{
    setBaseTimeV();
    var.stoppedTimeV = var.baseTimeV;
}

static inline int timevalToTime(struct timeval *tv)
{
    return tv->tv_sec * var.quantum.quantaPerSec + tv->tv_usec / var.quantum.us;
}

static inline void timeToTimeval(int mt,struct timeval *newTv)
{
    newTv->tv_sec = mt / var.quantum.quantaPerSec;
    newTv->tv_usec = (mt % var.quantum.quantaPerSec) * var.quantum.us;
}

static inline boolean_t _timevalLEQ(struct timeval  *a, 
				   struct timeval  *b)
    /* See below */
{
    if (a->tv_sec < b->tv_sec)
	return TRUE;
    else if (b->tv_sec < a->tv_sec) 
        return FALSE;
    return (b->tv_usec >= a->tv_usec) ? TRUE : FALSE;
}

static inline boolean_t _timevalGEQ(struct timeval  *a, 
				   struct timeval  *b)
    /* See below */
{
    if (a->tv_sec > b->tv_sec)
	return TRUE;
    if (b->tv_sec > a->tv_sec) 
	return FALSE;
    return (a->tv_usec >= b->tv_usec) ? TRUE : FALSE;
}

static inline boolean_t timevalLEQ(struct timeval  *a, 
				   struct timeval  *b)
    /* Direction-independent LEQ for timevals */
{
    if (var.clockDirection == FORWARD)
	return _timevalLEQ(a,b);
    else return _timevalGEQ(a,b);
}

static inline boolean_t timevalGEQ(struct timeval  *a, 
				   struct timeval  *b)
    /* Direction-independent GEQ for timevals */
{
    if (var.clockDirection == FORWARD)
	return _timevalGEQ(a,b);
    else return _timevalLEQ(a,b);
}

#define WRAPPED(_small,_big) ((_big - _small) > var.quantum.wrapThreshInQuanta)

static inline boolean_t _timeLEQ(int  a,int  b)
    /* See below */
{
    if (a <= b) 
	if (WRAPPED(a,b))
	    return FALSE;
	else return TRUE;
    else /* a > b */
	if (WRAPPED(b,a))
	    return TRUE;
    return FALSE;
}

static inline boolean_t _timeGEQ(int a,int b)
    /* See below */
{
    if (a >= b) 
	if (WRAPPED(b,a))
	    return FALSE;
	else return TRUE;
    else /* b > a */
	if (WRAPPED(a,b))
	    return TRUE;
    return FALSE;
}

static inline boolean_t timeLEQ(int a,int b)
    /* Direction-independent LEQ for user time base */
{
    if (var.clockDirection == FORWARD)
	return _timeLEQ(a,b);
    else return _timeGEQ(a,b);
}

static inline boolean_t timeGEQ(int a,int b)
    /* Direction-independent LEQ for user time base */
{
    if (var.clockDirection == FORWARD)
	return _timeGEQ(a,b);
    else return _timeLEQ(a,b);
}

static inline boolean_t _timeLessThan(int  a,int  b)
    /* See below */
{
    if (a < b) 
	if (b - a < var.quantum.wrapThreshInQuanta)
	    return TRUE;
	else return FALSE;
    else /* a >= b */
	if (a - b > var.quantum.wrapThreshInQuanta)
	    return TRUE;
    return FALSE;
}

static inline boolean_t _timeGreaterThan(int a,int b)
    /* See below */
{
    if (a > b) 
	if (a - b < var.quantum.wrapThreshInQuanta)
	    return TRUE;
	else return FALSE;
    else /* b >= a */
	if (b - a > var.quantum.wrapThreshInQuanta)
	    return TRUE;
    return FALSE;
}

static inline boolean_t timeLessThan(int a,int b)
    /* Direction-independent < for user time base */
{
    if (var.clockDirection == FORWARD)
	return _timeLessThan(a,b);
    else return _timeGreaterThan(a,b);
}

static inline boolean_t timeGreaterThan(int a,int b)
    /* Direction-independent > for user time base */
{
    if (var.clockDirection == FORWARD)
	return _timeGreaterThan(a,b);
    else return _timeLessThan(a,b);
}

static inline int getCurrentTime(void)
    /* Gets current time and returns it in user time base. 
       Should be called at splmidi to prevent problems involving
       baseTimeV changing out from under us in MTC_SYNC mode. */
{
    struct timeval tv;
    int t;
    if (var.clockRunning) 
        microboot(&tv);
    else {
	if (var.clockMode == MD_CLOCK_MODE_MTC_SYNC) 
	    return var.prevMtc;
	else tv = var.stoppedTimeV;
    }
    timevalsub(&tv,&var.baseTimeV);
    t = timevalToTime(&tv);
    if (var.clockMode == MD_CLOCK_MODE_MTC_SYNC) {
	t += var.prevMtc;
	if (t >= var.nextMtc)   /* Don't let it go beyond nextMtc */
	    t = var.nextMtc - 1;
    }
    return t;
}

static void clockChanged(void)
    /* This is used when the clock has changed (e.g time was reset by user). 
       This function assumes clock mode is INTERNAL. */
{
    if (!var.nextClkIntValid) 
      return;
    cancelTimeouts();
    var.nextClkIntValid = FALSE;      /* Fool requestWakeup() into scheduling */
    requestWakeup(var.nextClkInt);
}

static inline struct timeval *timeoutTime(int later,struct timeval *t)
    /* Compute abstimeout value. 
       (See requestWakeup()--Factored out for clarity) */
{
    if (var.clockMode == MD_CLOCK_MODE_MTC_SYNC) {
	int diff;
	if (var.clockDirection == REVERSE) {
	    if (timeGreaterThan(later,var.prevMtc)) 
	      later = var.prevMtc;
	    diff = var.prevMtc - later;
	} else {                            /* FORWARD */
	    if (timeLessThan(later,var.prevMtc))
	      later = var.prevMtc;
	    diff = later - var.prevMtc;
	}
	timeToTimeval(diff,t);
    }
    else timeToTimeval(later,t);
    /* In MTC_SYNC mode, baseTimeV is the sys 
       time of the last mtc message.  In INTERNAL mode, baseTimeV is the
       time corresponding to user time 0. */
    timevaladd(t,&var.baseTimeV);   
    return t;
}

/* -------------------------------------------------------------------------
 * Important scheduling functions
 * -------------------------------------------------------------------------
 */
static void requestWakeup(int later) {
    /* This reschedules wakeup. Should be called at splmidi().
     */
#define TIMER_PRIORITY CALLOUT_PRI_SOFTINT0 
  /* FIXME Doc says that this has to be CALLOUT_PRI_SOFTINT0 but I used
     CALLOUT_PRI_SOFTINT1 at NeXT! */
    struct timeval t; 
    midi_slog("[requestWakeup \n");
    if (var.nextClkIntValid) 
 	if (timeLEQ(var.nextClkInt,later)) {
	    midi_slog("...requestWakeup 1]\n");
	    return;
	}
	else if (var.timeoutPending)
	    ns_untimeout((func)clkInterrupt,0);
    var.nextClkInt = later;
    var.nextClkIntValid = TRUE;
    if (var.clockRunning && 
	((var.clockMode == MD_CLOCK_MODE_INTERNAL) ||
	 timeLEQ(later,var.nextMtc))) { /* If we're in MTC_SYNC and the
					   next scheduled event is after
					   the nextMtc, we don't sched */
	var.timeoutPending = TRUE;
	ns_abstimeout((func)clkInterrupt,0,timeval_to_ns_time(timeoutTime(later,&t)), TIMER_PRIORITY);
	midi_tlog("later = %d\n",later,2,3,4,5);
	midi_tlog("t = %d min %d sec\n",t.tv_sec,t.tv_usec,3,4,5);
	midi_slog("...requestWakeup timeout scheduled]\n");
    }
    else
	midi_slog("...requestWakeup 2]\n");
}

static int clkInterrupt (void) {
    /* This gets called when there is or may be something to do. */
    int now;
    short unit;
    int s = splmidi();  /* deviceStartXmt() has to run at splmidi. */
    midi_slog("[clkInterrupt \n");
    if (var.owner) {
	now = getCurrentTime();
	var.timeoutPending = FALSE;
	var.nextClkIntValid = FALSE;
	for (unit=0; unit<MAX_UNITS; unit++)
	  /* Added check for CLAIMED()--Oct. 21, 1994 */
	    if (CLAIMED(unit) && var.u[unit].xmtInInd != var.u[unit].xmtOutInd && 
		!var.u[unit].xmtInProgress) 
		deviceStartXmt(now,unit);
	if (var.userAlarmPort) {
	    if (timeLEQ(var.userAlarmTime,now)) {
		nonDataEvent_t e;
		e.data.alarm.replyPort = var.userAlarmPort;
		e.data.alarm.requestedTime = var.userAlarmTime;
		e.type = ALARM_EVENT;
		var.userAlarmPort = PORT_NULL;
		raiseNonDataEvent(&e);
	    }
	    else
		requestWakeup(var.userAlarmTime);
	}
    }
    splx(s);
    midi_slog("...clkInterrupt ]\n");
    return 0;
}

/* -------------------------------------------------------------------------
 * Queue utilities
 * -------------------------------------------------------------------------
 */
static inline int bumpIndex(int oldInd,int max)
    /* Used for circular buffer management */
{
    int newInd = oldInd + 1;
    if (newInd == max)
	newInd = 0;
    return newInd;
}

static inline int isFlushing(int unit)
{
    int f = var.u[unit].xmtFlushInd;
    return (var.u[unit].xmtOutInd != f) && (f != NO_FLUSH);
}

static void checkFlushing(int unit)
{
    if (var.u[unit].xmtOutInd == var.u[unit].xmtFlushInd)
	var.u[unit].xmtFlushInd = NO_FLUSH;	
}

static inline int queueAvailSize(short unit)
    /* Returns available slots in queue. */
{
    int i = var.u[unit].xmtInInd - var.u[unit].xmtOutInd;
    if (i < 0)                 /* Wrap pointer around */
	i += XMT_FIFO_SIZE;
    return XMT_FIFO_SIZE - i - 1; /* -1 because we burn one fifo location
				    * to let us differentiate queue-empty from
				    * queue-full. */
}

static inline void checkQueueNotify(short unit)
    /* Sends a queue notify exception to user if necessary. */
{
    if (var.u[unit].queuePort) 
	if (queueAvailSize(unit) >= var.u[unit].availableNotify) {
	    nonDataEvent_t e;
	    midi_ilog(" notifying queue available = %d\n", var.u[unit].availableNotify,2,3,4,5);
	    e.data.queueNotification.unit = unit;
	    e.data.queueNotification.replyPort = var.u[unit].queuePort;
	    e.type = QUEUE_EVENT;
	    var.u[unit].queuePort = PORT_NULL;
	    raiseNonDataEvent(&e);
	}
}

/* -------------------------------------------------------------------------
 * Parsing MIDI time code.
 * -------------------------------------------------------------------------
 */
/* The following defines must agree with the MIDI time code spec. */
#define TYPE_24 0   
#define TYPE_25 1
#define TYPE_DROP_30 2
#define TYPE_30 3

/* There are 4 types of time code, 24, 25, 30-drop, and 30-no-drop. Only
   drop-frame is tricky.

   Here's the story about drop-frame:

   Color NTSC is only 29.97 frames per second instead of 30.  
   To compensate for this descrepency, 108 frames are eliminated each hour.
   This is done by omitting the first two frames every minute (see exception
   below).  E.g. after 01:08:59:29 comes 01:09:00:02.  The exception is that
   on every 10th minute, frames are not dropped.  This ensures that 108, rather
   than 120 frames are dropped. 

   This means that time code can be behind clock time by as much as
   2 frames @ 29.97 frames/sec. = 60 ms every minute.  Then the time
   code synchs up to within 6 milliseconds of clock time every minute
   (see below). Finally, every 10 minutes, time code synchs up exactly
   with clock time.

   30 frames/" * 59" + 28 frames = 1798 frames
   1798/29.97 = 59.993", which is 6 ms short. 

   I assume that it is on 10 minute boundaries that frames are not dropped or
   is it every 10 minutes from the start of time code. I'm not sure if that's
   right.
   
   So true MTC-to-clock conversion needs to do this:

   ((1/29.97) * frames) + 
   ((30/29.97) * seconds) + 
   ((1/29.97) * (30 * 59 + 28) * (min % 10)) + 
   ((min - (min % 10)) * 60) + 
   hours

   The constants in this formula are defined below:
*/
#define DROP_CONST1 33367       /* 1/29.97 = 0.0333667000333667 */
#define DROP_CONST2 1001001     /* 30/29.97 = 1.001001001001001 */
#define DROP_CONST3 59993327    /* (1/29.97)*(30*59+28) = 59.993326659993336 */

/* The following arrays give us the quarter-frame increment, indexed by 
 * quarter-frame number mod 3. Since 24 and 30-frame rates don't divide 
 * evenly, we drop (or add) one us every 3 times.  However, for 30-drop-frame, 
 * the calculation is already so involved that we don't try to do that.(FIXME?)
 * For 25-frame, it's easy.
 */
static const unsigned int mtcUsPerInc24[] = {10417, 10417, 10416};
#define mtcUsPerInc25 1000
static const unsigned int mtcUsPerInc30[] =  {8333, 8333, 8334};
#define mtcUsPerInc30Drop 8341

static inline int mtcUsPerInc(void)
{
    switch (var.mtcTime.type) {
      case TYPE_24:
	var.mtcParse.usIncIndex = bumpIndex(var.mtcParse.usIncIndex,3);
	return mtcUsPerInc24[var.mtcParse.usIncIndex];
      case TYPE_25:
	return mtcUsPerInc25;
      case TYPE_DROP_30:
	return mtcUsPerInc30Drop;
      default:
      case TYPE_30:
	var.mtcParse.usIncIndex = bumpIndex(var.mtcParse.usIncIndex,3);
	return mtcUsPerInc30[var.mtcParse.usIncIndex];
    }
}

/* The following arrays give us the us-per-frame value.
 * Since 24 and 30-frame rates don't divide evenly, we drop (or add) 
 * one us every 3 frames.  As above, we don't bother to do the already-
 * complicated drop frame. (FIXME?)
 */
static const unsigned int mtcUsPerFrame24[] = {41667,41667,41666};
#define mtcUsPerFrame25 40000
static const unsigned int mtcUsPerFrame30[] = {33333,33333,33334};
#define mtcUsPerFrame30Drop DROP_CONST1

static inline int mtcUsPerFrame(void)
{
    switch (var.mtcTime.type) {
      case TYPE_24:
	var.mtcParse.usFrameIndex = bumpIndex(var.mtcParse.usFrameIndex,3);
	return mtcUsPerFrame24[var.mtcParse.usFrameIndex];
      case TYPE_25:
	return mtcUsPerFrame25;
      case TYPE_DROP_30:
	return mtcUsPerFrame30Drop;
      default:
      case TYPE_30:
	var.mtcParse.usFrameIndex = bumpIndex(var.mtcParse.usFrameIndex,3);
	return mtcUsPerFrame30[var.mtcParse.usFrameIndex];
    }
}

static void mtcClk(int us)
    /* This function does any work necessary at each MIDI time code msg. 
     * Could optimize this by setting prevMtcV to nextMtcV and then
     * computing new nextMtcV.  But for now I'm not doing it the dumb
     * way to avoid confusion. 
     */
{
    struct timeval t;
    setBaseTimeV();
    if (var.clockDirection == REVERSE) {
	t.tv_usec = var.prevMtcV.tv_usec - us;
	if (var.prevMtcV.tv_sec < 0) {
	    t.tv_sec = var.prevMtcV.tv_sec - 1;
	    t.tv_usec += 1000000;
	} else t.tv_sec = var.prevMtcV.tv_sec;
    }
    else {
	t.tv_usec = var.prevMtcV.tv_usec + us;
	if (var.prevMtcV.tv_sec > 1000000) {
	    t.tv_sec = var.prevMtcV.tv_sec + 1;
	    t.tv_usec -= 1000000;
	} else t.tv_sec = var.prevMtcV.tv_sec;
    }
    if (var.clockRunning) 
      var.prevMtc = var.nextMtc;
    else  /* First one */
      var.prevMtc = timevalToTime(&var.prevMtcV);
    var.nextMtc = timevalToTime(&t);
    if (var.nextClkIntValid && 
	timeLessThan(var.nextClkInt,var.nextMtc)) {
	midi_tlog("mtcClk: alarm timed out.\n",1,2,3,4,5);
	midi_tlog("var.nextClkInt: %d, var.nextMtc: %d\n",
		  var.nextClkInt,
		  var.prevMtc,3,4,5);
	clkInterrupt();
    }
}

static void setTimeFromMtc(boolean_t quarterFrameForward)
    /* MIDI time code spec stipulates that time must be set every 8 messages */
{
    static const unsigned int mtcFramesPerSec[] = {24,25,30,30};
    int i = mtcFramesPerSec[var.mtcTime.type];
    int us = mtcUsPerFrame();
    if (quarterFrameForward) { /* add 2 to frame count here (cf spec) */
	var.mtcTime.frames += 2;
	if (var.mtcTime.frames >= i) {
	    var.mtcTime.frames -= i;
	    var.mtcTime.seconds++;
	}
    }
    if (var.mtcTime.type == TYPE_DROP_30) {
	/* See drop frame discussion above */
	long minLow,minHigh;
	var.prevMtcV.tv_usec = var.mtcTime.frames * us;
	var.prevMtcV.tv_usec += DROP_CONST2*var.mtcTime.seconds; /* sec (us) */
	minLow = var.mtcTime.minutes % 10; /* Low 10 minutes */
	minHigh = var.mtcTime.minutes - minLow; /* Other minutes */
	var.prevMtcV.tv_usec += DROP_CONST3 * minLow; /* Low min in us */
	var.prevMtcV.tv_sec = minHigh * 60 + var.mtcTime.hours * (60 * 60);
	if (var.prevMtcV.tv_usec > 1000000) {
	    var.prevMtcV.tv_sec += var.prevMtcV.tv_usec / 1000000;
	    var.prevMtcV.tv_usec %= 1000000;
	}
    }
    else {
	var.prevMtcV.tv_usec = var.mtcTime.frames * us;
	var.prevMtcV.tv_sec = (var.mtcTime.seconds + var.mtcTime.minutes * 60 +
			       var.mtcTime.hours * (60 * 60));
    }
    midi_tlog("setTimeFromMtc sets time to %d \"%d us\n",
	      var.prevMtcV.tv_sec,
	      var.prevMtcV.tv_usec,3,4,5);
    mtcClk(mtcUsPerInc());
}

static void incrementMTC(void)
    /* MIDI time code spec stipulates that time should be incremented between
     * 8 messages */
{
    int us = mtcUsPerInc();
    switch (var.clockDirection) {
      case FORWARD:
	var.prevMtcV.tv_usec += us;  
	if (var.prevMtcV.tv_usec > 1000000) {
	    var.prevMtcV.tv_usec -= 1000000;
	    var.prevMtcV.tv_sec++;
	}
	break;
      case REVERSE:
	var.prevMtcV.tv_usec -= us;  
	if (var.prevMtcV.tv_usec < 0) {
	    var.prevMtcV.tv_usec += 1000000;
	    var.prevMtcV.tv_sec--;
	}
	break;
    }
    midi_tlog("incrementTimeFromMtc sets time to %d \"%d us\n",
	      var.prevMtcV.tv_sec,
	      var.prevMtcV.tv_usec,3,4,5);
    mtcClk(us);
}

static int checkMTCTimeStopped(void) {
    #define TV_TO_MS(_x) (_x.tv_sec * 1000 + _x.tv_usec / 1000)
    struct timeval inc = {1, 0};
    struct timeval t;
    microboot(&t);
    if (!var.clockRunning || (var.clockMode != MD_CLOCK_MODE_MTC_SYNC))
	return 0;  /* Already stopped */
    if (TV_TO_MS(t) > TV_TO_MS(var.baseTimeV) + 500)
	/* No time code for half a second. */
	stopMtcSync();
    else ns_timeout((func)checkMTCTimeStopped,0,timeval_to_ns_time(&inc),TIMER_PRIORITY);
    return 0;
}

static void startMtcSync(int newDirection)
    /* This is called when mtc starts. */
{
    struct timeval inc = {1, 0};
    var.clockDirection = newDirection;
    if (!var.clockRunning || var.clockDirection != newDirection) {
	if (var.clockPrevDirection == -newDirection) 
	    clearOutputQueuesAndAlarm();
	var.clockPrevDirection = newDirection;
	ns_untimeout((func)checkMTCTimeStopped,0);
        ns_timeout((func)checkMTCTimeStopped,0,timeval_to_ns_time(&inc),TIMER_PRIORITY);
	raiseException(newDirection == FORWARD ?
		       MD_EXCEPTION_MTC_STARTED_FORWARD :
		       MD_EXCEPTION_MTC_STARTED_REVERSE);
    }
    var.clockRunning = TRUE;
}

static void stopMtcSync(void)
    /* This is called when mtc stops. */
{
    if (var.clockMode == MD_CLOCK_MODE_MTC_SYNC &&
	var.clockRunning) {
	var.clockRunning = FALSE;
	raiseException(MD_EXCEPTION_MTC_STOPPED);
    }
}

static void abortMtcParse()
{
    var.mtcParse.usFrameIndex = 0;
    var.mtcParse.usIncIndex = 0;
    var.mtcParse.op = 0;
    var.mtcParse.sysExCount = 0;
    var.mtcParse.sysExMsgType = NO_SYSEX;
}

static inline void checkMtcDirection(int expectedLastForward,
				     int expectedLastReverse)
{
    /* This logic takes 2 mtc bytes before it notices that mtc time has
     * started (rather than 1, as specified in mtc spec), but this should
     * be good enough.
     */
    if ((var.clockDirection != FORWARD || 
	 !var.clockRunning) 
	&& (var.mtcParse.lastQNibble == expectedLastForward))
	startMtcSync(FORWARD);
    else if ((var.clockDirection != REVERSE || 
	      !var.clockRunning) 
	     && (var.mtcParse.lastQNibble == expectedLastReverse))
	startMtcSync(REVERSE);
}

static inline void setMtcLow(unsigned char *var,unsigned char data)
{
    *var &= 0xf0; /* Clear old low bits */
    *var |= data; /* Set new low bits */
}

static inline void setMtcHigh(unsigned char *var,unsigned char data)
{
    *var &= 0x0f;       /* Clear old high bits */
    *var |= (data << 4);/* Set new high bits */
}

/* Returns TRUE if it's a status byte */
#define TYPE_STATUS(byte) ((byte)&0x80)

static inline boolean_t mtcParse(unsigned char byte,short unit)
{
    /* If we made it to here, we've got to parse MIDI time code. */
    if (TYPE_STATUS(byte))
	switch (byte) {
	  case MIDI_CLOCK: case 0xf9: case MIDI_START: case MIDI_CONTINUE: 
	  case MIDI_STOP: case 0xfd: case MIDI_ACTIVE: case MIDI_RESET:
	    /* System real time -- can appear anywhere */
	    return var.u[unit].ignore[byte];
	  case MIDI_TIMECODEQUARTER:
	    var.mtcParse.op = byte;
	    return TRUE;
	  case MIDI_SYSEXCL:  
	    var.mtcParse.op = byte;
	    var.mtcParse.sysExCount = 1;
	    return FALSE;
	  case MIDI_EOX:  
	    switch (var.mtcParse.sysExMsgType) {
	      case FULL_SYSEX:  /* time code is stopped */
		abortMtcParse();
		stopMtcSync();
		setTimeFromMtc(FALSE);
		midi_tlog("***Full frame frames %d seconds %d minutes %d hours %d\n",
			  var.mtcTime.frames,
			  var.mtcTime.seconds,
			  var.mtcTime.minutes,
			  var.mtcTime.hours,
			  5);
		return FALSE; 
	      case NAK_SYSEX:   /* another way to know time code is stopped */
		abortMtcParse();
		stopMtcSync();
		return FALSE;
	      case NO_SYSEX:
		return FALSE;
	    }
	  default:  	               /* Other status */
	    var.mtcParse.op = byte;
	    return FALSE;
	}

    /* If we made it here, it's a data byte */
    switch (var.mtcParse.op) {         /* Look up previously-stored status */
      case MIDI_TIMECODEQUARTER: {
	  int curNibble = byte >> 4;
	  switch (curNibble) {
	    case 0:
	      checkMtcDirection(7,1);
	      setMtcLow(&var.mtcTime.frames,byte & 0xf);
	      if (var.clockDirection == REVERSE)
		  setTimeFromMtc(FALSE);
	      else incrementMTC();
	      break;
	    case 1:
	      checkMtcDirection(0,2);
	      setMtcHigh(&var.mtcTime.frames,byte & 0x1);
	      incrementMTC();
	      break;
	    case 2:
	      checkMtcDirection(1,3);
	      setMtcLow(&var.mtcTime.seconds,byte & 0xf);
	      incrementMTC();
	      break;
	    case 3:
	      checkMtcDirection(2,4);
	      setMtcHigh(&var.mtcTime.seconds,byte & 0x3);
	      incrementMTC();
	      break;
	    case 4:
	      checkMtcDirection(3,5);
	      setMtcLow(&var.mtcTime.minutes,byte & 0xf);
	      incrementMTC();
	      break;
	    case 5:
	      checkMtcDirection(4,6);
	      setMtcHigh(&var.mtcTime.minutes,byte & 0x3);
	      incrementMTC();
	      break;
	    case 6:
	      checkMtcDirection(5,7);
	      setMtcLow(&var.mtcTime.hours,byte & 0xf);
	      incrementMTC();
	      break;
	    case 7:
	      checkMtcDirection(4,0);
	      setMtcHigh(&var.mtcTime.hours,byte & 0x1);
	      var.mtcTime.type = (byte & 0x6) >> 1;
	      if (var.clockDirection == FORWARD) 
		  setTimeFromMtc(TRUE);
	      else incrementMTC();
	      break;
	  } /* End of nibble case */
	  var.mtcParse.lastQNibble = curNibble;
	  return TRUE;
      }   /* End of TIMECODEQ case */
      case MIDI_SYSEXCL: {
	  #define ANY_BYTE 0
	  static const unsigned char fullMsgHeader[] = {0xf0,0x7f,0x7f,1,1};
	  static const unsigned char nakMsgHeader[] = {0xf0,0x7e,ANY_BYTE,0x7e,ANY_BYTE};
	  switch (var.mtcParse.sysExCount) {
	    case 0:
	      return FALSE;
	    case 1:
	      if (byte == fullMsgHeader[var.mtcParse.sysExCount]) {
		  var.mtcParse.sysExMsgType = FULL_SYSEX;
		  var.mtcParse.sysExCount++;
	      }
	      else if (byte == nakMsgHeader[var.mtcParse.sysExCount]) {
		  var.mtcParse.sysExMsgType = NAK_SYSEX;
		  var.mtcParse.sysExCount++;
	      }
	      else abortMtcParse();
	      return FALSE;
	    default:
	      break;
	  }

	  /* If we made it to here, we're at least up to the 2nd byte of
	   * sys ex. */ 
	  switch (var.mtcParse.sysExMsgType) {
	    case FULL_SYSEX:
	      if (var.mtcParse.sysExCount < 5) {
		  if (byte != fullMsgHeader[var.mtcParse.sysExCount++]) 
		      abortMtcParse();
		  return FALSE;
	      } else switch (var.mtcParse.sysExCount++) {
		case 5: 
		  var.mtcTime.type = (byte & 0x60) >> 5;
		  var.mtcTime.hours = byte & 0x1f;
		  return FALSE;
		case 6: 
		  var.mtcTime.minutes = byte & 0x3f;
		  return FALSE;
		case 7: /* seconds */
		  var.mtcTime.seconds = byte & 0x3f;
		  return FALSE;
		case 8: /* frames */
		  var.mtcTime.frames = byte & 0x1f;
		  return FALSE;
	      }
	    case NAK_SYSEX:
	      if (byte != nakMsgHeader[var.mtcParse.sysExCount] &&
		  nakMsgHeader[var.mtcParse.sysExCount] != ANY_BYTE)
		  abortMtcParse();
	      else var.mtcParse.sysExCount++;
	      return FALSE;
	  }   /* End of type switch */
      }   /* End of status SYSEXCL case */
      default:
	return FALSE;
    } /* End of status switch */
    return FALSE;  /* This stmt will never be reached--make compiler happy */
}

/* -------------------------------------------------------------------------
 * Receiving MIDI data.  
 *
 * We use a separate thread for sending data to user to avoid deadlock in
 * intense MIDI loop situations.
 * -------------------------------------------------------------------------
 */

static char portName(short unit)
{
    return (unit == 1) ? 'B' : 'A';
}
 
#define INCOMPLETE 0
#define VARIABLE 4
#define EOX 5

static unsigned char parseMidiStatusByte(short unit,unsigned char statusByte)
    /* This is called when a status byte is found. Returns 1 if byte is a 
     * one-byte MIDI message.  Returns EOX if it's a complete SYSEX message. 
     */
{
    switch (MIDI_OP(statusByte)) {
      case MIDI_PROGRAM: case MIDI_CHANPRES:
	var.u[unit].parse.status = var.u[unit].parse.runningStat = statusByte;
	var.u[unit].parse.dataBytes = 1;
	return INCOMPLETE;
      case MIDI_NOTEON:  case MIDI_NOTEOFF: case MIDI_POLYPRES:
      case MIDI_CONTROL: case MIDI_PITCH:
	var.u[unit].parse.status = var.u[unit].parse.runningStat = statusByte;
	var.u[unit].parse.dataBytes = 2;
	var.u[unit].parse.dataByteSeen = FALSE;
	return INCOMPLETE;
      case MIDI_SYSTEM:
	if (statusByte & MIDI_SYSRTBIT) {
	    switch (statusByte) {  
	      case MIDI_CLOCK:  case MIDI_START: case MIDI_STOP:
	      case MIDI_ACTIVE: case MIDI_RESET: case MIDI_CONTINUE:
		return 1; /* Doesn't affect running status. Also doesn't 
			   * affect dataBytes because real-time messages 
			   * may occur anywhere, even in a system exclusive 
			   * message. 
			   */
	      default:    /* Omit unrecognized status. */
		return INCOMPLETE;         
	    }                      
	}
	var.u[unit].parse.runningStat = 0;
	var.u[unit].parse.status = statusByte;
	switch (statusByte) {
	  case MIDI_SONGPOS:
	    var.u[unit].parse.dataBytes = 2;
	    var.u[unit].parse.dataByteSeen = FALSE;
	    return INCOMPLETE;
	  case MIDI_TIMECODEQUARTER: case MIDI_SONGSEL:
	    var.u[unit].parse.dataBytes = 1;
	    return INCOMPLETE;
	  case MIDI_SYSEXCL:
	    var.u[unit].parse.dataBytes = VARIABLE;
	    return VARIABLE;
	  case MIDI_TUNEREQ:         
	    var.u[unit].parse.dataBytes = 0;
	    return 1;
	  case MIDI_EOX: {          
	      boolean_t isInSysEx = (var.u[unit].parse.dataBytes == VARIABLE);
	      var.u[unit].parse.dataBytes = 0;
	      return (isInSysEx) ? EOX : 0;
	  }
	}
      default:                 /* Garbage */
	var.u[unit].parse.dataBytes = 0;
    }
    return INCOMPLETE;             
}   

static int parseMidiByte(short unit,unsigned char aByte)
    /* Takes an incoming byte and parses it. Returns 0 if incomplete.
     * Returns 1, 2 or 3 if complete. Returns VARIABLE if system exclusive.
     * Returns MIDI_EOX if complete system exclusive. 
     */
{
  doit:
    if (MIDI_STATUSBIT & aByte)  
      return parseMidiStatusByte(unit,aByte);
    switch (var.u[unit].parse.dataBytes) {
      case 0:                      /* Running status or garbage */
	if (!var.u[unit].parse.runningStat)  /* Garbage */
	  return INCOMPLETE;
	parseMidiStatusByte(unit,var.u[unit].parse.runningStat);
	goto doit;
      case 1:                      /* One-argument midi message. */
	var.u[unit].parse.data1 = aByte;
	var.u[unit].parse.dataBytes = 0;  /* Reset */
	return 2;
      case 2:                      /* Two-argument midi message. */
	if (var.u[unit].parse.dataByteSeen) {
	    var.u[unit].parse.dataBytes = 0;
	    return 3;
	}
	var.u[unit].parse.data1 = aByte;
	var.u[unit].parse.dataByteSeen = TRUE;
	return INCOMPLETE;
      case VARIABLE:
	return VARIABLE;
      default:
	return INCOMPLETE;
    }
}

static int dieThread = 0;

#if !USE_IO_THREAD
static void dataReplyThreadProc(void)
#else
static void dataReplyThreadProc(void *arg)
#endif
    /* Main body of dataReply thread */
{
    MDRawEvent data[MD_MAX_EVENT];    
    /* This buffer is smaller than the FIFO because it will be 
     * copied to the MIG message and MIG puts the message it conses 
     * up on the small kernel stack. */
    short unit;
    for (;;) {
        [var.rcvCalloutLock lockWhen:DATA_AVAILABLE];
	[var.rcvCalloutLock unlockWith:NO_DATA];
#if !USE_IO_THREAD
//	while (thread_should_halt(current_thread())) 
//	    /* GK sez this is right */
//	    thread_halt_self(); 
	if (dieThread)
	  thread_halt_self();
#else
	if (dieThread)
	  IOExitThread();
#endif
	/* We can be at spl 0.  The worst that can happen is that we will miss 
	   a byte because var.u[unit].rcvInInd will be bumped 
	   while we're testing it.  In that case, since we set callout to 
	   false BEFORE the test, another callout will be queued by the 
	   interrupt routine.  
	   */
	if (!var.owner) 
	    continue;
	midi_slog("[running reply thread\n");
	while (var.nonDataOutInd != var.nonDataInInd) {
	    nonDataEvent_t e = var.nonDataEventFifo[var.nonDataOutInd];
	    var.nonDataOutInd = bumpIndex(var.nonDataOutInd,NONDATA_FIFO_SIZE);
	    midi_xlog("Sending nonData type %d \n",e.type,2,3,4,5);
	    switch (e.type) {
	      case QUEUE_EVENT:
		MDQueueReply(e.data.queueNotification.replyPort,
			       e.data.queueNotification.unit);


		break;
	      case ALARM_EVENT: 
		{
		    int s = splmidi();  
		    int actualTime = getCurrentTime();
		    splx(s);
		    MDAlarmReply(e.data.alarm.replyPort, 
				   e.data.alarm.requestedTime, 
				   actualTime);
		}
		break;
	      case EXCEPTION_EVENT:
		MDExceptionReply(var.exceptPort, e.data.exception);
		break;
	    }
	}
	for (unit=0; unit<MAX_UNITS; unit++) {
	    if (CLAIMED(unit)) {
		int count,n;
		MDRawEvent datum;
		int time;
		while (var.u[unit].rcvOutInd != var.u[unit].rcvInInd) {
		    count = 0;
		    while (var.u[unit].rcvOutInd != var.u[unit].rcvInInd
			   && count < (MD_MAX_EVENT-2)) {
			/* -2 to make sure there's room for parsed data. 
			 * (We really need room for 3 but 1 is implicit in
			 * the '<'.) 
			 */
			datum = var.u[unit].rcvFifo[var.u[unit].rcvOutInd];
			var.u[unit].rcvOutInd = 
			    bumpIndex(var.u[unit].rcvOutInd,RCV_FIFO_SIZE);
			if (var.u[unit].parseInput) {
			    n = parseMidiByte(unit,datum.byte);
			    if (var.u[unit].ignore[var.u[unit].parse.status])
				continue;
			    switch (n) {
			      case 0:  /* Incomplete or garbage */
				break;
			      case 1:
			      case VARIABLE:
				data[count++] = datum;
				break;
			      case EOX:
				data[count++] = datum;
				goto sendData;
			      case 2:
				time = datum.time;
				data[count].time = time;
				data[count++].byte = var.u[unit].parse.status;
				data[count++] = datum;
				break;
			      case 3:
				time = datum.time;
				data[count].time = time;
				data[count++].byte = var.u[unit].parse.status;
				data[count].time = time;
				data[count++].byte = var.u[unit].parse.data1;
				data[count++] = datum;
				break;
			    }
			}
			else data[count++] = datum;
		    }
		  sendData:
		    if (count > 0) {
			kern_return_t r;
			midi_ilog(" data_reply thread forwards %d bytes\n",
				  count,2,3,4,5);
			r = MDDataReply(var.u[unit].rcvPort, unit, data, count);
			midi_ilog(" MDDataReply callout returns %d\n", r,2,3,4,5);
			if (r != KERN_SUCCESS) {
			    /* If error is -102, it means that the port
			     * died without releasing ownership. */
			    break; 
			}
		    }
		}
		if (var.u[unit].rcvOverrun) {
		    PRINTF("MIDI driver data overrun on serial port %c\n",
			   portName(unit));
		    var.u[unit].rcvOverrun = FALSE;
		}
	    }
	}
	if (var.nonDataOverrun) {
	    PRINTF("MIDI driver exception overrun\n");
	    var.nonDataOverrun = FALSE;
	}
	midi_slog("...reply_thread]\n");
    }
}

static inline boolean_t shouldFilter(unsigned char byte,short unit) {
    if (unit != var.syncUnit) 
	switch (byte) {
	  case MIDI_CLOCK: case 0xf9: case MIDI_START: case MIDI_CONTINUE: 
	  case MIDI_STOP: case 0xfd: case MIDI_ACTIVE: case MIDI_RESET:
	    /* System real time -- can appear anywhere */
	    return var.u[unit].ignore[byte];
	  default:
	    return FALSE;
	}
    return mtcParse(byte,unit);
}

/* -------------------------------------------------------------------------
 * Asynchronous exceptions
 * -------------------------------------------------------------------------
 */
static void raiseNonDataEvent(nonDataEvent_t *e)
{
    int newInd = bumpIndex(var.nonDataInInd,NONDATA_FIFO_SIZE);
    if (newInd == var.nonDataOutInd) {
	var.nonDataOverrun = TRUE;
	midi_log("***except overrun***\n",1,2,3,4,5);
    }
    else {
	var.nonDataEventFifo[var.nonDataInInd] = *e;
	var.nonDataInInd = newInd;
    }
    [var.rcvCalloutLock lock];
    [var.rcvCalloutLock unlockWith:DATA_AVAILABLE];
}

static void raiseException(int ex)
    /* Generates an exception.  This must be called at splmidi() */
{
    if (var.exceptPort) {
	nonDataEvent_t e;
	e.type = EXCEPTION_EVENT;
	e.data.exception = ex;
	raiseNonDataEvent(&e);
    }
}

// should be linked in eventually rather than included
#if i386
#import "mpu401.m"
#endif
#if ppc
#import "zs8530.m"
#endif

#warning Sub-unit choice disabled 
static int checkTransmitSubunit(int unit)
{
#if 0
  static int prevTransmitSubunit = 0; /* FIXME Need to make this a vector */
  if (unit != prevTransmitSubunit) {
    if (setTransmitSubunit(unit) == 0)
 	 prevTransmitSubunit = unit;
  }
#endif
  return 1;
}

/* ------------------------------------------------------------------- 
 * Interface functions, exported to the user via MIG. 
 * ------------------------------------------------------------------- 
 */
#define EXPORTED 

/******* Functions required by kern_loader *********************/

EXPORTED void _MDInit(void) {
    /* Load handler */
#if (DEBUG_METHOD==DEBUG_DDM)
    IOInitDDM(16);
#endif
    ASSERT(sizeof(MDRawEvent)==8); /* mididriver_common.defs */
    var.rcvCalloutLock = [[NXConditionLock alloc] initWith:NO_DATA];
}

EXPORTED void _MDSignoff(void) {
    /* Unload handler */
    cleanUp();
#if !USE_IO_THREAD
    dieThread = 1;
    thread_terminate((thread_t)var.rcvDataThread);
    var.rcvDataThread = (thread_t)0;
#else
    dieThread = 1;
    IOResumeThread(var.rcvDataThread);
    var.rcvDataThread = (IOThread)0;
#endif
    [var.rcvCalloutLock lock]; /* Fake lock to get thread to wake up */
    [var.rcvCalloutLock unlockWith:DATA_AVAILABLE];
    PRINTF("MIDI driver unloaded\n");
}

EXPORTED boolean_t _MDPortDeath(port_name_t port) {
    if (var.owner == port) {
	cleanUp();
//	PRINTF("MIDI driver released resources\n");
	return TRUE;
    }
    return FALSE;
}

/******* Managing ownership of the driver ********/
EXPORTED kern_return_t 
  MDBecomeOwner(port_t device_port, port_t owner_port) {
    /* Becoming owner of the driver and initializing time. */
    if (var.owner) {
	PRINTF("MDBecomeOwner failed: device is busy.\n");
	return MD_ERROR_BUSY;
    }
    var.devPort = device_port;
    var.owner = owner_port;
    var.clockMode = MD_CLOCK_MODE_INTERNAL;
    var.syncUnit = NO_SYNC;
    var.clockDirection = FORWARD;
    var.clockPrevDirection = NO_DIRECTION;
    MDSetClockQuantum(device_port,owner_port,1000);
    initTime();
    var.timeoutPending = FALSE;
    var.nextClkIntValid = FALSE;
    var.userAlarmPort = PORT_NULL;
    var.exceptPort = PORT_NULL;
    if (!var.rcvDataThread) { /* Do it the first time only */
    midi_slog("Starting receive Thread\n");
#if !USE_IO_THREAD
	var.rcvDataThread = kernel_thread(current_task(),dataReplyThreadProc);
#else
	var.rcvDataThread = IOForkThread(dataReplyThreadProc,NULL);
#endif
    }
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDReleaseOwnership(port_t device_port,port_t owner_port) {
    /* Releasing ownership of driver. */
    if (_MDPortDeath(owner_port))
	return KERN_SUCCESS;
    else return MD_ERROR_NOT_OWNER;
}

/********* Claiming a particular serial port ("unit") ********/
EXPORTED kern_return_t 
  MDClaimUnit(port_t device_port,port_t owner_port,short unit) {
    /* Claiming a particular serial port ("unit"). */
    int i;

    midi_log("MIDI driver attempting to claim serial port %c.\n", portName(unit), 2, 3, 4, 5);

    if (var.owner != owner_port)     
	return MD_ERROR_NOT_OWNER;
    if (INVALID(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    if (CLAIMED(unit))
	return KERN_SUCCESS;       /* Already claimed */
    if (!deviceInit(unit)) {
	PRINTF("MDClaimUnit failed: can't init serial port.\n");
	return MD_ERROR_UNIT_UNAVAILABLE;
    }
    midi_log("MIDI driver claimed serial port %c.\n", portName(unit), 2, 3, 4, 5);
    var.u[unit].xmtInProgress = FALSE;
    var.u[unit].rcvEnabled = FALSE;
    var.u[unit].parseInput = FALSE;
    for (i=0; i<256; i++) 
	var.u[unit].ignore[i] = 0;
    clearInputQueue(unit);
    clearOutputQueue(unit);
    deviceEnable(unit);
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDReleaseUnit(port_t device_port,port_t owner_port,short unit) {
    /* Releasing a particular serial port ("unit"). */
    if (var.owner != owner_port)     
	return MD_ERROR_NOT_OWNER;
    if (INVALID(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    if (!CLAIMED(unit))
	return KERN_SUCCESS;
    if (var.syncUnit == unit) 
	var.syncUnit = NO_SYNC;
    deviceReset(unit);
    midi_log("MIDI driver released serial port %c.\n", portName(unit), 2, 3, 4, 5);
    return KERN_SUCCESS;
}

/******** Controlling the clock ****************/
EXPORTED kern_return_t 
  MDSetClockMode(port_t device_port,port_name_t owner_port, 
		   short unit, int mode) {
    if (owner_port == var.owner) {
	/* FIXME might need splmidi here */
	if (mode != var.clockMode || unit != var.syncUnit) /* Not the same */
	    switch (mode) {
	      case MD_CLOCK_MODE_INTERNAL:
		var.syncUnit = NO_SYNC;
		var.clockRunning = FALSE;
		var.clockMode = mode;
		initTime();
		clearOutputQueuesAndAlarm();
		break;
	      case MD_CLOCK_MODE_MTC_SYNC:
		if (INVALID(unit))
		    return MD_ERROR_UNIT_UNAVAILABLE;
		else if (!CLAIMED(unit)) 
		    return MD_ERROR_UNIT_UNAVAILABLE;
		var.syncUnit = unit;
		var.clockRunning = FALSE;
		var.clockMode = mode;
		initTime();
		var.prevMtc = var.nextMtc = 0;
		clearOutputQueuesAndAlarm();
		break;
	      default:
		return MD_ERROR_BAD_MODE;
	    }
	return KERN_SUCCESS;
    }
    return MD_ERROR_NOT_OWNER;
}

EXPORTED kern_return_t 
  MDSetClockQuantum(port_t device_port,port_t owner_port,
			      int microseconds)
{
    /* Setting up clock quantum. */
    int s;
    if (var.owner != owner_port)     
	return MD_ERROR_NOT_OWNER;
    if (microseconds == var.quantum.us)
	return KERN_SUCCESS;
    if (microseconds < 1)
      microseconds = 1;
    s = splmidi();
    clearOutputQueuesAndAlarm();
    var.quantum.us = microseconds;
    var.quantum.quantaPerSec = 1000000/microseconds; 
    var.quantum.wrapThreshInQuanta = (LONG_TIME_IN_SEC * 
				      var.quantum.quantaPerSec);
    splx(s);
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDSetClockTime(port_t device_port,port_name_t owner_port,int time){
    struct timeval t1,t2;
    int s;
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    if (var.clockMode == MD_CLOCK_MODE_MTC_SYNC) /* MTC sets time */
	return MD_ERROR_ILLEGAL_OPERATION;
    s = splmidi();
    if (var.clockRunning) 
        microboot(&t2);
    else t2 = var.stoppedTimeV;
    /* We want time-baseTimeV = requestedTime. 
     * We can't change time, since it's gotten from the system.
     * So we set baseTimeV = time - requestedTime
     */
    timeToTimeval(time,&t1);
    timevalsub(&t2,&t1);  /* t2 -= t1. */
    var.baseTimeV = t2;
    clockChanged();
    splx(s);
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDGetClockTime(port_t device_port,port_name_t owner_port,
		   int *time) {
    int s = splmidi();
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    *time = getCurrentTime();
    splx(s);
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDGetMTCTime(port_t device_port,port_name_t owner_port, 
			  short *format,short *hours,short *minutes,
			  short *seconds,short *frames) {
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    if (var.clockMode != MD_CLOCK_MODE_MTC_SYNC) /* MTC sets time */
	return MD_ERROR_ILLEGAL_OPERATION;
    *format = var.mtcTime.type;
    *hours = var.mtcTime.hours;
    *minutes = var.mtcTime.minutes;
    *seconds = var.mtcTime.seconds;
    *frames = var.mtcTime.frames;
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDStartClock(port_t device_port,port_name_t owner_port) {
    int s;
    struct timeval t;
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    if (var.clockMode == MD_CLOCK_MODE_MTC_SYNC) /* MTC sets time */
	return MD_ERROR_ILLEGAL_OPERATION;
    if (var.clockRunning)
	return KERN_SUCCESS;
    s = splmidi();
    /* We want bNew = tNew - (tOld - bOld) = tNew + (bOld - tOld) */
    timevalsub(&var.baseTimeV,&var.stoppedTimeV); /* baseTimeV -= old time */
    microboot(&t);
    timevaladd(&var.baseTimeV,&t);                /* baseTimeV += new time */
    var.clockPrevDirection = var.clockDirection;
    var.clockDirection = FORWARD;
    var.clockRunning = TRUE;       /* Must be before clockChanged() */
    clockChanged();
    splx(s);
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDStopClock(port_t device_port, port_name_t owner_port) {
    int s;
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    if (var.clockMode == MD_CLOCK_MODE_MTC_SYNC) /* MTC sets time */
	return MD_ERROR_ILLEGAL_OPERATION;
    if (!var.clockRunning)
	return KERN_SUCCESS;
    s = splmidi();
    setStoppedTimeV();
    cancelTimeouts();
    var.clockRunning = FALSE;
    splx(s);
    return KERN_SUCCESS;
}

/****************** Requesting asynchronous messages *******************/
EXPORTED kern_return_t 
  MDRequestData(port_t device_port,port_name_t owner_port,short unit,
			  port_t rPort) { 
    if (owner_port == var.owner) {
	if (INVALID(unit) || !CLAIMED(unit)) 
	    return MD_ERROR_UNIT_UNAVAILABLE;
	var.u[unit].rcvOverrun = FALSE;
#if USE_IO_THREAD
        var.u[unit].rcvPort = IOConvertPort(rPort, IO_CurrentTask, IO_KernelIOTask);
#else
	var.u[unit].rcvPort = rPort;
#endif
	return KERN_SUCCESS;
    }
    return MD_ERROR_NOT_OWNER;
}

EXPORTED kern_return_t 
  MDRequestAlarm(port_t device_port,port_name_t owner_port,port_t replyPort, int time) {
    if (owner_port == var.owner) {
	int s = splmidi();
#if USE_IO_THREAD
        var.userAlarmPort = IOConvertPort(replyPort, IO_CurrentTask, IO_KernelIOTask);
#else
        var.userAlarmPort = replyPort;
#endif
	var.userAlarmTime = time;
	requestWakeup(time);
	splx(s);
	return KERN_SUCCESS;
    }
    return MD_ERROR_NOT_OWNER;
}

EXPORTED kern_return_t 
  MDRequestExceptions(port_t device_port, port_name_t owner_port, 
				port_t exceptPort) {
    if (owner_port == var.owner) {
#if USE_IO_THREAD
        var.exceptPort = IOConvertPort(exceptPort, IO_CurrentTask, IO_KernelIOTask);
#else
        var.exceptPort = exceptPort;
#endif
	return KERN_SUCCESS;
    }
    return MD_ERROR_NOT_OWNER;
}

EXPORTED kern_return_t 
  MDRequestQueueNotification(port_t device_port,
			       port_name_t owner_port, short unit,
			       port_t notification_port,
			       int size) 
{
    /* Generate exception when there is room for at least size messages */
    int s;
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    midi_xlog("MDRequestQueueNotification %d\n",size,2,3,4,5); 
    s = splmidi();
    var.u[unit].availableNotify = size;
#if USE_IO_THREAD
    var.u[unit].queuePort = IOConvertPort(notification_port, IO_CurrentTask, IO_KernelIOTask);
#else
    var.u[unit].queuePort = notification_port;
#endif
    checkQueueNotify(unit);
    splx(s);
    return KERN_SUCCESS;
}

/****************** Receiving asynchronous messages *******************/
/* ---------------- See MusicKit/mididriver_nonMig.c ---------------- */

/****************** Writing MD data to the driver *********************/
EXPORTED kern_return_t 
  MDSendData(port_t device_port, port_t owner_port, short unit,
	       MDRawEvent *data, unsigned int count) {
    int ind;
    if (owner_port != var.owner)
      return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    midi_slog("[MDSendData \n");
    if (queueAvailSize(unit) < count) {
	midi_log("***MDSendData queue full***\n",1,2,3,4,5);
	return MD_ERROR_QUEUE_FULL;
    }
    while (count--) {
	ind = bumpIndex(var.u[unit].xmtInInd,XMT_FIFO_SIZE);
	/* Since we can be interrupted here, we have to stuff the 
	 * data first and then update inInd. 
	 */
	midi_olog("Q %x t %d\n",(unsigned int)data->byte,data->time,3,4,5);
	var.u[unit].xmtFifo[var.u[unit].xmtInInd] = *data++;
	var.u[unit].xmtInInd = ind;
	if (!var.u[unit].xmtInProgress) {
	    int s = splmidi();   /* Protect deviceStartXmt(). */
	    deviceStartXmt(getCurrentTime(),unit);
	    splx(s);
	}
    }
    midi_slog("...MDSendData]\n");
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDGetAvailableQueueSize(port_t device_port,port_name_t owner_port,
			    short unit,int *size) {
    midi_slog("[MDGetAvailableQueueSize...\n");
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    *size = queueAvailSize(unit);
    midi_slog("...MDGetAvailableQueueSize]\n");
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDClearQueue(port_t device_port, port_name_t owner_port, short unit) 
{
    midi_slog("MDClearQueue\n");
    if (owner_port != var.owner) return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    clearOutputQueue(unit);
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDFlushQueue(port_t device_port, port_name_t owner_port, short unit) 
{
    midi_slog("MDFlushQueue\n");
    if (owner_port != var.owner)
	return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    if (var.u[unit].xmtOutInd == var.u[unit].xmtInInd) 
	return KERN_SUCCESS;
    /* We implement flushing by taking a snapshot of the in index.  We
     * then know we're flushing when outInd != flushInd.  To indicate no
     * flush in progress, we use a special number NO_FLUSH.  Note that
     * we need to check, after writing each byte, to see if outInd == flushInd.
     * If so, the flush is finished and we set flushInd to NO_FLUSH. 
     */
    var.u[unit].xmtFlushInd = var.u[unit].xmtInInd;
    if (!var.u[unit].xmtInProgress) {
	int s = splmidi();   /* Protect deviceStartXmt(). */
	deviceStartXmt(getCurrentTime(),unit);
	splx(s);
    }
    return KERN_SUCCESS;
}

/********************* Filtering MD system real time messages. *************/

#if PARSED
EXPORTED kern_return_t 
  MDFilterMessage(port_t device_port,port_t owner_port,short unit,
		    char statusByte,boolean_t filterIt) {
    midi_slog("MDFilterMessage\n");
    if (var.owner != owner_port)     
	return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    var.u[unit].ignore[statusByte] = filterIt;
    return KERN_SUCCESS;
}

EXPORTED kern_return_t 
  MDParseInput(port_t device_port,port_t owner_port,short unit,
		 boolean_t parseIt) {
    midi_slog("MDParseInput\n");
    if (var.owner != owner_port)     
	return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    if (var.u[unit].parseInput == parseIt)
	return KERN_SUCCESS;
    var.u[unit].parseInput = parseIt;
    var.u[unit].parse.runningStat = 0;
    var.u[unit].parse.status = 0;
    var.u[unit].parse.data1 = 0;
    var.u[unit].parse.dataBytes = 0;
    var.u[unit].parse.dataByteSeen = FALSE;
    return KERN_SUCCESS;
  }

#else

EXPORTED kern_return_t 
  MDSetSystemIgnores(port_t device_port,port_t owner_port,short unit,
		       int bits) {
    midi_slog("MDSetSystemIgnores\n");
    if (var.owner != owner_port)     
	return MD_ERROR_NOT_OWNER;
    if (INVALID(unit) || !CLAIMED(unit))
	return MD_ERROR_UNIT_UNAVAILABLE;
    #define SET(x,y) var.u[unit].ignore[x] = (bits & y) ? TRUE : FALSE;
    #define IGNORE_CLOCK	 0x0100
    #define IGNORE_START	 0x0400
    #define IGNORE_CONTINUE	 0x0800
    #define IGNORE_STOP	 0x1000
    #define IGNORE_ACTIVE	 0x4000
    #define IGNORE_RESET	 0x8000

    SET(MIDI_CLOCK,IGNORE_CLOCK);
    SET(MIDI_START,IGNORE_START);
    SET(MIDI_CONTINUE,IGNORE_CONTINUE);
    SET(MIDI_STOP,IGNORE_STOP);
    SET(MIDI_ACTIVE,IGNORE_ACTIVE);
    SET(MIDI_RESET,IGNORE_RESET);
    return KERN_SUCCESS;
}

#endif


- (IOReturn)getCharValues   : (unsigned char *)parameterArray
               forParameter : (IOParameterName)parameterName
                      count : (unsigned int *)count
{
  /* 
   * This method is documented in the IODevice spec sheet.
   */
	
  /* Handle any parameters we want to support */
    return [super getCharValues:parameterArray 
	  forParameter:parameterName count:count];
}

@end
