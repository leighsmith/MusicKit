#import "Wave.h"
#import <musickit/musickit.h> 
#import <musickit/unitgenerators/unitgenerators.h> 
#import <musickit/synthpatches/Wave1vi.h>

#define LOG10 2.3025
#define MAXVALUE 0.9

@implementation Wave
  
- setFftView:anObject
{
    fftView = anObject;
    return self;
}

#define SEND_DSP_CMDS() [Orchestra flushTimedMessages] 
/* This is a noop if sound is off (the DSP is closed.) */

- stopSound
{
    if ([anOrch deviceStatus] == MK_devClosed) /* Should never happen */
      return self;
    [tableLook dealloc];
    [aSP dealloc];
    tableLook = aSP = nil;
    [anOrch abort];
    return self;
}


- startSound
  /* Attempts to start sound.  Returns self if successful */
{
    /* We use a conductor-less performance.  Not normally a good idea,
     * but what we're doing is so basic that it doesn't hurt. 
     */
    if ([anOrch deviceStatus] != MK_devClosed) /* Should never happen */
      return self;
    anOrch = [Orchestra new];
    [anOrch setSamplingRate:44100];
    [anOrch setFastResponse:YES];	
    [anOrch setTimed:NO];
    if (![anOrch open]) {
	NXRunAlertPanel("WaveDraw","Can't open DSP."
			"Some other application must be using it.",
			"OK",NULL,NULL);
	return nil;
    }
    
    // Create one oscillator with table lookup.
    aSP = [anOrch allocSynthPatch:[Wave1vi class]];
    tableLook = [anOrch allocSynthData:MK_yData length:tableLength];
    [tableLook setData:DSPTable];           
    [aNote setPar:MK_freq toDouble:frq];
    [aNote setPar:MK_amp toDouble:amp];
    [aNote setPar:MK_waveform toWaveTable:tableLook];
    if (vibOn) {
	[aNote setPar:MK_svibAmp toDouble:pvib];
	[aNote setPar:MK_rvibAmp toDouble:rvib];
    }
    [aNote setPar:MK_svibFreq toDouble:pvibFrq];
    [aNote setPar:MK_freq toDouble:frq];
    [anOrch run];
    [aSP noteOn:aNote];
    [aNote removePar:MK_freq];
    [aNote removePar:MK_amp];
    [aNote removePar:MK_waveform];
    [aNote removePar:MK_svibFreq];
    if (vibOn) {
	[aNote removePar:MK_svibAmp];
	[aNote removePar:MK_rvibAmp];
    }
    SEND_DSP_CMDS();
    return self;
}

-awakeFromNib
{
    DSPTable = (DSPDatum*) calloc(tableLength,sizeof(DSPDatum));
    DPSSetTracking(0); //Tells window server to coalesce mouse dragged events
    frq = 10 * exp (1.5 * LOG10);
    amp = .1;
    pvibFrq = 4.5;
    pvib = .01;
    rvib = .008;
    aNote = [[Note alloc] init];
    [self sine:self];
    return self;
}

- mouseDown:(NXEvent *) anEvent
{
    [fftView storeCurrent:self];
    [super mouseDown:anEvent];
    return self;
}

- sawTooth:sender
{
    int i;
    for(i=0;i<tableLength;i++)
      {
	  FuncTable[i] = (float)i/tableLength;
	  DSPTable[i] = DSP_FLOAT_TO_INT(MAXVALUE*(2*FuncTable[i] -1));  
      }
    [tableLook setData:DSPTable];           
    SEND_DSP_CMDS();
    [self display];
    [fftView receiveData:FuncTable length:tableLength];
    return self;
}

- triangle:sender
{
    int i;
    for(i=0;i<tableLength;i++)
      {
	  FuncTable[i] = ((i < tableLength/2) ? (float)i/tableLength*2 
			  :  1. - (float)(i - tableLength /2) / tableLength * 2 );
	  DSPTable[i] = DSP_FLOAT_TO_INT(MAXVALUE*(2*FuncTable[i]-1));  
      }
    [tableLook setData:DSPTable];           
    SEND_DSP_CMDS();
    [self display];
    [fftView receiveData:FuncTable length:tableLength];
    return self;
}

