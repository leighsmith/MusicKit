/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    MKMixerInstrument mixes soundfiles based on a score description of the mix.
    It allows setting the amplitude scaling of each soundfile and to
    change that scaling over time by applying an amplitude envelope. It
    allows resampling (change the pitch of) a file.  It also allows
    you to specify that only a portion of a file be used in the mix.
    There is no limit to the number of soundfiles that may be mixed
    together. Also, the same soundfile may be mixed several times and may
    overlap with itself.  The soundfiles may have different sampling rates
    and different formats.  However, the output must be 16 bit linear.
    The mix is done on the main CPU, rather than the DSP.  The more files
    you mix, the longer it will take the program to run.  Note also that
    if you mix many large files, you will need a fair degree of swap
    space--keep some room free on the disk off of which you booted.

    MKMixerInstrument is also an illustration of how to make your own MusicKit
    MKInstrument subclass to "realize MKNotes" in some novel fashion. In this
    case, MKNotes are soundfile mix specifications. They are "realized" by
    being mixed into the output file.

    To make your own custom version of mixsounds, add code where indicated
    below by "###"

  Original Author: David A. Jaffe, with Michael McNabb adding the
    enveloping and pitch transposition, the latter based on code
    provided by Julius Smith. Incorporation into the MusicKit framework, conversion
    to OpenStep and the SndKit by Leigh M. Smith.

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001 The MusicKit Project.
*/
/*
Modification history:

 $Log$
 Revision 1.14  2002/09/24 21:48:45  leighsmith
 Simplified combined pointer assignments and increments to remove gcc 3.1 warnings

 Revision 1.13  2002/04/03 03:59:41  skotmcdonald
 Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

 Revision 1.12  2002/03/06 19:02:05  leighsmith
 Added extra NULL parameter to match new prototype for resample()

 Revision 1.11  2002/01/29 16:21:49  sbrandon
 fixed small retain/release problem (theoretical crasher)

 Revision 1.10  2001/09/20 01:41:37  leighsmith
 Typed parameters

 Revision 1.9  2001/09/06 21:27:47  leighsmith
 Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

 Revision 1.8  2001/08/30 19:07:17  leighsmith
 upgraded parName to parTagForName methods

 Revision 1.7  2000/05/13 17:21:11  leigh
 Better variable naming

 Revision 1.6  2000/05/06 02:34:33  leigh
 Added M_PI if it isn't there

 Revision 1.5  2000/04/26 01:23:19  leigh
 Renamed to more meaningful samplesToMix ivar

 Revision 1.4  2000/04/22 20:14:58  leigh
 Verified sound was non-nil before releasing...duh

 Revision 1.3  2000/04/20 21:34:53  leigh
 Replaced SFInfoStruct with expanded MKSamples, plugged memory leaks

 Revision 1.2  2000/04/17 22:55:32  leigh
 Added debugging information attempting to find malloc problem

 Revision 1.1  2000/04/16 21:18:36  leigh
 First version using SndKit incorporated into the MusicKit framework

*/

#import "_musickit.h"
#import <SndKit/SndKit.h>
#import <SndKit/SndResample.h>
#import "MKMixerInstrument.h"

// Dear WinNT doesn't know about PI, stolen from MacOSX-Servers math.h definition
#ifndef M_PI
#define M_PI            3.14159265358979323846  /* pi */
#endif

@implementation MKMixerInstrument /* See MKMixerInstrument.h for instance variables */

#define BUFFERSIZE (BUFSIZ * 8)   /* size (in samples per frame) of temporary mixing buffer */

static int timeScalePar = 0,timeOffsetPar = 0;
/* ### If you add a parameter, put in a declaration here */

enum {applyEnvBefore = 0,applyEnvAfter = 1,scaleEnvToFit = 2};

+ (void) initialize
{
    timeOffsetPar = [MKNote parTagForName:@"timeOffset"];
    timeScalePar = [MKNote parTagForName:@"ampEnvTimeScale"];
    /* ### Add a par int initialization statement here. */
}

