#import <musickit/SynthPatch.h>

/* Interface for example SynthPatch EnvySimplified. */
@interface EnvySimplified:SynthPatch
{
}

+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- (double)noteOffSelf:aNote;
- noteEndSelf;
- init;

@end

