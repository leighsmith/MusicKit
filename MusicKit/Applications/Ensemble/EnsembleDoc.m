/*
 * This object is an Ensemble document.  It maintains up to four chains of 
 * note filters and four instruments.  Notes are sent from MIDI and/or
 * Score parts down each chain of note filters.  The last note filter in
 * each chain sends the notes to one or more instruments and/or 
 * part recorders.
 */
#import "EnsembleDoc.h"
#import "EnsembleDocument.h"
#import "EnsembleNoteFilter.h"
#import "EnsembleApp.h"
#import "EnsembleSynthIns.h"
#import "SamplerInstrument.h"
#import "Preferences.h"
#import "MidiFilter.h"
#import "MidiOutInstrument.h"
#import "ResonInstrument.h"
#import "KeyRange.h"
#import "MIDIometer.h"
#import <appkit/appkit.h>
#import <SoundKit/Sound.h>

extern id docUsingDSP();

#define NUMINSCLASSES 7
/* The names of the 7 instrument classes included now. */
char *instrumentClasses[] = {"Wave1Instrument", "Fm1Instrument", "PluckInstrument",
							"ShapeInstrument", "MidiOutInstrument", "SamplerInstrument",
							"ResonInstrument"};
char *instrumentNames[] = {"Wavetable", "FM", "Pluck", "Waveshaper",
							"MIDI Out", "Sampler", "Resonator"};

@implementation EnsembleDoc

+ initialize
 /*
  * Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[EnsembleDoc setVersion:2];
	[EnsembleDoc setDocFileExtension:"ens"];
	return self;
}

- setDefaults
	/* Called by superclass's initFromPath when path is NULL */
{
	int i;
	[super setDefaults];
	[self addFilter:[KeyRange class] toInput:0 atPosition:0];
	[self addFilter:[KeyRange class] toInput:1 atPosition:0];
	[self addFilter:[KeyRange class] toInput:2 atPosition:0];
	[self addFilter:[KeyRange class] toInput:3 atPosition:0];
	for (i = 0; i < MAXINSTRUMENTS; i++) {
		partNums[i] = i;
		midiChannels[i] = i + 1;
		midiEnabled[i] = YES;
		partEnabled[i] = YES;
		instruments[i] = nil;
		instrumentMap[i][i] = YES;
	}
	dspNum = 0;
	tempo = 60;
	scoreFile = NULL;
	headphoneLevel = -86;		/* < -84 means don't change */
	deemphasis = NO;
	program = -1;
	delegate = self;
	return self;
}

- initFromPath:(char *)path
 /* Initialize a newly created document. */
{
	self = [super initFromPath:path];	/* Might replace self with unarchived doc */
	if (self) {
		orchestra = [Orchestra newOnDSP:dspNum];
		samplingRate = [[NXApp preferences] samplingRate];
		headroom = [[NXApp preferences] headroom];
		selectedInput = -1;
		selectedInstrument = -1;
	}
	return self;
}

- buildMenus
{
	int i, j;
	id button, menu, cell, filter, f;
	char s[128];
	BOOL instantiated;

	for (i=0; i<4; i++) {
		button = filterButtons[i];
		menu = [button target];
		filter = noteFilters[i];
		for (j=0; j<NUMFILTERS; j++) {
			f = filter;
			instantiated = NO;
			while (f = [f nextFilter])
				if (f && ([f position]==j)) {instantiated = YES; break;}
			strcpy(s,instantiated ? "Show " : "Open ");
			strcat(s, filterNames[j]);
			cell = [menu addItem:s];
			[cell setTag:j];
			[cell setTarget:self];
			[cell setAction:@selector(takeNoteFilterFrom:)];
			[f setMenuCell:cell];
		}
	}
	return self;
}

- awakeFromNib
{
	int i, j;
	KeyRange *kr;
	float left, right;
	
	[super awakeFromNib];
	[insSelectButtons setEmptySelectionEnabled:YES];
	[insSelectButtons selectCellAt:-1:-1];
	[inputSelectButtons setEmptySelectionEnabled:YES];
	[inputSelectButtons selectCellAt:-1:-1];
	NXPing();
	[window setMiniwindowIcon:"EnsembleDoc"];
	mouseDownSliders([window contentView]);	/* Controls respond to down click */
	instrumentBoxes[0] = instrumentBox0;	/* Use arrays for convenience */
	instrumentBoxes[1] = instrumentBox1;
	instrumentBoxes[2] = instrumentBox2;
	instrumentBoxes[3] = instrumentBox3;
	filterButtons[0] = filterButton0;
	filterButtons[1] = filterButton1;
	filterButtons[2] = filterButton2;
	filterButtons[3] = filterButton3;
	instrumentButtons[0] = instrumentButton0;
	instrumentButtons[1] = instrumentButton1;
	instrumentButtons[2] = instrumentButton2;
	instrumentButtons[3] = instrumentButton3;
	insNumButtons[0] = insNumButton0;
	insNumButtons[1] = insNumButton1;
	insNumButtons[2] = insNumButton2;
	insNumButtons[3] = insNumButton3;
	muteButtons[0] = muteButton0;
	muteButtons[1] = muteButton1;
	muteButtons[2] = muteButton2;
	muteButtons[3] = muteButton3;
	[midiButton0 setState:!midiEnabled[0]];
	[midiButton1 setState:!midiEnabled[1]];
	[midiButton2 setState:!midiEnabled[2]];
	[midiButton3 setState:!midiEnabled[3]];
	[scoreButton0 setState:!partEnabled[0]];
	[scoreButton1 setState:!partEnabled[1]];
	[scoreButton2 setState:!partEnabled[2]];
	[scoreButton3 setState:!partEnabled[3]];

	for (i=0; i<MAXINSTRUMENTS; i++) {
		[[midiChanDisplayer cellAt:0 :i] setIntValue:midiChannels[i]];
		[[partNumDisplayer cellAt:0 :i] setIntValue:partNums[i] + 1];
		kr = noteFilters[i];
		kr->maxKeySlider = [keyRangeSliders cellAt:0:i];
		kr->minKeySlider = [keyRangeSliders cellAt:1:i];
		kr->rangeField   = [keyRangeFields cellAt:0:i];
		kr->transpositionSlider = [transposeSliders cellAt:0:i];
		kr->transpositionField = [transposeFields cellAt:0:i];
		[[keyRangeSliders cellAt:0:i] setTarget:kr];
		[[keyRangeSliders cellAt:0:i] setAction:@selector(takeMaxKeyFrom:)];
		[[keyRangeSliders cellAt:1:i] setTarget:kr];
		[[keyRangeSliders cellAt:1:i] setAction:@selector(takeMinKeyFrom:)];
		[[transposeSliders cellAt:0:i] setTarget:kr];
		[[transposeSliders cellAt:0:i] setAction:@selector(takeTranspositionFrom:)];
		[kr awakeFromNib]; /* The keyRange instances used to be in the doc nib... */
		[self addInstrumentView:instruments[i] at:i];
		for (j=0; j<NUMINSCLASSES; j++)
			if ([instruments[i] isMemberOfClassNamed:instrumentClasses[j]]) {
				[instrumentButtons[i] setTitle:instrumentNames[j]];
				break;
			}
		if (instruments[i] && [[instruments[i] noteReceiver] isSquelched])
			[muteButtons[i] setState:1];
		for (j=0; j<MAXINSTRUMENTS; j++)
			[[insNumButtons[i] cellAt:0:j] setState:instrumentMap[i][j]];
	}
	[self buildMenus];

	if (commentText &&
		(commentText != [[[[commentPanel contentView] subviews] objectAt:0] docView]))
		[[[[[commentPanel contentView] subviews] objectAt:0]
			setDocView:commentText] free];
	else commentText = [[[[commentPanel contentView] subviews] objectAt:0] docView];
	[commentText setDelegate:self];

	[soundOutDevice getAttenuationLeft:&left right:&right];
	[self setMidi:[NXApp midi]];

	return self;
}

