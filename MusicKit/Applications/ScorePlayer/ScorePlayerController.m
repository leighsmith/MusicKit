/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Addition of timecode and Intel support copyright David A. Jaffe, 1992 */

/* This is NOT a good programming example.  It is full of special-purpose
 * hacks, some of which have only historical signifigance.  Please see
 * /LocalDeveloper/Examples/MusicKit for good examples of how to use the
 * Music Kit.
 */

/* Modification history:

   8/9/90/daj - Changed to allow abort on all alert panels.
   8/9/90/daj - Changes for thread safety.
   8/14/90/daj - Added setuid(getuid())
   8/18/90/daj - Increased deltaT to .75 from .5.  Especially in view of the
		 -open bug (the buffers don't seem to be filling properly)
		 this is probably a good idea.
   8/20/90/daj - Added automatic tempo adjustment when falling out of real 
                 time.
                 This required starting the tempo animation at the start of 
		 the performance.
   10/8/90/daj - Changed to make automatic tempo adjustment NOT the default.
   1/25/91/daj - Changed to use scrolling alert panel for Music Kit messages.
   4/24/91/daj - Changed to not complain if there's no part info or no
                 synthpatch in the part info.
   4/26/91/daj - More work on the damn alert panel stuff.
   8/22/91/daj - Localized.
   6/06/92/daj - Added resetting of tuning system before reading a new file.
   10/21/92/daj - Various fixes.
   9/28/94/daj - Changes for Intel support.
*/   

#import "ErrorLog.h"
#import "MKAlert.h"
#import "ScorePlayerController.h"
#import "Animator.h"
#import <AppKit/AppKit.h>
#import <objc/NXBundle.h>
#import <MusicKit/MusicKit.h>

@implementation ScorePlayerController

static BOOL playScoreForm;
static id synthInstruments;
static id openPanel;
static char* fileName,*shortFileName;
static id scoreObj,scorePerformer,theOrch;
static double headroom = .1;
static BOOL userCancelFileRead = NO;
static char errMsg[200];
static double initialTempo = 60.0;
static double lastTempo = 60.0;
static double desiredTempo = 60.0;
static char *fileSuffixes[3] = {"score","playscore",NULL};
static char *dir = NULL;
static id condClass = nil;
static BOOL messageFlashed = NO;
static BOOL isLate = NO;
static BOOL wasLate = NO;
static id stopImage,playImage,playHImage;
static id midis[2] = {0};
static int midiOffset;
static BOOL synchToTimeCode = NO;
static int timeCodePort = 0;
static unsigned capabilities;
static double samplingRate;

static char outputFilePath[MAXPATHLEN+1]; /* Complete output file path */
static char outputFileDir[MAXPATHLEN+1];	 /* Just the directory */
static char outputFileName[MAXPATHLEN+1]; /* Just the name */


static BOOL DSPCommands = NO;
static BOOL writeData = NO;

#define PLAYING ([condClass performanceThread] != NO_CTHREAD)

#define SOUND_OUT_PAUSE_BUG 1 /* Workaround for problem synching MIDI to DSP */

static int handleObjcError(const char *className)
{
    return 0;
}

static id errorLog;
static BOOL errorDuringPlayback = NO;

- showConductorDidSeek
{
    [timeCodeTextField setStringValue:"Time code running"];
    return self;
}

- showConductorWillSeek
{
    [timeCodeTextField setStringValue:"Time code starting..."];
    return self;
}
 
- showConductorDidReverse
{
     [timeCodeTextField setStringValue:"Time code running backwards"];
     return self;
}
 
- showConductorDidPause
{
    [timeCodeTextField setStringValue:
     "Time code stopped.  Waiting for time code to start"];
    return self;
}

- showConductorDidResume
{
    [timeCodeTextField setStringValue:"Time code running"];
    return self;
}

-showErrorLog:sender
{
    return [errorLog show];
}

-runAlert:(char *)text
{
    [errorLog addText:text];
    free(text);
    errorDuringPlayback = YES;
    return self;
}

static int warnedAboutSrate = NO;

/* Localizable strings */
#define MB [NXBundle mainBundle]

#define STR_SCOREPLAYER NXLocalStringFromTableInBundle("ScorePlayer",MB,"ScorePlayer",NULL,"Name of program")

#define STR_SCOREPLAYER_ERROR NXLocalStringFromTableInBundle("ScorePlayer",MB,"ScorePlayer Error",NULL,"ScorePlayer error alert panel name.")

#define STR_OK NXLocalStringFromTableInBundle("ScorePlayer",MB,"OK",NULL,"OK button name")

#define STR_CANCEL NXLocalStringFromTableInBundle("ScorePlayer",MB,"Cancel",NULL,"Cancel button name")

#define STR_FILE_CHANGED NXLocalStringFromTableInBundle("ScorePlayer",MB,"File has changed. Reread it?",NULL,"This message appears when the user attempts to play a file, but that file has changed.")

#define STR_YES NXLocalStringFromTableInBundle("ScorePlayer",MB,"Yes",NULL,"Yes button name")

#define STR_NO NXLocalStringFromTableInBundle("ScorePlayer",MB,"No",NULL,"No button name")

#define STR_NO_FILE_OPEN NXLocalStringFromTableInBundle("ScorePlayer",MB,"No file open.",NULL,"This message appears when the user asks to edit a file but no file is open. Also used as title of main window when no file is open.")

#define STR_NO_SETTINGS NXLocalStringFromTableInBundle("ScorePlayer",MB,"The selected device has no user-settable settings.",NULL,"This message appears when the user asks to set settings of a sound out device for which there is no settings panel.")

#define STR_EDIT_CANT_OPEN_FILE NXLocalStringFromTableInBundle("ScorePlayer",MB,"Edit can't open file.",NULL,"This message appears if the user tries to edit a file but that file can't be opened.")

#define STR_READING NXLocalStringFromTableInBundle("ScorePlayer",MB,"Reading %s...",NULL,"This message appears when a file is being read.  It takes one argument which follows the message. E.g. 'Reading x.score...'")

#define STR_HUNG_DSP NXLocalStringFromTableInBundle("ScorePlayer",MB,"No response from DSP--aborting",NULL,"Hung DSP msg")

#define STR_FIX_ERRORS NXLocalStringFromTableInBundle("ScorePlayer",MB,"Fix scorefile errors and try again.",NULL,"This message appears after the user aborts a scorefile parse due to errors.")

