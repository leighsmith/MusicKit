/* EdSoundView.m -- implementation for custom SoundView
 *
 * jwp@silvertone.Princeton.edu, 11/89
 * Version 1.2, 1/90
 *	-- Added enveloping
 * Version 1.21, 2/90
 *	-- Fixed enveloping for stereo files
 *	-- Fixed enveloping and erasing to maintain selection
 * Version 1.3, 2/90
 *	-- Fixed bug that allowed enveloping of fragmented files
 * Version 1.4, 4/90
 *	-- Now envelopes edited sounds
 */

#import "EdSoundView.h"
#import <appkit/Panel.h>
#import <soundkit/soundkit.h>
#import <string.h>

/* Prototypes of functions in SNDindirect
 */
extern char *getblock(id aSound, int inskip, int nsamps);
extern int putblock(id aSound, int inskip, int nsamps, char *samples);

/* C functions used by EdSoundView methods:
 */

/* makesilence() -- Make a sound full of silence
 *	Returns pointer to silent Sound object
 */
id makesilence(modelsnd,nsamps)
id modelsnd;				/* Sound we're doing this for */
int nsamps;				/* Amount of silence */
{
	id newsnd;		/* The silent sound */
	SNDSoundStruct *s;	/* Sound struct for modelsnd */
	int nbytes;		/* Number of bytes of silence */
	unsigned char *dataptr;	/* Pointer to samples */
	int format;		/* Sound's data format */

/* Use the info in modelsnd to determine the data size, etc. of
 * the silent Sound
 */
	s = [modelsnd soundStruct];
	format = [modelsnd dataFormat];		/* don't use struct dataFormat,
						 * since it might be INDIRECT
						 */
	nbytes = SNDSamplesToBytes(nsamps,s->channelCount,format);
	newsnd = [Sound new];
	[newsnd setDataSize:nbytes 
		dataFormat:format 
		samplingRate:s->samplingRate
		channelCount:s->channelCount
		infoSize:[modelsnd infoSize]];

/* Fill the newsnd data space with zeroes and return
 */
	dataptr = [newsnd data];
	*dataptr = 0;
	bcopy(dataptr,dataptr+1,nbytes-1);	/* Fill with 0's */
	return newsnd;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

@implementation EdSoundView

/* erase -- Zero out the current selection
 */

- erase:sender
{
	id silent;		/* "Sound of silence ..." */
	int start,dur;		/* Start and dur of selection */

/* Get the duration of the selection and make a sound object with
 * that much silence in it.
 */
	[self getSelection:&start size:&dur];
	silent = makesilence(sound,dur);

/* Write the silence to the pasteboard, then paste into current sound.
 */
 	[silent writeToPasteboard];
	[self paste:self];
	[silent free];		/* Free this space */
	if (delegate && [delegate respondsTo:@selector(soundChanged:)])
		[delegate perform:@selector(soundChanged:) with:self];

/* Pasting screws up the selection.  Reset it to where we were.
 */
	[self setSelection:start size:dur];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

/* addSilence -- add some silence to file
 * 	Argument is duration (in seconds) of silence to add
 */
- addSilence:(float)dur
{
	id silent;		/* "Sound of silence ..." */
	int nsamps;


/* Make a Sound object with 'dur' seconds worth of silence in it.
 * Use our current sound as a model for sampling rate, etc.
 */
	nsamps = (int)(dur * [sound samplingRate]);
	silent = makesilence(sound,nsamps);

/* Write the silence to the pasteboard, then paste into current sound.
 */
 	[silent writeToPasteboard];
	[self paste:self];
	[silent free];		/* Free this space */
	if (delegate && [delegate respondsTo:@selector(soundChanged:)])
		[delegate perform:@selector(soundChanged:) with:self];
	return self;
}

/* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = */

#define SNDSHORT SND_FORMAT_LINEAR_16
#define SNDFLOAT SND_FORMAT_FLOAT

/* envelope:Points:
 *	Envelopes the current selection.  See "EnvelopeView.h" for details
 *	about the envelope format.
 */
- envelope:(NXPoint *)env Points:(int)n
{
	id newSound;		/* Scratch sound to work on */
	int start;		/* Starting sample of selection */
	int size;		/* Number of samples to envelope */
	int nchans;		/* Number of channels */
	int format;		/* Format of sound (short/float) */
	char *samples;		/* Pointer to samples */
	short *sout;		/* Pointer to short samples */
	float *fout;		/* Pointer to float samples */

	int nsamps;		/* Number of samples in envelope segment */
	float ampmul, incr;	/* Amplitude factor and increment per sample */

	int i,j;


/* Make a new sound that contains the current selection:
 */
	newSound = [Sound new];
	nchans = [sound channelCount];
	[self getSelection:&start size:&size];
	if (!size)		/* No selection = no envelope */
		return self;
	[newSound copySamples:sound at:start count:size];

/* Get the samples into a contiguous array via getblock().
 * (See SNDindirect.m for info on this function)
 */
	if (!(samples = getblock(newSound,0,size))) {
		fprintf(stderr,"EdSoundView: error in getblock()\n");
		return self;
	}
	format = [newSound dataFormat];
	n--;

/* Two versions of same code:  one for shorts, one for floats.  I could
 * just put a test in the inner loop for SNDSHORT/SNDFLOAT, but that
 * would slow things down.
 */
	if (format == SNDSHORT) {
		sout = (short *)samples;
		for (i=0; i < n; i++) {
			if (!(nsamps = (env[i+1].x - env[i].x) * size))
				continue;
			ampmul = env[i].y;
			incr = (env[i+1].y - env[i].y) / nsamps;
			while (nsamps--) {
				for (j = 0; j < nchans; j++)
					*sout++ *= ampmul;
				ampmul += incr;
			}
		}
	}
	else if (format == SNDFLOAT) {
		fout = (float *)samples;
		for (i=0; i < n; i++) {
			if (!(nsamps = (env[i+1].x - env[i].x) * size))
				continue;
			ampmul = env[i].y;
			incr = (env[i+1].y - env[i].y) / nsamps;
			while (nsamps--) {
				for (j = 0; j < nchans; j++)
					*fout++ *= ampmul;
				ampmul += incr;
			}
		}
	}

/* Put the samples back into newSound and update the sound by making
 * a phony paste -- writing directly to the
 * sound would force a complete re-draw of the view.
 */
	putblock(newSound,0,size,samples);
	[newSound writeToPasteboard];
	[self paste:self];

/* Pasting screws up the selection.  Reset it to where we were so that
 * we can apply the same envelope multiple times.
 */
	[self setSelection:start size:size];
	return self;
}

@end

