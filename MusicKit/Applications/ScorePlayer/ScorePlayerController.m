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
  Revision 1.18  2002/02/05 15:51:44  leighsmith
  Added extra checks that we were able to initialise a MIDI device

  Revision 1.17  2002/01/24 17:01:43  sbrandon
  fixed a number of release problems (mainly pathnames)

  Revision 1.16  2001/09/19 23:43:34  leighsmith
  Upgraded to more descriptive parTagForName: and parNameForTag: methods

  Revision 1.15  2001/04/19 14:57:55  leighsmith
  Now allocate MIDI devices dynamically, added abort to MKSamplerInstrument, help file is now HTML

  Revision 1.14  2001/04/16 23:16:56  leighsmith
  Now uses the NSOpenPanel default location

  Revision 1.13  2001/03/22 20:17:49  leigh
  Made tempo changeable during playback

  Revision 1.12  2001/03/17 02:04:39  leigh
  Forced synthPatches to midi if we loaded a midi file, not a score

  Revision 1.11  2001/03/12 02:02:01  leigh
  Updated to findPatchClass method

  Revision 1.10  2001/03/02 04:09:18  leigh
  Added MIDI file reading, automatic menu validation, now relying on MKScore to tell us the file extensions

  Revision 1.9  2001/03/01 17:56:32  leigh
  Removed unnecessary condClass define

  Revision 1.8  2001/02/15 01:51:08  leigh
  Added MKSamplerInstrument support, retrieved valid filename extensions from MKScore

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
static NSArray *openFileExtensions;
static NSString *dir = nil;
static BOOL messageFlashed = NO;
static BOOL isLate = NO;
static BOOL wasLate = NO;
static id stopImage,playImage,playHImage;
// MIDI management
static NSMutableDictionary *midis;
static MKSamplerInstrument *sampleInstrument = nil;
static int midiOffset;
// MTC sync
static BOOL synchToTimeCode = NO;
static NSString *timeCodeDevice;
static MKMidi *timeCodeMIDIDevice = nil;

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

enum _fileType {NO_TYPE = -1, SCORE_FILE, PLAYSCORE_FILE, MIDI_FILE, DSP_COMMANDS_FILE, SOUND_FILE};
static enum _fileType saveType = NO_TYPE;
static enum _fileType scoreForm = NO_TYPE;

static NSArray *fileIcons;
static NSArray *fileTypes;
static NSArray *saveFileExtensions;

static NSButton *accessoryView = nil;
static id savePanel = nil;
static NSString *soundFile = nil;

static int warnedAboutSrate = NO;
static NSDate *lastModifyTime;

static ErrorLog *errorLog;
static BOOL errorDuringPlayback = NO;

#define PLAYING ([MKConductor inPerformance])
#if m68k
#define SOUND_OUT_PAUSE_BUG 1 /* Workaround for problem synching MIDI to DSP */
#endif


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

// LMS disabled, the console is good enough for us to see ObjectiveC errors.
// static int handleObjcError(const char *className)
//{
//    return 0;
//}

static void handleMKError(NSString *msg)
{
    if (!PLAYING) {
        [errorLog addText:msg];
	if (!mkRunAlertPanel(STR_SCOREPLAYER_ERROR,msg,STR_OK,STR_CANCEL,NULL)) {
            MKSetScorefileParseErrorAbort(0);
            userCancelFileRead = YES;         /* A kludge for now. */
        }
    }
    else {
        [MKConductor sendMsgToApplicationThreadSel: @selector(runAlert:)
                                                to: mySelf
                                          argCount: 1, [msg copy]];
    }
}

static void setFileTime(void)
{
    NSDictionary *fattrs;
    if (scoreForm == PLAYSCORE_FILE)
        return;
    fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: fileName
                                                     traverseLink: YES];
    lastModifyTime = [[fattrs objectForKey:NSFileModificationDate] retain];
}

// Return YES if we should re-read the score file.
static BOOL needToReread(void)
{
    NSDictionary *fattrs;
    NSDate *fileModifyTime;
    BOOL reread;
    
    if (scoreForm == PLAYSCORE_FILE)
        return NO;
    fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: fileName
                                                     traverseLink: YES];
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