#define STR_BAD_SRATE NXLocalStringFromTableInBundle("ScorePlayer",MB,"Sampling rate must be 44100 or 22050 for the NeXT DACs--using default of 22050.",NULL,"This message appears if the scorefile specifies an illegal sampling rate.")

#define STR_BAD_SSI_SRATE NXLocalStringFromTableInBundle("ScorePlayer",MB,"Requested sampling rate not supported by the specified serial port device.",NULL,"This message appears if the scorefile specifies an illegal sampling rate for SSI device.")

#define STR_ERRORS NXLocalStringFromTableInBundle("ScorePlayer",MB,"There were errors during playback.\nClick the \"Show Errors\" menu item to view them.",NULL,"This message appears after a file is played if errors occurred during playback")

#define STR_CANT_OPEN_DSP NXLocalStringFromTableInBundle("ScorePlayer",MB,"Can't open DSP. Perhaps another application has it.",NULL,"This message appears if the DSP is busy.")

#define STR_INFO_MISSING NXLocalStringFromTableInBundle("ScorePlayer",MB,"%s info missing.",NULL, "This message takes one leading argument, the name of a scorefile part.  It appears when a part is declared with no info.")

#define STR_NO_SYNTHPATCH NXLocalStringFromTableInBundle("ScorePlayer",MB,"This scorefile calls for a synthesis instrument (%s) that isn't available in this application.",NULL,"This message appears if a SynthPatch is specified in the scorefile for which no SynthPatch can be found.  Its one argument is the name of the SynthPatch.")

#define STR_CONTINUE NXLocalStringFromTableInBundle("ScorePlayer",MB,"Continue",NULL,"Continue button name")

#define STR_PLAYING NXLocalStringFromTableInBundle("ScorePlayer",MB,"Playing %s...",NULL,"This message appears when a file is being played.  The trailing argument is the name of the file.")

#define STR_TOO_MANY_SYNTHPATCHES NXLocalStringFromTableInBundle("ScorePlayer",MB,"Could only allocate %d instead of %d %ss for %s",NULL,"This message apepars when too many Synthpatches are requested in the scorefile for a given part. There are four arguments, which must appear in the following order: 1 = the number of patches that could be allocated, 2 = number of patches that were requested to be allocated, 3 = the name of the synthpatch specified in the scorefile and 4 = the part name")

#define STR_SCOREFILE NXLocalStringFromTableInBundle("ScorePlayer",MB,"Score File",NULL,"This appears in the SaveAs... panel")

#define STR_PLAYSCOREFILE NXLocalStringFromTableInBundle("ScorePlayer",MB,"Playscore File",NULL,"This appears in the SaveAs... panel")

#define STR_MIDIFILE NXLocalStringFromTableInBundle("ScorePlayer",MB,"MIDI File",NULL,"This appears in the SaveAs... panel")

#define STR_DSPFILE NXLocalStringFromTableInBundle("ScorePlayer",MB,"DSPCommands File",NULL,"This appears in the SaveAs... panel")

#define STR_SOUNDFILE NXLocalStringFromTableInBundle("ScorePlayer",MB,"Sound File",NULL,"This appears in the SaveAs... panel")

#define STR_CANT_OPEN_MIDI NXLocalStringFromTableInBundle("ScorePlayer",MB,"Can't open serial port for MIDI. Perhaps another application has it.",NULL,"This message appears if the serial port is busy.")

static void handleMKError(char *msg)
{
    if (!PLAYING) {
	[errorLog addText:msg];
	if (!mkRunAlertPanel(STR_SCOREPLAYER_ERROR,msg,STR_OK,STR_CANCEL,NULL))
	    {
		MKSetScorefileParseErrorAbort(0);
		userCancelFileRead = YES;         /* A kludge for now. */
	    }
    }
    else {
	char *str = malloc(strlen(msg)+1);
	strcpy(str,msg);
	[Conductor sendMsgToApplicationThreadSel:@selector(runAlert:) to:NXApp
         argCount:1, (id)str];
    }
}

#import <sys/types.h>
#import <sys/stat.h>

static time_t lastModifyTime;

static void setFileTime(void)
{
    struct stat info;
    if (playScoreForm)
      return;
    stat(fileName,&info);
    lastModifyTime = info.st_mtime;
}

static BOOL needToReread(void)
{
    struct stat info;
    BOOL rtnVal;
    if (playScoreForm)
      return NO;
    stat(fileName,&info);
    rtnVal = (info.st_mtime > lastModifyTime);
    if (rtnVal)
      rtnVal = NXRunAlertPanel(STR_SCOREPLAYER,STR_FILE_CHANGED, 
			       STR_YES,STR_NO,STR_CANCEL);
    if (rtnVal != NX_ALERTOTHER)
      lastModifyTime = info.st_mtime;
    return rtnVal;
}

//#import <appkit/Speaker.h>

#define  NEXT_SOUND 0
#define  DAI2400 1
#define  AD64x 2
#define  PROPORT 3
#define  GENERIC 4

static int soundOutType;
static id serialSoundOutDevice = nil;
static id SSAD64xDev = nil,StealthDAI2400Dev = nil,ProPortDev = nil;
static id SSAD64xPanel = nil,StealthDAI2400Panel = nil,NeXTDACPanel = nil;

/* Should figure a way to get rid of these case statements! */

static char *soundOutputTagToName[] = 
  /* These are the class names */
  {"","StealthDAI2400","SSAD64x","ArielProPort","DSPSerialPortDevice"};

-(int)_soundOutputNameToTag:(char *)s
{
    int tag = GENERIC;
    int i;
    for (i=1; i<GENERIC; i++) 
      if (!strcmp(s,soundOutputTagToName[i]))
	tag = i;
    [serialPortDeviceMatrix selectCellWithTag:tag];
    return tag;
}

