/*
  $Id$  

  Description:
    This is NOT a good programming example.  It is full of special-purpose
    hacks, some of which have only historical significance.  Please see
    MusicKit/Examples for good examples of how to use the Music Kit.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Addition of timecode and Intel support copyright David A. Jaffe, 1992
  Portions Copyright (c) 1999-2000 The MusicKit Project
*/
/*
Modification history:

  $Log$
  Revision 1.7  2001/02/06 20:23:04  leigh
  Retained MKMidi instances which were preventing second play of score\
  Now using a single sound saving panel and updating the message

  Revision 1.6  2001/02/06 02:28:31  leigh
  Removed unnecessary retains, fixed rereading files, replacing the prompt with a log message

  Revision 1.5  2000/12/15 02:01:19  leigh
  Initial Revision

  Revision 1.4  2000/11/28 23:10:38  leigh
  Removed dependency on Edit.app and OpenStep directory structure

  Revision 1.3  2000/10/22 18:21:59  leigh
  added SB's OpenStep conversions

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
#import <Foundation/NSBundle.h>
#import <MusicKit/MusicKit.h>

@implementation ScorePlayerController

#define MAX_MIDIS 2

static BOOL playScoreForm;
static NSMutableArray *synthInstruments;
static id openPanel;
static NSString *fileName, *shortFileName;
static MKScore *scoreObj;
static MKScorePerformer *scorePerformer;
static MKOrchestra *theOrch;
static double headroom = .1;
static BOOL userCancelFileRead = NO;
static NSString *errMsg;
static double initialTempo = 60.0;
static double lastTempo = 60.0;
static double desiredTempo = 60.0;
static NSArray *fileSuffixes;
static NSString *dir = nil;
#define condClass MKConductor
static BOOL messageFlashed = NO;
static BOOL isLate = NO;
static BOOL wasLate = NO;
static id stopImage,playImage,playHImage;
static MKMidi *midis[MAX_MIDIS] = {nil, nil};
static int midiOffset;
static BOOL synchToTimeCode = NO;
static int timeCodePort = 0;
static unsigned capabilities;
static double samplingRate;
static id mySelf;
static id tempoAnimator = nil;

static NSString *outputFilePath; /* Complete output file path */
static NSString *outputFileDir;	 /* Just the directory */
static NSString *outputFileName; /* Just the name */


static BOOL DSPCommands = NO;
static BOOL writeData = NO;


/* The following added based on Ensemble's version of the same. */
/* Scores can be saved as Scorefiles, Midi files, or DSPCommands files */

static enum _saveType {NO_TYPE = -1, SAVE_SCORE, SAVE_PLAYSCORE, SAVE_MIDI, SAVE_COMMANDS, SAVE_SOUND} saveType = NO_TYPE;
static NSArray* fileIcons;
static NSArray* fileTypes;
static NSArray* fileExtensions;

static NSButton *accessoryView = nil;
static id savePanel = nil;
static NSString *soundFile = nil;


#define PLAYING ([condClass inPerformance])
#if m68k
#define SOUND_OUT_PAUSE_BUG 1 /* Workaround for problem synching MIDI to DSP */
#endif

// LMS disabled, the console is good enough for us to see ObjectiveC errors.
// static int handleObjcError(const char *className)
//{
//    return 0;
//}

static id errorLog;
static BOOL errorDuringPlayback = NO;

- showConductorDidSeek
{
    [timeCodeTextField setStringValue:@"Time code running"];
    return self;
}

- showConductorWillSeek
{
    [timeCodeTextField setStringValue:@"Time code starting..."];
    return self;
}
 
- showConductorDidReverse
{
     [timeCodeTextField setStringValue:@"Time code running backwards"];
     return self;
}
 
- showConductorDidPause
{
    [timeCodeTextField setStringValue:@"Time code stopped.  Waiting for time code to start"];
    return self;
}

- showConductorDidResume
{
    [timeCodeTextField setStringValue:@"Time code running"];
    return self;
}

- (void)showErrorLog:sender
{
    [errorLog show]; 
}

-runAlert:(NSString *)text
{
    [errorLog addText:text];
    [text release];
    errorDuringPlayback = YES;
    return self;
}

static int warnedAboutSrate = NO;

/* Localizable strings */
#define MB [NSBundle mainBundle]

#define STR_SCOREPLAYER NSLocalizedStringFromTableInBundle(@"ScorePlayer", @"ScorePlayer", MB, "Name of program")

#define STR_SCOREPLAYER_ERROR NSLocalizedStringFromTableInBundle(@"ScorePlayer Error", @"ScorePlayer", MB, "ScorePlayer error alert panel name.")

#define STR_OK NSLocalizedStringFromTableInBundle(@"OK", @"ScorePlayer", MB, "OK button name")

#define STR_CANCEL NSLocalizedStringFromTableInBundle(@"Cancel", @"ScorePlayer", MB, "Cancel button name")

#define STR_FILE_CHANGED NSLocalizedStringFromTableInBundle(@"File has changed. Reread it?", @"ScorePlayer", MB, "This message appears when the user attempts to play a file, but that file has changed.")

#define STR_YES NSLocalizedStringFromTableInBundle(@"Yes", @"ScorePlayer", MB, "Yes button name")

#define STR_NO NSLocalizedStringFromTableInBundle(@"No", @"ScorePlayer", MB, "No button name")

#define STR_NO_FILE_OPEN NSLocalizedStringFromTableInBundle(@"No file open.", @"ScorePlayer", MB, "This message appears when the user asks to edit a file but no file is open. Also used as title of main window when no file is open.")

#define STR_NO_SETTINGS NSLocalizedStringFromTableInBundle(@"The selected device has no user-settable settings.", @"ScorePlayer", MB, "This message appears when the user asks to set settings of a sound out device for which there is no settings panel.")