-init
{
    [super init];
    defaultAmp = 1.0;
    defaultFreq0 = 440;
    defaultFreq1 = 440;
    defaultEnvelope = nil;
    defaultTimeScale = applyEnvBefore;
    /* ### Add instance variables in MixInstrument.h and put in initialization
     *     here
     */

    channelCount = 2;
    samplingRate = 44100;
    /* array of MKSamples, one for each active file. */
    samplesToMix = [[NSMutableArray alloc] init];
    [self addNoteReceiver: [[MKNoteReceiver alloc] init]]; /* Need one NoteReceiver */ 
    return self;
}

- (void) dealloc
{
    [samplesToMix release];
    if(outSoundStruct) // could be set NULL in afterPerformance
        SndFree(outSoundStruct);
    if(sound)
        [sound release]; // when sound is being allocated we should release this
    [stream release];  
    if(defaultFile)
        [defaultFile release];	      /* default sound file name */
    [super dealloc];
}

-setSamplingRate: (double) aSrate
    channelCount: (int) chans
 writingToStream: (NSMutableData *) aStream
    /* Invoked once before performance from mixsounds.m. */
{
    if ([self inPerformance])
      return nil;
    samplingRate = aSrate;
    channelCount = chans;
    stream = [aStream retain];
    return self;
}

// Invoked once before performance. 
// The sound generated can be retrieved after the performance.
-setSamplingRate: (double) aSrate
    channelCount: (int) chans
{
    if ([self inPerformance])
      return nil;
    samplingRate = aSrate;
    channelCount = chans;
    // sound = [[Snd alloc] init];
    return self;
}

-firstNote: (MKNote *) aNote 
    /* This is invoked when first note is received during performance */
{
    SndAlloc(&outSoundStruct,
	     0 /* data size (we'll set this later) */,
	     SND_FORMAT_LINEAR_16,
	     (int)samplingRate,
	     channelCount,
	     104 /* info string space to allocate (for 128 bytes) */  );
    outSoundStruct->magic = NSSwapHostIntToBig(outSoundStruct->magic);
    outSoundStruct->dataLocation = NSSwapHostIntToBig(outSoundStruct->dataLocation);
    outSoundStruct->dataFormat = NSSwapHostIntToBig(outSoundStruct->dataFormat);
    outSoundStruct->samplingRate = NSSwapHostIntToBig(outSoundStruct->samplingRate);
    outSoundStruct->channelCount = NSSwapHostIntToBig(outSoundStruct->channelCount);
    [stream appendBytes: (void *) outSoundStruct length: sizeof(*outSoundStruct)];
    NSAssert([stream length] == sizeof(*outSoundStruct), @"stream initialized with outSoundStruct header");
    return self;
}

static void swapIt(short *data,int howMany)
{
    while (howMany--) {
        *data = NSSwapHostShortToBig(*data);
	data++;
    }
}