-_setSoundOutDeviceTag:(int)aTag
{
    char *soundOutputName;
    warnedAboutSrate = NO;
    soundOutType = aTag;
    switch (aTag) {
      case PROPORT:
	if (!ProPortDev)
	  ProPortDev = serialSoundOutDevice = [[ArielProPort alloc] init];
	else serialSoundOutDevice = ProPortDev;
	soundOutputName = "Ariel ProPort";
	break;
      case DAI2400:
	if (!StealthDAI2400Dev)
	  StealthDAI2400Dev = serialSoundOutDevice = [[StealthDAI2400 alloc] init];
	else serialSoundOutDevice = StealthDAI2400Dev;
	soundOutputName = "Stealth DAI2400";
	break;
      case AD64x:
	if (!SSAD64xDev)
	  SSAD64xDev = serialSoundOutDevice = [[SSAD64x alloc] init];
	else serialSoundOutDevice = SSAD64xDev;
	soundOutputName = "Singular Solutions A/D64x";
	break;
      default:
      case GENERIC:
	soundOutputName = "Serial port sound";
	serialSoundOutDevice = nil;
	break;
      case NEXT_SOUND:
	soundOutputName = "NeXT Sound";
	serialSoundOutDevice = nil;
	break;
    }
    [serialPortDeviceNameField setStringValue:soundOutputName];
    /* Run alert panel here if we're playing? FIXME */
    return self;
}

-setSoundOutFrom:sender
  /* Invoked by U.I. */
{
    int tag = [[sender selectedCell] tag];
    if (soundOutType == tag)
      return self;
    if (tag == NEXT_SOUND && 
	(!([theOrch capabilities] & MK_hostSoundOut))) {
	NXRunAlertPanel(STR_SCOREPLAYER,
			"NeXT sound not supported on this architecture",
			STR_OK, NULL, NULL);
	[serialPortDeviceMatrix selectCellWithTag:soundOutType];
	return self;
    }
    return [self _setSoundOutDeviceTag:tag];
}

-saveAsDefaultDevice:sender
{
    unsigned caps = [theOrch capabilities];
    if (caps & MK_hostSoundOut)
      NXWriteDefault("MusicKit","OrchestraSoundOut",
		     (soundOutType == NEXT_SOUND) ? "Host" : "SSI");
    if (caps & MK_nextCompatibleDSPPort)
      if (soundOutType != NEXT_SOUND)
	NXWriteDefault("MusicKit","DSPSerialPortDevice0", 
		       soundOutputTagToName[soundOutType]);
    return self;
}

-deviceSpecificSettings:sender
{
    switch (soundOutType) {
      case DAI2400:
	if (!StealthDAI2400Panel) {
	    [NXApp loadNibSection:"StealthDAI2400.nib" owner:self withNames:YES];
	    StealthDAI2400Panel = NXGetNamedObject("StealthDAI2400Panel",self);
	}
	[StealthDAI2400Panel makeKeyAndOrderFront:self];
	break;
      case AD64x:
	if (!SSAD64xPanel) {
	    [NXApp loadNibSection:"SSAD64x.nib" owner:self withNames:YES];
	    SSAD64xPanel = NXGetNamedObject("SSAD64xPanel",self);
	}
	[SSAD64xPanel makeKeyAndOrderFront:self];
	break;
      case NEXT_SOUND:
	if (!NeXTDACPanel) {
	    [NXApp loadNibSection:"NextDACs.nib" owner:self withNames:YES];
	    NeXTDACPanel = NXGetNamedObject("NeXTDACPanel",self);
	}
	[NeXTDACPanel makeKeyAndOrderFront:self];
	break;
      default:
      case PROPORT:
      case GENERIC:
	NXRunAlertPanel(STR_SCOREPLAYER,"No special settings for this device",
			STR_OK, NULL, NULL);
	break;
    }
    return self;
}

-setAD64xConsumer:sender
{
    [SSAD64xDev setProfessional:NO];
    return self;
}

-setAD64xProfessional:sender
{
    [SSAD64xDev setProfessional:YES];
    return self;
}

-setDAI2400CopyProhibit:sender
{
    [StealthDAI2400Dev setCopyProhibit:[sender intValue]];
    return self;
}

-setDAI2400Emphasis:sender
{
    [StealthDAI2400Dev setEmphasis:[sender intValue]];
    return self;
}

-setNeXTDACVolume:sender
{
    [Sound setVolume:[sender doubleValue] :[sender doubleValue]];
    return self;
}

-setNeXTDACMute:sender
{
    [Sound setMute:[sender intValue]];
    return self;
}

-getNeXTDACCurrentValues:sender
{
    float l,r;
    [Sound getVolume:&l :&r];
    [NeXTDacVolumeSlider setFloatValue:l];
    [NeXTDacMuteSwitch setIntValue:[Sound isMuted]];
    return self;
}

-openEditFile:sender
{
    port_t	port;
    int		ok1 = 0;
    port = NXPortFromName("Edit",NULL);
    if (port == PORT_NULL)  /* No workspace -- impossible error, probably */
	return nil;
    [[NXApp appSpeaker] setSendPort: port];
    if (!fileName) {
	NXRunAlertPanel(STR_SCOREPLAYER,STR_NO_FILE_OPEN,STR_OK, NULL, NULL);
	return nil;
    }
    if ([[NXApp appSpeaker] openFile:fileName ok:&ok1] || !ok1) {
	NXRunAlertPanel(STR_SCOREPLAYER,STR_EDIT_CANT_OPEN_FILE,STR_OK, NULL, NULL);
	return nil;
    }
    return NXApp;
}

