#import <musickit/musickit.h>
#import "ResonController.h"
#import "ResonSound.h"


@implementation ResonController

#define VOICE_COUNT 8  /* Must be even */
#define FIRST_B (VOICE_COUNT/2)

static id anOrch = nil;
static id notes[VOICE_COUNT];
static int feedbackGainPar,chanPar;
static id aNoteSender,anIns;
static BOOL serialSoundOut = NO;
static id serialPortDevice = nil;

+ initialize
{
    feedbackGainPar = [MKNote parName:"feedbackGain"];
    chanPar = [MKNote parName:"chan"];
    anOrch = [MKOrchestra new];        
    return self;
}

static char *keyNumToName(int keyNum) {
    static char *name[4];
    char *s = NULL;
    int base = c1k;
    int octave = (keyNum - base) / 12;
    int scaleDegree = (keyNum - base) % 12;
    switch (scaleDegree) {
      case 0:
	s = "C";
	break;
      case 1:
	s = "C#";
	break;
      case 2:
	s = "D";
	break;
      case 3:
	s = "Eb";
	break;
      case 4:
	s = "E";
	break;
      case 5:
	s = "F";
	break;
      case 6:
	s = "F#";
	break;
      case 7:
	s = "G";
	break;
      case 8:
	s = "G#";
	break;
      case 9:
	s = "A";
	break;
      case 10:
	s = "Bb";
	break;
      case 11:
	s = "B";
	break;
      default:
	break;
    }
    sprintf((char *)name,"%s%d",s,octave);
    return (char *)name;
}

- showInfoPanel:sender
{
    id obj;
    [NXApp loadNibSection:"Info.nib" owner:NXApp withNames:YES];
    obj = NXGetNamedObject("Info",NXApp);
    [obj makeKeyAndOrderFront:self];
    return self;
}

static int sliderToKeyNum(float val)
{
    return (100-c1k) * val + c1k;
}

static double sliderToFBG(float val)
{
    if (val < .99)
      return val;  /* Maybe a different scaling here? */
    else return .99;
}

static double sliderToAmp(float dB)
{
    double ampVal = (dB < .01) ? 0 : (MKdB(dB * 60 - 60) / VOICE_COUNT);
    return (ampVal > .2) ? .2 : ampVal;
}

static double sliderToPan(float val)
{
    return 90 * val - 45;
}

- _makeNotes
{
    int i;
    if (!notes[0])
      for (i=0; i<VOICE_COUNT; i++) {
	  notes[i] = [[MKNote alloc] init];
	  [notes[i] setNoteTag:MKNoteTag()];
	  [notes[i] setPar:chanPar toInt:(i < FIRST_B) ? 0 : 1];
	  [[ampFieldBank cellAt:i :0] setFloatValue:
	   sliderToAmp([[ampSliderBank cellAt:i :0] floatValue])];
	  [[freqFieldBank cellAt:i :0] 
	  setStringValue:keyNumToName(sliderToKeyNum([[freqSliderBank cellAt:i :0] 
						      floatValue]))];
	  [[panFieldBank cellAt:i :0] 
	   setFloatValue:sliderToPan([[panSliderBank cellAt:i :0] floatValue])];
	  [[resGainFieldBank cellAt:i :0] 
	   setFloatValue:sliderToFBG([[resGainSliderBank cellAt:i :0] floatValue])];
      }
    return self;
}

- appDidInit:sender
{
    [self _makeNotes];
    if (!([anOrch capabilities] & MK_hostSoundOut)) {
	[outputDevice selectCellWithTag:1];
	[outputDevice setEnabled:NO];
    }
    if (!([anOrch capabilities] & MK_nextCompatibleDSPPort)) {
	[inputDevice selectCellWithTag:0];
	[inputDevice setEnabled:NO];
    } else {
	id serialPortDeviceClass = [[anOrch serialPortDevice] class];
	if (serialPortDeviceClass == [ArielProPort class])
	  [inputDevice selectCellWithTag:1];
	else if (serialPortDeviceClass == [StealthDAI2400 class])
	  [inputDevice selectCellWithTag:2];
	else if (serialPortDeviceClass == [SSAD64x class])
	  [inputDevice selectCellWithTag:3];
	else if (serialPortDeviceClass == [DSPSerialPortDevice class])
	  [inputDevice selectCellWithTag:4];
	else [inputDevice selectCellWithTag:0];
    }
    return self;
}

