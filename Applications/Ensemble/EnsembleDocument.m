/* Obsolete - see EnsembleDoc.m */
#import "EnsembleDocument.h"
#import "EnsembleNoteFilter.h"
#import "EnsembleDoc.h"
#import "EnsembleSynthIns.h"
#import <AppKit/AppKit.h>

@implementation EnsembleDocument

- selectInput:sender {return self;}
- selectInstrument:sender {return self;}
- takeMidiChannelFrom:sender {return self;}
- muteMidiInput:sender {return self;}
- takePartNumberFrom:sender {return self;}
- mutePartInput:sender {return self;}
- takeNoteFilterFrom:sender {return self;}
- takeInstrumentNumberFrom:sender {return self;}
- takeInstrumentFrom:sender {return self;}
- sendTestNote:sender {return self;}
- muteInstrument:sender {return self;}

- read:(NXTypedStream *) stream
 /* Unarchive a document from a typed stream. */
{
	int i, j, n, nfilters, version;
	id filter;
	id instrumentViews[4];

	[super read:stream];
	/*
	 * The class version (set in +initialize) will be needed if we make changes
	 * to archiving documents in the future. 
	 */
	version = NXTypedStreamClassVersion(stream, "EnsembleDocument");
	NXReadTypes(stream, "@ddicc@iii", &window,
				&samplingRate, &headroom, &dspNum, &loadScore, &usesDSP,
				&commentPanel, &program, &tempo, &n);
	/*
	 * The filters archive their nextFilter and lastFilter as references, so
	 * the linked list is preserved, and all we have to do is read in the
	 * objects. 
	 */
	for (i = 0; i < n; i++) {
		NXReadType(stream, "i", &nfilters);
		if (nfilters) {
			NXReadType(stream, "@", &noteFilters[i]);
			for (j = 1; j < nfilters; j++)
				NXReadType(stream, "@", &filter);
		}
	}
	NXReadArray(stream, "@", n, instruments);
	NXReadArray(stream, "i", n, partNums);
	NXReadArray(stream, "i", n, midiChannels);
	NXReadArray(stream, "c", n, midiEnabled);
	NXReadArray(stream, "c", n, partEnabled);
	NXReadArray(stream, "c", n * n, instrumentMap);
	if (version < 3) {
		/* EnsembleSynthIns now keeps track of its own allocation */
		int    *patchCount;

		NX_MALLOC(patchCount, int, n);
		NXReadArray(stream, "i", n, patchCount);
		for (i = 0; i < n; i++)
			[[instruments[i] setPatchAllocation:patchCount[i]] displayPatchCount];
		NX_FREE(patchCount);
	}
	NXReadArray(stream, "@", n, instrumentViews);
	NXReadTypes(stream, "@@@", &insSelectButtons,
				&midiChanDisplayer, &partNumDisplayer);
	NXReadArray(stream, "@", n, instrumentBoxes);
	NXReadArray(stream, "@", n, filterButtons);
	NXReadArray(stream, "@", n, instrumentButtons);
	NXReadType(stream, "i", &n);
	if (n) {
		NX_MALLOC(scoreFilePath, char, n + 1);
		NXReadArray(stream, "c", n, scoreFilePath);
		scoreFilePath[n] = '\0';
	} else {
		NXReadArray(stream, "c", 0, scoreFilePath);	/* not optional! */
		scoreFilePath = NULL;
	}
	if (version > 3) {
		NXReadTypes(stream, "ic", &headphoneLevel, &deemphasis);
		if (headphoneLevel > 2)  { /* a pre-3.0 doc */
			if (headphoneLevel == 44)
				headphoneLevel = -86;		/* < -84 now means "don't change" */
			else
				headphoneLevel = 2*headphoneLevel - 86;
		}
		else headphoneLevel = -86;
	}
	else
		headphoneLevel = -86;

	if (version <= 1)
		program = -1;			/* reset program to new default */
	return self;
}

- free
{
	[window free];
	return [super free];
}

- finishUnarchiving
{
	int i, j;
	EnsembleDoc *newself = [EnsembleDoc allocFromZone:[NXApp zone]];
	
	for (i=0; i<MAXINSTRUMENTS; i++) {
		newself->noteFilters[i] = noteFilters[i];
		newself->instruments[i] = instruments[i];
		newself->partNums[i] = partNums[i];
		newself->midiChannels[i] = midiChannels[i];
		newself->midiEnabled[i] = midiEnabled[i];
		newself->partEnabled[i] = partEnabled[i];
		for (j=0; j<MAXINSTRUMENTS; j++)
			newself->instrumentMap[i][j] = instrumentMap[i][j];
	}
	newself->samplingRate = samplingRate;
	newself->headroom = headroom;
	newself->tempo = tempo;
	newself->dspNum = dspNum;
	newself->loadScore = loadScore;
	newself->usesDSP = usesDSP;
	newself->scoreFile = scoreFilePath;
	newself->commentText = [[[[commentPanel contentView] subviews] objectAt:0] docView];
	[newself->commentText removeFromSuperview];
	[commentPanel free];
    newself->program = program;
    newself->headphoneLevel = headphoneLevel;
    newself->deemphasis = deemphasis;

	[NXApp delayedFree:self];
	return newself;
}

@end
