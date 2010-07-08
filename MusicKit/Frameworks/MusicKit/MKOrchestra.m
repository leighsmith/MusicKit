/*
 $Id$
 Defined In: The MusicKit
 
 Description:
   See class documentation in MKOrchestra.h
 
 CF: MKUnitGenerator.m, MKSynthPatch.m, MKSynthData.m and MKPatchTemplate.m.
 
 Original Author: David A. Jaffe
 Rewritten for use without DSP hardware: Leigh M. Smith
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2004 The MusicKit Project.
 */
/*
 Original pre MusicKit.org project modification history. For current history, 
 check the CVS log on musickit.org.
 
 11/10/89/daj - Moved StartSoundOut from -run to -open. The idea is to
 let soundout fill up the buffers so we don't get random
 behavior at the start of the score. This should be tested
 for write data and for write dac.
 11/21/89/daj - Minor changes to support lazy shared data garbage collection.   
 11/27/89/daj - Removed argument from _MKCurSample. Made _previousTime and
 _previousTimeStamp be instance variables of MKOrchestra.
 12/3/89/daj  - Moved deviceStatus = MK_devClosed to freeUgs() from 
 closeOrch() to prevent problems when Conductor's 
 finishPerformance sends -close recursively. For maximum
 safety, setting this instance variable is now the last 
 thing when opening and the first thing when closing.
 12/13/89/daj - Changed _MKCurSample() so that it does NOT return
 DSPMK_UNTIMED when there's no conductor. This was a bug.
 01/07/89/daj - Changed comments. Made _setSimualtorFilePtr: be private.
 Made compaction helper functions be in compaction cond
 compilation. Flushed MIXTEST and some false cond. comp.
 01/10/90/daj - Made changes to accomodate new dspwrap. Adjusted headroom.
 01/16/90/daj - Added conditional compilation to NOT start sound out early.
 This is an attempt to fix a strange deltaT bug.
 01/25/90/daj - Reimplemented simulator support. Made segmentZero: and
 segmentSink: accept MK_xData as well as MK_xPatchpoint.
 01/30/90/daj - Broke out the devstatus methods into a separate file for
 ease of maintaining. New file is orchControl.m. 
 01/31/90/daj - Changed instance variables to be backward-compatable with 1.0
 header files. This meant making a private "extraVars" struct.
 Changed loadOrchLoop failure case to just call freeUGs(). 
 This failure should never happen, anyway.
 Fixed trace message in allocUnitGenerator.
 Fixed bug in resoAlloc. It wasn't selecting MKUnitGenerator
 times correctly. Got rid of wasTimed in loadOrchLoop(). It
 was a noop because we're always untimed when loading the
 orch loop. Added new dspwrap support to compaction code.
 Flushed obsolete methods 
 -installSharedObject:for:segment:length and 
 -installSharedObject:for:segment:.
 02/13/90/daj - Fixed bugs in compaction: I was pre-incrementing piLoop so
 the space for a freed MKUnitGenerator wasn't really getting 
 freed. Reversed order of bltArgs and bltLoop so that 
 moved messages get sent after the MKUnitGenerator is fully
 moved. Changed increment of el to end of loop. Removed -1
 in bltLoop and bltArgs calls. Changed bltLoop and bltArgs
 to take address of ug list pointer and set it to NULL (this
							is a cosmetic change). Added code to break up BLTs that
 straddle onChip/offChip boundary. Fixed bug in leaper setting.
 (it was being set to leap to the wrong address.) Tested
 compaction and it seems to be working well for all cases.
 
 2/26/90/jos - deleted dummy versions of DSPMKThawOrchestra() and 
 DSPMKFreezeOrchestra()
 03/23/90/mtm - Added -setOutputDSPCommandsSoundfile: and
 -(char *)outputDSPCommandsSoundfile
 03/28/90/mtm - Changed above to "setOutputCommandsFile" and 
 "outputCommandsFile"
 03/28/90/daj - Added read data API support. 
 04/05/90/mmm - Added synchToConductor: from daj experimental MKOrchestra
 04/05/90/mmm - Added adjustTime hack in all allocation routines.
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 04/25/90/daj - Added check for devStatus == MK_devClosed in 
 flushTimedMessages
 Changed _DSPSendArraySkipTimed to DSPMKSendArraySkipTimed
 05/05/90/daj - Made external memory configurable and sensed. This involved 
 adding several new instance variables.
 06/10/90/daj - Added check in synchTime() for whether Conductor is behind.
 If Conductor is behind, doesn't synch.
 06/26/90/mtm - Grab conductor thread lock in synchTime().
 10/04/90/daj - Changed _MKCurSample() to return truly untimed if unclocked and
 stopped.
 12/18/90/daj - Fixed memory leak (orchloop UG was leaking on close/abort)
 01/08/91/daj - Added compaction call and clearing of previousLosingTemplate
 to setHeadroom:.  This is needed if headroom is set when
 the MKOrchestra is open.
 02/08/91/daj - Changed allocPatchPoint to be more forgiving if passed
 MK_xData instead of MK_xPatch or MK_yData instead of MK_yPatch
 07/10/91/daj - Changed to make synchToConductor: safer.
 11/23/92/daj - Added rounding to _MKCurSamp().
 12/21/92/daj - Added support for SSI sound in.
 1/31/93/daj -  Changed value of _XLI_USR and _YLI_USR
 1/31/93/daj -  Added .02 to HEADROOMFUDGE to accomodate new slightly slower ugs
 (because R_L is gone.)
 3/10/93/daj -  Got rid of orchBadFree error.  MKOrchestra now frees existing 
 unitgenerators for you.
 3/18/93/daj -  Added check for DSPCheckVersion() failing.  Added goto in
 loadOrchLoop.
 7/23/93/daj -  Added DSPMKStartReaders() to loadOrchLoop().
 9/1/93/daj -   Fixed bug in serial port sound out allocation of compute time
 9/25/93/daj -  Updated for new typed sharedSynthInfo
 9/25/93/daj -  Commented out lock/unlockPerformance in _adjustOrchTE
 1/9/94/daj -   Bug in getUGComputeTime() fixed.  The first UG off chip was
 getting assigned the on-chip compute time instead of the off-chip
 compute time.
 2/1/94/daj -   Added support for non-overlaid memory
 2/19/94/daj -  Added + 1 to xArg in overlay case.
 9/7/94/daj  -  Added support for Intel. Changed soundOut to hostSoundOut
 10/7/94/daj  - Changed allocFromZone: to allocFromZone:onDSP: in 
 allocFromZone:onDSP:.
 7/18/95/daj -  Subunit support.  Changed to loop over contiguous array (orchs)
 instead of sparse array (orchestras, which has been renamed to
			  dspNumToOrch).
 11/23/95/daj-nick - Changed deallocation in freeUGs to really free them
 (fix of a memory leak).  Also set isLoopOffChip to NO.
 1/1/96/daj -   Added sound delegate
 1/11/96/daj -  Plugged leak in setMonitorFileName:
 7/12/97/daj -  Added MONITOR_4_2 driver parameter for release 4.2
 */

#import <Foundation/NSUserDefaults.h>
#import "_musickit.h"
#import "_error.h"
#import "_time.h"
#import "PatchTemplatePrivate.h"
#import "ConductorPrivate.h"

/* FIXME Consider changing patch List and unitGeneratorStack to non-objc linked lists. */

#define COMPACTION 1 /* Set to 0 to turn off compaction. */
#define READDATA 0   /* Set to 1 to turn on read data to host */

/* Codes returned by memory allocation routines (private) */
#define OK 0
#define TIMEERROR -2
#define BADADDR -1
#define NOMEMORY MAXINT

/* Size of "leaper" (causes orch loop to leap off chip) and "looper" 
(causes orch loop to return to start of loop) */
#define LEAPERSIZE 3  /* For jumping off-chip */
#define LOOPERSIZE 2

/* The DSP memory map, in orchestra terms, is given by the following: 
*/

/* The following constants deal with the bounds of DSP INTERNAL memory. 
Ultimately, they should be dynamically obtained from the DSP library.
But it is assumed that the INTERNAL memory size of the DSP will not
change. 
When things change enough for them to become variables, we may want to 
revamp the entire memory map. Note also that the MKOrchestra assumes 
overlaid addressing of off-chip memory (i.e. X, Y and P spaces all refer 
					to the same memory location). 
FIXME */
/* The value of _DEGMON_L can be reduced if we don't care about trapping
illegal DSP instructions correctly and don't think we'll ever add any
more host commands.  Furthermore, it would need to be increased for the
new DSP rev if we decided we DID still want to support trapping illegal
DSP instructions. */
#define _DEGMON_L     0x000034 
#define _XHI_USR      0x0000f5
#define _YHI_USR      0x0000f5
#define _XLI_USR      0x000005 /* Changed from 4 to 5 by DAJ. Jan 31, 1993 */
#define _YLI_USR      0x000005 /* ditto */
#define _PHI_USR      0x0001ff
// #define _PLI_USR      0x000080  /* 1.0 number */
#define _PLI_USR      0x00009b

/* The following constants must be kept in synch with mkmon_8k.asm and libdsp. */
#define _BIG_SND_BUFFER_SIZE 8192 /* Driver buffers in non-fast-response mode */
#define _SND_BUFF_COUNT 4     /* Number of buffers in the driver */
#define _DSP_SND_BUFFER_SIZE 0x200 /* Total sound-out or sound-in buffer size on DSP.
Assume sound-in and sound-out use same size */

/* The following numbers are the default values for the percentage of 
off-chip memory devoted to X and Y unit generator arguments, respectively. 
If these values are used for the standard 8k memory configuration, they 
come out to the same numbers used in the 1.0 release, i.e. 272. They were 
computed as follows:

XARGPCDEFAULT = 272/(DSPMK_HE_USR - DSPMK_LE_USR) = 
(float) 272/(0x30d9-0x4313)

*/

#define XARGPCDEFAULT 0.063065151884503 
#define YARGPCDEFAULT 0.063065151884503 

/* On-chip P memory -------------------------------------------------------- */
#define ORCHLOOPLOC (self->_bottomOfMemory)
/*  the first user location. */
#define MINPILOOP  (ORCHLOOPLOC)
/*  where the looper jumps to. */
#define MAXPILOOP  (_PHI_USR - LEAPERSIZE)
/*  upper bound of internal p loop. Leaves room for leaper to offchip */
#define DEFAULTONCHIPPATCHPOINTS 11

/* On-chip L memory -------------------------------------------------------- */
#define MINLARG    (MAX(_XLI_USR,_YLI_USR))
/*  lower bound of lArg. */
#define MAXLARG    (MAXXPATCH - self->_onChipPPPartitionSize)
/*  upper bound of lArg. Shares with xArg and yArg. */

/* On-chip X memory ------------------------------------------------------ */
#define MINXPATCH   (MAXLARG + 1)
/*  lower bound of on-chip patch-points partition. */
#define MAXXPATCH   (MIN(_XHI_USR,_YHI_USR))

/*  upper bound of on-chip patch-point partition. Other patch-points offchip */

/* On-chip Y memory ---------------------------------------------------- */
#define MINYPATCH   MINXPATCH
/*  lower bound of on-chip patch-points partition. */
#define MAXYPATCH   MAXXPATCH
/*  upper bound of on-chip patch-point partition. Other patch-points offchip */

/* Off-chip memory (overlaid) --------------------------------------------- */

#define NUMXARGS self->_numXArgs
#define NUMYARGS self->_numYArgs

#define X_EMEM 0
#define Y_EMEM 1
#define P_EMEM 2
#define O_EMEM X_EMEM /* Overlaid external memory. */
#define EMEM_INVALID (-1)

#define P_IND(_self) ((_self->_overlaidEMem!=MK_orchEmemNonOverlaid)?O_EMEM: P_EMEM)
#define X_IND(_self) ((_self->_overlaidEMem!=MK_orchEmemNonOverlaid) ?O_EMEM: X_EMEM)
#define Y_IND(_self) ((_self->_overlaidEMem==MK_orchEmemOverlaidXYP) ?O_EMEM: Y_EMEM)

static int segToMemIndNonOverlaid[] = {
    EMEM_INVALID, /* MK_noSegment */
    P_EMEM,       /* MK_pLoop */
    P_EMEM,       /* MK_pSubr */
    X_EMEM,       /* MK_xArg */
    Y_EMEM,       /* MK_yArg */
    EMEM_INVALID, /* MK_lArg */
    X_EMEM,       /* MK_xData */
    Y_EMEM,       /* MK_yData */
    EMEM_INVALID, /* MK_lData */
    X_EMEM,       /* MK_xPatch */
    Y_EMEM,       /* MK_yPatch */
    EMEM_INVALID}; /* MK_lPatch */

static int segToMemIndOverlaidPX[] = {
    EMEM_INVALID, /* MK_noSegment */
    O_EMEM,       /* MK_pLoop */
    O_EMEM,       /* MK_pSubr */
    O_EMEM,       /* MK_xArg */
    Y_EMEM,       /* MK_yArg */
    EMEM_INVALID, /* MK_lArg */
    O_EMEM,       /* MK_xData */
    Y_EMEM,       /* MK_yData */
    EMEM_INVALID, /* MK_lData */
    O_EMEM,       /* MK_xPatch */
    Y_EMEM,       /* MK_yPatch */
    EMEM_INVALID}; /* MK_lPatch */

#define S_IND(_self,_segment) \
  ((_self->_overlaidEMem==MK_orchEmemOverlaidXYP) ?O_EMEM: \
   (_self->_overlaidEMem==MK_orchEmemNonOverlaid) ?segToMemIndNonOverlaid[_segment]: \
   (segToMemIndOverlaidPX[_segment]))
   
static int extraRoomAtTopOfOffchipMemory = 0;

int _MKSetTopOfMemory(int val)
    /* This is something Julius wanted for debugging purposes. It allows an
       extra partition to be left at the top of DSP memory. Must be 
       called before the MKOrchestra is opened. val is the amount of extra
       room to leave at the top of memory. */
{
    extraRoomAtTopOfOffchipMemory = val;
    return 0;
}

#define SINTABLESPACE MK_yData
#define MULAWTABLESPACE MK_xData

#define JUMP 0x0af080  /* Used by leaper */
#define SHORTJUMP 0x0C0000 /* add in short (12 bit) jump address */ 

#import "SynthDataPrivate.h"
#import "UnitGeneratorPrivate.h"
#import "SynthPatchPrivate.h"
#import "_SharedSynthInfo.h"
#import "_OrchloopbeginUG.h"

#import "OrchestraPrivate.h"

@implementation MKOrchestra

/* Some global variables. --------------------------------------- */
static char isTimedDefault = YES;

static NSMutableArray *synthInstruments = nil;

#define DEFAULTSRATE         22050.0
#define DEFAULTHEADROOM      .1
#define HEADROOMFUDGE        (-(.1 + .025 + .02)) /* .02 added by daj Feb 4, 1993 */

static double samplingRateDefault = DEFAULTSRATE;
static BOOL fastResponseDefault = NO;
static double headroomDefault = DEFAULTHEADROOM;
static double localDeltaTDefault = 0;

/* Memory allocation primitives */
typedef struct _dataMemBlockStruct {
    DSPAddress baseAddr;
    DSPAddress size;
    BOOL isAllocated;
    struct _dataMemBlockStruct *next,*prev;
} dataMemBlockStruct;

#define DATAMEMBLOCKCACHESIZE 32
static dataMemBlockStruct *dataMemBlockCache[DATAMEMBLOCKCACHESIZE];
static unsigned dataMemBlockCachePtr = DATAMEMBLOCKCACHESIZE;

static dataMemBlockStruct *allocDataMemBlock(void)
/* alloc a new structure that keeps track of data memory. */
{
    if (dataMemBlockCachePtr) 
	return dataMemBlockCache[--dataMemBlockCachePtr]; 
    else {
        dataMemBlockStruct *theBlock;
        _MK_MALLOC(theBlock,dataMemBlockStruct,1);
        return theBlock;
    }
}

static void initDataMemBlockCache(void)
/* init cache of structs that keep track of data memory */
{
    int i;
    for (i=0; i<DATAMEMBLOCKCACHESIZE; i++)
	_MK_MALLOC(dataMemBlockCache[i],dataMemBlockStruct,1);
}

static dataMemBlockStruct *freeDataMemBlock(dataMemBlockStruct *block)
/* Free a dataMemBlockStruct. Cache it, if possible */
{
    if (block) {
	if (dataMemBlockCachePtr < DATAMEMBLOCKCACHESIZE) {
	    dataMemBlockCache[dataMemBlockCachePtr++] = block;
	}
	else {
	    free(block);
	    block = NULL;
	}
    }
    return NULL;
}

static id allocUG(); /* Forward refs. */
static void givePatchMem();
static void giveDataMem();
static DSPAddress getPatchMem();
static DSPAddress getDataMem();
static DSPAddress getPELoop();
static BOOL givePELoop();

// TODO should become an NSArray
static id *patchTemplates = NULL; /* Array of PatchTemplates */
static int nTemplates = 0;  /* Number of templates about which the orchestra knows. */
static unsigned short nDSPs = 0;  /* Number of DSP resources */
// TODO should become an NSArray
static id *orchestraClasses = NULL;

// The default loop unit generator class
static id defaultOrchloopClass = nil;

// Holds the mapping from DSP index number to MKOrchestra instance.
// All orchestra instances created are held, indexed by DSP number (0 based).
// TODO this implies a strict one DSP, one MKOrchestra instance. This may nowdays be a relaxable constraint.
static NSMutableDictionary *dspNumToOrch = nil; 