- sine:sender
{
    int i;
    for(i=0;i<tableLength;i++)
      {
	  FuncTable[i] = .5 + 0.5*sin((float)i/tableLength*2*M_PI) ;
	  DSPTable[i] = DSP_FLOAT_TO_INT(MAXVALUE*(2*FuncTable[i]-1));  
      }
    [tableLook setData:DSPTable];           
    SEND_DSP_CMDS();
    [self display];
    [fftView receiveData:FuncTable length:tableLength];
    return self;
}

- square:sender
{
    int i;
    for(i=0;i<tableLength;i++)
      {
	  FuncTable[i] = (float)(i < tableLength/2) ;  
	  DSPTable[i] = DSP_FLOAT_TO_INT(MAXVALUE*(2*FuncTable[i]-1));  
      }
    [tableLook setData:DSPTable];           
    SEND_DSP_CMDS();
    [self display];
    [fftView receiveData:FuncTable length:tableLength];
    return self;
}

- afterDrag:(float*)data length:(int)aLength offset:(int)anOffset
{
    int i;
    for(i=anOffset;i<anOffset + aLength;i++)
      {
	  DSPTable[i] = DSP_FLOAT_TO_INT (MAXVALUE*(2*data[i] - 1));
      }
    
    [tableLook setData:(DSPTable+anOffset) length:aLength offset:anOffset];
    SEND_DSP_CMDS();
    return self;
}

- afterUp:(float*)data length:(int)aLength
{
    [fftView receiveData:data length:aLength];
    return self;
}

-sendFreq:sender
{
    frq = 10 * exp ([sender floatValue] * LOG10);
    [aNote setPar:MK_freq toDouble:frq];
    [aSP noteUpdate:aNote];
    [aNote removePar:MK_freq];
    SEND_DSP_CMDS();
    return self;
}

-sendAmp:sender
{
    amp = .1 * exp ([sender floatValue]);
    [aNote setPar:MK_amp toDouble:amp];
    [aSP noteUpdate:aNote];
    [aNote removePar:MK_amp];
    SEND_DSP_CMDS();
    return self;
}

-sendRVib:sender
{
    rvib = .04 * MKMidiToAmp([sender floatValue]);
    if (!vibOn)
      return self;
    [aNote setPar:MK_rvibAmp toDouble:rvib];
    [aSP noteUpdate:aNote];
    [aNote removePar:MK_rvibAmp];
    SEND_DSP_CMDS();
    return self;
}

-sendPVib:sender
{
    pvib = .04 * MKMidiToAmp([sender floatValue]);
    if (!vibOn)
      return self;
    [aNote setPar:MK_svibAmp toDouble:pvib];
    [aSP noteUpdate:aNote];
    [aNote removePar:MK_svibAmp];
    SEND_DSP_CMDS();
    return self;
}

-sendPVibFreq:sender
{
    pvibFrq = [sender floatValue];
    [aNote setPar:MK_svibFreq toDouble:pvibFrq];
    [aSP noteUpdate:aNote];
    [aNote removePar:MK_svibFreq];
    SEND_DSP_CMDS();
    return self;
}

- setSound:sender
{
    int i;
    for(i=0;i<tableLength;i++)
      DSPTable[i] = DSP_FLOAT_TO_INT(MAXVALUE*(2*FuncTable[i]-1));  
    [tableLook setData:DSPTable length:tableLength offset:0];
    SEND_DSP_CMDS();
    return self;
}

- vibOnOff:sender
{
    BOOL newVibState = [[sender selectedCell] tag];
    double pa,ra;
    if (vibOn && !newVibState) 
      pa = ra = 0;
    else if (!vibOn && newVibState) {
	pa = pvib;
	ra = rvib;
    }
    else return self;
    [aNote setPar:MK_svibAmp toDouble:pa];
    [aNote setPar:MK_rvibAmp toDouble:ra];
    [aSP noteUpdate:aNote];
    SEND_DSP_CMDS();
    [aNote removePar:MK_svibAmp];
    [aNote removePar:MK_rvibAmp];
    vibOn = newVibState;
    return self;
}

@end