- _startNote:(int)i
{
    [notes[i] setNoteType:MK_noteOn];
    
    [notes[i] setPar:MK_amp 
   toDouble:sliderToAmp([[ampSliderBank cellAt:i :0] floatValue])];
    
    [notes[i] setPar:MK_keyNum 
   toInt:sliderToKeyNum([[freqSliderBank cellAt:i :0] floatValue])];
    
    [notes[i] setPar:MK_bearing 
   toDouble:sliderToPan([[panSliderBank cellAt:i :0] floatValue])];
    
    [notes[i] setPar:feedbackGainPar 
   toDouble:sliderToFBG([[resGainSliderBank cellAt:i :0] floatValue])];
    
    [aNoteSender sendNote:notes[i]];
    [notes[i] removePar:MK_amp];
    [notes[i] removePar:MK_keyNum];
    [notes[i] removePar:MK_bearing];
    return self;
}

- _startNotes
{
    int i;
    [MKConductor lockPerformance];
    for (i=0; i<VOICE_COUNT; i++) 
      [self _startNote:i];
    [MKConductor unlockPerformance];
    return self;
}

-_stop {
    [anOrch abort];
    [MKConductor finishPerformance];
    anIns = [anIns free];
    aNoteSender = [aNoteSender free];
    if (([anOrch capabilities] & MK_hostSoundOut))
	[outputDevice setEnabled:YES];
    if (([anOrch capabilities] & MK_nextCompatibleDSPPort))
	[inputDevice setEnabled:YES];
    return self;
}

#define DEFAULT_SOUND_OUT 0

-_run {
    int inputTag,outputTag;
    [outputDevice setEnabled:NO];
    [inputDevice setEnabled:NO];
    if (!([anOrch capabilities] & MK_hostSoundOut)) {
	if ([[outputDevice selectedCell] tag] == 0) {
	    NXRunAlertPanel("Reson",
			    "Sorry, NeXT sound output is not available on Intel-based computers.",
			    "OK",NULL,NULL);
	    return nil;
	}
    }
    serialPortDevice = [serialPortDevice free];
    outputTag = [[outputDevice selectedCell] tag];
    inputTag = [[inputDevice selectedCell] tag];
    serialSoundOut = (outputTag == 1);
    switch (inputTag) {
      default: /* Let the orchestra handle it */
	break;
      case 1:
	serialPortDevice = [[ArielProPort alloc] init];
	break;
      case 2:
	serialPortDevice = [[StealthDAI2400 alloc] init];
	break;
      case 3:
	serialPortDevice = [[SSAD64x alloc] init];
	break;
      case 4:
	serialPortDevice = [[DSPSerialPortDevice alloc] init];
	break;
    }
    if (serialSoundOut && (inputTag == 4)) {
	NXRunAlertPanel("Reson",
			"Sorry, the selected serial port device does not support sound output.",
			"OK",NULL,NULL);
	if ([anOrch capabilities] & MK_hostSoundOut) {
	    [outputDevice selectCellAt:0 :0];
	    serialSoundOut = NO;
	} else return nil;
    }
// [anOrch setOnChipMemoryConfigDebug:YES patchPoints:0];
    if (inputTag == DEFAULT_SOUND_OUT)
      [anOrch setDefaultSoundOut]; 
    else {
	[anOrch setSerialSoundOut:serialSoundOut];
	[anOrch setHostSoundOut:!serialSoundOut];
	[anOrch setSerialPortDevice:serialPortDevice];
    }
    [anOrch setSerialSoundIn:YES];
    if ([anOrch supportsSamplingRate:22050])
      [anOrch setSamplingRate:22050];
    else [anOrch setSamplingRate:[anOrch defaultSamplingRate]];
    while (![anOrch open]) 
      if (NXRunAlertPanel("Reson",
			  "Can't open DSP.  Another application probably has it.",
			  "Try Again","Quit",NULL) 
	  != NX_ALERTDEFAULT)
	exit(0);
    anIns = [SynthInstrument new];      
    [anIns setSynthPatchClass:[ResonSound class]]; 
    [anIns setSynthPatchCount:VOICE_COUNT/2 patchTemplate:
     [ResonSound patchTemplateFor:notes[0]]];
    [anIns setSynthPatchCount:VOICE_COUNT/2 patchTemplate:
     [ResonSound patchTemplateFor:notes[FIRST_B]]];
    aNoteSender = [[NoteSender alloc] init];
    [aNoteSender connect:[anIns noteReceiver]];
    [MKConductor setClocked:YES];
    [MKConductor setFinishWhenEmpty:NO];
    [anOrch run];                  /* Start the DSP. */
    [MKConductor startPerformance];  /* Start sending Notes, loops till done.*/
    [self _startNotes];
    return self;
}

