/* 
  $Id$

  Description:
    MidiLoop is an example of a MusicKit performance where the interactive
    response time needs to be as fast as possible, even if at the expense of 
    a bit of timing indeterminacy. Therefore, the MKConductor is clocked and 
    MKMidi is untimed (i.e. no delays are introduced in the MKMidi object). 
    The MKConductor is also set to not 'finishWhenEmpty'. This ensures the 
    performance will continue, whether or not the MKConductor has 
    any messages to send, until the user decides to terminate the 
    performance. The MKMidi object is set to not 'useInputTimeStamps' because
    we are interested in producing regular echoes (using the Conductor's notion
    of time), rather than in recording the exact time the MIDI entered the 
    MIDI device driver. 

  Portions Copyright (c) 1999-2005, The MusicKit Project.  All rights reserved.
  
    Permission is granted to use and modify this code for commercial and 
    non-commercial purposes so long as the author attribution and copyright 
    messages remain intact and accompany all relevant code.
*/

#import "MidiLoop.h"

@implementation MidiLoop

- (IBAction) showInfoPanel: (id) sender
{
    // TODO platform specific bundle searching disabled/broken on 4K46?
    // [NSBundle loadNibNamed: @"Info" owner: self];
    [NSBundle loadNibNamed: @"Info-macos" owner: self];
    [infoPanel makeKeyAndOrderFront: sender];
}

static void handleMKError(NSString *msg)
{
    if (!NSRunAlertPanel(@"MidiLoop", msg, @"OK", @"Quit", nil, NULL))
	[NSApp terminate: NSApp];
}

- (IBAction) go: (id) sender
{
    int i;
    
    if ([MKConductor inPerformance]) /* Already started */
        return;
    if(midiObj)
        [midiObj release];
    midiObj = [[MKMidi midi] retain];

    MKSetErrorProc(handleMKError); /* Intercept Music Kit errors. */

    /* 16 midi channels plus one for system messages */
    for (i = 0; i <= 16; i++) 
	/* Connect them up */
	[[midiObj channelNoteSender: i] connect: [midiObj channelNoteReceiver: i]];

    /* No delay in sending out midi out events */
    [midiObj setOutputTimed: NO];  

    /* Just wait until terminate */
    [MKConductor setFinishWhenEmpty: NO];  

    /* Boost priority of performance. */ 
    [MKConductor setThreadPriority: 1.0];

    /* Start MIDI clock */
    [midiObj run];                

    /* Start the Performance */
    [MKConductor startPerformance];
}

- (void) applicationWillTerminate: (NSNotification *) aNotification
{
    /* Finish up */
    [MKConductor finishPerformance];
    
    /* Close the MIDI device */
    [midiObj close];
}

@end
