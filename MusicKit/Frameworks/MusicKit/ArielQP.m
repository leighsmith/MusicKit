#import "_musickit.h"
#import <Foundation/NSArray.h>
#import "_ArielQP.h"
#import "OrchestraPrivate.h"
#import "_error.h"

@implementation ArielQP:MKOrchestra
{
    int slot;         /* One of 2, 4 or 6 */
    BOOL satSoundIn;  /* YES if we're receiving sound from the satellites */
    BOOL DRAMAutoRefresh; /* YES if we're refreshing when needed */
    MKSynthData * _satSynthData; /* Buffers for incoming sound data */
    BOOL _initialized;
    NSDate * _reservedArielQP1; //sb: was double
}

#define NO_SLOT (-1)
#define NO_DSP (-1)
#define NO_BOARD (-1)

#define SLOT_TO_BOARD(_slot) ((_slot==2)?0:(_slot==4)?1:(_slot==6)?2:NO_BOARD)
#define SLOT_TO_HUB(_slot) ((_slot==2)?5:(_slot==4)?10:(_slot==6)?15:NO_DSP)
#define HUB_TO_SLOT(_index) ((_index==5)?2:(_index==10)?4:(_index==15)?6:NO_SLOT)
#define VALID_SLOT(_slot) ((_slot == 2)||(_slot == 4)||(_slot == 6))

+ (void)initialize
{
    int i;
    int dsps = [MKOrchestra DSPCount];
    if (dsps > 15) 
      dsps = 15;
    for (i=1; i<= dsps; i++)
      if ((i % 5)==0)
	[MKOrchestra registerOrchestraSubclass:self forOrchIndex:i];
      else [MKOrchestra registerOrchestraSubclass:[ArielQPSat class] 
	    forOrchIndex:i];
    return;
}

+allocFromZone:(NSZone *)zone onDSP:(unsigned short)index
{
    int theSlot = HUB_TO_SLOT(index);
    ArielQP *obj;
    if (!VALID_SLOT(theSlot))
      return nil;
    obj = [super allocFromZone:zone onDSP:index];
    if (!obj)    /* This will happen if QP is not there. */
      return nil;
    obj->slot = theSlot;
    return obj;
}

+allocFromZone:(NSZone *)zone inSlot:(unsigned short)slotNumber
{
    if (!VALID_SLOT(slotNumber))
      return nil;
    return [self allocFromZone:zone onDSP:SLOT_TO_HUB(slotNumber)];
}

+newInSlot:(unsigned short)slotNumber
{
    return [[self allocFromZone:NSDefaultMallocZone() inSlot:slotNumber] init];
}

+new
{
    return [[self alloc] init];
}

+alloc
{
    return [self allocFromZone:NSDefaultMallocZone() inSlot:2];
}

+ allocWithZone:(NSZone *)zone
{
    return [self allocFromZone:zone inSlot:2];
}

-init
  /* Creates all satellite DSPs */
{
    int board = SLOT_TO_BOARD(slot);
    int i,startDSP,hubDSP;
    id obj;
    [super init];
    if (_initialized)
      return self;
    _initialized = YES;
    [self setSoundOut:NO];
    [self setSerialSoundOut:YES];
    [self setSatSoundIn:YES];
    startDSP = 1+board*5;
    if (startDSP >= [MKOrchestra DSPCount]) {
	[super release];
        return nil; /* sb: nil for compatibility with old -free method */
    }
    hubDSP = startDSP + 4;
    for (i=startDSP; i<hubDSP; i++) {
	obj = [ArielQPSat newOnDSP:i];
	if (!obj) {
	    [super release];
            return nil; /* sb: nil for compatibility with old -free method */

	}
    }
    [self setMonitorFileName:@"mkmon_A_qp_hub_8k.dsp"];
    return self;
}

-(double)systemOverhead
{
    return (satSoundIn) ? .3 : 0;
}

-(BOOL)startSoundWhenOpening {
    return NO;
}

-setUpDSP
  /* This gets invoked by -open method when DSP is booted but before sound
   * of any kind is started.  
   */
{
    if (satSoundIn) {
	int addr;
	int varAddr;
	int hmVal;
	int bufferSize = DSPGetSystemSymbolValueInLC("NB_DMA_W", DSP_LC_N);
#if 1
	if (bufferSize != 0x200)
	  fprintf(stderr,"Warning: NB_DMA_W != 0x200.  == %d\n",bufferSize);
#endif
	_satSynthData = [self allocSynthData:MK_yData length:bufferSize*4]; /* FIXME */
        if (!_satSynthData)
	  fprintf(stderr,"Can't allocate hub memory.\n");
	addr = [_satSynthData address];
        varAddr =  DSPGetSystemSymbolValueInLC("X_SAT1_REB", DSP_LC_X);     
        if (varAddr > 0)
	  DSPWriteValue(addr,DSP_MS_X,varAddr);
	else _MKErrorf(MK_dspMonitorVersionError,[self class]);
	hmVal = DSPGetSystemSymbolValueInLC("HM_DMA_RD_SAT_ON", DSP_LC_P);      
	if (hmVal > 0)
	  DSPHostMessage(hmVal);
	else _MKErrorf(MK_dspMonitorVersionError,[self class]);
    }
    return self;
}