- runFrom:sender
{
    if ([anOrch deviceStatus] == MK_devClosed) {
	if (![self _run])
	  [sender setState:0];
    }
    else [self _stop];
    return self;
}

- setAmpFromSlider:sender
{
    id cell = [sender selectedCell];
    int row = [sender selectedRow];
    float amp = sliderToAmp([cell floatValue]);
    [MKConductor lockPerformance];
    [notes[row] setNoteType:MK_noteUpdate];
    [notes[row] setPar:MK_amp toDouble:amp];
    [aNoteSender sendNote:notes[row]];
    [notes[row] removePar:MK_amp];
    [MKConductor unlockPerformance];
    [[ampFieldBank cellAt:row :0] setFloatValue:amp];
    return self;
}

- setFreqFromSlider:sender
{
    id cell = [sender selectedCell];
    int row = [sender selectedRow];
    int keyNum = sliderToKeyNum([cell floatValue]);
    [MKConductor lockPerformance];
    [notes[row] setNoteType:MK_noteUpdate];
    [notes[row] setPar:MK_keyNum toInt:keyNum];
    [aNoteSender sendNote:notes[row]];
    [notes[row] removePar:MK_keyNum];
    [MKConductor unlockPerformance];
    [[freqFieldBank cellAt:row :0] setStringValue:keyNumToName(keyNum)];
    return self;
}

- setPanFromSlider:sender
{
    id cell = [sender selectedCell];
    int row = [sender selectedRow];
    float bearing = sliderToPan([cell floatValue]);
    [MKConductor lockPerformance];
    [notes[row] setNoteType:MK_noteUpdate];
    [notes[row] setPar:MK_bearing toDouble:bearing];
    [aNoteSender sendNote:notes[row]];
    [notes[row] removePar:MK_bearing];
    [MKConductor unlockPerformance];
    [[panFieldBank cellAt:row :0] setFloatValue:bearing];
    return self;
}

- setResGainFromSlider:sender
{
    id cell = [sender selectedCell];
    int row = [sender selectedRow];
    float feedbackGain = sliderToFBG([cell floatValue]);
    [MKConductor lockPerformance];
    [notes[row] setNoteType:MK_noteUpdate];
    [notes[row] setPar:feedbackGainPar toDouble:feedbackGain];
    [aNoteSender sendNote:notes[row]];
    [notes[row] removePar:feedbackGainPar];
    [MKConductor unlockPerformance];
    [[resGainFieldBank cellAt:row :0] setFloatValue:feedbackGain];
    return self;
}

- setSamplingRateFrom:sender
  /* Might be nice to do this someday! */
{
    return self;
}

- setVarietyModeFrom:sender
  /* Might be nice to do this someday! */
{
    return self;
}

static BOOL fileExists(char *name)
{
	FILE   *fp;

	if (fp = fopen(name, "r")) {
		fclose(fp);
		return YES;
	} else
		return NO;
}

- help:sender
 /* Display the help text file with Edit. */
{
	int     ok = 0;
	port_t	port;
	char   *helpfile;
	NX_MALLOC(helpfile, char, MAXPATHLEN + 1);
	sprintf(helpfile, "%s/help.rtfd", *NXArgv);	/* Look in the app wrapper */
	if (!fileExists(helpfile)) {/* If not there, try the directory. */
		char   *end = strrchr(*NXArgv, '/');
		int     n = (end) ? end - *NXArgv + 1 : 0;

		if (n) {
			strncpy(helpfile, *NXArgv, n);
			helpfile[n] = '\0';
			strcat(helpfile, "help.rtfd");
		} else {
			getwd(helpfile);
			strcat(helpfile, "/help.rtfd");
		}
	}
	port = NXPortFromName("Edit",NULL);
	if (port == PORT_NULL) 
		return nil;
	[[NXApp appSpeaker] setSendPort: port];
        if ([[NXApp appSpeaker] openFile:helpfile ok:&ok] || !ok) 
		NXRunAlertPanel("Reson", "Can't open help file", NULL, 
				NULL, NULL);
	NX_FREE(helpfile);
	return self;
}
@end
