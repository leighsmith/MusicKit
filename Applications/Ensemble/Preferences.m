#import "Preferences.h"
#import <appkit/appkit.h>
#import "EnsembleApp.h"

@implementation Preferences
{
}

+ initialize
 /* The "default" defaults */
{
	static NXDefaultsVector EnsembleDefaults = {
		{"DSPSamplingRate", "44100"},
		{"OrchestraHeadroom", "0.18"},
		{"OrchestraPreemption", "0.003"},
		{"DeltaT", "0.006"},
		{"FileDeltaT", "0.5"},
		{"MIDIDevice", "0"},
		{"RetainDSP", "YES"},
		{"Leader", "1.0"},
		{"ProgramChannel", "1"},
		{"DocDirectory", "/LocalLibrary/Music/Ensemble"},
		{"MidiInit", ""},
		{"MultiThreaded", "NO"},
		{"MidiTimedOutput", "YES"},
		{"AutoLoadDocs", "NO"},
		{"AutoPlay", "NO"},
		{"SoundBuffers", "ROBUST"},
		{"ScoresToMIDI", "NO"},
		{"SendMIDIRealTimeNotes", "YES"},
		{"ActiveSoundMax", "16"},
		{NULL}
	};

	NXRegisterDefaults("Ensemble", EnsembleDefaults);
	return self;
}

- init
{
	NX_MALLOC(channel, char, 3);
	return[super init];
}

- takeSamplingRateFrom:sender
{
	samplingRate = [[sender selectedCell] title];
	return self;
}

- takeHeadroomFrom:sender
{
	headroom = [sender stringValue];
	return self;
}

- takePreemptionTimeFrom:sender
{
	preemption = [sender stringValue];
	return self;
}

- takeDeltaTFrom:sender
{
	if (![[sender selectedCell] tag])
		deltaT = [sender stringValue];
	else
		fileDeltaT = [sender stringValue];
	return self;
}

static char serialPortString[2] = {'\0'};

- takeSerialPortFrom:sender;
{
	strncpy(serialPortString,[[sender selectedCell] title],1);
	serialPort = serialPortString;
	return self;
}

- takeRetainDSPFrom:sender
{
	retainDSP = ([sender state]) ? "YES" : "NO";
	return self;
}

- takeLeaderFrom:sender
{
	leader = [sender stringValue];
	return self;
}

- takeChannelFrom:sender
{
	int     n = strtol(channel, NULL, 0);

	sprintf((char *)channel, "%d", MAX(MIN(n + [[sender selectedCell] tag], 16), 1));
	[channelDisplayer setStringValue:channel];
	return self;
}

- takeDocDirectoryFrom:sender
{
	docDirectory = [sender stringValue];
	return self;
}

- takeMidiInitFrom:sender
{
	midiInit = [sender stringValue];
	return self;
}

- takeMultiThreadedFrom:sender
{
	multiThreaded = ([sender state]) ? "YES" : "NO";
	return self;
}

- takeMidiTimedFrom:sender
{
	midiTimedOutput = ([sender state]) ? "YES" : "NO";
	return self;
}

- takeSoundBuffersFrom:sender
{
	soundBuffers = ([[sender selectedCell] tag] == 1) ? "RESPONSIVE" : "ROBUST";
	return self;
}

- takeScoresToMIDIFrom:sender
{
	scoresToMIDI = ([sender state]) ? "YES" : "NO";
	return self;
}

- takeRealTimeNotesFrom:sender
{
	sendRealTimeNotes = ([sender state]) ? "YES" : "NO";
	return self;
}


typedef enum {
	SSAD64x_tag = 0,
	StealthDAI2400_tag = 1,
	ArielProPort_tag = 2,
	Generic_tag = 3,
    NumSerialPortTags = 5} serialPortTags;

static char *serialTagToName[] = 
  /* These are the class names */
  {"SSAD64x",
  "StealthDAI2400",
  "ArielProPort",
  "DSPSerialPortDevice"};

-(int)serialDevice
{
	int i;
	char *s;
	if (!([[NXApp orchestra] capabilities] & MK_nextCompatibleDSPPort))
	  return Generic_tag;
	s =	(char *)NXGetDefaultValue("MusicKit", "DSPSerialPortDevice0");
	for (i=0; i<NumSerialPortTags; i++)
	  if (!strcmp(s,serialTagToName[i]))
		return i;
	return Generic_tag;
}

- takeSerialDeviceFrom:sender
{
	serialDevice = serialTagToName[[[sender selectedCell] tag]];
	return self;
}

- takeSoundOutFrom:sender
{
    soundOut = ([[sender selectedCell] tag] == 1) ? "SSI" : "Host";
    return self;
}

- takeSoundMaxFrom:sender
{
	soundMax = [sender stringValue];
	return self;
}

