#import "MyApp.h"

/* MidiPlay is an example of an interactive Music Kit performance.
   Therefore, the Conductor is clocked. The Conductor is also set to not 
   'finishWhenEmpty' to ensure the performance will continue, whether or 
   not the Conductor has any objective-c messages to send, 
   until the user decides to terminate the performance.  

   In this case, we are interested in a fast interactive response; 
   therefore, we set the delta time to a very small number (using 
   MKSetDeltaT()). 

   Beware that using very small delta times can cause some unpredictability. 
   You can cause your performance to be more predictable at the expense of 
   greater latency by increasing the delta time. You may also want to 
   experiment with untimed mode (see Orchestra.h), which can give better 
   response, but at the expense of decreased predictability. 

   MIDI pitch bend data is thinned out by sending it through a subclass of
   NoteFilter.

   Please note that the SynthPatches in the Music Kit SynthPatch library
   are not optimized for real time applications such as this one.
*/

@implementation MyApp

#import "MidiFilter.h"

#import <appkit/Application.h>
#import <musickit/musickit.h>
#import <musickit/synthpatches/synthpatches.h>
#import <objc/NXStringTable.h>
#define STRINGVAL(_x) [stringTable valueForStringKey:_x]

static void handleMKErrors(char *msg)
{
    if ([Conductor inPerformance]) /* Don't disturb performance. */
	return;
    else if (!NXRunAlertPanel("MidiPlay",msg,"OK","Quit",NULL,NULL))
	[NXApp terminate:NXApp];
}

#define VOICES 5

- showInfoPanel:sender
{
    [self loadNibSection:"Info.nib" owner:self];
    [infoPanel orderFront:sender];
    return self;
}

static id orch = nil;

- go:sender
{
    id synthIns,aNote;
    id myMidiFilter;

    /* We're already running */
    if ([Conductor inPerformance]) 
	return nil;
    
    [Conductor setThreadPriority:1.0];    /* Boost priority of performance. 
					     If you run as root, this will
					     also change your thread policy
					     to use non-degrading priorities. */

    /* Disable error printing. We don't want error print-out to slow us down */
    MKSetErrorProc(handleMKErrors);      

    /* Make a Midi object to get events from serial port A. */ 
    midiIn = [Midi new];

    /* Make a SynthInstrument to do voice (SynthPatch) management. */
    synthIns = [[SynthInstrument alloc] init];

    /* Connect Midi to the SynthInstrument by way of a note filter. */
    myMidiFilter = [[MidiFilter alloc] init];
    [[midiIn channelNoteSender:1] connect:[myMidiFilter noteReceiver]];
    [[myMidiFilter noteSender] connect:[synthIns noteReceiver]];
    [midiIn openInputOnly];

    /* Create the Orchestra, if it doesn't exist yet,
	which manages DSP resources. */
    orch = [Orchestra new];

    /* Set some variables for all Orchestras. */
    MKSetDeltaT(0.01); /* See comment above. */

    [orch setSamplingRate:44100.0]; /* High sampling rate gives faster
					    response (in current release). */
    [orch setFastResponse:YES];     /* Use small sound-out buffers */

    /* You must first open the Orchestra before allocating SynthPatches */
    while (![orch open]) {               
	if (NXRunAlertPanel("MidiPlay",
			    STRINGVAL("DSPUnavailable"),
			    STRINGVAL("Quit"),
			    STRINGVAL("TryAgain"),
			    NULL) == NX_ALERTDEFAULT)
	    [self terminate:sender];
    }

    /* Specify the SynthPatch to use. Here we use Pluck. */
    [synthIns setSynthPatchClass:[Pluck class]];

    /* Specify manual allocation mode and number of simultaneous notes */ 
    [synthIns setSynthPatchCount:VOICES];

    [Conductor setFinishWhenEmpty:NO];    /* Just wait until terminate */

    /* Next we set a few default parameters. */
    aNote = [[Note alloc] init];      
    [aNote setNoteType:MK_noteUpdate];

    /* Set pitch bend to be plus or minus 1 semi tone. */
    [aNote setPar:MK_pitchBendSensitivity toDouble:1.0]; 
    
    /* The following is optional. It helps make the pitch bend smoother for 
       Pluck -- by specifying the lowest frequency, Pluck always allocates 
       more than it needs (assuming the frequency never goes below 100 Hz.) */
    [aNote setPar:MK_lowestFreq toDouble:100.0];

    /* Set the brightness. Brightness is scaled by MIDI velocity. */
    [aNote setPar:MK_bright toDouble:.75];

    /* Now send the updates. */
    [[synthIns noteReceiver] receiveNote:aNote]; 
    
    /* Now start up the DSP, Midi and the Conductor. */

    [orch run];
    [midiIn run];
    [Conductor startPerformance];
    return self;
}

- terminate:sender
{
    [Conductor finishPerformance];
    [midiIn close];
    [orch close];
    [super terminate:self];
    return self;
}

@end