#define STR_EDIT_CANT_OPEN_FILE NSLocalizedStringFromTableInBundle(@"Can't open file for editing.", @"ScorePlayer", MB, "This message appears if the user tries to edit a file but that file can't be opened.")

#define STR_READING NSLocalizedStringFromTableInBundle(@"Reading %@...", @"ScorePlayer", MB, "This message appears when a file is being read.  It takes one argument which follows the message. E.g. 'Reading x.score...'")

#define STR_HUNG_DSP NSLocalizedStringFromTableInBundle(@"No response from DSP--aborting", @"ScorePlayer", MB, "Hung DSP msg")

#define STR_FIX_ERRORS NSLocalizedStringFromTableInBundle(@"Fix scorefile errors and try again.", @"ScorePlayer", MB, "This message appears after the user aborts a scorefile parse due to errors.")

#define STR_BAD_SRATE NSLocalizedStringFromTableInBundle(@"Sampling rate must be 44100 or 22050 for the NeXT DACs--using default of 22050.", @"ScorePlayer", MB, "This message appears if the scorefile specifies an illegal sampling rate.")

#define STR_BAD_SSI_SRATE NSLocalizedStringFromTableInBundle(@"Requested sampling rate not supported by the specified serial port device.", @"ScorePlayer", MB, "This message appears if the scorefile specifies an illegal sampling rate for SSI device.")

#define STR_ERRORS NSLocalizedStringFromTableInBundle(@"There were errors during playback.\nClick the \"Show Errors\" menu item to view them.", @"ScorePlayer", MB, "This message appears after a file is played if errors occurred during playback")

#define STR_CANT_OPEN_DSP NSLocalizedStringFromTableInBundle(@"Can't open DSP. Perhaps another application has it.", @"ScorePlayer", MB, "This message appears if the DSP is busy.")

#define STR_INFO_MISSING NSLocalizedStringFromTableInBundle(@"%@ info missing.", @"ScorePlayer", MB, "This message takes one leading argument, the name of a scorefile part.  It appears when a part is declared with no info.")

#define STR_NO_SYNTHPATCH NSLocalizedStringFromTableInBundle(@"This scorefile calls for a synthesis instrument (%@) that isn't available in this application.", @"ScorePlayer", MB, "This message appears if a SynthPatch is specified in the scorefile for which no SynthPatch can be found.  Its one argument is the name of the SynthPatch.")

#define STR_CONTINUE NSLocalizedStringFromTableInBundle(@"Continue", @"ScorePlayer", MB, "Continue button name")

#define STR_PLAYING NSLocalizedStringFromTableInBundle(@"Playing %@...", @"ScorePlayer", MB, "This message appears when a file is being played.  The trailing argument is the name of the file.")

#define STR_TOO_MANY_SYNTHPATCHES NSLocalizedStringFromTableInBundle(@"Could only allocate %d instead of %d %@s for %@", @"ScorePlayer", MB, "This message apepars when too many Synthpatches are requested in the scorefile for a given part. There are four arguments, which must appear in the following order: 1 = the number of patches that could be allocated, 2 = number of patches that were requested to be allocated, 3 = the name of the synthpatch specified in the scorefile and 4 = the part name")

#define STR_SCOREFILE NSLocalizedStringFromTableInBundle(@"Score File", @"ScorePlayer", MB, "This appears in the SaveAs... panel")

#define STR_PLAYSCOREFILE NSLocalizedStringFromTableInBundle(@"Playscore File", @"ScorePlayer", MB, "This appears in the SaveAs... panel")

#define STR_MIDIFILE NSLocalizedStringFromTableInBundle(@"MIDI File", @"ScorePlayer", MB, "This appears in the SaveAs... panel")

#define STR_DSPFILE NSLocalizedStringFromTableInBundle(@"DSPCommands File", @"ScorePlayer", MB, "This appears in the SaveAs... panel")

#define STR_SOUNDFILE NSLocalizedStringFromTableInBundle(@"Sound File", @"ScorePlayer", MB, "This appears in the SaveAs... panel")

#define STR_CANT_OPEN_MIDI NSLocalizedStringFromTableInBundle(@"Can't open MIDI driver port for MIDI. Perhaps another application has it.", @"ScorePlayer", MB, "This message appears if the serial port is busy.")

static void handleMKError(NSString *msg)
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
        [MKConductor sendMsgToApplicationThreadSel:@selector(runAlert:) to:mySelf
         argCount:1, [msg copy]];
    }
}

static NSDate *lastModifyTime;

static void setFileTime(void)
{
    NSDictionary *fattrs;
    if (playScoreForm)
      return;
    fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName
                                                     traverseLink:YES];
    lastModifyTime = [[fattrs objectForKey:NSFileModificationDate] retain];
}

// Return YES if we should re-read the score file.
static BOOL needToReread(void)
{
    NSDictionary *fattrs;
    NSDate *fileModifyTime;
    BOOL reread;
    
    if (playScoreForm)
        return NO;
    fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:fileName
                                                     traverseLink:YES];
    fileModifyTime = [fattrs objectForKey: NSFileModificationDate];
    reread = ([fileModifyTime compare: lastModifyTime] == NSOrderedDescending);
    [lastModifyTime release];
    lastModifyTime = [fileModifyTime retain];
    return reread;
}

#define  NEXT_SOUND 0
#define  DAI2400 1
#define  AD64x 2
#define  PROPORT 3
#define  GENERIC 4

static int soundOutType;
static id serialSoundOutDevice = nil;
static id SSAD64xDev = nil,StealthDAI2400Dev = nil,ProPortDev = nil;
//static id SSAD64xPanel = nil,StealthDAI2400Panel = nil,NeXTDACPanel = nil;