- free
 /* Free the note filters and instruments before freeing document. */
{
	int i;
	id filter, next;

	[Conductor lockPerformance];
	for (i = 0; i < MAXINSTRUMENTS; i++) {
		filter = noteFilters[i];
		while (filter) {
			next = [filter nextFilter];
			[filter setDocument:nil];
			[filter free];
			filter = next;
		}
	}
	for (i = 0; i < MAXINSTRUMENTS; i++) {
		if (instruments[i]) {
			[instruments[i] setDocument:nil];
			[instruments[i] free];
		}
	}
	[Conductor unlockPerformance];
	if (scoreFile)
		NX_FREE(scoreFile);
	return [super free];
}

- documentWillClose:sender
 /* Window is about to close. */
{
	[self disconnect];
	return self;
}

- textDidChange:sender
 /* Received from comments Text object if text is edited. */
{
	return [window setDocEdited:YES];
}

- setParamWindowTitle:(int)insNum
 /*
  * Set the instrument parameter window titles according to the document name. 
  */
{
	char title[MAXPATHLEN + 32];
	id win = nil;

	if ([instruments[insNum] respondsTo:@selector(inspector)])
		win = [instruments[insNum] inspector];
	if (win) {
		char *s;
		sprintf(title, "%s [%d] Parameters", fileName, insNum + 1);
		s = malloc(sizeof(char)+(strlen(title)+1));
		strcpy(s,title);
		[win setTitle:(const char *)s];
	}
	return self;
}

- setFilterWindowTitles:(int)inputNum
 /* Set the note filter window titles according to the document name. */
{
	char title[MAXPATHLEN + 32];
	id win;
	id filter;

	filter = [noteFilters[inputNum] nextFilter];
	while (filter) {
		win = [filter inspectorPanel];
		sprintf(title, "%s [%d] %s", fileName, inputNum + 1,
				filterNames[[filter position]]);
		[win setTitle:(const char *)title];
		filter = [filter nextFilter];
	}

	return self;
}

- addInstrumentView:instrument at:(int)position
 /* Add a new instrument view to one of the rectangular boxes in the lower
  * half of the document window. 
  */
{
	id insView = [instrument view];

	if (insView) {				/* Add the new view to the window */
		[insView setDrawOrigin:0 :0];
		[instrumentBoxes[position] addSubview:insView];
	}

	/* Update the display */
	[instrumentBoxes[position] display];
	NXPing();

	mouseDownSliders(insView);
	if ([instrument inspector])
		[self setParamWindowTitle:position];

	return self;
}

- setSamplingRate:(double)srate
 /* Set the sampling rate.  If changed, reset the orchestra. */
{
	if (!((srate == 44100.0) || (srate == 22050.0)))
		return nil;
	if (samplingRate != srate) {
		[window setDocEdited:YES];
		samplingRate = srate;
		if (keyDocument == self)
			[NXApp reset:self];
	}
	return self;
}

- setHeadroom:(double)value
 /*
  * Set the orchestra headroom factor. Provides fine adjustment over the
  * orchestra's idea of how many synthpatches will fit on the dsp. 
  */
{
	if (headroom != value) {
		[window setDocEdited:YES];
		headroom = value;
		if (keyDocument == self) {
			[Conductor lockPerformance];
			[orchestra setHeadroom:headroom];
			[Conductor unlockPerformance];
		}
	}
	return self;
}

- setLoadScore:(BOOL)load
 /*
  * Set whether to auto-load a score file next time this document is
  * unarchived. 
  */
{
	if (loadScore != load)
		[window setDocEdited:YES];
	loadScore = load;

	return self;
}

- setDocumentTempo:(int)aTempo
{
	tempo = aTempo;
	return self;
}

- (int)documentTempo
{
	return tempo;
}

