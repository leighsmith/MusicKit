/* 
 * EnsembleApp - a subclass of Application.
 * Handles documents, scores, and performances.
 */

#import "EnsembleApp.h"
#import "EnsembleDoc.h"
#import "EnsembleNoteFilter.h"
#import "Wave1Instrument.h"
#import "SamplerInstrument.h"
#import "Preferences.h"
#import "ParamInterface.h"
#import <appkit/appkit.h>
#import <MusicKit/midi_spec.h>
#import <mach/cthreads.h>

static void errProc(char *msg)
{								/* A null function (see MKSetErrorProc below) */
}

/************  Static Variables local to the application ************/

BOOL multiThreaded;
static Note *updateNote;		/* A shared note for updates */
Score *score = nil;				/* The playback score */
static PartPerformer *partPerformers[MAXPARTS];	/* A PartPerformer for each part */
static Part *recordParts[MAXPARTS];				/* Parts which record notes */
static PartRecorder *partRecorders[MAXPARTS];	/* A PartRecorder for each part */
static BOOL recordEnabled[MAXPARTS];		/* Record enable flag for each part */
static id controllers[MAXINSTRUMENTS];		/* Stores state of MIDI controllers */
static PartPerformer *midiPartPerformer0;	/* Performer for sys ex part */
static BOOL recording = NO;					/* YES when recording is happening */
char scoreFilePath[MAXPATHLEN + 1];			/* Complete score file path */
char scoreFileDir[MAXPATHLEN + 1];	/* Just the directory */
char scoreFileName[MAXPATHLEN + 1];	/* Just the name */
static int tempo = 60;						/* Current tempo */
static double recordBeginTime;				/* Stores when recording begins */
static int selectedPart = -1;				/* Number of selected part */

BOOL batchMode = NO;
BOOL newRanVals = NO;
char *soundFile = NULL;
id soundOutDevice = nil;
BOOL robustSound;

/* Scores can be saved as Scorefiles, Midi files, or DSPCommands files */
static enum _saveType {
	SAVE_SCORE, SAVE_MIDI, SAVE_COMMANDS, SAVE_SOUND
} saveType;
static char *fileIcons[] = {"Score", "Midi", "Sound", "Sound"};
static char *fileTypes[] = {"Score File", "MIDI File", "DSPCommands File",
							"Sound File"};
static char *fileExtensions[] = {"score", "midi", "snd", "snd"};

extern id documents;

extern int activeSoundMax;

/* Ensemble supports copying and pasting of documents, parts, note filters,
 * and instruments.
 */
id pasteboard;
const char DocumentPBType[] = "EnsembleDoc";
const char NoteFilterPBType[] = "EnsembleNoteFilter";
const char InstrumentPBType[] = "EnsembleInstrument";
const char PartPBType[] = "EnsemblePart";

static id accessoryView;
extern void parsePath(char *path, char *dir, char *name);
extern void getPath(char *path, char *dir, char *name, char *ext);
extern BOOL fileExists(const char *name);

int fileType(char *name)
 /* return the file type for the specified name */
{
	char *ext;

	ext = strrchr(name, '.');
	if (!ext)
		return SAVE_SCORE;
	if (!strcmp(ext, ".midi"))
		return SAVE_MIDI;
	else if (!strcmp(ext, ".snd"))
		return (soundFile) ? SAVE_SOUND : SAVE_COMMANDS;

	return SAVE_SCORE;
}

static double latestTimeTag(id score)
 /*
  * Find the latest time tag in a score.  Used to determine when to close a
  * DSP commands file. 
  */
{
	id parts = [score parts];
	id part, notes;
	int i;
	double time;
	double latestTime = 0;

	for (i = 0; i < [parts count]; i++) {
		part = [parts objectAt:i];
		if ([part noteCount] > 0) {
			[part sort];
			notes = [part notesNoCopy];
			time = [[notes lastObject] timeTag];
			if ((time != MK_ENDOFTIME) && (latestTime < time))
				latestTime = time;
		}
	}

	return latestTime;
}

void mouseDownSliders(id view)
 /*
  * Convert all sliders and buttons which are decendants in the view heirarchy
  * from the specified view to send their action on mouse downs instead of
  * mouse ups (the default).  Recursive. 
  */
{
	id subviews = [view subviews];
	int n = (subviews) ? [subviews count] : 0;
	int i;
	id cells;

	if ([view isKindOf:[Slider class]])
		[view sendActionOn:(NX_MOUSEDOWNMASK | NX_MOUSEDRAGGEDMASK)];
	else if (([view isKindOf:[Matrix class]]) &&
			 ([[view prototype] isKindOf:[SliderCell class]])) {
		cells = [view cellList];
		for (i = 0; i < [cells count]; i++)
			[[cells objectAt:i]
			 sendActionOn:(NX_MOUSEDOWNMASK | NX_MOUSEDRAGGEDMASK)];
	} else if ([view isKindOf:[Button class]])
		[view sendActionOn:NX_MOUSEDOWNMASK];
	else if (([view isKindOf:[Matrix class]]) &&
			 ([[view prototype] isKindOf:[ButtonCell class]])) {
		cells = [view cellList];
		for (i = 0; i < [cells count]; i++)
			[[cells objectAt:i] sendActionOn:NX_MOUSEDOWNMASK | NX_PERIODICMASK];
	}
	for (i = 0; i < n; i++)
		mouseDownSliders([subviews objectAt:i]);
}

@implementation EnsembleApp:Application
{
}

#define SOUND_IN_SEPARATE_THREAD NO

- initSoundOut
{
	robustSound = [preferences bigBuffers];

	if (soundOutDevice) {
		[soundOutDevice abortStreams:self];
		[soundOutDevice setReserved:NO];
		[soundOutDevice free];
	}
	[NXSoundOut setUseSeparateThread:SOUND_IN_SEPARATE_THREAD];
	[NXSoundOut setTimeout:250];

	if (soundOutDevice = [[NXSoundOut alloc] init]) {
		[soundOutDevice setRampsUp:NO];
		[soundOutDevice setRampsDown:robustSound];
		[soundOutDevice setBufferCount:(robustSound) ? 5 : 4];
		[soundOutDevice setBufferSize:1024];
		[soundOutDevice setBufferCount:(robustSound) ? 5 : 4];
	} else if (NXRunAlertPanel("Ensemble", "Cannot get SoundOut Device.",
							   "Ok", "Quit", NULL) != NX_ALERTDEFAULT)
		exit(0);

	if (documents) {
		id *doc;
		int i, n;

		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if ([*doc isConnected])
				for (i = 0; i < MAXINSTRUMENTS; i++)
					if ([[*doc instruments][i] isKindOf:[SamplerInstrument class]])
						[[*doc instruments][i] reset];
	}
	activeSoundMax = [preferences soundMax];
	return self;
}

id docUsingDSP()
{
	int n = (documents) ? [documents count] : 0;
	id *doc;
	if (n > 0)
		for (doc = NX_ADDRESS(documents); n--; doc++)
			if ([*doc isConnected] && [*doc usesDSP])
				return *doc;
	return nil;
}