static id setFile(ScorePlayerController* self)
{
    id tuningSys;
    id scoreInfo;                                    
    MKSetScorefileParseErrorAbort(10);
    if ((!fileName) || (!strlen(fileName))) { /* Can this every happen? */ 
	[self->theMainWindow setTitle:STR_NO_FILE_OPEN];
	[self->editFileItem setEnabled:NO];
	[self->saveAsFileItem setEnabled:NO];
	return nil;
    }
    playScoreForm = (strstr(fileName,".playscore") != NULL);
    setFileTime();
    [self->editFileItem setEnabled:!playScoreForm];
    [self->saveAsFileItem setEnabled:YES];
    [scoreObj free];
    scoreObj = [Score new];
    sprintf(errMsg,STR_READING,shortFileName);
//    [theMainWindow makeKeyAndOrderFront:NXApp]; /* Probably not needed */
    [self->theMainWindow setTitle:errMsg];
    [self->theMainWindow display];
    [self->button setEnabled:NO];
    userCancelFileRead = NO;
    tuningSys = [[TuningSystem alloc] init]; /* 12-tone equal tempered */
    [tuningSys install];
    [tuningSys free];
    if (![scoreObj readScorefile:(char *)fileName] || 
	userCancelFileRead) 
      {  
	/* Error in file? */
	if (!userCancelFileRead) 
	    NXRunAlertPanel(STR_SCOREPLAYER,
			    STR_FIX_ERRORS,STR_OK,NULL,NULL);
	scoreObj = [scoreObj free];
	fileName[0] = '\0';
	[self->editFileItem setEnabled:NO];
	[self->saveAsFileItem setEnabled:NO];
	[self->theMainWindow setTitle:STR_SCOREPLAYER];
	[self->button setEnabled:YES];
	[self->theMainWindow display];
	return nil;
    }
    samplingRate = [theOrch defaultSamplingRate];
    headroom = .1;
    initialTempo = 60.0;
    [[condClass defaultConductor] setTempo:initialTempo];
    scoreInfo = [(MKScore *)scoreObj infoNote];
    if (scoreInfo) { /* Configure performance as specified in info. */ 
	int midiOffsetPar;
	midiOffset = 0;
	midiOffsetPar = [Note parName:"midiOffset"];
	if ([scoreInfo isParPresent:midiOffsetPar])
	    midiOffset = [scoreInfo parAsDouble:midiOffsetPar];
	if ([scoreInfo isParPresent:MK_headroom])
	  headroom = [scoreInfo parAsDouble:MK_headroom];	  
	if ([scoreInfo isParPresent:MK_alternativeSamplingRate] &&
	    [theOrch prefersAlternativeSamplingRate])
	  samplingRate = [scoreInfo parAsDouble:MK_alternativeSamplingRate];
	else if ([scoreInfo isParPresent:MK_samplingRate]) 
	  samplingRate = [scoreInfo parAsDouble:MK_samplingRate];
	if ([scoreInfo isParPresent:MK_tempo]) {
	    initialTempo = [scoreInfo parAsDouble:MK_tempo];
	    [[condClass defaultConductor] setTempo:initialTempo];
	} 
	if (soundOutType == NEXT_SOUND) {
#if SOUND_OUT_PAUSE_BUG
	    if (samplingRate == 22050)
	      midiOffset +=  .36363636363636/8.0;
	    else midiOffset += .181818181818181/8.0;
#else
	    if (samplingRate == 22050)
	      midiOffset +=  .36363636363636;
	    else midiOffset += .181818181818181;
#endif
	}
	/* Note: there is a .1 second indeterminacy (in the 22khz case) due 
	   to not knowing where we are in soundout buffering. Using more, 
	   but smaller buffers would solve this. */
    }
    lastTempo = desiredTempo = initialTempo;
    [self->tempoSlider setFloatValue:0.0];
    [self->tempoTextField setFloatValue:initialTempo];
    [self->theMainWindow setTitle:shortFileName];
    [self->theMainWindow display];
    [self->button setEnabled:YES];
    return NXApp;
}


-_enableMTCControls:(BOOL)yesOrNo
{
    [timeCodeButton setEnabled:yesOrNo];
    [timeCodePortMatrix setEnabled:yesOrNo];
    if (yesOrNo) 
      [timeCodeTextField setStringValue:(synchToTimeCode) ? 
       "Press Play, then start time code" : "Press button above to enable time code"];
    if (!synchToTimeCode)
      [timeCodeTextField setEnabled:yesOrNo];
    else [timeCodeTextField setEnabled:YES];
    return self;
}

static id setUpFile(char *workspaceFileName);

#import <mach/mach.h>
#import <mach/mach_error.h>
#import	<mach/message.h>

static port_t endOfTimePort = PORT_NULL;

-endOfTime	// called by the musickit thread
{
    int i;
    msg_header_t msg =    {0,                   /* msg_unused */
                           TRUE,                /* msg_simple */
			   sizeof(msg_header_t),/* msg_size */
			   MSG_TYPE_NORMAL,     /* msg_type */
			   0};                  /* Fills in remaining fields */
    [theOrch close]; /* This will block! */
    for (i=0; i<2; i++) {
	[midis[i] close];
	midis[i] = nil;
    }
    if (DSPCommands) {
	DSPCommands = NO;
	[theOrch setOutputCommandsFile:NULL];
    } else if (writeData) {
	writeData = NO;
	[theOrch setOutputSoundfile:NULL];
    }
    [theOrch setHostSoundOut:(soundOutType == NEXT_SOUND)];
    msg.msg_local_port = PORT_NULL;
    msg.msg_remote_port = endOfTimePort;
    msg_send(&msg, SEND_TIMEOUT, 0);
    return self;
}

static id tempoAnimator = nil;

void *endOfTimeProc(msg_header_t *msg,ScorePlayerController *myself )
{
    [tempoAnimator stopEntry];
    [myself->button setImage:playImage];
    [myself->button display];
    [myself->tooFastErrorMsg setTextGray:NX_LTGRAY];
    [myself->tooFastErrorMsg setBackgroundGray:NX_LTGRAY];
    if (errorDuringPlayback && ![errorLog isVisible])
	NXRunAlertPanel(STR_SCOREPLAYER,
			STR_ERRORS,
			STR_OK,NULL,NULL);
    messageFlashed = NO;
    isLate = NO;
    wasLate = NO;
    errorDuringPlayback = NO;
    [myself->theMainWindow setTitle:shortFileName];
    [myself->theMainWindow display];
    [myself->soundSavePanel close];
    [myself->dspCommandsSavePanel close];
    [myself _enableMTCControls:YES];
    return NXApp;
}

static BOOL isMidiClassName(char *className)
{
    return (className && ((strcmp(className,"midi") == 0)  ||
			  (strcmp(className,"midi1") == 0) ||
			  (strcmp(className,"midi0") == 0)));
}

#if SOUND_OUT_PAUSE_BUG

static BOOL checkForMidi(MKScore *obj)
{
    NSArray *subobjs;
    int i,cnt;
    id info;
    subobjs = [obj parts];
    if (!subobjs)
      return NO;
    cnt = [subobjs count];
    for (i=0; i<cnt; i++) {
	info = [(MKPart *)[subobjs objectAtIndex:i] infoNote];
	if ([info isParPresent:MK_synthPatch] &&
	    (isMidiClassName([info parAsStringNoCopy:MK_synthPatch]))) {
	    return YES;
	}
    }
    return NO;
}
#endif

static double tempoExponent = 1.5;

static double getTempo(float val)
    /* scales the initial tempo by the current slider value (-1,1) */
{
    val = pow(tempoExponent,val);
    return initialTempo * val;
}

static double getUntempo(float tempoVal)
    /* reverses above mapping */
{
    return log(tempoVal/initialTempo) / log(tempoExponent);
}