-(BOOL)DRAMAutoRefresh
{
    return DRAMAutoRefresh;
}


- setDRAMAutoRefresh:(BOOL)yesOrNo
{
    int hmVal;
    char *s;
    if (yesOrNo == DRAMAutoRefresh)
      return self;
    DRAMAutoRefresh = yesOrNo;
    if (yesOrNo)
      s = "HM_DRAM_REFRESH_ON";
    else s = "HM_DRAM_REFRESH_OFF";
    hmVal = DSPGetSystemSymbolValueInLC(s, DSP_LC_P);      
    if (hmVal > 0) {
	DSPHostMessage(hmVal);
	return self;
    }
    _MKErrorf(MK_dspMonitorVersionError,[self class]);
    return nil;
}

-abort
{
    [_satSynthData release];
    _satSynthData = nil;
    return [super abort];
}

-satellite:(char)which
{
    if (which < 'A' || which > 'D')
      return nil;
    which -= 'A';
    which += (orchIndex - 4);
    return [ArielQPSat newOnDSP:which];
}

-setSatSoundIn:(BOOL)yesOrNo
  /* Default is YES. */
{
    int i;
    if (deviceStatus != MK_devClosed)
      return nil;
    for (i='A';i<='D';i++) {
	[[self satellite:i] _setHubSoundOut:yesOrNo];
    }
    [self _setSatSoundIn:yesOrNo];
    return self;
}

-(BOOL)satSoundIn
{
    return satSoundIn;
}

-makeSatellitesPerform:(SEL)selector
{
    [[self satellite:'A'] performSelector:selector];
    [[self satellite:'B'] performSelector:selector];
    [[self satellite:'C'] performSelector:selector];
    [[self satellite:'D'] performSelector:selector];
    return self;
}

-makeQPPerform:(SEL)selector
{
    [self makeSatellitesPerform:selector];
    [self performSelector:selector];
    return self;
}

-makeSatellitesPerform:(SEL)selector with:arg;
{
    [[self satellite:'A'] performSelector:selector withObject:arg];
    [[self satellite:'B'] performSelector:selector withObject:arg];
    [[self satellite:'C'] performSelector:selector withObject:arg];
    [[self satellite:'D'] performSelector:selector withObject:arg];
    return self;
}

-makeQPPerform:(SEL)selector with:arg;
{
    [self makeSatellitesPerform:selector with:arg];
    [self performSelector:selector withObject:arg];
    return self;
}

- (void)dealloc
{
    [self makeQPPerform:@selector(abort)];
    [self makeSatellitesPerform:@selector(release)];
    [super dealloc];
}

- close
{
    if (!satSoundIn)
        return [super close];
    [super close];  /* Waits for the end of time */
    [self makeSatellitesPerform:@selector(abort)];
    return self;
}

#define DSP_AWAIT_BROKEN 1

#if DSP_AWAIT_BROKEN
/* The following is to work around the fact that we can't seem to
 * wait for the end of time successfully. 
 */

#define _runT _reservedArielQP1 

static NSDate * getTime(void) /*sb: was static double... */
    /* Taken from Conductor.m */
{
/*
    struct tsval ts;
    static unsigned int lastStamp = 0;
    static double accumulatedTime = 0.0;
#   define MICRO ((double)0.000001)
#   define WRAP_TIME (((double)0xffffffff) * MICRO)
    kern_timestamp(&ts);
    if (ts.low_val < lastStamp)
	accumulatedTime += WRAP_TIME;
    lastStamp = ts.low_val;
    return accumulatedTime + ((double)ts.low_val) * MICRO;
 */
    /*sb: replaced all of above with new class, NSDate.
     * There's really not much point in keeping this function, as it can be replaced in all instances
     * by the NSDate call.
     */
       return [NSDate date];

}

-awaitEndOfTime:(double)endOfTime timeStamp:(DSPTimeStamp *)aTimeStampP
/* sb: endOfTime should be relative, so _runT needs to be absolute  (relative - (abs - abs))*/
{
//    double timeToWait = endOfTime - ([NSDate date]-_runT);
    double timeToWait = endOfTime + [_runT timeIntervalSinceNow];//sb: timeIntervalSinceNow is neg!
//    int sleepTime = timeToWait + .9999999; /* Round up */ //sb: unnecessary now, as sleepuntilDate uses millis.
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(timeToWait)]]; //sb: changed from sleepTime
    return self;
}

- run
{
    id val = [super run];
    [_runT autorelease];//sb
    _runT = [[NSDate date] retain]; //sb: was getTime();
    return val;
}
#endif


@end

@implementation ArielQP(Private)

-_setSatSoundIn:(BOOL)yesOrNo
  /* Default is YES. */
{
    satSoundIn = yesOrNo;
    return self;
}