/* Should figure a way to get rid of these case statements! */

static NSArray *soundOutputTagToName;

-(int)_soundOutputNameToTag:(NSString *)s
{
    int tag = GENERIC;
    int i;
    for (i=1; i<GENERIC; i++)
        if ([[soundOutputTagToName objectAtIndex:i] isEqualToString:s])
            tag = i;
    [serialPortDeviceMatrix selectCellWithTag:tag];
    return tag;
}

- (void)_setSoundOutDeviceTag:(int)aTag
{
    NSString *soundOutputName;
    warnedAboutSrate = NO;
    soundOutType = aTag;
    switch (aTag) {
      case PROPORT:
	if (!ProPortDev)
	  ProPortDev = serialSoundOutDevice = [[ArielProPort alloc] init];
	else serialSoundOutDevice = ProPortDev;
	soundOutputName = @"Ariel ProPort";
	break;
      case DAI2400:
	if (!StealthDAI2400Dev)
	  StealthDAI2400Dev = serialSoundOutDevice = [[StealthDAI2400 alloc] init];
	else serialSoundOutDevice = StealthDAI2400Dev;
	soundOutputName = @"Stealth DAI2400";
	break;
      case AD64x:
	if (!SSAD64xDev)
	  SSAD64xDev = serialSoundOutDevice = [[SSAD64x alloc] init];
	else serialSoundOutDevice = SSAD64xDev;
	soundOutputName = @"Singular Solutions A/D64x";
	break;
      default:
      case GENERIC:
	soundOutputName = @"Serial port sound";
	serialSoundOutDevice = nil;
	break;
      case NEXT_SOUND:
	soundOutputName = @"NeXT Sound";
	serialSoundOutDevice = nil;
	break;
    }
    [serialPortDeviceNameField setStringValue:soundOutputName];
    /* Run alert panel here if we're playing? FIXME */
    return;
}

+ scoreFileEditorAppName
{
    return @"TextEdit";
}

- (void)setSoundOutFrom:sender
  /* Invoked by U.I. */
{
    int tag = [[sender selectedCell] tag];
    if (soundOutType == tag)
      return;
    if (tag == NEXT_SOUND && 
	(!([theOrch capabilities] & MK_hostSoundOut))) {
	NSRunAlertPanel(STR_SCOREPLAYER, @"NeXT sound not supported on this architecture", STR_OK, nil, nil);
	[serialPortDeviceMatrix selectCellWithTag:soundOutType];
	return;
    }
    [self _setSoundOutDeviceTag:tag];
}

