#import "SamplerInstrument.h"
#import "SoundRecorder.h"
#import <appkit/appkit.h>
#import <objc/HashTable.h>
#import <musickit/Note.h>
#import <musickit/keynums.h>
#import <mididriver/midi_spec.h>
#import "EnsembleDoc.h"
#import "EnsembleApp.h"
#import "ParamInterface.h"
#import <soundkit/soundkit.h>
#import <sound/sound.h>
#import <sys/types.h>
#import <sys/dir.h>

static char *globalSoundDirectory = NULL;

int activeSoundMax = 16;
int activeSoundCount = 0;

static void displayName(char *filepath, id displayer)
{
	if (filepath && strlen(filepath)) {
		int     n;
		char   *path, *name;
		char   *dot = strrchr(filepath, '.');

		path = strrchr(filepath, '/');	/* strip off directory */
		if (path)
			path++;
		else
			path = filepath;
		NX_MALLOC(name, char, MAXPATHLEN + 1);
		strncpy(name, path, n = (dot) ? (int)(dot - path) : strlen(path));
		name[n] = '\0';
		[displayer setStringValue:name];
		NX_FREE(name);
	} else
		[displayer setStringValue:""];
}

@implementation SamplerInstrument
{
}

+ initialize
{
	[SamplerInstrument setVersion:2];
	return self;
}

- reset
{
	int i;
	amp = (double)strtol([ampField stringValue], NULL, 10);
	linearAmp = MKdB(amp);
	bearing = [bearingField doubleValue];
	volume = 1.0;
	pitchBend = 1.0;
	for (i = 0; i < 128; i++) {
		if (performers[i]) {
		        [Conductor lockPerformance];
			[performers[i] reset];
			[performers[i] setAmp:linearAmp volume:volume bearing:bearing/45.0];
		        [Conductor unlockPerformance];
		}
	}
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"SamplerInstrument.nib" owner:self withNames:NO];
	return self;
}

- setDefaults
{
	[super setDefaults];
	keyNum = c4k;
	testKey = keyNum;
	voiceCount = 3;
	volume = 1.0;
	pitchBend = 0.0;
	pitchbendSensitivity = 0.0;
	pbSensitivity = (pitchbendSensitivity / 12.0) / 8192.0;
	recordModeController = -1;
	return self;
}

- init
 /*
  * Load SamplerInstrument nib section. Initialize two hashtables to store the
  * filenames and sound structs mapped to their assigned key numbers.
  * Initialize the tables to be a system beep sampler. 
  */
{
	DIR *dir = opendir("/NextLibrary/Sounds");
	struct direct *dp;
	char *path;
	int k, n;
	[super init];
	fileTable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"*" capacity:16];
	soundTable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"!" capacity:16];
	[self addNoteReceiver:[[NoteReceiver alloc] init]];
	path = malloc(sizeof(char)*(MAXPATHLEN+1));
	k = 37;
	while (dp = readdir(dir)) {
		n = strlen(dp->d_name);
		if ((n > 4) && !strcmp(dp->d_name+n-4,".snd")) {
			sprintf(path,"/NextLibrary/Sounds/%s",dp->d_name);
			[self setFile:path forKey:k];
			[self mapKey:k from:k-1 to:k+1];
			k += 3;
			if (k > 83) break;
		}
	}
	closedir(dir);
	displayName([fileTable valueForKey:(const void *)keyMap[keyNum]], filenameField);
	conductor = [Conductor defaultConductor];
	NX_MALLOC(directory, char, MAXPATHLEN + 1);
	*directory = '\0';
	if (!globalSoundDirectory)
		NX_MALLOC(globalSoundDirectory, char, MAXPATHLEN + 1);
	[self reset];
	[self displayPatchCount];
	return self;
}

- awakeFromNib
{
	[super awakeFromNib];
    [voiceCountField setIntValue:voiceCount];
	[keyInterface setMode:KEYNUMS];
	[keyInterface setIntValue:keyNum];
	[preloadingSwitch setState:preloadingEnabled];
	[tieNotesSwitch setState:tieRepeats];
	[modeButtons selectCellWithTag: (diatonic ? 1 : 0)];
	[recordModeInterface setMode:CONTROLS];
	[recordModeInterface setIntValue:recordModeController];
	return self;
}

