#import "PlayingSound.h"
#import "MKSamplerInstrument.h"
#import <SoundKit/mulaw.h>

#define SOUND_IN_SEPARATE_THREAD NO

@implementation PlayingSound

// class wide variables, different PlayingSound instances share these.
id soundOutDevice;
BOOL robustSound;

+ (void) close
{
   [soundOutDevice setReserved:NO];
}

- prepareToPlay
{
  int i, n, performDataSize;
	
  if (!soundStruct)
    return self;

  [self setAmp:amp];

  data = ((char *)soundStruct + soundStruct->dataLocation);
  endData = data + soundStruct->dataSize;

  if (resamplingEnabled) {
    bufferSize = ((robustSound) ? 65536 : 16384) * 
      ((float)samplingRate)/44100.0 * ((float)(soundStruct->channelCount))/2.0;
    nchunks = (pitchBend) ? ((robustSound) ? 16 : 4) : 1;
    performDataSize = bufferSize/nchunks;
    fraction = 0;
    chunk = 0;
    if (soundStruct->dataSize < performDataSize)
      performDataSize = soundStruct->dataSize;
  }
  else {
    bufferSize = soundStruct->dataSize;
    performDataSize = soundStruct->dataSize;
  }
	
  performDuration = (double)(performDataSize/frameSize)/(double)samplingRate;
	
  bufferTag = 0;

  n = (resamplingEnabled) ? 4*nchunks : 1;
  for (i = 0; i < n; i++)
    if (endData > data)
      [self perform];

  return self;
}

- reset
{
  transposition = pitchBend = 1.0;
  conductor = [MKConductor clockConductor];
  amp = volume = velocity = 1.0;
  leftPan = rightPan = 1.0;
  activationTime = 0;
  [soundStream setGainLeft:1.0 right:1.0];
  if (soundOutDevice != [soundStream device]) {
    [soundStream deactivate];
    [soundStream setDevice:soundOutDevice];
  }
  if (soundStruct) {
    if ([soundStream isActive] && !resamplingEnabled && preloadingEnabled) {
      /* If possible and if requested, pre-enqueue the first buffers */
      [soundStream activate];
      [soundStream pause:self];
      [self prepareToPlay];
    }
  }
  return self;
}

// return YES if able to claim and init the sound device, NO if not.
- (BOOL) initSoundOut
{
    robustSound = YES;  // originally from [preferences bigBuffers];

    if (soundOutDevice) {
        [soundOutDevice abortStreams:self];
        [soundOutDevice setReserved:NO];
        [soundOutDevice release];
    }
    [NXSoundOut setUseSeparateThread:SOUND_IN_SEPARATE_THREAD];
    [NXSoundOut setTimeout:250];

    if (soundOutDevice = [[NXSoundOut alloc] init]) {
        [soundOutDevice setRampsUp:NO];
        [soundOutDevice setRampsDown:robustSound];
        [soundOutDevice setBufferCount:(robustSound) ? 5 : 4];
        [soundOutDevice setBufferSize:1024];
        [soundOutDevice setBufferCount:(robustSound) ? 5 : 4];
    }
    else 
	return NO;
    return YES;
}

// return nil if unable to initialise,  self if everything went ok.
- init
{
  [super init];
  if(![self initSoundOut])
      return nil;
  soundStream = [[NXPlayStream alloc] initOnDevice:soundOutDevice];
  [soundStream retain];
  [soundStream setDelegate:self];
  return [self reset];
}

- (void) dealloc
{
  int i;
  [super dealloc];  // LMS check this is right
  [soundStream abort:nil];
  [soundStream setDelegate:nil];
  [soundStream setDevice:nil];
  for (i=1; i<16; i++)
    if (buffers[i] != NULL)
      NSZoneFree([self zone], buffers[i]);
  //	[NXApp perform:@selector(delayedFree:) with:soundStream afterDelay:500
  //		cancelPrevious:NO];
}

