/*
 $Id$
 Defined In: The MusicKit
 
 Description:
 This is a command line scorefile player, with support for
 synthpatches and DSP serial I/O. See showUsage() below for details.
 
 Original Author: David A. Jaffe.
 
 Copyright 1988-1992, NeXT Inc.  All rights reserved.
 Release 4.0 modifications copyright CCRMA, Stanford University, 1993
 */
/* 
Modification history prior to commit to CVS:

  12/20/89/daj - Added support for optimized scorefiles.
  03/05/90/daj - Removed warning message for no synthPatch in -f mode.
  04/11/90/mtm - Added support for generating DSP Commands soundfile.
  07/1/90/daj -  Added Midi support and repeat count.
  07/26/90/daj - Removed nice() (on conditional compilation).  New MK
                 runs performance at a high-priority (equivalent to nice(-18)).
                 Added setThreadPriority:
  08/06/90/daj - Merged in midi and repeat features from CCRMA summer class
                 version.
  08/14/90/daj - Added setuid(getuid()) 
                 There's a definite bug in coordination between DSP and Midi.
                 The DSP generally starts too soon, which means (probably) that the 
                 sound-out buffers are not getting properly filled.
  10/04/92/daj - Changed directory (back) to be /LocalLibrary/Music/Scores.
  10/04/93/daj - Added -p switch.
  10/04/94/daj - Changed default channelNoteReceiver for midi parts from 1
                 to 0.  That way, channel information in the notes will
                 be preserved.  Added alternativeSamplingRate for Multisound.
 10/11/94/daj - Fixed bugs. Added -a switch, etc.
 */ 

#import <Foundation/Foundation.h>
#import <MusicKit/MusicKit.h>
#import <stdlib.h>
#import <stdio.h>

#define SCORE_DIR @"Music/Scores/"
#define SOUND_EXTENSION @"snd"

#if m68k
#define SOUND_OUT_PAUSE_BUG 1
#else
#define SOUND_OUT_PAUSE_BUG 0
#endif

#define  DEFAULT_SOUND 0
#define  NEXT_DACS 0
#define  DAI2400 1
#define  AD64x 2
#define  PROPORT 4
#define  GENERIC 3

static int soundOutType = DEFAULT_SOUND;
static MKOrchestra *anOrch = nil;

static BOOL quiet = NO;

static NSString *findFile(NSString *name, BOOL *midifile)
{
    NSArray *fileExtensions = [MKScore fileExtensions];
    NSArray *midifileExtensions = [MKScore midifileExtensions];
    NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    unsigned i, j;
    
    if (!name) {
	fprintf(stderr,"No file name specified.\n");
	exit(1);
    }
    if([[NSFileManager defaultManager] isReadableFileAtPath: name]) {
        *midifile = [midifileExtensions containsObject: [name pathExtension]];
        return name;
    }
    for(i = 0; i < [libraryDirs count]; i++) {
        NSString *directoryQualifiedName;
        directoryQualifiedName = [[[libraryDirs objectAtIndex: i] stringByAppendingPathComponent: SCORE_DIR]
                                        stringByAppendingPathComponent: name];
        for(j = 0; j < [fileExtensions count]; j++) {
            NSString *fullyQualifiedName;
            NSString *possibleFileExt = [fileExtensions objectAtIndex: j];
            fullyQualifiedName = [directoryQualifiedName stringByAppendingPathExtension: possibleFileExt];
            if([[NSFileManager defaultManager] isReadableFileAtPath: fullyQualifiedName]) {
                *midifile = [midifileExtensions containsObject: possibleFileExt];
                return fullyQualifiedName;
            }
        }
    }
    return nil;
}

