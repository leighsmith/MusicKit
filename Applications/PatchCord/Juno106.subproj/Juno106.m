/*
 * Class declaring Roland Juno 106 SubtractiveSynth patch management.
 * Leigh Smith 20/6/95
 */
#import "Juno106.h"
//#import "misckit/MiscSliderField.h"  // we use Normal sliders instead
//#import "misckit/MiscValueField.h"  // we use Normal value fields instead

#define ROLAND          0x41
#define PATCHCHG        0x30	  // values in Juno-106 Sys-Ex message
#define MANUAL          0x31
#define CTRLCHG	        0x32
#define JUNO_HEADER	5	  // No of bytes preceding the patch info
#define MIDI_CHAN       3	  // position in the SysEx messages for the MIDI channel
#define PATCH_NUM       4         // position in the SysEx patch
				  // message for the MIDI channel
#define UPDATE_PARAM_NO 4
#define UPDATE_PARAM	5
#define SWITCH_1        16	  // Parameter numbers corresponding to
#define SWITCH_2        17	  // switch bytes 1 & 2

@implementation Juno106
	
// just a private common way to do this for the two following methods.
- (void) loadAndShowNib
{
    NSWindow *junoWindow;
    NSColor *junoBackgroundGrey = [NSColor colorWithDeviceRed: .047 green: .1294 blue: .0784 alpha: 1.0];

    [super initWithWindowNibName: @"juno106" owner:self];
    junoWindow = [self window];
    [junoWindow setDocumentEdited: NO];
    [junoWindow setBackgroundColor: junoBackgroundGrey];
    [self displayPatch];
}

// Ideally init should just call initWithEmptyPatch, but the question is how we unbundle ourselves and not display the Nib file at the same time.

// Create ourselves a SysExMessage to transmit our parameter updates.
- init
{
    [super init];
// update = [[[SysExMessage alloc] init] retain];
    update = [[SysExMessage alloc] init];
    [update initWithString:@"f0,41,32,00,00,00,f7"];
    return self;
}

// Create a new empty instance of a patch and download it and display it
- (id) initWithEmptyPatch
{
    [self init];
    [super initWithEmptyPatch];
    [patch initWithString:@"f0,41,30,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,f7"];
    // Need to do something with Channel semantics here.
    [self loadAndShowNib];
    return self;
}

// Set and display a new patch.
- (void) acceptNewPatch: (SysExMessage *) msg
{
    [super acceptNewPatch:msg];
    [self setMidiChannel:[msg messageByteAt: MIDI_CHAN]];
    [self loadAndShowNib];
}

// Given a sys-ex message, returns YES if it's updating a Juno106 parameter.
- (BOOL) isParameterUpdate: (SysExMessage *) msg
{
    return([msg messageByteAt: 1] == ROLAND &&
           [msg messageByteAt: 2] == CTRLCHG);
}

// Check if the sys-ex message is a new Juno106 patch message
- (BOOL) isNewPatch: (SysExMessage *) msg
{
    return([msg messageByteAt: 1] == ROLAND &&
           ([msg messageByteAt: 2] == PATCHCHG ||
            [msg messageByteAt: 2] == MANUAL));
}

// Update the display of switches in the first switch byte
- displaySwitchBank1: (int) switch1
{    
    [range selectCellWithTag: switch1 & 0x7];
    [chorus selectCellWithTag: switch1 & 0x60];
    [pulse setIntValue: switch1 & 0x8];
    [saw setIntValue: switch1 & 0x10];
    return self;
}

// Update the display of switches in the second switch byte
- displaySwitchBank2: (int) switch2
{
    // HPF setting, it's a switch but it appears as a slider.
    [hpf setIntValue:3 - ((switch2 >> 3) & 0x3)];
    [vca setIntValue: switch2 & 0x04];
    [envDirection setIntValue: switch2 & 0x02];
    [pwm setIntValue: switch2 & 0x01];
    return self;
}

// return a pointer to a statically allocated string containing the current patch
// number
- (NSString *) junoName
{
    char group;
    int patchNum;

    if([patch messageByteAt: 2] == MANUAL) {
	return @"--";
    }
    else if((patchNum = [patch messageByteAt: PATCH_NUM]) < 64) {
	group = 'A';
    }
    else {
	group = 'B';
	patchNum -= 64;
    }
    return [NSString stringWithFormat: @"%c%d%d", group, (patchNum / 8) + 1, (patchNum % 8) + 1];
}

// Format the patch number into that displayed on the Juno.
- displayJunoName 
{
    [patchName setStringValue: [self junoName]];
    return self;
}

// display the slider
- displaySliderNo: (int) sliderNo with: (unsigned char) value
{
    if(sliders[sliderNo] != nil)
	[sliders[sliderNo] setIntValue:value];
    return self;
}