id docInputFromSSI()
{
	int n = (documents) ? [documents count] : 0;
	id *doc;
	if (n > 0)
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if ([*doc isConnected] && [*doc inputFromSSI])
				return *doc;
	return nil;
}

#define SMALL_BUFFER_BYTES 1024
#define LARGE_BUFFER_BYTES 8192

- setDeltaT:(double)aDeltaT
{
	id dspDoc = docUsingDSP();
	BOOL fast = (aDeltaT <.1);
	int buffSamps = 4 * (((fast) ? SMALL_BUFFER_BYTES : LARGE_BUFFER_BYTES) >> 1);

	if (dspDoc) {
		[Orchestra setFastResponse:fast];
		MKSetDeltaT(aDeltaT);
		/* compensate MIDI for the sound output buffer latency */
		[midi setLocalDeltaT:buffSamps / [dspDoc samplingRate]];
	} else {
		MKSetDeltaT(([preferences midiTimedOutput]) ? aDeltaT : 0);
		[midi setLocalDeltaT:0.0];
	}

	return self;
}


- appWillInit:sender
 /* Initialize anything which only needs initializing once. */
{
	int i;
	id info;

	[self setDelegate:self];
	[[self appSpeaker] setSendPort:NXPortFromName(NX_WORKSPACEREQUEST, NULL)];
	[self loadNibSection:"Preferences.nib" owner:self withNames:NO];
	[preferences center];
	orchestra = [Orchestra newOnDSP:0];	/* Orchestra for the resident DSP */
	MKSetErrorProc(&errProc);	/* Disable error printing */
	[self initSoundOut];
	[Orchestra setTimed:MK_TIMED];	/* DSP handles timing of commands */
	[Conductor setThreadPriority:1.0];	/* at higher priority than the app */
#if SOUND_IN_SEPARATE_THREAD
	/* Disable fixed policy due to objc thread deadlock problems in NeXT 3.0 */
	system("/usr/local/lib/MusicKit/bin/fixedpolicy -d -q");
	/*
	 * Note that we don't reenable fixedpolicy--thus it remains disabled until
	 * a new Music Kit app is launched (or some other app that enables
	 * fixedpolicy 
	 */
#endif
	[PartPerformer setFastActivation:YES];	/* Don't copy notes upon
											 * activation */
	for (i = 0; i < MAXPARTS; i++) {
		partPerformers[i] = [[PartPerformer alloc] init];
		partRecorders[i] = [[PartRecorder alloc] init];
		[partRecorders[i] setTimeUnit:MK_beat];
		[partRecorders[i] setPart:recordParts[i] = [[Part alloc] init]];
		recordEnabled[i] = NO;
	}
	midiPartPerformer0 = [[PartPerformer alloc] init];
	info = [[Note alloc] init];	/* The score info note */
	[info setPar:MK_tempo toInt:tempo];
	[score setInfo:info];		/* copies the note */
	[info free];
	sprintf(scoreFilePath, "/LocalLibrary/Music/Midi/");
	sprintf(scoreFileDir, "/LocalLibrary/Music/Midi/");
	*scoreFileName = '\0';
	updateNote = [[Note alloc] init];	/* General purpose note for updates */
	[updateNote setNoteType:MK_noteUpdate];
	saveType = -1;
	status = MK_inactive;		/* Ensemble's performance status */
	pasteboard = [Pasteboard new];
	/*
	 * Add a port so that the Music Kit thread can communicate with the main
	 * thread. When the port gets a message, invoke the function
	 * musicKitToAppPort() with self as an argument. 
	 */
	multiThreaded = [preferences multiThreaded];
	return self;
}

- awakeFromNib
{
	[partSelectButtons setEmptySelectionEnabled:YES];
	[partSelectButtons selectCellAt:-1:-1];
	[window setMiniwindowIcon:"EnsembleApp"];
	[window setDelegate:self];
	if (!batchMode)
		[window makeKeyAndOrderFront:self];
	mouseDownSliders([window contentView]);	/* See mouseDownSliders comment */
	return self;
}

- setSaveType:(int)type
 /* Set the Save panel accessory view icon and label according to type. */
{
	saveType = type;
	if (!accessoryView)
		accessoryView = [[Button alloc] init];
	[accessoryView setIcon:fileIcons[type]];
	[accessoryView setTitle:fileTypes[type]];
	[[SavePanel new] setRequiredFileType:fileExtensions[type]];

	return self;
}

- changeSaveType:sender
 /* Called by the accessory view (the Type button on the Save Panel */
{
	if ((++saveType) > SAVE_SOUND)
		saveType = SAVE_SCORE;
#if i386  /* DAJ */
	if (saveType == SAVE_SOUND) /* Intel doesn't support saving as soundfile */
		saveType = SAVE_SCORE;
#endif
	[self setSaveType:saveType];

	return self;
}

- sendRealTimeNote:(MKMidiParVal) message
 /*
  * Send everyone a MIDI system real time message according to the argument. 
  */
{
	int i, n;
	id *doc;
	static id note = nil;
	if (documents) {
		if (!note)
			note = [[Note alloc] init];
		[note setPar:MK_sysRealTime toInt:message];
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if ([*doc isConnected])
				for (i = 0; i < MAXINSTRUMENTS; i++)
					[[[*doc firstEnabledFilter:i] noteReceiver]
						receiveNote:note];
	}
	return self;
}

- sendAllNotesOff:sender
 /* Send allNotesOff directly to Instruments */
{
	int i, n;
	id *doc;
	static id note = nil;

	if (documents) {
		if (!note) {
			note = [[Note alloc] init];
			[note setNoteType:MK_noteUpdate];
		}
		[note setPar:MK_chanMode toInt:MK_allNotesOff];
		[note setPar:MK_controlChange toInt:MIDI_ALLNOTESOFF];
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if ([*doc isConnected])
				for (i = 0; i < MAXINSTRUMENTS; i++)
					[[[*doc firstEnabledFilter:i] noteReceiver]
						receiveNote:note];
	}
	[midi allNotesOff];
	return self;
}

- midiSetup
 /* Create if necessary and initialize the midi object */
{
	id newmidi;

	/*
	 * There is only one object per serial port, so the folowing returns the
	 * same object if the port has not changed via preferences. 
	 */
	newmidi = [Midi newOnDevice:(char *)[preferences serialPort]];
	if (newmidi != midi) {
		int n;
		id *doc;

		if (midi)
			[midi abort];
		midi = newmidi;
		if (documents) 
			for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
				[*doc setMidi:midi];
	}
	[midi setUseInputTimeStamps:YES];
	[midi setConductor:[Conductor defaultConductor]];
	[midi setOutputTimed:[preferences midiTimedOutput]];
	[midi acceptSys:MK_sysStart];
	[midi acceptSys:MK_sysContinue];
	[midi acceptSys:MK_sysStop];
	//if (![midi open])
		//NXRunAlertPanel("Ensemble", "Can't open MIDI device.", NULL, NULL, NULL);
	[[programChanger noteReceiver] disconnect];
	[[programChanger noteReceiver]
	 connect:[midi channelNoteSender:[preferences channel]]];
	[[programChanger noteReceiver] connect:[midi channelNoteSender:0]];
	if ([preferences channel] <= 8)
		[self connectReceiver:[programChanger noteReceiver]
		 toPart:[preferences channel] - 1];
	[self connectReceiverToClavier:[programChanger noteReceiver]];

	return self;
}