- (void)saveAsDefaultDevice:sender
{
    unsigned caps = [theOrch capabilities];
    if (caps & MK_hostSoundOut) {
        NSDictionary *pdi =
        [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
        NSMutableDictionary *pdm = [[pdi mutableCopy] autorelease];
        
        [pdm setObject:(soundOutType == NEXT_SOUND) ? @"Host" : @"SSI"
                forKey:@"MKOrchestraSoundOut"];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:NSGlobalDomain];
        [[NSUserDefaults standardUserDefaults] setPersistentDomain:pdm forName:NSGlobalDomain]; 

    }
    if (caps & MK_nextCompatibleDSPPort)
        if (soundOutType != NEXT_SOUND) {
            NSDictionary *pdi =
            [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
            NSMutableDictionary *pdm = [[pdi mutableCopy] autorelease];

            [pdm setObject:[soundOutputTagToName objectAtIndex:soundOutType]
                    forKey:@"MKDSPSerialPortDevice0"];
            [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:NSGlobalDomain];
            [[NSUserDefaults standardUserDefaults] setPersistentDomain:pdm forName:NSGlobalDomain]; 

        }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)deviceSpecificSettings:sender
{
    switch (soundOutType) {
      case DAI2400:
	if (!StealthDAI2400Panel) {
	    [NSBundle loadNibNamed:@"StealthDAI2400.nib" owner:self];
//#error ApplicationConversion:  NXGetNamedObject() is obsolete. Replace with nib file outlets.
//	    StealthDAI2400Panel = NXGetNamedObject("StealthDAI2400Panel",self);
	}
	[StealthDAI2400Panel makeKeyAndOrderFront:self];
	break;
      case AD64x:
	if (!SSAD64xPanel) {
	    [NSBundle loadNibNamed:@"SSAD64x.nib" owner:self];
//#error ApplicationConversion:  NXGetNamedObject() is obsolete. Replace with nib file outlets.
//	    SSAD64xPanel = NXGetNamedObject("SSAD64xPanel",self);
	}
	[SSAD64xPanel makeKeyAndOrderFront:self];
	break;
      case NEXT_SOUND:
	if (!NeXTDACPanel) {
	    [NSBundle loadNibNamed:@"NextDACs.nib" owner:self];
//#error ApplicationConversion:  NXGetNamedObject() is obsolete. Replace with nib file outlets.
//	    NeXTDACPanel = NXGetNamedObject("NeXTDACPanel",self);
	}
	[NeXTDACPanel makeKeyAndOrderFront:self];
	break;
      default:
      case PROPORT:
      case GENERIC:
	NSRunAlertPanel(STR_SCOREPLAYER, @"No special settings for this device", STR_OK, nil, nil);
	break;
    } 
}

- (void)setAD64xConsumer:sender
{
    [SSAD64xDev setProfessional:NO]; 
}

- (void)setAD64xProfessional:sender
{
    [SSAD64xDev setProfessional:YES]; 
}

- (void)setDAI2400CopyProhibit:sender
{
    [StealthDAI2400Dev setCopyProhibit:[sender intValue]];
}

- (void)setDAI2400Emphasis:sender
{
    [StealthDAI2400Dev setEmphasis:[sender intValue]];
}

- (void)setNeXTDACVolume:sender
{
    [Snd setVolume:[sender doubleValue] :[sender doubleValue]];
}

- (void)setNeXTDACMute:sender
{
    [Snd setMute:[sender intValue]];
}

- (void)getNeXTDACCurrentValues:sender
{
    float l,r;
    [Snd getVolume:&l :&r];
    [NeXTDacVolumeSlider setFloatValue:l];
    [NeXTDacMuteSwitch setIntValue:[Snd isMuted]];
}

- (void)openEditFile:sender
{
    NSString *editor;
    
    if (!fileName) {
	NSRunAlertPanel(STR_SCOREPLAYER, STR_NO_FILE_OPEN, STR_OK, nil, nil);
	return;
    }
    editor = [ScorePlayerController scoreFileEditorAppName];
    if ([editor length] == 0) {
        if (![[NSWorkspace sharedWorkspace] openFile: fileName])
            NSRunAlertPanel(STR_SCOREPLAYER, STR_EDIT_CANT_OPEN_FILE, STR_OK, nil, nil);
    }
    else {
        if (![[NSWorkspace sharedWorkspace] openFile: fileName withApplication: editor])
            NSRunAlertPanel(STR_SCOREPLAYER, STR_EDIT_CANT_OPEN_FILE, STR_OK, nil, nil);
    }

}

static id setFile(ScorePlayerController* self)
{
    id tuningSys;
    id scoreInfo;
    MKSetScorefileParseErrorAbort(10);
    /* Can this every happen? */
    if (!fileName || ![fileName length]) {
        [self->theMainWindow setTitle:STR_NO_FILE_OPEN];
        [self->editFileItem setEnabled:NO];
        [self->saveAsFileItem setEnabled:NO];
        return nil;
    }
    playScoreForm = [[fileName pathExtension] isEqualToString:@"playscore"];
    setFileTime();
    [self->editFileItem setEnabled:!playScoreForm];
    [self->saveAsFileItem setEnabled:YES];
    scoreObj = [MKScore score];
//    [theMainWindow makeKeyAndOrderFront:NXApp]; /* Probably not needed */
    [self->theMainWindow setTitle: [NSString stringWithFormat:STR_READING, shortFileName]];
    [self->theMainWindow display];
    [self->button setEnabled:NO];
    userCancelFileRead = NO;
    tuningSys = [[MKTuningSystem alloc] init]; /* 12-tone equal tempered */
    [tuningSys install];
    [tuningSys release];
    if (![scoreObj readScorefile:fileName] || userCancelFileRead) {  
	/* Error in file? */
	if (!userCancelFileRead) 
	    NSRunAlertPanel(STR_SCOREPLAYER, STR_FIX_ERRORS,STR_OK,NULL,NULL);
	scoreObj = nil;
        [fileName release];
	fileName = @"";
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
	midiOffsetPar = [MKNote parName:@"midiOffset"];
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
    [scoreObj retain];  // yep, keep it.
    return NSApp;
}


-_enableMTCControls:(BOOL)yesOrNo
{
    [timeCodeButton setEnabled:yesOrNo];
    [timeCodePortMatrix setEnabled:yesOrNo];
    if (yesOrNo) 
      [timeCodeTextField setStringValue:(synchToTimeCode) ? @"Press Play, then start time code" : @"Press button above to enable time code"];
    if (!synchToTimeCode)
      [timeCodeTextField setEnabled:yesOrNo];
    else [timeCodeTextField setEnabled:YES];
    return self;
}

static BOOL setUpFile(NSString *workspaceFileName);

- endOfTime	// called by the musickit thread
{
    int i;
    [theOrch close]; /* This will block! */
    for (i = 0; i < MAX_MIDIS; i++) {
	[midis[i] close];
        [midis[i] release];
	midis[i] = nil;
    }
    if (DSPCommands) {
	DSPCommands = NO;
	[theOrch setOutputCommandsFile:NULL];
    }
    else if (writeData) {
	writeData = NO;
	[theOrch setOutputSoundfile:NULL];
    }
    [theOrch setHostSoundOut:(soundOutType == NEXT_SOUND)];
    [tempoAnimator stopEntry];
    [button setImage:playImage];
    [button display];
    [tooFastErrorMsg setTextColor: [NSColor lightGrayColor]];
    [tooFastErrorMsg setBackgroundColor: [NSColor lightGrayColor]];
    if (errorDuringPlayback && ![errorLog isVisible])
	NSRunAlertPanel(STR_SCOREPLAYER, STR_ERRORS, STR_OK, nil, nil);
    messageFlashed = NO;
    isLate = NO;
    wasLate = NO;
    errorDuringPlayback = NO;
    [theMainWindow setTitle: shortFileName];
    [theMainWindow display];
    [soundSavePanel close];
    [self _enableMTCControls:YES];
    return self;
}

#if 0  /*sb: as this is never called */
void *endOfTimeProc(msg_header_t *msg,ScorePlayerController *myself )
{
    [tempoAnimator stopEntry];
    [myself->button setImage:playImage];
    [myself->button display];
    [myself->tooFastErrorMsg setTextColor:[NSColor lightGrayColor]];
    [myself->tooFastErrorMsg setBackgroundColor:[NSColor lightGrayColor]];
    if (errorDuringPlayback && ![errorLog isVisible])
	NSRunAlertPanel(STR_SCOREPLAYER, STR_ERRORS, STR_OK, nil, nil);
    messageFlashed = NO;
    isLate = NO;
    wasLate = NO;
    errorDuringPlayback = NO;
    [myself->theMainWindow setTitle:shortFileName];
    [myself->theMainWindow display];
    [myself->soundSavePanel close];
    [myself->dspCommandsSavePanel close];
    [myself _enableMTCControls:YES];
    return myself;
}
#endif

static BOOL isMidiClassName(NSString *className)
{
    return (className && ([className isEqualToString:@"midi"] ||
                          [className isEqualToString:@"midi0"] ||
                          [className isEqualToString:@"midi1"]));
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

static void playIt(ScorePlayerController *self)
{
    int partCount, synthPatchCount, voices, i, whichMidi, midiChan;
    NSString *className;
    NSString *msg = nil;
    double actualSrate;  
    NSArray *partPerformers;
    MKPartPerformer *partPerformer;
    Class synthPatchClass;
    MKSynthInstrument *anIns;
    MKNote *partInfo;
    MKPart *aPart;
    NSString *writeMsg;

    /* Could keep these around, in repeat-play cases: */ 
    [scorePerformer release];
    scorePerformer = nil;
    [synthInstruments release];
    [self _enableMTCControls:NO];

    if (synchToTimeCode) {
	midis[timeCodePort] = [[MKMidi midiOnDevice: (timeCodePort) ? @"midi1" : @"midi0"] retain];
	[[MKConductor defaultConductor] setMTCSynch: midis[timeCodePort]];
    }
    else
        [[MKConductor defaultConductor] setMTCSynch:nil];

    theOrch = [MKOrchestra newOnDSP:0]; /* A noop if it exists */

    [theOrch setHeadroom:headroom];    /* Must be reset for each play */ 
    if (serialSoundOutDevice)
      [theOrch setSerialPortDevice:serialSoundOutDevice];
    switch (soundOutType) {
      case NEXT_SOUND:
	if (![theOrch supportsSamplingRate:samplingRate]) {
	    msg = STR_BAD_SRATE;
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
	    msg = STR_BAD_SSI_SRATE;
	    actualSrate = [theOrch defaultSamplingRate];
	}
	else actualSrate = samplingRate;
	break;
    }
    if (msg && !warnedAboutSrate) {	
        [errorLog addText:msg];
	warnedAboutSrate = YES;
	NSRunAlertPanel(STR_SCOREPLAYER,msg,STR_OK,NULL,NULL);
    }
    [theOrch setSamplingRate:actualSrate];

#if SOUND_OUT_PAUSE_BUG
    if (checkForMidi(scoreObj))
	[theOrch setFastResponse:YES];
    else [theOrch setFastResponse:NO];
#endif
    [theOrch setOutputCommandsFile:(DSPCommands)?outputFilePath:nil];
    [theOrch setOutputSoundfile:(writeData)?outputFilePath:nil];
    [theOrch setHostSoundOut:!writeData && (soundOutType == NEXT_SOUND)];
    [theOrch setSerialSoundOut:(soundOutType != NEXT_SOUND) && !writeData];

    if (![theOrch open]) {
        [errorLog addText: STR_CANT_OPEN_DSP];
        NSRunAlertPanel(STR_SCOREPLAYER, STR_CANT_OPEN_DSP, STR_OK, NULL, NULL);
//	return; // LMS disabled until MOX orchestra opening works
    }
    scorePerformer = [MKScorePerformer new];
    [scorePerformer setScore:scoreObj];
    [(MKScorePerformer *)scorePerformer activate]; 
    partPerformers = [scorePerformer partPerformers];
    partCount = [partPerformers count];
    synthInstruments = [[NSMutableArray array] retain];
    for (i = 0; i < partCount; i++) {
	partPerformer = [partPerformers objectAtIndex:i];
	aPart = [partPerformer part]; 
	partInfo = [aPart infoNote];      
	if ((!partInfo) || ![partInfo isParPresent:MK_synthPatch]) {
            errMsg = [NSString stringWithFormat: STR_INFO_MISSING, MKGetObjectName(aPart)];
            [errorLog addText: errMsg];
#if 0
            if (!NSRunAlertPanel(STR_SCOREPLAYER, errMsg, STR_CONTINUE, STR_CANCEL, nil)) 
                return;
#endif
	    continue;
	}		
	className = [partInfo parAsStringNoCopy:MK_synthPatch];
	if (isMidiClassName(className)) {
	    midiChan = [partInfo parAsInt:MK_midiChan];
	    if ((midiChan == MAXINT) || (midiChan > 16))
		midiChan = 0;
            if ([className isEqualToString:@"midi"])
		className = @"midi0"; /* Was "midi1" -- changed 9/30/94 */
            if ([className isEqualToString:@"midi1"])
		whichMidi = 1;
	    else whichMidi = 0;
	    if (midis[whichMidi] == nil)
		midis[whichMidi] = [[MKMidi midiOnDevice:className] retain];
	    [[partPerformer noteSender] connect:
	     [midis[whichMidi] channelNoteReceiver:midiChan]];
	}
	else {
	    synthPatchClass = ([className length]) ? 
			       [MKSynthPatch findSynthPatchClass:className] : nil;
	    if (!synthPatchClass) {         /* Class not loaded in program? */
                errMsg = [NSString stringWithFormat: STR_NO_SYNTHPATCH, className];
                [errorLog addText: errMsg];
		if (!NSRunAlertPanel(STR_SCOREPLAYER, errMsg, STR_CONTINUE, STR_CANCEL, nil))
		    return;
		/* We would prefer to do dynamic loading here. */
		continue;
	    }
	    anIns = [MKSynthInstrument new];      
	    [synthInstruments addObject:anIns];
	    [[partPerformer noteSender] connect:[anIns noteReceiver]];
	    [anIns setSynthPatchClass:synthPatchClass];
	    if (![partInfo isParPresent:MK_synthPatchCount])
		continue;         
	    voices = [partInfo parAsInt:MK_synthPatchCount];
	    synthPatchCount = [anIns setSynthPatchCount: voices
                                          patchTemplate: [synthPatchClass patchTemplateFor:partInfo]];
	    if (synthPatchCount < voices) {
                errMsg = [NSString stringWithFormat: STR_TOO_MANY_SYNTHPATCHES,
                    synthPatchCount, voices, className, MKGetObjectName(aPart)];

                [errorLog addText: errMsg];
		if (!NSRunAlertPanel(STR_SCOREPLAYER, errMsg, STR_CONTINUE, STR_CANCEL, NULL))
		    return;
	    }
	}
    }
    [partPerformers release];
    errorDuringPlayback = NO;
    [self->theMainWindow setTitle: [NSString stringWithFormat: STR_PLAYING, shortFileName]];
    [self->theMainWindow display];
    MKSetDeltaT(.75);
    [MKOrchestra setTimed: YES];
    [condClass afterPerformanceSel: @selector(endOfTime) to: self argCount: 0];
    [self->button setImage: stopImage];
    [self->button display];
    if (synchToTimeCode)
        [self showConductorDidPause];
    if (writeData) {
        writeMsg = @"Writing sound file (silently) ...";
    }
    else if (DSPCommands) {
        writeMsg = @"Writing DSP Commands format soundfile.";
    }
    if (writeData || DSPCommands) {
        [self->soundWriteMsg setStringValue: writeMsg];
	[self->soundSavePanel orderFront: self];
    }
    [tempoAnimator setIncrement: ANIMATE_INCREMENT];
    [tempoAnimator startEntry];
    for (i = 0; i < MAX_MIDIS; i++) 
        if (midis[i] && ![midis[i] openOutputOnly]) /* midis[i] is nil if not in use */
            mkRunAlertPanel(STR_SCOREPLAYER_ERROR, STR_CANT_OPEN_MIDI, STR_OK, STR_CANCEL, NULL);
    for (i = 0; i < MAX_MIDIS; i++) {
        if (midiOffset > 0) 
	    [midis[i] setLocalDeltaT: midiOffset];
	else if (midiOffset < 0)
	    [theOrch setLocalDeltaT: -midiOffset];
    }
    for (i=0; i<MAX_MIDIS; i++) 
	[midis[i] run];
    [theOrch run];
    [condClass startPerformance];     
}

-setTempoAdjustment:sender
{
    [MKConductor setDelegate:([[sender selectedCell] tag] == 0) ? self : nil];
    return self;
}

static id LocalImage(NSString *s)
{
    NSString * buf;
    buf = [[NSBundle mainBundle] pathForResource:s ofType:@"tiff"]; 
    return [[NSImage alloc] initByReferencingFile:buf];
}

+ (void)initialize
{
    NSDictionary *ScorePlayerDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
        @"NeXTsound", @"SoundOutput", NULL, NULL];
    [[NSUserDefaults standardUserDefaults] registerDefaults:ScorePlayerDefaults];
    return;
}

static void abortNow();

- orchestraDidAbort:whichOrch
  /* This is received by the appkit thread */
{
    NSRunAlertPanel(STR_SCOREPLAYER,STR_HUNG_DSP,NULL,NULL,NULL);
    abortNow();
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification 
{
    NSString *s;
    static int inited = 0;
    NSUserDefaults *scorePlayerDefaults = [NSUserDefaults standardUserDefaults];
//    int ec;

    if (inited++)
      return;
    mySelf = self;
    fileExtensions = [[NSArray alloc] initWithObjects:
        @"score", @"playscore",@"midi", @"snd", @"snd",nil];
    fileIcons = [[NSArray alloc] initWithObjects:
        @"ScorePlayerDoc", @"ScorePlayerDoc2",@"Midi", @"Sound", @"Sound",nil];
    soundOutputTagToName = [[NSArray alloc] initWithObjects:
      /* These are the class names */
      @"",@"StealthDAI2400",@"SSAD64x",@"ArielProPort",@"DSPSerialPortDevice",nil];


    SSAD64xPanel = StealthDAI2400Panel = NeXTDACPanel = nil;
    playImage = LocalImage(@"play");
    [button setImage:playImage];
    [button display];
    fileSuffixes = [[NSArray arrayWithObjects: @"score", @"playscore", nil] retain];
    errorLog = [[ErrorLog alloc] init];
    [condClass setThreadPriority:1.0];
    [MKPartPerformer setFastActivation:YES]; /* We're not modifying parts while playing */
    setuid(getuid()); /* Must be after setThreadPriority. */
    [condClass useSeparateThread:YES];
//    [condClass setDelegate:NXApp]; /* Default is no tempo adjustment */
    [[MKConductor defaultConductor] setDelegate:self];
    /* These numbers could be endlessly tweaked */
    MKSetLowDeltaTThreshold(.25);
    MKSetHighDeltaTThreshold(.4);
//    _MKSetConductorThreadMaxStress(1000000); /* Don't do cthread_yields */
#if 0
    ec = port_allocate(task_self(), &endOfTimePort);
#error DPSConversion: 'addPort:forMode:' used to be DPSAddPort(endOfTimePort, (DPSPortProc)endOfTimeProc, sizeof(msg_header_t), (void *)self, 30).  endOfTimePort should be retained to avoid loss through deallocation, the functionality of (DPSPortProc)endOfTimeProc should be implemented by a delegate of the NSPort in response to 'handleMachMessage:' or 'handlePortMessage:',  and 30 should be converted to an NSRunLoop mode (NSDefaultRunLoopMode, NSModalPanelRunLoopMode, and NSEventTrackingRunLoopMode are predefined).
    [[NSRunLoop currentRunLoop] addPort:[NSPort portWithMachPort:endOfTimePort] forMode:30];
#endif
    MKSetErrorProc(handleMKError);
// LMS disabled, the console is good enough for us to see ObjectiveC errors.
//    objc_setClassHandler(handleObjcError);
   
    /* Create the tempo aminmator, but don't start it yet */
    tempoAnimator = [Animator newChronon: 0.0
	                   adaptation: 0.0				
		           target:     self
		           action:     @selector(animateTempo:)
		           autoStart:  NO
		           eventMask:  NSAnyEventMask];
	
	/* set up the button */			   
	
    stopImage = LocalImage(@"stop");
    playHImage = LocalImage(@"playH");
    [button setAlternateImage:playHImage];
	    
    [MKOrchestra setAbortNotification:self]; 
    theOrch = [MKOrchestra new];
    capabilities = [theOrch capabilities];


    if (capabilities & MK_hostSoundOut) {
        s = [scorePlayerDefaults stringForKey: @"MKOrchestraSoundOut"];
	if ([s isEqual: @"Host"]) {
	    [self _setSoundOutDeviceTag: NEXT_SOUND];
	}
	else {
            s = [scorePlayerDefaults stringForKey: @"MKDSPSerialPortDevice0"];
	    [self _setSoundOutDeviceTag:[self _soundOutputNameToTag: s]];
	}
    } else {
	if ((capabilities & MK_nextCompatibleDSPPort)) {
            s = [scorePlayerDefaults stringForKey: @"MKDSPSerialPortDevice0"];
	    [self _setSoundOutDeviceTag:[self _soundOutputNameToTag: s]];
	}
	else {
	    [self _setSoundOutDeviceTag:GENERIC];
	    [serialPortDeviceMatrix selectCellWithTag:GENERIC];
	    [serialPortDeviceMatrix setEnabled:NO];
	}
    }
}

static BOOL setUpFile(NSString *workspaceFileName)
{
    int success;
    static BOOL firstTime = YES;
    if (!openPanel)
        openPanel = [NSOpenPanel new];    
    if (!workspaceFileName) {
	if (firstTime) {
            NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);

            success = [openPanel
                    runModalForDirectory: [[libraryDirs objectAtIndex: 0] stringByAppendingPathComponent: @"/Music/Scores"]
                    file:@"Examp1.score"
                    types:fileSuffixes];
        }
        else if (dir) {
             success = [openPanel 
		     runModalForDirectory:dir
		     file:shortFileName 
		     types:fileSuffixes]; 
	     [dir release];
	     dir = nil;
	}
	else 
	  success = [openPanel runModalForTypes:fileSuffixes];
	if (!success)
	  return NO;
        [fileName release];
        fileName = [[openPanel filename] retain];
        [shortFileName release];
        shortFileName = [[fileName lastPathComponent] retain];
    }
    else {
        [fileName release];
	fileName = [workspaceFileName copy];
        [shortFileName release];
        shortFileName = [[workspaceFileName lastPathComponent] retain];
    }
    if  ( [shortFileName isEqualToString:@"Jungle.score"] ||
          [shortFileName isEqualToString:@"Jungle.playscore"]
	 )
      tempoExponent = 1.3;  /* A real hack to make the demos play ok. */
    else tempoExponent = 1.5;
    firstTime = NO;
    return YES;
}

static void abortNow()
{
    int i;
    if (PLAYING) {
	[condClass lockPerformance];
	for (i=0; i<MAX_MIDIS; i++) {
            if (midis[i]) {
                [midis[i] allNotesOff];
                [midis[i] abort];
            }
        }
	[theOrch abort];
	[condClass finishPerformance];
	[condClass unlockPerformance];

//	while (PLAYING) /* Make sure it's really done. */
//	  usleep(1000);
    }
}

- (void)selectFile:sender
{
    abortNow(); /* Could move this to after setUpFile() */
    if (!setUpFile(nil)) {
      return;
    }
    setFile(self); 
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSString *aType = [fileName pathExtension];
    if (aType)
        if (![aType isEqualToString:@"score"] &&
            ![aType isEqualToString:@"playscore"])
	return NO;
    setUpFile(filename);
    abortNow();
    setFile(self);
    return YES;
}


- (void) playStop:sender
{
    if (!fileName || ![fileName length])
        [self selectFile:self];
    if (!fileName || ![fileName length])
        return;
    if (PLAYING)
        abortNow();
    else {
	if (needToReread()) {
            NSLog(@"File has changed, re-reading\n");
	    setFile(self);
	}
        playIt(self);
    }
    return;
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
	[tooFastErrorMsg setTextColor:[NSColor blackColor]];
	[tooFastErrorMsg setBackgroundColor:[NSColor lightGrayColor]];
	messageFlashed = YES;
    } else if (!isLate && messageFlashed) {
	[tooFastErrorMsg setTextColor:[NSColor lightGrayColor]];
	[tooFastErrorMsg setBackgroundColor:[NSColor lightGrayColor]];
	messageFlashed = NO;
	wasLate = NO;
    }
    diff = lastTempo - desiredTempo;
    if (diff < 0.0)  /* Abs value */
      diff = -diff;
    if (!forceAdjustment && diff < ANIMATE_DIFF_THRESHOLD) /* diff too small */
      return self;
    [condClass lockPerformance];
    [[MKConductor defaultConductor] setTempo:desiredTempo];
    [condClass unlockPerformance];
    [tempoTextField setFloatValue:desiredTempo];
    if (wasLate || isLate)
       [tempoSlider setFloatValue:getUntempo(desiredTempo)];
    lastTempo = desiredTempo;
    return self;
}

- (void)setTempoFrom:sender	// currently called by slider only
{
    double val = ([sender doubleValue]);
    desiredTempo = getTempo(val);
    if (!PLAYING) {
	[[condClass defaultConductor] setTempo:desiredTempo];
	[tempoTextField setFloatValue:desiredTempo];
	lastTempo = desiredTempo;
    }
}

- (void)setTimeCodeSynch:sender
{
    synchToTimeCode = [sender intValue];
    [timeCodeTextField setStringValue:(synchToTimeCode) ? @"Press Play, then start time code" : @"Press button above to enable time code"]; 
}

- (void)setTimeCodeSerialPort:sender
{
    /* 0 for portA, 1 for portB */
    timeCodePort = [[sender selectedCell] tag]; 
}


- conductorWillSeek:sender
{
    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorWillSeek)
     to:self argCount:0];
    return self;
}