- initSoundTable
{
	int err;
	NXHashState state;
	void *path;
	const void *key;
	SNDSoundStruct *newSound;

	if (!soundTable)
		soundTable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"!" capacity:16];
	else
		[soundTable empty];
		
	state = [fileTable initState];
	while ([fileTable nextState:&state key:&key value:&path]) {
		if ((err = SNDReadSoundfile((char *)path, &newSound)) == SND_ERR_NONE)
			[soundTable insertKey:key value:(void *)newSound];
	}
	
	return self;
}

- initKeyMap
{
	NXHashState state;
	void *sound;
	const void *key;
	int *map = keyMap;
	int *end = map+128;

	while (map<end) *map++ = -1;

	state = [soundTable initState];
	while ([soundTable nextState:&state key:&key value:&sound])
		if (sound) keyMap[(int)key] = (int)key;
	
	return self;
}

- updateDisplay
{
	char *path = (char *)[fileTable valueForKey:(const void *)keyMap[keyNum]];
	if (!path && [soundTable isKey:(const void *)keyNum])
		path = "temp";
	displayName(path, filenameField);
	if (keyNum != [keyInterface intValue])
		[keyInterface setIntValue:keyNum];
	return self;
}

- initPerformers
{
	int i;
	SNDSoundStruct *sound;

	for (i = 0; i < 128; i++) {
		sound = (SNDSoundStruct *)[soundTable valueForKey:(const void *)keyMap[i]];
		if (sound) {
			if (!performers[i]) {
				performers[i] = [[SoundPerformer alloc] init];
				[performers[i] setDelegate:self];
				[performers[i] enablePreloading:preloadingEnabled];
			}
			[performers[i] setSoundStruct:sound];
			if (i == keyNum)
				[self updateDisplay];
		}
		else {
			if (performers[i]) [performers[i] free];
			performers[i] = nil;
		}
	}

	return self;
}

- freeSounds
 /* Free all the sound structs */
{
	NXHashState state;
	void *sound;
	const void *key;
	int i;
	[Conductor lockPerformance];
	for (i=0; i<128; i++) {
		[performers[i] abort];
		[performers[i] free];
		performers[i] = nil;
		keyMap[i] = -1;
	}

	state = [soundTable initState];
	while ([soundTable nextState:&state key:&key value:&sound])
		SNDFree((SNDSoundStruct *)sound);

	[soundTable empty];
	[Conductor unlockPerformance];
	return self;
}

- free
 /*
  * Free the sound structs, the filename strings, the hash tables, and the
  * window. 
  */
{
	[self freeSounds];
	[fileTable freeObjects];
	[fileTable free];
	[soundTable free];
	NX_FREE(directory);
	[keyInterface free];
	[recordModeInterface free];
	return [super free];
}

- takeRecordControllerFrom:sender
{
	recordModeController = [sender intValue];
	return self;
}

- getUpdates:(Note **) aNoteUpdate controllerValues:(HashTable **) controllers
 /* For compatibility with the SynthInstrument method */
{
	*aNoteUpdate = nil;
	*controllers = nil;
	return self;
}

- setDocument:aDocument
{
	document = aDocument;
	return self;
}

- window
{
	return window;
}

- setView:aView
 /*
  * Although our window's content view is stolen away by the document, it is
  * sometimes temporarily stored here for cut and paste purposes. 
  */
{
	view = aView;
	return self;
}

- view
{
	return view;
}

- (int)testKey
 /* The key that will be used by the document's test note method */
{
	return testKey;
}

- deleteFileForKey:(int)key
{
	int baseKey = keyMap[key];
	SNDSoundStruct *snd = 
		(SNDSoundStruct *)[soundTable valueForKey:(const void *)baseKey];
	char *path = (char *)[fileTable valueForKey:(const void *)baseKey];
	int  i;

	NX_FREE(path);
	SNDFree(snd);
	[fileTable removeKey:(const void *)baseKey];
	[soundTable removeKey:(const void *)baseKey];
	
	for (i=baseKey; i<128; i++) {
		if (keyMap[i] == baseKey) {
			[performers[i] free];
			performers[i] = nil;
			keyMap[i] = -1;
			if (i == keyNum)
				displayName(NULL, filenameField);
		}
	}

	[document setEdited];
	return self;
}