static int fileType(NSString *name)
     /* return the file type for the specified name */
{
    NSString *ext = [name pathExtension];
    
    if ([[MKScore midifileExtensions] indexOfObject: ext] != NSNotFound)
        return MIDI_FILE;
    else if ([ext isEqualToString:@"playscore"] ||
             [ext isEqualToString:@"PLAYSCORE"])
        return PLAYSCORE_FILE;
    // TODO [[Snd fileExtensions] indexOfObject: ext] != NSNotFound
    else if ([ext isEqualToString:@"snd"] ||
             [ext isEqualToString:@"SND"])
        return (soundFile && [soundFile length]) ? SOUND_FILE : DSP_COMMANDS_FILE;
    return SCORE_FILE;
}

// Menu Item update method selectively enabling the editing of scores and saving files.
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
    BOOL validFileNameAndObject = fileName && [fileName length] && scoreObj;
    
    if([[menuItem title] isEqualToString: @"Edit Scorefile..."])
        return validFileNameAndObject && scoreForm == SCORE_FILE;
    if([[menuItem title] isEqualToString: @"Save As..."])
        return validFileNameAndObject;
    // TODO surely this is more valid?
    // return [super validateMenuItem: menuItem];
    return YES;
}

static BOOL setFile(ScorePlayerController *self)
{
    MKTuningSystem *tuningSys;
    MKNote *scoreInfo;
    MKScore *loadResult;
    
    MKSetScorefileParseErrorAbort(10);
    /* Can this every happen? */
    if (!fileName || ![fileName length]) {
        [self->theMainWindow setTitle: STR_NO_FILE_OPEN];
        return NO;
    }
    scoreForm = fileType(fileName);    // determine what sort of file we are reading.
    setFileTime();
    scoreObj = [MKScore score];
    [self->theMainWindow setTitle: [NSString stringWithFormat: STR_READING, shortFileName]];
    [self->theMainWindow display];
    [self->playButton setEnabled: NO];
    tuningSys = [[MKTuningSystem alloc] init]; /* 12-tone equal tempered */
    [tuningSys install];
    [tuningSys release];
    userCancelFileRead = NO;
    loadResult = (scoreForm == MIDI_FILE) ? [scoreObj readMidifile: fileName] :
                                            [scoreObj readScorefile: fileName];
    if (!loadResult || userCancelFileRead) {  
	/* Error in file? */
	if (!userCancelFileRead) 
	    NSRunAlertPanel(STR_SCOREPLAYER, STR_FIX_ERRORS, STR_OK, NULL, NULL);
	scoreObj = nil;
        [fileName release];
	fileName = @"";
	[self->theMainWindow setTitle: STR_SCOREPLAYER];
	[self->playButton setEnabled: YES];
	[self->theMainWindow display];
	return NO;
    }
    samplingRate = [theOrch defaultSamplingRate];
    headroom = .1;
    initialTempo = 60.0;
    [[MKConductor defaultConductor] setTempo: initialTempo];
    scoreInfo = [scoreObj infoNote];
    if (scoreInfo) { /* Configure performance as specified in info. */ 
	int midiOffsetPar;
	midiOffset = 0;
	midiOffsetPar = [MKNote parTagForName: @"midiOffset"];
	if ([scoreInfo isParPresent: midiOffsetPar])
	    midiOffset = [scoreInfo parAsDouble: midiOffsetPar];
	if ([scoreInfo isParPresent: MK_headroom])
            headroom = [scoreInfo parAsDouble: MK_headroom];	  
	if ([scoreInfo isParPresent: MK_alternativeSamplingRate] &&
	    [theOrch prefersAlternativeSamplingRate])
            samplingRate = [scoreInfo parAsDouble: MK_alternativeSamplingRate];
	else if ([scoreInfo isParPresent: MK_samplingRate]) 
            samplingRate = [scoreInfo parAsDouble: MK_samplingRate];
	if ([scoreInfo isParPresent: MK_tempo]) {
	    initialTempo = [scoreInfo parAsDouble: MK_tempo];
	    [[MKConductor defaultConductor] setTempo: initialTempo];
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
    [self->tempoSlider setFloatValue: 0.0];
    [self->tempoTextField setFloatValue: initialTempo];
    [self->theMainWindow setTitle: shortFileName];
    [self->theMainWindow display];
    [self->playButton setEnabled: YES];
    [scoreObj retain];  // yep, keep it.
    return YES;
}


-_enableMTCControls:(BOOL)yesOrNo
{
    [timeCodeButton setEnabled:yesOrNo];
    [timeCodePortMatrix setEnabled:yesOrNo];
    if (yesOrNo) 
        [timeCodeTextField setStringValue:
            (synchToTimeCode) ? @"Press Play, then start time code" : @"Press button above to enable time code"];
    if (!synchToTimeCode)
        [timeCodeTextField setEnabled:yesOrNo];
    else 
        [timeCodeTextField setEnabled:YES];
    return self;
}

static BOOL setUpFile(NSString *workspaceFileName);

- endOfTime	// called by the musickit thread
{
    NSEnumerator *midiDevEnumerator = [midis objectEnumerator];
    MKMidi *midiDev;

    [theOrch close]; /* This will block! */
    while ((midiDev = [midiDevEnumerator nextObject])) {
	[midiDev close];
    }
    if (DSPCommands) {
	DSPCommands = NO;
	[theOrch setOutputCommandsFile: NULL];
    }
    else if (writeData) {
	writeData = NO;
	[theOrch setOutputSoundfile: NULL];
    }
    [theOrch setHostSoundOut: (soundOutType == NEXT_SOUND)];
    [tempoAnimator stopEntry];
    [playButton setImage: playImage];
    [playButton display];
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
    [myself->playButton setImage:playImage];
    [myself->playButton display];
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

/* TODO make this more encompassing of all MIDI device namings */
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
    int partCount, synthPatchCount, voices, i, midiChan;
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
    NSEnumerator *midiDevEnumerator;
    MKMidi *midiDev;

    /* Could keep these around, in repeat-play cases: */ 
    [scorePerformer release];
    scorePerformer = nil;
    [synthInstruments release];
    [self _enableMTCControls:NO];

    if (synchToTimeCode) {
	timeCodeMIDIDevice = [[MKMidi midiOnDevice: timeCodeDevice] retain];
	[[MKConductor defaultConductor] setMTCSynch: timeCodeMIDIDevice];
    }
    else
        [[MKConductor defaultConductor] setMTCSynch: nil];

    theOrch = [MKOrchestra newOnDSP: 0]; /* A noop if it exists */

    [theOrch setHeadroom:headroom];    /* Must be reset for each play */ 
    if (serialSoundOutDevice)
        [theOrch setSerialPortDevice: serialSoundOutDevice];
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

#if 0 // LMS disabled until cross-platform orchestra opening works
    if (![theOrch open]) {
        [errorLog addText: STR_CANT_OPEN_DSP];
        NSRunAlertPanel(STR_SCOREPLAYER, STR_CANT_OPEN_DSP, STR_OK, NULL, NULL);
	return; 
    }
#endif
    scorePerformer = [MKScorePerformer new];
    [scorePerformer setScore: scoreObj];
    [scorePerformer activate]; 
    partPerformers = [scorePerformer partPerformers];
    partCount = [partPerformers count];
    synthInstruments = [[NSMutableArray array] retain];
    for (i = 0; i < partCount; i++) {
	partPerformer = [partPerformers objectAtIndex:i];
	aPart = [partPerformer part]; 
	partInfo = [aPart infoNote];
	if (!partInfo) {
            errMsg = [NSString stringWithFormat: STR_INFO_MISSING, MKGetObjectName(aPart)];
            [errorLog addText: errMsg];
            if (!NSRunAlertPanel(STR_SCOREPLAYER, errMsg, STR_CONTINUE, STR_CANCEL, nil)) 
                return;
	    continue;
	}		
        // If it's a SMF, all parts are MKMidi synthPatches.
        if(![partInfo isParPresent: MK_synthPatch] && scoreForm == MIDI_FILE) {
            [partInfo setPar: MK_synthPatch toString: @"midi"];
        }
        className = [partInfo parAsStringNoCopy: MK_synthPatch];
	if (isMidiClassName(className)) {
            MKMidi *newMIDI = nil;
            
	    midiChan = [partInfo parAsInt: MK_midiChan];
	    if ((midiChan == MAXINT) || (midiChan > 16))
		midiChan = 0;
            if ([className isEqualToString: @"midi"])  // set the default MIDI device.
		className = @"midi0"; /* Was "midi1" -- changed 9/30/94 */
                       
	    if ((newMIDI = [midis objectForKey: className]) == nil) {
                newMIDI = [MKMidi midiOnDevice: className];
                // Check that newMIDI is not nil, i.e midiOnDevice did initialise
                if(newMIDI != nil)
                    [midis setObject: newMIDI forKey: className];
            }
            if(newMIDI != nil)
                [[partPerformer noteSender] connect: [newMIDI channelNoteReceiver: midiChan]];
	}
        else if([className isEqualToString: @"Samples"]) {
            sampleInstrument = [[MKSamplerInstrument alloc] init];
            [[partPerformer noteSender] connect: [sampleInstrument noteReceiver]];
        }
	else {
	    synthPatchClass = ([className length]) ? [MKSynthPatch findPatchClass: className] : nil;
	    if (!synthPatchClass) {         /* Class not loaded in program? */
                errMsg = [NSString stringWithFormat: STR_NO_SYNTHPATCH, className];
                [errorLog addText: errMsg];
		if (!NSRunAlertPanel(STR_SCOREPLAYER, errMsg, STR_CONTINUE, STR_CANCEL, nil))
		    return;
		/* We would prefer to do dynamic loading here. */
		continue;
	    }
	    anIns = [MKSynthInstrument new];      
	    [synthInstruments addObject: anIns];
	    [[partPerformer noteSender] connect: [anIns noteReceiver]];
	    [anIns setSynthPatchClass: synthPatchClass];
	    if (![partInfo isParPresent: MK_synthPatchCount])
		continue;         
	    voices = [partInfo parAsInt: MK_synthPatchCount];
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
    errorDuringPlayback = NO;
    [self->theMainWindow setTitle: [NSString stringWithFormat: STR_PLAYING, shortFileName]];
    [self->theMainWindow display];
    MKSetDeltaT(.75);
    [MKOrchestra setTimed: YES];
    [MKConductor afterPerformanceSel: @selector(endOfTime) to: self argCount: 0];
    [self->playButton setImage: stopImage];
    [self->playButton display];
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
    
    midiDevEnumerator = [midis objectEnumerator];
    while ((midiDev = [midiDevEnumerator nextObject])) {
        if ([midiDev openOutputOnly]) {
            // set the localDeltaT time offset, negative values are for orchestras
            if (midiOffset > 0) 
                [midiDev setLocalDeltaT: midiOffset];
            else if (midiOffset < 0)
                [theOrch setLocalDeltaT: -midiOffset];
            [midiDev run];
        }
        else {
            mkRunAlertPanel(STR_SCOREPLAYER_ERROR, STR_CANT_OPEN_MIDI, STR_OK, STR_CANCEL, NULL);
        }
    }
    [theOrch run];
    [MKConductor startPerformance];     
}

-setTempoAdjustment:sender
{
    [MKConductor setDelegate:([[sender selectedCell] tag] == 0) ? self : nil];
    return self;
}

- (void) setMidiDriverName: (id) sender
{
    NSEnumerator *midiDevEnumerator = [midis objectEnumerator];
    MKMidi *midiDev;

    while ((midiDev = [midiDevEnumerator nextObject])) {
        NSLog([midiDev driverName]);
//      [midiDev close];
//      [midiDev release];
//      midiDev = [MKMidi midiOnDevice: [driverPopup titleOfSelectedItem]];
//      [midiDev retain];
    }
}

static id localIconImage(NSString *s)
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

    if (inited++)
        return;
    mySelf = self;
    saveFileExtensions = [[NSArray alloc] initWithObjects:
        @"score", @"playscore",@"midi", @"snd", @"snd",nil];
    fileIcons = [[NSArray alloc] initWithObjects:
        @"ScorePlayerDoc", @"ScorePlayerDoc2", @"Midi", @"Sound", @"Sound",nil];
    /* These are the class names */
    soundOutputTagToName = [[NSArray alloc] initWithObjects:
      @"",@"StealthDAI2400",@"SSAD64x",@"ArielProPort",@"DSPSerialPortDevice",nil];

    SSAD64xPanel = StealthDAI2400Panel = NeXTDACPanel = nil;
    playImage = localIconImage(@"play");
    [playButton setImage:playImage];
    [playButton display];
    openFileExtensions = [[MKScore fileExtensions] retain];  // accept both MIDI and Scorefiles.
    errorLog = [[ErrorLog alloc] init];
    [MKConductor setThreadPriority:1.0];
    [MKPartPerformer setFastActivation:YES]; /* We're not modifying parts while playing */
    setuid(getuid()); /* Must be after setThreadPriority. */
    [MKConductor useSeparateThread:YES];
//    [MKConductor setDelegate: self]; /* Default is no tempo adjustment */
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
   
    /* Create the tempo aminmator, but don't start it yet */
    tempoAnimator = [Animator newChronon: 0.0
	                   adaptation: 0.0				
		           target:     self
		           action:     @selector(animateTempo:)
		           autoStart:  NO
		           eventMask:  NSAnyEventMask];

    /* set up the playButton */
    stopImage = localIconImage(@"stop");
    playHImage = localIconImage(@"playH");
    [playButton setAlternateImage:playHImage];

    midis = [[NSMutableDictionary dictionaryWithCapacity: 8] retain]; // heaps!
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
    
    // initialise the device list for selecting MIDI drivers with the default.
    // [driverPopup removeAllItems];
    // [driverPopup addItemsWithTitles: [MKMidi getDriverNames]];
    // [driverPopup selectItemWithTitle: [[MKMidi midi] driverName]]; 

}

static BOOL setUpFile(NSString *workspaceFileName)
{
    int success;
    // Look for a score in a default place if this is the first time this has been run
    BOOL firstTime = [[NSUserDefaults standardUserDefaults] objectForKey: @"NSDefaultOpenDirectory"] == nil;
    
    if (!openPanel)
        openPanel = [NSOpenPanel new];    
    if (!workspaceFileName) {
	if (firstTime) {
            NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);

            success = [openPanel runModalForDirectory: [[libraryDirs objectAtIndex: 0]
                       stringByAppendingPathComponent: @"/Music/Scores"]
                                                 file: @"Examp1.score"
                                                types: openFileExtensions];
        }
        else if (dir) {
             success = [openPanel runModalForDirectory: dir
                                                  file: shortFileName 
                                                 types: openFileExtensions]; 
	     [dir release];
	     dir = nil;
	}
	else 
	  success = [openPanel runModalForTypes:openFileExtensions];
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
    if ([shortFileName isEqualToString:@"Jungle.score"] ||
        [shortFileName isEqualToString:@"Jungle.playscore"])
        tempoExponent = 1.3;  /* A real hack to make the demos play ok. */
    else
        tempoExponent = 1.5;
    firstTime = NO;
    return YES;
}

static void abortNow()
{
    NSEnumerator *midiDevEnumerator = [midis objectEnumerator];
    MKMidi *midiDev;

    if (PLAYING) {
	[MKConductor lockPerformance];
        while ((midiDev = [midiDevEnumerator nextObject])) {
            // This is tricky. allNotesOff sends note offs to all channels immediately,
            //  while abort will remove any pending events beyond time 0.
            [midiDev allNotesOff];
            [midiDev abort];
        }
        if(sampleInstrument)
            [sampleInstrument abort];
	[theOrch abort];
	[MKConductor finishPerformance];
	[MKConductor unlockPerformance];
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
        if ([openFileExtensions indexOfObject: aType] == NSNotFound)
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
    [[MKConductor defaultConductor] setTempo:desiredTempo];
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
    }
    else if (!isLate && messageFlashed) {
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
    [MKConductor lockPerformance];
    [[MKConductor defaultConductor] setTempo:desiredTempo];
    [MKConductor unlockPerformance];
    [tempoTextField setFloatValue:desiredTempo];
    if (wasLate || isLate)
       [tempoSlider setFloatValue:getUntempo(desiredTempo)];
    lastTempo = desiredTempo;
    return self;
}

- (void)setTempoFrom:sender	// currently called by slider only
{
    double val = [sender doubleValue];
    desiredTempo = getTempo(val);
    // LMS it's unclear if this was only able to happen when not playing due to earlier MK limitations.
//    if (!PLAYING) {  
	[[MKConductor defaultConductor] setTempo: desiredTempo];
	[tempoTextField setFloatValue:desiredTempo];
	lastTempo = desiredTempo;
//    }
}

- (void)setTimeCodeSynch:sender
{
    synchToTimeCode = [sender intValue];
    [timeCodeTextField setStringValue: (synchToTimeCode) ? @"Press Play, then start time code" : @"Press button above to enable time code"]; 
}

- (void)setTimeCodeSerialPort:sender
{
    /* 0 for portA, 1 for portB */
    timeCodeDevice = [[sender selectedCell] title]; 
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
    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidReverse)
                                            to: self
                                      argCount: 0];
    return self;
}

- conductorDidPause:sender
{
    NSEnumerator *midiDevEnumerator = [midis objectEnumerator];
    MKMidi *midiDev;

    [MKConductor sendMsgToApplicationThreadSel: @selector(showConductorDidPause) to: self argCount: 0];
    [synthInstruments makeObjectsPerformSelector: @selector(allNotesOff)];
    
    while ((midiDev = [midiDevEnumerator nextObject])) {
        [midiDev allNotesOff];
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
    if (flag)
        *returnBuf = [savePanel filename];
    soundFile = (saveType==SOUND_FILE) ? *returnBuf : NULL;

    return flag;
}

NSString *getPath(NSString *dir, NSString *name, NSString *ext)
     /* Construct a path given a file name, directory, and type */
{
    if (!dir || ![dir length]) dir = [NSHomeDirectory() retain];
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
    // TODO, the icons should probably be determined from the OS itself, not held within the app, since the
    // ScorePlayer has it's preferred file icon, but other programs may also.
    [accessoryView setImage:[NSImage imageNamed:[fileIcons objectAtIndex:type]]];
    [accessoryView setTitle:[fileTypes objectAtIndex:type]];
    [savePanel setRequiredFileType:[saveFileExtensions objectAtIndex:type]];
    return self;
}

- changeSaveType:sender
    /* Called by the accessory view (the Type button on the Save Panel */
{
    saveType++;
    if (saveType == SOUND_FILE && (!(capabilities & MK_soundfileOut)))
        saveType++;
    if (saveType > SOUND_FILE) saveType = SCORE_FILE; /* Wrap */
    [self setSaveType:saveType];
    return self;
}

- (void)saveScoreAs:sender
    /* Save the score, always prompting for a file name first.
       This is what the SaveAs: menu item calls. */
{
    if (PLAYING)
        abortNow();
    if (saveType == -1) 
	[self setSaveType: SCORE_FILE];
    if (!getSavePath(&outputFilePath,outputFileDir, outputFileName,
                     [saveFileExtensions objectAtIndex: saveType]))
	return;
    [outputFilePath retain];
    outputFileDir = [[outputFilePath stringByDeletingLastPathComponent] retain];
    outputFileName = [[outputFilePath lastPathComponent] retain];
    [self setSaveType: fileType(outputFilePath)];
    [outputFilePath release];
    outputFilePath = [getPath(outputFileDir, outputFileName,
                             [saveFileExtensions objectAtIndex: saveType]) retain];
    switch (saveType) {
    case SCORE_FILE: 
        [scoreObj writeScorefile:outputFilePath];
        break;
    case PLAYSCORE_FILE: 
        [scoreObj writeOptimizedScorefile:outputFilePath];
        break;
    case MIDI_FILE:
        [scoreObj writeMidifile:outputFilePath];
        break;
    case DSP_COMMANDS_FILE:
        /* Here we play the score, capturing the performance in the DSPCommands file. */
        DSPCommands = YES;
        [playButton performClick:self];
        break;
    case SOUND_FILE:
        /* Here we play the score, capturing the performance in the sound file. */
        writeData = YES;
        [playButton performClick:self];
        break;
    default:
        break;
    }
    [[NSCursor arrowCursor] set]; 
}

- (void)help:sender
 /* Display the help file formatted as HTML with the default handling application. */
{
    /* Look in the app wrapper */
    NSString *helpfile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"help.html"];
    if (![[NSWorkspace sharedWorkspace] openFile: helpfile])
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

