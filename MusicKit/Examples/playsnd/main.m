////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    playsnd - a simple SndKit streaming architecture exerciser / sound player
//
//  Original Author: SKoT McDonald <skot@tomandandy.com>
//
//  Contributors: Stephen Brandon
//
//  Copyright (c) 2001-2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>
#import <unistd.h>

// Version info
#define V_MAJ  1
#define V_MIN  1
#define V_TINY 1

#define USE_SNDEXPT 0

static int iReturnCode = 0;

////////////////////////////////////////////////////////////////////////////////
// printError
////////////////////////////////////////////////////////////////////////////////

void printError(char* msg, int iPossibleReturnCode)
{
    fprintf(stderr,"%s\n",msg);
    if (iReturnCode == 0)
	iReturnCode = iPossibleReturnCode;
}

////////////////////////////////////////////////////////////////////////////////
// ShowHelp
////////////////////////////////////////////////////////////////////////////////

void showHelp(const char *absolutePath)
{
    const char *commandLineName = rindex(absolutePath, '/');

    if(commandLineName == NULL)
        commandLineName = absolutePath;
    else
        commandLineName = commandLineName + 1;
    printf("usage: %s [options] <soundfile>\n", commandLineName);
    printf("\nOptions:\n"\
           "  -O N   offset playback time by N seconds (can be non-integral)\n"\
           "  -d N   playback duration, in samples\n"\
           "  -b N   playback start point, in samples\n"\
           "  -r     use reverb (freeverb) module\n"\
           "  -v     show author/version info\n"\
           "  -h     show this help\n"\
           "  -t     turn on time information output\n"\
           "  -R f   relative playback rate (floating point)\n"\
           "  -S     shoutcast as MP3 stream to an icecast server running on local host\n"\
           "  -a A   shoutcast server address (either form: abc.com or 127.0.0.1)\n"\
           "  -P N   shoutcast port number\n"\
           "  -p A   shoutcast server password\n");
         /*
           " -o N  offset playback time by N samples\n"\
           " -E N  playback duration, in seconds\n"\
	 */
}

////////////////////////////////////////////////////////////////////////////////
// main
////////////////////////////////////////////////////////////////////////////////