#define ANIMATE_DIFF_THRESHOLD 1.0
#define ANIMATE_INCREMENT 0.3

static id playIt(ScorePlayerController *self)
{
    int partCount,synthPatchCount,voices,i,whichMidi,midiChan;
    char *className;
    char *msg = NULL;
    double actualSrate;  
    NSArray *partPerformers;
    id synthPatchClass,partPerformer,partInfo,anIns,aPart;

    /* Could keep these around, in repeat-play cases: */ 
    scorePerformer = [scorePerformer free];
    [synthInstruments freeObjects];
    synthInstruments = [synthInstruments free];
    [self _enableMTCControls:NO];

    if (synchToTimeCode) {
	midis[timeCodePort] = [Midi newOnDevice:(timeCodePort) ? "midi1" : "midi0"];
	[[Conductor defaultConductor] setMTCSynch:midis[timeCodePort]];
    } else [[Conductor defaultConductor] setMTCSynch:nil];

    theOrch = [Orchestra newOnDSP:0]; /* A noop if it exists */

    [theOrch setHeadroom:headroom];    /* Must be reset for each play */ 
    if (serialSoundOutDevice)
      [theOrch setSerialPortDevice:serialSoundOutDevice];
    switch (soundOutType) {
      case NEXT_SOUND:
	if (![theOrch supportsSamplingRate:samplingRate]) {
	    msg = (char *)STR_BAD_SRATE;
	    actualSrate = [theOrch defaultSamplingRate];
	}
	else actualSrate = samplingRate;
	break;
      case GENERIC:
	actualSrate = samplingRate;
	break;
      default:
      case PROPORT:
      case AD64x:
      case DAI2400:
	if (![theOrch supportsSamplingRate:samplingRate]){
	    msg = (char *)STR_BAD_SSI_SRATE;
	    actualSrate = [theOrch defaultSamplingRate];
	}
	else actualSrate = samplingRate;
	break;
    }
    if (msg && !warnedAboutSrate) {	
	[errorLog addText:msg];
	warnedAboutSrate = YES;
	NXRunAlertPanel(STR_SCOREPLAYER,msg,STR_OK,NULL,NULL);
    }
    [theOrch setSamplingRate:actualSrate];

    #if SOUND_OUT_PAUSE_BUG
    if (checkForMidi(scoreObj))
	[theOrch setFastResponse:YES];
    else [theOrch setFastResponse:NO];
    #endif
    [theOrch setOutputCommandsFile:(DSPCommands)?outputFilePath:NULL];
    [theOrch setOutputSoundfile:(writeData)?outputFilePath:NULL];
    [theOrch setHostSoundOut:!writeData && (soundOutType == NEXT_SOUND)];
    [theOrch setSerialSoundOut:(soundOutType != NEXT_SOUND) && !writeData];

    if (![theOrch open]) {
	char *msg = (char *)STR_CANT_OPEN_DSP;
	[errorLog addText:msg];
	NXRunAlertPanel(STR_SCOREPLAYER,msg,STR_OK,NULL,NULL);
	return nil;
    }
    scorePerformer = [MKScorePerformer new];
    [scorePerformer setScore:scoreObj];
    [(MKScorePerformer *)scorePerformer activate]; 
    partPerformers = [scorePerformer partPerformers];
    partCount = [partPerformers count];
    synthInstruments = [List new];
    for (i = 0; i < partCount; i++) {
	partPerformer = [partPerformers objectAtIndex:i];
	aPart = [partPerformer part]; 
	partInfo = [(MKPart *)aPart infoNote];      
	if ((!partInfo) || ![partInfo isParPresent:MK_synthPatch]) {
	    sprintf(errMsg,STR_INFO_MISSING,
		    (char *)MKGetObjectName(aPart));
	    [errorLog addText:errMsg];
#if 0
	    if (!NXRunAlertPanel(STR_SCOREPLAYER,errMsg,STR_CONTINUE,
				 STR_CANCEL,NULL)) 
	      return nil;
#endif
	    continue;
	}		
	className = [partInfo parAsStringNoCopy:MK_synthPatch];
	if (isMidiClassName(className)) {
	    midiChan = [partInfo parAsInt:MK_midiChan];
	    if ((midiChan == MAXINT) || (midiChan > 16))
		midiChan = 0;
	    if (strcmp(className,"midi") == 0)
		className = "midi0"; /* Was "midi1" -- changed 9/30/94 */
	    if (strcmp(className,"midi1") == 0) 
		whichMidi = 1;
	    else whichMidi = 0;
	    if (midis[whichMidi] == nil)
		midis[whichMidi] = [Midi newOnDevice:className];
	    [[partPerformer noteSender] connect:
	     [midis[whichMidi] channelNoteReceiver:midiChan]];
	}
	else {
	    synthPatchClass = (strlen(className) ? 
			       [SynthPatch findSynthPatchClass:className] : nil);
	    if (!synthPatchClass) {         /* Class not loaded in program? */ 
		sprintf(errMsg,STR_NO_SYNTHPATCH,className);
		[errorLog addText:errMsg];
		if (!NXRunAlertPanel(STR_SCOREPLAYER,errMsg,STR_CONTINUE,
				     STR_CANCEL, NULL))
		    return nil;
		/* We would prefer to do dynamic loading here. */
		continue;
	    }
	    anIns = [SynthInstrument new];      
	    [synthInstruments addObject:anIns];
	    [[partPerformer noteSender] connect:[anIns noteReceiver]];
	    [anIns setSynthPatchClass:synthPatchClass];
	    if (![partInfo isParPresent:MK_synthPatchCount])
		continue;         
	    voices = [partInfo parAsInt:MK_synthPatchCount];
	    synthPatchCount = 
		[anIns setSynthPatchCount:voices patchTemplate:
		 [synthPatchClass patchTemplateFor:partInfo]];
	    if (synthPatchCount < voices) {
		sprintf(errMsg,STR_TOO_MANY_SYNTHPATCHES,
			synthPatchCount,voices,className,
			MKGetObjectName(aPart));
		[errorLog addText:errMsg];
		if (!NXRunAlertPanel(STR_SCOREPLAYER,errMsg,STR_CONTINUE,
				     STR_CANCEL, NULL))
		    return nil;
	    }
	}
    }
    [partPerformers free];
    errorDuringPlayback = NO;
    sprintf(errMsg,STR_PLAYING,shortFileName);
    [self->theMainWindow setTitle:errMsg];
    [self->theMainWindow display];
    MKSetDeltaT(.75);
    [Orchestra setTimed:YES];
    [condClass afterPerformanceSel:@selector(endOfTime) to:NXApp argCount:0];
    [self->button setImage:stopImage];
    [self->button display];
    if (synchToTimeCode)
      [self showConductorDidPause];
    if (writeData)
	[self->soundSavePanel orderFront:self];
    else if (DSPCommands)
	[self->dspCommandsSavePanel orderFront:self];
    [[tempoAnimator setIncrement:ANIMATE_INCREMENT] startEntry];
    for (i=0; i<2; i++) 
      if (midis[i] && ![midis[i] openOutputOnly]) /* midis[i] is nil if not in use */
	mkRunAlertPanel(STR_SCOREPLAYER_ERROR,STR_CANT_OPEN_MIDI,STR_OK,STR_CANCEL,NULL);
    for (i=0; i<2; i++) 
        if (midiOffset > 0) 
	    [midis[i] setLocalDeltaT:midiOffset];
	else if (midiOffset < 0)
	    [theOrch setLocalDeltaT:-midiOffset];
    for (i=0; i<2; i++) 
	[midis[i] run];
    [theOrch run];
    [condClass startPerformance];     
    return NXApp;
}