- setDspNum:(int)num
 /*
  * For future compatibility with multi-DSP environments. Not guaranteed to
  * work at present. 
  */
{
	if (num != dspNum) {
		id orch;

		[Conductor lockPerformance];
		orch = [Orchestra newOnDSP:num];
		[Conductor unlockPerformance];
		if (orch && isConnected) {
			[self disconnect];
			orchestra = orch;
			[self connect];
		}
		[window setDocEdited:YES];
	}
	return self;
}

- setProgram:(int)number
{
	if (program != number) {
		int i;
		id doc;

		program = number;
		[window setDocEdited:YES];
		for (i = 0; i < [documents count]; i++) {
			doc = [documents objectAt:i];
			if (doc != self) {
				if ((program >= 0) && ([doc program] == program))
					[doc connect];
				else if ([doc program] < 128)
					[doc disconnect];
			}
		}
	}
	return self;
}

- setSoundDeemphasis:(BOOL)state
{
	deemphasis = state;
	[soundOutDevice setDeemphasis:deemphasis];
	return self;
}

- setHeadphoneLevel:(int)level
{
	headphoneLevel = level;
	if (headphoneLevel >= -84)
		[soundOutDevice setAttenuationLeft:headphoneLevel right:headphoneLevel];
	return self;
}

- (int)headphoneLevel
{
	return headphoneLevel;
}

- (BOOL)deemphasis
{
	return deemphasis;
}

- (double)samplingRate
{
	return samplingRate;
}

- (double)headroom
{
	return headroom;
}

- (BOOL)loadScore
{
	return loadScore;
}

- (char *)scoreFilePath
{
	return scoreFile;
}

- (int)dspNum
{
	return dspNum;
}

/* A linked list of NoteFilter instances is maintained for each input
 * stage.  "Enabled" note filters send notes down the chain, then finally
 * to one or more instruments or part recorders.  "Disabled" note filters
 * remain in their place in the chain, but neither send nor receive notes,
 * effectively behaving as if they weren't there (this is what happens when 
 * "ByPass" is selected on a note filter panel).
 *
 * Below, we always assume there is always at least one active noteFilter,
 * since there is no way to remove the KeyRange instances.
 */

- firstEnabledFilter:(int)inputNum
 /* Return the first enabled note filter in the linked list. */
{
	id filter = noteFilters[inputNum];

	while (filter && ![filter isEnabled])
		filter = [filter nextFilter];

	return filter;
}

- lastEnabledFilter:(int)inputNum
 /* Return the last enabled note filter in the linked list. */
{
	id filter = noteFilters[inputNum];
	id returnVal = nil;

	while (filter) {
		if ([filter isEnabled])
			returnVal = filter;
		filter = [filter nextFilter];
	}

	return returnVal;
}

- takeMidiChannelFrom:sender
 /* The instrument number is abs(tag)-1, and the increment is sign of tag */
{
	int tag = [[sender selectedCell] tag];
	int inc = (tag < 0) ? -1 : 1;
	int inputNum = ABS(tag) - 1;
	int midiChan = midiChannels[inputNum] + inc;
	id receiver;

	if (midiChan < 1)
		midiChan = 16;
	else if (midiChan > 16)
		midiChan = 1;

	[Conductor lockPerformance];
	/* The first destination of midi input notes is the note filter chain */
	receiver = [[self firstEnabledFilter:inputNum] noteReceiver];
	/* Disconnect from the previous channel note sender. */
	[[midi channelNoteSender:midiChannels[inputNum]] disconnect:receiver];
	[[midi channelNoteSender:0] disconnect:receiver];
	midiChannels[inputNum] = midiChan;
	/* Connect to the new channel note sender. */
	if (midiEnabled[inputNum]) {
		[[midi channelNoteSender:midiChan] connect:receiver];
		[[midi channelNoteSender:0] connect:receiver];
	}
	[Conductor unlockPerformance];
	[[midiChanDisplayer cellAt:0 :inputNum] setIntValue:midiChan];
	[window setDocEdited:YES];

	return self;
}

- takePartNumberFrom:sender
 /* The instrument number is abs(tag)-1, and the increment is sign of tag */
{
	int tag = [[sender selectedCell] tag];
	int inc = (tag < 0) ? -1 : 1;
	int inputNum = ABS(tag) - 1;
	int partNum = partNums[inputNum] + inc;
	id receiver, senders;

	if (partNum < 0)
		partNum = 7;
	else if (partNum > 7)
		partNum = 0;
	/* The first destination of score notes is the note filter chain */
	receiver = [[self firstEnabledFilter:inputNum] noteReceiver];
	/* Disconnect the first note filter form the old part. */
	[NXApp disconnectReceiver:receiver fromPart:partNums[inputNum]];
	/* Disconnect the last note filter from any partRecorders */
	senders = [[self lastEnabledFilter:inputNum] allSenders];
	[NXApp disconnectSenders:senders fromRecorder:partNums[inputNum]];
	partNums[inputNum] = partNum;
	/* Now connect to the new part */
	if (partEnabled[inputNum])
		[NXApp connectReceiver:receiver toPart:partNum];
	[NXApp connectSenders:senders toRecorder:partNum];
	[[partNumDisplayer cellAt:0 :inputNum] setIntValue:partNum + 1];
	[window setDocEdited:YES];

	return self;
}

- muteMidiInput:sender
 /* Disable or enable midi input to a particular filter chain */
{
	int n = [sender tag];
	id receiver = [[self firstEnabledFilter:n] noteReceiver];

	[Conductor lockPerformance];
	if (midiEnabled[n] = ![sender state]) {
		[[midi channelNoteSender:midiChannels[n]] connect:receiver];
		[[midi channelNoteSender:0] connect:receiver];
	} else {
		[[midi channelNoteSender:midiChannels[n]] disconnect:receiver];
		[[midi channelNoteSender:0] disconnect:receiver];
	}
	[Conductor unlockPerformance];
	[window setDocEdited:YES];

	return self;
}