- orchestra
{
    return orchestra;
}

- orchestraSetup
 /*
  * Set up the orchestra(s) according to the current document and the
  * preferences. 
  */
{
	id dspDoc = docUsingDSP();
	double srate;
	BOOL ssiIn = docInputFromSSI() != nil;
	BOOL ssiOut = [preferences serialSoundOut];
	[Orchestra setHeadroom:[dspDoc headroom]];
	MKSetPreemptDuration([preferences preemption]);
	[Orchestra setTimed:MK_TIMED];
	[orchestra setOutputCommandsFile:(DSPCommands) ? scoreFilePath : NULL];
	[orchestra setOutputSoundfile:(writeData) ? scoreFilePath : NULL];
	if (ssiIn || ssiOut) 
	  [preferences setSerialDevice]; /* must be before samplingRate, etc. */
	[orchestra setHostSoundOut:!writeData && !ssiOut]; 
	[orchestra setSerialSoundIn:ssiIn];
	[orchestra setSerialSoundOut:ssiOut];
	srate = [dspDoc samplingRate]; 
	[Orchestra setSamplingRate:([orchestra supportsSamplingRate:srate] ? srate :
				    [orchestra defaultSamplingRate])];
	if (![Orchestra open]) {
		if (batchMode)
			[self terminate:self];
		else
			NXRunAlertPanel("Ensemble", "Can't open DSP", NULL, NULL, NULL);
	}
	if (ssiIn && ([preferences serialDevice]==0))
		[orchestra sendSCIByte:0x20];

	return self;
}

- start
 /*
  * Start Midi, the conductor, and the orchestra (if needed) simultaneously.
  * Connect the current document to the performers, also loading its
  * synthpatches, if any. 
  */
{
	int n;
	id *doc;
	id dspDoc = docUsingDSP();
	double d = MKGetDeltaT();

	if ([Conductor inPerformance])
		[self stop];
	[Conductor useSeparateThread:multiThreaded];
	[self midiSetup];
	if (dspDoc)
		[self orchestraSetup];
	[midi run];
	if ([preferences midiInit] && strlen([preferences midiInit])) {
		id note = [[Note alloc] init];

		MKSetNoteParToString(note, MK_sysExclusive,
							 (char *)[preferences midiInit]);
		[[midi channelNoteReceiver:0] receiveNote:note];
		[note free];
	}
	[[Conductor defaultConductor] setTempo:tempo];
	[Conductor setFinishWhenEmpty:NO];
	if (dspDoc)
		[Orchestra run];
	if (!writeData)
		[Conductor startPerformance];
	MKSetDeltaT(0);
	if (dspDoc) {
		[Conductor lockPerformance];
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			if ([*doc isConnected])
				[*doc allocatePatches];
		[Conductor unlockPerformance];
		if (!writeData)
			[NXApp synchDSPDelayed:(d >= 0.5) ? 0.9*d : 0.5];
	}
	MKSetDeltaT(d);
	if (writeData)
		[Conductor startPerformance];
	return self;
}

- stop
 /* Stop Midi, the conductor, and the orchestra. */
{
	[Conductor lockPerformance];
	[Conductor finishPerformance];
	[Conductor unlockPerformance];
	[midi stop];
	[midi abort];
	[Orchestra abort];
	return self;
}


- reset
{
	[self stop];
	[self setDeltaT:[preferences deltaT]];
	[self initSoundOut];
	[self start];
	return self;
}

- connectReceiver:receiver toPart:(int)partNum
 /* Connect a NoteReceiver to a partPerformer */
{
	[Conductor lockPerformance];
	[[partPerformers[partNum] noteSender] connect:receiver];
	[[midiPartPerformer0 noteSender] connect:receiver];
	[Conductor unlockPerformance];

	return self;
}

- disconnectReceiver:receiver fromPart:(int)partNum
 /* Disonnect a NoteReceiver from a partPerformer */
{
	[Conductor lockPerformance];
	[[partPerformers[partNum] noteSender] disconnect:receiver];
	[[midiPartPerformer0 noteSender] disconnect:receiver];
	[Conductor unlockPerformance];

	return self;
}

- (BOOL)isConnected:receiver toPart:(int)partNum
 /* Whether a NoteReceiver instance is connected to a partPerformer */
{
	return [[partPerformers[partNum] noteSender] isConnected:receiver];
}

- connectReceiverToClavier:receiver
 /* Connect a NoteReceiver to the screen clavier. */
{
	[Conductor lockPerformance];
	[[clavier noteSender] connect:receiver];
	[Conductor unlockPerformance];

	return self;
}

- disconnectReceiverFromClavier:receiver
 /* Disconnect a NoteReceiver from the screen clavier. */
{
	[Conductor lockPerformance];
	[[clavier noteSender] disconnect:receiver];
	[Conductor unlockPerformance];

	return self;
}

- connectSenders:noteSenders toRecorder:(int)partNum
 /*
  * Connect a list of NoteSenders to the PartRecorder for the specified part. 
  */
{
	int i;
	id sender;
	id receivers;

	if (!recording)
		return self;

	[Conductor lockPerformance];
	for (i = 0; i < [noteSenders count]; i++) {
		sender = [noteSenders objectAt:i];
		receivers = [sender connections];
		/* Insure that recorder is first in line for notes */
		[sender disconnect];
		[sender connect:[partRecorders[partNum] noteReceiver]];
		[receivers makeObjectsPerform:@selector(connect:)
		 with :sender];
		[receivers free];
	}
	[Conductor unlockPerformance];

	return self;
}

- disconnectSenders:noteSenders fromRecorder:(int)partNum
 /*
  * Disconnect a list of NoteSenders from the PartRecorder for the specified
  * part. 
  */
{
	[Conductor lockPerformance];
	[noteSenders makeObjectsPerform:@selector(disconnect:)
	 with :[partRecorders[partNum] noteReceiver]];
	[Conductor unlockPerformance];

	return self;
}

- saveControllers
 /*
  * Save the state of MIDI controllers for each instrument. We do this at the
  * beginning of a recording sesssion so that resulting score files can
  * initialize the controllers to what they were at the beginning of a
  * performance, rather than what they were at the end. 
  */
{
	int i;
	HashTable *controllerTable;

	[Conductor lockPerformance];
	for (i = 0; i < MAXINSTRUMENTS; i++) {
		if (controllers[i])
			[controllers[i] empty];
		else
			controllers[i] = [[HashTable alloc] initKeyDesc:"i" valueDesc:"i"];
		if (controllerTable = [keyDocument controllers:i]) {
			NXHashState state = [controllerTable initState];
			const void *controller;
			void *value;

			while ([controllerTable nextState:&state
					key:&controller value:&value])
				[controllers[i] insertKey:controller value:value];
		}
	}
	[Conductor unlockPerformance];

	return self;
}

/********************  Main Panel Interface methods  ********************/

- clickStopButton
{
	[stopButton performClick:self];
	NXPing();
	return self;
}