- touch
{
  [soundStream activate];
  [soundStream pause:self];
  [soundStream playBuffer:(void *)soundStruct+soundStruct->dataLocation 
	       size:soundStruct->dataSize
	       tag:0 channelCount:soundStruct->channelCount
	       samplingRate:samplingRate];
  [soundStream deactivate];
  return self;
}

// assign the sound object that will be used to perform.
- setSound: (Snd *) aSoundObj
{
  SndSoundStruct *aSoundStruct = [aSoundObj soundStruct];

  if (soundStruct != aSoundStruct) {
    if (status == MK_active)
      [self deactivate];
    [soundStream deactivate];
    sound = [aSoundObj retain];
    soundStruct = aSoundStruct;
    if (soundStruct) {
//      [self touch];
      frameSize = 2 * soundStruct->channelCount;
      if (((soundStruct->samplingRate != 44100) && (soundStruct->samplingRate != 22050)) ||
	  (soundStruct->dataFormat != SND_FORMAT_LINEAR_16)) {
	resamplingEnabled = YES;
	samplingRate = (soundStruct->samplingRate >= 44100) ? 44100 : 22050;
	rateConvert = soundStruct->samplingRate / 44100.0;
      }
      else {
	samplingRate = soundStruct->samplingRate;
	rateConvert = 1.0;
      }
      if (!resamplingEnabled && preloadingEnabled) {
				/* If possible and if requested, pre-enqueue the first buffers */
	[soundStream activate];
	[soundStream pause:self];
	[self prepareToPlay];
      }
      if (soundStruct->samplingRate < 22000.0)
	[soundOutDevice setParameter:NX_SoundDeviceDeemphasize toBool:YES];
    }
  }
  NSLog(@"sampling rate: %d data format: %d rate conversion:%f\n", samplingRate, soundStruct->dataFormat, rateConvert);
  return self;
}

- (SndSoundStruct *) soundStruct
{
  return soundStruct;
}

- (Sound *) sound
{
  return sound;
}

- initWithSound:(Snd *) aSound andNote: (MKNote *) note
{
  [self init];
  [self setSound: aSound];
  return self;
}

- setNoteTag:(int)aTag
{
  noteTag = aTag;
  return self;
}

- (int)noteTag
{
  return noteTag;
}

- (double)activationTime
{
  return activationTime;
}

- setPitchBend:(float)aPitchBend;
{
  pitchBend = aPitchBend;
  return self;
}

- setTransposition:(float)aTransposition;
{
  transposition = aTransposition;
  return self;
}

- setAmp:(float)anAmp;
{
  float tmp = anAmp * volume * velocity;
  amp = anAmp;
  [soundStream setGainLeft:tmp*leftPan right:tmp*rightPan];
  return self;
}

- setVolume:(float)aVolume;
{
  float tmp = amp * aVolume * velocity;
  volume = aVolume;
  [soundStream setGainLeft:tmp*leftPan right:tmp*rightPan];
  return self;
}

- setVelocity:(float)aVelocity;
{
  float tmp = amp * volume * aVelocity;
  velocity = aVelocity;
  [soundStream setGainLeft:tmp*leftPan right:tmp*rightPan];
  return self;
}

- setBearing:(float)aBearing;
{
  float tmp = amp * volume * velocity;
  if (aBearing < 0) {
    leftPan = 1.0;
    rightPan = 1.0 + aBearing;
  }
  else {
    leftPan = 1.0 - aBearing;
    rightPan = 1.0;
  }
  [soundStream setGainLeft:tmp*leftPan right:tmp*rightPan];
  return self;
}

- setAmp:(float)anAmp volume:(float)aVolume bearing:(float)aBearing
{
  float tmp;
  amp = anAmp;
  volume = aVolume;
  if (aBearing < 0) {
    leftPan = 1.0;
    rightPan = 1.0 + aBearing;
  }
  else {
    leftPan = 1.0 - aBearing;
    rightPan = 1.0;
  }
  tmp = amp * volume * velocity;
  [soundStream setGainLeft:tmp*leftPan right:tmp*rightPan];
  return self;
}
	
