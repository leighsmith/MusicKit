/*
 * The abstract Synth class and the stubs defining methods which are over-ridden
 * in the sub-classes corresponding to each particular synth.
 *
 * $Id$
 */
#import "MIDISysExSynth.h"
#import "PatchBankDocument.h"

@implementation MIDISysExSynth

// issue the dump request message, what about the MIDI channel it's on?
+ (void) requestPatchUpload
{
}

// initialise and register oneself with the SysExMessage
- (id) init
{
    self = [super init];
    if(self != nil) {
	[SysExMessage registerSynth: self];
	// set a random number seed
	[self setBank: nil];
    }
    return self;
}

// Called from PatchBankDocument where there is no data accompanying it.
// We need to initialise to a meaningful empty patch (randomise it) and 
// at some point (as soon as it is
// generated?, when commanded to, using sendPatch?) download that patch. 
// A user will want to audition a patch straight after 
// creating a new one and may just start playing on the keyboard. Perhaps that should be an instance decision?
- (id) initWithEmptyPatch
{
//    [patch autorelease]; Don't think this is right
    patch = [[SysExMessage alloc] init];
    return self;
}

- (SysExMessage *) sysEx
{
    return patch;
}

// Display the patch currently held. This is necessary
// when we have several sysex messages to communicate
// a meaningful patch, we don't want to neccessarily
// display the patch until all are received.
- (void) displayPatch
{
}

// Mix things up a bit (needs a random number seed)
- (void) randomizePatch
{
    // randomize the instance variables pertaining to the patch parameters
    // (and that's all)
    // randomize a patch description of say 10 characters
	 
}

// Download current patch to synth
- (void) sendPatch
{
    // get the patch (instance variables) and translate to a sys-ex message
    [patch send]; 
}

- (void) sendUpdate
{
	 
}

// The method used to provide new sysEx messages to the synth instance.
- (BOOL) initWithSysEx: (SysExMessage *) msg
{
    if([self isParameterUpdate: msg])
	[self parameterUpdate:msg];
    else if ([self isNewPatch: msg])
	[self acceptNewPatch:msg];
    else if ([self isBulkDump: msg])
	[self acceptBulkDump:msg];
    else
	return NO;
    return YES;
}

// Given a sys-ex message, returns YES if it's updating a parameter.
- (BOOL) isParameterUpdate: (SysExMessage *) msg
{
    return NO;
}

// Check if the sys-ex message is a new patch message
- (BOOL) isNewPatch: (SysExMessage *) msg
{
    return NO;
}

// Check if the sys-ex message is a bulk patch dump message.
- (BOOL) isBulkDump: (SysExMessage *) msg
{
    return NO;
}

// Set and display a new patch.
- (void) acceptNewPatch: (SysExMessage *) msg
{
    [patch autorelease];
    patch = [msg copy]; 
}

// Decompose the message into a set of synth sub-class instances (self) and hand each one over to the bank object (which one? and where do we find it?)
// From a bank, we could produce a new patch which would be a synth object.
// This may be better performed by read... (have to read on archiving objects), rather than calling acceptNewPatch.
// Here is where we handle a whole bank of patches being uploaded in a single sys-ex message.
// This perhaps should just save the message and then have bits scooped out using read.
- (void) acceptBulkDump: (SysExMessage *) msg
{
	 
}

// Change a single parameter in the current patch and update the GUI.
// When a slider is moved on the synth, this method will be called by sysEx:
- (void) parameterUpdate: (SysExMessage *) msg
{
	// check we already have a window up
	 
}

// Synthesiser capability defining methods.

// Identifies the synth as responding to note-on/offs.
- (BOOL) canPlayNotes
{
    return NO;
}

// We can send parameter updates to the synth while it
// sounds and hear the changes without retriggering a note.
- (BOOL) canUpdatePatchWhilePlaying
{
    return NO;
}

// We are able to retrieve patches from the synth via sysex.
+ (BOOL) canUploadPatches
{
    return NO;
}

/*
The following two informational methods consider the same problem, banks, delegates?
Probably should start thinking about the bank interface in order to fully define the
synth multiple patch handling methods. Think of it in terms of a general object storage device.
PatchBankDocument - a managed collection of dissimilar synth subclass instances, containing synth data.
*/