- setFile:(char *)filePath forKey:(int)key
 /* Map a sound file to the specified key number in the file and sound hash
  * tables. 
  */
{
	SNDSoundStruct *newSound = NULL, *oldSound;
	char   *path, *oldPath;
	int     err;
	[Conductor lockPerformance];
	NX_MALLOC(path, char, strlen(filePath) + 1);
	strcpy(path, filePath);
	
	oldPath = (char *)[fileTable insertKey:(const void *)key value:(void *)path];
	if (oldPath) NX_FREE(oldPath);

	if ((err = SNDReadSoundfile(filePath, &newSound)) != SND_ERR_NONE)
		NXRunAlertPanel("Ensemble", "Sound Library error: %s, file = %s",
			NULL, NULL, NULL, SNDSoundError(err), filePath);
	else {
		oldSound = [soundTable insertKey:(const void *)key value:(void *)newSound];
		if (oldSound) SNDFree(oldSound);
	}
	
	keyMap[key] = key;
	if (!performers[key]) {
		performers[key] = [[SoundPerformer alloc] initWithSound:newSound];
		[performers[key] setDelegate:self];
		[performers[key] enablePreloading:preloadingEnabled];
	}
	else
		[performers[key] setSoundStruct:newSound];
	if (key == keyNum)
		displayName(path, filenameField);

	[Conductor unlockPerformance];
	return self;
}

- clearAtKey:(int)aKey
{
	if (aKey == keyMap[aKey]) {
		/* This is the base key, so we need to find another base key */
		int i;
		int newBase = -1;
		keyMap[aKey] = -1;
		for (i=0; i<128; i++)
			if (keyMap[i] == aKey) {
				if (newBase == -1) {
					/* Make this key the new base key */
					SNDSoundStruct *sound;
					char *path;
					newBase = i;
					sound = [soundTable valueForKey:(const void *)aKey];
					path = [fileTable valueForKey:(const void *)aKey];
					[fileTable removeKey:(const void *)aKey];
					[soundTable removeKey:(const void *)aKey];
					[soundTable insertKey:(const void *)newBase value:(void *)sound];
					[fileTable insertKey:(const void *)newBase value:(void *)path];
				}
				keyMap[i] = newBase;
			}
		if (newBase == -1)
			[self deleteFileForKey:keyNum];
	}
		
	[performers[aKey] free];
	performers[aKey] = nil;
	keyMap[aKey] = -1;
	return self;
}

- mapKey:(int)key from:(int)minKey to:(int)maxKey
{
	int i;
	int baseKey = keyMap[key];
	SNDSoundStruct *sound;
	
	sound = [soundTable valueForKey:(const void *)baseKey];
	if (!sound) return self;
	
	for (i=minKey; i<=maxKey; i++) {
		if (keyMap[i] == baseKey) continue;
		if (keyMap[i]) [self clearAtKey:i];
		keyMap[i] = baseKey;
		performers[i] = [[SoundPerformer alloc] initWithSound:sound];
		[performers[i] setDelegate:self];
		[performers[i] enablePreloading:preloadingEnabled];
	}
	return self;
}

- loadFileList:(char *)path
{
	FILE   *fp;
	int     key;
	char   *str = malloc(sizeof(char)*(MAXPATHLEN + 1));
	char  *filename;
	
	if (!(fp = fopen(path, "r")))
		return self;

	[self freeSounds];
	[fileTable freeObjects];

	while (fscanf(fp, "%d %s ", &key, str) != EOF) {
		NX_MALLOC(filename, char, strlen(str) + 1);
		strcpy(filename, str);
		[fileTable insertKey:(const void *)key value:(void *)filename];
	}
	[self initSoundTable];
	[self initKeyMap];
	[self initPerformers];

	free(str);
	[self reset];
	return self;
}

extern void getPath(char *path, char *dir, char *name, char *ext);

- addFile:sender
 /*
  * Load a new sound file and map it to the current key. If the currrent key is
  * mapped to some other file, remove it first. Send a test note to verify and
  * insure that the file is mapped into memory. 
  */
{
	id      note;
	char    filePath[MAXPATHLEN + 1];
	char   *ext;
	char const *fileTypes[3] = {"snd", "sndkeymap", 0};
	id openPanel = [OpenPanel new];
	[openPanel allowMultipleFiles:NO];

	if (!strlen(directory)) {
		if (strlen(globalSoundDirectory))
			strncpy(directory, globalSoundDirectory, MAXPATHLEN);
		else if ([document fileDir])
			strncpy(directory, [document fileDir], MAXPATHLEN);
		else
			strcpy(directory,  NXHomeDirectory());
	}

	if ([openPanel runModalForDirectory:directory file:"" types:fileTypes]) {
		strcpy(directory,[openPanel directory]);
		if (!strlen(globalSoundDirectory))
			strcpy(globalSoundDirectory, directory);
		getPath(filePath, directory, (char *)*[openPanel filenames], NULL);
		ext = strrchr(filePath, '.');
		if (ext && !strcmp(ext, ".sndkeymap")) {
			[self loadFileList:filePath];
			return self;
		}
		[self setFile:filePath forKey:keyNum];
		[self reset];
		/* Play the first 2 seconds of the sound as a confirmation */
		[Conductor lockPerformance];
		[note = [[Note alloc] init] setDur:2.0];
		[note setNoteTag:MKNoteTag()];
		[note setPar:MK_keyNum toInt:testKey];
		[self realizeNote:note fromNoteReceiver:nil];
		[note free];
		[Conductor unlockPerformance];
		[document setEdited];
	}
	return self;
}