// TODO should become an NSArray caching the result of [dspNumToOrch valueObjects]
static id *orchs = NULL;
/* Packed nil-terminated array of Orchestras that have actually been created */
// TODO should become [orchs makeObjectsPerformSelector: @sel(blah)];
#define FOREACHORCH(_i) for (_i=0; orchs[i]; _i++) 


_MK_ERRMSG garbageMsg = @"Garbage collecting freed unit generator %@_%p";

static NSString * orchMemSegmentNames[(int) MK_numOrchMemSegments] = 
{@"noSegment",@"pLoop",@"pSubr",@"xArg",@"yArg",@"lArg",@"xData",@"yData",@"lData",
    @"xPatch",@"yPatch",@"lPatch"};

- (double) systemOverhead
    /* Subclasses can override this. */
{
    return 0.0;
}


/* Initialization methods --------------------------------------- */

+ (NSString *) driverParameter: (NSString *) parameterName 
		forOrchIndex: (unsigned short) index
{
    char *s;
    if (index >= nDSPs) 
	return NULL;
    DSPSetCurrentDSP(index);
    s = DSPGetDriverParameter([parameterName UTF8String]);
    return s ? [NSString stringWithUTF8String: s] : @"";
}

- (NSString *) driverParameter: (NSString *) parameterName
{
    char *s;
    DSPSetCurrentDSP(orchIndex);
    s = DSPGetDriverParameter([parameterName UTF8String]);
    return s ? [NSString stringWithUTF8String: s] : @"";
}

+ (NSArray *) getDriverNames
{
    return [SndStreamManager getDriverNamesForOutput: YES];
}

- (NSString *) driverName 
{
    // return (DSPGetInUseDriverNames() )[orchIndex];
    return @"Not Yet Implemented"; // driverNames[orchIndex]; or just driverName?
}

-(int) driverUnit
{
    return (DSPGetInUseDriverUnits())[orchIndex];
}

-(int) driverSubUnit
{
    return (DSPGetInUseDriverSubUnits())[orchIndex];
}

/* Sent once at start-up time. */
+ (void) initialize
{
    _MKLinkUnreferencedClasses([MKUnitGenerator class], [MKSynthData class], [_OrchloopbeginUG class]);
    NSAssert(((DSP_SINE_SPACE == 2) && (DSP_MULAW_SPACE == 1)), @"Need to change SINTABLESPACE or MULAWTABLESPACE.");
    defaultOrchloopClass = [_OrchloopbeginUG class];
    nDSPs = (unsigned short) DSPGetDSPCount();
    dspNumToOrch = [[NSMutableDictionary dictionaryWithCapacity: nDSPs] retain];
    _MK_CALLOC(orchs,id,(int) nDSPs+1); /* + 1 for trailing nil */
    _MK_CALLOC(orchestraClasses,id,(int) nDSPs);
    {   
	/* If there's an ORCHESTRA parameter provided by the DSP driver,
	* get its value and use it as the MKOrchestra class.
	*/
	int dspIndex;
	for (dspIndex = 0; dspIndex < nDSPs; dspIndex++) {
	    id classObj = nil;
	    NSString *className;
            className = [MKOrchestra driverParameter: [NSString stringWithUTF8String: DSPDRIVER_PAR_ORCHESTRA] 
					forOrchIndex: dspIndex];
	    if (className)
                classObj = NSClassFromString(className);
	    if (classObj)
		[MKOrchestra registerOrchestraSubclass: classObj forOrchIndex: dspIndex];
	}
    }
    _MKCheckInit();
    initDataMemBlockCache();
}    

// Nowdays a "DSP" becomes an abstract concept of processing resource rather than an actual hardware device.
// In theory it could be another DSP processor, a native processor (for multi-processor machines) or a vector unit.
// We retain the indexing to allow allocation of processing resources.
- initOnDSP: (unsigned short) dspIndex;
{
    int i;
    
    self = [super init];
    if(self != nil) {
	orchIndex = dspIndex;
	deviceStatus = MK_devClosed;
	_simFP = NULL;
	[dspNumToOrch setObject: self forKey: [NSNumber numberWithInt: orchIndex]];
	// TODO orchs = [dspNumToOrch values];
	/* Now add it to the end of orchs */
	for (i = 0; orchs[i] != nil; i++) /* Get to end */
	    ;
	orchs[i] = self; 
	[self setSamplingRate: samplingRateDefault];
	[self setFastResponse: fastResponseDefault];
	[self setHeadroom: headroomDefault];
	[self setLocalDeltaT: localDeltaTDefault];
	[self setTimed: isTimedDefault];     
	[self setDefaultSoundOut];	
    }
    return self;
}

- init
{
    return [self initOnDSP: 0];
}

+ orchestra
{
    return [[[MKOrchestra alloc] init] autorelease];
}

/* Create all orchestras (one per DSP) by sending them the orchestraOnDSP: method
  (see below). Does not claim the DSP device at this time. 
  You can check to see which MKOrchestra objects are created by using
  the +nthOrchestra: method. Returns an array of MKOrchestra instances.
*/
+ (NSArray *) orchestrasOnAllDSPs
{
    unsigned short dspIndex;
    NSMutableArray *allOrchestras = [NSMutableArray arrayWithCapacity: 2];
    
    for (dspIndex = 0; dspIndex < nDSPs; dspIndex++)  {
        MKOrchestra *orch = [self orchestraOnDSP: dspIndex];
	[allOrchestras addObject: orch];
    }
    return [NSArray arrayWithArray: allOrchestras];
}

+ orchestraOnDSP: (unsigned short) index
    /* Creates an orchestra object corresponding with the orchIndex'th DSP. 
    (DSPs are numbered from 0.) 
    The index must be of a valid DSP. If there is currently an 
    orchestra instance for that index, returns that orchestra.
    */
{
    MKOrchestra *orch;
    
    if (index >= nDSPs)
	return nil;
#if i386 && defined(__NeXT__)
    if (!driverPresent(index))
	return nil;
#endif
    // TODO this means we can only create one instance of MKOrchestra on a DSP resource.
    // We may want to relax this constraint in the future.
    orch = [dspNumToOrch objectForKey: [NSNumber numberWithInt: index]];
    if (orch != nil)
	return orch;
    if (self == [MKOrchestra class]) { /* Avoid infinite recursion */
	if (orchestraClasses[index]) 
	    return [[orchestraClasses[index] alloc] initOnDSP: index];
    }
    orch = [[MKOrchestra alloc] initOnDSP: index];
    return [orch autorelease];
}

+ (MKOrchestra *) nthOrchestra: (unsigned short) index
    /* Returns the index'th orchestra or nil if none. */
{
    if (index >= nDSPs)
	return nil;
    return [dspNumToOrch objectForKey: [NSNumber numberWithInt: index]];
}

#define DEBUG_DELTA_T 0

#if DEBUG_DELTA_T
/* This stuff allows us to tell exactly when stuff is sent to the dsp. 
It is normally commented out. */

#import <sys/time_stamp.h>

#define MAX_STAMPS      200

static unsigned timeStamps[MAX_STAMPS];
static int numStamps = 0;

static double MKTimeStamps[MAX_STAMPS];
static int numMKStamps = 0;

static unsigned DSPTimeStamps[MAX_STAMPS];
static int numDSPStamps = 0;

static void _timeStamp(void)
{
    struct tsval timeStruct;
    
    if (numStamps == MAX_STAMPS)
	return;
    kern_timestamp(&timeStruct);
    timeStamps[numStamps++] = timeStruct.low_val;
}

void _printTimeStamps(void)
{
    
    int i;
    
    printf("Number of time stamps: %d\n", numStamps);
    if (numStamps == MAX_STAMPS)
	printf("MAY HAVE MISSED SOME TIME STAMPS!!!!\n");
    printf("time\tdelta\n");
    for (i = 0; i < numStamps; i++) {
        if (i != 0)
	    printf("\t%d\n", timeStamps[i] - timeStamps[i-1]);
        printf("%u\n", timeStamps[i]);
    }
    printf("Number of DSP time stamps: %d\n", numStamps);
    if (numDSPStamps == MAX_STAMPS)
	printf("MAY HAVE MISSED SOME TIME STAMPS!!!!\n");
    printf("time\tdelta\n");
    for (i = 0; i < numDSPStamps; i++) {
        if (i != 0)
	    printf("\t%d\n", DSPTimeStamps[i] - DSPTimeStamps[i-1]);
        printf("%u\n", DSPTimeStamps[i]);
    }
    printf("Number of MK time stamps: %d\n", numStamps);
    if (numMKStamps == MAX_STAMPS)
	printf("MAY HAVE MISSED SOME TIME STAMPS!!!!\n");
    printf("time\tdelta\n");
    for (i = 0; i < numMKStamps; i++) {
        if (i != 0)
	    printf("\t%f\n", MKTimeStamps[i] - MKTimeStamps[i-1]);
        printf("%u\n", MKTimeStamps[i]);
    }
}

static void _DSPTimeStamp()
{
    int stamp;
    DSPFix48 aTimeStamp = *_MKCurSample(self);
    if (numDSPStamps == MAX_STAMPS)
	return;
    DSPMKRetValueTimed(&aTimeStamp,DSP_MS_Y,2,&stamp);
    DSPTimeStamps[numStamps++] = stamp;
}

static void _MKTimeStamp()
{
    if (numDSPStamps == MAX_STAMPS)
	return;
    MKTimeStamps[numStamps++] = MKGetTime();
}

#endif

-setMonitorFileName: (NSString *) name
{
    if (deviceStatus != MK_devClosed)
	return nil;
    [monitorFileName autorelease];
//    if (monitorFileName)         /* This is only set if the user explicitly set it */
//      free(monitorFileName);
    if (name) {
//	monitorFileName = _MKMakeStr(name);
        monitorFileName = [name copy];
	if (mkSys)
	    DSPLoadSpecFree(mkSys);
	mkSys = NULL;
    }
    else monitorFileName = nil;
    return self;
}

-(NSString *) monitorFileName
{
#if m68k
    static int memSize = 0;  /* Only do it once */
    if (monitorFileName)
	return monitorFileName;
    /* Else use default */
    if (!memSize)
	if (DSPSenseMem(&memSize))
	    return nil;
    if (memSize == DSP_64K)
	return DSP_192K_MUSIC_SYSTEM_BINARY_0; /* non-overlaid (UCSF board) */
    if (memSize == DSP_32K)
	return DSP_32K_MUSIC_SYSTEM_BINARY_0;
    return [NSString stringWithUTF8String: DSP_MUSIC_SYSTEM_BINARY_0];
#else
    if (monitorFileName)      /* Allow user-override */
	return monitorFileName;
    if (!_driverParMonitorFileName)
        _driverParMonitorFileName = [self driverParameter: [NSString stringWithUTF8String: DSPDRIVER_PAR_MONITOR_4_2]];
    if (!_driverParMonitorFileName) /* Pre-4.2 driver? */
        _driverParMonitorFileName = [self driverParameter: [NSString stringWithUTF8String: DSPDRIVER_PAR_MONITOR]];
    return _driverParMonitorFileName;
#endif
}

-flushTimedMessages
    /* Flush timed messages. */
{
    if (deviceStatus == MK_devClosed)
	return self;
    DSPSetCurrentDSP(orchIndex);
    DSPMKFlushTimedMessages();
#if DEBUG_DELTA_T
    /* This is normally commented out */
    _DSPTimeStamp();
    _timeStamp();
    _MKTimeStamp();
#endif
    return self;
}

+(unsigned short) DSPCount
    /* Returns the number of DSPs configured on the NeXT machine. The standard
    configuration contains one DSP. This is not necessarily the number of
    DSPs available to your program as other programs may have other DSPs
    assigned. */
{
    return nDSPs;
}

static void setLooper(MKOrchestra *self); /* forward ref */
static int resoAlloc(MKOrchestra *self,id factObj,MKOrchMemStruct *reloc);

-setDefaultSoundOut
    /* Sets orchestra sound output to "default state".  
    * For NeXT hardware, this means
    * using the NeXT monitor's sound hardware.  
    * For Intel-based hardware, it means
    * using the serial port device returned by the 
    * driver parameter, if any. If the driver returns "NeXT"
    * that means that we get the serial port device from the
    * defaults data base.
    */
{
    NSString *s;
    NSString *name;
    [self setOutputSoundfile: nil];
    [self setOutputSoundDelegate: nil];
    [self setOutputCommandsFile: NULL];
    [self useDSP: YES];
    s = [self driverParameter: [NSString stringWithUTF8String: DSPDRIVER_PAR_SERIALPORTDEVICE]];
    _nextCompatibleSerialPort = (s && [s isEqualToString: @"NeXT"]);
    if (_nextCompatibleSerialPort) {
	/* Get it from defaults data base */
        name = [NSString stringWithFormat: @"MKDSPSerialPortDevice%d",orchIndex];
        s = [[NSUserDefaults standardUserDefaults] objectForKey: name];
    }
    s = [[NSUserDefaults standardUserDefaults] objectForKey: @"MKOrchestraSoundOut"];
    if ([s isEqualToString: @"Host"] && ([self capabilities] & MK_hostSoundOut))
	[self setHostSoundOut: YES];
    return self;
}

static id broadcastAndRtn(MKOrchestra *self, SEL sel)
/* Does broadcast. Returns nil if any orchestras return nil, else self. */
{
    register unsigned short i;
    id rtn = self;
    id tmp;
    FOREACHORCH(i) {
        tmp = [orchs[i] performSelector: sel];
        if (!tmp && orchs[i])
	    rtn = nil;
    }
    return rtn;
}

+flushTimedMessages
    /* Send all buffered DSP messages immediately for all orchestras. 
    Returns self. */
{
    register unsigned short i;
    FOREACHORCH(i) 
	[orchs[i] flushTimedMessages];
    return self;
}

/*sb: was +free before OS conversion. FIXME - not good OS allocation strategy I think.*/
/* Frees all orchestra objects by sending -free to each orchestra object. 
Returns self. */
+ (void) dealloc
{
    NSArray *orchestrasAllocatedOnDSPs = [dspNumToOrch allValues];

    [orchestrasAllocatedOnDSPs makeObjectsPerformSelector: @selector(release)];
    [super dealloc];
}

/* Sends open to each orchestra object. Returns nil if one of the
MKOrchestra returns nil, else self. */
+ open
{
    return broadcastAndRtn(self, @selector(open));
}

+ run
    /* Sends run to each orchestra object. Returns nil if one of the 
    Orchestras does, else self. */
{
    return broadcastAndRtn(self, @selector(run));
}

+ stop
    /* Sends stop to each orchestra object. */
{
    return broadcastAndRtn(self, @selector(stop));
}

#if 0
+ step
    /* Sends step to each orchestra object. */
{
    unsigned short i;
    FOREACHORCH(i)
	[orchs[i] step];
    return self;
}
#endif

+ close
    /* Sends close to each orchestra object. Returns nil if one of the 
    Orchestras does, else self. */
{
    return broadcastAndRtn(self, @selector(close));
}

+ abort
    /* Sends abort to each orchestra object. Returns nil if one of the 
    Orchestras does, else self. */
{
    return broadcastAndRtn(self, @selector(abort));
}


+ (void) setSamplingRate: (double)newSRate
    /* Sets sampling rate (for all orchs). It is illegal to do this while an
    orchestra is open. */
{
    unsigned short i;
    samplingRateDefault = newSRate;
    FOREACHORCH(i)
	[(MKOrchestra *) orchs[i] setSamplingRate: newSRate];
}

+ setFastResponse: (char) yesOrNo
    /* Sets whether fast response (small sound out buffers) is used (for all
    orchs). It is illegal to do this while an
    orchestra is open */
{
    unsigned short i;
    fastResponseDefault = yesOrNo;
    FOREACHORCH(i)
	[orchs[i] setFastResponse: fastResponseDefault];
    return self;
}

+ (void) setHeadroom: (double) newHeadroom
    /* Sets headroom for all orchs. */
{
    unsigned short i;
    
    headroomDefault = newHeadroom;
    FOREACHORCH(i)
	[orchs[i] setHeadroom: newHeadroom];
}

+ setLocalDeltaT: (double) newLocalDeltaT
    /* Sets localDeltaT for all orchs. */
{
    unsigned short i;
    localDeltaTDefault = newLocalDeltaT;
    FOREACHORCH(i)
	[orchs[i] setLocalDeltaT: localDeltaTDefault];
    return self;
}


+ setTimed: (MKOrchestraTiming) areOrchsTimed
    /* Controls (for all orchs) whether DSP commands are sent timed or untimed. 
    Untimed DSP commands are executed as soon as they are received by the DSP.
    It is permitted to change from timed to untimed during a performance, 
    but it will not work correctly in release 0.9.  */
{
    int  i;
    isTimedDefault = areOrchsTimed;
    FOREACHORCH(i)
	[orchs[i] setTimed: areOrchsTimed];
    return self;
}

- (MKOrchestraTiming) isTimed
    /* Returns whether DSP commands are sent timed. */
{
    return isTimed;
}

/* Allocation methods for the entire orchestra. ----------------------- */

+ allocUnitGenerator:  classObj 
    /* Allocate a unit generator of the specified class
    on the first DSP which has room. */
{
    id rtnVal;
    register unsigned short i;
    FOREACHORCH(i);
    if ((rtnVal = [orchs[i] allocUnitGenerator: classObj]))
        return rtnVal;
    return nil;
}

+ allocSynthData: (MKOrchMemSegment) segment length: (unsigned ) size
    /* Allocate some private data memory on the first DSP which has room. */
{
    id rtnVal;
    register unsigned short i;
    FOREACHORCH(i);
    if ((rtnVal = [orchs[i] allocSynthData: segment length: size]))
        return rtnVal;
    return nil;
}