@end


@implementation ArielQPSat:MKOrchestra
{
    BOOL hubSoundOut; /* YES if we're sending sound to the hub. */
    NSDate * _reservedArielQPSat1; //sb: this is a timestamp, thus changed from double to NSDate *
}

#if DSP_AWAIT_BROKEN
/* The following is to work around the fact that we can't seem to
 * wait for the end of time successfully. 
 */
#undef _runT
#define _runT _reservedArielQPSat1 
-awaitEndOfTime:(double)endOfTime timeStamp:(DSPTimeStamp *)aTimeStampP
{
//    double timeToWait = endOfTime - ([NSDate date]-_runT); //sb: was getTime();
    double timeToWait = endOfTime + [_runT timeIntervalSinceNow];//sb: timeIntervalSinceNow is neg!
//    int sleepTime = timeToWait + .9999999; /* Round up */ //sb: unnec because sleepUntilDate works!
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(timeToWait)]];//sb: was sleepTime
    return self;
}

- run
{
    id val = [super run];
    _runT = [NSDate date]; //sb: was getTime();
    return val;
}
#endif

static int getSlot(int index)
{
    int i = index;
    if (i >= 1 && i <= 4)
      return 2;
    else if (i >= 6 && i <= 9)
      return 4;
    else if (i >= 11 && i <= 14)
      return 6;
    return NO_SLOT;
}

static int validSlot(int i)
{
    return (i==2 || i==4 || i==6);
}

-(BOOL)isRealTime
{
    return hubSoundOut ? [[self hub] isRealTime] : [super isRealTime];
}

-hub
{
    int slot;
    slot = getSlot(self->orchIndex);
    return [ArielQP newInSlot:slot];
}

+allocFromZone:(NSZone *)zone onDSP:(unsigned short)index
{
    int slot = getSlot(index);
    if (!validSlot(slot))
      return nil;
    return [super allocFromZone:zone onDSP:index];
}

-init
{
    [super init];
    [self setSoundOut:NO];
    hubSoundOut = YES;
    [self setMonitorFileName:@"mkmon_A_qp_sat_16k.dsp"];
    return self;
}

-(BOOL)startSoundWhenOpening {
    return NO;
}

- close
{
    if (hubSoundOut)
      return self;
    else return [super close];
}

-setUpDSP
{
    int hmVal;
#if 0
    int varAddr =  DSPGetSystemSymbolValueInLC("X_SAT_ID", DSP_LC_X);     
    int theBit;
    theBit = 1 << (self->orchIndex - 1)*2;
    if (varAddr > 0)
      DSPWriteValue(theBit,DSP_MS_X,varAddr);
    else fprintf(stderr,"Warning: Can't find X_SAT_ID\n");
#endif
    if (hubSoundOut) {
	hmVal = DSPGetSystemSymbolValueInLC("HM_DMA_WD_HUB_ON", DSP_LC_P);      
	if (hmVal > 0)
	  DSPHostMessage(hmVal);
	else _MKErrorf(MK_dspMonitorVersionError,[self class]);
    }
    return self;
}

-setHubSoundOut:(BOOL)yesOrNo
  /* Default is YES. Setting hubSoundOut disables serialSoundOut.  */
{
    if (deviceStatus != MK_devClosed)
      return nil;
    [[self hub] setSatSoundIn:yesOrNo];
    return self;
}

-setSerialSoundOut:(BOOL)yesOrNo
{
    if (deviceStatus != MK_devClosed)
      return nil;
    if (yesOrNo == serialSoundOut)
      return self;
    if (yesOrNo)
      [self setHubSoundOut:NO];
    [super setSerialSoundOut:YES];
    return self;
}

-(BOOL)hubSoundOut
{
    return hubSoundOut;
}

-(int)outputChannelOffset
  /* Offset in DSP sound output buffer of the second channel.
   * Note that we don't support simultaneous SSI output and hub output.
   * If hubSoundOut, Hub orchestra's serialPortDevice must be set before 
   * sending this message.
   */
{
    if (serialSoundOut) 
      return [super outputChannelOffset];
    else return [[self hub] outputChannelOffset]; 
}

-(int)outputChannelCount
{
    if (serialSoundOut) 
      return [super outputChannelCount];
    else return [[self hub] outputChannelCount]; 
}	    

-(BOOL)upSamplingOutput
{
    if (serialSoundOut) 
      return [super upSamplingOutput];
    else return [[self hub] upSamplingOutput]; 
}

-(int)outputInitialOffset
  /* Offset in DSP sound output buffer of the second channel */
{
    if (serialSoundOut) 
      return [super outputInitialOffset];
    else return [[self hub] outputInitialOffset]; 
}

@end

@implementation ArielQPSat(Private)

-_setHubSoundOut:(BOOL)yesOrNo
  /* Default is YES. Setting hubSoundOut disables serialSoundOut.  */
{
    hubSoundOut = yesOrNo;
    if (yesOrNo)
      [self setSerialSoundOut:NO];
    return self;
}

@end