- removeFile:sender
{
        [Conductor lockPerformance];
	[self deleteFileForKey:keyMap[keyNum]];
        [Conductor unlockPerformance];
	return [self updateDisplay];
}

- clearKey:sender
{
        [Conductor lockPerformance];
	[self clearAtKey:keyNum];
        [Conductor unlockPerformance];
	[document setEdited];
	return [self updateDisplay];
}

- clearAll:sender
{
	[soundOutDevice abortStreams:nil];
	[self freeSounds];
	[fileTable freeObjects];
	[document setEdited];
	return [self updateDisplay];
}

- fill:sender
{
	int n = [[sender selectedCell] tag];
	if (keyMap[keyNum+n] == keyNum+n) {
		/* Bumped up against a base key, so stop */
		NXBeep();
		return self;
	}
	[Conductor lockPerformance];
	[self mapKey:keyMap[keyNum] from:keyNum+n to:keyNum+n];
	[Conductor unlockPerformance];
	testKey = (keyNum+=n);
	[document setEdited];
	return [self updateDisplay];
}
	
- takeKeyFrom:sender
{
	keyNum = [sender intValue];
	testKey = keyNum;
	[document setEdited];
	return [self updateDisplay];
	return self;
}

- displayPatchCount
{
	if (voiceCount != [voiceCountField intValue])
		[voiceCountField setIntValue:voiceCount];
	return self;
}

- takePatchCountFrom:sender
{
	voiceCount = MIN(MAX(voiceCount + [[sender selectedCell] tag], 0), 6);
	return [self displayPatchCount];
}

- (int)patchCount
{
	return voiceCount;
}

- takeDiatonicFrom:sender
{
	diatonic = [[sender selectedCell] tag];
	if (!diatonic && (pitchbendSensitivity == 0.0)) {
		[preloadingSwitch setEnabled:YES];
		[preloadingSwitch setState:preloadingEnabled];
	}
	else {
		[preloadingSwitch setEnabled:NO];
		[preloadingSwitch setState:0];
	}
	return self;
}

- takeTiesFrom:sender
{
	tieRepeats = [sender state];
	return self;
}

- takePreloadingFrom:sender
{
	id *p = performers;
	id *end = p + 128;
	preloadingEnabled = [sender state];
	while (p < end) {
		if (*p) [*p enablePreloading:preloadingEnabled];
		p++;
	}
	return self;
}

- prepareSound:aNote
{
	int i, vel;
	int key = [aNote keyNum];
	SoundPerformer *performer = performers[key];
	SNDSoundStruct *sound = [performer soundStruct];
	int baseKey = keyMap[key];

	if (!sound || (activeSoundCount >= activeSoundMax)) return self;

	if ([performer status] == MK_active) {
		if (tieRepeats) return self;
		[performer abort];
	}
	sustained[key] = damperOn;

 	while (activeVoices >= voiceCount) {
		/* Blow away the longest-running performer */
		double time = MK_ENDOFTIME;
		id oldest = nil;
		for (i = 0; i < 128; i++)
			if (performers[i] && ([performers[i] status]==MK_active) && 
				([performers[i] activationTime] < time))
				time = [oldest=performers[i] activationTime];
		if (oldest) [oldest abort]; else break;
	}
	
	vel = MKGetNoteParAsInt(aNote,MK_velocity);
	[performer setDuration:MK_ENDOFTIME];
	[performer setTag:[aNote noteTag]];
	if (vel != MAXINT) {
		float v = (float)vel/127.0;
		[performer setVelocity:1.0-(1.0-(v*v))*velocitySensitivity];
	}
	[performer setAmp:linearAmp volume:volume bearing:bearing/45.0];
	[performer enableResampling:
		(pitchbendSensitivity || (diatonic && (key != baseKey)))];
	[performer setTransposition:
		(diatonic) ? pow(2.0, (double)(key - baseKey) / 12.0) : 1.0];
	[performer setPitchBend:pitchBend];

	return performer;
}