// Indicates the synth can send a whole bunch of patches in a single sysex message.
// Should the synth carve up the
// patches and hand them back to the controller - hmm.
- (BOOL) canSendMultiplePatches
{
    return NO;
}

/*
It is feasible to have a synth which only works by downloading an entire bank, even though we are working on a single patch. In that case before anything can be changed a complete bank has to be assembled.
Controller may need to inform the user that a complete bank must be downloaded, where should the patch be placed.
*/
- (BOOL) mustDownloadBank
{
    return NO;
}

// restore a whole patch, including the MIDI channel, but it is conditional whether
// we will actually use it.
- (id) initWithCoder: (NSCoder *) aDecoder
{
    int savedMIDIchan;
    
// was [aDecoder decodeValuesOfObjCTypes: "@", patch];
    patch = [[aDecoder decodeObject] retain]; 
    [aDecoder decodeValuesOfObjCTypes: "i", &savedMIDIchan];
    [aDecoder decodeValuesOfObjCTypes: "*", &patchDescription];
    if(1)	// restoreMIDIchannel
	MIDIChannel = savedMIDIchan;
    return self;
}

// save the patch, including the MIDI channel it was on
- (void) encodeWithCoder: (NSCoder *) aCoder
{
// was	[aCoder encodeValuesOfObjCTypes: "@", patch];
    [aCoder encodeObject: patch];
    [aCoder encodeValuesOfObjCTypes: "i", &MIDIChannel];
    [aCoder encodeValuesOfObjCTypes: "*", &patchDescription];
}

// return the MIDI channel the synth is on, if deducable from the sysEx messages.
// otherwise return what? -1?
- (int) midiChannel
{
    return MIDIChannel;
}

// assign the MIDI channel the synth is on
- (void) setMidiChannel: (int) midiChan
{
    MIDIChannel = midiChan; 
}

/*
Should the description and the patch name be two different fields, or should the
patch name be derived from the description (when downloading) & vice-versa when uploading?
*/
- (NSString *) patchDescription	// returns the text of the patch description
{
    return patchDescription;
}

// Assign a new description to the patch
- (void) setPatchDescription: (NSString *) newDescription
{
    NSWindow *theWindow = [self window];

//    [patchDescription autorelease]; // TODO check this is now ok
    patchDescription = [newDescription copy];
    if(theWindow != nil)
	[theWindow setTitle: [self patchDescription]];
}

// return the MIDI patch change number the patch is addressed by.
- (int) midiPatchNumber
{
    return MIDIpatchNumber;
}

// assign the patch number.
- (void) setMidiPatchNumber: (int) midiPatchNumber
{
    MIDIpatchNumber = midiPatchNumber;
}

// returns the name of the Synthesiser
- (NSString *) synthName
{
    return [(MIDISysExSynth *)[self class] description];
}

// Typically all but one subclass will selectively respond to sysEx: messages
- (BOOL) catchesAllMessages
{
    return NO;
}

// Assign which bank we are part of. A PatchBankDocument is a document instance but assigning it as this sub-classes document
// makes PatchBankDocument handle the synth inspector window closing, which isn't what we want. We do need to know what PatchBankDocument we
// are part of, hence the following two methods.
- (void) setBank: (PatchBankDocument *) b
{
    bank = b;
}

// return the bank we belong within.
- (PatchBankDocument *) bank
{
    return bank;
}

@end	

@implementation MIDISysExSynth(WindowDelegate)

// Implementing this in the abstract superclass makes this the delegate of all window closing of all synths.
- (BOOL) windowShouldClose: (id) sender
{
    NSWindow *windowToClose = [self window];
    int result;

    if(![windowToClose isDocumentEdited])
        return YES;
    [windowToClose makeFirstResponder: windowToClose];
    result = NSRunAlertPanel(@"Close", 
	[NSString stringWithFormat: @"%@ patch \"%@\" has been modified. Save changes before closing?",
        [self synthName], [self patchDescription]], @"Save", @"Don't Save", @"Cancel");

    switch(result) {
    case NSAlertDefaultReturn:
        [[self bank] addPatch: self];  // should this be in PatchBankDocument.m?
        return YES;
    case NSAlertAlternateReturn:
        return YES;
    case NSAlertOtherReturn:
        return NO;
    }
    return NO;
}

@end