- mutePartInput:sender;
 /* Disable or enable score input to a particular filter chain */
{
	int n = [sender tag];
	id receiver = [[self firstEnabledFilter:n] noteReceiver];

	if (partEnabled[n] = ![sender state])
		[NXApp connectReceiver:receiver toPart:partNums[n]];
	else
		[NXApp disconnectReceiver:receiver fromPart:partNums[n]];
	[window setDocEdited:YES];

	return self;
}

- addFilter:filterOrFilterClass toInput:(int)inputNum atPosition:(int)position
 /* Add or instantiate a note filter to a note filter linked list */
{
	id filter = nil;
	id class = nil;
	BOOL new = NO;
	BOOL enable = YES;

	if (!filterOrFilterClass)
		return nil;
	if ([filterOrFilterClass isKindOf:[EnsembleNoteFilter class]]) {
		/* adding an existing filter instance to this voice */
		id cell, menu = nil;
		char label[32];

		class = [filterOrFilterClass class];
		filter = noteFilters[inputNum];
		/* Look for an existing instance of this class */
		while (filter &&
			   !([filter isKindOf:class] && ([filter position] == position)))
			filter = [filter nextFilter];
		if (filter)
			[filter free];
		filter = filterOrFilterClass;
		if (enable = [filter isEnabled])
			[filter setEnabled:NO];
		new = YES;
		if (![filter isKindOf:[KeyRange class]]) {
			/*
			 * This filter is handled specially because it is instantiated
			 * automatically when the document is created. 
			 */
			menu = [filterButtons[inputNum] target];
			cell = [menu findCellWithTag:position];
			[filter setMenuCell:cell];
			sprintf(label, "Show %s", filterNames[position]);
			[cell setTitle:label];
			[menu display];
			NXPing();
		}
	} else {
		class = filterOrFilterClass;
		filter = noteFilters[inputNum];
		/* Look for an existing instance of this class */
		while (filter &&
			 !([filter isKindOf:class] && ([filter position] == position))) {
			/*
			 * Following line repairs old documents where lastFilter was not
			 * set correctly.  This caused problems deleting filters. 
			 */
			[[filter nextFilter] setLastFilter:filter];
			filter = [filter nextFilter];
		}
		if (!filter) {
			BOOL isActive = ([NXApp performanceStatus] == MK_active);

			/* none there, so create a new instance */
			id filterWindow;

			if (isActive)
				[(EnsembleApp *) NXApp pause];
			filter = [[class alloc] init];
			[filter setPosition:position];	/* Its position in the chain */
			filterWindow = [filter inspectorPanel];
			if (filterWindow) {	/* Center the window on the document */
				NXRect f1, f2;

				[window getFrame:&f1];
				[filterWindow getFrame:&f2];
				[filterWindow moveTo:NX_X(&f1) + (NX_WIDTH(&f1) - NX_WIDTH(&f2)) / 2
				 :NX_Y(&f1) + (NX_HEIGHT(&f1) - NX_HEIGHT(&f2)) / 2];
				[[filter inspectorPanel] makeKeyAndOrderFront:self];
				NXPing();
			}
			if (isActive)
				[(EnsembleApp *) NXApp resume];
			new = YES;
		}
	}
	if (new) {
		char newtitle[MAXPATHLEN + 32];
		id tmp = noteFilters[inputNum];
		id next;

		if (!tmp) {
			noteFilters[inputNum] = filter;
			[filter setNextFilter:nil];
			[filter setLastFilter:nil];
		} else {				/* Find the right place in the chain to insert
								 * this filter */
			while (tmp && [tmp nextFilter] &&
				   ([[tmp nextFilter] position] <= position))
				tmp = [tmp nextFilter];
			next = [tmp nextFilter];
			[tmp setNextFilter:filter];
			[filter setLastFilter:tmp];
			[filter setNextFilter:next];
			[next setLastFilter:filter];
		}
		sprintf(newtitle, "%s [%d] %s", fileName, inputNum + 1,
				filterNames[[filter position]]);
		[[filter inspectorPanel] setTitle:(const char *)newtitle];
		[filter setInputNum:inputNum];
		[filter setDocument:self];
		[filter setEnabled:enable];
		[window setDocEdited:YES];
	}
	return filter;
}

- takeNoteFilterFrom:sender
 /*
  * Select a note filter from a filter pull-down menu on the document. The
  * absolute value of the first menu element's tag indicates which input stage
  * this is for 
  */
{
	id filter;
	id cell = [sender selectedCell];
	int inputNum = abs([[sender cellAt:0:0] tag]) - 1;
	int filterNum = [cell tag];
	char label[32];

	if (filterNum >= 0) {
		filter = [self addFilter:objc_getClass(filterClasses[filterNum])
				  toInput :inputNum atPosition:filterNum];
		if (filter) {
			[filter showInspector];
			[filter setMenuCell:cell];
		}
		sprintf(label, "Show %s", filterNames[filterNum]);
		[cell setTitle:label];
		[sender display];
	}
	return self;
}

- takeInstrumentNumberFrom:sender
 /* Connect or disconnect a note filter chain and an instrument. */
{
	id cell = [sender selectedCell];
	int inputNum = [sender tag];
	int insNum = [cell tag];
	id senders;

	senders = [[self lastEnabledFilter:inputNum] allSenders];
	[Conductor lockPerformance];
	if (instrumentMap[inputNum][insNum] = [cell state])
		[senders makeObjectsPerform:@selector(connect:)
		 with :[instruments[insNum] noteReceiver]];
	else
		[senders makeObjectsPerform:@selector(disconnect:)
		 with :[instruments[insNum] noteReceiver]];
	[Conductor unlockPerformance];
	[window setDocEdited:YES];

	return self;
}

