@interface Bark : SynthPatch
{
	id LoochWave;
}

+ patchTemplateFor:aNote;
- noteOnSelf:aNote;
- noteUpdateSelf:aNote;
- (double)noteOffSelf:aNote;
- noteEndSelf;
- initialize;

@end