- clickStop
{
	[Conductor sendMsgToApplicationThreadSel:@selector(clickStopButton) to :self
	 argCount:0];
	return self;
}

- unsetPauseButton
{
	if ([pauseButton state])
		[pauseButton setState:0];
	if (recording)
		[pauseButton setEnabled:NO];
	NXPing();
	return self;
}

- play:sender
 /* start playing a file or algorithm from the beginning */
{
	int i;
	double leader = [preferences leader];

	if (!keyDocument) {
		NXRunAlertPanel("Play", "No Document.", NULL, NULL, NULL);
		[playButton setState:0];
		return self;
	}
	if (status != MK_inactive)	/* This shouldn't happen */
		[self stop:self];
	status = MK_active;
	if (![playButton state])	/* If called programmatically */
		[playButton setState:1];
	NXPing();
	[self saveControllers];		/* See method above. */

	[self stop];
	if ((writeData || DSPCommands) && !batchMode)
		[soundSavePanel orderFront:self];
	[self setDeltaT:[preferences fileDeltaT]];	/* May use longer delta T */

	/* Ready, set... */
	if ([preferences sendRealTimeNotes])
		[[Conductor defaultConductor] sel:@selector(sendRealTimeNote:)
		 to :self atTime:leader argCount:1, MK_sysStart];
	if ([score noteCount]) {
		for (i = 0; i < MAXPARTS; i++)
			[partPerformers[i] activate];
		[midiPartPerformer0 activate];
		if ([preferences sendRealTimeNotes])
			[[Conductor defaultConductor] sel:@selector(sendRealTimeNote:)
			 to :self atTime:latestTimeTag(score) argCount :1, MK_sysStop];
		[[Conductor defaultConductor] sel:@selector(clickStop)
		 to :self atTime:latestTimeTag(score) + 8.0 argCount:0];
	}
	/* Go! */
	[self start];

	[playButton setEnabled:NO];	/* Must hit Stop before Play again */
	return self;
}

- stop:sender
 /* stop playing a file or algorithm */
{
	int i;
	id dspDoc = docUsingDSP();

	if (status == MK_inactive) {/* Just do a synch if not playing */
		[self synchDSPDelayed:.25];
		return self;
	}
	[Conductor lockPerformance];
	for (i = 0; i < MAXPARTS; i++) {	/* Deactivate all performers */
		if ([partPerformers[i] status] != MK_inactive)
			[partPerformers[i] deactivate];
	}
	if ([midiPartPerformer0 status] != MK_inactive)
		[midiPartPerformer0 deactivate];
	if (recording)				/* Stop recording */
		for (i = 0; i < MAXPARTS; i++)
			[[partRecorders[i] noteReceiver] disconnect];
	if ([preferences sendRealTimeNotes])
		[self sendRealTimeNote:MK_sysStop];	/* Stop algorithms and sequencers */

	if (recording) {			/* Now merge in recorded notes */
		static id part, note, oldNotes, newNotes;
		int n = [numPartsDisplayer intValue] - 1;
		double now = [[Conductor defaultConductor] time];
		double firstTag = MK_ENDOFTIME;
		double leader = [preferences leader];
		double offset = recordBeginTime;

		if (dspDoc)
			offset += MKGetDeltaT();
		for (i = 0; i < MAXPARTS; i++) {
			part = [partPerformers[i] part];
			if ([recordParts[i] noteCount]) {
				oldNotes = [part firstTimeTag:0.0
							lastTimeTag:now - recordBeginTime];
				newNotes = [recordParts[i] notes];
				/* Flush the initial MIDI Start */
				if ([note = [newNotes objectAt:0] noteType] == MK_mute)
					[newNotes removeObject:note];
				/* Out with the old, in with the new. */
				[part removeNotes:oldNotes];
				[part addNotes:newNotes timeShift:-offset];
				[newNotes free];
				[recordParts[i] empty];	/* Clear record part for next time */
				n = MAX(n, i);
			}
			if ([part noteCount])	/* Find the earliest time tag */
				firstTag = MIN(firstTag,[[part atOrAfterTime:0] timeTag]);
		}
		/* Shift all parts so first note in score is at leader time */
		for (i = 0; i < MAXPARTS; i++) {
			part = [partPerformers[i] part];
			[part shiftTime:leader - firstTag];
		}
		if (n > [numPartsDisplayer intValue] - 1)	/* Update number of parts */
			[numPartsDisplayer setIntValue:n + 1];
		recording = NO;
	}
	[Conductor unlockPerformance];

	if (batchMode) {
		[self stop];
		[self terminate:self];
	}
	[playButton setState:0];	/* Normalize the buttons */
	[playButton setEnabled:YES];
	[pauseButton setState:0];
	[pauseButton setEnabled:YES];
	[recordButton setState:0];
	[recordButton setEnabled:YES];
	[recordButtons setEnabled:YES];
	if (writeData && !batchMode)
		[soundSavePanel close];
	NXPing();

	if (status != MK_inactive) {
		[self stop];
		DSPCommands = NO;
		writeData = NO;
		[self setDeltaT:[preferences deltaT]];
		[self start];
	}
	status = MK_inactive;

	if (dspDoc)
		[self synchDSPDelayed:0.5];
	return self;
}

- pause
 /* Pause playing a file or algorithm */
{
	int i;

	if (status == MK_inactive) {
		[Conductor sendMsgToApplicationThreadSel:@selector(unsetPauseButton)
		 to :self argCount:0];
		return self;
	}
	status = MK_paused;
	[Conductor lockPerformance];
	if ([preferences sendRealTimeNotes])
		[self sendRealTimeNote:MK_sysStop];
	for (i = 0; i < MAXPARTS; i++)
		[partPerformers[i] pause];
	[midiPartPerformer0 pause];
	if (![pauseButton state])
		[pauseButton setState:1];
	[Conductor unlockPerformance];

	return self;
}

- resume
 /* Resume playing a file or algorithm */
{
	int i, partNum;
	id senders;

	if (status != MK_paused)
		return self;
	status = MK_active;
	/*
	 * Since the resume method may be sent from within the Music Kit thread,
	 * we need to use the sendMsgToApplicationThreadSel: mechanism. 
	 */
	[Conductor sendMsgToApplicationThreadSel:@selector(unsetPauseButton)
	 to :self argCount:0];
	[Conductor lockPerformance];
	if (recording) {			/* Pause is called by -record, below */
		/* Connect a partRecorder in parallel with each instrument */
		for (i = 0; i < MAXINSTRUMENTS; i++) {
			partNum = [keyDocument partNum:i];
			if (recordEnabled[partNum]) {
				senders = [[keyDocument lastEnabledFilter:i] allSenders];
				[self connectSenders:senders toRecorder:partNum];
				[senders free];
			}
		}
		recordBeginTime = [[Conductor defaultConductor] time];
		if ([preferences sendRealTimeNotes])
			[[Conductor defaultConductor] sel:@selector(sendRealTimeNote:)
			 to :self withDelay:[preferences leader]
			 argCount:1, MK_sysStart];
	}
	for (i = 0; i < MAXPARTS; i++)	/* Now resume all the performers */
		[partPerformers[i] resume];
	[midiPartPerformer0 resume];
	if (!recording && [preferences sendRealTimeNotes])
		[self sendRealTimeNote:MK_sysContinue];	/* Resume algorithms &
												 * sequencers */
	[Conductor unlockPerformance];

	return self;
}

