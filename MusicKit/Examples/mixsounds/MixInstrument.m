/* To make your own custom version of mixsounds, add code where indicated
 * below by "###" 
 */

#import <objc/Storage.h>
#import <appkit/nextstd.h>
#import <musickit/musickit.h>
#import <soundkit/Sound.h>
typedef short          HWORD;
#import "resample.h"
 
typedef struct _SFInfo {  /* Used to represent each input soundfile */
    int curLoc;           /* Index into current sample in soundfile */
    id sound;             /* Sound object representing soundfile */
    int intAmp;           /* Amplitude scaling of soundfile in fixed point */ 
    int lastSampLoc;      /* Length of portion of soundfile to be used. */
    BOOL swapped;         /* YES if was byte-swapped */
} SFInfo;

#import "MixInstrument.h"
@implementation MixInstrument /* See MixInstrument.h for instance variables */

#define BUFFERSIZE (BUFSIZ * 8)
static short samps[BUFFERSIZE]; /* We always write SND_FORMAT_LINEAR_16 */

static int filePar = 0,timeScalePar = 0,timeOffsetPar = 0;
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

    filePar = [Note parName:"soundFile"];
    timeOffsetPar = [Note parName:"timeOffset"];
    timeScalePar = [Note parName:"ampEnvTimeScale"];
    /* ### Add a par int initialization statement here. */

    channelCount = 2;
    samplingRate = 22050;
    SFInfoStorage =      /* List of SFInfos, one for each active file. */
	[[Storage alloc] initCount:0 elementSize:sizeof(SFInfo) description:
	 "i@dii"];       /* See <objc/Storage.h> */
    [self addNoteReceiver:[[NoteReceiver alloc] init]]; 
	                 /* Need one NoteReceiver */ 
    return self;
}

-setSamplingRate:(double)aSrate channelCount:(int)chans 
 stream:(NXStream *)aStream
    /* Invoked once before performance from mixsounds.m. */
{
    if ([self inPerformance])
      return nil;
    samplingRate = aSrate;
    channelCount = chans;
    stream = aStream;
    return self;
}

-firstNote:aNote 
    /* This is invoked when first note is received during performance */
{
    SNDAlloc(&outSoundStruct,
	     0 /* data size (we'll set this later) */,
	     SND_FORMAT_LINEAR_16,
	     (int)samplingRate,
	     channelCount,
	     104 /* info string space to allocate (for 128 bytes) */  );
    outSoundStruct->magic = NXSwapHostIntToBig(outSoundStruct->magic);
    outSoundStruct->dataLocation = NXSwapHostIntToBig(outSoundStruct->dataLocation);
    outSoundStruct->dataFormat = NXSwapHostIntToBig(outSoundStruct->dataFormat);
    outSoundStruct->samplingRate = NXSwapHostIntToBig(outSoundStruct->samplingRate);
    outSoundStruct->channelCount = NXSwapHostIntToBig(outSoundStruct->channelCount);
    NXWrite(stream,(char *)outSoundStruct, sizeof(*outSoundStruct));
    return self;
}

static void swapIt(short *data,int howMany)
{
    while (howMany--) {
        *data = NXSwapHostShortToBig(*data);
	data++;
    }
}

-_mixToTime:(double)untilTime
{
    /* Private method used to mix up to the current time (untilTime) */
    SFInfo *aSFInfo;           /* Pointer to current file's SFInfo */
    int fileNum;               /* SFInfo index */
    int curBufSize;            /* Number of samples we're computing */
    int untilSamp;             /* We're mixing until this output sample */
    BOOL inFileLastBuf;        /* Is this the last buffer for current file? */
    int inDataLastLoc;         /* Index of last usable sample in cur file */
    int inDataRemaining;       /* Size of remaining input data */

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
	    aSFInfo = (SFInfo *)[SFInfoStorage elementAt:fileNum];
	    untilSamp = MAX(aSFInfo->lastSampLoc - aSFInfo->curLoc + 
			    curOutSamp,untilSamp);
	}
    }
    while (curOutSamp < untilSamp) {
	bzero(samps,BUFFERSIZE * sizeof(short)); /* Clear out buffer */
	curBufSize = MIN(untilSamp - curOutSamp,BUFFERSIZE);
	for (fileNum = 0; fileNum < [SFInfoStorage count]; fileNum++) {
	    curOutPtr = &(samps[0]);
	    aSFInfo = (SFInfo *)[SFInfoStorage elementAt:fileNum];
	    inDataLastLoc = aSFInfo->lastSampLoc;
	    inData = (short *)[aSFInfo->sound data];
	    inData = &(inData[aSFInfo->curLoc]);
	    inDataRemaining = inDataLastLoc - aSFInfo->curLoc;
	    inFileLastBuf = inDataRemaining < curBufSize;
	    endOutPtr = ((inFileLastBuf) ? (curOutPtr + inDataRemaining) : 
			 &(samps[curBufSize]));
	    if (!aSFInfo->swapped) {
	        short *inPtr = inData;
	        short *endInPtr = inData + (endOutPtr-curOutPtr);
		while (inPtr < endInPtr) {
		  *inPtr = NXSwapBigShortToHost(*inPtr);
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
		[aSFInfo->sound free];
		[SFInfoStorage removeElementAt:fileNum--]; 
	    }
	    else aSFInfo->curLoc += ((inFileLastBuf) ? inDataRemaining :
				     curBufSize);
	}
	swapIt(samps,curBufSize);	
	NXWrite(stream,(char *)samps, curBufSize * sizeof(short));
	curOutSamp += curBufSize;
    }
    NXFlush(stream);
    return self;
}

