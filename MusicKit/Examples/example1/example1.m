#include <stdlib.h>
#include <musickit/musickit.h>

main()
{
	Note *aNote,*partInfo;
	Part *aPart;
	Score *aScore;
	aScore = [[Score alloc] init];
	aPart = [[Part alloc] init];
	/* REPEAT FROM HERE TO XXX TO ADD MULTIPLE NOTES */
	aNote = [[Note alloc] init];
	[aNote setPar:MK_freq toDouble:440.0];
	[aNote setTimeTag:1.0];
	[aNote setDur:1.0];
	[aScore addPart:aPart];
	[aPart addNote:aNote];           /* Doesn't copy note */
	/* XXX */
	partInfo = [[Note alloc] init];	
	[partInfo setPar:MK_synthPatch toString:"Pluck"];
	[aPart setInfo:partInfo];
	[aScore writeScorefile:"test.score"];
	system("playscore test.score");  /* play the thing */
}