- pause:sender
 /* Pause or resume playing a file or algorithm.  The button method */
{
	return ([sender state]) ?[self pause] :[self resume];
}

- record:sender
{
	int i;

	if (!keyDocument) {
		NXRunAlertPanel("Record", "No Document.", NULL, NULL, NULL);
		[recordButton setState:0];
		return self;
	}
	recording = YES;
	if (strlen(scoreFileName) == 0)
		[self newScore:self];	/* Create a new score if none exists */
	[recordButtons setEnabled:NO];	/* Can't change state while recording */
	[recordButton setEnabled:NO];	/* Must hit Stop to finish */
	[playButton setState:1];
	[playButton setEnabled:NO];	/* Must hit Stop before Play again */
	[Conductor lockPerformance];
	/* get set up to play existing score or algorithms */
	if ([score noteCount]) {
		for (i = 0; i < MAXPARTS; i++) {
			[partPerformers[i] activate];
			[partPerformers[i] pause];
		}
		[midiPartPerformer0 activate];
		[midiPartPerformer0 pause];
	}
	[Conductor unlockPerformance];
	status = MK_paused;
	[pauseButton setState:1];
	[self synchDSPDelayed:0.5];
	return self;
}

- reset:sender
 /* stop a file or algorithm, and reset the dsp orchestra */
{
	[self stop:self];
	[Conductor lockPerformance];
	[self sendRealTimeNote:MK_sysReset];
	[Conductor unlockPerformance];
	[Conductor sendMsgToApplicationThreadSel:@selector(reset) to :self argCount:0];
	return self;
}

- recordEnable:sender
 /* Enable or disable recording for a particular part */
{
	id cell = [sender selectedCell];
	int partNum = [cell tag];

	if ([cell state])
		recordEnabled[partNum] = YES;
	else
		recordEnabled[partNum] = NO;

	return self;
}

- mutePart:sender
 /* Mute or unmute one part of a score by squelching it's sender */
{
	id cell = [sender selectedCell];
	int partNum = [cell tag];

	[Conductor lockPerformance];
	if ([cell state])
		[[partPerformers[partNum] noteSender] squelch];
	else
		[[partPerformers[partNum] noteSender] unsquelch];
	[Conductor unlockPerformance];

	return self;
}

- selectPart:sender
 /* Select a part to copy, cut, or paste to. */
{
	int tag = [[sender selectedCell] tag];

	if (tag == selectedPart) {
		selectedPart = -1;
		[partSelectButtons selectCellAt:-1:-1];
	} else
		selectedPart = tag;

	return self;
}

- copy:sender
 /* Archive the selected part to the pasteboard */
{
	char *data;
	const char *types[1];
	int length;
	id part;

	if (selectedPart >= 0) {
		part = [partPerformers[selectedPart] part];
		if (part) {
			types[0] = PartPBType;
			[pasteboard declareTypes:types num:1 owner:self];
			[Conductor lockPerformance];
			data = NXWriteRootObjectToBuffer(part, &length);
			[Conductor unlockPerformance];
			[pasteboard writeType:PartPBType data:data length:length];
			NXFreeObjectBuffer(data, length);
		}
	}
	return self;
}

- paste:sender
 /*
  * Unarchive a part from the pasteboard and replace the selected part with
  * it. 
  */
{
	char *data;
	int length;
	NXStream *stream;
	NXTypedStream *ts;
	const char *const * types = [pasteboard types];

	if ((!strcmp(types[0], PartPBType)) && (selectedPart >= 0)) {
		id part, oldPart;

		[pasteboard readType:PartPBType data:&data length:&length];
		stream = NXOpenMemory(data, length, NX_READONLY);
		ts = NXOpenTypedStream(stream, NX_READONLY);
		[Conductor lockPerformance];
		part = NXReadObject(ts);
		[Conductor unlockPerformance];
		NXCloseTypedStream(ts);
		NXCloseMemory(stream, NX_FREEBUFFER);
		if (part) {
			[Conductor lockPerformance];
			[partPerformers[selectedPart] deactivate];
			oldPart = [partPerformers[selectedPart] part];
			[score removePart:oldPart];
			[partPerformers[selectedPart] setPart:nil];
			[oldPart free];
			[score addPart:part];
			[partPerformers[selectedPart] setPart:part];
			[Conductor unlockPerformance];
			if ((selectedPart + 1) > [numPartsDisplayer intValue])
				[numPartsDisplayer setIntValue:(selectedPart + 1)];
		}
	}
	return self;
}

- delete:sender
{
	id part;

	if (selectedPart >= 0) {
		[Conductor lockPerformance];
		[partPerformers[selectedPart] deactivate];
		part = [partPerformers[selectedPart] part];
		[score removePart:part];
		[partPerformers[selectedPart] setPart:nil];
		[part free];
		part = [[Part alloc] init];
		[score addPart:part];
		[partPerformers[selectedPart] setPart:part];
		[Conductor unlockPerformance];
	}
	return self;
}

- cut:sender
 /* Copy the selected part, then replace it with a new empty part. */
{
	if (selectedPart >= 0) {
		[self copy:self];
		[self delete:self];
	}
	return self;
}

- takeTempoFrom:sender
 /* Get the tempo from the tempo slider */
{
	tempo = [sender intValue];
	[Conductor lockPerformance];
	[[Conductor defaultConductor] setTempo:tempo];
	[Conductor unlockPerformance];
	[tempoDisplayer setIntValue:tempo];
	[keyDocument setDocumentTempo:tempo];

	return self;
}

- displayTempo
{
	[self->tempoDisplayer setIntValue:tempo];
	if (tempo < ([(Slider *) self->tempoSlider minValue] + 10))
		[self->tempoSlider setMinValue:tempo *.8];
	if (tempo > ([(Slider *) self->tempoSlider maxValue] - 20))
		[self->tempoSlider setMaxValue:tempo * 1.2];
	[self->tempoSlider setIntValue:tempo];
	NXPing();
	return self;
}

- setTempoFromDocument:(int)aTempo
{
	tempo = aTempo;
	[Conductor lockPerformance];
	[[Conductor defaultConductor] setTempo:tempo];
	[Conductor unlockPerformance];
	[Conductor sendMsgToApplicationThreadSel:@selector(displayTempo) to :self argCount:0];
	return self;
}

/**************************  Score Files  ***********************/

