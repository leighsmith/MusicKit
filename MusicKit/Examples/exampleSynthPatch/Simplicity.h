#import <musickit/SynthPatch.h>

@interface Simplicity : SynthPatch
{}

+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- noteEndSelf;

@end