-setTempoAdjustment:sender
{
    [Conductor setDelegate:([[sender selectedCell] tag] == 0) ? NXApp : nil];
    return self;
}

static char *copyStr(char *oldPtr,char *strToCopy)
{
    char *rtnVal;
    if (oldPtr)
      free(oldPtr);
    if (!strToCopy)
      return NULL;
    NX_MALLOC(rtnVal,char,strlen(strToCopy)+1);
    strcpy(rtnVal,strToCopy);
    return rtnVal;
}

extern void _MKSetConductorThreadMaxStress(int arg);

static id LocalImage(char *s)
{
    char buf[MAXPATHLEN + 1];
    [[NXBundle mainBundle] getPath:buf forResource:s ofType:"tiff"]; 
    return [[NXImage alloc] initFromFile:buf];
}

+initialize
{
    static NXDefaultsVector ScorePlayerDefaults = {
	{"Sound output", "NeXT sound"},
	{NULL}
    };
    NXRegisterDefaults("ScorePlayer", ScorePlayerDefaults);
    return self;
}

static void abortNow();

- orchestraDidAbort:whichOrch
  /* This is received by the appkit thread */
{
    NXRunAlertPanel(STR_SCOREPLAYER,STR_HUNG_DSP,NULL,NULL,NULL);
    abortNow();
    return self;
}

- appWillInit:sender
{
    char *s;
    static int inited = 0;
    int ec;
    if (inited++)
      return NXApp;
    playImage = LocalImage("play.tiff");
    [button setImage:playImage];
    [button display];
    errorLog = [[ErrorLog alloc] init];
    condClass = [Conductor class];
    [condClass setThreadPriority:1.0];
    [PartPerformer setFastActivation:YES]; /* We're not modifying parts while playing */
    setuid(getuid()); /* Must be after setThreadPriority. */
    [condClass useSeparateThread:YES];
//    [condClass setDelegate:NXApp]; /* Default is no tempo adjustment */
    [[Conductor defaultConductor] setDelegate:self];
    /* These numbers could be endlessly tweaked */
    MKSetLowDeltaTThreshold(.25);
    MKSetHighDeltaTThreshold(.4);
//    _MKSetConductorThreadMaxStress(1000000); /* Don't do cthread_yields */
    ec = port_allocate(task_self(), &endOfTimePort);
    DPSAddPort(endOfTimePort,(DPSPortProc)endOfTimeProc,
	       sizeof(msg_header_t),(void *)self,30);
    MKSetErrorProc(handleMKError);
    objc_setClassHandler(handleObjcError);
   
    /* Create the tempo aminmator, but don't start it yet */
    tempoAnimator = [Animator newChronon: 0.0
	                   adaptation: 0.0				
		           target:     self
		           action:     @selector(animateTempo:)
		           autoStart:  NO
		           eventMask:  NX_ALLEVENTS];
	
	/* set up the button */			   
	
    stopImage = LocalImage("stop.tiff");
    playHImage = LocalImage("playH.tiff");
    [button setAltImage:playHImage];
	    
    [Orchestra setAbortNotification:self]; 
    theOrch = [Orchestra new];
    capabilities = [theOrch capabilities];
    if (capabilities & MK_hostSoundOut) {
	s = (char *)NXGetDefaultValue("MusicKit", "OrchestraSoundOut");
	if (!strcmp(s,"Host")) {
	    [self _setSoundOutDeviceTag:NEXT_SOUND];
	}
	else {
	    s = (char *)NXGetDefaultValue("MusicKit", "DSPSerialPortDevice0");
	    [self _setSoundOutDeviceTag:[self _soundOutputNameToTag:s]];
	}
    } else {
	if ((capabilities & MK_nextCompatibleDSPPort)) {
	    s = (char *)NXGetDefaultValue("MusicKit", "DSPSerialPortDevice0");
	    [self _setSoundOutDeviceTag:[self _soundOutputNameToTag:s]];
	}
	else {
	    [self _setSoundOutDeviceTag:GENERIC];
	    [serialPortDeviceMatrix selectCellWithTag:GENERIC];
	    [serialPortDeviceMatrix setEnabled:NO];
	}
    }
    return self;
}


char *getShortFileName(char *fName)
{
    char *tmp;
    tmp = strrchr(fName,'/');
    if (tmp) {
	dir = copyStr(dir,fName);
	dir[tmp - fName] = '\0'; 
	tmp++; /* Increment over the '/' */
    }
    else {
	if (dir)
	  free(dir);
	dir = NULL;
    }
    return (tmp) ? tmp : fName;
}

