/*
 * This example test program records MIDI data as a standard Level 0 Midifile
 * as defined by the Midi Manufacturer's Association.
 *
 * Original written by Gregg Kellogg and Danna Massie.
 * Rewritten for release 3.0 MIDI driver by David Jaffe.
 * Ported to Intel architectures,
 * then ported to Rhapsody/MacOs X Server (Nov 98),
 * then converted to use MusicKit midifile routines (Apr 99) 
 * by Leigh Smith (leigh@cs.uwa.edu.au, leigh@tomandandy.com)
 */

#import <mach/mach.h>
#import <stdio.h>
#import <stdlib.h>
#import <mach/mach_error.h>
#import <signal.h>
#import <servers/netname.h>
#import <libc.h>
//#import <MusicKit/MusicKit.h> // not yet..one day this should be the only header we include 
#import <MKPerformMIDI/midi_driver.h>
#import <MusicKit/midi_spec.h>
#import <MusicKit/midifile.h>

static port_t driverPort;    /* Port for driver on particular host. */
static port_t ownerPort;     /* Port that represents ownership */
static port_t dataPort;      /* Port for incoming data. */
static port_t exceptionPort; /* Port for timing exceptions */
static port_t alarmPort;     /* To get periodic messages. */
static NSMutableData *outputMIDIdata;          /* Stream for writing output file */
static int unit = MIDI_PORT_A_UNIT;/* Serial port to read from */
static int byteCount = 0;

static boolean_t verbose;    /* Flag. */

/* Forward references */
static void usage(void);
static void checkForError(char *msg,int errorReturn);
static port_t allocPort(void);
static void initFile(NSMutableData *stream);
static void myExceptionReply(port_t replyPort, int exception);
static void myAlarmReply(port_t replyPort, int requestedTime, int actualTime); 
static void myDataReply(port_t replyPort, short unit, MIDIRawEvent *events, unsigned int count);
static void cleanup();
static port_t createPortSet(port_t dataPort, port_t exceptionPort,
			    port_t alarmPort);
static char *filename = NULL;	

int main(int argc, char **argv)
{
    int i;
    kern_return_t r;
    int synchToTimeCode = FALSE;
    port_set_name_t ports;   /* Port set to listen for messages from driver */
    int synchUnit = MIDI_PORT_A_UNIT;           /* Serial port to listen for time code */
    MIDIReplyFunctions funcs = {0};
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    signal (SIGINT, cleanup); /* Control-C routine to clean up gracefully */
    while ((i = getopt(argc, argv, "p:f:s:v")) != EOF) {
	switch (i) {
	case 'p':
	    unit = (!strcmp (optarg ,"a")) ? MIDI_PORT_A_UNIT : MIDI_PORT_B_UNIT;
	    break;
	case 'f':
	    filename = optarg ;
	    break;
	case 's':
	    synchToTimeCode = TRUE;
	    synchUnit = (!strcmp (optarg ,"a")) ? MIDI_PORT_A_UNIT : MIDI_PORT_B_UNIT;
	    break;
	case 'v':
	    verbose = 1;
	    break;
	case 'h':
	case '?':
	default:
	    usage();
	    exit(1);
	}
    }
    
    if (filename == NULL) {
	fprintf(stderr,"No filename specified...\n");
	usage();
	exit(1);
    }
    fprintf(stderr,"using midi port: ");
    fprintf(stderr,unit == MIDI_PORT_A_UNIT ? "A\n" : "B\n");
    if (synchToTimeCode) {
	fprintf(stderr,"Synching to MIDI time code on port: ");
	fprintf(stderr,unit == MIDI_PORT_A_UNIT ? "A\n" : "B\n");
    }

    outputMIDIdata = [NSMutableData dataWithCapacity: 1024];  // most MIDI files are at least 1Kb

//    if ((fd = open(filename, O_WRONLY | O_CREAT, 0644)) < 0) {
//        fprintf(stderr,"open failed on filename %s\n", filename);
//	exit(1);
//    }
    initFile(outputMIDIdata);
	
    /* Set up MIDI driver */
    r = netname_look_up(name_server_port, "","mididriver", &driverPort);
    checkForError("playmidifile: netname_look_up error",r);
    r = MIDIBecomeOwner(driverPort,ownerPort = allocPort());
    checkForError("MIDIBecomeOwner",r);
    r = MIDIClaimUnit(driverPort, ownerPort,unit);
    checkForError("MIDIClaimUnit",r);
    if (synchToTimeCode && synchUnit != unit) {
	r = MIDIClaimUnit(driverPort, ownerPort,synchUnit);
	checkForError("MIDIClaimUnit",r);
    }
    r = MIDISetClockMode(driverPort, ownerPort, synchUnit,
			 (synchToTimeCode ? MIDI_CLOCK_MODE_MTC_SYNC : 
			  MIDI_CLOCK_MODE_INTERNAL));
    checkForError("MIDISetClockMode",r);
    r = MIDISetClockQuantum(driverPort, ownerPort, 1000);
    checkForError("MIDISetClockQuantum",r);
    ports = createPortSet(dataPort=allocPort(), exceptionPort=allocPort(),
			  alarmPort=allocPort());
    r = MIDIRequestExceptions(driverPort, ownerPort, exceptionPort);
    checkForError("MIDIRequestExceptions",r);
    /*
     * Tell it to ignore system real time messages we're not interested in.
     */
    r = MIDISetSystemIgnores(driverPort,ownerPort,unit,MIDI_IGNORE_REAL_TIME);
    checkForError("MIDISetSysIgnores",r);
    /* Ask for data */
    r = MIDIRequestData(driverPort,ownerPort,unit,dataPort);
    checkForError("MIDIRequestData",r);
    /* Request a message at time 1000ms (1 second). */
    r = MIDIRequestAlarm(driverPort,ownerPort,alarmPort,1000);
    checkForError("MIDIRequestAlarm",r);
    if (!synchToTimeCode) {
	r = MIDISetClockTime(driverPort, ownerPort, 0);
	checkForError("MIDISetClockTime",r);
	/* We start clock now.  Alternatively, we could first queue up
	 * some messages and then start time.  That would insure that
	 * the first few notes come out correctly.  
	 */
	r = MIDIStartClock(driverPort, ownerPort);
	checkForError("MIDIStartTime",r);
    }
    /* Note: If this code is included in an Application, you must either
     * run MIDIAwaitReply() in a separate Mach thread or use MIDIHandleReply()
     * instead of MIDIAwaitReply() and register the port set with DPSAddPort().
     * See <mididriver/midi_driver.h> for details. 
     */	
    funcs.exceptionReply = myExceptionReply;
    funcs.dataReply = myDataReply;
    funcs.alarmReply = myAlarmReply;
    if (synchToTimeCode) 
	fprintf(stderr,"Waiting for time code to start...\n");
    for (;;) {
	r = MIDIAwaitReply(ports,&funcs,MIDI_NO_TIMEOUT);
	checkForError("MIDIAwaitReply",r);
    }

    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}