- _mixToTime: (double) untilTime
{
    /* Private method used to mix up to the current time (untilTime) */
    MKSamples *aSFInfo;           /* Pointer to current file's SFInfo */
    int fileNum;               /* SFInfo index */
    int curBufSize;            /* Number of samples we're computing */
    int untilSamp;             /* We're mixing until this output sample */
    BOOL inFileLastBuf;        /* Is this the last buffer for current file? */
    int inDataLastLoc;         /* Index of last usable sample in cur file */
    int inDataRemaining;       /* Size of remaining input data */
    short *samps;              /* buffer of BUFFERSIZE used in mixing, we always write SND_FORMAT_LINEAR_16 */

    /* Variables used in inner loop */
    short *curOutPtr;
    short *endOutPtr;
    short *inData;
    int tmp;

    if (untilTime != MK_ENDOFTIME)
	untilSamp = ((int)(untilTime * samplingRate + .5)) * channelCount;
    else { /* We're at the end of time. Find file with longest duration */
	untilSamp = curOutSamp;  
	for (fileNum = 0; fileNum < [samplesToMix count]; fileNum++) {
	    aSFInfo = (MKSamples *)[samplesToMix objectAtIndex:fileNum];
	    untilSamp = MAX([aSFInfo processingEndSample] - [aSFInfo currentSample] + curOutSamp, untilSamp);
	}
    }
    _MK_MALLOC(samps, short, BUFFERSIZE);
    if(samps == NULL) {
        NSLog(@"unable to allocate the memory for mix buffer\n");
    }
    while (curOutSamp < untilSamp) {
	memset(samps, 0, BUFFERSIZE * sizeof(short)); /* Clear out buffer */
	curBufSize = MIN(untilSamp - curOutSamp,BUFFERSIZE);
	for (fileNum = 0; fileNum < [samplesToMix count]; fileNum++) {
	    curOutPtr = samps;
	    aSFInfo = (MKSamples *)[samplesToMix objectAtIndex:fileNum];
	    inDataLastLoc = [aSFInfo processingEndSample];
	    inData = (short *)[[aSFInfo sound] data];
	    inData = inData + [aSFInfo currentSample];
	    inDataRemaining = inDataLastLoc - [aSFInfo currentSample];
	    inFileLastBuf = inDataRemaining < curBufSize;
	    endOutPtr = (inFileLastBuf) ? (curOutPtr + inDataRemaining) : (samps + curBufSize);
	    if ([aSFInfo amplitude] == 1.0) {  // since we only assign this below, we can be pretty confident the test won't lose precision.
	        while (curOutPtr < endOutPtr)
                    *curOutPtr++ += *inData++; // mix by adding
	    }
	    else {
                int intAmp = [aSFInfo amplitude] * MAXSHORT;
	        while (curOutPtr < endOutPtr) {
                    tmp = *inData++; /* Do fixed point multiply */
                    tmp *= intAmp;
                    tmp >>= 15;      /* intAmp has only 15 bits of magnitude */
                    *curOutPtr++ += tmp;
	        }
	    }
	    if (inFileLastBuf) {      /* This file's done. */
		//[aSFInfo->sound release]; 
		[samplesToMix removeObjectAtIndex: fileNum--]; 
	    }
	    else
                [aSFInfo setCurrentSample: [aSFInfo currentSample] + ((inFileLastBuf) ? inDataRemaining : curBufSize)];
	}
	swapIt(samps, curBufSize);
        [stream appendBytes: (void *) samps length: curBufSize * sizeof(short)];
	curOutSamp += curBufSize;
    }
  if (samps) {
    free(samps);
    samps = NULL;
}
    return self;
}

/* These methods do pre-mix processing */
/* ### Add your own processing methods here */

-_position:(int)bearing inSound: (Snd *) inSound outSound: (Snd *) outSound 
 startSamp:(int)startSamp sampCount:(int)sampCount amp:(double)amp
 alreadySwapped:(BOOL)alreadySwapped
{
    /* Left-right panning */
    short *inData = &(((short *)[inSound data])[startSamp]);
    short *inDataEnd = inData + sampCount;
    short *outData = (short *)[outSound data];
    double bearingD,leftAmpD,rightAmpD;
    int leftSample,rightSample,leftAmp,rightAmp;

#define bearingFun1(theta)    fabs(cos(theta))
#define bearingFun2(theta)    fabs(sin(theta))

    bearingD = bearing * M_PI/180.0 + M_PI/4.0;
    leftAmpD = amp * bearingFun1(bearingD);
    leftAmp = leftAmpD * MAXSHORT;
    rightAmpD = amp * bearingFun2(bearingD);
    rightAmp = rightAmpD * MAXSHORT;
    while (inData < inDataEnd) {
        leftSample = rightSample = (signed short int) (alreadySwapped ? *inData : NSSwapBigShortToHost(*inData));
        leftSample *= leftAmp;   /* Do fixed point multiply */
        leftSample >>= 15;       /* intAmp has only 15 bits of magnitude */
        *outData++ = (short) leftSample;
        rightSample *= rightAmp; /* Do fixed point multiply */
        rightSample >>= 15;      /* intAmp has only 15 bits of magnitude */
        *outData++ = (short) rightSample;
        inData++;
    }
    return self; 
}

