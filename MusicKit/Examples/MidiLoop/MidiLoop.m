/* 
  $Id$

  Description:
   MidiLoop is an example of a Music Kit performance where the interactive
   response time needs to be as fast as possible, even if at the expense of 
   a bit of timing indeterminacy. Therefore, the Conductor is clocked and 
   Midi is untimed (i.e. no delays are introduced in the Midi object). 
   The Conductor is also set to not 'finishWhenEmpty'. This ensures the 
   performance will continue, whether or not the Conductor has 
   any messages to send, until the user decides to terminate the 
   performance. The Midi object is set to not 'useInputTimeStamps' because
   we are interested in producing regular echoes (using the Conductor's notion
   of time), rather than in recording the exact time the MIDI entered the 
   MIDI device driver. 
*/

#import "MidiLoop.h"

@implementation MidiLoop

- showInfoPanel:sender
{
    [NSBundle loadNibNamed:@"Info.nib" owner:self];
    [infoPanel orderFront:sender];
    return self;
}

static void handleMKError(NSString *msg)
{
    if (!NSRunAlertPanel(@"MidiLoop", msg, @"OK", @"Quit", nil, NULL))
	[NSApp terminate:NSApp];
}

- go: sender
{
    int i;
    if ([MKConductor inPerformance]) /* Already started */
      return self;
    if(midiObj)
        [midiObj release];
    midiObj = [[MKMidi midi] retain];

    MKSetErrorProc(handleMKError); /* Intercept Music Kit errors. */

    /* 16 midi channels plus one for system messages */
    for (i = 0; i <= 16; i++) 
	/* Connect them up */
	[[midiObj channelNoteSender:i] connect: [midiObj channelNoteReceiver:i]];

    /* No delay in sending out midi out events */
    [midiObj setOutputTimed:NO];  

    /* Just wait until terminate */
    [MKConductor setFinishWhenEmpty:NO];  

    /* Boost priority of performance. */ 
    [MKConductor setThreadPriority:1.0];

    /* Start MIDI clock */
    [midiObj run];                

    /* Start the Performance */
    [MKConductor startPerformance];
    return self;
}

- (void) applicationWillTerminate: (NSNotification *) aNotification
{
    /* Finish up */
    [MKConductor finishPerformance];
    
    /* Close the MIDI device */
    [midiObj close];
}

@end