+ allocPatchpoint: (MKOrchMemSegment) segment 
    /* Allocate patch memory on first DSP which has room. segment must
    be MK_xPatch or MK_yPatch. */
{
    id rtnVal;
    register unsigned short i;
    FOREACHORCH(i);
    if ((rtnVal = [orchs[i] allocPatchpoint: segment]))
        return rtnVal;
    return nil;
}

+ allocSynthPatch: aSynthPatchClass
  /* Same as allocSynthPatch: patchTemplate: but uses default template. The default
    template is obtained by sending [aSynthPatchClass defaultPatchTemplate].*/
{
    return [self allocSynthPatch: aSynthPatchClass patchTemplate: 
	[aSynthPatchClass defaultPatchTemplate]];
}

+ allocSynthPatch: aSynthPatchClass
    patchTemplate: p
    /* Get a MKSynthPatch on the first DSP which has sufficient resources. */
{
    id rtnVal;
    register int i;
    FOREACHORCH(i);
    if ((rtnVal = [orchs[i] allocSynthPatch: aSynthPatchClass patchTemplate: p]))
        return rtnVal;
    return nil;
}

+ dealloc: aSynthResource
    /* Deallocates aSynthResource by sending it the dealloc
    message. 
    aSynthResource may be a MKUnitGenerator, a MKSynthData or a MKSynthPatch.
    This method is provided for symmetry with the alloc family
    of methods. */
{
    [aSynthResource mkdealloc]; /* sb: changed to mkdealloc */
    return aSynthResource;
}

- dealloc: aSynthResource
    /* Deallocates aSynthResource by sending it the dealloc
    message. 
    aSynthResource may be a MKUnitGenerator, a MKSynthData or a MKSynthPatch.
    This method is provided for symmetry with the alloc family
    of methods. */
{
    [aSynthResource mkdealloc]; /*sb: changed to mkdealloc */
    return aSynthResource;
}

/* Assorted instance methods and functions. ----------------------------- */

NSHashTable *_MKGetSharedSynthGarbage(MKOrchestra *self)
{
    return self->sharedGarbage;
}

static char **sharedTypeTable = NULL;
static int sharedTypeTableSize = 0;
static int numSharedTypes = 0;

static void initSharedTable(void)
{
    _MK_MALLOC(sharedTypeTable,char *,10);
    sharedTypeTableSize = 10;
    sharedTypeTable[0] = "noOrchSharedType";
    sharedTypeTable[1] = "oscTable";
    sharedTypeTable[2] = "waveshapingTable";
    numSharedTypes = 3;
}

+ (int) sharedTypeForName: (char *) str
    /* Return shared type for the specified name. */
{
    int i;
    if (!sharedTypeTable) 
	initSharedTable();
    for (i=0; i<numSharedTypes; i++)
	if (strcmp(str,sharedTypeTable[i]) ==0)
	    return i;
    /* Not found */
    if (sharedTypeTableSize == numSharedTypes) {
	sharedTypeTableSize *= 2;
	_MK_REALLOC(sharedTypeTable,char *,sharedTypeTableSize);
    }
    sharedTypeTable[++numSharedTypes] = _MKMakeStr(str);
    return numSharedTypes;
}

+ (char *) nameForSharedType: (int) typeInt
{
    int i;
    if (!sharedTypeTable) 
	initSharedTable();
    for (i=0; i<numSharedTypes; i++)
	return sharedTypeTable[i];
    return NULL;
}

- sharedSynthDataFor: aKeyObj 
	     segment: (MKOrchMemSegment) whichSegment 
	      length: (int) length
    /* This method returns the MKSynthData, MKUnitGenerator or MKSynthPatch instance 
    representing anObj in the specified segment and increments its reference 
    count, if such an object exists. 
    If not, or if the orchestra is not open, returns nil. 
    anObj is any object associated with the abstract notion of the data.
    The object comparison is done on the basis of aKeyObj's id. */
{
    if (deviceStatus == MK_devClosed)
	return nil;
    return _MKFindSharedSynthObj(_sharedSet,sharedGarbage,aKeyObj,
                                 whichSegment,length,MK_noOrchSharedType);
}

/* Obsolete */
-sharedObjectFor: aKeyObj 
	 segment: (MKOrchMemSegment) whichSegment 
	  length: (int) length
{
    return [self sharedSynthDataFor: aKeyObj segment: whichSegment length: length];
}


- sharedSynthDataFor: aKeyObj 
	     segment: (MKOrchMemSegment)whichSegment 
	      length: (int) length
	        type: (MKOrchSharedType) type
{
    if (deviceStatus == MK_devClosed)
	return nil;
    return _MKFindSharedSynthObj(_sharedSet,sharedGarbage,aKeyObj,
                                 whichSegment,length,type);
}

- sharedSynthDataFor: aKeyObj segment: (MKOrchMemSegment) whichSegment
{
    return [self sharedSynthDataFor: aKeyObj segment: whichSegment length: 0];
}

/* Obsolete */
-sharedObjectFor: aKeyObj segment: (MKOrchMemSegment) whichSegment
{
    return [self sharedSynthDataFor: aKeyObj segment: whichSegment];
}

- sharedSynthDataFor: aKeyObj 
	     segment: (MKOrchMemSegment) whichSegment 
	        type: (MKOrchSharedType) type
{
    return [self sharedSynthDataFor: aKeyObj segment: whichSegment length: 0
			       type: type];
}

- sharedObjectFor: aKeyObj 
{
    return [self sharedSynthDataFor: aKeyObj segment: MK_noSegment length: 0];
}

- sharedObjectFor: aKeyObj type: (MKOrchSharedType) type
{
    return [self sharedSynthDataFor: aKeyObj segment: MK_noSegment length: 0
			       type: type];
}

static id installSharedObject(MKOrchestra *self,
                              id aSynthObj,
                              id aKeyObj,
                              MKOrchMemSegment whichSegment,
                              int length,
			      MKOrchSharedType type)
/* This function installs the synthObj into the shared 
table in the specified segment and sets the reference count to 1.
Does nothing and returns nil if aKeyObj is already represented for that
segment. Also returns nil if the orchestra is not open. Otherwise, 
returns self. 
aKeyObj is any object associated with the abstract notion of the data.
aKeyObj is not copied and should not be freed while any shared data 
associated with it exists. 
*/
{
    if (self->deviceStatus == MK_devClosed)
	return nil;
    if (_MKInstallSharedObject(self->_sharedSet,aSynthObj,aKeyObj,whichSegment,
                               length,type)) {
        if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	    _MKOrchTrace(self,MK_TRACEORCHALLOC,
			 @"Installing shared data %@ in segment %@.",
			 NSStringFromClass([aKeyObj class]) ,[self segmentName: whichSegment]);
        return self;
    }
    return nil;
}

-installSharedSynthDataWithSegmentAndLength: (MKSynthData *) aSynthDataObj
					for: aKeyObj
{
    return installSharedObject(self,aSynthDataObj,aKeyObj,
                               [aSynthDataObj orchAddrPtr]->memSegment, 
                               [aSynthDataObj length],
			       MK_noOrchSharedType);
}

-installSharedSynthDataWithSegmentAndLength: (MKSynthData *) aSynthDataObj
					for: aKeyObj type: (MKOrchSharedType) aType
{
    return installSharedObject(self,aSynthDataObj,aKeyObj,
                               [aSynthDataObj orchAddrPtr]->memSegment, 
                               [aSynthDataObj length],
			       aType);
}

-installSharedSynthDataWithSegment: aSynthDataObj
			       for: aKeyObj
{
    return installSharedObject(self,aSynthDataObj,aKeyObj,
                               [aSynthDataObj orchAddrPtr]->memSegment,
			       0,
			       MK_noOrchSharedType); 
}

-installSharedSynthDataWithSegment: aSynthDataObj
			       for: aKeyObj type: (MKOrchSharedType) aType
{
    return installSharedObject(self,aSynthDataObj,aKeyObj,
                               [aSynthDataObj orchAddrPtr]->memSegment,
			       0,
			       aType);
}

-installSharedObject: aSynthObj 
		 for: aKeyObj
{
    return installSharedObject(self,aSynthObj,aKeyObj, 
                               MK_noSegment,
			       0,
			       MK_noOrchSharedType);
}

-installSharedObject: aSynthObj 
		 for: aKeyObj type: (MKOrchSharedType) aType
{
    return installSharedObject(self,aSynthObj,aKeyObj, 
                               MK_noSegment,
			       0,
			       aType);
}

- sineROM
    /* Returns a MKSynthData object representing the SineROM. You should never
    deallocate this object. */
{
    return sineROM;
}

- muLawROM
    /* Returns a MKSynthData object representing the MuLawROM. You should never
    deallocate this object. */
{
    return muLawROM;
}

/* READ DATA */
- segmentInputSoundfile: (MKOrchMemSegment) segment
    /* Returns special pre-allocated Patchpoint which always holds 0 and which,
    by convention, nobody ever writes to. This patch-point may not be
    freed. You should not deallocate
    the returned value. Segment should be MK_xPatch or MK_yPatch. */
{
    return ((segment == MK_xPatch) || (segment == MK_xData)) ? xReadData : yReadData;
}

- segmentZero: (MKOrchMemSegment) segment
    /* Returns special pre-allocated Patchpoint which always holds 0 and which,
    by convention, nobody ever writes to. This patch-point may not be
    freed. You should not deallocate
    the returned value. Segment should be MK_xPatch or MK_yPatch. */
{
    return ((segment == MK_xPatch) || (segment == MK_xData)) ? xZero : yZero;
}

- segmentSink: (MKOrchMemSegment) segment
    /* Returns special pre-allocated Patchpoint from which nobody reads, by
    convention. This patch-point may not be freed. 
    You should not deallocate the returned value. 
    Segment should be MK_xPatch or MK_yPatch. */
{
    return ((segment == MK_xPatch) || (segment == MK_xData)) ? xSink : ySink;
}

- segmentSinkModulus: (MKOrchMemSegment) segment
    /* Returns special pre-allocated modulus Patchpoint from which nobody 
    reads, by convention. This patch-point may not be freed. 
    You should not deallocate the returned value. 
    Segment should be MK_xPatch or MK_yPatch. */
{
    return (((segment == MK_xPatch) || (segment == MK_xData)) ? xModulusSink : 
	    yModulusSink);
}

- (int) tickSize
{
    return DSPMK_I_NTICK;       /* from dsp.h */
}

- (double) samplingRate
    /* Returns samplingRate. */
{
    return samplingRate;
}

#if !m68k
-(int) _waitStates
{
    NSString *s = [self driverParameter: [NSString stringWithUTF8String: DSPDRIVER_PAR_WAITSTATES]];
    if (!s)
	return 0;
    return [s intValue];
}
#endif

-_compensateForDSPClockRate
{
#if i386 && defined(__NeXT__)
#define DEFAULT_CLOCK_RATE 25  /* Mhz. */
    NSString *s = [self driverParameter: [NSString stringWithUTF8String: DSPDRIVER_PAR_CLOCKRATE]];
    int clockRate;
    double adjustment;
    if (!s || ![s length] || ([self _waitStates] >= 3))
	return self;
    clockRate = [s intValue];
    if (clockRate == DEFAULT_CLOCK_RATE)
	return self;
    adjustment = ((double) clockRate) /DEFAULT_CLOCK_RATE;
    _effectiveSamplePeriod *= adjustment;
    /* To compensate for faster-than-default (i.e. faster than old
	NeXT) DSPs, we make the samplePeriod artificially bigger.
*/
#endif
    return self;
}


- setSamplingRate: (double) newSRate
    /* Set sampling rate. Only legal when receiver is closed. Returns self
    or nil if receiver is not closed. */ 
{
    if (deviceStatus != MK_devClosed) 
	return nil;
    samplingRate =  newSRate;
    _effectiveSamplePeriod = (1.0 / newSRate) * (1 - _headroom);
    [self _compensateForDSPClockRate];
    return self;
}

- setFastResponse: (char) yesOrNo
    /* Set whether response is fast. 
    Only legal when receiver is closed. Returns self
    or nil if receiver is not closed. */ 
{
    if (deviceStatus != MK_devClosed) 
	return nil;
    fastResponse = yesOrNo;
    return self;
}

- (char) fastResponse
{
    return fastResponse;
}

- (void *) currentSample
{
    return _MKCurSample(self);
}

- (BOOL) isRealTime
{
    return hostSoundOut || soundIn;
}

- setOutputSoundfile: (NSString *) file
    /* Sets a file name to which output samples are to be written as a 
    soundfile (the string is copied). In the current release, it
    is not permissable to have an output soundfile and do sound-out at the same
    time. This message is currently ignored if the receiver is not closed. 
    If you re-run the MKOrchestra, the file is rewritten. To specify that
    you no longer want a file when the MKOrchestra is re-run, close the MKOrchestra,
     then send setOutputSoundfile: NULL. 

     Note that sending setOutputSoundfile: NULL does not automatically 
     send setHostSoundOut: YES. You must do this yourself. */
{
    if (deviceStatus != MK_devClosed) 
	return nil;
    if (outputSoundfile) {
        [outputSoundfile release];
        outputSoundfile = nil;
    }
    if (!file)
	return self;
    outputSoundfile = [file copy];
    hostSoundOut = NO;
    [self useDSP: YES];
    return self;
}

- (NSString *) outputSoundfile
    /* Returns the output soundfile or NULL if none. */
{
    return outputSoundfile;
}

- setOutputSoundDelegate: aDelegate
    /* Sets an object to receive delegate messages.  Same restrictions as
     setOutputSoundfile: 
    */
{
    if (deviceStatus != MK_devClosed) 
	return nil;
    outputSoundDelegate = aDelegate;
    if (!aDelegate)
	return self;
    hostSoundOut = NO;
    [self useDSP: YES];
    return self;
}

- outputSoundDelegate
    /* Returns the output sound delegate */
{
    return outputSoundDelegate;
}

- setOutputCommandsFile: (NSString *) file
    /* Sets a file name to which DSP commands are to be written as a DSPCommands
    format soundfile.  A copy of the fileName is stored in the instance variable
    outputCommandsFile.
    This message is currently ignored if the receiver is not closed.
    */
{
    if (deviceStatus != MK_devClosed)
        return nil;
    if (!file)
        return self;
    [outputCommandsFile release];
    outputCommandsFile = [file copy];
    [self useDSP: YES];
    return self;
}

- (NSString *) outputCommandsFile
    /* Returns the output soundfile or NULL if none. */
{
    return outputCommandsFile;
}

/* READ DATA */
- setInputSoundfile: (NSString *) file
{
    if (deviceStatus != MK_devClosed) 
	return nil;
    if (inputSoundfile) {
        [inputSoundfile release];
        inputSoundfile = nil;
    }
    if (!file)
	return self;
    inputSoundfile = [file copy];
    return self;
}

/* READ DATA */
- (NSString *) inputSoundfile
    /* Returns the input soundfile or NULL if none. */
{
    return inputSoundfile;
}

- setSimulatorFile: (char *) filename
    /* Sets a file name to which logfile output suitable for the DSP simulator
    is to be written. In the current release a complete log is only available
    when doing sound-out or writing a soundfile.
    This message is currently ignored if the receiver is not closed. 
    If you re-run the MKOrchestra, the file is rewritten. To specify that
    you no longer want a file when the MKOrchestra is re-run, close the MKOrchestra,
     then send setSimulatorFile: NULL.  */
{
    if (deviceStatus != MK_devClosed) 
	return nil;
    if (simulatorFile) {
	free(simulatorFile);
	simulatorFile = NULL;
    }
    if (!filename)
	return self;
    simulatorFile = _MKMakeStr(filename);
    return self; 
}

- (char *) simulatorFile
    /* Gets text file being used for DSP log file output, if any. */
{
    return simulatorFile;
}

- setSoundOut: (BOOL) yesOrNo
{
    return [self setHostSoundOut: yesOrNo];
}

/* Controls whether sound is sent to the DACs. The default is YES. 
It is not permissable to have an output soundfile and do sound-out at the
 same time. Thus, sending sethostSoundOut: YES also sends 
 setOutputSoundfile: NULL. 
If the receiver is not closed, this message has no effect.
*/
- setHostSoundOut: (BOOL) yesOrNo
{
    if (deviceStatus != MK_devClosed)
	return nil;
    hostSoundOut = yesOrNo;
    if (hostSoundOut) {
	[self setOutputSoundfile: nil];
	[self setOutputSoundDelegate: nil];
    }
    [self useDSP: YES];
    return self;
}

- (BOOL) hostSoundOut
    /* Returns whether or not sound-out is being used. */
{
    return hostSoundOut;
}

- setSerialPortDevice: obj 
{
    if (!_nextCompatibleSerialPort)
	return nil;
    return self;
}

- serialPortDevice
{
    return nil;
}

/* Controls whether sound is sent to the SSI port. The default is NO. 
If the receiver is not closed, this message has no effect.
Now disabled.
*/
- setSerialSoundOut: (BOOL) yesOrNo
{
    if (deviceStatus != MK_devClosed)
	return nil;
    [self useDSP: YES];
    return self;
}

/* Returns whether or not sound is being sent to the SSI port. Now always NO. */
- (BOOL) serialSoundOut
{
    return NO;
}

- setSoundIn: (BOOL) yesOrNo
    /* Controls whether sound is sent to the SSI port. The default is NO. 
    If the receiver is not closed, this message has no effect.
    */
{
    if (deviceStatus != MK_devClosed) 
	return nil;
    soundIn = yesOrNo;
    [self useDSP: YES];
    return self;
}

- (BOOL) soundIn
    /* Returns whether or not sound is being sent to the SSI port. */
{
    return soundIn;
}

