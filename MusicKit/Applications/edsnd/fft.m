/* fft.m -- FFT support for FFTView and SpectrumView classes
 * Functions contained in this file:
 *	float *getframe()	-- gets a frame of samples from a sound
 *	float scaledata()	-- scales data for dB, LINEAR, and/or GRAYSCALE
 *
 * jwp@silvertone.Princeton.edu
 * smb@datran2.uunet.uu.net
 * 02/90
 * Added support for indirect format Sounds, 03/90
 */

#import <soundkit/Sound.h>
#import <stdio.h>
#import <math.h>
#import "fft.h"

extern char *getblock(id aSound, int inskip, int nsamps);

/* getframe() -- Gets a frame of samples from a sound
 *
 * This function gets 'nsamps' samples from 'sound' starting at
 * sample frame 'startsamp'.  This function will convert shorts to floats
 * and stereo to mono (the channels are added together).  getframe()
 * also allocates its own sample buffer, and returns a pointer to that
 * buffer.
 */

float *getframe(sound,startsamp,nsamps)
id sound;		/* Sound object */
int startsamp;		/* Starting sample frame */
int nsamps;		/* Number of sample frames to get */
{
	static float *sframe = NULL;		/* Sample buffer */	
	static double *hanning = NULL;		/* Hanning window */
	static int framesize;			/* Last framesize */
	short *idata;				/* Pointers to samples */
	float *fdata;				/*    (shorts or floats) */
	int nchans;				/* Channel count */
	int i,j;
	float f;

	if (!sound) 
		return 0;

/* If we have a new frame size, allocate a new buffer and a new
 * Hanning window.
 */
	if (framesize != nsamps) {
		if (sframe && hanning) {
			free(sframe);
			free(hanning);
		}
		sframe = malloc(nsamps * sizeof(float));
		hanning = malloc(nsamps * sizeof(double));
		create_hanning(hanning, nsamps, 1.);	/* (see fft_net.c) */
		framesize = nsamps;
	}
	nchans = [sound channelCount];

/* For either short or float samples, add all channels together, multiply by
 * the Hanning window and store result in buffer
 */
        switch([sound dataFormat]) {
                case SND_FORMAT_LINEAR_16:
//			idata = (short *)[sound data] + startsamp*nchans;
			if ((idata = 
			     (short *)getblock(sound,startsamp,framesize))
			    == NULL)
				return NULL;
			for (i = 0; i < framesize; i++) {
				for (j = 0, f= 0.0; j < nchans; j++, idata++)
					f += *idata;
				sframe[i] = f * hanning[i];
			}
                        break;
                case SND_FORMAT_FLOAT:
//			fdata = (float *)[sound data] + startsamp*nchans;
			if ((fdata = 
			     (float *)getblock(sound,startsamp,framesize))
			    == NULL)
				return NULL;
			for (i = 0; i < framesize; i++) {
				f = 0.0;
				for (j = 0; j < nchans; j++, fdata++)
					f += *fdata;
				sframe[i] = f * hanning[i];
			}
                        break;

                default:
			NXRunAlertPanel("FFTView","Unknown sound data format",
					"OK",NULL,NULL);
                        return 0;
                        break;
        }
	return sframe;
}

/* scaledata() -- Scale FFT output
 *
 * Does following scaling:
 *	dB or LINEAR:   in dB (logarhythmic) scale, output = 20 * log10(input)
 *			in LINEAR scale, output = input / FFT_size
 *	GRAYSCALE:	output is values 0.0 to 1.0 representing PostScript
 *			grayscale values.
 * if 'scalemask' is 0 (default), LINEAR scaling is done.  To get
 * dB and/or grayscale output, scalemask should be set to dBMASK or
 * GRAYSCALEMASK or an OR-ing of those values (dBMASK|GRAYSCALEMASK).
 * If 'mean' is not NULL, the index of the mean frequency within the
 * FFT frame will be placed there.  The function returns the peak
 * amplitude found in the frame.
 */

float scaledata(inptr,outptr,nsamps,scalemask,mean)
float *inptr, *outptr;			/* Input and output buffers */
int nsamps;				/* Size of buffer */
int scalemask;				/* dB, GRAYSCALE, or none */
int *mean;				/* (optional) pointer to mean freq. */
{
	float maxamp;
	float slicesum,slicemean;	/* For storing slice info */
	int N = nsamps/2;		/* Convenience variables */
	float *inp, *outp;
	int i;

/* Rescale the FFT results
 */
	for (i=0, slicesum=maxamp=0.0, inp = inptr, outp = outptr;
	     i < N;
	     i++, inp++, outp++) {
		if (!(scalemask & dBMASK))	/* For linear scale: */
			*outp = *inp/nsamps;	/*   scale by 1/npts */
		else				/* For dB scale: */
			*outp = (float)20. * log10(*inp);
		if (*outp > maxamp)		/* Figure peak amp */
			maxamp = *outp;
		slicesum += *outp;		/* And sum of amps */
	}

	if (mean) {
		for (i=slicemean=0, outp=outptr; i < N; i++, outp++) {
			slicemean += *outp * 2.;
			if (slicemean >= slicesum)
				break;
		}
		*mean = i;	/* Just the index into the FFT */
	}

	if (scalemask & GRAYSCALEMASK) {
		slicesum /= (float)(N >> 5);
		for (i = 0, outp = outptr; i < N; i++, outp++) {
			*outp = floor(*outp / slicesum * 50.0) / 50.0;
			*outp = 1.0 - *outp;
		}
	}
	return maxamp;
}