- conductorDidSeek:sender
{
    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorDidSeek)
     to:self argCount:0];
    return self;
}

- conductorDidReverse:sender
{
    [MKConductor sendMsgToApplicationThreadSel:@selector(showConductorDidReverse)
     to:self argCount:0];
    return self;
}

- conductorDidPause:sender
{
    int i;
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidPause) to: self argCount: 0];
    [synthInstruments makeObjectsPerformSelector: @selector(allNotesOff)];
    for (i=0; i<MAX_MIDIS; i++) {
        [midis[i] allNotesOff];
    }
    return self;
}

- conductorDidResume:sender
{
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidResume) to: self argCount: 0];
    return self;
}

- (void) applicationWillTerminate: (NSNotification *) aNotification
{
    abortNow();
}

BOOL getSavePath(NSString **returnBuf, NSString *dir, NSString *name, NSString *theType)
     /* Set up and run the Save panel for the given type.  The accessory view
      * is a button which allows the type to be changed when saving scores.
      */
{
    BOOL flag;

    if (!savePanel) {
	savePanel = [NSSavePanel new];
	[savePanel setTitle:@"ScorePlayer Save"];
	[accessoryView setImagePosition:NSImageAbove];
	[accessoryView setTarget:mySelf];
	[accessoryView setAction:@selector(changeSaveType:)];
	[accessoryView setFrameSize:NSMakeSize(124, 68)];
    }
    [savePanel setAccessoryView:accessoryView];
    if (theType && [theType length])
        [savePanel setRequiredFileType:theType];
    flag = [savePanel runModalForDirectory:@"" file:@""];
    if (flag) *returnBuf = [savePanel filename];
    soundFile = (saveType==SAVE_SOUND) ? *returnBuf : NULL;

    return flag;
}