- (void) setDebug: (BOOL) yesOrNo
{
    NSLog(@"Set debugging %d\n", yesOrNo);
}

/* Methods that do MKOrchestra control (e.g. open, close, free, etc.) */


static BOOL popResoAndSetLooper(MKOrchestra *self);
static BOOL popReso();

#define TWO_TO_24   ((double) 16777216.0)
#define TWO_TO_48   (TWO_TO_24 * TWO_TO_24)

static DSPFix48 *doubleIntToFix48UseArg(double dval,DSPFix48 *aFix48)
/* dval is an integer stored in a double. */
{
    double shiftedDval;
#   define TWO_TO_M24 ((double) 5.9604644775390625e-08)
    if (dval < 0) 
	dval = 0;
    if (dval > TWO_TO_48)
	dval = TWO_TO_48;
    shiftedDval = dval * TWO_TO_M24;
    aFix48->high24 = (int) shiftedDval;
    aFix48->low24 = (int) ((shiftedDval - aFix48->high24) * TWO_TO_24);
    return aFix48;
}

static void freeEMem(MKOrchestra *self,int whichSpace) {
    dataMemBlockStruct *tmp;
    while ((dataMemBlockStruct *) self->_eMemList[whichSpace]) {     
	/* Free memory data structure. */
	tmp = ((dataMemBlockStruct *) self->_eMemList[whichSpace])->next; 
	freeDataMemBlock(self->_eMemList[whichSpace]);
	self->_eMemList[whichSpace] = (void *) tmp;
    }
}

static void freeUGs(MKOrchestra *self)
/* Free all MKSynthData and MKUnitGenerators. */
{
    char wasTimed = [self isTimed];
    self->deviceStatus = MK_devClosed;
    [self setTimed: NO];          /* Finalization may generate some
	reset code and we don't want it
	to go out timed. */
    [synthInstruments makeObjectsPerformSelector: @selector(_disconnectOnOrch: ) withObject: self];
    /* Causes each synthIns to end any residual running voices and deallocate
	its own idle voices so that popReso gets all. */
    popReso(self);                    /* Doesn't reset looper. */
    /* Note that patchpoints/synthdata is NOT automatically dealloc'ed! FIXME */
    
    if ([self->unitGeneratorStack count]) { /*sb: was lastObject */ 
	id obj;
	int i,count = [self->unitGeneratorStack count];
	for (i=0; i<count; i++)
            [[self->unitGeneratorStack objectAtIndex: i] mkdealloc]; /*sb: changed to mkdealloc */
	
        while ([self->unitGeneratorStack count] > 0) {
	    obj = [self->unitGeneratorStack lastObject];
	    [obj _free]; /* Added by DAJ.  Nov/21/95 */
            [self->unitGeneratorStack removeLastObject];/*sb: careful this releases last object... 
		*maybe ok cos I don't release as part of _free now*/
	}
    }
    if (self->inputSoundfile) { /* READ DATA */
	[self->readDataUG mkdealloc]; /*sb: changed to mkdealloc */
	[self->readDataUG _free];
	[self->readDataUG release]; /* sb */
    }
    [self->_sysUG mkdealloc]; /*sb: changed to mkdealloc */
    [self->_sysUG _free];
    [self->_sysUG release];/* sb */
    self->_sysUG = nil;
    _MKProtectSynthElement(self->xZero,NO);
    [self->xZero mkdealloc]; /*sb: changed to mkdealloc */
    _MKProtectSynthElement(self->yZero,NO);
    [self->yZero mkdealloc]; /*sb: changed to mkdealloc */
    _MKProtectSynthElement(self->xSink,NO);
    [self->xSink mkdealloc]; /*sb: changed to mkdealloc */
    _MKProtectSynthElement(self->ySink,NO);
    [self->ySink mkdealloc]; /*sb: changed to mkdealloc */
    _MKProtectSynthElement(self->xModulusSink,NO);
    [self->xModulusSink mkdealloc]; /*sb: changed to mkdealloc */
    _MKProtectSynthElement(self->yModulusSink,NO);
    [self->yModulusSink mkdealloc]; /*sb: changed to mkdealloc */
    _MKProtectSynthElement(self->sineROM,NO);
    [self->sineROM mkdealloc]; /*sb: changed to mkdealloc */
    _MKProtectSynthElement(self->muLawROM,NO);
    if (self->inputSoundfile) { /* READ DATA */
	_MKProtectSynthElement(self->xReadData,NO);
	_MKProtectSynthElement(self->yReadData,NO);
	[self->xReadData mkdealloc]; /*sb: changed to mkdealloc */
	[self->yReadData mkdealloc]; /*sb: changed to mkdealloc */
    }
    [self->muLawROM mkdealloc]; /*sb: changed to mkdealloc */
    _MKCollectSharedDataGarbage(self,self->sharedGarbage);
    /*sb: the following were set to nil rather than released. I think releasing is a much better idea!
    self->muLawROM = self->sineROM = self->xZero = self->yZero = 
    self->xSink = self->ySink = self->xModulusSink = 
    self->yModulusSink = nil;
    */
    [self->muLawROM release];
    [self->sineROM  release];
    [self->xZero release];
    [self->yZero release];
    [self->xSink release];
    [self->ySink release];
    [self->xModulusSink release];
    [self->yModulusSink release];
    self->muLawROM = self->sineROM = self->xZero = self->yZero =
    self->xSink = self->ySink = self->xModulusSink =
    self->yModulusSink = nil;

    switch (self->_overlaidEMem) {
	case MK_orchEmemNonOverlaid: 
	    freeEMem(self,X_EMEM);
	    freeEMem(self,Y_EMEM);
	    freeEMem(self,P_EMEM);
	    break;
	case MK_orchEmemOverlaidPX: 
	    freeEMem(self,O_EMEM);
	    freeEMem(self,Y_EMEM);
	    break;
	case MK_orchEmemOverlaidXYP: 
	    freeEMem(self,O_EMEM);
	    break;
    }
    self->_sharedSet = _MKFreeSharedSet(self->_sharedSet, &self->sharedGarbage);
    [self->unitGeneratorStack release];
    self->unitGeneratorStack = nil;//sb: added
    if (self->_xPatch != NULL) {
	free(self->_xPatch);
	self->_xPatch = NULL;
    }
    if (self->_yPatch != NULL) {
	free(self->_yPatch);
	self->_yPatch = NULL;
    }
    self->_xPatchAllocBits = 0;
    self->_yPatchAllocBits = 0;
    [self setTimed: wasTimed];
}

#if 0
/* Comment this in if needed */
void _MKSetDefaultOrchloopClass(id anOrchSysUGClass)
{
    defaultOrchloopClass = anOrchSysUGClass;
}

void _MKSetOrchloopClass(MKOrchestra *self,id anOrchSysUGClass)
{
    self->_orchloopClass = anOrchSysUGClass;
}    
#endif

/* Set NOOPS to 3 to insert 3 noops between each unit generator. This is 
useful for DSP debugging. */
#define NOOPS 0

#ifdef DEBUG
static int noops = NOOPS;
#else 
static int noops = 0;
#endif

int _MKOrchestraGetNoops(void)
{
    return noops;
}

void _MKOrchestraSetNoops(int nNoops)
{
    noops = nNoops;
}

#define NOOP 0x0      /* Used to separate unit generators. */

static void insertNoops(self,where)
MKOrchestra *self;
int where;
/* Inserts NOOPS noops between each unit generator. This is 
useful for DSP debugging. */
{
    if (!noops)
	return;
    DSPSetCurrentDSP(self->orchIndex);
    if (_MK_ORCHTRACE(self,MK_TRACEDSP))
	_MKOrchTrace(self,MK_TRACEDSP,@"inserting %d NOOPs at %d",noops,where);
    DSPMKMemoryFillSkipTimed(_MKCurSample(self),NOOP,DSP_MS_P,where,1,noops);
}

/* Loads the orchestra loop (a.k.a. _OrchloopbeginUG, 
a.k.a. orchloopbegin) 
Also initializes memory data structures, etc. */
static id loadOrchLoop(MKOrchestra *self)
{
#define INITIAL_STACK_SIZE 128 /* A guess at how many UGs and PPs we'll have */
    int i;
    dataMemBlockStruct *xAvailDmb,*yAvailDmb,*pAvailDmb;
    int sysver;
    MKOrchMemStruct reloc;
    dataMemBlockStruct *peLoop,*availDataMem,*endMarker;
    self->previousTime = -1;
    self->_previousTimeStamp.high24 = 0;
    self->_previousTimeStamp.low24 = 0;
    if (!self->_orchloopClass)
	self->_orchloopClass = defaultOrchloopClass;
    self->deviceStatus = MK_devOpen;
    self->_sharedSet = _MKNewSharedSet(&self->sharedGarbage);
    self->unitGeneratorStack = [[NSMutableArray alloc] initWithCapacity: INITIAL_STACK_SIZE];
    self->computeTime = 0;
    self->isLoopOffChip = 0;  /* Added by DAJ. 11/21/95 */
    switch (self->_overlaidEMem) {
	case MK_orchEmemOverlaidXYP: 
	    _MK_MALLOC(peLoop, dataMemBlockStruct, 1);
	    _MK_MALLOC(availDataMem,dataMemBlockStruct,1);
	    self->_availDataMem[O_EMEM] = (void *)availDataMem;
	    /* baseAddr = MINXDATA */
	    availDataMem->baseAddr = (self->_bottomOfExternalMemory[O_EMEM] + 
				      LOOPERSIZE);
	    /* size = MAXXDATA - MINXDATA + 1 */
	    availDataMem->size = 
		((self->_topOfExternalMemory[O_EMEM] - 
		  self->_numXArgs - self->_numYArgs) - 
		 availDataMem->baseAddr + 1);
	    availDataMem->isAllocated = NO;
	    /* baseAddr = MINPELOOP */
	    peLoop->baseAddr = self->_bottomOfExternalMemory[O_EMEM];
	    peLoop->size = LOOPERSIZE;
	    peLoop->isAllocated = YES;
	    peLoop->next = availDataMem;
	    availDataMem->prev = peLoop;
	    peLoop->prev = NULL;
	    availDataMem->next = NULL;
	    self->_eMemList[O_EMEM] = (void *) peLoop;
	    
	    self->_xArg = (self->_topOfExternalMemory[O_EMEM] - 
			   self->_numXArgs - self->_numYArgs + 1);
	    self->_yArg = self->_xArg + self->_numXArgs;
	    break;
	case MK_orchEmemOverlaidPX: 
	    /* First do P/X overlaid portion */
	    _MK_MALLOC(peLoop, dataMemBlockStruct, 1);
	    _MK_MALLOC(availDataMem,dataMemBlockStruct,1);
	    self->_availDataMem[O_EMEM] = (void *) availDataMem;
	    /* baseAddr = MINXDATA */
	    availDataMem->baseAddr = (self->_bottomOfExternalMemory[O_EMEM] + 
				      LOOPERSIZE);
	    /* size = MAXXDATA - MINXDATA + 1 */
	    availDataMem->size = 
		((self->_topOfExternalMemory[O_EMEM] - self->_numXArgs) - 
		 availDataMem->baseAddr + 1);
	    availDataMem->isAllocated = NO;
	    /* baseAddr = MINPELOOP */
	    peLoop->baseAddr = self->_bottomOfExternalMemory[O_EMEM];
	    peLoop->size = LOOPERSIZE;
	    peLoop->isAllocated = YES;
	    peLoop->next = availDataMem;
	    availDataMem->prev = peLoop;
	    peLoop->prev = NULL;
	    availDataMem->next = NULL;
	    self->_eMemList[O_EMEM] = (void *) peLoop;
	    self->_xArg = (self->_topOfExternalMemory[O_EMEM] - 
			   self->_numXArgs + 1);
	    /* Now do Y non-overlaid portion */
	    _MK_MALLOC(availDataMem, dataMemBlockStruct, 1);
	    _MK_MALLOC(endMarker, dataMemBlockStruct, 1);
	    self->_availDataMem[Y_EMEM] = (void *) availDataMem;
	    availDataMem->baseAddr = self->_bottomOfExternalMemory[Y_EMEM];
	    endMarker->size = 0;
	    self->_eMemList[Y_EMEM] = (void *) endMarker;
	    availDataMem->isAllocated = NO;
	    endMarker->baseAddr = self->_bottomOfExternalMemory[Y_EMEM];
	    endMarker->isAllocated = YES;
	    endMarker->next = availDataMem;
	    availDataMem->prev = endMarker;
	    endMarker->prev = NULL;
	    availDataMem->next = NULL;
	    yAvailDmb = self->_availDataMem[Y_EMEM];
	    yAvailDmb->size = 
		(self->_topOfExternalMemory[Y_EMEM] -
		 self->_numYArgs - yAvailDmb->baseAddr + 1);
	    self->_yArg = (yAvailDmb->size + yAvailDmb->baseAddr);
	    break;
	case MK_orchEmemNonOverlaid: 
	    for (i=0; i<3; i++) {
		_MK_MALLOC(availDataMem, dataMemBlockStruct, 1);
		_MK_MALLOC(endMarker, dataMemBlockStruct, 1);
		self->_availDataMem[i] = (void *) availDataMem;
		if (i == P_EMEM) {
		    availDataMem->baseAddr = (self->_bottomOfExternalMemory[i] + 
					      LOOPERSIZE);
		    endMarker->size = LOOPERSIZE;
		}
		else {
		    availDataMem->baseAddr = self->_bottomOfExternalMemory[i];
		    endMarker->size = 0;
		}
		self->_eMemList[i] = (void *) endMarker;
		availDataMem->isAllocated = NO;
		endMarker->baseAddr = self->_bottomOfExternalMemory[i];
		endMarker->isAllocated = YES;
		endMarker->next = availDataMem;
		availDataMem->prev = endMarker;
		endMarker->prev = NULL;
		availDataMem->next = NULL;
	    }
	    xAvailDmb = self->_availDataMem[X_EMEM];
	    xAvailDmb->size = (self->_topOfExternalMemory[X_EMEM] -
			       self->_numXArgs - xAvailDmb->baseAddr + 1);
	    yAvailDmb = self->_availDataMem[Y_EMEM];
	    yAvailDmb->size = (self->_topOfExternalMemory[Y_EMEM] -
			       self->_numYArgs - yAvailDmb->baseAddr + 1);
	    pAvailDmb = self->_availDataMem[P_EMEM];
	    pAvailDmb->size = (self->_topOfExternalMemory[P_EMEM] -
			       pAvailDmb->baseAddr + 1);
	    self->_xArg = xAvailDmb->size + xAvailDmb->baseAddr;
	    self->_yArg = yAvailDmb->size + yAvailDmb->baseAddr;
    }
    self->_maxXArg = self->_xArg + self->_numXArgs - 1;
    self->_maxYArg = self->_yArg + self->_numYArgs - 1;
    self->_piLoop = ORCHLOOPLOC;
    self->_lArg = MINLARG;  
    self->_looper = SHORTJUMP | MINPILOOP; /* This is the start of _sysUG. */
    [self->_orchloopClass _setXArgsAddr: self->_xArg y: self->_yArg l: 
		     self->_lArg looper: self->_looper]; 
    /* Set argument start addresses to point to correct locations.
	Also set ug to loop */
    _MK_MALLOC(self->_xPatch,DSPAddress,self->onChipPatchPoints);
    _MK_MALLOC(self->_yPatch,DSPAddress,self->onChipPatchPoints);
    self->_xPatch[0] = MINXPATCH;
    self->_yPatch[0] = MINYPATCH;
    for (i = 1; i < self->onChipPatchPoints; i++) {
        self->_xPatch[i] = self->_xPatch[i - 1] + DSPMK_NTICK;
        self->_yPatch[i] = self->_yPatch[i - 1] + DSPMK_NTICK;
    }
    /* Allocate sink first in case we ever decide to have just 1 patchpoint 
	on chip. (Modulus sink is always off-chip.)
	*/
    self->xSink = [self allocPatchpoint: MK_xPatch];
    self->ySink = [self allocPatchpoint: MK_yPatch];
    self->xZero = [self allocPatchpoint: MK_xPatch];
    [self->xZero clear];
    self->yZero = [self allocPatchpoint: MK_yPatch];
    [self->yZero clear];
    self->sineROM = [MKSynthData _newInOrch: self index: self->orchIndex 
				     length: DSP_SINE_LENGTH segment: SINTABLESPACE 
				   baseAddr: DSP_SINE_TABLE isModulus: NO];
    self->muLawROM = [MKSynthData _newInOrch: self index: self->orchIndex 
				      length: DSP_MULAW_LENGTH segment: MULAWTABLESPACE 
				    baseAddr: DSP_MULAW_TABLE isModulus: NO];
    [self->muLawROM setReadOnly: YES];
    [self->sineROM setReadOnly: YES];
    [self->xZero setReadOnly: YES];
    [self->yZero setReadOnly: YES];
    _MKProtectSynthElement(self->xZero,YES);
    _MKProtectSynthElement(self->yZero,YES);
    _MKProtectSynthElement(self->ySink,YES);
    _MKProtectSynthElement(self->xSink,YES);
    _MKProtectSynthElement(self->yModulusSink,YES);
    _MKProtectSynthElement(self->xModulusSink,YES);
    _MKProtectSynthElement(self->sineROM,YES);
    _MKProtectSynthElement(self->muLawROM,YES);
    if (self->inputSoundfile) { /* READ DATA */
        _MKProtectSynthElement(self->xReadData,YES);
        _MKProtectSynthElement(self->yReadData,YES);
    }
#if READDATA 
/* Need something here to selectively create either the stereo or the
mono Read data MKUnitGenerator. Or maybe it'll just be one MKUnitGenerator.
*/
if (((resoAlloc(self,self->_orchSysUGClass,&reloc) != OK) || 
     self->isLoopOffChip || 
     (!(self->_sysUG = 
	[self->_orchSysUGClass _newInOrch: self index: self->orchIndex
				    reloc: &reloc looper: self->_looper]))) ||
    ((inputSoundfile != nil) &&  /* READ DATA */
    ((resoAlloc(self,readDataUG,&reloc) != OK) ||
     (!(readDataUG = 
	[SysReadDataUG _newInOrch: self index: self->orchIndex
			    reloc: &reloc looper: self->_looper]))))) { /* Should never happen */
	    if (self->_sysUG) {
		[self->_sysUG mkdealloc];  /*sb: changed to mkdealloc */
		[self->_sysUG _free];
		[self->_sysUG release];
		self->_sysUG = nil;
	    }
		loadOrchLoopAbort: 
	    freeUGs(self);
	    if (self->useDSP)
	    DSPClose();
	    self->deviceStatus = MK_devClosed;
	    return nil;
}
#else
if ((resoAlloc(self,self->_orchloopClass,&reloc) != OK) || 
    self->isLoopOffChip || 
    (!(self->_sysUG = 
       [self->_orchloopClass _newInOrch: self index: self->orchIndex
				  reloc: &reloc looper: self->_looper]))) { /* Should never happen */
		      loadOrchLoopAbort: 
	   freeUGs(self);
	   if (self->useDSP)
	   DSPClose();
	   self->deviceStatus = MK_devClosed;
	   return nil;
}
#endif
    insertNoops(self,reloc.pLoop - noops);
    if (DSPCheckVersion(&sysver,&self->release)) 
    goto loadOrchLoopAbort;
    self->version = sysver; /* Bad RISC cast? */
    if (self->version != 'A') {
	MKErrorCode(MK_dspMonitorVersionError, NSStringFromClass([self class]));
	goto loadOrchLoopAbort;
    }
    DSPMKStartReaders();
    return self;
}

