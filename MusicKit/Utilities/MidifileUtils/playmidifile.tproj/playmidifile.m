/*
 * This example test program reads a standard Level 0 Midifile (.midi suffix)
 * as defined by the Midi Manufacturer's Association, and plays it 
 * through the MIDI Driver. Level 1 and level 2 files are not supported
 * in this example.
 *
 * Original written by Gregg Kellogg and Danna Massie.
 * Rewritten for release 3.0 MIDI driver by David Jaffe
 * Ported to Intel architectures (NS/OS),
 * then ported to Rhapsody/MacOs X Server (Nov 98),
 * then integrated into the MusicKit by adopting its SMF routines (Apr 99) 
 * by Leigh Smith (leigh@cs.uwa.edu.au, leigh@tomandandy.com).
 */
#import <mach/mach.h>
#import <stdio.h>
#import <stdlib.h>
#import <mach/mach_error.h>
#import <signal.h>
#import <servers/netname.h>
#import <libc.h>
#import <MusicKit/MusicKit.h> // one day this should be the only header we include..not yet.. 
#import <MKPerformSndMIDI/midi_driver.h>
#import <MusicKit/midifile.h>

static mach_port_t driverPort;    /* Port for driver on particular host. */
static mach_port_t ownerPort;     /* Port that represents ownership */
static mach_port_t queuePort;     /* Port for output queue notification messages */
static mach_port_t exceptionPort; /* Port for timing exceptions */
static int maxQueueSize;     /* Maximum output queue size */
static boolean_t allRead;    /* Flag signaling all data read from file. */
static boolean_t allSent;    /* Flag signaling all data sent to driver. */ 
static boolean_t someSent;   /* Flag signaling if  data was sent to driver.*/
static NSMutableData *inputMIDIdata;          /* Stream for reading input file */
static int tempo = 60;
static int unit = MIDI_PORT_A_UNIT; /* Serial port to send to */
static port_set_name_t ports;/* Port set to listen for messages from driver */

/* Forward references */
static void usage(void);
static void checkForError(char *msg,int errorReturn);
static mach_port_t allocPort(void);
static mach_port_t createPortSet(mach_port_t queuePort, mach_port_t exceptionPort); 
static void initFile(void);
static void setTempo(int newTempo);
static void myExceptionReply(mach_port_t replyPort, int exception);
static void myQueueReply(mach_port_t replyPort, short unit);
static void cleanup();

int main(int argc, char **argv)
{
    int i;
    int synchToTimeCode = FALSE;
    kern_return_t r;
    int synchUnit = MIDI_PORT_A_UNIT;           /* Serial port to listen for time code */
    char *filename = NULL;
    MIDIReplyFunctions funcs = {0};
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    signal (SIGINT, cleanup); /* Control-C routine to clean up gracefully */
    while ((i = getopt(argc, argv, "p:f:t:s:")) != EOF)
	switch (i) {
	case 'p':
	    unit = ((!strcmp (optarg ,"a") || !strcmp(optarg,"A")) ? 
		    MIDI_PORT_A_UNIT : MIDI_PORT_B_UNIT);
	    break;
	case 'f':
	    filename = optarg ;
	    break;
	case 't':
	    tempo = atoi(optarg) ;
	    fprintf(stderr,"tempo= %d\n",tempo);
	    break;
	case 's':
	    synchToTimeCode = TRUE;
	    synchUnit = (!strcmp (optarg ,"a")) ? MIDI_PORT_A_UNIT : MIDI_PORT_B_UNIT;
	    break;
	case 'h':
	case '?':
	default:
	    usage();
	    exit(1);
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
    inputMIDIdata = [NSMutableData dataWithContentsOfFile: [NSString stringWithCString: filename]];
    if (inputMIDIdata == nil) {
	fprintf(stderr,"Cannot open file : %s\n", filename);
	exit(1);
    }
    initFile();

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
			 (synchToTimeCode ? MIDI_CLOCK_MODE_MTC_SYNC : MIDI_CLOCK_MODE_INTERNAL));
    checkForError("MIDISetClockMode",r);
    r = MIDISetClockQuantum(driverPort, ownerPort, 1000);
    checkForError("MIDISetClockQuantum",r);
    ports = createPortSet(queuePort=allocPort(), exceptionPort=allocPort());
    r = MIDIRequestExceptions(driverPort, ownerPort, exceptionPort);
    checkForError("MIDIRequestExceptions",r);
    r = MIDIGetAvailableQueueSize(driverPort, ownerPort, unit, &maxQueueSize);
    checkForError("MIDIGetAvailableQueueSize",r);
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
    /*
     * We play the file by chaining invocations of myQueueReply().  To
     * start the process, we ask the driver to invoke myQueueReply() when
     * the queue is fully available (which will be immediately, since nothing
     * has been sent yet.)
     *
     * Note: If this code is included in an Application, you must either
     * run MIDIAwaitReply() in a separate Mach thread or use MIDIHandleReply()
     * instead of MIDIAwaitReply() and register the port set with DPSAddPort().
     * See <mididriver/midi_driver.h> for details. 
     */	
    r = MIDIRequestQueueNotification(driverPort, ownerPort, unit, queuePort, maxQueueSize);
    checkForError("MIDIRequestQueueNotification",r);
    funcs.exceptionReply = myExceptionReply;
    funcs.queueReply = myQueueReply;
    if (synchToTimeCode) 
	fprintf(stderr,"Waiting for time code to start...\n");
    allSent = FALSE;
    allRead = FALSE;
    someSent = TRUE;
    while (!allSent) {                /* Here's where the work happens */
	r = MIDIAwaitReply(ports,&funcs,MIDI_NO_TIMEOUT);
	checkForError("MIDIAwaitReply",r);
    }

    /* Wait for our output to drain. */
    r = MIDIRequestQueueNotification(driverPort, ownerPort, unit, queuePort, maxQueueSize);
    checkForError("MIDIRequestQueueNotification",r);
    funcs.queueReply = NULL;
    r = MIDIAwaitReply(ports,&funcs,MIDI_NO_TIMEOUT);
    checkForError("MIDIAwaitReply",r);
    cleanup();

    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}

