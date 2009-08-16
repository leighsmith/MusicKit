#import "EnsembleDoc.h"
#import "SoundPerformer.h"
#import "SamplerInstrument.h"
#import <appkit/nextstd.h>
#import <limits.h>
#import <sound/mulaw.h>

extern BOOL	robustSound;

@implementation SoundPerformer:Performer
{
}

- prepareToPlay
{
	int i, n, performDataSize;
	
	if (!sound) return self;

	[self setAmp:amp];

	data = ((char *)sound + sound->dataLocation);
	endData = data + sound->dataSize;

	if (resamplingEnabled) {
		bufferSize = ((robustSound) ? 65536 : 16384) * 
			((float)samplingRate)/44100.0 * ((float)(sound->channelCount))/2.0;
		nchunks = (pitchBend) ? ((robustSound) ? 16 : 4) : 1;
		performDataSize = bufferSize/nchunks;
		fraction = 0;
		chunk = 0;
		if (sound->dataSize < performDataSize) performDataSize = sound->dataSize;
	}
	else {
		bufferSize = sound->dataSize;
		performDataSize = sound->dataSize;
	}
	
	performDuration = (double)(performDataSize/frameSize)/(double)samplingRate;
	
	bufferTag = 0;

	n = (resamplingEnabled) ? 4*nchunks : 1;
	for (i = 0; i < n; i++)
		if (endData > data) [self perform];

	return self;
}

- reset
{
	transposition = pitchBend = 1.0;
	conductor = [Conductor clockConductor];
	amp = volume = velocity = 1.0;
	leftPan = rightPan = 1.0;
	activationTime = 0;
	[soundStream setGainLeft:1.0 right:1.0];
	if (soundOutDevice != [soundStream device]) {
		[soundStream deactivate];
		[soundStream setDevice:soundOutDevice];
	}
	if (sound) {
		if ([soundStream isActive] && !resamplingEnabled && preloadingEnabled) {
			/* If possible and if requested, pre-enqueue the first buffers */
			[soundStream activate];
			[soundStream pause:self];
			[self prepareToPlay];
		}
	}
	return self;
}

- init
{
	[super init];
	soundStream = [[NXPlayStream alloc] initOnDevice:soundOutDevice];
	[soundStream setDelegate:self];
	return [self reset];
}

- free
{
	int i;
	[soundStream abort:nil];
	[soundStream setDelegate:nil];
	[soundStream setDevice:nil];
	for (i=1; i<16; i++)
		if (buffers[i] != NULL)
			 NXZoneFree([self zone], buffers[i]);
	[NXApp perform:@selector(delayedFree:) with:soundStream afterDelay:500
		cancelPrevious:NO];
	return [super free];
}

- touch
{
	[soundStream activate];
	[soundStream pause:self];
	[soundStream playBuffer:(void *)sound+sound->dataLocation 
		size:sound->dataSize
		tag:0 channelCount:sound->channelCount
		samplingRate:samplingRate];
	[soundStream deactivate];
	return self;
}

- setSoundStruct:(SNDSoundStruct *) aSound
{
	if (sound != aSound) {
		if (status == MK_active) [self deactivate];
		[soundStream deactivate];
		sound = aSound;
		if (sound) {
			[self touch];
			frameSize = 2 * sound->channelCount;
			if ((!(sound->samplingRate == 44100) || (sound->samplingRate == 22050)) ||
				(sound->dataFormat != SND_FORMAT_LINEAR_16)) {
				resamplingEnabled = YES;
				samplingRate = (sound->samplingRate >= 44100) ? 44100 : 22050;
				rateConvert = sound->samplingRate/22050.0;
			}
			else {
				samplingRate = sound->samplingRate;
				rateConvert = 1.0;
			}
			if (!resamplingEnabled && preloadingEnabled) {
				/* If possible and if requested, pre-enqueue the first buffers */
				[soundStream activate];
				[soundStream pause:self];
				[self prepareToPlay];
			}
			if (sound->samplingRate < 22000.0)
				[soundOutDevice setParameter:NX_SoundDeviceDeemphasize toBool:YES];
		}
	}
	return self;
}

- (SNDSoundStruct *) soundStruct
{
	return sound;
}

- initWithSound:(SNDSoundStruct *)aSoundStruct
{
	[self init];
	[self setSoundStruct:aSoundStruct];
	return self;
}

- setTag:(int)aTag
{
	tag = aTag;
	return self;
}

