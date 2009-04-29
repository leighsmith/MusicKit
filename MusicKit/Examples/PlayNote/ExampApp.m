/* 
   MusicKit programming example

   This example illustrates real-time DSP control. The interface has a button
   for playing a note with a plucked-string timbre, and a slider to change its
   pitch.


   PlayNote is an example of an interactive MusicKit performance.
   Therefore, the Conductor is clocked. The Conductor is also set to not 
   'finishWhenEmpty' to ensure the performance will continue, whether or 
   not the Conductor has any objective-c messages to send, 
   until the user decides to terminate the performance.  In this case, we are 
   interested in the fastest possible interactive response; therefore, we
   set the delta time to a very small number (using MKSetDeltaT()). Beware
   that using very small delta times can cause some unpredictability. You
   can cause your performance to be more predictable at the expense of 
   greater latency by increasing the delta time.

     In this example, a MusicKit MKSynthPatch is used with a MKSynthInstrument.
       
       However, the SynthInstrument, the main purpose of which is to do voice 
       allocation, is not really needed in this simple case. We could have 
       done our own SynthPatch management. Here's how the above code could be 
       changed if a SynthInstrument were NOT used:
       
       1. Remove the variable theIns and add a variable called theSynthPatch.
       
       2. In the -init method, replace the lines 
       
       theIns = [[SynthInstrument alloc] init];
       [theIns setSynthPatchClass:[Pluck class]];   
       [theIns setSynthPatchCount:1];	
       
       with the following:
       
       theSynthPatch = [Orchestra allocSynthPatch:[Pluck class]];
       
       3. In the method -_sendNote:, replace the line
       
       [[theIns noteReceiver] receiveNote:aNote]; 
       
       with the following:
       
       if ([aNote noteType] == MK_noteOn)
           [theSynthPatch noteOn:aNote];
       else [theSynthPatch noteUpdate:aNote];
       
       4. In the method terminate:, before closing the Orchestra, add the line 
       
       [theSynthPatch dealloc];
       
*/

#import <Appkit/Appkit.h>
#import <MusicKit/MusicKit.h>
#import <MKSynthPatches/Pluck.h>
#import <MusicKit/Pitches.h>
#import "ExampApp.h"

#define DEFAULTFREQ 440

static MKNote *theNote,*theNoteUpdate;
static MKOrchestra *theOrch;
static MKSynthInstrument *theIns;
static double freq;  	        /* frequency in Hz */
static float transposition;     /* shift in semitones (units of 1/12 octave) */

@implementation ExampApp

static void handleMKError(char *msg) {
    if (!NXRunAlertPanel("PlayNote",msg,"OK","Quit",NULL,NULL))
	[NXApp terminate:NXApp];
}
  
- appDidInit: sender;
{
    MKSetErrorProc(handleMKError); /* Intercept music kit errors. */

    /* this is used for all note-ons */
    theNote = [[MKNote alloc] init];

    /* we don't send any note-offs */
    [theNote setNoteType: MK_noteOn]; 	

    /* All notes are considered to be part of a single phrase. 
       That means we can send the same noteOn type Note and it 
       will retrigger the same SynthPatch. */
    [theNote setNoteTag: MKNoteTag()];      

    /* maximum amplitude */
    [theNote setPar: MK_amp toDouble: 1.0];  

    /* let the Pluck instrument know the lowest possible frequency
       in order to allocate enough delay memory at the beginning of the 
       phrase. */
    [theNote setPar: MK_lowestFreq toDouble: g2];   

    /* used to immediately update the frequency during the course of a 
       note */
    theNoteUpdate = [[MKNote alloc] init];
    [theNoteUpdate setNoteType: MK_noteUpdate]; 

    /* We set the noteTag of the noteUpdate to be the same as the noteOn,
       in order to affect the same sound */
    [theNoteUpdate setNoteTag: [theNote noteTag]]; 
    freq = DEFAULTFREQ;

    /* Create the Orchestra which manages all DSP activity. */
    theOrch = [MKOrchestra new];

#ifdef DEBUG
    [theOrch setOnChipMemoryConfigDebug:YES patchPoints:0];
    DSPEnableErrorFile("/dev/tty");
    // extern int _DSPVerbose; _DSPVerbose = 1;
#endif

    /* Send DSP updates with time stamps very close to the Conductor's time. */
    MKSetDeltaT(0.01); /* See comment above. */

    /* Set the sound-out buffer size to be small. This uses somewhat more CPU
       cycles and leaves the DSP with a smaller "rubber band" in return for a 
       faster response time. */
    [MKOrchestra setFastResponse: YES]; 

    /* Opening the Orchestra instance has the effect of claiming the DSP
       and allowing us to allocate Orchestra resources. */
    if (![theOrch open]) {               
	fprintf(stderr,"Can't open DSP. Perhaps some other process has it.\n");
	exit(1);
    }

    /* Create a MKSynthInstrument to manage MKSynthPatches. */
    theIns = [[MKSynthInstrument alloc] init];

    /* In this case we use the MKSynthPatch class Pluck. Thus, theIns manages
       instances of Pluck. Pluck implements a plucked-string synthesis  
       model (see <MKSynthPatches/Pluck.h> for more info.) */
    [theIns setSynthPatchClass: [Pluck class]];   

    /* only one note at a time */
    [theIns setSynthPatchCount: 1];	

    /* don't quit when the MKConductor's messages-to-send queue is
       empty, since we wait for the user to click the button for new 
       notes */
    [MKConductor setFinishWhenEmpty: NO];
   
    /* Run the performance in a separate thread to maximize independence
       of music and user interface. */
    [MKConductor useSeparateThread: YES];
   
    [MKConductor setThreadPriority: 1.0];     /* Boost priority of performance */

    /* Start the DSP running */
    [theOrch run];				

    /* Start the performance. */
    [MKConductor startPerformance];        
    return self;
}

#define PLAY(aNote) [[theIns noteReceiver] receiveNote: aNote] 

- playNote: sender
{
    [MKConductor lockPerformance];	     /* Prepare to send MK message */
    [theNote setPar: MK_freq toDouble: freq];  /* use the current frequency. */
    PLAY(theNote); 
    [MKConductor unlockPerformance];	     /* End of MK message block */
    return self;
}

- bendPitch: sender
{    
    transposition = [sender floatValue];	  /* -12 to +12 semitones */
    freq =  DEFAULTFREQ * pow(2, transposition / 12.0);         /* in Hz */
    [MKConductor lockPerformance];
    [theNoteUpdate setPar: MK_freq toDouble: freq]; 
    PLAY(theNoteUpdate);
    [MKConductor unlockPerformance];
    return self;
}

- terminate: sender
{
    [MKConductor lockPerformance];
    [MKConductor finishPerformance];       
    [MKConductor unlockPerformance];
    [theOrch close];     /* Free MKOrchestra resources and release the DSP. */ 
    return [super terminate: self];
}

- showInfoPanel: sender
{
    [self loadNibSection: @"Info.nib" owner: self];
    [infoPanel orderFront: sender];
    return self;
}

@end