- addInstrument:insClass number:(int)insNum
 /* Create or replace an instrument */
{
	int i;
	id instrument = nil, oldInstrument;
	int nPatches = 0;
	BOOL isActive = ([NXApp performanceStatus] == MK_active);

	if ([insClass isKindOf:[Instrument class]]) {
		instrument = insClass;
		insClass = [instrument class];
	}
	/* If there is a different existing instrument there, flush it. */
	oldInstrument = instruments[insNum];
	if (oldInstrument && (!instrument) && [oldInstrument isMemberOf:insClass])
		return nil;
	if (isActive)
		[(EnsembleApp *) NXApp pause];
	/* Stop any note-generating routines and abort any active synthpatches */
	if (oldInstrument) {
		[Conductor lockPerformance];
		[oldInstrument abort];
		[[oldInstrument noteReceiver] disconnect];
		instruments[insNum] = nil;
		if ([oldInstrument isKindOf:[EnsembleSynthIns class]]) {
			nPatches = [oldInstrument patchAllocation];
			[oldInstrument setSynthPatchCount:0];
			usesDSP = NO;
			for (i = 0; i < MAXINSTRUMENTS; i++)
				if ([instruments[i] isKindOf:[SynthInstrument class]]) {
					usesDSP = YES;
					break;
				}
		}
		[[oldInstrument view] free];
		[oldInstrument free];
		[Conductor unlockPerformance];
	}
	[Conductor lockPerformance];
	if (!instrument)
		instrument = [[insClass alloc] init];
	instruments[insNum] = instrument;
	[self addInstrumentView:instrument at:insNum];
	[Conductor unlockPerformance];
	if (instrument) {
		MKDeviceStatus orchStatus = [orchestra deviceStatus];
		const char *name;
		[instrument setDocument:self];
		/* If new dsp instrument added, allocate synthpatches */
		if ([instrument isKindOf:[SynthInstrument class]]) {
			usesDSP = YES;
			[instrument setPatchAllocation:(nPatches) ? nPatches : (nPatches = 3)];
		} else {				/* Check for change in use of DSP */
			usesDSP = NO;
			for (i = 0; i < MAXINSTRUMENTS; i++)
				if ([instruments[i] isKindOf:[SynthInstrument class]]) {
					usesDSP = YES;
					break;
				}
			if (!docUsingDSP() && (orchStatus == MK_devRunning))
				[orchestra abort];
		}
		for (i = 0; i < MAXINSTRUMENTS; i++)	/* Connect new instrument to
												 * filters */
			if (instrumentMap[i][insNum])
				[self connectToInstruments:[self lastEnabledFilter:i]];
		name = [[instrument class] name];
		for (i=0; i<NUMINSCLASSES; i++)
			if (!strcmp(instrumentClasses[i],name)) break;
		[instrumentButtons[insNum] setTitle:instrumentNames[i]];
	}
	[Conductor lockPerformance];
	if (isActive)				/* Resume an on-going performance in 1 sec. */
		[[Conductor clockConductor] sel:@selector(resume)
		 to :NXApp withDelay:1.0 argCount:0];
	[Conductor unlockPerformance];

	return instrument;
}

- takeInstrumentFrom:sender
 /* Select an instrument from the document's pop-up list. */
{
	int insNum, classNum;
	id class;

	/* tag of "inactive" item indicates which instrument number */
	insNum = abs([[sender cellAt:0 :0] tag]) - 1;
	/* item tag indicates type of instrument, e.g. Wave1, Midi, etc. */
	classNum = [[sender selectedCell] tag];
	class = (classNum >= 0) ? objc_getClass(instrumentClasses[classNum]) : nil;
	[self addInstrument:class number:insNum];
	if ([instruments[insNum] isKindOf:[SynthInstrument class]]) {
		if (([orchestra deviceStatus] != MK_devRunning) ||
			([instruments[insNum] isKindOf:[ResonInstrument class]] &&
			 ![orchestra serialSoundIn]))
			[NXApp reset:self];
		else {
			[instruments[insNum] allocatePatches];
			[NXApp synchDSPDelayed:1.0];
		}
		[instruments[insNum] displayPatchCount];
	}
	[window setDocEdited:YES];

	return self;
}

- sendTestNote:sender
 /* Send a 2 second test note to an instrument. */
{
	static id aNote = nil;
	id instrument = instruments[[sender tag]];

	[Conductor lockPerformance];
	if (!aNote)
		[aNote = [[Note alloc] init] setDur:2.0];
	[aNote setNoteTag:MKNoteTag()];
	[aNote setPar:MK_keyNum toInt:[instrument testKey]];
	[[instrument noteReceiver] receiveNote:aNote];
	[Conductor unlockPerformance];

	return self;
}

- muteInstrument:sender
 /*
  * Block or allow an instrument to receive notes by squelching or
  * unsquelching its note receiver. 
  */
{
	id instrument = instruments[[sender tag]];

	[Conductor lockPerformance];
	if ([sender state])
		[[instrument noteReceiver] squelch];
	else
		[[instrument noteReceiver] unsquelch];
	[Conductor unlockPerformance];
	[window setDocEdited:YES];

	return self;
}

- controllers:(int)insNum
 /* returns the state of the given instrument's MIDI controllers */
{
	id updates, controllerTable = nil;

	if ((self == keyDocument) && instruments[insNum] &&
		[instruments[insNum] isKindOf:[SynthInstrument class]])
		[instruments[insNum] getUpdates:&updates
		 controllerValues:&controllerTable];

	return controllerTable;
}

- updates:(int)insNum
 /* Returns the update note of the given instrument */
{
	id updates = nil, controllerTable;

	[Conductor lockPerformance];
	if ((self == keyDocument) && instruments[insNum])
		[instruments[insNum] getUpdates:&updates
		 controllerValues:&controllerTable];
	[Conductor unlockPerformance];

	return updates;
}

- (int)partNum:(int)inputNum
 /* Return the part number of the given input stage. */
{
	return partNums[inputNum];
}