/* These methods do pre-mix processing */
/* ### Add your own processing methods here */

-_position:(int)bearing inSound:inSound outSound:outSound 
 startSamp:(int)startSamp sampCount:(int)sampCount amp:(double)amp
 alreadySwapped:(BOOL)alreadySwapped
{
    /* Left-right panning */
    short *inData = &(((short *)[inSound data])[startSamp]);
    short *inDataEnd = inData + sampCount;
    short *outData = (short *)[outSound data];
    double bearingD,leftAmpD,rightAmpD;
    int tmp,leftAmp,rightAmp;

#define bearingFun1(theta)    fabs(cos(theta))
#define bearingFun2(theta)    fabs(sin(theta))

    bearingD = bearing * M_PI/180.0 + M_PI/4.0;
    leftAmpD = amp * bearingFun1(bearingD);
    leftAmp = leftAmpD * MAXSHORT;
    rightAmpD = amp * bearingFun2(bearingD);
    rightAmp = rightAmpD * MAXSHORT;
    if (alreadySwapped)
      while (inData < inDataEnd) {
	tmp = *inData;   /* Do fixed point multiply */
	tmp *= leftAmp;
	tmp >>= 15;      /* intAmp has only 15 bits of magnitude */
	*outData++ = tmp;
	tmp = *inData++; /* Do fixed point multiply */
	tmp *= rightAmp;
	tmp >>= 15;      /* intAmp has only 15 bits of magnitude */
	*outData++ = tmp;
      }
    else while (inData < inDataEnd) {
	tmp = NXSwapBigShortToHost(*inData); /* Do fixed point multiply */
	tmp *= leftAmp;
	tmp >>= 15;      /* intAmp has only 15 bits of magnitude */
	*outData++ = tmp;
	tmp = *inData++; /* Do fixed point multiply */
	tmp *= rightAmp;
	tmp >>= 15;      /* intAmp has only 15 bits of magnitude */
	*outData++ = tmp;
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
		    *data++ = (short)(((int)NXSwapBigShortToHost(*data) * (int)amp)>>15);
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
		    *data++ = (short)(((int)NXSwapBigShortToHost(*data) * intamp)>>15);
		    *data++ = (short)(((int)NXSwapBigShortToHost(*data) * intamp)>>15);
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
    if (!outSoundStruct)  /* Did we never received any notes? */
	return self;
    [self _mixToTime:MK_ENDOFTIME];
    outSoundStruct->dataSize = NXSwapHostIntToBig(curOutSamp * sizeof(short));
    NXSeek(stream, 0, NX_FROMSTART);
    NXWrite(stream,(char *)outSoundStruct, sizeof(*outSoundStruct));
    NXFlush(stream);
    outSoundStruct->dataSize = 0;
    SNDFree(outSoundStruct);
    outSoundStruct = NULL;
    NXSeek(stream,0,NX_FROMEND);
    NXFlush(stream);
    return self;
}

static int timeToSamp(Sound *s,double time)
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
	  char *file;
	  file = [aNote parAsStringNoCopy:filePar];
	  if (!file || !strlen(file))  /* Parameter not present? */
	      file = defaultFile;
	  if (!file || !strlen(file)) {  /* Parameter not present? */	
	      fprintf(stderr,"No input sound file specified.\n");
	      break;
	  }
	  newSFInfo.sound = [[Sound alloc] initFromSoundfile:file]; 
	  newSFInfo.swapped = NO;
	  if (!newSFInfo.sound) {
	      fprintf(stderr,"Can't find file %s.\n",file);
	      break;
	  }
	  else if  ([newSFInfo.sound dataFormat] != SND_FORMAT_LINEAR_16) {
	      [newSFInfo.sound convertToFormat:SND_FORMAT_LINEAR_16
	       samplingRate:[newSFInfo.sound samplingRate]
	       channelCount:[newSFInfo.sound channelCount]];
	      if  ([newSFInfo.sound dataFormat] != SND_FORMAT_LINEAR_16) {
		  fprintf(stderr,"Error: mixsounds input files must be in 16-bit linear or Mu Law format.\n");
		  break;
	      }
	  }
	  fprintf(stderr,"%f ",MKGetTime()); /* Give user feedback */
	  fflush(stderr);
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
	      fprintf(stderr,"Warning: no samples to mix for this file.\n");
	      break;
	  }
	  if ([newSFInfo.sound channelCount] != channelCount) {
	      if (channelCount == 2 && [newSFInfo.sound channelCount] == 1) {
		  /* Sound is going to be twice as long, so we have to
		   * allocate a new sound here. 
		   */
		  id inSound = newSFInfo.sound;
		  id outSound = [[Sound alloc] init];
		  int bearing = (MKIsNoteParPresent(aNote,MK_bearing) ? 
				 MKGetNoteParAsInt(aNote,MK_bearing) : 0);
		  int samps = (newSFInfo.lastSampLoc - newSFInfo.curLoc);
		  [outSound
		     setDataSize:samps*sizeof(short)*2
		     dataFormat:[inSound dataFormat]
		     samplingRate:[inSound samplingRate]
		     channelCount:2
		     infoSize:4];
		  [self _position:bearing inSound:inSound outSound:outSound
		   startSamp:newSFInfo.curLoc sampCount:samps 
		   amp:([aNote isParPresent:MK_amp])?amp:defaultAmp
		   alreadySwapped:NO];
		  newSFInfo.swapped = YES;
		  newSFInfo.sound = outSound;
		  newSFInfo.curLoc = 0;
		  newSFInfo.lastSampLoc = samps * 2; /* Stereo */
		  newSFInfo.intAmp = MAXSHORT;     /* Amp factored in above */
		  [inSound free];
	      } else {
		  fprintf(stderr,
			  "Error: File %s has %d channels and channelCount is %d.\n",
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
	  if (timeScale == applyEnvBefore || timeScale == scaleEnvToFit) 
	    if ([aNote isParPresent:MK_ampEnv] || defaultEnvelope) {
		Envelope *ampEnv = [aNote parAsEnvelope:MK_ampEnv];
		if (!ampEnv) 
		  ampEnv = defaultEnvelope;
		[self _applyEnvelope:ampEnv to:newSFInfo 
	         scaleToFit:timeScale == 2];
		newSFInfo.swapped = YES;
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
		  fprintf(stderr,"Warning: Must specify both Freq0 and Freq1 if either are specified.\n");
	      factor = ((f1 && f0)?(f0 / f1):1.0) *
		  (samplingRate / [newSFInfo.sound samplingRate]);
	      if ((factor>32) || (factor<.03125))
		  fprintf(stderr,"Warning: resampling more than 5 octaves.\n");
	      if (fabs(factor-1.0)>.0001) {
		  id inSound = newSFInfo.sound;
		  id outSound = [[Sound alloc] init];
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
			  *startP = NXSwapBigShortToHost(*startP);
			  startP++;
		      }
		      newSFInfo.swapped = YES;
		  }
		  resample(factor,
			   (short *)[inSound data]+newSFInfo.curLoc,
			   (short *)[outSound data],
			   inSampleFrames,outSampleFrames,
			   [inSound channelCount], NO, /* No interp filter. */
		           0,         /* 0 = highest quality, slowest speed */
			   NO, 	      /* Not large filter */
			   NULL);     /* No filter file supplied */
		  newSFInfo.sound = outSound;
		  newSFInfo.curLoc = 0;
		  newSFInfo.lastSampLoc = outSampleFrames*[inSound channelCount];
		  [inSound free];
	      }
	  }
	  if (timeScale == applyEnvAfter)
	    if ([aNote isParPresent:MK_ampEnv] || defaultEnvelope) {
		Envelope *ampEnv = [aNote parAsEnvelope:MK_ampEnv];
		if (!ampEnv) 
		  ampEnv = defaultEnvelope;
		[self _applyEnvelope:ampEnv to:newSFInfo scaleToFit:0];
		newSFInfo.swapped = YES;
	    }

	  /* ### Add your processing modules here, if you want them to apply
	   *     after pitch-shifting. 
	   */

	  [SFInfoStorage addElement:(void *)&newSFInfo];
	  break;
      }
      case MK_noteUpdate: { /* Only no-tag NoteUpdates are recognized */
	  if ([aNote noteTag] != MAXINT)
	      break;        /* Ignore noteUpdates with note tags */
	  if ([aNote isParPresent:MK_amp]) 
	    defaultAmp = [aNote parAsDouble:MK_amp]; 
	  if ([aNote isParPresent:filePar])
	    defaultFile = [aNote parAsStringNoCopy:filePar];
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

