#ifndef __MK_EnvySimplified_H___
#define __MK_EnvySimplified_H___
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

#endif
