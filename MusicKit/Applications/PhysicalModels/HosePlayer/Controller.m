
/* Generated by Interface Builder */

#import <AppKit/AppKit.h>
#import <SndKit/SndKit.h>
#import <MusicKit/MusicKit.h>
#import "Controller.h"
#import "HoseIns.h"
#import <math.h>
//#import <mach/time_stamp.h>

//    #define MINLENGTH 189.2				// In an otherwise perfect world
//    #define MAXLENGTH 267.57

#define MINLENGTH 160
#define MAXLENGTH 240

static MKNote *theNote,*theNoteOff,*theNoteUpdate;
static MKOrchestra *theOrch;
static MKSynthInstrument *theIns;
static MKMidi *midiIn;

@implementation Controller

- (void)play:sender
{
    int		MY_outAmp = [[MKNote class] parName: @"MY_outAmp"];
    int		MY_dLineLength = [[MKNote class] parName: @"MY_dLineLength"];
    int		MY_lipCoeff1 = [[MKNote class] parName: @"MY_lipCoeff1"];
    int		MY_lipCoeff2 = [[MKNote class] parName: @"MY_lipCoeff2"];
    int		MY_lipFiltGain = [[MKNote class] parName: @"MY_lipFiltGain"];
    double xAmpArray[] = {0.0,0.2,1.0,2.0}; 
    double yAmpArray[] = {0.0,0.0,1.0,0.0};
    id ampEnvelope;

    if ([sender state] == 1)	{

        if (! theNote) 	{
  	    theNote = [MKNote new];			
	    theNoteUpdate = [MKNote new];
	    theNoteOff = [MKNote new];
            theIns = [MKSynthInstrument new];
            theOrch = [MKOrchestra new];          
	    [theOrch setSamplingRate: 22050.0];
	    ampEnvelope = [MKEnvelope new];
	    [ampEnvelope setPointCount:4 xArray:xAmpArray yArray:yAmpArray];
	    [ampEnvelope setStickPoint:2];
	
    	    midiIn = [MKMidi new];
//	    [myMidiHandler init];
	    [[midiIn channelNoteSender:1] connect:[myMidiHandler noteReceiver]];
//	    [[myMidiFilter noteSender] connect:[synthIns noteReceiver]];
	    [midiIn openInputOnly];

	    [theNote setNoteType:MK_noteOn]; 	
	    [theNote setNoteTag:MKNoteTag()];      
	    [theNoteUpdate setNoteType:MK_noteUpdate]; 
	    [theNoteUpdate setNoteTag:[theNote noteTag]]; 
	    [theNoteOff setNoteType:MK_noteOff]; 
	    [theNoteOff setNoteTag:[theNote noteTag]]; 
	    MKSetDeltaT(.01) ;           
	    [MKOrchestra setFastResponse:YES]; 
	    [MKOrchestra setTimed:NO]; 
	     if (![theOrch open]) {               
	    fprintf(stderr,"Can't open DSP. Perhaps some other process has it.\n");
		exit(1);
	    }
	    [theIns setSynthPatchClass:[HoseIns class]];   
	    [theIns setSynthPatchCount:1];	
	    [MKConductor setFinishWhenEmpty:NO];
//	[MKConductor useSeparateThread:YES];
//	[MKConductor setThreadPriority:1.0];     /* Boost priority of performance */
	    [theOrch run];				
            [midiIn run];
	    [MKConductor startPerformance];    
	    [MKConductor lockPerformance];	     /* Prepare to send MK message */
	    [theNote setPar:MK_portamento toDouble: 0.5];   
	    [theNote setPar:MK_ampEnv toEnvelope:ampEnvelope];
    	    [theNoteUpdate setPar:MK_amp1 toDouble: 0.5];  

	    [theNote setPar:MY_outAmp toDouble: 0.2];
	    [theNote setPar:MY_dLineLength toDouble: MINLENGTH];
	    [theNote setPar:MY_lipCoeff1 toDouble: -1.99];
	    [theNote setPar:MY_lipCoeff2 toDouble: 0.99];
	    [theNote setPar:MY_lipFiltGain toDouble: 0.01];

	    [[theIns noteReceiver] receiveNote:theNote];
	    [MKConductor unlockPerformance];

        }	
	[self changeLip:lipPots];
    }
    else	{
        [MKConductor lockPerformance];
	[[theIns noteReceiver] receiveNote:theNoteOff];
	[theNote release];
	[theNoteUpdate release];
	[theNoteOff release];
	[MKConductor finishPerformance];       
	[MKConductor unlockPerformance];
    } 
}

