/*
** Perhaps these routines should be the Synth Class routines and form
** defaults if no other classes accept the sys-ex message.
*/
#import "UnhandledSynth.h"

@implementation UnhandledSynth

// Declare ourselves a system exclusive message instance to channel
// the user strings to the synths.
- init
{
    [super init];
    userMessages = [[SysExMessage alloc] init];
    return self;
}

// Load the nib and bring up the Text ScrollView if we want to probe an unhandled synth rather
// than respond to a SysEx from the device.
- (id) initWithEmptyPatch
{
    [super initWithEmptyPatch];
    [self init];
    [super initWithWindowNibName: @"unhandled" owner:self];
    [[self window] makeKeyAndOrderFront:nil];     // make the window visible
    return self;
}

- (void) dealloc
{
    [userMessages release];
    [super dealloc];
}

// Append messages to the Text ScrollView
- (void) displayToText: (NSString *) msg
{
    NSRange selectedRange;
    int lastSelected;

    // Since we are modifying a NSTextView and the new update can come from a 
    // sysex message delivered asynchronously, we need to lock it.
    [sysExText lockFocusIfCanDraw];
    selectedRange = [sysExText selectedRange];
    lastSelected = NSMaxRange(selectedRange);
   
    [sysExText replaceCharactersInRange: NSMakeRange(lastSelected, 0) withString: msg];
    [sysExText unlockFocus];
}

// Catch the initialisation of the text scroll view so we can determine the NSTextView object
// and assign it to sysExText, set the delegate and the filter.
- (void) setScrollingDisplay: (id) aScroller
{
    scrollingDisplay = aScroller;    // really necessary? i.e is scrollingDisplay already set?
    sysExText = [aScroller documentView];
    [sysExText setDelegate:self];
    [sysExText setSelectable:YES];
    [sysExText setEditable:YES];
    [sysExText setFieldEditor: YES];
    [sysExText selectAll:self]; 
}

// Display the sysEx message to the text scroller.
// As this is a catchesAllMessages MIDISysExSynth, we will always want
// to process this sysex message, so we always return YES.
// Need to determine the type of msg and properly manage the export
- (BOOL) initWithSysEx: (SysExMessage *) msg
{
    [self initWithEmptyPatch];      // load and make the window visible

    // convert to a formatted ascii string
    [self displayToText: [NSString stringWithFormat: @"Bytes in message: %d\n", [msg length]]];
    [self displayToText: [msg exportToAscii: musicKitSysExSyntax]];
    [self displayToText: @"\n"];
    return YES;
}


// Return the NSTextView object
- (NSTextView *) text
{
    return sysExText;
}

// We are a catch-all synth
- (BOOL) catchesAllMessages
{
    return YES;
}

@end

@implementation UnhandledSynth(TextDelegate)

// Invoked each time a line of text is entered.
// Here we extract the last line and send it to MIDI as a valid system exclusive stream.
// However, should we allow illegal SysEx messages
// to be sent, i.e. half finished?, or should we just store up everything until we have a
// complete message then send that? (probably)
- (void) textDidEndEditing: (NSNotification *) aNotification
{
    NSString *textString;			// All of the text typed to date.
    NSString *lastHexStringEntered;
    NSRange  selectedRange;
    NSRange  startRange;
    NSRange  hexStringRange;
    unsigned int endLocation, startLocation, hexStringBegin;

// if aNotification // NSReturnTextMovement?

    textString = [sysExText string];             // get the string as stands
    selectedRange = [sysExText selectedRange];   // get entire selection (all chars typed)

    [textString getLineStart: &startLocation
                end:          NULL 
		contentsEnd:  &endLocation forRange: selectedRange];

    startRange = [textString rangeOfString: @"\n" 
                             options:       NSBackwardsSearch
                             range:         NSMakeRange(0, endLocation)];
    hexStringBegin = NSMaxRange(startRange);
    if (startRange.length == 0)
	hexStringRange = NSMakeRange(0, endLocation);
    else
        hexStringRange = NSMakeRange(hexStringBegin, endLocation - hexStringBegin);
    lastHexStringEntered = [textString substringWithRange: hexStringRange];

    if([lastHexStringEntered length] > 0) {
	[userMessages initWithString: lastHexStringEntered];
        [self displayToText:@"\n"];
	[userMessages send];
    }
}

@end