- (BOOL)getScoreFile:(char *)path
 /* Retrieve a score or midi file from the specified file path */
{
	int i, count, fileTempo = MAXINT;
	id parts, info, note;
	Part *part;
	double firstTag = MK_ENDOFTIME;
	double leader = [preferences leader];
	Score *newScore = [[Score alloc] init];
	char name[MAXPATHLEN + 1];
	char dir[MAXPATHLEN + 1];
	BOOL isMIDIFile = NO;
	BOOL hasGlobalPart = NO;

	parsePath(path, dir, name);
	if (strlen(name) == 0) {
		[newScore free];
		return NO;
	}
	[self setSaveType:fileType(path)];

	if (saveType == SAVE_MIDI) {
		int level = 1;			/* MIDI File format level */

		if (![newScore readMidifile:path]) {
			[newScore free];
			return NO;
		}
		isMIDIFile = YES;
		count = [newScore partCount];
		if (count > 0) {
			/* Get info of last part. */
			id partInfo = [(Part *)[[newScore parts] objectAt:count - 1] info];

			if (partInfo)
				level = MKIsNoteParPresent(partInfo, MK_track) ? 1 :
					(MKIsNoteParPresent(partInfo, MK_sequence) ? 2 : 0);
		}
		if (level == 2) {
			NXRunAlertPanel("Open Score File",
							"Sorry, cannot play level 2 format MIDI files.",
							NULL, NULL, NULL);
			[newScore free];
			return NO;
		}
		if ([[newScore info] isParPresent:MK_tempo])
			fileTempo = MKGetNoteParAsInt([newScore info], MK_tempo);
		/*
		 * The first part is a sysex part for level 0 or a tempo map for level
		 * 1. 
		 */
	} else {					/* Must be a scorefile */
		isMIDIFile = [preferences scoresToMIDI];
		if (![newScore readScorefile:path]) {
			[newScore free];
			return NO;
		}
		if ([[newScore info] isParPresent:MK_tempo])
			fileTempo = MKGetNoteParAsInt([newScore info], MK_tempo);
		parts = [newScore parts];
		hasGlobalPart = !strcmp(MKGetObjectName([parts objectAt:0]),"allParts");
		[parts free];
		if (isMIDIFile) {
			/* convert to MIDI data only */
			NXStream *stream = NXOpenMemory(NULL, 0, NX_READWRITE);
			[newScore writeMidifileStream:stream];
			[newScore free];
			newScore = [[Score alloc] init];
			if (!hasGlobalPart)
				[newScore addPart:[[Part alloc] init]];
			NXSeek(stream, 0, NX_FROMSTART);
			[newScore readMidifileStream:stream];
			NXCloseMemory(stream, NX_FREEBUFFER);
		}
	}
	parts = [newScore parts];
	count = [parts count];
	for (i = 0; i < count; i++) {
		part = [parts objectAt:i];
		while ([note = [part atOrAfterTime:0] noteType] == MK_mute)
			[part removeNote:note];
		if ((!isMIDIFile || (i > 0)) && (![part noteCount]))
			[newScore removePart:part];
	}
	[parts free];
	if (isMIDIFile) {
		/* Part #0 is always the "sysex" part */
		[numPartsDisplayer setIntValue:[newScore partCount] - 1];
		while ([newScore partCount] - 1 < MAXPARTS)
			[newScore addPart:[[Part alloc] init]];
		parts = [newScore parts];
		[midiPartPerformer0 setPart:[parts objectAt:0]];
		for (i = 0; i < MAXPARTS; i++)
			[partPerformers[i] setPart:[parts objectAt:i + 1]];
	} else {
		int j = 0;
		[numPartsDisplayer setIntValue:[newScore partCount]];
		while ([newScore partCount] < MAXPARTS)
			[newScore addPart:[[Part alloc] init]];
		parts = [newScore parts];
		if (hasGlobalPart)
			[midiPartPerformer0 setPart:[parts objectAt:j++]];
		else [midiPartPerformer0 setPart:nil];
		for (i = 0; i < MAXPARTS; i++)
			[partPerformers[i] setPart:[parts objectAt:j++]];
	}
	if (fileTempo != MAXINT) {
		tempo = fileTempo;
		[[Conductor defaultConductor] setTempo:tempo];
		[keyDocument setDocumentTempo:tempo];
		[tempoDisplayer setIntValue:tempo];
		if (tempo < [(Slider *) tempoSlider minValue])
			[tempoSlider setMinValue:tempo *.8];
		if (tempo > [(Slider *) tempoSlider maxValue])
			[tempoSlider setMaxValue:tempo * 1.2];
		[tempoSlider setIntValue:tempo];
	} else
		[[newScore info] setPar:MK_tempo toInt:tempo];
	for (i = 0; i < [parts count]; i++) {
		part = [parts objectAt:i];
		if (![part info]) {
			[part setInfo:info = [[Note alloc] init]];
			/* setInfo copies the note, so we have to free it */
			[info free];
		}
		if ([part noteCount])	/* Find the earliest time tag */
			firstTag = MIN(firstTag,[[part atOrAfterTime:0] timeTag]);
	}
	if (firstTag != leader)		/* Adjust so that first note is at leader
								 * time. */
		for (i = 0; i < [parts count]; i++) {
			part = [parts objectAt:i];
			[part shiftTime:leader - firstTag];
		}
	[parts free];
	if (score)
		[score free];
	score = newScore;
	strcpy(scoreFilePath, path);
	strcpy(scoreFileName, name);
	strcpy(scoreFileDir, dir);
	[scoreFileNameDisplayer setStringValue:name];

	return YES;
}

- openScoreFile:sender
 /* Get a score file name from the user and load it. */
{
	char path[MAXPATHLEN + 1];
	char const *fileTypes[3] = {"midi", "score", 0};
	id openPanel = [OpenPanel new];
	[openPanel allowMultipleFiles:NO];

	[self stop:self];
	[self stop];

	if (!scoreFilePath) {
		if ([keyDocument filePath])
			strcpy(scoreFilePath,[keyDocument filePath]);
		else if ([preferences docDirectory])
			strcpy(scoreFilePath,[preferences docDirectory]);
		else
			strcpy(scoreFilePath, NXHomeDirectory());
	}

	if (![openPanel runModalForDirectory:(const char *)scoreFilePath
				file:"" types:fileTypes])
		return self;

	getPath(path, (char *)[openPanel directory],(char *)*[openPanel filenames], NULL);
	[self getScoreFile:path];

	/* Start up the music kit performance again */
	[self start];

	return self;
}

- newScore:sender
 /* Create a new scratch score. */
{
	int i;
	id part;

	getwd(scoreFileDir);
	sprintf(scoreFileName, "Untitled");
	[Conductor lockPerformance];
	if (score) {
		[score freeParts];
	} else
		score = [[Score alloc] init];
	[midiPartPerformer0 setPart:part = [[Part alloc] init]];
	[score addPart:part];
	for (i = 0; i < MAXPARTS; i++) {
		[score addPart:part = [Part new]];
		[partPerformers[i] setPart:part];
	}
	[scoreFileNameDisplayer setStringValue:scoreFileName];
	[numPartsDisplayer setIntValue:0];
	[Conductor unlockPerformance];

	return self;
}