static id setUpFile(char *workspaceFileName)
{
    int success;
    static BOOL firstTime = YES;
    if (!openPanel)
        openPanel = [OpenPanel new];    
    if (!workspaceFileName) {
	if (firstTime)
	  success = [openPanel 
		   runModalForDirectory:"/LocalLibrary/Music/Scores"
		   file:"Examp1.score" 
		   types:(const char *const *)fileSuffixes]; 
	else if (dir) {
	    success = [openPanel 
		     runModalForDirectory:dir
		     file:shortFileName 
		     types:(const char *const *)fileSuffixes]; 
	    free(dir);
	    dir = NULL;
	}
	else 
	  success = [openPanel 
		   runModalForTypes:(const char *const *)fileSuffixes];
	if (!success)
	  return nil;
	fileName = copyStr(fileName,
				 (char *)[openPanel filename]);
	shortFileName = copyStr(shortFileName,
				      (char *)*[openPanel filenames]);
    }
    else {
	fileName = copyStr(fileName,workspaceFileName);
	shortFileName = copyStr(shortFileName,
				      getShortFileName(workspaceFileName));
    }
    if  ( (strcmp(shortFileName,"Jungle.score") == 0) ||
	  (strcmp(shortFileName,"Jungle.playscore") == 0)
	 )
      tempoExponent = 1.3;  /* A real hack to make the demos play ok. */
    else tempoExponent = 1.5;
    firstTime = NO;
    return NXApp;
}

static void abortNow()
{
    int i;
    if (PLAYING) {
	[condClass lockPerformance];
	for (i=0; i<2; i++) 
	  if (midis[i]) {
	      [midis[i] allNotesOff];
	      [midis[i] abort];
	  }
	[theOrch abort];
	[condClass finishPerformance];
	[condClass unlockPerformance];
	cthread_yield();
	while (PLAYING) /* Make sure it's really done. */
	  usleep(1000);
    }
}

- selectFile:sender
{
    abortNow(); /* Could move this to after setUpFile() */
    if (!setUpFile(NULL)) {
      return NXApp;
    }
    setFile(self);
    return NXApp;
}

- (BOOL) appAcceptsAnotherFile : sender {
    return YES;
}

- (BOOL)appOpenFile: (char *)filename type:(char *)aType {
    if (aType)
      if ((strcmp(aType,"score") != 0) &&
	  (strcmp(aType,"playscore") != 0))
	return NO;
    setUpFile(filename);
    abortNow();
    setFile(self);
    return YES;
}


- playStop:sender
{
    if ((!fileName) || (!strlen(fileName)))
      [NXApp selectFile:NXApp];
    if ((!fileName) || (!strlen(fileName))) 
      return NXApp;
    if (PLAYING)
      abortNow();
    else {
	int i = needToReread();
	if (i == NX_ALERTDEFAULT) {
	    setFile(self);
	    playIt(self);
	}
	else if (i == NX_ALERTALTERNATE)
	  playIt(self);
    }
    return NXApp;
}

- setTooFastErrorMsg:obj
{
    tooFastErrorMsg = obj;
    return self;
}

#define INITIAL_SLOWDOWN_FACTOR .9
#define SUBSEQUENT_SLOWDOWN_FACTOR .925

static void adjustTempo(double slowDown)
{
    double d = lastTempo * slowDown;
    if (d < desiredTempo) /* User may have just set slider lower than this. */
      desiredTempo = d;
}

#define PROTECT_PAGING_TIME 1.5

- conductorCrossedLowDeltaTThreshold
{
    if (MKGetTime() < PROTECT_PAGING_TIME)
      return self;
    adjustTempo(INITIAL_SLOWDOWN_FACTOR);
    [[condClass defaultConductor] setTempo:desiredTempo];
    isLate = YES;
    return self;
}

- conductorCrossedHighDeltaTThreshold
{
    if (isLate)  /* If early time test failed, this won't be true. */
      wasLate = YES;
    isLate = NO;
    return self;
}

- animateTempo:sender
{
    double diff;
    BOOL forceAdjustment;
    if (forceAdjustment = isLate) 
      adjustTempo(SUBSEQUENT_SLOWDOWN_FACTOR);
    if ((isLate || wasLate) && !messageFlashed) {
	[tooFastErrorMsg setTextGray:NX_BLACK];
	[tooFastErrorMsg setBackgroundGray:NX_LTGRAY];
	messageFlashed = YES;
    } else if (!isLate && messageFlashed) {
	[tooFastErrorMsg setTextGray:NX_LTGRAY];
	[tooFastErrorMsg setBackgroundGray:NX_LTGRAY];
	messageFlashed = NO;
	wasLate = NO;
    }
    diff = lastTempo - desiredTempo;
    if (diff < 0.0)  /* Abs value */
      diff = -diff;
    if (!forceAdjustment && diff < ANIMATE_DIFF_THRESHOLD) /* diff too small */
      return self;
    [condClass lockPerformance];
    [[condClass defaultConductor] setTempo:desiredTempo];
    [condClass unlockPerformance];
    [tempoTextField setFloatValue:desiredTempo];
    if (wasLate || isLate)
       [tempoSlider setFloatValue:getUntempo(desiredTempo)];
    lastTempo = desiredTempo;
    return self;
}

- setTempoFrom:sender	// currently called by slider only
{
    double val = ([sender doubleValue]);
    desiredTempo = getTempo(val);
    if (!PLAYING) {
	[[condClass defaultConductor] setTempo:desiredTempo];
	[tempoTextField setFloatValue:desiredTempo];
	lastTempo = desiredTempo;
    }
    return NXApp;
}

- setTimeCodeSynch:sender
{
    synchToTimeCode = [sender intValue];
    [timeCodeTextField setStringValue:(synchToTimeCode) ? 
     "Press Play, then start time code" : "Press button above to enable time code"];
    return self;
}

- setTimeCodeSerialPort:sender
{
    /* 0 for portA, 1 for portB */
    timeCodePort = [[sender selectedCell] tag];
    return self;
}


- conductorWillSeek:sender
{
    [Conductor sendMsgToApplicationThreadSel:@selector(showConductorWillSeek)
     to:self argCount:0];
    return self;
}

- conductorDidSeek:sender
{
    [Conductor sendMsgToApplicationThreadSel:@selector(showConductorDidSeek)
     to:self argCount:0];
    return self;
}

- conductorDidReverse:sender
{
    [Conductor sendMsgToApplicationThreadSel:@selector(showConductorDidReverse)
     to:self argCount:0];
    return self;
}

- conductorDidPause:sender
{
    int i;
    [Conductor sendMsgToApplicationThreadSel:@selector(showConductorDidPause)
     to:self argCount:0];
    [synthInstruments makeObjectsPerform:@selector(allNotesOff)];
    for (i=0; i<2; i++) 
      [midis[i] allNotesOff];
    return self;
}