- (int)tag
{
	return tag;
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
	
- enablePreloading:(BOOL)flag
{
	BOOL wasEnabled = preloadingEnabled;
	preloadingEnabled = flag;
	if ((wasEnabled != preloadingEnabled)) {
	        [Conductor lockPerformance];
		if (!preloadingEnabled && !resamplingEnabled)
			[soundStream deactivate];
		else if (!resamplingEnabled) {
			[soundStream activate];
			[soundStream pause:self];
			[self prepareToPlay];
		}
	        [Conductor unlockPerformance];
	}
	return self;
}

- enableResampling:(BOOL)flag
{
	BOOL wasEnabled = resamplingEnabled;
	resamplingEnabled = (flag || (sound->dataFormat != SND_FORMAT_LINEAR_16) ||
		(!(sound->samplingRate == 44100) || (sound->samplingRate == 22050)));
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

	if (channels == 1) {
		if (format == SND_FORMAT_LINEAR_16) {
			register short *in = (short *)inData;
			register short *out = (short *)outData;
			register short *end = out + bufsize;
			register int diff;
			diff = (((short)NXSwapBigShortToHost(*(in + 1))) - 
					((short)NXSwapBigShortToHost(*in)));
	
			while (out < end) {
				*out++ = 
				  NXSwapHostShortToBig(((short)NXSwapBigShortToHost(*in)) + 
									   (short)((diff * frac) >> 15));
				frac += inc;
				if (frac >= 32768) {
					do ++in; while ((frac-=32767) >= 32768);
					diff = (((short)NXSwapBigShortToHost(*(in+1))) - 
							((short)NXSwapBigShortToHost(*in)));
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
				  (short)NXSwapHostShortToBig((short)(muLaw[(int)*in] + 
													  (short)((diff * frac) >> 15)));
				frac += inc;
				if (frac >= 32768) {
					do ++in; while ((frac-=32767) >= 32768);
					diff = muLaw[(int)*(in+1)] - muLaw[(int)*in];
				}
			}
			inData = (char *)in;
		}
	} else {
		register short *in = (short *)inData;
		register short *out = (short *)outData;
		register short *end = out + bufsize;
		register int diff1 = (((short)NXSwapBigShortToHost(*(in + 2))) - 
							  ((short)NXSwapBigShortToHost(*in)));
		register int diff2 = (((short)NXSwapBigShortToHost(*(in + 3))) - 
							  ((short)NXSwapBigShortToHost(*(in + 1))));

		while (out < end) {
			*out++ = 
			  (short)NXSwapHostShortToBig(((short)NXSwapBigShortToHost(*in)) + 
										  (short)((diff1 * frac) >> 15));
			*out++ = 
			  (short)NXSwapHostShortToBig(((short)
										   NXSwapBigShortToHost(*(in + 1))) + 
										  (short)((diff2 * frac) >> 15));
			frac += inc;
			if (frac >= 32768) {
				do in+=2; while ((frac-=32767) >= 32768);
				diff1 = (((short)NXSwapBigShortToHost(*(in + 2))) - 
						 ((short)NXSwapBigShortToHost(*in)));
				diff2 = (((short)NXSwapBigShortToHost(*(in + 3))) - 
						 ((short)NXSwapBigShortToHost(*(in + 1))));
			}
		}
		inData = (char *)in;
	}
	*fraction = (float)frac / 32768.0;
	return inData;
}

- deactivateSelf
{
	int i;
	tag = MAXINT;
	[soundStream deactivate];
	for (i=1; i<16; i++)
		if (buffers[i] != NULL) {
			 NXZoneFree([self zone],buffers[i]);
			 buffers[i] = NULL;
		}
	bufferTag = 0;
	performDuration = 0;
	if ([soundStream isActive] && !resamplingEnabled && preloadingEnabled) {
		[soundStream activate];
		[soundStream pause:nil];
		[self prepareToPlay];
	}

	return self;
}

- abort
{
	[soundStream abort:nil];
	if (status != MK_inactive)
		[self deactivate];
	else [self deactivateSelf];
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
				buffer = NXZoneMalloc([self zone], sizeof(char)*bufferSize);
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
									sound->channelCount, sound->dataFormat);

			bufptr += n;

			if ((++chunk == nchunks) || final) {
				[soundStream playBuffer:(void *)buffer size:bufptr - buffer
				 tag:bufTag channelCount:sound->channelCount
				 samplingRate:samplingRate];
				chunk = 0;
			}
		}
	} else {
		if (remaining > frameSize)
			[soundStream playBuffer:(void *)data size:sound->dataSize
				 tag:MAXINT channelCount:sound->channelCount
				 samplingRate:samplingRate];
		data += sound->dataSize;
	}

	nextPerform = performDuration;
	return self;
}

extern void _MKLock(void);
extern void _MKUnlock(void);

- soundStream:aStream didCompleteBuffer:(int)aTag
 /* Sent by the stream whenever it's finished with a play request.
  * This happens in the main thread so we need the locks below if 
  * we're running the Music Kit in a separate thread.
  */
{
	BOOL final = NO;
	_MKLock();  // Or [Conductor lockPerformance]; 
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
			NX_FREE(buffers[aTag]);
		buffers[aTag] = NULL;
	}
	
	if (final) {
		[self deactivate];
		velocity = 1.0;
	}
	_MKUnlock(); // Or [Conductor unlockPerformance]
	return self;
}

@end