void usage(void)
{
    fprintf(stderr,
	    "usage: recordmidifile -f file.midi [-p {A, B}] [-s {A, B}] [-v]\n"
	    "       -p is the serial port to receive the MIDI from\n"
	    "       -v means verbose\n"
	    "       -s is the serial port to receive MIDI time code, if any.\n");
}

static void *fileStruct;

enum {full,fullSysex,incomplete};

static int midiParser(unsigned char aByte)
    /* Returns TRUE when a valid MIDI message is parsed.  We don't need
     * to worry about System Real Time messages because they're filtered
     * out by the driver. */
{
    #define NO_RUNNING_STATUS 0
    static unsigned char runningStatus = NO_RUNNING_STATUS;
    static int op = 0;
    static int nBytes = 0;
    static int msgSize = 0;
    int ret;
    if (aByte & MIDI_STATUSBIT) {
	if (aByte == MIDI_EOX && op == MIDI_SYSEXCL)
	    return fullSysex;
	op = aByte;
	if (MIDI_TYPE_SYSTEM(aByte))
	    runningStatus = NO_RUNNING_STATUS;
	else runningStatus = op;
	msgSize = MIDI_EVENTSIZE(runningStatus);
	nBytes = 0;
    }
    ret = ((op == MIDI_SYSEXCL) ? incomplete : 
	    (++nBytes == msgSize) ? full : incomplete);
    if (ret == full)
        nBytes = 1;
    return ret;
}

static char *setBufferSize(char *bytes,int size)
{
    static int bufsize = 0;

    if (!bytes) {
        bufsize = size;
        bytes = (char *) malloc(sizeof(char) * bufsize);
    }
    else if (size < bufsize) {
	bufsize = size * 2;
        bytes = (char *) realloc(bytes, sizeof(char) * bufsize);
    }
    return bytes;
}

