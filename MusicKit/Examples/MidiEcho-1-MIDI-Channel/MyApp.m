#import <appkit/appkit.h>
#import "MyApp.h"

/* MidiEcho is an example of a Music Kit performance where the interactive
   response time needs to be as fast as possible, even if at the expense of 
   a bit of timing indeterminacy. Therefore, the Conductor is clocked and 
   Midi is untimed (i.e. no delays are introduced in the Midi object). 
   The Conductor is also set to not 'finishWhenEmpty'. This ensures the 
   performance will continue, whether or not the Conductor has 
   any objective-c messages to send, until the user decides to terminate the 
   performance. The Midi object is set to not 'useInputTimeStamps' because
   we are not interested in the exact time the MIDI entered the computer, as
   we would be if we were recording the MIDI (See MidiRecord). */

@implementation MyApp

#import <appkit/Application.h>
#import <musickit/musickit.h>
#import "EchoFilter.h"

static char *dev = "midi1"; /* Serial port B -- the default. */
static float delay = .1;

static void handleMKError(char *msg)
{
    if (!NXRunAlertPanel("MidiEcho",msg,"OK","Quit",NULL,NULL))
	[NXApp terminate:NXApp];
}

- showInfoPanel:sender
{
    [self loadNibSection:"Info.nib" owner:self];
    [infoPanel orderFront:sender];
    return self;
}

- go:sender
{
    if ([Conductor inPerformance])  
    	return self;

    MKSetErrorProc(handleMKError); /* Intercept Music Kit errors. */
       
    /* Get Midi object for the specified serial port. */
    midi = [Midi newOnDevice:dev];

    /* Open it for input and output */
    [midi open];

    /* We use a NoteFilter subclass to make the echoes. */
    myFilter = [[EchoFilter alloc] init];
    [myFilter setDelay:delay];

    /* Connect up the Midi NoteSender for channel 1 to the NoteReceiver
       of the NoteFilter.  Connect up the NoteFilter noteSender to the  
       NoteReceiver of Midi for channel 1. */
    [[midi channelNoteSender:1] connect:[myFilter noteReceiver]];
    [[myFilter noteSender] connect:[midi channelNoteReceiver:1]];

    /* No delay in sending out midi out events */      
    [midi setOutputTimed:NO];     

    /* The driver's time stamps are not useful in this application */
    [midi setUseInputTimeStamps:NO]; 

    /* Boost priority of performance. */ 
    [Conductor setThreadPriority:1.0];

    /* Tell Conductor not to quit when there are no more scheduled messages.
       We are often in the 'empty' state, waiting for the next MIDI message.
       */
    [Conductor setFinishWhenEmpty:NO];   

    /* Start up Midi */
    [midi run];

    /* Start the Conductor  */
    [Conductor startPerformance];
    return self;
}

- setMidiDev:sender
{
    if ([[sender selectedCell] tag])
	dev = "midi0";
    else dev = "midi1";
    if ([Conductor inPerformance]) { /* Already started? */
	[Conductor finishPerformance];
	[midi close];
	[midi free];    
	[myFilter free];
	myFilter = nil;
	[self go:self]; /* Start us up again. */
    }
    return self;
}

- setDelayFrom:sender
  /* This is invoked from the text field. Sets the delay used by the NoteFilter
   */
{
    delay = [sender floatValue];
    [myFilter setDelay:delay];
    return self;
}

@end
