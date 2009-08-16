/* Object responsible for managing reception of system exclusive messages */
#import <MusicKit/MusicKit.h>
#import "SysExMessage.h"
@class MIDISysExSynth;
@class Bank;

@interface SysExReceiver: MKInstrument
{
    BOOL enabled;                       // allow/disallow notification of synths
    SysExMessage *sysExMsg;		// The last received SysEx message
    NSMutableArray *registeredSynths;	// Synthesisers we communicate messages to.
    NSMutableArray *lastRespondantSynths;
    Bank *delegateBank;                 // So we can notify our bank we created new MIDISysExSynth instances
}

- init;
- (void) setDelegateBank: (Bank *) bank;
- (void) registerSynth: (MIDISysExSynth *) synth;
- (void) unregisterSynth: (MIDISysExSynth *) synth;
- (NSMutableArray *) registeredSynths;
- (void) enable;
- (void) disable;
- (void) respondToMsg: (SysExMessage *) sysExMsg;
- (NSArray *) respondantSynths;
- realizeNote: (MKNote *) theNote fromNoteReceiver: (MKNoteReceiver *) theReceiver;
@end