void _MKOrchAddSynthIns(id anIns)
/* The MKOrchestra keeps track of all the SynthInstruments so it can
clean up at the end of time. */
{
    if (!synthInstruments)
	synthInstruments = [[NSMutableArray alloc] init];
    [synthInstruments addObject: anIns];
}

void _MKOrchRemoveSynthIns(id anIns)
/* The MKOrchestra keeps track of all the SynthInstruments so it can
clean up at the end of time. */
{
    [synthInstruments removeObject: anIns];
}

- (MKDeviceStatus) deviceStatus
    /* Returns MKDeviceStatus of receiver. */
{
    return deviceStatus;
}

#define EQU(_x,_y) ((((_x)-(_y))>0)?(((_x)-(_y))<.0001): (((_y)-(_x))<.0001))

/* Contains the methods -open, -stop, -run, -close and -abort: */ 
#import "orchControl.m"

BOOL _MKOrchLateDeltaTMode(MKOrchestra *self)
{
    return (self->isTimed == MK_SOFTTIMED);
}

- setTimed: (MKOrchestraTiming) isOrchTimed
    /* Controls (for all orchs) whether DSP commands are sent timed or untimed. 
    The default is timed unless the Conductor is not loaded. 
    It is permitted to change
    from timed to untimed during a performance. (But this won't work in 0.9.) */
{
    if (deviceStatus != MK_devClosed && (isTimed != isOrchTimed))
	DSPSetTimedZeroNoFlush(0);
    isTimed = isOrchTimed;
    return self;
}

#if 0
-step
    /* Execute current tick, increment tick counter and stop. */
{
    [_sysUG step];
}
#endif

-copy
    /* We override this method. Copying is not supported by the MKOrchestra class.
    */
{
    [self doesNotRecognizeSelector: _cmd];  return nil;
}

- copyWithZone: (NSZone *) zone
    /* We override this method. Copying is not supported by the MKOrchestra class.
    */
{
    [self doesNotRecognizeSelector: _cmd];  return nil;
}

/* Frees a particular orchestra instance. This involves freeing all
unit generators in its unit generator unitGeneratorStack, clearing all
synthpatch allocation lists and releasing the DSP. It is an error
to free an orchestra with non-idle synthPatches or allocated unit
generators which are not members of a synthPatch. An attempt to
do so generates an error. 
*/
/* sb: was -free before OS conversion. probably ok */
- (void) dealloc 
{
    int i;
    
    [self abort];
    [dspNumToOrch removeObjectForKey: [NSNumber numberWithInt: orchIndex]];
    /* Now fill in the gap in orchs[] */
    for (i=0; orchs[i] != self; i++)
	;
    for (; orchs[i]; i++) /* Guaranteed to stop because we keep one nil at end */
	orchs[i] = orchs[i+1];
    [super dealloc];
}

- useDSP: (BOOL) useIt
    /* Controls whether or not the output actually goes to the DSP. Has no effect
    if the MKOrchestra is not closed. The default is YES. 
    This method should not be used in release 0.9. */
{
    if (deviceStatus != MK_devClosed)
	return nil;
    useDSP = useIt;
    return self;
}

-(BOOL) isDSPUsed
    /* If the receiver is not closed, returns YES if the DSP is used.
    If the receiver is closed, returns YES if the receiver is set to use
    the DSP when it is opened. */
{
    return useDSP;
}

FILE *_MKGetOrchSimulator(MKOrchestra *orch)
/* Returns Simulator file pointer, if any.
Assumes orchIndex is a valid orchestra. If this is ever made
non-private, should check for valid orchIndex.  */
{
    return orch->_simFP;
}

static void _traceMsg(FILE *simFP, int typeOfInfo, NSString *fmt, char *ap)
/* See trace: below */
{
    if (MKIsTraced(typeOfInfo)) {
        NSLogv([fmt stringByAppendingString: @"\n"], ap);
    }
    if (simFP) {
        vfprintf(simFP, [[NSString stringWithFormat: @"; %@\n", fmt] UTF8String], ap);
    }
}

static void _traceNSStringMsg(FILE *simFP, int typeOfInfo, NSString *msg)
/* See trace: below */
{
    if (MKIsTraced(typeOfInfo)) {
        NSLog(@"%@\n", msg);
    }
    if (simFP) {
        fprintf(simFP, "%s", [msg UTF8String]);
    }
}

- trace: (int) typeOfInfo msg: (NSString *) fmt, ...;
    /* Arguments are like printf. Writes text, as a comment, to the
    simulator file, if any. Text may not contain new-lines. 
    If the typeOfInfo trace is set, prints info to stderr as well. */
{
    va_list ap;
    va_start(ap,fmt); 
    _traceMsg(_simFP, typeOfInfo, fmt, ap);
    va_end(ap);
    return self;
}

void _MKOrchTrace(MKOrchestra *orch,int typeOfInfo, NSString *fmt, ...)
/* See trace: above */
{
    va_list ap;
    va_start(ap,fmt); 
    _traceNSStringMsg(orch->_simFP,
                      typeOfInfo,
                      [[[NSString alloc] initWithFormat: fmt arguments: ap] autorelease]);
    va_end(ap);
}

// TODO Should be a method
DSPFix48 *_MKCurSample(MKOrchestra *self)
/* Returns time turned into sample time for use to DSP routines. 
DeltaT is included in the result. */
{
    /* Need to differentiate between truly untimed and 'on next tick' 
    untimed. */
    switch (self->deviceStatus) {
	case MK_devClosed:  /* A bug, probably but, play along. */
	case MK_devOpen:    /* Can only do truly untimed pokes when open. */ 
	    return DSPMK_UNTIMED;
	case MK_devStopped: /* It's ok to do truly untimed pokes when stopped
	    because we're not running the orch loop */
	    if (!self->isTimed)
		return DSPMK_UNTIMED;
	default: 
	    break;
    }
    if (self->isTimed) {
        double curTime = MKGetDeltaTTime();
        if (self->previousTime != curTime) {
            self->previousTime = curTime;
            doubleIntToFix48UseArg((curTime + self->timeOffset + 
                                    self->localDeltaT) * 
                                   self->samplingRate + 0.5, /* rounding essential */
                                   &(self->_previousTimeStamp));
        }
    }
    else {
        self->_previousTimeStamp.high24 = 0;
        self->_previousTimeStamp.low24 = 0;
    }
    return &(self->_previousTimeStamp);
}

- (NSString *) segmentName: (int) whichSegment
    /* Returns name of the specified OrchMemSegment. */
{
    return ((whichSegment < 0 || whichSegment >= (int) MK_numOrchMemSegments)) ?
    [NSString stringWithString: @"invalid"] : (NSString *) (orchMemSegmentNames[whichSegment]);
}

/* Instance methods for UnitGenerator's resource allocation. ------------  */


static void putLeaper(MKOrchestra *self, int leapTo)
/* Adds leaper to specified place. A leaper jumps the orchestra loop
off chip. */
{
    int leaper[LEAPERSIZE]; 
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	if (!self->isLoopOffChip)
	    _MKOrchTrace(self,MK_TRACEORCHALLOC,@"Moving loop off chip.");
    leaper[0] = NOOP;
    leaper[1] = JUMP;
    leaper[2] = leapTo;
    DSPSetCurrentDSP(self->orchIndex);
    DSPMKSendArraySkipTimed(_MKCurSample(self) ,leaper,DSP_MS_P,self->_piLoop,
                            1,LEAPERSIZE);
    self->isLoopOffChip = YES;
}

-(double) headroom
{
    return _headroom - (HEADROOMFUDGE+[self systemOverhead]);
}

-beginAtomicSection
    /* Marks beginning of a section of DSP commands which are to be sent as 
    a unit. */
{
    DSPSetCurrentDSP(orchIndex);
    if (_parenCount == -1)
	return self;
    if (_parenCount++ == 0) {
        if (_MK_ORCHTRACE(self,MK_TRACEDSP))
	    _MKOrchTrace(self,MK_TRACEDSP,@"<<< Begin orchestra atomic unit ");
        DSPMKEnableAtomicTimed(_MKCurSample(self));
    }
    return self;
}

-endAtomicSection
    /* Marks end of a section of DSP commands which are to be sent as 
    a unit. */
{
    DSPSetCurrentDSP(orchIndex);
    if (_parenCount == -1)
	return self;
    if (--_parenCount == 0) {
        if (_MK_ORCHTRACE(self,MK_TRACEDSP))
	    _MKOrchTrace(self,MK_TRACEDSP,@"end orchestra atomic unit.>>> ");
        DSPMKDisableAtomicTimed(_MKCurSample(self));
    }
    else if (_parenCount < 0) 
	_parenCount = 0;
    return self;
}

extern BOOL _MKAdjustTimeIfNotBehind(void);

- (void) synchTime: (NSTimer *) timer
{
    DSPFix48 dspSampleTime;
    double dspTime,hostTime;
    if (![_MKClassConductor() inPerformance])
	return;
    _MKLock(); // TODO can we replace this with [MKConductor lockPerformance]; ?
    if ((self->_parenCount) /* Don't mess with parens */
        || (!_MKAdjustTimeIfNotBehind())) {
	_MKUnlock(); // TODO can we replace this with [MKConductor unlockPerformance]; ?
	return;
    }
    DSPSetCurrentDSP(self->orchIndex); /* Added March 7, 1993--DAJ */
    DSPMKReadTime(&dspSampleTime);
    dspTime = DSPFix48ToDouble(&dspSampleTime)/self->samplingRate;
    hostTime = MKGetTime();
    /* one pole filter */
    synchTimeRatio = (synchTimeRatio * .8 + dspTime/hostTime * .2);
    timeOffset = (synchTimeRatio - 1) * hostTime;
    _MKUnlock();  // TODO can we replace this with [MKConductor unlockPerformance]; ?
}

static void adjustOrchTE(MKOrchestra *self,BOOL yesOrNo,BOOL reset) {
    if (reset) {
        self->timeOffset = 0;
        self->synchTimeRatio = 1.0;
    }
    if (!self->hostSoundOut || ![MKConductor isClocked])
	yesOrNo = NO;
    if (yesOrNo && !self->timedEntry && self->synchToConductor) {
	
        self->timedEntry = [[NSTimer timerWithTimeInterval: 5.0
                                                    target: self
                                                  selector: (SEL) @selector(synchTime: )
                                                  userInfo: (void *) self /*sb: ok*/
                                                   repeats: YES] retain];
        [[NSRunLoop currentRunLoop] addTimer: self->timedEntry
                                     forMode: _MK_DPSPRIORITY];
    }
    else if ((!yesOrNo || !self->synchToConductor) && self->timedEntry) {
        [self->timedEntry invalidate];
        [self->timedEntry release];;
        self->timedEntry = NULL;
    }
}

-setSynchToConductor: (BOOL) yesOrNo
{
    synchToConductor = yesOrNo;
    if (deviceStatus == MK_devRunning)
	[self _adjustOrchTE: yesOrNo reset: YES];
    return self;
}

-(double) localDeltaT
{
    return localDeltaT;
}

-setLocalDeltaT: (double) value
{
    localDeltaT = value;
    return self;
}

static BOOL compactResourceStack(MKOrchestra *self); /* Forward ref */

- (void) setHeadroom: (double) headroom
    /* Sets DSP computational headroom. (This only has an effect when you are
    generating sound in real time.) This adjusts the tradeoff between
    maximizing the processing power of the MKOrchestra on the one hand and
    running a risk of falling out of real time on the other.
    A value of 0 runs a large risk of falling out of real time.
    A value of .5 runs a small risk of falling out of real time but 
    allows for a substantially less powerful MKOrchestra. 
    Since the MKUnitGenerator computation time estimates are conservative,
    negative headroom values may sometimes work. The default is .1. 

    The effective sampling period is computed as 

    sampling period * (1 - headroom).

    */
{
    /* We're overly conservative in our UG timings so we fudge here. */
    if (headroom > .99)
	headroom = .99;
    if ((deviceStatus != MK_devClosed) && 
    	(headroom + (HEADROOMFUDGE+[self systemOverhead]) > _headroom)) {
	popResoAndSetLooper(self);
	compactResourceStack(self);
    }	
    _previousLosingTemplate = nil;
    _headroom = headroom + HEADROOMFUDGE+[self systemOverhead];
    _effectiveSamplePeriod = (1.0/samplingRate) * (1 - _headroom);
    [self _compensateForDSPClockRate];
}     

/*  Returns the index of the DSP on which this instance is running. */
- (unsigned short) orchestraIndex
{
    return orchIndex;
}

/* Returns the compute time currently used by the orchestra system in seconds per sample. */
- (double) computeTime
{
    return computeTime;
}

id _MKFreeMem(MKOrchestra *self,MKOrchAddrStruct *mem)
/* Frees MK_yData, MK_xData, MK_pSubr,
MK_xSig or MK_ySig memory. */
{
    switch (mem->memSegment) {
	case MK_yData: 
	case MK_xData: 
	case MK_pSubr: 
	    giveDataMem(self,mem->memSegment,mem->address);
	    break;
	case MK_xPatch: 
	case MK_yPatch: 
	    givePatchMem(self,mem->memSegment,mem->address);
	    break;
	default: /* To make compiler happy */
	    break;
    }
    return self;
}

/* Instance methods for MKSynthPatch alloc/dealloc.------------------------  */

-allocSynthPatch: aSynthPatchClass
  /* Same as allocSynthPatch: patchTemplate: but uses default template. 
    The default
    template is obtained by sending [aSynthPatchClass defaultPatchTemplate].*/
{
    return [self allocSynthPatch: aSynthPatchClass patchTemplate: 
	[aSynthPatchClass defaultPatchTemplate]];
}

#define CHECKADJUSTTIME() if (self->isTimed == MK_SOFTTIMED) _MKAdjustTimeIfNecessary()

-allocSynthPatch: aSynthPatchClass patchTemplate: p
    /* Reuse a MKSynthPatch if possible. Otherwise, build a new one, if 
    possible. If successful, return the new MKSynthPatch. Otherwise,
    return nil. Note that the ordered collection of objects in the 
    MKSynthPatch is in the same order as specified in the template. */
{
    id rtnVal;
    if ((!p) || (deviceStatus == MK_devClosed))
	return nil;
    CHECKADJUSTTIME();
    if ((_previousLosingTemplate == p) || /* If we just lost, don't even try */
        (!(rtnVal = _MKAllocSynthPatch(p,aSynthPatchClass,self,orchIndex)))){
        if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	    _MKOrchTrace(self,MK_TRACEORCHALLOC,
			 @"allocSynthPatch can't allocate %@",
			 NSStringFromClass([aSynthPatchClass class]));
        _previousLosingTemplate = p;
        return nil;
    }
return rtnVal;
}

/* Instance methods for Unit generator alloc/dealloc. ------------------- */

-allocUnitGenerator:  factObj 
    /* Allocate unit generator of the specified class. */
{
    id rtnVal;
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocUnitGenerator looking for a %@.",NSStringFromClass([factObj class]));
    rtnVal = allocUG(self,factObj,nil,nil);
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	if (rtnVal)
	    _MKOrchTrace(self,MK_TRACEORCHALLOC,
			 @"allocUnitGenerator returns %@_%p",NSStringFromClass([rtnVal class]),rtnVal);
    return rtnVal;
}

-allocUnitGenerator:  factObj before: aUnitGeneratorInstance
    /* Allocate unit generator of the specified class before the specified 
    instance. */
{
    id rtnVal;
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocUnitGenerator looking for a %@ before %@_%p",
		     NSStringFromClass([factObj class]),
		     NSStringFromClass([aUnitGeneratorInstance class]),
		     aUnitGeneratorInstance);
    rtnVal = allocUG(self,factObj,aUnitGeneratorInstance,nil);
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocUnitGenerator returns %@_%p",
		     NSStringFromClass([rtnVal class]), rtnVal);
    return rtnVal;
}

