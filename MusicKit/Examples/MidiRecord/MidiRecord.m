#import "MidiRecord.h"

@implementation MidiRecord

#import <AppKit/NSSavePanel.h>
#import <synthpatches/synthpatches.h>

/* MidiRecord is an example of an interactive Music Kit performance.
   Therefore, the Conductor is clocked. The Conductor is also set to not 
   'finishWhenEmpty'. This ensures the performance will continue, whether or 
   not the Conductor has any objective-c messages to send, 
   until the user decides to terminate the performance. Finally, we set
   the midi object to 'useInputTimeStamps' so that the times written to the
   output file are as precise as possible. */

static BOOL needsUpdate = NO;

static void handleMKError(char *msg) {
    if (!NSRunAlertPanel(@"MidiRecord", [NSString stringWithCString:msg], @"OK", @"Quit", nil, NULL))
	[NSApp terminate:NSApp];
}

- _start
    /* This method sets things up and begins the performance. */
{
    id partRecorders,aPart,info;
    int i;

    needsUpdate = YES;
    MKSetErrorProc(handleMKError);
    [saveAsMenuItem setEnabled:YES]; /* Something to save now. */
    [score release];                  /* Free old score, parts and notes. */
    score = [[Score alloc] init];  /* Make a new Score to store Notes */
    for (i = 0; i<17; i++) {       /* 16 channels and one for system msgs */
	aPart =[[Part alloc] init];/* Make a new Part for each channel */

	/* Each Part has an 'info' MKNote which contains some special info
	   for that Part. In this case we put the midiChan there. */
	info = [[MKNote alloc] init];
	if (i != 0)  {               /* The 0th 'channel' is our 'sys' Part */
	    [info setPar:MK_midiChan toInt:i]; 
	    [info setPar:MK_synthPatch toString:"midi"]; 
	}
	[aPart setInfo:info];
	[score addPart:aPart];     /* Add the Part to the Score. */
    }
    scoreRecorder = [[ScoreRecorder alloc] init];

    /* ScoreRecorder is an Instrument that collects Notes and writes
       them to a Score. */
    [scoreRecorder setScore:score];

    /* ScoreRecorder automatically creates a PartRecorder for each Part in 
       the Score. The -partRecorders method returns a List object. */
    partRecorders = [scoreRecorder partRecorders]; 
    midiIn = [Midi midi];           /* Get the Midi object for the default serial port (port A on NeXT hardware) */

    /* Connect the outputs of the Midi object to the inputs of each of 
       the PartRecorders. */
    for (i = 0; i<17; i++)         
	[[midiIn channelNoteSender:i] connect:
	 [[partRecorders objectAt:i] noteReceiver]];
      
    [partRecorders release];               /* List is copied above so free here */
    [midiIn setUseInputTimeStamps:YES]; /* We want MIDI driver's time stamps */
    [midiIn openInputOnly];             /* We don't need MIDI output so we
					   specify 'input only' */

    [MKConductor setFinishWhenEmpty:NO];  /* Tell MKConductor not to quit when it 
					   has no more scheduled events.
					   Instead, tell it to wait until 
					   finishPerformance is received */
    [midiIn run];                  /* Start midi clock */
    [MKConductor startPerformance];  /* Start the performance */
    return self;
}

static char scoreFilePath[MAXPATHLEN+1] = "";
static char scoreFileDir[MAXPATHLEN+1] = "";
static char scoreFileName[MAXPATHLEN+1] = "";
static id savePanel = nil;

-_finish
  /* This method is used to write the file and finish the performance. */
{
    [MKConductor finishPerformance];/* End the performance */
    [midiIn close];               /* Close the midi device */
    [scoreRecorder release];         /* Also frees contained PartRecorders */
    return self;
}

- (void)go:sender
  /* This method is invoked when the button is pushed. */ 
{
    if ([MKConductor inPerformance]) { /* We're already performing */
	[theButton setTitle:@"Start recording"];   /* Change the button name */
	[self _finish];              /* Write file and end performance. */
    } else  {                        /* New performance */
	[theButton setTitle:@"Stop recording"];    /* Change the button name */
	[self _start];               /* Start things up */
    } 
}

static BOOL getSavePath(char *returnBuf, char *dir, char *name)
{
    if (!savePanel) {
#warning FactoryMethods: [SavePanel savePanel] used to be [SavePanel new].  Save panels are no longer shared.  'savePanel' returns a new, autoreleased save panel in the default configuration.  To maintain state, retain and reuse one save panel (or manually re-set the state each time.)
	savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:@"MidiRecord Save"];
    }
    [savePanel setRequiredFileType:@"score"];
    if ([savePanel runModalForDirectory:@"" file:@""])  {
	strcpy(returnBuf,[[savePanel filename] cString]);
	return YES;
    }
    else return NO;
}

- (void)saveAs:sender
{
    if (sender != self)
	if (!getSavePath(scoreFilePath,scoreFileDir, scoreFileName)) 
	    return;
	else [saveMenuItem setEnabled:YES];   /* We have a default now. */
    if ([MKConductor inPerformance])
	[self go:self];                       /* End performance. */
    [myWindow setTitle:[NSString stringWithCString:scoreFilePath]];
    [myWindow display];
    [score writeScorefile:scoreFilePath];     /* Write the file. */
    needsUpdate = NO; 
}

- (void)save:sender
{
    return [self saveAs:(strlen(scoreFilePath) > 0) ? self : nil];
}

- (void)showInfoPanel:sender
{
    [NSBundle loadNibNamed:@"Info.nib" owner:self];
    [infoPanel orderFront:sender]; 
}

- (void)terminate:(id)sender
  /* Sent from 'quit' option in menu. Terminates the app. */
{
    if ([MKConductor inPerformance]) 
	[self _finish];
    if (needsUpdate)
        if (NSRunAlertPanel(@"MidiRecord", @"Save file before quitting?", @"Yes", @"No", nil))
	    [self save:self];
    [super terminate:self];
}

@end
