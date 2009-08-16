/* DSPMKDriver.m by David A. Jaffe */

#import <driverkit/i386/directDevice.h>
#import <driverkit/i386/IOEISADeviceDescription.h>
#import <driverkit/generalFuncs.h>
#import <driverkit/interruptMsg.h>
#import <kernserv/kern_server_types.h>
#import <kernserv/prototypes.h>
#import <mach/mig_errors.h>
#import <driverkit/i386/ioPorts.h>

#import "DSPMKDriver.h"

#define MAX_UNITS 16 
#define AVAIL_PAGE_BUFFERS_PER_SUBUNIT 5

typedef struct _DSPMKDriverSubclassVars {
    int maxUnitNumber;
    DSPMKDriver *driverObjects[MAX_UNITS];
} DSPMKDriverSubclassVars;  

static DSPMKDriverSubclassVars classVars = {0};
/* DSPMKDriverSubclassVars are variables that we'll change to 
 * "class variables" if it's ever possible to have shared abstract 
 * super-classes in Driver Kit code.  Similarly, in that case, there will
 * be a separate classVars for each subclass.
 */

@implementation DSPMKDriver

/* Macros for accessing host port via Intel IO ports */
#define BASEIO(_unit) (classVars.driverObjects[_unit]->baseIO)

#define DSPDRIVER_ICR(_unit) (BASEIO(_unit)+0)
#define DSPDRIVER_CVR(_unit) (BASEIO(_unit)+1)
#define DSPDRIVER_ISR(_unit) (BASEIO(_unit)+2) // RO
#define DSPDRIVER_IVR(_unit) (BASEIO(_unit)+3)
// #define UNUSED(_unit) (BASEIO(_unit)+4)
#define DSPDRIVER_DATA_HIGH(_unit) (BASEIO(_unit)+5)
#define DSPDRIVER_DATA_MED(_unit) (BASEIO(_unit)+6)
#define DSPDRIVER_DATA_LOW(_unit) (BASEIO(_unit)+7)

+ (BOOL)probe:deviceDescription
  /*
   * Probe, configure board and init new instance.  This method is 
   * documented in the IODevice spec sheet.
   */
{
    id driver;
    IOEISADeviceDescription
      *devDesc = (IOEISADeviceDescription *)deviceDescription;
    if (classVars.maxUnitNumber == MAX_UNITS) {
	IOLog("Mididriver: Too many DSP devices installed.  Maximum allowed = %d\n",
	      MAX_UNITS);
	return NO;
    }
    if ([devDesc numPortRanges] < 1) {
	printf("Wrong number of port ranges.\n");
	return NO;
    }
 
    if ([devDesc numInterrupts] > 1) {
	IOLog("DSPMKDriver:  Wrong number of interrupts.\n");
	return NO;
    }

    driver = [self alloc];
    if (driver == nil) {
      IOLog("Can't allocate DSPMKDriver object.\n");
      return NO;
    }
    /* Perform more device-specific validation, e.g. checking to make 
     * sure the I/O port range is large enough.  Make sure the 
     * hardware is really there. Return NO if anything is wrong. */
    
    if ([driver initFromDeviceDescription:devDesc] == nil) {
	[driver free];
	return NO;
    }
    return YES;
}