-allocUnitGenerator:  factObj after: aUnitGeneratorInstance
    /* Allocate unit generator of the specified class
    after the specified instance. */
{
    id rtnVal;
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocUnitGenerator looking for a %@ after %@_%p",
		     NSStringFromClass([factObj class]),
		     NSStringFromClass([aUnitGeneratorInstance class]),
		     aUnitGeneratorInstance);
    rtnVal = allocUG(self,factObj,nil,aUnitGeneratorInstance);
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocUnitGenerator returns %@_%p",
		     NSStringFromClass([rtnVal class]),
		     rtnVal);
    return rtnVal;
}

-allocUnitGenerator: factObj 
	    between: aUnitGeneratorInstance : anotherUnitGeneratorInstance
    /* Allocate unit generator of the specified class between the 
    specified instances. */
{
    id rtnVal;
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocUnitGenerator looking for a %@ after %@_%p and before %@_%p",
		     NSStringFromClass([factObj class]),
		     NSStringFromClass([aUnitGeneratorInstance class]),
		     aUnitGeneratorInstance,
		     NSStringFromClass([anotherUnitGeneratorInstance class]),
		     anotherUnitGeneratorInstance);
    rtnVal = allocUG(self,factObj,anotherUnitGeneratorInstance,
                     aUnitGeneratorInstance);
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	if (rtnVal)
	    _MKOrchTrace(self,MK_TRACEORCHALLOC,
			 @"allocUnitGenerator returns %@_%p",
			 NSStringFromClass([rtnVal class]),rtnVal);
    return rtnVal;
}

/* Instance methods for memory alloc. ---------------------- */

static DSPAddress allocMem(MKOrchestra *self,MKOrchMemSegment segment,unsigned size,
			   BOOL isModulus);

-(NSString *)lastAllocationFailureString
{
    return lastAllocFailStr;
}

-allocSynthData: (MKOrchMemSegment) segment length: (unsigned) size
    /* Returns a new MKSynthData object with the specified length or nil if 
    there's no more memory or if size is 0. This method can be used
    to allocate patch points but the size must be DSPMK_NTICK. */
{
    DSPAddress baseAddr;
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocSynthData: looking in segment %@ for size %d.",
		     orchMemSegmentNames[segment],size);
    baseAddr = allocMem(self,segment,size,NO);
    if (baseAddr == BADADDR) {
	lastAllocFailStr = 
	@"Allocation failure: Patchpoints must be 16 samples long.";
	if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	    _MKOrchTrace(self,MK_TRACEORCHALLOC,lastAllocFailStr);
        return nil;
    }
    else if (baseAddr == NOMEMORY) {
	lastAllocFailStr = 
	@"Allocation failure: No more offchip data memory.";
        if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	    _MKOrchTrace(self,MK_TRACEORCHALLOC,
			 lastAllocFailStr);
        return nil;
    }
    else if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC)) 
	_MKOrchTrace(self,MK_TRACEORCHALLOC,
		     @"allocSynthData returns %@ %d of length %d.",
		     orchMemSegmentNames[segment],baseAddr,size);
    return [MKSynthData _newInOrch: self index: orchIndex
			    length: size segment: segment baseAddr: baseAddr isModulus: NO];
}

-allocPatchpoint: (MKOrchMemSegment) segment 
    /* returns a new patch point object. Segment must be xPatch or yPatch.
    Returns nil if an illegal segment is requested. 
    */
{
    switch (segment) {
	case MK_xPatch: 
	case MK_yPatch: 
	    break;
	case MK_xData: 
	    segment = MK_xPatch;
	    break;
	case MK_yData: 
	    segment = MK_yPatch;
	    break;
	default: 
	    return nil;
    }
    return [self allocSynthData: segment length: DSPMK_NTICK];
}

/* Version checking. -------------------------------------------------- */


-getMonitorVersion: (char *) versionP release: (int *) releaseP
    /* version is a pointer to a single character.  No NULL is appended 
    * Returns nil if not open.
    */
{
    if (deviceStatus == MK_devClosed)
	return nil;
    *versionP = version;
    *releaseP = release;
    return self;
}

/* Garbage collection. -------------------------------------------------- */

static void adjustResources(self,time,reloc)
register MKOrchestra *self;
double time;
MKOrchMemStruct *reloc;
/* Pops off unitGeneratorStack the UG with given time and relocation. */ 
{
    self->computeTime -= time;
    if (self->isLoopOffChip) 
	self->isLoopOffChip = givePELoop(self,reloc->pLoop - noops);
    else self->_piLoop = reloc->pLoop - noops;
    self->_xArg = reloc->xArg;
    self->_lArg = reloc->lArg;
    self->_yArg = reloc->yArg;
    giveDataMem(self,MK_yData,reloc->yData);
    giveDataMem(self,MK_xData,reloc->xData);
    giveDataMem(self,MK_pSubr,reloc->pSubr);
}

static double getUGComputeTime(MKOrchestra *self,int pReloc,MKLeafUGStruct *p)
{
    return (((p->reserved1 != MK_2COMPUTETIMES)  /* version 1.0 unit gen */
//             || (pReloc < MINPELOOP)) ?          /* it's on-chip */
    || (pReloc <= MAXPILOOP)) ?          /* it's on-chip */
    p->computeTime
    : p->offChipComputeTime);
}

static void abortAlloc(self,factObj,reloc)
register MKOrchestra *self;
id factObj;
MKOrchMemStruct *reloc;
/* Give up */
{
    adjustResources(self,getUGComputeTime(self,reloc->pLoop,
					  [factObj classInfo]),
                    reloc);
    setLooper(self);
}

static void adjustUGInSP(sp,aUG)
id sp,aUG;
/* This is what we do when freeing a MKUnitGenerator that's in a 
MKSynthPatch */
{
    [sp _remove: aUG];                     /* Put a hole in the sp */
    _MKDeallocSynthElement(aUG,NO);
    /* Dealloc (if needed) but don't idle, since it's going 
	to be freed anyway. We know it's unshared because we know it's 
	freeable (and hence deallocated.) */
}

void _MKOrchResetPreviousLosingTemplate(MKOrchestra *self)
/* After we dealloc or free something, we may win on next template
so we have to reset _previousLosingTemplate. */
{
    self->_previousLosingTemplate = nil;
}

static void freeUG(self,aUG,aSP)
register MKOrchestra *self;
id aUG;
id aSP;
/* Free a MKUnitGenerator */
{
    double time;
    MKLeafUGStruct *classInfo;
    MKOrchMemStruct *reloc;
    if (aSP)
	adjustUGInSP(aSP,aUG);
    reloc = [aUG _getRelocAndClassInfo: &classInfo];
    time = getUGComputeTime(self,reloc->pLoop,classInfo);
    adjustResources(self,time,reloc);
    self->_previousLosingTemplate = nil;
    [aUG _free];
    [aUG release];
}

static BOOL popResoAndSetLooper(MKOrchestra *self)
/* Pops the MKUnitGenerator unitGeneratorStack and resets the looper. See popReso */
{
    BOOL resetLooper = popReso(self);
    if (resetLooper)
	setLooper(self);
    return resetLooper;
}

static BOOL popReso(self)
MKOrchestra *self;
/* Frees up resources on top of DSP memory unitGeneratorStack. This is ordinarily invoked
automatically by the orchestra instance. Returns YES if something is
freed.
*/
{
    register id aUG;
    BOOL resetLooper = NO;
    id spHead = nil,spTail = nil,sp;
    while ([self->unitGeneratorStack count]) {
        aUG = [self->unitGeneratorStack lastObject];
        if (![aUG isFreeable])
	    break;
        [aUG retain]; /*sb: retain here to fend off pending release... */
        [self->unitGeneratorStack removeLastObject];/*sb: careful this releases last object...*/
	    resetLooper = YES;
	    sp = [aUG synthPatch];
	    if (sp)
		[sp _prepareToFree: &spHead : &spTail];
	    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
		_MKOrchTrace(self,MK_TRACEORCHALLOC,garbageMsg,NSStringFromClass([aUG class]),
			     aUG);
	    freeUG(self,aUG,sp);/*sb: this includes a release, to finally release what we held above */
    }
//sb: see explanation in MKSynthpatch.m
//    [spTail _freeList: spHead];
    [spTail _freeList2];
    [spTail release];
    return resetLooper;
}

#if COMPACTION 

static void freeUG2(self,aUG,aSP)
register MKOrchestra *self;
id aUG;
id aSP;
/* Used when freeing unit generators during compaction. Like 
freeUG but doesn't change ploop nor argument memory. The
point here is that we don't need to set these because
we will just clobber the values later. */
{
    double time;
    MKLeafUGStruct *classInfo;
    MKOrchMemStruct *reloc;
    if (aSP)
	adjustUGInSP(aSP,aUG);
    reloc = [aUG _getRelocAndClassInfo: &classInfo];
    time = getUGComputeTime(self,reloc->pLoop,classInfo);
    self->computeTime -= time;
    giveDataMem(self,MK_yData,reloc->yData);
    giveDataMem(self,MK_xData,reloc->xData);
    giveDataMem(self,MK_pSubr,reloc->pSubr);
    self->_previousLosingTemplate = nil;
    [aUG _free];
    [aUG release];
}

/*static void bltArgs(MKOrchestra *self,MKOrchMemStruct *argBLTFrom,
MKOrchMemStruct *argBLTTo,MKOrchMemStruct *reso,
id **ugList,id *endOfUGList,id theList)
*/
static void bltArgs(MKOrchestra *self,MKOrchMemStruct *argBLTFrom,
                    MKOrchMemStruct *argBLTTo,MKOrchMemStruct *reso,
                    unsigned int *ugList,unsigned int endOfUGList,id theList)
/* Moves unit generator arguments during compaction. 
Note that endOfUGList is one past the last UG we'll blt */
/*sb: added last arg to the above, to avoid having to send **uglist etc.
* because we can't use pointers to List contents any more.
*/
{
    DSPFix48 *ts = _MKCurSample(self);
    register id el;
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC)) 
	_MKOrchTrace(self,MK_TRACEORCHALLOC,@"Copying arguments.");
    if (reso->xArg && (argBLTFrom->xArg != argBLTTo->xArg))
	DSPMKBLTTimed(ts,DSP_MS_X,argBLTFrom->xArg,
		      argBLTTo->xArg,reso->xArg);
    if (reso->yArg && (argBLTFrom->yArg != argBLTTo->yArg))
	DSPMKBLTTimed(ts,DSP_MS_Y,argBLTFrom->yArg,
		      argBLTTo->yArg,reso->yArg);
    if (reso->lArg && (argBLTFrom->lArg != argBLTTo->lArg)) {
        /* Can't BLT for L space. Need to do x/y separately. */
        DSPMKBLTTimed(ts,DSP_MS_X,argBLTFrom->lArg,argBLTTo->lArg,
                      reso->lArg);
        
        /* JOS/89jul28 */
        DSPMKBLTTimed(ts,DSP_MS_Y,argBLTFrom->lArg,argBLTTo->lArg,
                      reso->lArg);
    }
//    for (el = *ugList; (el < endOfUGList); el++) {
    for (;*ugList < endOfUGList; (*ugList) ++) {
        el = [theList objectAtIndex: *ugList];
        /* Inform MKUnitGenerator and its patch of the relocation change. */
        [el moved];             
        [[el synthPatch] moved: el];
    }
    *ugList = -1; //sb: was NULL. FIXME we aren't dealing with this pointer any more, so I don't know what to do.
}

/*
 static void bltLoop(MKOrchestra *self,MKOrchMemStruct *loopBLTFrom,
		     MKOrchMemStruct *loopBLTTo,MKOrchMemStruct *reso,
		     id **ugList,id *endOfUGList)
 */
static void bltLoop(MKOrchestra *self,MKOrchMemStruct *loopBLTFrom,
                    MKOrchMemStruct *loopBLTTo,MKOrchMemStruct *reso,
                    unsigned int *ugList,unsigned int endOfUGList,id theList)

/* Moves unit generator code during compaction. 
Note that endOfUGList is one past the last UG we'll blt */
/*sb: added last arg to the above, to avoid having to send **uglist etc.
* because we can't use pointers to List contents any more.
*/
{
    DSPFix48 *ts = _MKCurSample(self);
    unsigned int el;
//    register id *el;
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC)) 
	_MKOrchTrace(self,MK_TRACEORCHALLOC,@"Copying p memory.");
    if (reso->pLoop && (loopBLTFrom->pLoop != loopBLTTo->pLoop))
	DSPMKBLTTimed(ts,DSP_MS_P,loopBLTFrom->pLoop,
		      loopBLTTo->pLoop,reso->pLoop);
    el = *ugList; 
    while (el < endOfUGList)  /* Do fixups */
        _MKFixupUG([theList objectAtIndex: el++],ts);//sb: was *el++
	*ugList = -1; //sb: was NULL
}