- (BOOL *)instrumentMap:(int)inputNum
 /* Return the input to instrument map. */
{
	return instrumentMap[inputNum];
}

- (id *)instruments
 /* Return the array of instruments. */
{
	return instruments;
}

- connectToPerformers:aNoteFilter
 /* Connect the given note filter to the appropriate performers */
{
	int inputNum = [aNoteFilter inputNum];
	id receiver = [aNoteFilter noteReceiver];

	[Conductor lockPerformance];
	if (partEnabled[inputNum])
		[NXApp connectReceiver:receiver toPart:partNums[inputNum]];
	if (midiEnabled[inputNum]) {
		[[midi channelNoteSender:midiChannels[inputNum]] connect:receiver];
		[[midi channelNoteSender:0] connect:receiver];
	}
	[NXApp connectReceiverToClavier:receiver];
	[Conductor unlockPerformance];

	return self;
}

- disconnectFromPerformers:aNoteFilter
 /* Disconnect the given note filter from the appropriate performers */
{
	int inputNum = [aNoteFilter inputNum];
	id receiver = [aNoteFilter noteReceiver];

	[Conductor lockPerformance];
	[NXApp disconnectReceiver:receiver fromPart:partNums[inputNum]];
	[[midi channelNoteSender:midiChannels[inputNum]] disconnect:receiver];
	[[midi channelNoteSender:0] disconnect:receiver];
	[NXApp disconnectReceiverFromClavier:receiver];
	[Conductor unlockPerformance];

	return self;
}

- connectToInstruments:aNoteFilter
 /* Connect the given note filter to the appropriate instruments */
{
	int i;
	int inputNum;
	id senders;

	[Conductor lockPerformance];
	inputNum = [aNoteFilter inputNum];
	senders = [aNoteFilter allSenders];
	for (i = 0; i < MAXINSTRUMENTS; i++)
		if (instrumentMap[inputNum][i])
			[senders makeObjectsPerform:@selector(connect:)
			 with :[instruments[i] noteReceiver]];
	[Conductor unlockPerformance];
	[NXApp connectSenders:senders toRecorder:partNums[inputNum]];
	[senders free];

	return self;
}

- allocatePatches
{
	int i;

	for (i = 0; i < MAXINSTRUMENTS; i++) {
		if (instruments[i] && [instruments[i] isKindOf:[SynthInstrument class]])
			[instruments[i] allocatePatches];
	}
	return self;
}

- displayPatchCounts
{
	int i;

	for (i = 0; i < MAXINSTRUMENTS; i++) {
		if (instruments[i] &&
			[instruments[i] isKindOf:[SynthInstrument class]])
			[instruments[i] displayPatchCount];
	}
	NXPing();
	return self;
}

- setMidi:newMidi
{
	if (newMidi != midi) {
		int i;

		if (isConnected) {
			[self disconnect];
			midi = newMidi;
			[self connect];
		} else
			midi = newMidi;
		for (i = 0; i < MAXINSTRUMENTS; i++)
			if (instruments[i] &&
				[instruments[i] isKindOf:[MidiOutInstrument class]])
				[instruments[i] setMidi:midi];
	}
	return self;
}

- connect
 /*
  * Connect the entire document to performers and recorders. Load the DSP
  * instrument's synthpatches onto the DSP. 
  */
{
	int i;
	id senders;
	id note = [[Note alloc] init];

	if (isConnected)
		return self;

	[Conductor lockPerformance];
	[orchestra setHeadroom:headroom];
	if (loadScore && scoreFile && strcmp(scoreFile, scoreFilePath))
		[NXApp getScoreFile:scoreFile];
	if (tempo)
		[NXApp setTempoFromDocument:tempo];
	isConnected = YES;

	/* Stop the performance if the sampling rate has to change */
	if (usesDSP && ([orchestra deviceStatus] == MK_devRunning) &&
		([orchestra samplingRate] != samplingRate)) {
		[NXApp stop:self];
		[(EnsembleApp *) NXApp stop];
	}
	for (i = 0; i < MAXINSTRUMENTS; i++) {
		[self connectToPerformers:[self firstEnabledFilter:i]];
		senders = [[self lastEnabledFilter:i] allSenders];
		[NXApp connectSenders:senders toRecorder:partNums[i]];
		[senders free];
	}

	/* Load the patches if the orchestra is around */
	if (usesDSP && ([orchestra deviceStatus] == MK_devRunning))
		[self allocatePatches];

	[self setHeadphoneLevel:headphoneLevel];
	[self setSoundDeemphasis:deemphasis];

	MKSetNoteParToInt(note, MK_sysRealTime, MK_sysReset);
	for (i = 0; i < MAXINSTRUMENTS; i++)
		[[[self firstEnabledFilter:i] noteReceiver] receiveNote:note];

	[Conductor unlockPerformance];
	[note free];
	return self;
}

- disconnect
 /*
  * Disconnect the entire document from performers and recorders. Save the
  * number of synthpatches for DSP instruments, then set them to 0 and abort
  * them, in order to free up their space. 
  */
{
	int i;
	id instrument, senders;

	if (!isConnected)
		return self;

	[Conductor lockPerformance];

	for (i = 0; i < MAXINSTRUMENTS; i++) {
		[self disconnectFromPerformers:[self firstEnabledFilter:i]];
		senders = [[self lastEnabledFilter:i] allSenders];
		[NXApp disconnectSenders:senders fromRecorder:partNums[i]];
		[senders free];
	}

	if ([orchestra deviceStatus] == MK_devRunning)
		for (i = 0; i < MAXINSTRUMENTS; i++) {
			instrument = instruments[i];
			if (instrument) {
				[instrument abort];
				if ([instrument isKindOf:[SynthInstrument class]])
					[instrument setSynthPatchCount:0];
			}
		}

	[Conductor unlockPerformance];
	isConnected = NO;

	return self;
}