// Receive a patch update message from the Juno and change a single parameter of
// our held patch.
- (void) parameterUpdate: (SysExMessage *) msg
{
    int parameter = [msg messageByteAt: UPDATE_PARAM];
    int parameterNo = [msg messageByteAt: UPDATE_PARAM_NO];
    
    [patch setMessageByteAt: parameterNo + JUNO_HEADER to: parameter];
    [[self window] setDocumentEdited: YES];
    switch(parameterNo) {
    case SWITCH_1:
    	[self displaySwitchBank1: parameter];
        break;
    case SWITCH_2:
        [self displaySwitchBank2: parameter];
        break;
    default:
        [self displaySliderNo: parameterNo with: parameter];
	break;
    } 
}

// display the complete patch to the user interface
- (void) displayPatch
{
    int i;
    
    for(i = 0; i < MAX_SLIDERS; i++) {
	[self displaySliderNo: i with: [patch messageByteAt: i + JUNO_HEADER]];
    }
    [self displaySwitchBank1: [patch messageByteAt: SWITCH_1 + JUNO_HEADER]];
    [self displaySwitchBank2: [patch messageByteAt: SWITCH_2 + JUNO_HEADER]];
    [midiChan setIntValue:[self midiChannel] + 1];	// display the channel
    [self displayJunoName];
    [[self window] makeKeyAndOrderFront: nil];
}

// Method to update a parameter in the patch, and download the parameter to the
// Juno.
- updateParameter: (int) parameterNo with: (int) newValue
{
    [patch setMessageByteAt: parameterNo + JUNO_HEADER to: newValue];
    [update setMessageByteAt: UPDATE_PARAM_NO to: parameterNo];
    [update setMessageByteAt: UPDATE_PARAM to: newValue];
    [self sendUpdate];
    [[self window] setDocumentEdited: YES];
    return self;
}

// Action to accept the changes from the sliders comprising the
// interface and update the patch in the Juno itself.
- (void) updateSliders:slider
{
    int parameterNo, newValue;

    parameterNo = [slider tag];
    newValue = [slider intValue];
    [self updateParameter: parameterNo with: newValue];
}

// Action to accept the changes from the HPF sliding switch comprising the
// interface and update the patch in the Juno itself.
- (void) updateHPF: slider
{
    int newValue = [hpf intValue];
    int oldValue = [patch messageByteAt: SWITCH_2 + JUNO_HEADER];

    [hpf setIntValue:newValue];       // to update the display
    newValue = ((3 - newValue) << 3) + (0x7 & oldValue);
    [self updateParameter: SWITCH_2 with: newValue];
}

// Modify the existing SysEx patch according to the setting of the switches
// and send the new parameter to the Juno.
- (void) updateSwitches: sender
{
    unsigned char newValue, oldValue, mask;
    int parameterNo;
    
    mask = [sender tag] & 0xff;	      // the bit to mask is in the lower 8 bits
    parameterNo = [sender tag] >> 8;  // parameter number is in the top 8 bits
    oldValue =  [patch messageByteAt: parameterNo + JUNO_HEADER];
    newValue = ([sender intValue] != 0) ? mask | oldValue : ~mask & oldValue;
    [self updateParameter: parameterNo with: newValue];
}

// Range and Chorus Radio Button action method.
// Update the message bytes associated with the radio buttons and send the bytes to
// the Juno.
- (void) updateRangeAndChorus: sender
{
    unsigned char newValue, oldValue, mask, clearBits;
    int parameterNo = SWITCH_1;
    
    mask = [[sender selectedCell] tag];	// tag of the button is parameter value
    clearBits = [sender tag];		// tag of the matrix are the bits to clear
    oldValue =  [patch messageByteAt: parameterNo + JUNO_HEADER];
    newValue = (oldValue & clearBits) | mask;
    [self updateParameter: parameterNo with: newValue];
}

// Receives a message from our MIDI channel value field.
// Internally MIDI channels are 0-15, for the user they are 1-16.
- (void) updateMidiChannel: sender
{
    [self setMidiChannel:[sender intValue] - 1]; 
}

- (void) setMidiPatchNumber: (int) midiPatchNumber
{
    [super setMidiPatchNumber: midiPatchNumber];
    [patch setMessageByteAt: PATCH_NUM to: midiPatchNumber];
}

// Send the update parameter sysEx message. Assumes the parameter number and
// the parameter have already been assigned. Overrides the MIDI channel
// however.
- (void) sendUpdate
{
    [update setMessageByteAt: MIDI_CHAN to: [self midiChannel]];
    [update send]; 
}

// This method will be called automatically when unbundling the .nib
// Grab all the sliders collected in the group, assign the
// updateSliders: action method to them and save their ids into a C
// array indexed by their tag. This emulates the behaviour of an uneven
// Matrix in someway but also gives us an efficient means of indexing the
// sliders so we can update them based on a MIDI message.
- (void) setSliderGroup: aSliderGroup;
{
    int i;
    NSArray *boxOfSliders;
    id currentSlider;

    sliderGroup = aSliderGroup;
    boxOfSliders = [[sliderGroup contentView] subviews];
    /* load the array with the slider objects */
    for(i = 0; i < [boxOfSliders count]; i++) {
	currentSlider = [boxOfSliders objectAtIndex: i];
	[currentSlider setTarget:self];
	[currentSlider setAction:@selector(updateSliders:)];
	sliders[[currentSlider tag]] = currentSlider;
    }
}

@end