void showUsage(void)
{
    static const char * const help = 
    "\n\
The playscore program performs a scorefile or midifile by playing it on the DSP\n\
and/or MIDI. It's invoked as:\n\n\
playscore [options] <scorefile|midifile>\n\n\
If the specified file isn't an absolute path, the program searches for\n\
it in the following directories, in order:\n\n\
The current working directory\n\
%s\n\
The '.playscore' or '.score' extension, which identify a file as a \n\
scorefile, or '.midi', which identifies a file as a MIDI file,\n\
can be omitted -- the program will append it for you. If you\n\
leave off the extension and more than one '.playscore', '.score' or '.midi'\n\
versions are present, the '.playscore' version is chosen.\n\n\
The following options are recognized: \n\
-a               Open all DSPs (Intel architecture only.)\n\
-c  <soundfile>  Write the DSP commands output as the named soundfile.\n\
    The '.%s' extension is automatically appended to\n\
    the file name.\n\
-d               Debug mode. This leaves room for the Ariel Bug56\n\
    debugger on the DSP.\n\
-f               Fast mode -- uses a ScorefilePerformer.\n\
    Usually, playscore reads the entire scorefile before\n\
    playing it. By using a ScorefilePerformer, the\n\
    program can read the file on the fly. The\n\
    performance begins sooner but puts a heavier demand\n\
    on the main CPU than does the default.\n\
-p               Persistent mode.  Waits for DSP if it's in use.\n\
-q               Quiet mode. All print-out is surpressed.\n\
-r  <count>      Repeat performance the specified number of times.\n\
-s  <devicename> Send sound to DSP serial port. <name> should be the name \n\
    of a device that connects to serial port.  Currently \n\
    supported devices are SSAD64x (Singular Solutions), \n\
    StealthDAI2400, ArielProPort and GENERIC.\n\
-w  <soundfile>  Write the DSP sample output as the named soundfile.\n\
    The '.%s' extension is automatically appended to\n\
    the file name.\n\
    For futher details, see the playscore MAN page.\n\
    \n";
    NSMutableString *searchedDirectories = [NSMutableString stringWithString: @""];
    NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    unsigned i;

    for(i = 0; i < [libraryDirs count]; i++)
	[searchedDirectories appendFormat: @"   %@\n", [[libraryDirs objectAtIndex: i] stringByAppendingPathComponent: SCORE_DIR]];

    fprintf(stderr, help, [searchedDirectories cString], [SOUND_EXTENSION cString], [SOUND_EXTENSION cString]);
}

void setSoundOutDevice(char *optarg)
{
    NSLog(@"To be implemented\n");
}

double setUpFromScoreInfo(id scoreInfo,double *midiOffset)
/* returns srate */
{
    double samplingRate = 0;
    const char *msg = NULL;
    int midiOffsetPar;
    *midiOffset = 0;
    if (scoreInfo) {  
	if ([scoreInfo isParPresent: MK_headroom])
	    [MKOrchestra setHeadroom: [scoreInfo parAsDouble: MK_headroom]];
	if ([scoreInfo isParPresent: MK_alternativeSamplingRate] &&
	    [anOrch prefersAlternativeSamplingRate])
	    samplingRate = [scoreInfo parAsDouble: MK_alternativeSamplingRate];
	else if ([scoreInfo isParPresent: MK_samplingRate]) 
	    samplingRate = [scoreInfo parAsDouble: MK_samplingRate];
	if ([scoreInfo isParPresent: MK_tempo]) {
	    double tempo = [scoreInfo parAsDouble: MK_tempo];
	    [[MKConductor defaultConductor] setTempo: tempo];
	}
	midiOffsetPar = [MKNote parTagForName: @"midiOffset"];
	if ([scoreInfo isParPresent: midiOffsetPar])
	    *midiOffset = [scoreInfo parAsDouble: midiOffsetPar];
    }
    if (![anOrch supportsSamplingRate: samplingRate]){
	if (samplingRate != 0)
	    msg = "Requested sampling rate not supported by serial port device.";
	samplingRate = [anOrch defaultSamplingRate];
    }
    if (msg && !quiet)
	fprintf(stderr,"%s\n",msg);
    [MKOrchestra setSamplingRate: samplingRate];
#if SOUND_OUT_PAUSE_BUG
    if (samplingRate == 22050)
	*midiOffset +=  .36363636363636/8.0;
    else 
	*midiOffset += .181818181818181/8.0;
#else
    if (samplingRate == 22050)
	*midiOffset +=  .36363636363636;
    else 
	*midiOffset += .181818181818181;
#endif
    /* Note: there is a .1 second indeterminacy (in the 22khz case) due to not knowing where
	we are in soundout buffering. Using more, but smaller buffers would solve this. */
    return samplingRate;
}


