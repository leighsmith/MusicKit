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
    MKInstrument subclass to "realize Notes" in some novel fashion. In this
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
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

 $Log$
 Revision 1.2  2000/04/17 22:55:32  leigh
 Added debugging information attempting to find malloc problem

 Revision 1.1  2000/04/16 21:18:36  leigh
 First version using SndKit incorporated into the MusicKit framework

*/

#import "_musickit.h"
#import <SndKit/SndKit.h>
#import <SndKit/SndResample.h>
 
typedef struct _SFInfo {  /* Used to represent each input soundfile */
    int curLoc;           /* Index into current sample in soundfile */
    Snd *sound;           /* Sound object representing soundfile */
    int intAmp;           /* Amplitude scaling of soundfile in fixed point */ 
    int lastSampLoc;      /* Length of portion of soundfile to be used. */
    BOOL swapped;         /* YES if was byte-swapped */
} SFInfo;

#import "MKMixerInstrument.h"

@implementation MKMixerInstrument /* See MKMixerInstrument.h for instance variables */

#define BUFFERSIZE (BUFSIZ * 8)   /* size (in samples per frame) of temporary mixing buffer */
//#define BUFFERSIZE (20)   /* size (in samples per frame) of temporary mixing buffer */

static int timeScalePar = 0,timeOffsetPar = 0;
/* ### If you add a parameter, put in a declaration here */

enum {applyEnvBefore = 0,applyEnvAfter = 1,scaleEnvToFit = 2};

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

    timeOffsetPar = [MKNote parName:@"timeOffset"];
    timeScalePar = [MKNote parName:@"ampEnvTimeScale"];
    /* ### Add a par int initialization statement here. */

    channelCount = 2;
    samplingRate = 44100;
    /* array of SFInfos (each held as NSData), one for each active file. */
    SFInfoStorage = [[NSMutableArray array] retain];
    [self addNoteReceiver: [[MKNoteReceiver alloc] init]]; /* Need one NoteReceiver */ 
    return self;
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

-firstNote:aNote 
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

//short testbuf[BUFFERSIZE];
//short testbuf[20];

- _mixToTime: (double) untilTime
{
    /* Private method used to mix up to the current time (untilTime) */
    SFInfo *aSFInfo;           /* Pointer to current file's SFInfo */
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
	for (fileNum = 0; fileNum < [SFInfoStorage count]; fileNum++) {
	    aSFInfo = (SFInfo *)[[SFInfoStorage objectAtIndex:fileNum] bytes];
	    untilSamp = MAX(aSFInfo->lastSampLoc - aSFInfo->curLoc + curOutSamp, untilSamp);
	}
    }
    _MK_MALLOC(samps, short, BUFFERSIZE);
    if(samps == NULL) {
        NSLog(@"unable to allocate the memory for mix buffer\n");
    }
    while (curOutSamp < untilSamp) {
	bzero(samps,BUFFERSIZE * sizeof(short)); /* Clear out buffer */
	curBufSize = MIN(untilSamp - curOutSamp,BUFFERSIZE);
	for (fileNum = 0; fileNum < [SFInfoStorage count]; fileNum++) {
	    curOutPtr = samps;
	    aSFInfo = (SFInfo *)[[SFInfoStorage objectAtIndex:fileNum] bytes];
	    inDataLastLoc = aSFInfo->lastSampLoc;
	    inData = (short *)[aSFInfo->sound data];
	    inData = inData + aSFInfo->curLoc;
	    inDataRemaining = inDataLastLoc - aSFInfo->curLoc;
	    inFileLastBuf = inDataRemaining < curBufSize;
	    endOutPtr = (inFileLastBuf) ? (curOutPtr + inDataRemaining) : (samps + curBufSize);
	    if (!aSFInfo->swapped) {
	        short *inPtr = inData;
	        short *endInPtr = inData + (endOutPtr-curOutPtr);
		while (inPtr < endInPtr) {
		  *inPtr = NSSwapBigShortToHost(*inPtr);
		  inPtr++;
		}
	    }
	    if (aSFInfo->intAmp == MAXSHORT) {
	        while (curOutPtr < endOutPtr) 
		  *curOutPtr++ += *inData++;
	    }
	    else {
	        while (curOutPtr < endOutPtr) {
		  tmp = *inData++; /* Do fixed point multiply */
		  tmp *= aSFInfo->intAmp;
		  tmp >>= 15;      /* intAmp has only 15 bits of magnitude */
		  *curOutPtr++ += tmp;
	        }
	    }
	    if (inFileLastBuf) {      /* This file's done. */
                // NSLog(@"aSFInfo->sound retainCount = %d\n", [aSFInfo->sound retainCount]); // over released?
		[aSFInfo->sound release]; 
		[SFInfoStorage removeObjectAtIndex: fileNum--]; 
	    }
	    else
		aSFInfo->curLoc += ((inFileLastBuf) ? inDataRemaining : curBufSize);
	}
	swapIt(samps,curBufSize);
#if 0 // some wierd pointer bug is tickled here and I'm not sure it's even in this code.
NSLog(@"current stream length = %d, length to append: %d\n", [stream length], curBufSize * sizeof(short));
//    [stream appendBytes: (void *) testbuf length: BUFFERSIZE * sizeof(short)];
        [stream appendBytes: (void *) testbuf length: 20 * sizeof(short)];
#else
        [stream appendBytes: (void *) samps length: curBufSize * sizeof(short)];
#endif
	curOutSamp += curBufSize;
    }
    free(samps);
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