static BOOL compactResourceStack(MKOrchestra *self)
/* Frees up idle resources in entire DSP memory unitGeneratorStack. 
This is ordinarily invoked automatically by the orchestra instance.
Returns YES if compaction was accomplished.
*/
{
    /* We start from the bottom of the unitGeneratorStack (i.e. nearest the DSP system)
    and work our way up. First we skip over all running UGs, since
    these can't be compacted -- they are already at the bottom of the
    unitGeneratorStack. The first time we find a ug that is freeable, we peel back
    the unitGeneratorStack as if that ug were the top of unitGeneratorStack using freeUG. 
    We also flush p-memory allocation at this point. The idea is that 
    the moved ugs are actually 'reallocated', i.e. we deallocate
    and then allocate again, as if this were a new ug. 
    So it is as if we have a new unitGeneratorStack that 
    is growing over the old unitGeneratorStack. Thus, for each 
    subsequent freeable ugs, we need not reset the unitGeneratorStack, since we
    have already done so. Instead, we merely free any off-chip
    memory that ug has. This is done by the C-function freeUG2.
    The actual moving of the DSP code and argument values is done
    by the MKUnitGenerator function _MKMoveUGCodeAndArgs(). */
    
    unsigned int i;
    unsigned n = [self->unitGeneratorStack count];
    id el; 
    
    /* check first here to avoid copying List */
    for (i = 0; i < n; i++) {
        el = [self->unitGeneratorStack objectAtIndex: i];
        if ([el isFreeable])          /* Can we flush this UG? */
	    break;
    }
    if (i == n)                      
	return NO;
//    if (el == nil) return NO; /*sb: replaces above method. should return if no freeable object found (???) */
    {   /* We've got a freeable one. Here we go... */
        id sp,aUG;
        BOOL UGIsOffChip,UGWasOffChip = NO;
        unsigned int elNum=0;
        unsigned int pendingArgBLT= ~0; //id *pendingArgBLT = NULL;
        unsigned int pendingLoopBLT = ~0; // *pendingLoopBLT = NULL;
        MKOrchMemStruct *ugReso,resoToBLT,newReloc,fromBLT,toBLT, *oldReloc;
        int pLoopNeeds;
	// TODO needs release
        register NSMutableArray *aList = _MKLightweightArrayCopy(self->unitGeneratorStack); //was [self->unitGeneratorStack copy]; /* Local copy */
	id spHead = nil;
	id spTail = nil;
	
	[self beginAtomicSection];
	elNum = i; 
	aUG = [aList objectAtIndex: elNum];
	elNum++;
	[aUG retain]; //so we won't lose it after removal. Must release later.
	[self->unitGeneratorStack removeObjectAtIndex: (elNum - 1)];  //sb. removes from ORIGINAL array not copy.
	if ((sp = [aUG synthPatch]))
	    [sp _prepareToFree: &spHead : &spTail]; /* won't add twice */
	DSPSetCurrentDSP(self->orchIndex);
	if (_MK_ORCHTRACE(self, MK_TRACEORCHALLOC)) {
	    _MKOrchTrace(self, MK_TRACEORCHALLOC, @"Compacting unitGeneratorStack.");
	    _MKOrchTrace(self, MK_TRACEORCHALLOC, garbageMsg, NSStringFromClass([aUG class]), aUG);
	}
	/* freeUG sets unitGeneratorStacks to what they would be if this were actually
	    the top of the unitGeneratorStack. */
	UGIsOffChip = (([aUG relocation]->pLoop) >= self->_bottomOfExternalMemory[P_EMEM]);
	if ((!UGIsOffChip) && self->isLoopOffChip) /* Clear offchip loop */
	    self->isLoopOffChip = givePELoop(self, self->_bottomOfExternalMemory[P_EMEM]);
	freeUG(self,aUG,sp);    //sb: hmmm. Does this do the release for me? yep I think so
	for (i++; i < n; i++) {            /* Starting with the next one... */
	    aUG = [aList objectAtIndex: elNum];
	    if ([aUG isFreeable]) {         /* Can we flush this UG? */
		if (pendingLoopBLT != -1)
		    bltLoop(self, &fromBLT, &toBLT, &resoToBLT, &pendingLoopBLT, elNum, aList); //sb: FIXME! what does blt do? Uses address of el
		if (pendingArgBLT != -1)
		    bltArgs(self, &fromBLT, &toBLT, &resoToBLT, &pendingArgBLT, elNum, aList); //sb: FIXME! what does blt do? Uses address of el
		[self->unitGeneratorStack removeObject: aUG]; /* Same routine as above.*/ 
		if ((sp = [aUG synthPatch]))
		    [sp _prepareToFree: &spHead : &spTail]; 
		if (_MK_ORCHTRACE(self, MK_TRACEORCHALLOC))
		    _MKOrchTrace(self, MK_TRACEORCHALLOC, garbageMsg, NSStringFromClass([aUG class]), aUG);
		freeUG2(self,aUG,sp);      /* But now just free offchip mem */ 
		elNum++;
	    }
	    else {                         /* A running UG must be moved */
		ugReso = [aUG resources];
		oldReloc = [aUG relocation];
		pLoopNeeds = ugReso->pLoop + noops;
		/* The following seems confusing because there are several things to keep in mind: 
		 * Is the unit generator on chip or off chip before it's moved?
		 * Is the unit generator on chip or off chip after it's moved?
		 * Has the (new) loop spilled off chip yet? 
		 */
		if (self->isLoopOffChip) {  /* We're already off chip */
		    newReloc.pLoop = noops + getPELoop(self, pLoopNeeds);
		    UGIsOffChip = YES;
		}
		else {                      /* We're not yet off chip */
		    /* Can we fit the ug on chip? */
		    if ((self->_piLoop + pLoopNeeds) <= MAXPILOOP) {
			/* Yes. The UG can be moved on chip */
			UGIsOffChip = NO; /* We increment piLoop later */
			newReloc.pLoop = noops + self->_piLoop;
			/* Are we moving from off chip to on chip? */
			if (oldReloc->pLoop >= self->_bottomOfExternalMemory[P_EMEM]) {
			    MKLeafUGStruct *p = [aUG classInfo];
			    /* Need to correct compute time. Also need
			    to split up the blt. */
			    self->computeTime -= 
				(getUGComputeTime(self,oldReloc->pLoop,p) -
				 getUGComputeTime(self,newReloc.pLoop,p));
			    if ((pendingLoopBLT != -1) && !UGWasOffChip)
				/* If previous UG was not off chip, we need
				to flush BLT here, since BLT can't straddle
				chip. */
				bltLoop(self, &fromBLT, &toBLT, &resoToBLT, &pendingLoopBLT, elNum, aList);
			    UGWasOffChip = YES;
			}
			else
			    UGWasOffChip = NO;
		    }
		    else { /* We're moving off chip now */
			/* Add a leaper so orchestra system can straddle on-chip/off-chip boundary. */
			UGIsOffChip = YES;
			if (pendingLoopBLT != -1) 
			    bltLoop(self, &fromBLT, &toBLT, &resoToBLT, &pendingLoopBLT, elNum, aList);
			newReloc.pLoop = noops + getPELoop(self, pLoopNeeds);
			putLeaper(self, newReloc.pLoop);
		    }
		}
		if (!(pendingArgBLT != -1)) {
		    toBLT.xArg = self->_xArg;
		    toBLT.yArg = self->_yArg;
		    toBLT.lArg = self->_lArg;
		    fromBLT.xArg = oldReloc->xArg;
		    fromBLT.yArg = oldReloc->yArg;
		    fromBLT.lArg = oldReloc->lArg;
		    resoToBLT.xArg = ugReso->xArg; 
		    resoToBLT.yArg = ugReso->yArg;
		    resoToBLT.lArg = ugReso->lArg;
		    pendingArgBLT = elNum;
		} 
		else {
		    resoToBLT.xArg += ugReso->xArg; 
		    resoToBLT.yArg += ugReso->yArg;
		    resoToBLT.lArg += ugReso->lArg;
		}
		newReloc.xArg = self->_xArg; /* First grab values */
		newReloc.yArg = self->_yArg;
		newReloc.lArg = self->_lArg;
		self->_xArg += ugReso->xArg; /* Now adjust for next reso. */
		self->_yArg += ugReso->yArg;
		self->_lArg += ugReso->lArg;
		if (!(pendingLoopBLT != -1)) {       
		    toBLT.pLoop = newReloc.pLoop - noops;
		    fromBLT.pLoop = oldReloc->pLoop - noops;
		    resoToBLT.pLoop = ugReso->pLoop + noops; 
		    pendingLoopBLT = elNum; //sb: check this. could el become null?
		} 
		else
		    resoToBLT.pLoop += (ugReso->pLoop + noops); 
		if (!UGIsOffChip)            
		    self->_piLoop += pLoopNeeds;  /* Adjust the next reso */
		_MKRerelocUG(aUG,&newReloc);
		elNum++;
	    }   /* End of running UG block. */
	}
	if (pendingLoopBLT != -1) 
	    bltLoop(self, &fromBLT, &toBLT, &resoToBLT, &pendingLoopBLT, elNum, aList);
	if (pendingArgBLT != -1) 
	    bltArgs(self, &fromBLT, &toBLT, &resoToBLT, &pendingArgBLT, elNum, aList); 
	//        [aList release];                        /* Free local copy */
	[spTail _freeList: spHead];           /* Free synthpatches */
	setLooper(self);                     
	[self endAtomicSection];

	/* Top of list might have been  freed so we need to set looper
	explicitly. Actually, if we know for sure that the unitGeneratorStack has been
	popped, this is not necessary, we could just blt p one word more. */

	return YES; 
    } 
}

#else

static BOOL compactResourceStack(MKOrchestra *self)
/* Dummy routine for when compaction is disabled */
{
    return NO;
}

#endif


static void giveDataMem(self,segment,addr)
MKOrchestra *self;
MKOrchMemSegment segment; /* Needed in non-overlaid case. */
int addr;
{
    /* These are the primitives for managing external memory. Since
    pe memory must be kept contiguous, we allocate pe memory from
    the bottom of the memory segment and keep it contiguous. To do
    this, we keep the pe memory allocated from the standpoint of this
    allocator, even if the unit generator is deallocated. 
    Memory lists are sorted by address with the tail of the list 
    being the highest address. In the structs themselves, the
    address is the base (i.e. lower) address. */
    register dataMemBlockStruct *tmp;
    register dataMemBlockStruct *theBlock;
    if ((addr == BADADDR) || (addr == NOMEMORY))
	return;
    for (tmp = self->_availDataMem[S_IND(self,segment)]; 
	 (tmp->prev && (tmp->baseAddr > addr)); 
         tmp = tmp->prev)
	;
    if ((!(tmp->prev)) ||              /* The first one's the PELoop memory */
        (tmp->baseAddr != addr) ||     /* Wrong address. */
        (!tmp->isAllocated))           /* Unclaimed */
	return;                          /* Caller goofed somehow */
    
    theBlock = tmp;                    /* This is the one to free. */
    theBlock->isAllocated = NO;        /* Unmark it. */
    if (!theBlock->prev->isAllocated) {/* Combine with lower addressed block */
        tmp = theBlock->prev;          
        theBlock->baseAddr = tmp->baseAddr;
        theBlock->size = tmp->size + theBlock->size;
        theBlock->prev = tmp->prev;
        theBlock->prev->next = theBlock;
        /* This is safe 'cause end of list is always allocated */
        freeDataMemBlock(tmp);
    }
tmp = theBlock->next;
if (tmp && (!(tmp->isAllocated))) {/* Combine with upper addressed block */
theBlock->size = theBlock->size + tmp->size;
theBlock->next = tmp->next;
if (theBlock->next)            /* Not tail-of-list */ 
theBlock->next->prev = theBlock;
else 
self->_availDataMem[S_IND(self,segment)] = theBlock;/* New tail of list. */
freeDataMemBlock(tmp);
}
}

static void
insertFreeMemStruct(MKOrchestra *self,
		    DSPAddress base,DSPAddress size,
		    dataMemBlockStruct *prev,
		    dataMemBlockStruct *next,
		    MKOrchMemSegment segment)
{
    /* Returns and inits new dataMemBlockStruct between prev and next. */
    register dataMemBlockStruct *newNode;
    newNode = allocDataMemBlock();
    newNode->baseAddr = base;
    newNode->isAllocated = NO;
    newNode->size = size;
    newNode->next = next;
    newNode->prev = prev;
    if (next)
	next->prev = newNode;
    else self->_availDataMem[S_IND(self,segment)] = newNode;
    prev->next = newNode;
}    

static DSPAddress getDataMem(MKOrchestra *self,MKOrchMemSegment segment,int size)
/* Memsegment needed in non-overlaid case. */
{
    /* Memory lists are sorted by address with the tail of the list 
    being the highest address. In the structs themselves, the
    address is the base (i.e. lower) address. */
    register dataMemBlockStruct *tmp = self->_availDataMem[S_IND(self,segment)];
    if (size <= 0)
	return BADADDR;
    while (tmp && (tmp->isAllocated || (tmp->size < size)))
	tmp = tmp->prev;
    if (!tmp)
	return NOMEMORY;
    tmp->isAllocated = YES;
    if (tmp->size > size) {
        insertFreeMemStruct(self,tmp->baseAddr,tmp->size - size,tmp->prev,tmp,
			    segment);
        tmp->baseAddr += (tmp->size - size);
        tmp->size = size;
    }
    return tmp->baseAddr;
}    

static inline int nextPowerOf2(int n)
{
    double y;
    double logN = log((double)n) /log(2.0); /* Log2 */
    if ((modf(logN ,&y)) == 0.0)
	return n;
    return (int) pow(2.0,(double) (((int) logN) +1));
}

static inline int getModulus(dataMemBlockStruct *tmp,int modulus,int size)
{
    int ta = tmp->baseAddr+tmp->size;
    int ba = ta - size;  /* We know tmp->size > size */
    int remainder = ba % modulus;
    if (remainder == 0)  /* Lucked out */
	return ba;
    ba -= remainder;     /* Round Down */
    if (ba < tmp->baseAddr)
	return NOMEMORY;
    return ba;
}

static DSPAddress getModulusDataMem(MKOrchestra *self,
				    MKOrchMemSegment segment,int size)
{
    register dataMemBlockStruct *tmp = self->_availDataMem[S_IND(self,segment)];
    int modulus,ba;
    if (size <= 0)
	return BADADDR;
    modulus = nextPowerOf2(size);
    for (; ;) {
	while (tmp && (tmp->isAllocated || (tmp->size < size)))
	    tmp = tmp->prev;
	if (!tmp)
	    return NOMEMORY;
	if ((ba = getModulus(tmp,modulus,size)) != NOMEMORY) 
	    break;
	tmp = tmp->prev; /* skip this one */
    }
    tmp->isAllocated = YES;
    if (ba+size < tmp->baseAddr+tmp->size) 
	/* Insert a new one in hole */
	insertFreeMemStruct(self,ba+size,tmp->baseAddr+tmp->size-(ba+size),
			    tmp,tmp->next,segment);
    if (ba > tmp->baseAddr) {
        insertFreeMemStruct(self,tmp->baseAddr,ba-tmp->baseAddr,tmp->prev,tmp,
			    segment);
        tmp->baseAddr = ba;
    }
    tmp->size = size;
    return tmp->baseAddr;
}    

#if 0
-(int) largestAvailableContiguousSynthData: (MKOrchMemSegment) segment
    /* Returns size of largest available block of contiguous DSP memory in
    * the specified segment. 
    */
{
    /* We ignore segment for now, since we use overlaid XYP mem */
    register dataMemBlockStruct *tmp = self->_availDataMem[segment];
    int biggest = 0;
    while (tmp) {
	if (!tmp->isAllocated) 
	    if (tmp->size > biggest)
		biggest = tmp->size;
	tmp = tmp->prev;
    }
    return biggest;
}    
#endif

static void givePatchMem(self,segment,addr)
MKOrchestra *self;
MKOrchMemSegment segment;
DSPAddress addr;
{
    /* Give Patchpoint. Forwards call to giveDataMem if necesary. */
    DSPAddress *sigs;
    register int i;
    if (segment == MK_xPatch)
	sigs = &(self->_xPatch[0]);
    else sigs = &(self->_yPatch[0]);
    if ((addr == NOMEMORY) || (addr == BADADDR))
	return;
    if (addr > ((segment == MK_xPatch) ? MAXXPATCH : MAXYPATCH)) {
        giveDataMem(self,(segment == MK_xPatch) ? MK_xData : MK_yData,addr);
        return;
    }
    for (i = 0; i < self->onChipPatchPoints; i++)
	if (*sigs++ == addr) {
	    if (segment == MK_xPatch)
		self->_xPatchAllocBits &= (~(1 << i));
	    else self->_yPatchAllocBits &= (~(1 << i));
	    return;
	}
}

static DSPAddress getPatchMem(self,segment)
MKOrchestra *self;
MKOrchMemSegment segment;
{
    /* Get Patchpoint. Forwards call to giveDataMem if necesary. */
#   define SIGS ((segment == MK_xPatch) ? self->_xPatch : self->_yPatch)
    register int i;
    register unsigned long bVect = (segment == MK_xPatch) ? self->_xPatchAllocBits 
							  : self->_yPatchAllocBits;
    for (i = 0; i < self->onChipPatchPoints; i++)
	if ((bVect & (1 << i)) == 0) {              /* If bit is 0, it's free */
	    if (segment == MK_xPatch)               /* Set bit */
		self->_xPatchAllocBits |= (1 << i); 
	    else self->_yPatchAllocBits |= (1 << i); 
	    return SIGS[i];                         /* Return address */
	}
return getDataMem(self,(segment == MK_xPatch) ? MK_xData : MK_yData,
		  DSPMK_NTICK);                /* Off chip Patchpoint */
}

static DSPAddress getPELoop(self,size)
MKOrchestra *self;
int size;
{
    /* Adjust boundary between PELOOP and PSUBR/XDATA/YDATA memory by adding 
    size. */
    register dataMemBlockStruct *peLoop = self->_eMemList[P_IND(self)];
    register dataMemBlockStruct *availData = peLoop->next;
    /* We do all calculations as if UG really started at newUGLoc. Then we
	subtract 1 at the end. That is, the new UG is really put at newUGLoc-1
	and the looper is after it. In other words, all UGs are shifted down
	by 1 (due to the return value). Since we allocate 1 at the start, this
	works out ok. */
    /* Base of new block, before compensating for looper. */
    int newUGLoc = availData->baseAddr;
    /* Base of next of availData (if any): */
    int nextAvailData = newUGLoc + availData->size;   
    /* Base of availData after allocation: */
    int newAvailData = newUGLoc + size;  
    if (size <= 0)
	return BADADDR;
    if ((availData->isAllocated) ||                /* Can't use it. */
        (nextAvailData <= newAvailData))           /* Not enough free memory */
	return NOMEMORY;
    availData->size = nextAvailData - newAvailData;/* Shrink availData block.*/
	availData->baseAddr = newAvailData;            /* Update its base addr */
	peLoop->size += size;                     /* Update peLoop size. This is
	    the true size (including
			   looper). */
	return newUGLoc - LOOPERSIZE; 
	/* Returns location of new unit generator. This is the true base. The
	    looper will go after this. We have allocated a block of the specified
	    size with LOOPERSIZE words of free storage above the block. The extra
	    space is then reclaimed next time and a new word is allocated. 
	    Get it? */
}

static BOOL givePELoop(self,freedPEAddr)
MKOrchestra *self;
int freedPEAddr;
{
    /* Adjust boundary between PE and XDATA/YDATA memory by subtracting 
    size. freedPEAddr is the relocation of the peLoop being returned 
    (including the 3 preceeding noops). 
    Returns YES if there is still a non-zero PELoop after
    the unitGeneratorStack pop. */
    register dataMemBlockStruct *peLoop = self->_eMemList[P_IND(self)];
    register dataMemBlockStruct *availData = peLoop->next;
    freedPEAddr += LOOPERSIZE;
    /* We add LOOPERSIZE here because we always want to leave space at 
	the end of peLoop for the LOOPER. All of the calculations below
	work out correctly. E.g. peLoop->size will always be at least 
	LOOPERSIZE. */
    peLoop->size = freedPEAddr - peLoop->baseAddr;
    if (availData->isAllocated)   /* Put a new block in for freed segment */
	insertFreeMemStruct(self,freedPEAddr,availData->baseAddr - freedPEAddr,peLoop,
			    availData,MK_pLoop);
    else {                        /* Adjust free list. */
        availData->size += (availData->baseAddr - freedPEAddr);
        availData->baseAddr = freedPEAddr;
    }
return (peLoop->size > LOOPERSIZE);
}

static void setLooper(MKOrchestra *self)
{
    /* Returns address where looper is (or should be). Assumes looper
    is inited. */
    unsigned int looper[2];
    DSPAddress addr = (self->isLoopOffChip) ?
	(((dataMemBlockStruct *)self->_eMemList[P_IND(self)])->next->baseAddr - 
	 LOOPERSIZE) 
					    : self->_piLoop;
    if (_MK_ORCHTRACE(self,MK_TRACEDSP))
	_MKOrchTrace(self,MK_TRACEDSP,@"Adding looper at 0x%x.",addr);
    DSPSetCurrentDSP(self->orchIndex);
    looper[0] = NOOP; /* Jos says you need a noop before the looper to 
	insure that there's no problem if final word of 
	unit generator is a jump. */
    looper[1] = self->_looper;
    DSPMKSendArraySkipTimed(_MKCurSample(self) ,(DSPFix24 *) &looper[0],
                            DSP_MS_P,addr,1,LOOPERSIZE);
}

static DSPAddress allocMemAux(MKOrchestra *self,MKOrchMemSegment segment,
			      int size,BOOL isModulus)
{
    /* Memory alloc auxiliary routine. */
    switch (segment) {
	case MK_pSubr: 
	case MK_xData: 
	case MK_yData: 
	    return ((isModulus) ? 
		    getModulusDataMem(self,segment,size) : 
		    getDataMem(self,segment,size));
	case MK_xPatch: 
	case MK_yPatch: 
	    if (size != DSPMK_NTICK) 
		return BADADDR;
	    return ((isModulus) ?
		    getModulusDataMem(self,segment,size) : 
		    getPatchMem(self,segment));
	case MK_pLoop: 
	    return BADADDR;
	default: 
	    return BADADDR;
    }
}