- _applyEnvelope:envelope to:(MKSamples *) info scaleToFit:(BOOL)scaleToFit
{
    /* Put an envelope on a signal. */
    int n;
    short *end, *segend;
    short *data = (short *)[[info sound] data] + [info currentSample];
    int intamp;
    double amp, inc;
    int nchans = [[info sound] channelCount];
    int arrCount;
    double factor;
    double *xarr;
    double *yarr;
    double *arrEnd;
    double dt;
    if (!envelope)
      return self;
    arrCount = [envelope pointCount];
    xarr = [envelope xArray]; /* Assumes xarr is valid */
    yarr = [envelope yArray];
    arrEnd = xarr+arrCount;
    end = data + [info processingEndSample] - [info currentSample];
    if (scaleToFit) {
	factor = ((((end-data)/(double)[[info sound] samplingRate])/nchans)/
		  (xarr[arrCount-1]-xarr[0]));
    }
    else factor = 1;
    while (data<end) {
	if (xarr < (arrEnd-1)) {
	    dt = (*(xarr+1)-*xarr) * factor;
	    n = (int)(dt*[[info sound] samplingRate] + .5);
	    segend = MIN(data+n*nchans,end);
	    amp = *yarr * 32768.0;
	    inc = (*(yarr+1)-*yarr) * 32768.0/(double)n;
	}
	else {
	    segend = end;
	    amp = *yarr * 32768.0;
	    inc = 0;
	}
	if (nchans==1) {
            while (data<segend) {
                *data = (short)(((int)*data * (int)amp)>>15);
		data++;
                amp += inc;
            }
	}
	else {
            while (data<segend) {
                intamp = (int)amp;
                *data = (short)(((int)*data * intamp)>>15);
		data++;
                *data = (short)(((int)*data * intamp)>>15);
		data++;
                amp += inc;
            }
	}
	xarr++;
	yarr++;
    }
    return self;
}

-afterPerformance 
  /* This is invoked when performance is over. */
{
    NSRange headerRange = {0, sizeof(*outSoundStruct)};

    if (!outSoundStruct)  /* Did we never receive any notes? */
	return self;
    [self _mixToTime:MK_ENDOFTIME];
    outSoundStruct->dataSize = NSSwapHostIntToBig(curOutSamp * sizeof(short));
    [stream replaceBytesInRange: headerRange withBytes: (void *) outSoundStruct];
    outSoundStruct->dataSize = 0;
    SndFree(outSoundStruct);
    outSoundStruct = NULL;
    return self;
}

static int timeToSamp(Snd *s,double time)
{
    return [s channelCount] * (int)([s samplingRate] * time + .5);
}

-realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* This is invoked when a new MKNote is received during performance */
{
    MKNoteType type;
    double amp = defaultAmp;
    int timeScale= defaultTimeScale;
    [self _mixToTime:MKGetTime()]; /* Update mix. */
    if (!aNote)
	return self;
    switch (type = [aNote noteType]) {
    case MK_noteDur: {/* NoteDur means new file with duration */
	MKSamples *newSoundFileSamples = [[MKSamples alloc] init];
	double dur,timeOffset;
	NSString *file;
	file = [aNote parAsStringNoCopy: MK_filename];
	if (!file || ![file length])  /* Parameter not present? */
	    file = defaultFile;
        if (!file || ![file length]) {  /* Parameter not present? */	
	    NSLog(@"No input sound file specified.\n");
	    break;
	}
        [newSoundFileSamples readSoundfile: file]; 
	if (![newSoundFileSamples sound]) {
	    NSLog(@"Can't find file %@.\n",file);
	    break;
	}
	else if([[newSoundFileSamples sound] dataFormat] != SND_FORMAT_LINEAR_16) {
	    [[newSoundFileSamples sound] convertToFormat:SND_FORMAT_LINEAR_16
                samplingRate:[[newSoundFileSamples sound] samplingRate]
	        channelCount:[[newSoundFileSamples sound] channelCount]];
	    if([[newSoundFileSamples sound] dataFormat] != SND_FORMAT_LINEAR_16) {
	        NSLog(@"Error: mixsounds input files must be in 16-bit linear or Mu Law format.\n");
		break;
	    }
	}
	NSLog(@"%f ",MKGetTime()); /* Give user feedback */
	if ([aNote isParPresent:MK_amp])
	    amp = [aNote parAsDouble:MK_amp];
	if ([aNote isParPresent:MK_velocity])
	    amp *= MKMidiToAmpAttenuation([aNote parAsInt:MK_velocity]);
	[newSoundFileSamples setProcessingEndSample: [[newSoundFileSamples sound] dataSize]/sizeof(short)]; // LMS Redundant
	if ([aNote isParPresent:timeOffsetPar]) {
	    timeOffset = [aNote parAsDouble:timeOffsetPar];
            [newSoundFileSamples setCurrentSample: timeToSamp([newSoundFileSamples sound],timeOffset)];
	}
	else
	    [newSoundFileSamples setCurrentSample: 0];
	dur = [aNote dur];
	if (!MKIsNoDVal(dur) && dur != 0) {
	    int lastLoc = timeToSamp([newSoundFileSamples sound],dur) + [newSoundFileSamples currentSample];
            [newSoundFileSamples setProcessingEndSample: MIN([newSoundFileSamples processingEndSample], lastLoc)];
	}
	if ([newSoundFileSamples currentSample] > [newSoundFileSamples processingEndSample] || dur < 0 ) {
	    NSLog(@"Warning: no samples to mix for this file.\n");
	    break;
	}
	if ([[newSoundFileSamples sound] channelCount] != channelCount) {
	    if (channelCount == 2 && [[newSoundFileSamples sound] channelCount] == 1) {
	        /* Sound is going to be twice as long, so we have to
	         * allocate a new sound here. 
	         */
                Snd *inSound = [newSoundFileSamples sound];
                Snd *outSound = [[[Snd alloc] init] autorelease];
	        int bearing = (MKIsNoteParPresent(aNote, MK_bearing) ? MKGetNoteParAsInt(aNote, MK_bearing) : 0);
	        int sampCount = ([newSoundFileSamples processingEndSample] - [newSoundFileSamples currentSample]);
	        [outSound
                     setDataSize:sampCount*sizeof(short)*2
		     dataFormat:[inSound dataFormat]
		     samplingRate:[inSound samplingRate]
		     channelCount:2
		     infoSize:4];
	        [self _position:bearing inSound:inSound outSound:outSound
                     startSamp:[newSoundFileSamples currentSample] sampCount:sampCount
                     amp:([aNote isParPresent:MK_amp])?amp:defaultAmp
                     alreadySwapped:NO];
                // outSound is copied by setSound, inSound is released before being assigned.
                [newSoundFileSamples setSound: outSound];     
                [newSoundFileSamples setProcessingEndSample: sampCount * 2]; /* Stereo */
		[newSoundFileSamples setAmplitude: 1.0];     /* Amp factored in above */
	    }
            else {
	        NSLog(@"Error: File %@ has %d channels and channelCount is %d.\n",
	       	  file, [[newSoundFileSamples sound] channelCount], channelCount);
	        break;
	    }
	}
        else {
	    if ([aNote isParPresent:MK_amp])
		[newSoundFileSamples setAmplitude: amp];
	    else
                [newSoundFileSamples setAmplitude: defaultAmp];
	}
	if ([aNote isParPresent:timeScalePar])
	    timeScale = [aNote parAsInt:timeScalePar];
	if (timeScale == applyEnvBefore || timeScale == scaleEnvToFit) {
	    if ([aNote isParPresent:MK_ampEnv] || defaultEnvelope) {
		MKEnvelope *ampEnv = [aNote parAsEnvelope:MK_ampEnv];
		if (!ampEnv) 
	            ampEnv = defaultEnvelope;
		[self _applyEnvelope:ampEnv to:newSoundFileSamples scaleToFit:timeScale == 2];
	    }
        }

        /* ### Add your processing modules here, if you want them to apply
         *     before pitch-shifting. 
         */

        /* freq0 is assumed old freq. freq1 is new freq. */
        if ([aNote isParPresent:MK_freq1] || [aNote isParPresent:MK_freq0] ||
	    [aNote isParPresent:MK_keyNum] || defaultFreq1 || defaultFreq0 ||
	    ((int)[[newSoundFileSamples sound] samplingRate]!=(int)samplingRate)) {
	    /* Sound is going to change length, so we have to allocate
	     * a new sound here.
	     */
	    double f0 = (([aNote isParPresent:MK_freq0])?
			   [aNote parAsDouble:MK_freq0]:defaultFreq0);
	    double f1 = (([aNote isParPresent:MK_freq1])?
			   [aNote parAsDouble:MK_freq1]:
			   (([aNote isParPresent:MK_keyNum])?[aNote freq]:
			    defaultFreq1));
	    double factor;
	    if ((f0 && !f1) || (f1 && !f0))
		NSLog(@"Warning: Must specify both Freq0 and Freq1 if either are specified.\n");
	    factor = ((f1 && f0)?(f0 / f1):1.0) *
		(samplingRate / [[newSoundFileSamples sound] samplingRate]);
	    if ((factor>32) || (factor<.03125))
		NSLog(@"Warning: resampling more than 5 octaves.\n");
	    if (fabs(factor-1.0)>.0001) {
		Snd *inSound = [newSoundFileSamples sound];
		Snd *outSound = [[[Snd alloc] init] autorelease];
		int inSampleFrames, outSampleFrames;
		inSampleFrames = 
		    (MIN([newSoundFileSamples processingEndSample],
			 [inSound sampleCount]*[inSound channelCount])
		     - [newSoundFileSamples currentSample])/[inSound channelCount];
		outSampleFrames = inSampleFrames * factor;
		[outSound
		    setDataSize:(outSampleFrames * sizeof(short) * [inSound channelCount])
		    dataFormat:[inSound dataFormat]
		    samplingRate:[inSound samplingRate]
		    channelCount:[inSound channelCount]
		    infoSize:4];
		resample(factor,
			 (short *)[outSound data],
			 inSampleFrames,outSampleFrames,
			 [inSound channelCount], NO, /* No interp filter. */
		         0,         /* 0 = highest quality, slowest speed */
			 NO, 	      /* Not large filter */
			 NULL,     /* No filter file supplied */
                         [inSound soundStruct],
                         [newSoundFileSamples currentSample],
                         NULL);

		[newSoundFileSamples setSound: outSound];
		[newSoundFileSamples setProcessingEndSample: outSampleFrames * [inSound channelCount]];
	    }
	}
	if (timeScale == applyEnvAfter)
	    if ([aNote isParPresent:MK_ampEnv] || defaultEnvelope) {
		MKEnvelope *ampEnv = [aNote parAsEnvelope:MK_ampEnv];
		if (!ampEnv) 
		  ampEnv = defaultEnvelope;
		[self _applyEnvelope:ampEnv to:newSoundFileSamples scaleToFit:0];
	    }

	  /* ### Add your processing modules here, if you want them to apply
	   *     after pitch-shifting. 
	   */
	  [samplesToMix addObject: newSoundFileSamples];
          [newSoundFileSamples autorelease]; // we are through with it, the samplesToMix will retain it as it needs.
	  break;
    }
    case MK_noteUpdate: { /* Only no-tag NoteUpdates are recognized */
	if ([aNote noteTag] != MAXINT)
	    break;        /* Ignore noteUpdates with note tags */
	if ([aNote isParPresent:MK_amp]) 
	    defaultAmp = [aNote parAsDouble:MK_amp]; 
	if ([aNote isParPresent:MK_filename])
            defaultFile = [aNote parAsStringNoCopy:MK_filename];
	if ([aNote isParPresent:MK_freq1])
	    defaultFreq1 =[aNote parAsDouble:MK_freq1];
	if ([aNote isParPresent:MK_freq0])
	    defaultFreq0 =[aNote parAsDouble:MK_freq0];
	if ([aNote isParPresent:MK_ampEnv])
	    defaultEnvelope =[aNote parAsEnvelope:MK_ampEnv];
	if ([aNote isParPresent:timeScalePar])
	    defaultTimeScale =[aNote parAsInt:timeScalePar];
	break;
    }
    default: /* Ignore all other notes */
	break;
    }
    return self;
}

@end