- conductorDidResume:sender
{
    [Conductor sendMsgToApplicationThreadSel:@selector(showConductorDidResume)
     to:self argCount:0];
    return self;
}

-terminate:sender
{
    abortNow();
    [super terminate:sender];
    return NXApp;
}


/* The following added based on Ensemble's version of the same. */
/* Scores can be saved as Scorefiles, Midi files, or DSPCommands files */

static enum _saveType {NO_TYPE = -1, SAVE_SCORE, SAVE_PLAYSCORE, SAVE_MIDI, SAVE_COMMANDS, SAVE_SOUND} saveType = NO_TYPE;
static char* fileIcons[] = {"ScorePlayerDoc", "ScorePlayerDoc2", "Midi", "Sound", "Sound"};
static char* fileTypes[5];
static char* fileExtensions[] = {"score", "playscore","midi", "snd", "snd"};

static id accessoryView = nil;
static id savePanel = nil;
char *soundFile = NULL;

BOOL getSavePath(char *returnBuf, char *dir, char *name, char const *theType)
     /* Set up and run the Save panel for the given type.  The accessory view
      * is a button which allows the type to be changed when saving scores.
      */
{
    BOOL flag;

    if (!savePanel) {
	savePanel = [SavePanel new];
	[savePanel setTitle:"ScorePlayer Save"];
	[accessoryView setIconPosition:NX_ICONABOVE];
	[accessoryView setTarget:NXApp];
	[accessoryView setAction:@selector(changeSaveType:)];
	[accessoryView sizeTo:124:68];
    }
    [savePanel setAccessoryView:accessoryView];
    if (theType && *theType)
	[savePanel setRequiredFileType:theType];
    [NXApp setAutoupdate:NO];
    flag = [savePanel runModalForDirectory:dir file:name];
    if (flag) strcpy(returnBuf,[savePanel filename]);
    soundFile = (saveType==SAVE_SOUND)?returnBuf:NULL;
    [NXApp setAutoupdate:YES];

    return flag;
}

void parsePath(char *path, char *dir, char *name)
     /* Parse out the name and directory given a path */
{
    char *c1, *c2;
    int dirlen, namelen;

    c1 = strrchr(path, '.');
    c2 = strrchr(path, '/');
    dirlen = (c2) ? c2-path+1 : 0;
    namelen = ((c1) ? c1-path : strlen(path)) -dirlen;
    strncpy(dir,path,dirlen);
    dir[dirlen] = '\0';
    strncpy(name, path+dirlen, namelen);
    name[namelen] = '\0';
}

static int fileType(char *name)
     /* return the file type for the specified name */
{
    char *ext;
    ext = strrchr(name, '.');
    if (!strcmp(ext,".midi"))
	return SAVE_MIDI;
    else if (!strcmp(ext,".playscore"))
        return SAVE_PLAYSCORE;
    else if (!strcmp(ext,".snd"))
      return (soundFile)?SAVE_SOUND:SAVE_COMMANDS;
    return SAVE_SCORE;
}

void getPath(char *path, char *dir, char *name, char *ext)
     /* Construct a path given a file name, directory, and type */
{
    strcpy(path,(strlen(dir))?dir:NXHomeDirectory());
    if (path[strlen(path)-1] != '/')
	strcat(path,"/");
    if (strlen(name)) {
	strcat(path,name);
	if (ext) {
	    if (ext[0] != '.')
		strcat(path,".");
	    strcat(path,ext);
	}
    }
}

- setSaveType:(int)type
    /* Set the Save panel accessory view icon and label according to type. */
{
    saveType = type;
    if (!accessoryView) {
	accessoryView = [[Button alloc] init];
	fileTypes[0] = (char *)STR_SCOREFILE;
	fileTypes[1] = (char *)STR_PLAYSCOREFILE;
	fileTypes[2] = (char *)STR_MIDIFILE;
	fileTypes[3] = (char *)STR_DSPFILE;
	fileTypes[4] = (char *)STR_SOUNDFILE;
    }
    [accessoryView setIcon:fileIcons[type]];
    [accessoryView setTitle:fileTypes[type]];
    [savePanel setRequiredFileType:fileExtensions[type]];
    return self;
}

- changeSaveType:sender
    /* Called by the accessory view (the Type button on the Save Panel */
{
    saveType++;
    if (saveType == SAVE_SOUND && (!(capabilities & MK_soundfileOut)))
      saveType++;
    if (saveType > SAVE_SOUND) saveType = SAVE_SCORE; /* Wrap */
    [self setSaveType:saveType];
    return self;
}

- saveScoreAs:sender
    /* Save the score, always prompting for a file name first.
       This is what the SaveAs: menu item calls. */
{
    if (PLAYING)
      abortNow();
    if (saveType==-1) 
	[self setSaveType:SAVE_SCORE];
    if (!getSavePath(outputFilePath,outputFileDir, outputFileName, 
		     fileExtensions[saveType]))
	return self;
    parsePath(outputFilePath, outputFileDir, outputFileName);
    [self setSaveType:fileType(outputFilePath)];
    getPath(outputFilePath, outputFileDir, outputFileName,
	    fileExtensions[saveType]);
    switch (saveType) {
      case SAVE_SCORE: 
	[scoreObj writeScorefile:outputFilePath];
	break;
      case SAVE_PLAYSCORE: 
	[scoreObj writeOptimizedScorefile:outputFilePath];
	break;
      case SAVE_MIDI:
	[scoreObj writeMidifile:outputFilePath];
	break;
      case SAVE_COMMANDS:
	/* Here we play the score, capturing the performance in the
	 * DSPCommands file.
	 */
	DSPCommands = YES;
	[button performClick:self];
	break;
      case SAVE_SOUND:
	/* Here we play the score, capturing the performance in the
	 * sound file.
	 */
	writeData = YES;
	[button performClick:self];
	break;
      default:
	break;
    }
    [NXArrow set];
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
		NXRunAlertPanel(STR_SCOREPLAYER, STR_EDIT_CANT_OPEN_FILE, NULL, 
				NULL, NULL);
	NX_FREE(helpfile);
	return self;
}

-pause:sender
{
    [MKConductor lockPerformance];
    [[MKConductor defaultConductor] pause];
    [MKConductor unlockPerformance];
    return self;
}

-resume:sender
{
    [MKConductor lockPerformance];
    [[MKonductor defaultConductor] resume];
    [MKConductor unlockPerformance];
    return self;
}

@end