- (BOOL)isConnected
{
	return isConnected;
}

- makekeyDocument
{
	id *doc;
	int n;
	BOOL usingDSP = usesDSP;

	keyDocument = self;
	if (isConnected)
		return self;

	/*
	 * Disconnect any documents with a different or no program number. A
	 * program number > 127 means always stay connected. 
	 */
	for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
		if ((*doc != self) && ([*doc program] < 128) &&
			(([*doc program] == -1) || ([*doc program] != program)))
		  {
		      if ([NXApp performanceStatus] != MK_inactive)
			[NXApp stop:nil];
		      [*doc disconnect];
		  }

	[self connect];

	/* Connect any other documents with the same program number */
	if (program >= 0)
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if ((*doc != self) && ([*doc program] == program) &&
				([*doc program] != -1)) {
				[*doc connect];
				usingDSP = (usingDSP || [*doc usesDSP]);
			}
	/* Flush the DSP orchestra if it's no longer needed */
	if (!usingDSP && ([orchestra deviceStatus] == MK_devRunning)) {
		[Conductor lockPerformance];
		[orchestra abort];
		[Conductor unlockPerformance];
	}
	return self;
}

- documentDidBecomeKey:sender
{
	static int nesting = 0;

	nesting++;
	if (nesting == 1) {
		[self makekeyDocument];
		if (![Conductor inPerformance] ||
			(usesDSP && ([orchestra deviceStatus] != MK_devRunning)))
			[NXApp reset];
	}
	nesting--;
	return self;
}

- documentDidResignKey:sender
 /* Deselect any instrument or input if the window stops being key. */
{
	[insSelectButtons selectCellAt:-1:-1];
	[inputSelectButtons selectCellAt:-1:-1];
	selectedInput = -1;
	selectedInstrument = -1;

	return self;
}

- (BOOL)usesDSP
{
	return usesDSP;
}

- (BOOL)inputFromSSI
{
	int i;

	for (i = 0; i < MAXINSTRUMENTS; i++)
		if ([instruments[i] isKindOf:[ResonInstrument class]])
			return YES;
	return NO;
}


- (int)program
{
	return program;
}

- (BOOL)saveDocumentToPath:(char *)path
 /*
  * Save the document by archiving it to a file. It is unsafe to do file i/o
  * in a multi-thread situation, so stop the performance first, then restart
  * it after. 
  */
{
	NXTypedStream *ts;
	[NXApp stop:self];
	[(EnsembleApp *) NXApp stop];
	[self disconnect];
	ts = NXOpenTypedStreamForFile(path, NX_WRITEONLY);
	if (ts) {
		[window setDocEdited:NO];
		NXWriteRootObject(ts, self);
		NXCloseTypedStream(ts);
	} else
		return NO;
	if (scoreFilePath) {
		if (scoreFile) free(scoreFile);
		scoreFile = malloc(strlen(scoreFilePath)+1);
		strcpy(scoreFile, scoreFilePath);
	}
	[self connect];
	[(EnsembleApp *) NXApp reset];

	return YES;
}

- loadDocumentFromPath:(char *)path
 /* Load a document from a typed stream file. */
{
	id doc;
	NXTypedStream *ts;
	ts = NXOpenTypedStreamForFile(path, NX_READONLY);
	if (ts) {
		[window setDocEdited:NO];
		doc = NXReadObject(ts);
		NXCloseTypedStream(ts);
		[doc awake];
	} else
		return nil;
	return doc;
}

- setWindowTitles
 /*
  * Set all filter panel and instrument parameter panel titles according to
  * the current document's title. 
  */
{
	int i;

	[window setTitleAsFilename:filePath];
	for (i = 0; i < MAXINSTRUMENTS; i++) {
		[self setParamWindowTitle:i];
		[self setFilterWindowTitles:i];
	}
	return self;
}

- selectInput:sender
 /* Select an input stage to paste a note filter to */
{
	int n = [[sender selectedCell] tag];

	[insSelectButtons selectCellAt:-1:-1];
	if (n == selectedInput) {
		[inputSelectButtons selectCellAt:-1:-1];
		selectedInput = -1;
	} else {
		selectedInput = n;
	}

	return self;
}

- selectInstrument:sender
 /* Select an instrument for cutting, copying or pasting */
{
	int n = [[sender selectedCell] tag];

	[inputSelectButtons selectCellAt:-1:-1];
	if (n == selectedInstrument) {
		[insSelectButtons selectCellAt:-1:-1];
		selectedInstrument = -1;
	} else
		selectedInstrument = n;

	return self;
}

- commentPanel
{
	return commentPanel;
}

- write:(NXTypedStream *) stream
 /* Archive this document to a typed stream. */
{
	int n = MAXINSTRUMENTS;
	[super write:stream];
	NXWriteTypes(stream, "ddicc@iii",
				 &samplingRate, &headroom, &dspNum, &loadScore, &usesDSP,
				 &commentText, &program, &tempo, &n);
	NXWriteArray(stream, "@", n, noteFilters);
	NXWriteArray(stream, "@", n, instruments);
	NXWriteArray(stream, "i", n, partNums);
	NXWriteArray(stream, "i", n, midiChannels);
	NXWriteArray(stream, "c", n, midiEnabled);
	NXWriteArray(stream, "c", n, partEnabled);
	NXWriteArray(stream, "c", n * n, instrumentMap);
	n = (loadScore && (scoreFilePath)) ? strlen(scoreFilePath) : 0;
	NXWriteType(stream, "i", &n);
	NXWriteArray(stream, "c", n, scoreFilePath);
	NXWriteTypes(stream, "ic", &headphoneLevel, &deemphasis);
	return self;
}