static DSPAddress allocMem(MKOrchestra *self,MKOrchMemSegment segment,unsigned size,
			   BOOL isModulus)
{
    /* Allocate off-chip memory of specified size in indicated segment 
    and returns address in specified segment. */
    id *templPtr;
    id aPatch;
    NSMutableArray *deallocatedPatches;
    DSPAddress rtnVal;     
    unsigned i;
    CHECKADJUSTTIME();
    if (self->deviceStatus == MK_devClosed)
	return NOMEMORY;
    if (size == 0)
	return BADADDR;
    if ((rtnVal = allocMemAux(self,segment,size,isModulus)) != NOMEMORY)
	return rtnVal;
    /* Now look if there's some garbage to collect in shared table. */
    if (_MKCollectSharedDataGarbage(self,self->sharedGarbage))
	if ((rtnVal = allocMemAux(self,segment,size,isModulus)) != NOMEMORY)
	    return rtnVal;
    /* Now look if there's some free memory in a deallocated syntpatch */
    i = nTemplates;
    templPtr = patchTemplates;
    while (i--) {
        deallocatedPatches = _MKDeallocatedSynthPatches(*templPtr,self->orchIndex);
	
        if ([deallocatedPatches count]) {
            aPatch = [deallocatedPatches lastObject]; /* peek */
            if ([aPatch _usesEMem: segment])
		/* See comment in MKSynthPatch.m */
                while ([deallocatedPatches count]) {
                    aPatch = [deallocatedPatches lastObject];
                    [aPatch _free];            /* Deallocate some UGs. */
                    [deallocatedPatches removeLastObject];/*sb: this correctly releases last object*/
                        if (popResoAndSetLooper(self)) /* Free some UGs. */
                            if ((rtnVal = allocMemAux(self,segment,size,isModulus))
				!= NOMEMORY)
                                return rtnVal;
		}
	}
            templPtr++;  /* Try next template. */
    }
	rtnVal = allocMemAux(self,segment,size,isModulus);
	if (rtnVal == NOMEMORY) {
	    if (compactResourceStack(self))
		rtnVal = allocMemAux(self,segment,size,isModulus);
	}
	return rtnVal;
}

/* Functions for unit generator allocation. ---------------------- */

#define CONSERVATIVE_UG_TIMING_COMPENSATION (DSP_CLOCK_PERIOD * 3)

static int resoAlloc(MKOrchestra *self,id factObj,MKOrchMemStruct *reloc)
/* Returns, in reloc, the relocation info matching the reso request. 
Returns 0 (OK) if successful, TIMEERROR if unsuccessful because 
of a lack of available runtime,
else an MKOrchMemSegment indicating what was in short supply.
If a non-0 value is returned, the
reloc contents is not valid and should be ignored. This is 
used by the MKUnitGenerator class to allocate space for the new
instance. */
{
    BOOL leapOffChip = NO;
    double time;
    int pLoopNeeds;
    int rtnVal;
    register MKOrchMemStruct *reso;
    MKLeafUGStruct *classInfo;
    [factObj orchestraWillCreate: self];
    classInfo = [factObj classInfo];
    reso = &classInfo->reso;
    pLoopNeeds = reso->pLoop + noops;
    time = getUGComputeTime(self,
			    ((self->isLoopOffChip) ? 
                             (int) self->_bottomOfExternalMemory[P_EMEM] : 
			     /* any old off-chip address */
			     (pLoopNeeds + self->_piLoop)), /* figure it */
			     classInfo);
			    if ((reloc->xData = allocMem(self,MK_xData,reso->xData,NO)) == 
				NOMEMORY) 
			    return (int)MK_xData;
			    if ((reloc->yData = allocMem(self,MK_yData,reso->yData,NO)) == 
				NOMEMORY) {
				giveDataMem(self,MK_xData,reloc->xData);
				return (int) MK_yData;
			    }
			    if ((reloc->pSubr = allocMem(self,MK_pSubr,reso->pSubr,NO)) == 
				NOMEMORY) {
				giveDataMem(self,MK_xData,reloc->xData);
				giveDataMem(self,MK_yData,reloc->yData);
				return (int) MK_pSubr;
			    }
			    reloc->xArg = self->_xArg;
			    reloc->yArg = self->_yArg;
			    reloc->lArg = self->_lArg;
			    if (self->isLoopOffChip) 
			    reloc->pLoop = noops + getPELoop(self,pLoopNeeds);
			    else {  
				reloc->pLoop = noops + self->_piLoop;
				if ((self->_piLoop + pLoopNeeds) <= MAXPILOOP) 
				    self->_piLoop += pLoopNeeds;
				else {
				    reloc->pLoop = noops + getPELoop(self,pLoopNeeds);
				    leapOffChip = YES;
				    /* Add a leaper so orchestra system can straddle on-chip/off-chip 
					boundary. */
				}
			    }
			    rtnVal = ((reloc->pLoop == NOMEMORY) ? (int) MK_pLoop : 
				      ([self isRealTime] && 
				       ((self->computeTime + time >= self->_effectiveSamplePeriod))) ? 
				      TIMEERROR : 
				      ((self->_xArg += reso->xArg) >= self->_maxXArg) ? (int)MK_xArg : 
				      ((self->_lArg += reso->lArg) >= MAXLARG) ? (int) MK_lArg : 
				      ((self->_yArg += reso->yArg) >= self->_maxYArg) ? (int) MK_yArg : OK);
			    /* >= because xArg, etc. point to the NEXT available location. */
			    if (rtnVal) {   /* Undo effect of resoAlloc. */
			    if (rtnVal != (int) MK_pLoop) {
				if (self->isLoopOffChip)  /* See if we're moving back on chip. */
				    self->isLoopOffChip = givePELoop(self,reloc->pLoop - noops); 
				else
				    self->_piLoop = reloc->pLoop - noops; /* Wind back. */
				self->_xArg = reloc->xArg;
				self->_lArg = reloc->lArg;
				self->_yArg = reloc->yArg;
				giveDataMem(self,MK_yData,reloc->yData);
				giveDataMem(self,MK_xData,reloc->xData);
				giveDataMem(self,MK_pSubr,reloc->pSubr);
				return rtnVal;
			    }
			    }
if (leapOffChip)
putLeaper(self,reloc->pLoop);
self->computeTime += time;
if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC)) {
    _MKOrchTrace(self,MK_TRACEORCHALLOC,
		 @"Reloc: pLoop %d, xArg %d, yArg %d, lArg %d, xData %d, yData %d, pSubr %d",
		 reloc->pLoop,reloc->xArg,reloc->yArg,reloc->lArg,
		 reloc->xData,reloc->yData,reloc->pSubr);
    _MKOrchTrace(self,MK_TRACEORCHALLOC,
		 @"Reso: pLoop %d, xArg %d, yArg %d, lArg %d, xData %d, yData %d, pSubr %d, time %e",
		 pLoopNeeds,reso->xArg,reso->yArg,reso->lArg,
		 reso->xData,reso->yData,reso->pSubr,time);
}
return OK;
}


#define KEEPTRYING 0
#define LOSE 1
#define WIN 2

static id getUG(self,factObj,beforeObj,afterObj,optionP)
MKOrchestra *self;
id factObj,beforeObj,afterObj;
unsigned *optionP;
{
    /* Returns a unit generator if one is around. Does not create one. */
    id rtnVal;
    if (afterObj) 
	if (beforeObj)
	    rtnVal = [factObj _allocFirstAfter: afterObj before: beforeObj 
					  list: self->orchIndex];
	else 
	    rtnVal = [factObj _allocFirstAfter: afterObj list: self->orchIndex];
    else if (beforeObj)
	rtnVal = [factObj _allocFirstBefore: beforeObj list: self->orchIndex];
    else rtnVal = [factObj _allocFromList: self->orchIndex];
    if (rtnVal) {
        *optionP = WIN;
        return rtnVal;
    }
    *optionP = KEEPTRYING;
    return nil;
}


static void allocError(self,allocErr)
MKOrchestra *self;
int allocErr;
{
    switch (allocErr) {
	case OK: 
	    self->lastAllocFailStr = 
	    @"Allocation failure. DSP error (should never happen).";
	    break;
	case TIMEERROR: 
	    self->lastAllocFailStr = 
	    @"Allocation failure. Not enough computeTime.";
	    break;
	default: 
	    self->lastAllocFailStr = 
            [NSString stringWithFormat: @"Allocation failure. Not enough %@ memory.",
		orchMemSegmentNames[allocErr]];
	    break;
    }
    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
	_MKOrchTrace(self,MK_TRACEORCHALLOC,self->lastAllocFailStr);
}

static id 
allocUG(self,factObj,beforeObj,afterObj)
register MKOrchestra *self;
id factObj,beforeObj,afterObj;
{
    /* Self is the orchestra instance. FactObj is the factory of the
    unit generator requested. beforeObj and afterObj, if specified,
    are used to limit the search. They should be unit generator
    instances. The algorithm used is as follows: 
    
    Here's the algorithm for ug alloc: 
    
    Deallocated ug of correct type? If so, use it.
    Otherwise, is there a ug of the correct type in a deallocated synth patch?
    If so, use it.
    Otherwise, pop unitGeneratorStack. Enough resources for new ug?
    If so, make it.
    Otherwise, do compaction. Enough resources for new ug?
    If so, make it.
    Otherwise, fail.
    */
    id *templPtr;
    id aPatch,rtnVal;
    NSMutableArray *deallocatedPatches;     
    unsigned i,option;
    CHECKADJUSTTIME();
    if (self->deviceStatus == MK_devClosed)
	return nil;
    rtnVal = getUG(self,factObj,beforeObj,afterObj,&option);
    if (option == WIN) 
	return rtnVal;
    else if (option == LOSE)
	return nil;
    /* Now look if there's one in an deallocated syntpatch */
    i = nTemplates;
    templPtr = patchTemplates;
    while (i--) {
        deallocatedPatches = _MKDeallocatedSynthPatches(*templPtr,self->orchIndex);
        if ([deallocatedPatches count]) /* peek */
	    if (_MKIsClassInTemplate(*templPtr,factObj))
		while ([deallocatedPatches count]) {
		    aPatch = [deallocatedPatches lastObject];
		    [aPatch _free];        /* Free up some UGs. */
		    [deallocatedPatches removeLastObject];/*sb: this correctly releases last object*/
			rtnVal = getUG(self,factObj,beforeObj,afterObj,&option);
			if (option == WIN) 
			    return rtnVal;
		    else if (option == LOSE)
			return nil;
		}
		    templPtr++;  /* Try next template. */
    }
    {   /* Make a new one. */
        int allocErr = 0;
        MKOrchMemStruct reloc;
        popResoAndSetLooper(self);
        if (!beforeObj) 
	    /* We always add at the top of the unitGeneratorStack. 
	    So if we've made it to here, we know
	    there can be no object after us. */    
	    if ((allocErr = resoAlloc(self,factObj,&reloc)) == OK)
		if (!(rtnVal = 
		      [factObj _newInOrch: self index: self->orchIndex reloc: 
			    &reloc looper: self->_looper])) 
		    abortAlloc(self,factObj,&reloc);
        if (!rtnVal) {
            if (!compactResourceStack(self)) {
                if (beforeObj) {
		    self->lastAllocFailStr = 
		    @"Allocation failure: Can't allocate before specified unit generator.";
                    if (_MK_ORCHTRACE(self,MK_TRACEORCHALLOC))
			_MKOrchTrace(self,MK_TRACEORCHALLOC,
				     self->lastAllocFailStr);
                }
                else
		    allocError(self,allocErr);
                return nil;
            }
            if ((allocErr = resoAlloc(self,factObj,&reloc)) == OK)
		if (!(rtnVal = 
		      [factObj _newInOrch: self index: self->orchIndex reloc: 
			    &reloc looper: self->_looper])) 
		    abortAlloc(self,factObj,&reloc);
            if (!rtnVal) {
                allocError(self,allocErr);
                return nil;
            }
        }
        [self->unitGeneratorStack addObject: rtnVal];
        insertNoops(self,reloc.pLoop - noops);
        /* We add the noops after the UG (in time) but positioned in memory
	    before the UG. This is guaranteed to be safe, since we know we have
	    a valid looper until we add the noops. */
        return rtnVal;
    }
    return nil;
}

+ registerOrchestraSubclass: (id) classObject forOrchIndex: (int) index
{
    if (index >= nDSPs)
	return nil;
    orchestraClasses[index] = classObject;
    return self;
}

- writeSymbolTable: (NSString *) fileName
{
    int i=0,cnt;//sb: fd
    NSMutableData *s = [[NSMutableData alloc] initWithCapacity: 100];
    DSPAddress looperAddr = (isLoopOffChip) ?
	((dataMemBlockStruct *) _eMemList[P_IND(self)])->next->baseAddr - LOOPERSIZE : 
        _piLoop;
    if (!s)
	return nil;
    for (cnt=[unitGeneratorStack count], i=0; i<cnt; i++)
        [[unitGeneratorStack objectAtIndex: i] writeSymbolsToStream: s];
//    [NX_ADDRESS(unitGeneratorStack)[i] writeSymbolsToStream: s];
    [s appendData: [[NSString stringWithFormat: @"_SYMBOL P\nLOOPER I %06X\n_END %06X\n", looperAddr,ORCHLOOPLOC]
                    dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    
    /* _MKOpenFileStream(fileName,&fd,NX_WRITEONLY,
				    "lod",YES);*/
    /*    if ([[fileName pathExtension] isEqualToString: @"lod"])
        [s writeToFile: fileName atomically: YES];
    else [s writeToFile: [fileName stringByAppendingPathExtension: @"lod"] atomically: YES];
    */
    [s release];
    _MKOpenFileStreamForWriting(fileName,@"lod",s, YES);
    
    return self;
}

- (int) hardwareSupportedSamplingRates: (double **) arr 
{
    *arr = (double *) _MKMalloc(sizeof(double) * 1);
    (*arr)[0] = 44100;
    return 1;
}

- (BOOL) supportsSamplingRate: (double) rate
{
    return EQU(rate, 44100.0) || EQU(rate, 22050.0);
}

- (double) defaultSamplingRate
{
    return DEFAULTSRATE;
}

- (unsigned) capabilities
{
#if m68k
    return (MK_nextCompatibleDSPPort | MK_hostSoundOut |
	    MK_serialSoundOut | MK_soundIn | MK_soundfileOut);
#else
    unsigned rtn;
    if (_nextCompatibleSerialPort)
	rtn = MK_nextCompatibleDSPPort;
    else rtn = 0;
    return (rtn | (MK_serialSoundOut | MK_soundIn | MK_soundfileOut));
#endif    
}

- (BOOL) prefersAlternativeSamplingRate
{
#if i386 && defined(__NeXT__)
    return ([self _waitStates] == 3);
#else
    return NO;
#endif
}


/* May want to make this on a per-DSP basis */
static id abortNotificationDelegate = nil;
static BOOL notificationSent = NO;

+ setAbortNotification: aDelegate
{
    abortNotificationDelegate = aDelegate;
    return self;
}

@end

/* Private MKOrchestra interface */
@implementation MKOrchestra(Private)

-_notifyAbort
    /* Sent by MKUnitGenerator, MKSynthData or MKOrchestra when they notice trouble */
{
    if (abortNotificationDelegate && !notificationSent)
	[MKConductor sendMsgToApplicationThreadSel: @selector(orchestraDidAbort: )
						to: abortNotificationDelegate argCount: 1, self];
    notificationSent = YES;
    return self;
}

-_clearNotification
{
    notificationSent = NO;
    return self;
}

#if i386 && defined(__NeXT__)
static BOOL driverPresent(unsigned short index)
{
    return (DSPGetInUseDriverNames()[index] != NULL);
}
#endif

+(NSMutableArray **) _addTemplate: aNewTemplate 
    /* The MKOrchestra keeps a list of MKSynthPatches indexed by PatchTemplates.
    MKPatchTemplate uses this to tell the MKOrchestra about each new Template. */
{
    static int curArrSize = 0;
    NSMutableArray **deallocatedPatches;
    int i;
#   define ARREXPAND 5 
    if (nTemplates == 0) {
        _MK_MALLOC(patchTemplates,id,ARREXPAND);
        curArrSize = ARREXPAND;
    }
    else if (nTemplates == curArrSize) {
        curArrSize = nTemplates + ARREXPAND;
        _MK_REALLOC(patchTemplates,id,curArrSize);
    }
    _MK_MALLOC(deallocatedPatches,id,nDSPs);
    for (i = 0; i < nDSPs; i++)
	deallocatedPatches[i] = [[NSMutableArray alloc] init];
    patchTemplates[nTemplates++] = aNewTemplate;
    return deallocatedPatches;
}

-_adjustOrchTE: (int) yesOrNo reset: (int) reset
{
    /* Check if we're called from the wrong thread. 
    The reason I jump through hoops in this case and no other is that
    this is the only case where we call DPSClient functions from within
    the Music Kit in a separate threaded performance. */
    if ([MKConductor separateThreadedAndInMusicKitThread]) {
        /* Forward msg to right thread */
        [MKConductor sendMsgToApplicationThreadSel: @selector(_adjustOrchTE: reset: )
	                                        to: self
                                          argCount: 2, yesOrNo, reset];
    }
    else {
        /* DAJ: Commented out lock/unlock here.  It's not needed */
//	[MKConductor lockPerformance];
	adjustOrchTE(self, yesOrNo, reset);
//	[MKConductor unlockPerformance];
    }
    return self;
}

@end