- (void) enablePreloading:(BOOL)flag
{
  BOOL wasEnabled = preloadingEnabled;
  preloadingEnabled = flag;
  if ((wasEnabled != preloadingEnabled)) {
    [MKConductor lockPerformance];
    if (!preloadingEnabled && !resamplingEnabled)
      [soundStream deactivate];
    else if (!resamplingEnabled) {
      [soundStream activate];
      [soundStream pause:self];
      [self prepareToPlay];
    }
    [MKConductor unlockPerformance];
  }
}

- enableResampling:(BOOL)flag
{
  BOOL wasEnabled = resamplingEnabled;
  resamplingEnabled = (flag || (soundStruct->dataFormat != SND_FORMAT_LINEAR_16) ||
		       (!(soundStruct->samplingRate == 44100) || (soundStruct->samplingRate == 22050)));
  if ((wasEnabled != resamplingEnabled) && preloadingEnabled) {
    if (resamplingEnabled)
      [soundStream deactivate];
    else {
      [soundStream activate];
      [soundStream pause:self];
      [self prepareToPlay];
    }
  }
  return self;
}

static char *resample(char *inData, char *outData, int bufsize,
		      float increment, float *fraction, int channels, int format)
{
  register int frac = 32768 * *fraction;
  register int inc = 32768 * increment;

  NSLog(@"resampling\n");
  if (channels == 1) {
    if (format == SND_FORMAT_LINEAR_16) {
      register short *in = (short *)inData;
      register short *out = (short *)outData;
      register short *end = out + bufsize;
      register int diff;
      diff = (((short)NSSwapBigShortToHost(*(in + 1))) - 
	      ((short)NSSwapBigShortToHost(*in)));
	
      while (out < end) {
	*out++ = 
	  NSSwapHostShortToBig(((short)NSSwapBigShortToHost(*in)) + 
			       (short)((diff * frac) >> 15));
	frac += inc;
	if (frac >= 32768) {
	  do ++in; while ((frac-=32767) >= 32768);
	  diff = (((short)NSSwapBigShortToHost(*(in+1))) - 
		  ((short)NSSwapBigShortToHost(*in)));
	}
      }
      inData = (char *)in;
    }
    else if (format == SND_FORMAT_MULAW_8) {
      register unsigned char *in = (unsigned char *)inData;
      register short *out = (short *)outData;
      register short *end = out + bufsize;
      register int diff = muLaw[(int)*(in + 1)] - muLaw[(int)*in];
	
      while (out < end) {
	*out++ = 
	  (short)NSSwapHostShortToBig((short)(muLaw[(int)*in] + 
					      (short)((diff * frac) >> 15)));
	frac += inc;
	if (frac >= 32768) {
	  do ++in; while ((frac-=32767) >= 32768);
	  diff = muLaw[(int)*(in+1)] - muLaw[(int)*in];
	}
      }
      inData = (char *)in;
    }
  }
  else {
    register short *in = (short *)inData;
    register short *out = (short *)outData;
    register short *end = out + bufsize;
    register int diff1 = (((short)NSSwapBigShortToHost(*(in + 2))) - 
			  ((short)NSSwapBigShortToHost(*in)));
    register int diff2 = (((short)NSSwapBigShortToHost(*(in + 3))) - 
			  ((short)NSSwapBigShortToHost(*(in + 1))));

    while (out < end) {
      *out++ = 
	(short)NSSwapHostShortToBig(((short)NSSwapBigShortToHost(*in)) + 
				    (short)((diff1 * frac) >> 15));
      *out++ = 
	(short)NSSwapHostShortToBig(((short)
				     NSSwapBigShortToHost(*(in + 1))) + 
				    (short)((diff2 * frac) >> 15));
      frac += inc;
      if (frac >= 32768) {
	do in+=2; while ((frac-=32767) >= 32768);
	diff1 = (((short)NSSwapBigShortToHost(*(in + 2))) - 
		 ((short)NSSwapBigShortToHost(*in)));
	diff2 = (((short)NSSwapBigShortToHost(*(in + 3))) - 
		 ((short)NSSwapBigShortToHost(*(in + 1))));
      }
    }
    inData = (char *)in;
  }
  *fraction = (float)frac / 32768.0;
  return inData;
}