- initFromDeviceDescription:deviceDescription
{
  /*
   * Init the new instance.  This method is documented in the i386-specific
   * part of the IODirectDevice spec sheet.
   */
    char name[80];
    const IORange *range; 
    int i;
    unsigned size,twoDsize;
    /* 
     * If the resources specified in this driver's bundle 
     * (in /usr/Devices/<obj>.config/*.table) are already reserved,
     * [super initFromDeviceDescription:] will return nil.
     */
    if ([super initFromDeviceDescription:deviceDescription] == nil)
    	return nil;
    range = [deviceDescription portRangeList];
    baseIO = range->start;
    useInterrupts = ([deviceDescription numInterrupts] == 1);
    maxDSPCount = [[self class] maxDSPCount];
    if (useInterrupts) {
      irq = [deviceDescription interrupt];
      if (maxDSPCount != 1) {
	IOLog("DSP driver doesn't support interrupt-driven transfer for devices with multiple sub-units.");
	return nil;
      }
    } else irq = 0;
    subUnitMap = IOMalloc(sizeof(int)*maxDSPCount);
    if (!subUnitMap) {
      IOLog("DSP driver can't allocate enough memory.\n");
      IOFree(subUnitMap,sizeof(int)*maxDSPCount);
      return nil;
    }     

    sprintf(name,"%s%d",[[self class] name],classVars.maxUnitNumber);
    [self setName:name];
    [self setUnit:classVars.maxUnitNumber];
    /* Make it possible for MIG interface to find us */
    classVars.driverObjects[classVars.maxUnitNumber] = self;

    [self setupFromDeviceDescription:deviceDescription];
    [self setDeviceKind:"DSP"]; /* Added Sept. 5, 94 */
    [self setLocation:NULL];
    messagingOn = 0;
    pollThreadRunning = FALSE;
    pollingThread = NULL;
    [self registerDevice];

#if SENSE_DSPS_AT_BOOT
#warning DSP Sensing on
    {
	unsigned char senseByte;
	if (![self resetHardware]) {
	    IOLog("%s failed to reset hardware at IO base address == 0x%x\n",
		  name,baseIO); 
	    IOFree(subUnitMap,sizeof(int)*maxDSPCount);
	    [self unregisterDevice];
	    return nil;
	}
	for (actualDSPCount = 0, i=0; i<maxDSPCount; i++) {
	    [self setPhysicalSubUnit:i];
	    [self resetDSP:1];
	    IOSleep(10);
	    [self resetDSP:0];
	    IOSleep(10);
            outb(DSPDRIVER_ICR(classVars.maxUnitNumber),8);
	    IOSleep(1); /* Shouldn't be needed, but what the hell */
            senseByte = inb(DSPDRIVER_ICR(classVars.maxUnitNumber));
            if ((senseByte & 0x18) == (unsigned char)8)  
              subUnitMap[actualDSPCount++] = i;
	}
	if (actualDSPCount == 0) {
	    IOLog("%s failed to sense any DSPs at IO base address == 0x%x\n",
		  name,baseIO); 
	    IOFree(subUnitMap,sizeof(int)*maxDSPCount);
	    [self unregisterDevice];
	    return nil;
	} 
	if (useInterrupts) 
	  IOLog("%s IO base address == 0x%x, IRQ == %d, %d DSPs found\n",name,
		baseIO,irq,actualDSPCount); 
	else 
	  IOLog("%s IO base address == 0x%x, %d DSPs found\n",name,baseIO,
		actualDSPCount); 
      }
#else
#warning DSP Sensing off
    actualDSPCount = maxDSPCount;
    {
	for (i=0;i<actualDSPCount;i++) {
	  subUnitMap[i] = i;
	}
    }
    subUnit = 0;
#endif
    /* Allocate all the arrays */
    twoDsize = actualDSPCount * (DSPDRIVER_MAX_TRANSFER_CHAN+1); /* +1 for 0 */
    /* 2 dimensional arrays [physicalDSP][DMAchan] */

    /* dspReadRegionTag */
    size = twoDsize * sizeof(int);   
    dspReadRegionTag = (int **)IOMalloc(size);
    bzero(dspReadRegionTag,size);

    /* dspReadWordCount */
    size = twoDsize * sizeof(short);   
    dspReadWordCount = (short **)IOMalloc(size);
    bzero(dspReadWordCount,size);

    /* dspReadType */
    dspReadType = (char **)IOMalloc(twoDsize);
    bzero(dspReadType,twoDsize);

    /* 1 dimensional arrays [physicalDSP] */

    /* mach ports */
    size = actualDSPCount * sizeof(port_t);	
    dspReadReplyPort = (port_t *)IOMalloc(size);
    dspBufferedReadReplyPort = (port_t *)IOMalloc(size);
    msgPort = (port_t *)IOMalloc(size);
    errPort = (port_t *)IOMalloc(size);
    bzero(dspReadReplyPort,size);
    bzero(dspBufferedReadReplyPort,size);
    bzero(msgPort,size);
    bzero(errPort,size);

    /* Optimization for poll interval and polling */
    messagingDSPs = (int *)IOMalloc(actualDSPCount * sizeof(int));
    messagingDSPsCount = 0;
    pendingReadRequests = 0; 
    pendingBufferedReadRequests = 0; 

    /* bufferedChanCount */
    size = actualDSPCount*sizeof(short);	
    curBufferedChanCount = (short *)IOMalloc(size);
    bzero(curBufferedChanCount,size);

    /* bufferedChanState */
    bufferedChanState = (char *)IOMalloc(actualDSPCount);
    bzero(bufferedChanState,actualDSPCount);

    /* bufferedChan buffers */
    size = actualDSPCount*sizeof(void *);	
    pendingBufferedChanData = (void **)IOMalloc(size);
    bzero(pendingBufferedChanData,size);

    size = actualDSPCount*sizeof(short);	
    pendingBufferedChanPageIndex = (short *)IOMalloc(size);
    bzero(pendingBufferedChanPageIndex,size);

    availPageCount = actualDSPCount * AVAIL_PAGE_BUFFERS_PER_SUBUNIT;
    size = availPageCount * sizeof(DSPDRIVERAvailPage);
    availPages = (DSPDRIVERAvailPage *)IOMalloc(size);
    bzero(availPages,size);

    if (!dspReadRegionTag || !dspReadWordCount || !dspReadType ||
	!dspReadReplyPort || !dspBufferedReadReplyPort || !curBufferedChanCount ||
	!pendingBufferedChanData || !bufferedChanState || !msgPort || !errPort ||
	!pendingBufferedChanPageIndex || !availPages) {
      IOLog("DSP driver can't allocate enough memory.\n");
      return nil;
    }     

    classVars.maxUnitNumber++;

    /*  Initialize messaging variables  */
    [self initOutputQueue];
    [self initAvailPagePool];
    [self startIOThread]; 
    if (useInterrupts)
      [self enableAllInterrupts];
    return self; 
}