static BOOL isMidiClassName(NSString *className)
{
    return (className && ([className isEqualToString: @"midi"]  ||
                          [className isEqualToString: @"midi1"] ||
                          [className isEqualToString: @"midi0"]));
}

#if SOUND_OUT_PAUSE_BUG

static BOOL checkForMidi(id obj)
{
    BOOL weGotScore;
    id subobjs;
    int i,cnt;
    id info;
    char *sp;
    
    if (weGotScore = [obj isKindOf: [MKScore class]])
	subobjs = [obj parts];
    else 
	subobjs = [obj noteSenders];
    if (!subobjs)
	return NO;
    cnt = [subobjs count];
    for (i = 0; i < cnt; i++) {
	if (weGotScore)
	    info = [[subobjs objectAtIndex: i] info];
	else 
	    info = [obj infoForNoteSender: [subobjs objectAtIndex: i]];
	if ([info isParPresent: MK_synthPatch] &&
	    (isMidiClassName([info parAsStringNoCopy: MK_synthPatch]))) {
	    [subobjs free];
	    return YES;
	}
    }
    [subobjs free];
    return NO;
}

#endif

static void nullErrorHandler(NSString *msg)
{
    NSLog(msg);
}

static int openOrch(int orchIndex, BOOL waitForIt, BOOL quiet, BOOL allDSPs)
{
    static int warnedAlready[16] = {0};
    MKOrchestra *theOrch = [MKOrchestra nthOrchestra: orchIndex];
    
    if (!theOrch)
	return -1;
    if (warnedAlready[orchIndex])
	return -1;
    if (![theOrch open]) {
	if (waitForIt) {
	    if (!quiet)
		fprintf(stderr,"Waiting for DSP%d...\n", [theOrch orchestraIndex]);
	    for (;;) {
		// sleep(3); 
		if ([theOrch open])
		    return 0;
	    }
	} 
	else {
	    if (!quiet)
		fprintf(stderr,"Can't open DSP%d.\n", [theOrch orchestraIndex]);
	    if (!allDSPs)
		exit(1);
	    warnedAlready[orchIndex] = 1;
	    return -1;
	}
    }
    return 0;
}