- performerDidActivate:sender
{
	activeVoices++;
	activeSoundCount++;
	return self;
}

- performerDidDeactivate:sender
{
	if (activeVoices > 0) activeVoices--;
	if (activeSoundCount > 0) activeSoundCount--;
	return self;
}

- setAmp:(int)tag
{
	SoundPerformer **p = performers;
	SoundPerformer **end = p + 128;
	while (p < end) {
		if (*p && ((tag==MAXINT) || (tag==[*p tag])))
			[*p setAmp:linearAmp];
		p++;
	}
	return self;
}

- setVolume:(int)tag
{
	int i;
	for (i = 0; i < 128; i++)
		if ((tag==MAXINT) || (tag==[performers[i] tag]))
			[performers[i] setVolume:volume];
	return self;
}

- setBearing:(int)tag
{
	int i;
	float tmp = bearing/45.0;
	for (i = 0; i < 128; i++)
		if ((tag==MAXINT) || (tag==[performers[i] tag]))
			[performers[i] setBearing:tmp];
	return self;
}

- setPitchBend:(int)tag
{
	int i;
	for (i = 0; i < 128; i++)
		if ((tag==MAXINT) || (tag==[performers[i] tag]))
			[performers[i] setPitchBend:pitchBend];
	return self;
}

- activate:(int)tag
{
	int i;
	for (i = 0; i < 128; i++)
		if (performers[i] && ((tag==MAXINT) || (tag==[performers[i] tag])))
			[performers[i] activate];
	return self;
}

- deactivate:(int)tag
{
	int i;
	if (tag == recordTag) {
		SNDSoundStruct *newSound, *oldSound;
		[recorder stopRecording];
		newSound = [recorder soundStruct];
		oldSound = [soundTable insertKey:(const void *)recordKey value:(void *)newSound];
		if (oldSound) SNDFree(oldSound);
		[self clearAtKey:recordKey];
		keyMap[recordKey] = recordKey;
		if (!performers[recordKey]) {
			performers[recordKey] = [[SoundPerformer alloc] initWithSound:newSound];
			[performers[recordKey] setDelegate:self];
			[performers[recordKey] enablePreloading:preloadingEnabled];
		}
		else
			[performers[recordKey] setSoundStruct:newSound];
		if (recordKey == keyNum)
			[Conductor sendMsgToApplicationThreadSel:
				@selector(updateDisplay) to:self argCount:0];
		recordTag = recordKey = -1;
	}

	if (tag >=0)
		for (i = 0; i < 128; i++)
			if (performers[i] && ((tag==MAXINT) || (tag==[performers[i] tag]))) {
				[performers[i] deactivate];
				sustained[i] = NO;
			}
	return self;
}

- abort
{
	int i;
	if ([recorder isActive])
		[recorder stopRecording];
	for (i = 0; i < 128; i++) {
			[performers[i] abort];
			sustained[i] = NO;
		}
	return self;
}

- recordSound:note
{
	if (!recorder)
		recorder = [[SoundRecorder allocFromZone:[self zone]] init];
	else if ([recorder isActive])
		[self deactivate:-1];
	recordKey = [note keyNum];
	recordTag = [note noteTag];
	[recorder startRecording];
	return self;
}