- saveScore
 /* Save the current score as a Score, Midi, or DSPCommands file. */
{
	double leader = [preferences leader];

	[self setSaveType:fileType(scoreFilePath)];
	getPath(scoreFilePath, scoreFileDir, scoreFileName,
			fileExtensions[saveType]);
	[scoreFileNameDisplayer setStringValue:scoreFileName];
	switch (saveType) {
		case SAVE_SCORE:
			{
				int partNum, inputNum, insNum;
				id outScore;
				id part, outPart, info;
				id updateNote;
				BOOL *insMap;
				const void *key;
				void *value;
				NXHashState state;
				id *instruments = [keyDocument instruments];

				[self stop:self];
				[self stop];
				outScore = [[Score alloc] init];
				updateNote = [[Note alloc] init];
				[updateNote setNoteType:MK_noteUpdate];
				/*
				 * We attempt to create a score which includes the
				 * orchestration of the current document. Since not all parts
				 * are assigned, and parts may be assigned to more than one
				 * input and inputs to more than one part, we have to be
				 * careful here to cover all the possibilities.  If a part is
				 * not used, it is written out as is. Otherwise, we write out
				 * each part once for every instrument it is connected to.
				 * Note that controllers are initialized to the state they
				 * were in at the beginning of the last recording session. 
				 */
				for (partNum = 0; partNum < MAXPARTS; partNum++) {
					part = [partPerformers[partNum] part];
					outPart = nil;
					for (inputNum = 0; inputNum < MAXINSTRUMENTS; inputNum++)
						if (partNum == [keyDocument partNum:inputNum]) {
							insMap = [keyDocument instrumentMap:inputNum];
							for (insNum = 0; insNum < MAXINSTRUMENTS; insNum++)
								if (insMap[insNum] && instruments[insNum]) {
									outPart = [part copy];
									[outScore addPart:outPart];
									info = [keyDocument updates:insNum];
									if (info) {
										id tmp = [[Note alloc] init];

										[tmp setNoteType:MK_noteUpdate];
										MKSetNoteParToString
											(tmp, MK_synthPatch,
											 MKGetNoteParAsString(info, MK_synthPatch));
										if (MKIsNoteParPresent(info, MK_svibAmp))
											MKSetNoteParToDouble
												(tmp, MK_svibAmp,
												 MKGetNoteParAsDouble(info,
																MK_svibAmp));
										if (MKIsNoteParPresent(info, MK_rvibAmp))
											MKSetNoteParToDouble
												(tmp, MK_rvibAmp,
												 MKGetNoteParAsDouble(info,
																MK_rvibAmp));
										if (MKIsNoteParPresent(info, MK_midiChan))
											MKSetNoteParToInt
												(tmp, MK_midiChan,
												 MKGetNoteParAsInt(info, MK_midiChan));
										[info removePar:MK_sysRealTime];
										[outPart setInfo:tmp];
										[tmp free];
										info = [info copy];
										[info removePar:MK_synthPatch];
										[info setTimeTag:leader -.01];
										[outPart addNote:info];
									}
									if (controllers[insNum]) {
										[updateNote setTimeTag:leader -.01];
										state = [controllers[insNum] initState];
										while ([controllers[insNum]
												nextState:&state
												key:&key value:&value]) {
											MKSetNoteParToInt
												(updateNote, MK_controlChange,
												 (int)key);
											MKSetNoteParToInt
												(updateNote, MK_controlVal,
												 (int)value);
											[outPart addNote:[updateNote copy]];
										}
									}
								}
						}
					if (!outPart)
						[outScore addPart:[part copy]];
				}
				info = [[Note alloc] init];
				MKSetNoteParToInt(info, MK_tempo, tempo);
				MKSetNoteParToInt(info, MK_samplingRate,[keyDocument samplingRate]);
				MKSetNoteParToDouble(info, MK_headroom,[keyDocument headroom]);
				[outScore setInfo:info];
				[outScore writeScorefile:scoreFilePath];
				[outScore free];
				[info free];
				/* Start up the music kit performance again */
				[self start];
				break;
			}
		case SAVE_MIDI:
			[self stop:self];
			[self stop];
			MKSetNoteParToInt([score info], MK_tempo, tempo);
			[score writeMidifile:scoreFilePath];
			/* Start up the music kit performance again */
			[self start];
			break;
		case SAVE_COMMANDS:
			/*
			 * Here we play the score, capturing the performance in the
			 * DSPCommands file. 
			 */
			DSPCommands = YES;
			[playButton performClick:self];
			break;
		case SAVE_SOUND:
			/*
			 * Here we play the score, capturing the performance in the sound
			 * file. 
			 */
			writeData = YES;
			[playButton performClick:self];
			break;
	}

	return self;
}


- saveScoreAs:sender
 /* Save the score, always prompting for a file name first */
{
	BOOL emptyScore;

	[Conductor lockPerformance];
	emptyScore = ([score noteCount] == 0);
	[Conductor unlockPerformance];
	if (emptyScore)
		NXRunAlertPanel("Save Score File", "%s is Empty.", NULL, NULL, NULL,
						scoreFileName);
	else {
		id savePanel = [SavePanel new];
		[savePanel setTitle:"Ensemble Save"];
		if (!accessoryView) {
			accessoryView = [[Button allocFromZone:[NXApp zone]] init];
			[accessoryView setIconPosition:NX_ICONABOVE];
			[accessoryView setTarget:NXApp];
			[accessoryView setAction:@selector(changeSaveType:)];
			[accessoryView sizeTo:124 :68];
		}
		[savePanel setAccessoryView:accessoryView];
		if (saveType == -1)
			[self setSaveType:SAVE_SCORE];
		if ([savePanel runModalForDirectory:scoreFileDir file:scoreFileName]) {
			strcpy(scoreFilePath,[savePanel filename]);
			soundFile = (saveType == SAVE_SOUND) ? scoreFilePath : NULL;
			parsePath(scoreFilePath, scoreFileDir, scoreFileName);
			[self saveScore];
		}
	}

	return self;
}

- saveScore:sender
 /* Save the score, only prompting for a file name if not yet set. */
{
	if (!strcmp(scoreFileName, "Untitled"))
		return[self saveScoreAs:self];
	else
		return[self saveScore];
}

- new:sender
{
	id doc = [[EnsembleDoc allocFromZone:[self zone]] initFromPath:NULL];
	[doc addInstrument:[Wave1Instrument class] number:0];
	[doc show];
	return self;
}

- open:sender
{
	[EnsembleDoc openFromZone:[self zone]];
	return self;
}

- saveAllDocuments:sender
 /* Save all open documents */
{
	int n;
	id *doc;
	if (documents)
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			[*doc save:sender];

	return self;
}

- settings:sender
 /* Display the document settings panel, unarchiving it if necessary */
{
	if (!settings) {
		settings
			= [self loadNibSection:"Settings.nib" owner:self withNames:NO];
		[settings center];
	}
	[settings runModal:self];

	return self;
}

- showComments:sender
 /* Display the current document's comments panel. */
{
	[[keyDocument commentPanel] makeKeyAndOrderFront:self];

	return self;
}

- miniaturizeAll:sender
{
	int n;
	id *doc;
	if (documents)
		for (doc = NX_ADDRESS(documents), n = [documents count]; n--; doc++)
			[[*doc window] performMiniaturize:sender];

	return self;
}


/************************  Printing  ************************/

- printKeyWindow:sender
 /* Print the key window */
{
	return[[NXApp keyWindow] printPSCode:sender];
}

- pageLayout:sender
 /* Display the page layout panel. */
{
	[[PageLayout new] runModal];

	return self;
}

/************************  Info  ************************/

