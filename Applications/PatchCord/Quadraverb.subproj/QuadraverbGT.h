/*
 * Declaration for Alesis Quadraverb GT Digital Effects Unit
 */
#import <AppKit/AppKit.h>
#import "../MIDISysExSynth.h"

@interface QuadraverbGT : MIDISysExSynth
{
    id configuration;
    SysExMessage *update;
}

- init;
- (id) initWithEmptyPatch;
- (BOOL) isParameterUpdate: (SysExMessage *) msg;
- (void) acceptNewPatch: (SysExMessage *) msg;
- (BOOL) isNewPatch: (SysExMessage *) msg;
- (BOOL) isAQuadraverbGT: (SysExMessage *) msg;

@end