- read:(NXTypedStream *) stream
 /* Read this document from a typed stream. */
{
	int version;
	int n = MAXINSTRUMENTS;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "EnsembleDoc");
	NXReadTypes(stream, "ddicc@iii",
				 &samplingRate, &headroom, &dspNum, &loadScore, &usesDSP,
				 &commentText, &program, &tempo, &n);
	if (version == 1) {
		id panel = commentText;
		commentText = [[[[panel contentView] subviews] objectAt:0] docView];
		[commentText removeFromSuperview];
		[panel free];
	}
	NXReadArray(stream, "@", n, noteFilters);
	NXReadArray(stream, "@", n, instruments);
	NXReadArray(stream, "i", n, partNums);
	NXReadArray(stream, "i", n, midiChannels);
	NXReadArray(stream, "c", n, midiEnabled);
	NXReadArray(stream, "c", n, partEnabled);
	NXReadArray(stream, "c", n * n, instrumentMap);
	if (version == 1) {
		NXReadTypes(stream, "@@@",
				&insSelectButtons, &midiChanDisplayer, &partNumDisplayer);
		NXReadArray(stream, "@", n, instrumentBoxes);
		NXReadArray(stream, "@", n, filterButtons);
		NXReadArray(stream, "@", n, instrumentButtons);
	}
	NXReadType(stream, "i", &n);
	scoreFile = malloc(n+1);
	NXReadArray(stream, "c", n, scoreFile);
	scoreFile[n] = '\0';
	NXReadTypes(stream, "ic", &headphoneLevel, &deemphasis);
	return self;
}

- fixFilters
	/* Arg - If I add a new note filter somewhere, the archived positions will be
	 * wrong, so check them here.
	 */
{
	int i, j, diff;
	id filter;

	for (i = 0; i < MAXINSTRUMENTS; i++) {
		filter = noteFilters[i];
		[filter setDocument:self];
		/* Start with the second filter (the KeyRange will always be correct) */
		while (filter = [filter nextFilter]) {
			[filter setDocument:self];
			for (j = 0; j < NUMFILTERS; j++)
				if ([filter isMemberOfClassNamed:filterClasses[j]]) {
					diff = [filter position]-j;
					if (ABS([filter position]-j) < 3) {
						[filter setPosition:j];
						break;
					}
				}
		}
	}
	return self;
}

- awake
 /* Initialize some things which are not archived */
{
	int i;
	[super awake];
	delegate = self;
	[self fixFilters];
	NX_MALLOC(filePath, char, MAXPATHLEN + 1);
	NX_MALLOC(fileName, char, MAXPATHLEN + 1);
	NX_MALLOC(fileDir, char, MAXPATHLEN + 1);
	orchestra = [Orchestra newOnDSP:dspNum];
	[self setMidi:[NXApp midi]];
	for (i = 0; i < MAXINSTRUMENTS; i++) {
		[instruments[i] setDocument:self];
	}
	if (loadScore && scoreFile)
		[NXApp getScoreFile:scoreFile];
	return self;
}

- copy:sender
{
	/* Archive an instrument or document to the pasteboard. */
	char *data = NULL;
	const char *types[1];
	int length;
	id ins;

	[Conductor lockPerformance];
	if ((selectedInstrument >= 0) &&
		(ins = instruments[selectedInstrument])) {
		types[0] = InstrumentPBType;
		[pasteboard declareTypes:types num:1 owner:self];
		data = NXWriteRootObjectToBuffer(ins, &length);
	}
	if (data) {
		[pasteboard writeType:types[0] data:data length:length];
		NXFreeObjectBuffer(data, length);
	}
	[Conductor unlockPerformance];

	return self;
}

- paste:sender
 /* unarchive an instrument, document, or noteFilter from the pasteboard. */
{
	char *data;
	int length;
	NXStream *stream;
	NXTypedStream *ts;
	id object;
	const char *const * types = [pasteboard types];

	[Conductor lockPerformance];
	if ((!strcmp(types[0], InstrumentPBType)) &&
			   (selectedInstrument >= 0)) {
		int i;
		id button;

		[pasteboard readType:InstrumentPBType data:&data length:&length];
		stream = NXOpenMemory(data, length, NX_READONLY);
		ts = NXOpenTypedStream(stream, NX_READONLY);
		object = NXReadObject(ts);
		NXCloseTypedStream(ts);
		NXCloseMemory(stream, NX_FREEBUFFER);
		if (object) {
			[self addInstrument:object number:selectedInstrument];
			if ([object isKindOf:[SynthInstrument class]]) {
				[object allocatePatches];
				[NXApp synchDSPDelayed:1.0];
			} else if ([object isKindOf:[SamplerInstrument class]])
				[object reset];
		}
		button = instrumentButtons[selectedInstrument];
		for (i = 0; i < NUMINSCLASSES; i++)
			if (!strcmp(instrumentClasses[i],[[object class] name]))
				break;
		[button setTitle:[[[button target] findCellWithTag:i] title]];
	} else if ((!strcmp(types[0], NoteFilterPBType)) &&
			   (selectedInput >= 0)) {
		[pasteboard readType:NoteFilterPBType data:&data length:&length];
		stream = NXOpenMemory(data, length, NX_READONLY);
		ts = NXOpenTypedStream(stream, NX_READONLY);
		object = NXReadObject(ts);
		NXCloseTypedStream(ts);
		NXCloseMemory(stream, NX_FREEBUFFER);
		if (object)
			[self addFilter:object toInput:selectedInput
			 atPosition:[object position]];
	}
	[Conductor unlockPerformance];

	return self;
}

- delete:sender
{
	if ((selectedInstrument >= 0) && instruments[selectedInstrument]) {
		[self addInstrument:nil number:selectedInstrument];
		[instrumentButtons[selectedInstrument] setTitle:"Inactive"];
	} else if (selectedInput >= 0)
		return self;
	else
		[window performClose:self];

	return self;
}


- cut:sender
 /* Copy the selected item to the pasteboard, then flush it. */
{
	[self copy:sender];
	[self delete:sender];

	return self;
}

@end