- (void)changeVelocity:(double)velocity;
{
    int		MY_envelopeSlew = [[MKNote class] parName: @"MY_envelopeSlew"];
    double temp;
    [MKConductor lockPerformance];
    temp = (velocity - 128.0) / 128.0;
    [theNoteUpdate setPar:MY_envelopeSlew toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
}

- (void)changeAmps:sender
{
    int		MY_outAmp = [[MKNote class] parName: @"MY_outAmp"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = [[sender cellAtRow:0 column:0] doubleValue];
    [theNoteUpdate setPar:MK_amp1 toDouble: temp];  
    temp = [[sender cellAtRow:1 column:0] doubleValue];
    [theNoteUpdate setPar:MY_outAmp toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance]; 
}

- changeAmpsQuick: (double) inValue : (double) outValue
{
    int		MY_outAmp = [[MKNote class] parName: @"MY_outAmp"];
    double temp;
    
    [MKConductor lockPerformance];
    [theNoteUpdate setPar:MK_amp1 toDouble: inValue];  
    [theNoteUpdate setPar:MY_outAmp toDouble: outValue];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- (void)changeLip:sender
{
    int		MY_lipCoeff1 = [[MKNote class] parName: @"MY_lipCoeff1"];
    int		MY_lipCoeff2 = [[MKNote class] parName: @"MY_lipCoeff2"];
    int		MY_lipFiltGain = [[MKNote class] parName: @"MY_lipFiltGain"];
    double lipC1,lipC2,lipGain,mass,sprConstant,damping,deltaT;
    
    deltaT = 1.0 / 22050.0;
    mass = [[lipPots cellAtRow:0 column:0] doubleValue];
    sprConstant = [[lipPots cellAtRow:0 column:1] doubleValue];
    damping = [[lipPots cellAtRow:0 column:2] doubleValue];
    [[lipFields cellAtRow:0 column:0] setDoubleValue:mass];
    [[lipFields cellAtRow:1 column:0] setDoubleValue:sprConstant];
    [[lipFields cellAtRow:2 column:0] setDoubleValue:damping];
    lipC1 = -2.0 + (((sprConstant * deltaT ) + damping) * deltaT / mass);
    lipC2 = 1.0 - (damping * deltaT / mass);
    lipGain = deltaT / mass;
//    printf("Coefficients = %f    %f\n",lipC1,lipC2);
    [MKConductor lockPerformance];
    [theNoteUpdate setPar:MY_lipCoeff1 toDouble: lipC1];  
    [theNoteUpdate setPar:MY_lipCoeff2 toDouble: lipC2];  
    [theNoteUpdate setPar:MY_lipFiltGain toDouble: lipGain];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance]; 
}

- changeLipQuick: (double) massValue : (double) springValue;
{
    int		MY_lipCoeff1 = [[MKNote class] parName: @"MY_lipCoeff1"];
    int		MY_lipCoeff2 = [[MKNote class] parName: @"MY_lipCoeff2"];
    int		MY_lipFiltGain = [[MKNote class] parName: @"MY_lipFiltGain"];
    double lipC1,lipC2,lipGain,mass,sprConstant,damping,deltaT;
    
    deltaT = 1.0 / 22050.0;
    mass = massValue;
    sprConstant = springValue;
    damping = [[lipPots cellAtRow:0 column:2] doubleValue];
    lipC1 = -2.0 + (((sprConstant * deltaT ) + damping) * deltaT / mass);
    lipC2 = 1.0 - (damping * deltaT / mass);
    lipGain = deltaT / mass;
//    printf("Coefficients = %f    %f\n",lipC1,lipC2);
    [MKConductor lockPerformance];
    [theNoteUpdate setPar:MY_lipCoeff1 toDouble: lipC1];  
    [theNoteUpdate setPar:MY_lipCoeff2 toDouble: lipC2];  
    [theNoteUpdate setPar:MY_lipFiltGain toDouble: lipGain];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance];
    return self;
}

- (void)changeSlide:sender
{
    int		MY_dLineLength = [[MKNote class] parName: @"MY_dLineLength"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = [[sender selectedCell] doubleValue];
    [[sender cellAtRow:0 column:0] setDoubleValue:temp];
    [[sender cellAtRow:1 column:0] setDoubleValue:temp];
    temp = MINLENGTH + (MAXLENGTH - MINLENGTH) * temp;
    [theNoteUpdate setPar:MY_dLineLength toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance]; 
}

- (void)changeSlideQuick:(double)value
{
    int		MY_dLineLength = [[MKNote class] parName: @"MY_dLineLength"];
    double temp;
    
    [MKConductor lockPerformance];
    temp = value;
    temp = MINLENGTH + (MAXLENGTH - MINLENGTH) * temp;
    [theNoteUpdate setPar:MY_dLineLength toDouble: temp];  
    [[theIns noteReceiver] receiveNote:theNoteUpdate];
    [MKConductor unlockPerformance]; 
}
@end