int main(int argc, char *argv[])
{
    int i, repeatCount, repeat, optch;
    NSString *inputFile;
    int orchPar;
    NSMutableArray *instruments = nil;
    NSData *aStream;
    double midiOffset;
    BOOL weGotAnOpenOrch = NO;
    BOOL allDSPs = NO;
    BOOL onTheFly = NO;
#if SOUND_OUT_PAUSE_BUG
    BOOL weGotMidi = NO;
#endif
    BOOL debugIt = NO;
    BOOL waitForIt = NO;
    BOOL midifile = NO;    // reading a MIDI file rather than a scorefile
    MKMidi *midis[2];
    int orchIndex = 0;
    NSString *outputFile = nil;
    NSString *commandsFile = nil;
    MKPerformer *aPerformer = nil;
    double samplingRate;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    orchPar = [MKNote parTagForName: @"orchestraIndex"];
    
    [MKConductor setThreadPriority: 1.0];
    setuid(getuid());   
    repeatCount = 1;
    samplingRate = 22050;
    
    if (argc == 1) {
        showUsage();
        exit(1);
    }
    
    while ((optch = getopt(argc, argv, "c:dn:afpqr:s:t:vw:h")) != -1) {
        switch(optch) {
	    case 'c':
		commandsFile = [[NSString stringWithCString: optarg] stringByAppendingPathExtension: SOUND_EXTENSION];
		break;
	    case 'd':
		debugIt = YES;
		break;
	    case 'n':
		orchIndex = atoi(optarg);
		break;
	    case 'a':
		allDSPs = YES;
		break;
	    case 'f':
		onTheFly = YES;
		break;
	    case 'p':
		waitForIt = YES;
		break;
	    case 'q':
		MKSetErrorProc(nullErrorHandler);
		quiet = YES;
		break;
	    case 'r':
		repeatCount = atoi(optarg);
		break;
	    case 's':
		soundOutType = GENERIC;
		setSoundOutDevice(optarg);
		break;
	    case 't':
		MKSetTrace(atoi(optarg));
		break;
	    case 'v':
		DSPEnableErrorFile("/dev/tty");
		break;
	    case 'w':
		outputFile = [[NSString stringWithCString: optarg] stringByAppendingPathExtension: SOUND_EXTENSION];
		break;
	    case 'y':  // override synthPatch for given part.
		       // TODO NSDictionary of optarg, parsed into part "=" synthPatch
		fprintf(stderr, "synthPatch assignment: %s\n", optarg);
		break;
	    case 'h':
	    default:
		showUsage();
		exit(1);
	}
    }
    
    anOrch = [[MKOrchestra orchestraOnDSP: orchIndex] retain];
    if ((soundOutType != DEFAULT_SOUND) && 
	!([anOrch capabilities] & MK_nextCompatibleDSPPort)) {
	fprintf(stderr, "A NeXT-compatible DSP port is not supported by this hardware configuration.\n");
	exit(1);
    }
    
    inputFile = [NSString stringWithCString: argv[argc-1]];
    for (repeat = 0; repeat < repeatCount; repeat++) {
	if (!onTheFly) {
	    if (repeat == 0) {
		MKScore *aScore = [MKScore new];
                NSString *scoreOrMidiFileName = findFile(inputFile, &midifile);
		if (scoreOrMidiFileName != nil && !quiet)
                    fprintf(stderr,"playscore reading %s...\n", [inputFile cString]);
                if(midifile) {
                    if (![aScore readMidifile: scoreOrMidiFileName] && !quiet) {
                        fprintf(stderr, "Fix midifile errors and try again.\n");
                        exit(1);
                    }
                }
                else {
                    if (![aScore readScorefile: scoreOrMidiFileName] && !quiet) {
                        fprintf(stderr, "Fix scorefile errors and try again.\n");
                        exit(1);
                    }
                }
#if SOUND_OUT_PAUSE_BUG
		weGotMidi = checkForMidi(aScore);
#endif
		aPerformer = [MKScorePerformer new];
		[(MKScorePerformer *) aPerformer setScore:aScore];
		samplingRate = setUpFromScoreInfo([aScore infoNote], &midiOffset);
		if (!quiet)
		    fprintf(stderr,"...done\n");
	    }
	    [aPerformer activate]; 
	}
	else { /* on the fly */
            aStream = [NSData dataWithContentsOfFile: findFile(inputFile, &midifile)];
            if(midifile) {
                // TODO once we have a MKMidifilePerformer class we can do this.
                fprintf(stderr, "Unable to play MIDI files on the fly, exitting.\n");
                exit(1);
            }
	    if (repeat == 0) {
		aPerformer = [MKScorefilePerformer new];                  
	    }
	    else
                [(MKScorefilePerformer *) aPerformer releaseNoteSenders];
            [(MKScorefilePerformer *) aPerformer setStream: aStream];
	    [aPerformer activate]; 
#if SOUND_OUT_PAUSE_BUG
	    weGotMidi = checkForMidi(aPerformer);
#endif
            setUpFromScoreInfo([(MKScorefilePerformer *) aPerformer infoNote], &midiOffset);
	}
	if (repeat == 0) {
	    if (debugIt)
		[anOrch setDebug: YES];
	    if (outputFile)
		[anOrch setOutputSoundfile: outputFile];
	    if (commandsFile)
		[anOrch setOutputCommandsFile: commandsFile];
	    [anOrch setSoundOut: !outputFile];
#if SOUND_OUT_PAUSE_BUG
	    if (weGotMidi)
                [anOrch setFastResponse: YES];
#endif
	    midis[0] = nil;
	    midis[1] = nil;
	}
	if (!onTheFly) {  
	    int partCount, synthPatchCount, voices, midiChan, whichMidi;
	    NSString *className;
	    NSArray *partPerformers;
            MKPartPerformer *partPerformer;
            MKNote *partInfo;
            MKPart *aPart;
            MKInstrument *anIns;
	    id synthPatchClass;
	    
            partPerformers = [(MKScorePerformer *) aPerformer partPerformers];
	    partCount = [partPerformers count];
	    if (repeat == 0) {
		instruments = [NSMutableArray arrayWithCapacity: partCount];
	    }
	    for (i = 0; i < partCount; i++) {
		partPerformer = [partPerformers objectAtIndex: i];
		aPart = [partPerformer part]; 
		partInfo = [aPart infoNote];      
		if (!partInfo) {               
		    continue;
		}		
		if (allDSPs) {
		    if ([partInfo isParPresent: orchPar]) 
                        orchIndex = [partInfo parAsInt: orchPar];
		    else
                        continue;
		}
		if (![partInfo isParPresent: MK_synthPatch]) {
                    if(midifile)
                        [partInfo setPar: MK_synthPatch toString: @"midi"];
                    else
                        continue;
		}
		className = [partInfo parAsStringNoCopy: MK_synthPatch];
		if (isMidiClassName(className)) {
		    if (repeat == 0) {
			midiChan = [partInfo parAsInt: MK_midiChan];
			if ((midiChan == MAXINT) || (midiChan > 16))
                            midiChan = 0;
			if ([className isEqualToString: @"midi"])
                            className = @"midi0";
                        if ([className isEqualToString: @"midi1"])
                            whichMidi = 1;
			else
                            whichMidi = 0;
			if (midis[whichMidi] == nil) {
                            midis[whichMidi] = [[MKMidi midiOnDevice: className] retain];
                            if(midis[whichMidi] == nil) {
                                fprintf(stderr, "No MIDI devices of class %s present, unable to play.\n", [className cString]);
                                continue;
                            }
                        }
			[[partPerformer noteSender] connect:
                            [midis[whichMidi] channelNoteReceiver: midiChan]];
		    }
		}
		else { /* It's a DSP part */
		    synthPatchClass = [MKSynthPatch findPatchClass: className];
		    if (!synthPatchClass) {          
			if (!quiet)
			    fprintf(stderr,"MKSynthPatch %s cannot be loaded into program.\n", [className cString]);
			continue;
		    }
		    if ([[MKOrchestra nthOrchestra: orchIndex] deviceStatus] != MK_devOpen) {
			if (openOrch(orchIndex, waitForIt, quiet, allDSPs) == -1)
			    continue;			
		    }
		    weGotAnOpenOrch = YES;
		    if (repeat == 0) {
                        [instruments insertObject:  anIns = [MKSynthInstrument new] atIndex: i];      
			[[partPerformer noteSender] connect: [anIns noteReceiver]];
		    }
                    [(MKSynthInstrument *)(anIns = [instruments objectAtIndex: i])
                        setSynthPatchClass: synthPatchClass
				 orchestra: [[MKOrchestra nthOrchestra: orchIndex] class]];
		    if (![partInfo isParPresent: MK_synthPatchCount])
                        continue;         
		    voices = [partInfo parAsInt: MK_synthPatchCount];
		    synthPatchCount =
                        [(MKSynthInstrument *) anIns setSynthPatchCount: voices patchTemplate:
			    [synthPatchClass patchTemplateFor: partInfo]];
		    /* Ignore warning regarding above since target IS the factory */
                    if (repeat == 0 && synthPatchCount < voices && !quiet)
                        fprintf(stderr,
				"Could only allocate %d instead of %d %ss for %s\n",
				synthPatchCount, voices,
				[[synthPatchClass name] cString], [MKGetObjectName(aPart) cString]);
		}
	    }
	}
	else {  /* on the fly */
	    int partCount, synthPatchCount, voices, midiChan, whichMidi;
	    NSString *className;
	    NSArray *noteSenders;
	    MKNote *partInfo;
	    MKSynthInstrument *anIns;
	    MKNoteSender *aNoteSender;
	    id synthPatchClass;
	    
	    noteSenders = [aPerformer noteSenders];
	    partCount = [noteSenders count];
	    for (i = 0; i < partCount; i++) {
		aNoteSender = [noteSenders objectAtIndex: i];
		partInfo = [(MKScorefilePerformer *) aPerformer infoNoteForNoteSender: aNoteSender];
		if (!partInfo) {               
		    continue;
		}		
		if (allDSPs) {
		    if ([partInfo isParPresent: orchPar])
			orchIndex = [partInfo parAsInt: orchPar];
		    else
			continue;
		} 
		if (![partInfo isParPresent: MK_synthPatch]) 
		    continue;         
		className = [partInfo parAsStringNoCopy: MK_synthPatch];
		if (isMidiClassName(className)) {
		    if (repeat == 0) {
			midiChan = [partInfo parAsInt: MK_midiChan];
			if ((midiChan == MAXINT) || (midiChan > 16))
			    midiChan = 0;
			if ([className isEqualToString: @"midi"])
			    className = @"midi0";
			if ([className isEqualToString: @"midi1"])
			    whichMidi = 1;
			else
			    whichMidi = 0;
			if (midis[whichMidi] == nil) {
			    midis[whichMidi] = [MKMidi midiOnDevice: className];
			    if(midis[whichMidi] == nil) {
				fprintf(stderr, "No MIDI devices of class %s present, unable to play.\n", [className cString]);
				continue;
			    }
			}
			[aNoteSender connect: [midis[whichMidi] channelNoteReceiver: midiChan]];
		    }
		}
		else { /* dsp */
		    synthPatchClass = [MKSynthPatch findPatchClass: className];
		    if (!synthPatchClass) {          
			if (!quiet)
			    fprintf(stderr, "Class %s cannot be loaded into program.\n",
				    [className cString]);
			continue;
		    }
		    if ([[MKOrchestra nthOrchestra: orchIndex] deviceStatus] != MK_devOpen) {
			if (openOrch(orchIndex, waitForIt, quiet, allDSPs) == -1)
			    continue;			
		    }
		    weGotAnOpenOrch = YES;
		    if (repeat == 0) {
			instruments = [NSMutableArray arrayWithCapacity: partCount];
			[instruments insertObject: [MKSynthInstrument new] atIndex: i];      
		    }
		    anIns = (MKSynthInstrument *) [instruments objectAtIndex: i];
		    [aNoteSender connect: [anIns noteReceiver]];
		    [anIns setSynthPatchClass: synthPatchClass 
				    orchestra: [[MKOrchestra nthOrchestra: orchIndex] class]];
		    if (![partInfo isParPresent: MK_synthPatchCount])
			continue;         
		    voices = [partInfo parAsInt: MK_synthPatchCount];
		    synthPatchCount = 
			[anIns setSynthPatchCount: voices patchTemplate:
			    [synthPatchClass patchTemplateFor: partInfo]];
		    if (repeat == 0 && synthPatchCount < voices) 
			if (!quiet)
			    fprintf(stderr, "Could only allocate %d instead of %d %ss for %s\n",
				    synthPatchCount, voices, [[synthPatchClass name] cString],
				    [MKGetObjectName(aNoteSender) cString]);
		}
	    }
	}
	MKSetDeltaT(1.0);              
	[MKConductor setClocked: NO];     
	for (i = 0; i < 2; i++) 
	    [midis[i] openOutputOnly];
	if (weGotAnOpenOrch && allDSPs) 
	    [MKOrchestra open]; /* Open any remaining dsps */
#if 1
	for (i = 0; i < 2; i++) 
	    if (midiOffset > 0) 
		[midis[i] setLocalDeltaT: midiOffset];
	    else if (midiOffset < 0) {
		int i;
		for (i = 0; i < [MKOrchestra DSPCount]; i++)
		    [[MKOrchestra nthOrchestra: i] setLocalDeltaT: -midiOffset];
	    }
#endif
	if (!quiet) {
	    if (commandsFile)
		fprintf(stderr,"writing to %s...\n", [commandsFile cString]);
	    if (outputFile)
		fprintf(stderr,"writing to %s...\n", [outputFile cString]);
	    else
		fprintf(stderr,"playing...\n");
	}
	for (i = 0; i < 2; i++)
	 [midis[i] run];
	if (weGotAnOpenOrch)
	    [MKOrchestra run];                  
	[MKConductor startPerformance];  
	// sleep(10000);
	if (weGotAnOpenOrch)
	    [MKOrchestra close];                
	for (i = 0; i < 2; i++)
	    [midis[i] close];
	if (!quiet)
	    fprintf(stderr,"...done\n");
    }
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}