- _applyEnvelope:envelope to:(SFInfo)info scaleToFit:(BOOL)scaleToFit
{
    /* Put an envelope on a signal. */
    int n;
    short *end, *segend;
    short *data = (short *)[info.sound data]+info.curLoc;
    int intamp;
    double amp, inc;
    int nchans = [info.sound channelCount];
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
    end = data+info.lastSampLoc-info.curLoc;
    if (scaleToFit) {
	factor = ((((end-data)/(double)[info.sound samplingRate])/nchans)/
		  (xarr[arrCount-1]-xarr[0]));
    }
    else factor = 1;
    while (data<end) {
	if (xarr < (arrEnd-1)) {
	    dt = (*(xarr+1)-*xarr) * factor;
	    n = (int)(dt*[info.sound samplingRate] + .5);
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
	    if (info.swapped)
	      while (data<segend) {
		  *data++ = (short)(((int)*data * (int)amp)>>15);
		  amp += inc;
	      }
	    else {
		while (data<segend) {
		    *data++ = (short)(((int)NSSwapBigShortToHost(*data) * (int)amp)>>15);
		    amp += inc;
		}
	    }
	}
	else {
	    if (info.swapped) {
		while (data<segend) {
		    intamp = (int)amp;
		    *data++ = (short)(((int)*data * intamp)>>15);
		    *data++ = (short)(((int)*data * intamp)>>15);
		    amp += inc;
		}
	    }
	    else  {
		while (data<segend) {
		    intamp = (int)amp;
		    *data++ = (short)(((int)NSSwapBigShortToHost(*data) * intamp)>>15);
		    *data++ = (short)(((int)NSSwapBigShortToHost(*data) * intamp)>>15);
		    amp += inc;
		  }
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

-realizeNote:aNote fromNoteReceiver:aNoteReceiver
  /* This is invoked when a new Note is received during performance */
{
    MKNoteType type;
    double amp = defaultAmp;
    int timeScale= defaultTimeScale;
    [self _mixToTime:MKGetTime()]; /* Update mix. */
    if (!aNote)
	return self;
    switch (type = [aNote noteType]) {
      case MK_noteDur: {/* NoteDur means new file with duration */
	  SFInfo newSFInfo;
	  double dur,timeOffset;
	  NSString *file;
	  file = [aNote parAsStringNoCopy: MK_filename];
	  if (!file || ![file length])  /* Parameter not present? */
	      file = defaultFile;
          if (!file || ![file length]) {  /* Parameter not present? */	
	      NSLog(@"No input sound file specified.\n");
	      break;
	  }
	  newSFInfo.sound = [[Snd alloc] initFromSoundfile:file]; 
	  newSFInfo.swapped = NO;
	  if (!newSFInfo.sound) {
	      NSLog(@"Can't find file %@.\n",file);
	      break;
	  }
	  else if  ([newSFInfo.sound dataFormat] != SND_FORMAT_LINEAR_16) {
	      [newSFInfo.sound convertToFormat:SND_FORMAT_LINEAR_16
	       samplingRate:[newSFInfo.sound samplingRate]
	       channelCount:[newSFInfo.sound channelCount]];
	      if  ([newSFInfo.sound dataFormat] != SND_FORMAT_LINEAR_16) {
		  NSLog(@"Error: mixsounds input files must be in 16-bit linear or Mu Law format.\n");
		  break;
	      }
	  }
	  NSLog(@"%f ",MKGetTime()); /* Give user feedback */
	  if ([aNote isParPresent:MK_amp])
	    amp = [aNote parAsDouble:MK_amp];
	  if ([aNote isParPresent:MK_velocity])
	      amp *= MKMidiToAmpAttenuation([aNote parAsInt:MK_velocity]);
	  newSFInfo.lastSampLoc = [newSFInfo.sound dataSize]/sizeof(short);
	  if ([aNote isParPresent:timeOffsetPar]) {
	      timeOffset = [aNote parAsDouble:timeOffsetPar];
	      newSFInfo.curLoc = timeToSamp(newSFInfo.sound,timeOffset);
	  }
	  else
	      newSFInfo.curLoc = 0;
	  dur = [aNote dur];
	  if (!MKIsNoDVal(dur) && dur != 0) {
	      int lastLoc = timeToSamp(newSFInfo.sound,dur) + newSFInfo.curLoc;
	      newSFInfo.lastSampLoc = MIN(newSFInfo.lastSampLoc,lastLoc);
	  }
	  if (newSFInfo.curLoc > newSFInfo.lastSampLoc || dur < 0 ) {
	      NSLog(@"Warning: no samples to mix for this file.\n");
	      break;
	  }
	  if ([newSFInfo.sound channelCount] != channelCount) {
	      if (channelCount == 2 && [newSFInfo.sound channelCount] == 1) {
		  /* Sound is going to be twice as long, so we have to
		   * allocate a new sound here. 
		   */
                  Snd *inSound = newSFInfo.sound;
                  Snd *outSound = [[Snd alloc] init];
		  int bearing = (MKIsNoteParPresent(aNote,MK_bearing) ? 
				 MKGetNoteParAsInt(aNote,MK_bearing) : 0);
		  int sampCount = (newSFInfo.lastSampLoc - newSFInfo.curLoc);
		  [outSound
                     setDataSize:sampCount*sizeof(short)*2
		     dataFormat:[inSound dataFormat]
		     samplingRate:[inSound samplingRate]
		     channelCount:2
		     infoSize:4];
		  [self _position:bearing inSound:inSound outSound:outSound
                        startSamp:newSFInfo.curLoc sampCount:sampCount
                        amp:([aNote isParPresent:MK_amp])?amp:defaultAmp
               	        alreadySwapped:NO];
		  newSFInfo.swapped = YES;
		  newSFInfo.sound = outSound;
		  newSFInfo.curLoc = 0;
                  newSFInfo.lastSampLoc = sampCount * 2; /* Stereo */
		  newSFInfo.intAmp = MAXSHORT;     /* Amp factored in above */
		  [inSound release];
	      } else {
		  NSLog(@"Error: File %@ has %d channels and channelCount is %d.\n",
			  file,[newSFInfo.sound channelCount],channelCount);
		  break;
	      }
	  } else {
	      if ([aNote isParPresent:MK_amp])
		newSFInfo.intAmp = amp * MAXSHORT;
	      else newSFInfo.intAmp = defaultAmp * MAXSHORT;
	  }
	  if ([aNote isParPresent:timeScalePar])
	    timeScale = [aNote parAsInt:timeScalePar];
	  if (timeScale == applyEnvBefore || timeScale == scaleEnvToFit) {
	    if ([aNote isParPresent:MK_ampEnv] || defaultEnvelope) {
		MKEnvelope *ampEnv = [aNote parAsEnvelope:MK_ampEnv];
		if (!ampEnv) 
		  ampEnv = defaultEnvelope;
		[self _applyEnvelope:ampEnv to:newSFInfo 
	         scaleToFit:timeScale == 2];
		newSFInfo.swapped = YES;
	    }
          }

	  /* ### Add your processing modules here, if you want them to apply
	   *     before pitch-shifting. 
	   */

	  /* freq0 is assumed old freq. freq1 is new freq. */
	  if ([aNote isParPresent:MK_freq1] || [aNote isParPresent:MK_freq0] ||
	      [aNote isParPresent:MK_keyNum] || defaultFreq1 || defaultFreq0 ||
	      ((int)[newSFInfo.sound samplingRate]!=(int)samplingRate)) {
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
		  (samplingRate / [newSFInfo.sound samplingRate]);
	      if ((factor>32) || (factor<.03125))
		  NSLog(@"Warning: resampling more than 5 octaves.\n");
	      if (fabs(factor-1.0)>.0001) {
		  Snd *inSound = newSFInfo.sound;
		  Snd *outSound = [[Snd alloc] init];
		  int inSampleFrames,outSampleFrames;
		  inSampleFrames = 
		    (MIN(newSFInfo.lastSampLoc,
			 [inSound sampleCount]*[inSound channelCount])
		     - newSFInfo.curLoc)/[inSound channelCount];
		  outSampleFrames = inSampleFrames * factor;
		  [outSound
		     setDataSize:(outSampleFrames*sizeof(short)*
				  [inSound channelCount])
		     dataFormat:[inSound dataFormat]
		     samplingRate:[inSound samplingRate]
		     channelCount:[inSound channelCount]
		     infoSize:4];
		  if (!newSFInfo.swapped) {
		      short *endP,*startP;
		      startP = (short *)[inSound data]+newSFInfo.curLoc;
		      endP = startP + [inSound channelCount]*inSampleFrames;
		      while (startP < endP) {
			  *startP = NSSwapBigShortToHost(*startP);
			  startP++;
		      }
		      newSFInfo.swapped = YES;
		  }
		  resample(factor,
			   (short *)[outSound data],
			   inSampleFrames,outSampleFrames,
			   [inSound channelCount], NO, /* No interp filter. */
		           0,         /* 0 = highest quality, slowest speed */
			   NO, 	      /* Not large filter */
			   NULL,     /* No filter file supplied */
                           [inSound soundStruct],
                           newSFInfo.curLoc);

		  newSFInfo.sound = outSound;
		  newSFInfo.curLoc = 0;
		  newSFInfo.lastSampLoc = outSampleFrames*[inSound channelCount];
	      }
	  }
	  if (timeScale == applyEnvAfter)
	    if ([aNote isParPresent:MK_ampEnv] || defaultEnvelope) {
		MKEnvelope *ampEnv = [aNote parAsEnvelope:MK_ampEnv];
		if (!ampEnv) 
		  ampEnv = defaultEnvelope;
		[self _applyEnvelope:ampEnv to:newSFInfo scaleToFit:0];
		newSFInfo.swapped = YES;
	    }

	  /* ### Add your processing modules here, if you want them to apply
	   *     after pitch-shifting. 
	   */

	  [SFInfoStorage addObject: [NSData dataWithBytes: (void *) &newSFInfo length: sizeof(SFInfo)]];
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

