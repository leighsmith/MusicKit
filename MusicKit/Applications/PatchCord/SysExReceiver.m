/*
 * A Subclassed Instrument, in order to have the notes sent here to be directed
 * to the synth objects which can deal with the sysex messages.
 * A bank will register itself as the receiver's delegate, determining which has new patches directed to it.
 */
#import "SysExReceiver.h"
#import "MIDISysExSynth.h"
#import "Bank.h"

@implementation SysExReceiver

- init
{
    self = [super init];
    if(self != nil) {
	registeredSynths = [[[NSMutableArray alloc] init] retain];
	lastRespondantSynths = [[[NSMutableArray alloc] init] retain];
	sysExMsg = [[[SysExMessage alloc] init] retain];
	// Allocate ourselves a MKNoteReceiver
	[self addNoteReceiver: [[MKNoteReceiver alloc] init]];
	enabled = FALSE;
	delegateBank = nil;	
    }
    return self;
}

// set the delegate bank to save received respondant synth instances into.
- (void) setDelegateBank: (Bank *) bank
{
    delegateBank = bank;
}

// To register a synth object that the received sysEx messages may be sent to.
- (void) registerSynth: (MIDISysExSynth *) synth
{
    if (![registeredSynths containsObject:synth]) {
        // push all the catchAllMessages synths so they are the last resort,
	// otherwise they will mask more specific synths.
        if([synth catchesAllMessages])
            [registeredSynths insertObject:synth atIndex: 0];
        else
            [registeredSynths addObject:synth];
    }
}

// To remove a previously registered synth
- (void) unregisterSynth: (MIDISysExSynth *) synth
{
    [registeredSynths removeObject: synth]; 
}

// Returns an array of the unique class objects of the registered synths.
// This allows the user of this method to then instantiate instances of those synths.
- (NSMutableArray *) registeredSynths
{
    int i;
    Class nonUniqueSynthClass;
//    NSMutableArray *registeredSynthClasses = [[NSMutableArray array] autorelease];
    NSMutableArray *registeredSynthClasses = [NSMutableArray array];

    // loop thru all registeredSynths
    for(i = 0; i < [registeredSynths count]; i++) {
        nonUniqueSynthClass = [[registeredSynths objectAtIndex: i] class];
        // now attempt to add the class objects into our class list so that they are unique
        if(![registeredSynthClasses containsObject: nonUniqueSynthClass]) {
	    [registeredSynthClasses addObject: nonUniqueSynthClass];
        }
    }
    return registeredSynthClasses;
}

// methods to allow the dispatch of SysEx messages
- (void) enable
{
    enabled = TRUE;
}

- (void) disable
{
    enabled = FALSE;
}

// Probably should do this with NSNotification.

// Determines the synth that responds to the given sysEx message and
// hands the message over to it to process. Process the list backwards so that the list
// ascends in priority with newer synths added overriding older ones.
- (void) respondToMsg: (SysExMessage *) msg
{
    int i;
    MIDISysExSynth *candidateSynth;
    BOOL aSynthResponded = NO;

    if(enabled) {
	[lastRespondantSynths release];
	lastRespondantSynths = [[NSMutableArray alloc] init];
        for(i = [registeredSynths count] - 1; i >= 0; i--) {
	    candidateSynth = [registeredSynths objectAtIndex: i];
	    // we forward onto to all instances in the list which respond,
	    // unless we have already had a positive result from some other
	    // synth instance and a catch-all is the only one left.
	    if(![candidateSynth catchesAllMessages] || !aSynthResponded) {
		if([candidateSynth initWithSysEx: msg] == YES) { // TODO not strictly reinitialising the object
		    aSynthResponded = YES;
		    if([candidateSynth isNewPatch: msg] == YES)
                        [lastRespondantSynths addObject: candidateSynth];
		}
	    }
	}
	// We have built up a list of Synths which responded to the msg, now allow them to be retrieved.
	// Call the delegate, it will probably retrieve the synth list created above using the respondantSynths method.
	if(delegateBank != nil && [lastRespondantSynths count] != 0)
            [delegateBank receiverDidAcceptPatches: self];
    }
}

// retrieve the list of Synth instances which responded to the most recent respondToMsg
- (NSArray *) respondantSynths
{
    return lastRespondantSynths;
}

// If the note received from the MusicKit is a system exclusive message, convert it 
// to our SysExMessage object, dispatch it to all synths 
// (they will decide if they want to do anything
// with the message, otherwise they will return).
- realizeNote: (MKNote *) theNote fromNoteReceiver: (MKNoteReceiver *) theReceiver
{
    MKNote *noteCopy;

    if([theNote isParPresent: MK_sysExclusive] == YES) {
    	noteCopy = [theNote copy];	// Always copy Notes, don't use them inplace
	[sysExMsg initWithString: [noteCopy parAsString: MK_sysExclusive]];
	[self respondToMsg: sysExMsg];
    }
    return self;
}

@end
