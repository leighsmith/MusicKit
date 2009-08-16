#ifndef __MK_Simplicity_H___
#define __MK_Simplicity_H___
#import <MusicKit/MusicKit.h>

@interface Simplicity : MKSynthPatch
{}

+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- noteEndSelf;

@end

#endif