#define SEND(receiver,selector,dt,arg) \
  { if (dt) [conductor sel:selector to:receiver withDelay:dt argCount:1,arg]; \
    else objc_msgSend(receiver,selector,arg); \
  }

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	MKNoteType type = [aNote noteType];
	int     noteTag = [aNote noteTag];
	double  deltaT = MKGetDeltaT() / [conductor beatSize];

	if ((type == MK_noteOn) || (type == MK_noteDur)) {
		if (!recordMode) {
			SEND(self,@selector(prepareSound:),deltaT,[aNote copy]);
		}
		else [self recordSound:aNote];
		if (type == MK_noteDur)
			SEND(self,@selector(deactivate:),deltaT+[aNote dur],noteTag);
	}
	else if ((type == MK_noteOff) && !damperOn)
		SEND(self,@selector(deactivate:),deltaT,noteTag);

	if (MKIsNoteParPresent(aNote, MK_amp)) {
		linearAmp = MKGetNoteParAsDouble(aNote, MK_amp);
		SEND(self,@selector(setAmp:),deltaT,noteTag);
	}
	if (MKIsNoteParPresent(aNote, MK_bearing)) {
		bearing = MKGetNoteParAsDouble(aNote, MK_bearing);
		SEND(self,@selector(setBearing:),deltaT,noteTag);
	}
	if (MKIsNoteParPresent(aNote, MK_pitchBendSensitivity)) {
		pitchbendSensitivity = MKGetNoteParAsDouble(aNote, MK_pitchBendSensitivity);
		pbSensitivity = (pitchbendSensitivity / 12.0) / 8192.0;
		if (!diatonic && (pitchbendSensitivity == 0.0)) {
			[preloadingSwitch setEnabled:YES];
			[preloadingSwitch setState:preloadingEnabled];
		}
		else if ([preloadingSwitch isEnabled]) {
			[preloadingSwitch setEnabled:NO];
			[preloadingSwitch setState:0];
		}
	}
	if (MKIsNoteParPresent(aNote, MK_pitchBend)) {
		double  bend = MKGetNoteParAsDouble(aNote, MK_pitchBend);
		pitchBend = pow(2.0, (bend - 8192.0) * pbSensitivity);
		SEND(self,@selector(setPitchBend:),deltaT,noteTag);
	}
	if (isControlPresent(aNote, recordModeController))
		recordMode = getControlValAsInt(aNote, recordModeController) > 0;
	if (MKIsNoteParPresent(aNote, MK_controlChange)) {
		int     controller = MKGetNoteParAsInt(aNote, MK_controlChange);

		if (controller == MIDI_DAMPER) {
			damperOn = (MKGetNoteParAsInt(aNote, MK_controlVal) >= 64);
			if (!damperOn)
				SEND(self,@selector(deactivate:),deltaT,noteTag);
		} else if (controller == MIDI_MAINVOLUME) {
			volume = (float)MKGetNoteParAsInt(aNote, MK_controlVal) / 127.0;
			SEND(self,@selector(setVolume:),deltaT,noteTag);
		} else if (controller == MIDI_PAN) {
			bearing = -45 + 90.0 * (MKGetNoteParAsInt(aNote, MK_controlVal)/127.0);
			SEND(self,@selector(setBearing:),deltaT,noteTag);
		} else if (controller == 14) {
			/* Mostly for 2.1 compatibility */
			int headphoneLevel = 
				(int)(-84.0 + MKGetNoteParAsDouble(aNote, MK_controlVal)*.66142);
			[soundOutDevice setAttenuationLeft:headphoneLevel right:headphoneLevel];
		}
	}
	
	if (((type == MK_noteOn) || (type == MK_noteDur)) && !recordMode) {
		SEND(self,@selector(activate:),deltaT,noteTag);
	}
	else if (type == MK_mute) {
		if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysReset)
			[self reset];
		else if (MKGetNoteParAsInt(aNote, MK_sysRealTime) == MK_sysStop)
			SEND(self,@selector(deactivate:),0.0,MAXINT);
	}
	
	
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the instrument to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "ii@iccci", &keyNum, &testKey, &fileTable,
				  &voiceCount, &diatonic, &tieRepeats, &preloadingEnabled,
				  &recordModeController);
	NXWriteArray(stream, "i", 128, keyMap);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the instrument from a typed stream. */
{
	int version = NXTypedStreamClassVersion(stream, "SamplerInstrument");

	[super read:stream];
	if (version == 1) {
		NXReadTypes(stream, "ii@iccc", &keyNum, &testKey, &fileTable,
				  &voiceCount, &diatonic, &tieRepeats, &preloadingEnabled);
		NXReadArray(stream, "i", 128, keyMap);
	}
	else if (version == 2) {
		NXReadTypes(stream, "ii@iccci", &keyNum, &testKey, &fileTable,
				  &voiceCount, &diatonic, &tieRepeats, &preloadingEnabled,
				  &recordModeController);
		NXReadArray(stream, "i", 128, keyMap);
	}
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];
	conductor = [Conductor defaultConductor];
	NX_MALLOC(directory, char, MAXPATHLEN + 1);
	strcpy(directory, NXHomeDirectory());
	if (!globalSoundDirectory)
		NX_MALLOC(globalSoundDirectory, char, MAXPATHLEN + 1);
	linearAmp = MKdB(amp);
	[self initSoundTable];
	[self reset];
	[self initPerformers];
	return self;
}

@end