int main (int argc, const char * argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL   bTimeOutputFlag    = FALSE;
    BOOL   bMP3Shoutcast      = FALSE;
    BOOL   useReverb          = FALSE;
    BOOL   showInfo           = FALSE;
    long   startTimeInSamples = 0;
    double durationInSamples  = -1;
    float  timeOffset         = 0.0f;
    double deltaTime = 1.0;
    int    i = 1;
    const  char  *soundFileName       = NULL;
    NSString *shoutcastServerAddress  = [SndAudioProcessorMP3Encoder defaultServerAddress];
    NSString *shoutcastSourcePassword = [SndAudioProcessorMP3Encoder defaultSourcePassword];
    int       shoutcastPortNumber     = [SndAudioProcessorMP3Encoder defaultSourcePort];
#if USE_SNDEXPT
    Snd *s = [SndExpt new];
#else
    Snd *s = [Snd new];
#endif
    NSString          *filename = nil, *extension = nil;
    NSFileManager     *fm       = [NSFileManager defaultManager];
    BOOL               bFileExists = FALSE, bIsDir = FALSE;

    if (argc == 1) {
        showHelp(argv[0]);
        return 0;
    }

    for (i = 1; i < argc; i++) {
	if (argv[i][0] == '-') {
	    switch (argv[i][1]) {
		case 'O':
		    i++;
		    if (i < argc) timeOffset = atof(argv[i]);
		    else          printError("No time offset in seconds value given after option -O",-1);
		    break;
		case 't': bTimeOutputFlag = TRUE;                       break;
		case 'r': useReverb       = TRUE;                       break;
		case 'R':
		    i++;
		    if (i < argc) deltaTime = atof(argv[i]);
		    else          printError("No relative playback rate given after option -R",-1);
		    break;
		case 'v': printf("playsnd %i.%i.%i  skot@tomandandy.com  Oct 2 2001\n",V_MAJ,V_MIN,V_TINY); break;
		case 'h': showHelp(argv[0]); break;
		case 'd':
		    i++;
		    if (i < argc) durationInSamples = atoi(argv[i]);
		    else          printError("No end time in samples given after option -e",-1);
		    break;
		case 'b':
		    i++;
		    if (i < argc) startTimeInSamples = atoi(argv[i]);
		    else          printError("No start time in samples given after option -b",-1);
		    break;
		case 'S':
		    bMP3Shoutcast = TRUE;
		    printf("Shoutcasting as MP3 stream to server on localhost!\n");
		    break;
		case 'a': // mp3 server address
		    [shoutcastServerAddress release];
		    shoutcastServerAddress = [NSString stringWithCString: argv[++i]];
		    break;
		case 'P': // mp3 server source port number
		    shoutcastPortNumber = atoi(argv[++i]);
		    break;
		case 'p': // mp3 server source password
		    [shoutcastSourcePassword release];
		    shoutcastSourcePassword = [NSString stringWithCString: argv[++i]];
		    break;
		case 'I': showInfo = TRUE; break;
		default: fprintf(stderr, "Ignoring unrecognized option -%c\n",argv[i][1]);
	    }
	}
	else if (soundFileName == NULL)
	    soundFileName = argv[i];
	else {
	    printf("Regrettably, playsnd doesn't support playing multiple files yet (no tech reason why not...).\n");
	    printf("  This file will not be played: %s\n",argv[i]);
	}
    }
    if (soundFileName == NULL)
	printError("No soundfile name given", -2);
    
    // Reason why we finally exit here instead of eariler - allow all error msgs to
    // be displayed before exit
    if (iReturnCode != 0)
	return iReturnCode;
    
    // Finally: do the actual sound playing!

    filename  = [fm stringWithFileSystemRepresentation: soundFileName
						length: strlen(soundFileName)];
    extension = [filename pathExtension];

    bFileExists = [fm fileExistsAtPath: filename isDirectory: &bIsDir];
    if (!bFileExists || bIsDir) {
        NSArray *ext = [Snd soundFileExtensions];
        int i, c = [ext count];

        for (i = 0; i < c; i++) {
	    NSString *temp = [filename stringByAppendingPathExtension: [ext objectAtIndex: i]];
	    
	    if ([fm fileExistsAtPath: temp]) {
		bFileExists = TRUE;
		filename = temp;
		break;
	    }
        }
    }

    if (![fm fileExistsAtPath: filename]) {
        printError("Can't find sound file",-2);
    }
    else {
        int waitCount = 0;
        int maxWait;
        SndPlayer  *player = [SndPlayer defaultSndPlayer];
        SndAudioProcessorMP3Encoder *mp3enc = nil;
//        SndAudioProcessorRecorder *rec = nil;
//        long b1, b2;
	
//        b1 = clock();
        [s readSoundfile: filename];
#if !USE_SNDEXPT
        [s convertToFormat: SND_FORMAT_FLOAT];
#endif
	/*
	    s = [[Snd alloc] initWithFormat: SND_FORMAT_FLOAT
			    channels: 2
			      frames: 100000
			samplingRate: 44100];
	 {
	     int i;
	     float *f = [s data];
	     for (i=0;i<200000;i+=2) {
		 f[i]   = 0.5 + 0.25 * sin (100 *  i / 100000.0);
		 f[i+1] = -0.5 - 0.25 * cos (100 *  i / 100000.0);
	     }
	 }
	 */
        if (showInfo) {
	    NSLog([s description]);
	    [s release];
	    return 0;
        }
	
//        b2 = clock();
//        printf("Readtime: %li\n",b2-b1);

        if (durationInSamples == -1)
	    maxWait = [s duration] + 5 + timeOffset + 1;
        else
	    maxWait = durationInSamples / [s samplingRate] + 5 + 1;

        maxWait /= deltaTime;

        [player setRemainConnectedToManager: FALSE];

        if (useReverb) {
            SndAudioProcessorReverb *rv = [[[SndAudioProcessorReverb alloc] init] autorelease];
            [rv setActive: TRUE];
            [[player audioProcessorChain] addAudioProcessor:rv];
        }
#if 0
        {
	    rec = [SndAudioProcessorRecorder new];
	    [rec setActive: TRUE];
	    [[player audioProcessorChain] addAudioProcessor:rec];
	    [rec startRecordingToFile: @"/Local/Users/skot/test.wav"
		withDataFormat: SND_FORMAT_LINEAR_16
		  channelCount: 2
		  samplingRate: 44100];
        }
#endif
        if (bMP3Shoutcast) {
	    mp3enc = [[SndAudioProcessorMP3Encoder alloc] init];
	    [mp3enc setShoutcastServerAddress: shoutcastServerAddress
				  port: shoutcastPortNumber
			      password: shoutcastSourcePassword];
	    if ([mp3enc connectToShoutcastServer]) {
		[[player audioProcessorChain] addAudioProcessor: [mp3enc autorelease]];
		[mp3enc setActive: TRUE];
	    }
	    else {
		bMP3Shoutcast = FALSE;
		printf("Couldn't connect to MP3 reflection server on %s:%i with password [%s]\n", [[mp3enc serverAddress] cString],
	 [mp3enc serverPort],
	 [[mp3enc serverPassword] cString]);
		[mp3enc release];
		mp3enc = nil;
	    }
        }
        {
	    SndPerformance *perf;
	    perf = [s playInFuture: timeOffset
		beginSample: startTimeInSamples
		sampleCount: durationInSamples];
	    [perf setDeltaTime: deltaTime];
        }
        if (bTimeOutputFlag) printf("Sound duration: %.3f\n",[s duration]);
	
        // Wait for stream manager to go inactive, signalling the sound has finished playing
        while ([[SndStreamManager defaultStreamManager] isActive] && waitCount < maxWait) {
	    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	    waitCount++;
	    if (bTimeOutputFlag)  printf("Time: %i\n",waitCount);
        }
#if 0
        [rec stopRecording];
        [rec closeRecordFile];
#endif
        if (waitCount >= maxWait) {
	    fprintf(stderr,"Aborting wait for stream manager shutdown - taking too long.\n");
	    fprintf(stderr,"(snd dur:%.3f, maxwait:%i)\n",[s duration],maxWait);
        }
        if (bMP3Shoutcast)
	    [mp3enc disconnectFromShoutcastServer];
    }
    [pool release];
    return iReturnCode;
}

////////////////////////////////////////////////////////////////////////////////