static MIDIRawEvent events[MIDI_MAX_EVENT];
static byteIndex = 0;

/* Used by MKMIDIFile routines. */
static void *fileStruct;
static BOOL *metaEvent;
static int *quanta;
static int *nData;
unsigned char **data;

static int getNextFileByte(void)
{
    static int fileEventCtr = 0;
    if (fileEventCtr == 0)
	if (!MKMIDIFileReadEvent(fileStruct))
	    return FALSE;
    if (*metaEvent) 
	fileEventCtr = 0;
    else {
	events[byteIndex].time = *quanta;
	events[byteIndex].byte = (*data)[fileEventCtr++];
	byteIndex++;
	if (fileEventCtr == *nData)
	    fileEventCtr = 0;
    }
    return TRUE;
}

static int sendData(void) 
    /* Sends the data. Returns FALSE if the driver's buffer is full. */
{
    kern_return_t r = 
	MIDISendData(driverPort, ownerPort, unit, events, byteIndex);
    if (r == MIDI_ERROR_QUEUE_FULL) {
	/* Request notification when at least half the queue is available */
	r = MIDIRequestQueueNotification(driverPort, ownerPort, unit, queuePort, maxQueueSize/2);
	checkForError("MIDIRequestQueueNotification",r);
	return FALSE;
    }
    else
        checkForError("MIDISendData",r);
    byteIndex = 0;
    return TRUE;
}

static void myQueueReply(mach_port_t replyPort, short unit)
    /* This gets invoked when the queue has enough room for more data. */
{
    for (;;) {
	if (byteIndex == MIDI_MAX_EVENT-1)
	    if (!sendData())
		return; 
	if (!allRead) 
	    allRead = !getNextFileByte();
	if (allRead) {
	    if (sendData()) 
		allSent = TRUE;
	    return;
	}
    }
}

static void myExceptionReply(mach_port_t replyPort, int exception)
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