static void myDataReply(port_t replyPort, short unit, MIDIRawEvent *events, unsigned int count)
    /* This gets invoked when data comes in. */
{
    static int byteIndex;
    int i;
    MIDIRawEvent *p;
    if (verbose) {
	for (i = 0, p = events; i < count; i++, p++)
	    fprintf(stderr,"0x%x@%d ", p->byte, p->time);
	fprintf(stderr,"\n");
    }
    byteCount += count;
    for (p = events; count--; p++) {
	static char *bytes = NULL;
	bytes = setBufferSize(bytes,byteIndex+1);
	bytes[byteIndex++] = p->byte;
	switch (midiParser(p->byte)) {
	  case full:
	    MKMIDIFileWriteEvent(fileStruct,p->time,byteIndex,bytes);
	    byteIndex = 0;
	    break;
	  case fullSysex:
	    MKMIDIFileWriteSysExcl(fileStruct,p->time,byteIndex,bytes);
	    byteIndex = 0;
	    break;
	  default:
	    break;
	}
    }
}

static void myAlarmReply(port_t replyPort, int requestedTime, int actualTime) 
    /* This gets invoked when an alarm occurs. */ 
{
    kern_return_t r;
    fprintf(stderr,"Time = %d ms\n",requestedTime);
    r = MIDIRequestAlarm(driverPort,ownerPort,alarmPort,requestedTime+1000);
    checkForError("MIDIRequestAlarm",r);
}

static void myExceptionReply(port_t replyPort, int exception)
    /* This gets invoked when exceptions occur. */
{
    switch (exception) {
      case MIDI_EXCEPTION_MTC_STOPPED:
	fprintf(stderr,"MIDI time code stopped.\n");
	break;
      case MIDI_EXCEPTION_MTC_STARTED_FORWARD:
	fprintf(stderr,"MIDI time code started (forward).\n");
	break;
      case MIDI_EXCEPTION_MTC_STARTED_REVERSE:
	fprintf(stderr,"MIDI time code started (reverse).\n");
	break;
      default:
	break;
    }
}

static void checkForError(char *msg,int errorReturn)
    /* Checks for error.  If error, prints message and quits. */
{
    if (errorReturn != KERN_SUCCESS) {
	switch (errorReturn) {
          case MIDI_ERROR_BUSY:
	    printf("%s: %s",msg,"MIDI driver busy.\n");
	    break;
          case MIDI_ERROR_NOT_OWNER:
	    printf("%s: %s",msg,"You must be owner of the MIDI driver.\n");
	    break;
          case MIDI_ERROR_QUEUE_FULL:
	    printf("%s: %s",msg,"MIDI driver queue full.\n");
	    break;
          case MIDI_ERROR_BAD_MODE:
	    printf("%s: %s",msg,"Bad MIDI driver clock mode.\n");
	    break;
          case MIDI_ERROR_UNIT_UNAVAILABLE:
	    printf("%s: %s",msg,"MIDI driver unit unavailable.\n");
	    break;
          case MIDI_ERROR_ILLEGAL_OPERATION:
	    printf("%s: %s",msg,"MIDI driver illegal operation.\n");
	    break;
	  default: 
	    mach_error(msg,errorReturn);
	}
	exit(1);
    }
}

static port_t allocPort(void)
    /* Allocates a port and returns it. */
{
    port_t aPort;
    int r = port_allocate(task_self(), &aPort);
    checkForError("allocPort",r);
    return aPort;
}

static port_t createPortSet(port_t dataPort, port_t exceptionPort, port_t alarmPort) 
    /* Creates the port set and adds the three ports.  */
{
    port_set_name_t aPortSet;
    int r = port_set_allocate(task_self(), &aPortSet);
    checkForError("createPortSet",r);
    r = port_set_add(task_self(), aPortSet, dataPort);
    checkForError("createPortSet",r);
    r = port_set_add(task_self(), aPortSet, alarmPort);
    checkForError("createPortSet",r);
    r = port_set_add(task_self(), aPortSet, exceptionPort);
    checkForError("createPortSet",r);
    return aPortSet;
}

static void initFile(NSMutableData *outputMIDIdata)
    /* Set up file. */
{
    fileStruct = MKMIDIFileBeginWriting(outputMIDIdata,0,@"track",YES);
    MKMIDIFileWriteTempo(fileStruct,0,60);
    MKMIDIFileBeginWritingTrack(fileStruct,NULL);
}

void cleanup()
    /* we kill this test program by control-C; must save midifile */
{
    fprintf(stderr,"Received %d MIDI bytes\n",byteCount);    
    MIDIReleaseOwnership(driverPort,ownerPort);
    MKMIDIFileEndWritingTrack(fileStruct,0);
    MKMIDIFileEndWriting(fileStruct);
    [outputMIDIdata writeToFile: [NSString stringWithCString: filename] atomically: YES];
    exit(0);
}