static int fileType(NSString *name)
     /* return the file type for the specified name */
{
    NSString *ext = [name pathExtension];
    if ([ext isEqualToString:@"midi"] ||
        [ext isEqualToString:@"MIDI"] ||
        [ext isEqualToString:@"mid"] ||
        [ext isEqualToString:@"MID"])
        return SAVE_MIDI;
    else if ([ext isEqualToString:@"playscore"] ||
             [ext isEqualToString:@"PLAYSCORE"])
        return SAVE_PLAYSCORE;
    else if ([ext isEqualToString:@"snd"] ||
             [ext isEqualToString:@"SND"])
        return (soundFile && [soundFile length])?SAVE_SOUND:SAVE_COMMANDS;
    return SAVE_SCORE;
}

NSString *getPath(NSString *dir, NSString *name, NSString *ext)
     /* Construct a path given a file name, directory, and type */
{
    if (!dir || ![dir length]) dir = NSHomeDirectory();
    if (!name ) name=@"";
    if (!ext ) ext=@"";
    if ([[name pathExtension] isEqualToString:ext])
        name = [name stringByDeletingPathExtension];
    return [dir stringByAppendingPathComponent:[name stringByAppendingPathExtension:ext]];
}

- setSaveType:(int)type
    /* Set the Save panel accessory view icon and label according to type. */
{
    saveType = type;
    if (!accessoryView) {
	accessoryView = [[NSButton alloc] init];
        [fileTypes release];
        fileTypes = [[NSArray alloc] initWithObjects:
            STR_SCOREFILE, STR_PLAYSCOREFILE, STR_MIDIFILE, STR_DSPFILE, STR_SOUNDFILE,nil];
    }
    [accessoryView setImage:[NSImage imageNamed:[fileIcons objectAtIndex:type]]];
    [accessoryView setTitle:[fileTypes objectAtIndex:type]];
    [savePanel setRequiredFileType:[fileExtensions objectAtIndex:type]];
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

- (void)saveScoreAs:sender
    /* Save the score, always prompting for a file name first.
       This is what the SaveAs: menu item calls. */
{
    if (PLAYING)
      abortNow();
    if (saveType==-1) 
	[self setSaveType:SAVE_SCORE];
    if (!getSavePath(&outputFilePath,outputFileDir, outputFileName,
                     [fileExtensions objectAtIndex:saveType]))
	return;
    outputFileDir = [outputFilePath stringByDeletingLastPathComponent];
    outputFileName = [outputFilePath lastPathComponent];
    [self setSaveType:fileType(outputFilePath)];
    outputFilePath = getPath(outputFileDir, outputFileName,
                             [fileExtensions objectAtIndex:saveType]);
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
    [[NSCursor arrowCursor] set]; 
}

- (void)help:sender
 /* Display the help text file with Edit. */
{
    /* Look in the app wrapper */
    NSString *helpfile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"help.rtfd"];
    if (![[NSWorkspace sharedWorkspace] openFile:helpfile])
        NSRunAlertPanel(STR_SCOREPLAYER, STR_EDIT_CANT_OPEN_FILE, @"", nil, nil);
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
    [[MKConductor defaultConductor] resume];
    [MKConductor unlockPerformance];
    return self;
}

@end

