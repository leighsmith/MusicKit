/*
 * Blue Chip Axon NGC-77 MIDI Guitar Controller object declaration
 */
#import <AppKit/AppKit.h>
#import "../MIDISysExSynth.h"

@interface AxonNGC77: MIDISysExSynth
{
    SysExMessage *update;
    IBOutlet id guitarNeck;
    IBOutlet id pickups;
    IBOutlet id holdMode;
    IBOutlet id holdController;
    IBOutlet NSButton *splitButton;
    NSMutableString *patchName;
}

- init;
- (id) initWithEmptyPatch;
- (BOOL) isParameterUpdate: (SysExMessage *) msg;
- (BOOL) isNewPatch: (SysExMessage *) msg;
- (void) acceptNewPatch: (SysExMessage *) msg;
- (void) setPatchDescription: (NSString *) name;
//- (NSString *) patchName;
// actions
- (void) displayHoldSegment: sender;
- (void) displaySelectedSegment: sender;


@end