- info:sender
 /* Display the info panel, unarchiving it if necessary. */
{
	if (!infoPanel) {
		infoPanel = [self loadNibSection:"Info.nib" owner:self withNames:NO];
		[infoPanel center];
	}
	[infoPanel orderFront:self];

	return self;
}

- preferences:sender
 /* Display the preferences panel. */
{
	if ([preferences runModal:self]) {
		multiThreaded = [preferences multiThreaded];
		[self reset:self];
	}
	return self;
}

- preferences
{
	return preferences;
}

/********************  Miscellaneous App Methods  ********************/

- clavier:sender
 /* Display the clavier.  Create one if necessary and connect it to the
  * current document.
  */
{
	int i;

	if (!clavier) {
		clavier = [[Clavier alloc] init];
		if (keyDocument)
			for (i = 0; i < MAXINSTRUMENTS; i++)
				[self connectReceiverToClavier:
				 [[keyDocument firstEnabledFilter:i] noteReceiver]];
	}
	[[clavier window] makeKeyAndOrderFront:self];
	[self connectReceiverToClavier:[programChanger noteReceiver]];

	return self;
}

- midi
{
	return midi;
}

- (MKPerformerStatus) performanceStatus
{
	return status;
}

- terminate:sender
 /* Check for unsaved documents and abort the performance, then say goodbye. */
{
	int i;

	[self stop:self];
	[self stop];
	[soundOutDevice setReserved:NO];
	for (i = 0; i < [documents count]; i++)
		if (![[documents objectAt:i] okToClose])
			return self;
	[super terminate:self];

	return self;
}

- windowDidResignKey:sender
 /* De-select any parts before giving up key. */
{
	[partSelectButtons selectCellAt:-1:-1];
	selectedPart = -1;
	return self;
}

struct appDef {
	@defs (Application)
} *nx_app;

#define RUNNING_MODAL (((nx_app=(struct appDef *)NXApp)->running)>1)

- appDidResignActive:sender
 /* Close the DSP orchestra unless otherwise indicated in preferences. */
{
	if (!batchMode && ![preferences retainDSP] && !RUNNING_MODAL) {
		[self stop:self];
		[self stop];
	}
	return self;
}

- appDidBecomeActive:sender
 /* Start up again unless we were performing in the background. */
{
	if (keyDocument && ![Conductor inPerformance] && !RUNNING_MODAL)
		[self start];
	if (batchMode && (status != MK_active)) {
		if (soundFile) {
			strcpy(scoreFilePath, soundFile);
			parsePath(scoreFilePath, scoreFileDir, scoreFileName);
			saveType = SAVE_SOUND;
			[self saveScore];
		} else
			[playButton performClick:self];
	}
	return self;
}

void myError(int error)
{
	fprintf(stderr,"Goddamn malloc error #%d\n", error);
}

- appDidInit:sender
{
	int i;
	BOOL autoNewDoc = YES;
	malloc_error(myError);
	for (i = 1; i < NXArgc, NXArgv[i]; i++) {
		if (!strcmp(NXArgv[i], "-BatchMode")) {
			if (++i == NXArgc) {
				fprintf(stderr, "-BatchMode requires a Yes or No argument.\n");
				exit(1);
			}
			batchMode = !strcmp(NXArgv[i], "Yes");
		} else if (!strcmp(NXArgv[i], "-RanSeed")) {
			if (++i == NXArgc) {
				fprintf(stderr, "-RanSeed requires an integer argument.\n");
				exit(1);
			}
			srandom(strtol(NXArgv[i], NULL, 10));
			newRanVals = YES;
		} else if (!strcmp(NXArgv[i], "-SoundFile")) {
			if (++i == NXArgc) {
				fprintf(stderr, "-SoundFile requires a file name argument.\n");
				exit(1);
			}
			NX_MALLOC(soundFile, char, 256);
			strcpy(soundFile, NXArgv[i]);
		} else if (!strcmp(NXArgv[i], "-n")) {
			autoNewDoc = NO;
		}
	}

	if (batchMode)
		[self hide:self];

	if (autoNewDoc && ![documents count])
		/* Create a default document when starting up without one. */
		[self new:sender];

	[self activateSelf:YES];

	if (keyDocument && !batchMode) {
		[keyDocument show];
		[self synchDSPDelayed:1.5];
	}
	return self;
}

- (int)appOpenFile:(const char *)path type:(const char *)type
 /*
  * This method is performed whenever a user double-clicks on an icon in the
  * Workspace Manager representing an Ensemble document. 
  */
{
	if (type && (!strcmp(type, "midi") || !strcmp(type, "score")))
		return[self getScoreFile:(char *)path];
	else if (type && !strcmp(type, "ens")) {
		id newdoc = [[EnsembleDoc alloc] initFromPath:(char *)path];
		id dspDoc = docUsingDSP();

		if (newdoc) [[newdoc window] makeKeyAndOrderFront:nil];

		if (![Conductor inPerformance] ||
			(dspDoc && ([orchestra deviceStatus] != MK_devRunning)))
			[Conductor sendMsgToApplicationThreadSel:@selector(reset) to :self
			 argCount:0];
		else if (dspDoc)
			[NXApp synchDSPDelayed:1.0];
		return newdoc != nil;
	}
	return NO;
}

- (BOOL)appAcceptsAnotherFile:sender
 /* We accept any number of appOpenFile:type: messages. */
{
	return YES;
}

/*******************  DSP Synchronization Insurance  *******************/

DSPFix48 *doubleIntToFix48UseArg(double dval, DSPFix48 * aFix48)
 /* dval is an integer stored in a double. */
{
	double shiftedDval;

#   define TWO_TO_24  ((double) 16777216.0)
#   define TWO_TO_48  (TWO_TO_24 * TWO_TO_24)
#   define TWO_TO_M24 ((double)5.9604644775390625e-08)

	if (dval < 0)
		dval = 0;
	if (dval > TWO_TO_48)
		dval = TWO_TO_48;
	shiftedDval = dval * TWO_TO_M24;
	aFix48->high24 = (int)shiftedDval;
	aFix48->low24 = (int)((shiftedDval - aFix48->high24) * TWO_TO_24);

	return aFix48;
}

- synchDSP
 /*
  * We hope this will not be needed in future releases. Furthermore, it's not
  * even perfectly accurate as is, since the DSP does not run in a strictly
  * sample synchronous manner. 
  */
{
	static DSPFix48 dspsampletime;

	if ([orchestra deviceStatus] != MK_devRunning)
		return nil;
	if ([Conductor inPerformance]) {
		[Conductor lockPerformance];
		DSPMKSetTime(doubleIntToFix48UseArg
					 (MKGetTime() * [orchestra samplingRate],
					  &dspsampletime));
		[Conductor unlockPerformance];
	}
	return self;
}

- synchDSPDelayed:(double)time
 /*
  * After loading synthpatches it is best to wait a few buffers before doing
  * the synch.  This method schedules a synch in the future. Note that the
  * time is in seconds, not beats. 
  */
{
	[Conductor lockPerformance];
	if ([Conductor inPerformance])
		[[Conductor clockConductor] sel:@selector(synchDSP)
		 to :self withDelay:time argCount:0];
	[Conductor unlockPerformance];

	return self;
}

@end