- (double)samplingRate
{
	return strtod(NXGetDefaultValue("Ensemble", "DSPSamplingRate"), NULL);
}

- (double)headroom
{
	return strtod(NXGetDefaultValue("Ensemble", "OrchestraHeadroom"), NULL);
}

- (double)preemption
{
	return strtod(NXGetDefaultValue("Ensemble", "OrchestraPreemption"), NULL);
}

- (double)deltaT
{
	return strtod(NXGetDefaultValue("Ensemble", "DeltaT"), NULL);
}

- (double)fileDeltaT
{
	return strtod(NXGetDefaultValue("Ensemble", "FileDeltaT"), NULL);
}

- (const char *)serialPort
{
	return (!strcmp(NXGetDefaultValue("Ensemble", "MIDIDevice"), "0")) ?
		"midi0" : "midi1";
}

- (BOOL)retainDSP
{
	return (!strcmp(NXGetDefaultValue("Ensemble", "RetainDSP"), "YES"));
}

- (double)leader
{
	return strtod(NXGetDefaultValue("Ensemble", "Leader"), NULL);
}

- (int)channel
{
	return strtol(NXGetDefaultValue("Ensemble", "ProgramChannel"), NULL, 0);
}

- (const char *)docDirectory
{
	return NXGetDefaultValue("Ensemble", "DocDirectory");
}

- (const char *)midiInit;
{
	return NXGetDefaultValue("Ensemble", "MidiInit");
}

- (BOOL)multiThreaded
{
	return (!strcmp(NXGetDefaultValue("Ensemble", "MultiThreaded"), "YES"));
}

- (BOOL)midiTimedOutput
{
	return (!strcmp(NXGetDefaultValue("Ensemble", "MidiTimedOutput"), "YES"));
}

- (BOOL)bigBuffers
{
	return (!strcmp(NXGetDefaultValue("Ensemble", "SoundBuffers"), "ROBUST"));
}

- (BOOL)scoresToMIDI
{
	return (!strcmp(NXGetDefaultValue("Ensemble", "ScoresToMIDI"), "YES"));
}

- (BOOL)sendRealTimeNotes
{
	return (!strcmp(NXGetDefaultValue("Ensemble", "SendMIDIRealTimeNotes"), "YES"));
}

- setSerialDevice
  /* Invoked by EnsembleApp when it wants to set the Orchestra's serial
   *	 port device.
   */
{
	id orch = [NXApp orchestra];
	id device;
	if (!([orch capabilities] & MK_nextCompatibleDSPPort))
	  return nil;  
	switch ([self serialDevice]) {
	  case SSAD64x_tag:
		device = [[SSAD64x alloc] init];
		break;
	  case StealthDAI2400_tag:
		device = [[StealthDAI2400 alloc] init];
		break;
	  case ArielProPort_tag:
		device = [[ArielProPort alloc] init];
		break;
	  default:
	  case Generic_tag:
		device = [[DSPSerialPortDevice alloc] init];
		break;
	}
	[[orch serialPortDevice] free];  /* Free old one, if any */ 
	[orch setSerialPortDevice:device];
	return self;
}

- (BOOL)serialSoundOut
{
	unsigned orchCapabilities = [[NXApp orchestra] capabilities];
	if (orchCapabilities & MK_hostSoundOut)
	  return (!strcmp(NXGetDefaultValue("MusicKit", "OrchestraSoundOut"),"SSI"));
	else return YES;
}

- (int)soundMax
{
	return strtol(NXGetDefaultValue("Ensemble", "ActiveSoundMax"), NULL, 0);
}