- (void) deactivate
{
  int i;
  noteTag = MAXINT;

  [super deactivate];
  [soundStream deactivate];
  for (i=1; i<16; i++)
    if (buffers[i] != NULL) {
      NSZoneFree([self zone],buffers[i]);
      buffers[i] = NULL;
    }
  bufferTag = 0;
  performDuration = 0;
  if ([soundStream isActive] && !resamplingEnabled && preloadingEnabled) {
    [soundStream activate];
    [soundStream pause:nil];
    [self prepareToPlay];
  }
}

- abort
{
  [soundStream abort:nil];
//  if (status != MK_inactive)
//    [self deactivate];
//  else [self deactivateSelf];
  [self deactivate];
  return self;
}

- activateSelf
{
  activationTime = [conductor time];

  if (![soundStream isActive]) {
    [soundStream activate];
    performDuration = 0;
  }
  if ([soundStream isActive]) {
    if (resamplingEnabled || !preloadingEnabled)
      [self prepareToPlay];
    else [soundStream resume:nil];
  }
  else return nil; 

  return self;
}

- perform
{
  int remaining = endData - data;
	
  if (resamplingEnabled) {
    float   increment = pitchBend * transposition * rateConvert;
    int     outRemaining = 
      ((int)((float)(remaining / frameSize) / increment)) * frameSize;
    int     n;
    BOOL final = NO;
		
    if (outRemaining >= frameSize) {
      int bufTag;
      if (chunk == 0) {
	if (++bufferTag == 16) bufferTag = 1;
	// buffer = [NSMutableData dataWithCapacity: bufferSize];
	buffer = NSZoneMalloc([self zone], sizeof(char)*bufferSize);
	buffers[bufferTag] = buffer;
	bufptr = buffer;
      }
      bufTag = bufferTag;

      if (outRemaining <= (bufferSize/nchunks-frameSize)) {
	n = outRemaining;
	final = YES;
	bufTag |= 0x10;
      }
      else n = bufferSize / nchunks;

      data = resample(data, bufptr, n / 2, increment, &fraction,
		      soundStruct->channelCount, soundStruct->dataFormat);

      bufptr += n;

      if ((++chunk == nchunks) || final) {
	[soundStream playBuffer:(void *)buffer size:bufptr - buffer
		     tag:bufTag channelCount:soundStruct->channelCount
		     samplingRate:samplingRate];
	chunk = 0;
      }
    }
  }
  else {
      fprintf(stderr, "playing to buffer\n");
/*
    if (remaining > frameSize)
      [soundStream playBuffer:(void *)data size:soundStruct->dataSize
		   tag:MAXINT channelCount:soundStruct->channelCount
		   samplingRate:samplingRate];
*/
    [sound play]; // LMS kludge to check sample rates

    data += soundStruct->dataSize;
  }

//  nextPerform = performDuration;
  return self;
}

- (void) soundStream:aStream didCompleteBuffer:(int)aTag
  /* Sent by the stream whenever it's finished with a play request.
  * This happens in the main thread so we need the locks below if 
  * we're running the Music Kit in a separate thread.
  */
{
  BOOL final = NO;
  [MKConductor lockPerformance]; 
  if (aTag == MAXINT) {
    aTag = 0;
    final = YES;
  }
  else if (aTag & 0x10) {
    aTag &= 0xF;
    final = YES;
  }
	
  /* Free the buffer if it has been allocated by the perform method */
  if (aTag) {
    if (buffers[aTag] != NULL)
      //			NX_FREE(buffers[aTag]);
      //			[[buffers objectAtIndex: aTag] release];
      ;
    buffers[aTag] = NULL;
  }
	
  if (final) {
    [self deactivate];
    velocity = 1.0;
  }
  [MKConductor unlockPerformance];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"%@ noteTag %d\n", [[(PlayingSound *) self class] description], noteTag];
}

@end