static void usage(void)
{
    fprintf(stderr,
	    "usage: playmidifile -f file.midi [-p {A, B}] [-s {A, B}]\n"
	    "       -p is the serial port to send the MIDI\n"
	    "       -s is the serial port to receive MIDI time code, if any.\n");
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

static mach_port_t allocPort(void)
    /* Allocates a port and returns it. */
{
    mach_port_t aPort;
    int r = port_allocate(task_self(), &aPort);
    checkForError("allocPort",r);
    return aPort;
}

static mach_port_t createPortSet(mach_port_t queuePort, mach_port_t exceptionPort) 
    /* Creates the port set and adds the two ports.  */
{
    port_set_name_t aPortSet;
    int r = port_set_allocate(task_self(), &aPortSet);
    checkForError("createPortSet",r);
    r = port_set_add(task_self(), aPortSet, queuePort);
    checkForError("createPortSet",r);
    r = port_set_add(task_self(), aPortSet, exceptionPort);
    checkForError("createPortSet",r);
    return aPortSet;
}

// TODO disabled until we know how to override the tempo from the MIDI file.
// Really this should be done after reading the times from the file, whereas it used to munge the times as they were read.
static void setTempo(int newTempo)
{
//    MKMIDIFileSetReadQuantaSize(fileStruct,(tempo = newTempo)/60.0 * 1000);
      fprintf(stderr, "Warning: disabled tempo override to %d\n", newTempo);
}

static void initFile(void)    
{
    int level,trackCount;

    fileStruct = MKMIDIFileBeginReading(inputMIDIdata,&quanta,&metaEvent,&nData,&data,YES);
    if (!fileStruct) {
      fprintf(stderr,"playmidifile unable to open the file\n");
      return;
    }
    if (MKMIDIFileReadPreamble(fileStruct,&level,&trackCount)) {
	if (level != 0) {
	    fprintf(stderr,"playmidifile cannot play level %d files.\n",level);
	    exit(1);
	}
    }
    else {
	fprintf(stderr,"failed to read preamble!\n");
	exit(1);
    }
    setTempo(tempo);
}

static void allNotesOff(void) {
    #define NOTEOFF_ARRAY_SIZE (128*2)          /* Use running status */
    MIDIRawEvent arr[NOTEOFF_ARRAY_SIZE]; 
    kern_return_t r;
    int chan = 0;
    int bytesToSend;
    int i;
    MIDIRawEvent op;
    MIDIReplyFunctions funcs = {0};
    for (i=0; i<128; i++) {  /* Initialize array */
	arr[i*2].byte = i;   /* KeyNum */
	arr[i*2+1].byte = 0; /* Velocity */
    }

#ifdef DRIVER_HANG_BUG
    fprintf(stderr, "Waiting...\n");
#endif
    while (MIDIAwaitReply(ports,&funcs,1) == KERN_SUCCESS)
	;    /* Empty out ports of any old notification messages. */
#ifdef DRIVER_HANG_BUG
    fprintf(stderr, "Clearing queue...\n");
#endif
    r = MIDIClearQueue(driverPort,ownerPort,unit);
    checkForError("MIDIClearQueue",r);
    for (chan = 0; chan < 16; chan++) {
	op.byte = MIDI_NOTEOFF | chan;
#ifdef DRIVER_HANG_BUG
        fprintf(stderr, "sending data to chan %d...\n", chan);
#endif
	r = MIDISendData(driverPort,ownerPort,unit,&op,1);
	checkForError("MIDISendData",r);
#ifdef DRIVER_HANG_BUG
        fprintf(stderr, "sending noteoff array...\n");
#endif
	for (i = 0; i < NOTEOFF_ARRAY_SIZE; i += MIDI_MAX_EVENT) {
	    bytesToSend = NOTEOFF_ARRAY_SIZE - i;
	    if (bytesToSend > MIDI_MAX_EVENT)
		bytesToSend = MIDI_MAX_EVENT;
	    r = MIDISendData(driverPort,ownerPort,unit,&arr[i],bytesToSend);
	    checkForError("MIDISendData",r);
	}
#ifdef DRIVER_HANG_BUG
        fprintf(stderr, "flushing queue...\n");
#endif
	r = MIDIFlushQueue(driverPort,ownerPort,unit);
	checkForError("MIDIFlushQueue",r);
#ifdef DRIVER_HANG_BUG
        fprintf(stderr, "requesting queue notification size %d...\n", ((chan==15) ? maxQueueSize : NOTEOFF_ARRAY_SIZE+1));
#endif
	r = MIDIRequestQueueNotification(driverPort, ownerPort, unit, queuePort,
		((chan==15) ? maxQueueSize : NOTEOFF_ARRAY_SIZE+1));
	checkForError("MIDIRequestQueueNotification",r);
#ifdef DRIVER_HANG_BUG
        fprintf(stderr, "awaiting reply...\n");
#endif
	r = MIDIAwaitReply(ports,&funcs,MIDI_NO_TIMEOUT);
	checkForError("MIDIAwaitReply",r);
    }
}

static void cleanup() {
    kern_return_t r;
    if (!driverPort || !ownerPort)
	exit(0);
    if (someSent)
	allNotesOff(); 
    r = MIDIReleaseOwnership(driverPort,ownerPort);
    checkForError("MIDIReleaseOwnership",r);
    exit(0);
}
