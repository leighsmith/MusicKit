/*
 * Class declaring Alesis Quadraverb GT MultiFX unit patch management.
 * Leigh Smith 6/9/98
 *
 * $Id$
 */
#import "QuadraverbGT.h"

@implementation QuadraverbGT

- init
{
    self = [super init];
    if(self != nil) {
        NSLog(@"Quadraverb GT initialisation\n");
        update = [[SysExMessage alloc] init];
        // F0 00 00 0E 07 01<function#><page#>< value1>< value2>< value3>F7
        [update initWithString:@"f0,00,00,0e,07,01,0,0,0,0,0,f7"];
    }
    return self;
}

- (void) loadAndShowNib
{
    [super initWithWindowNibName: @"quadraverb" owner: self];
    [[self window] setDocumentEdited: NO];
    [self displayPatch];
}

- (id) initWithEmptyPatch
{
   [super initWithEmptyPatch];
   [self init];
   [patch initWithString:@"f0,00,00,0e,07,01,0,0,0,0,0,f7"];
   // Need to do something with Channel semantics here.
   [self loadAndShowNib];
   return self;
}

- (NSString *) getPatchName: (SysExMessage *) msg
{
    return @"Dummy name";
}

- (void) acceptNewPatch: (SysExMessage *) msg
{
    [super acceptNewPatch:msg];
    // [self setMidiChannel:[msg messageByteAt: MIDI_CHAN]];
    [self setPatchDescription: [self getPatchName: msg]];
    [self loadAndShowNib];
}

// Ensure it's an Alesis Quadraverb GT
- (BOOL) isAQuadraverbGT: (SysExMessage *) msg
{
    return([msg messageByteAt: 0] == 0xF0 &&
           [msg messageByteAt: 1] == 0x00 &&
           [msg messageByteAt: 2] == 0x00 &&
           [msg messageByteAt: 3] == 0x0e &&
           [msg messageByteAt: 4] == 0x07);
}

- (BOOL) isNewPatch: (SysExMessage *) msg
{
//    NSLog(@"checking if we have a patch\n");
    return([self isAQuadraverbGT: msg] && [msg messageByteAt: 5] == 0x02);
}

- (BOOL) isParameterUpdate: (SysExMessage *) msg;
{
    return([self isAQuadraverbGT: msg] && [msg messageByteAt: 5] == 0x01);
}

// display the complete patch to the user interface
- (void) displayPatch
{
    [[self window] makeKeyAndOrderFront: nil];
}

@end