-(int)resetSleepTime {
    return 10;
}

-resetAllDSPs {
    int i,resetTime = [self resetSleepTime];
    for (i=0; i<actualDSPCount; i++) {
	[self setVirtualSubUnit:i];
	[self setMessagingOn:0];
    }
    for (i=0; i<actualDSPCount; i++) {
	[self setVirtualSubUnit:i];
	[self resetDSP:1];
	IOSleep(resetTime); /* ms */
	[self resetDSP:0];
    }
    return self;
}

-setVirtualSubUnit:(int)aUnit
{
    if (aUnit >= actualDSPCount)
      return nil;
    return [self setPhysicalSubUnit:subUnitMap[aUnit]];
}

-_returnCharValue:(const char *)theValue 
  inArray:(unsigned char *)parameterArray
  count : (unsigned int *)count
{
    const char  *param;
    unsigned int length;
    unsigned int maxCount = *count;
    param = theValue;
    length = strlen(param);
    if(length >= maxCount) {
      length = maxCount - 1;
    }
    *count = length + 1;
    strncpy(parameterArray, param, length);
    parameterArray[length] = '\0';
    return self;
}

- (IOReturn)getCharValues   : (unsigned char *)parameterArray
               forParameter : (IOParameterName)parameterName
                      count : (unsigned int *)count
{
  /* 
   * This method is documented in the IODevice spec sheet.
   */
    if(strcmp(parameterName, DSPDRIVER_PAR_MONITOR) == 0){
      [self _returnCharValue:[[self class] monitorFileName]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_MONITOR_4_2) == 0){
      const char *val;
#ifdef IMPLEMENTS_MONITOR_4_2
#warning Implements monitorFileName_4_2
      val = [[self class] monitorFileName_4_2];
#else
      val = [[self class] monitorFileName];
#endif
      [self _returnCharValue:val
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_SERIALPORTDEVICE) == 0){
      [self _returnCharValue:[[self class] serialPortDeviceName]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_ORCHESTRA) == 0){
      [self _returnCharValue:[[self class] orchestraName]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_WAITSTATES) == 0){
      [self _returnCharValue:[[self class] waitStates]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_CLOCKRATE) == 0){
      [self _returnCharValue:[[self class] clockRate]
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else if(strcmp(parameterName, DSPDRIVER_PAR_SUBUNITS) == 0){
      char numStr[4];
      sprintf(numStr,"%d",actualDSPCount);
      [self _returnCharValue:numStr
       inArray:parameterArray 
       count:count];
      return IO_R_SUCCESS;
    }
    else { 
	/* Pass parameters we don't recognize to our superclass. */
        return [super getCharValues:parameterArray 
            forParameter:parameterName count:count];
    }
}


#import "dspdriver_server.c"

#import "dspdriverServer.c"

@end