- displayDefaults
 /* Set up the preferences panel to reflect the current defaults */
{
	unsigned orchCapabilities = [[NXApp orchestra] capabilities];
	samplingRate = NXGetDefaultValue("Ensemble", "DSPSamplingRate");
	headroom = NXGetDefaultValue("Ensemble", "OrchestraHeadroom");
	preemption = NXGetDefaultValue("Ensemble", "OrchestraPreemption");
	deltaT = NXGetDefaultValue("Ensemble", "DeltaT");
	fileDeltaT = NXGetDefaultValue("Ensemble", "FileDeltaT");
	serialPort = NXGetDefaultValue("Ensemble", "MIDIDevice");
	retainDSP = NXGetDefaultValue("Ensemble", "RetainDSP");
	leader = NXGetDefaultValue("Ensemble", "Leader");
	channel = NXGetDefaultValue("Ensemble", "ProgramChannel");
	docDirectory = NXGetDefaultValue("Ensemble", "DocDirectory");
	midiInit = NXGetDefaultValue("Ensemble", "MidiInit");
	multiThreaded = NXGetDefaultValue("Ensemble", "MultiThreaded");
	midiTimedOutput = NXGetDefaultValue("Ensemble", "MidiTimedOutput");
	soundBuffers = NXGetDefaultValue("Ensemble", "SoundBuffers");
	scoresToMIDI = NXGetDefaultValue("Ensemble", "ScoresToMIDI");
	sendRealTimeNotes = NXGetDefaultValue("Ensemble", "SendMIDIRealTimeNotes");
	serialDevice = NXGetDefaultValue("MusicKit", "DSPSerialPortDevice0");
	if (orchCapabilities & MK_hostSoundOut)
	  soundOut = NXGetDefaultValue("MusicKit", "OrchestraSoundOut");
	else soundOut = "SSI";
	soundMax = NXGetDefaultValue("Ensemble", "ActiveSoundMax");
	[srateDisplayer selectCellWithTag:strtol(samplingRate, NULL, 0)];
	[headroomDisplayer setStringValue:headroom];
	[preemptionDisplayer setStringValue:preemption];
	[[deltaTDisplayer cellAt:0 :0] setStringValue:deltaT];
	[[deltaTDisplayer cellAt:1 :0] setStringValue:fileDeltaT];
	[serialPortDisplayer selectCellWithTag:(!strcmp(serialPort, "0")) ? 0 : 1];
	[retainDSPDisplayer setState:!strcmp(retainDSP, "YES")];
	[leaderDisplayer setStringValue:leader];
	[channelDisplayer setStringValue:channel];
	[directoryDisplayer setStringValue:docDirectory];
	[midiInitDisplayer setStringValue:midiInit];
	[multiThreadDisplayer setState:!strcmp(multiThreaded, "YES")];
	[midiTimedDisplayer setState:!strcmp(midiTimedOutput, "YES")];
	[buffersDisplayer selectCellWithTag:(!strcmp(soundBuffers, "ROBUST"))?0:1];
	[scoresToMIDIDisplayer setState:!strcmp(scoresToMIDI, "YES")];
	[realTimeNotesDisplayer setState:!strcmp(sendRealTimeNotes, "YES")];
	[soundOutDisplayer selectCellAt:0:(!strcmp(soundOut,"SSI") ? 1 : 0)];
	if (!(orchCapabilities & MK_hostSoundOut)) 
	  [soundOutDisplayer setEnabled:NO];
	[deviceDisplayer selectCellAt:[self serialDevice]:0];
	if (!(orchCapabilities & MK_nextCompatibleDSPPort))
	  [deviceDisplayer setEnabled:NO];
	[soundMaxDisplayer setStringValue:soundMax];
	return self;
}

- writeDefaults
{
	unsigned orchCapabilities = [[NXApp orchestra] capabilities];
	NXWriteDefault("Ensemble", "DSPSamplingRate", samplingRate);
	NXWriteDefault("Ensemble", "OrchestraHeadroom", headroom);
	NXWriteDefault("Ensemble", "OrchestraPreemption", preemption);
	NXWriteDefault("Ensemble", "DeltaT", deltaT);
	NXWriteDefault("Ensemble", "FileDeltaT", fileDeltaT);
	NXWriteDefault("Ensemble", "MIDIDevice", serialPort);
	NXWriteDefault("Ensemble", "RetainDSP", retainDSP);
	NXWriteDefault("Ensemble", "Leader", leader);
	NXWriteDefault("Ensemble", "ProgramChannel", channel);
	NXWriteDefault("Ensemble", "DocDirectory", docDirectory);
	NXWriteDefault("Ensemble", "MidiInit", midiInit);
	NXWriteDefault("Ensemble", "MultiThreaded", multiThreaded);
	NXWriteDefault("Ensemble", "MidiTimedOutput", midiTimedOutput);
	NXWriteDefault("Ensemble", "SoundBuffers", soundBuffers);
	NXWriteDefault("Ensemble", "ScoresToMIDI", scoresToMIDI);
	NXWriteDefault("Ensemble", "SendMIDIRealTimeNotes", sendRealTimeNotes);
	NXWriteDefault("Ensemble", "ActiveSoundMax", soundMax);
	if (orchCapabilities & MK_hostSoundOut) /* Otherwise, just default above */
	  NXWriteDefault("MusicKit", "OrchestraSoundOut", soundOut);
	if (orchCapabilities & MK_nextCompatibleDSPPort)
	  NXWriteDefault("MusicKit", "DSPSerialPortDevice0", serialDevice);
	return self;
}

- runModal:sender
{
	id      returnVal = nil;

	[self displayDefaults];
	[self center];
	[self makeKeyAndOrderFront:self];
	if ([NXApp runModalFor:self] == NX_RUNSTOPPED) {
		[self writeDefaults];
		returnVal = self;
	}
	[self close];
	return returnVal;
}

- ok:sender
{
	return[NXApp stopModal];
}

- cancel:sender
{
	[NXApp abortModal];
	return nil;
}

@end
