/* SNDindirect.m -- Functions to assist in handling fragmented Sound objects
 *
 * char *getblock(id aSound, int inskip, int nsamps)
 * int putblock(id aSound, int inskip, int nsamps, char *samples)
 * 
 * jwp@silvertone.Princeton.EDU, 4/90
 */

#import <stdio.h>
#import <stdlib.h>
#import <soundkit/Sound.h>

/* Macros:
 *	MIN(a,b) = minimum of a and b
 *	DATA(s) = pointer to data in the SNDSoundStruct pointed to by s
 *	SIZE(s) = number of bytes in the SNDSoundStruct pointed to by s
 */
#define MIN(a,b)	((a > b) ? b : a)
#define DATA(s)		(char *)(s) + (s)->dataLocation
#define SIZE(s)		(s)->dataSize

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

/* char *getblock(id aSound, int inskip, int nsamps)
 *	Gets a block of 'nsamps' sample frames from the Sound object
 *	'aSound', starting at frame 'inskip'.  These are placed in an
 *	array a pointer to which is returned (the array is either of
 *	shorts or floats, depending on the sample type).  Returns
 *	NULL on error.
 */
char *getblock(id aSound, int inskip, int nsamps)
{
	int inbytes, nbytes, fragbytes, nchans;
	char *samples, *inptr, *outptr;
	SNDSoundStruct **slist;

/* Handle some basic errors like: nil sound pointer, no samples,
 * too many samples
 */
	if (!aSound || !nsamps)
		return NULL;
	if (inskip + nsamps > [aSound sampleCount])
		return NULL;

/* Convert the inskip and nsamps arguments to a byte count by multiplying
 * by the number of channels and the number of bytes per sample
 */
	nchans = [aSound channelCount];
	switch([aSound dataFormat]) {
		case SND_FORMAT_LINEAR_16:
			inbytes = inskip * nchans * 2;
			nbytes = nsamps * nchans * 2;
			break;
		case SND_FORMAT_FLOAT:
			inbytes = inskip * nchans * 4;
			nbytes = nsamps * nchans * 4;
			break;
		default:
			return NULL;
	}

/* If the sound isn't indirect, then just return a pointer into the
 * sound.  Otherwise, we have to copy it to an array.
 */
	if (![aSound needsCompacting])
		samples = (char *)[aSound data] + inbytes;
	else {
	
	/* Allocate the array for the samples
	 */
	 	if ((samples = malloc(nbytes)) == NULL) {
			fprintf(stderr,"getblock: Out of memory\n");
			return NULL;
		}
	/* Get the list of SoundStructs and seek into the sound
	 */
	 	for (slist = (SNDSoundStruct **)[aSound data]; 
		     inbytes > SIZE(*slist); 
		     slist++)
			inbytes -= SIZE(*slist);
	
	/* Use bcopy to move the bytes into the array.  Be careful
	 * not to overshoot fragment boundaries.
	 */
	 	inptr = DATA(*slist) + inbytes;
		fragbytes = MIN((SIZE(*slist) - inbytes), nbytes);
		outptr = samples;
		while (nbytes > 0) {
			bcopy(inptr,outptr,fragbytes);
			outptr += fragbytes;
			if ((nbytes -= fragbytes) <= 0)
				break;
			slist++;
			inptr = DATA(*slist);
			fragbytes = MIN(SIZE(*slist), nbytes);
		}
	}
	return samples;
}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
/* int putblock(id aSound, int inskip, int nsamps, char *samples)
 * 	Copies a block of 'nsamps' contiguous samples from 'samples' to
 *	'aSound', starting at 'inskip' samples.  This is designed
 *	to be the reverse of getblock().  Note that if the contiguous
 *	block was obtained from getblock(), putblock() will always
 *	"do the right thing".  Returns -1 on error, 1 otherwise.
 */
int putblock(id aSound, int inskip, int nsamps, char *samples)
{
	int inbytes, nbytes, fragbytes,nchans;
	char *outptr;
	SNDSoundStruct **slist;

/* Handle some basic errors like: nil sound pointer, no samples
 * too many samples, etc.
 */
	if (!aSound || !nsamps)
		return -1;
	if (inskip + nsamps > [aSound sampleCount])
		return -1;

/* Convert the inskip and nsamps arguments to a byte count by multiplying
 * by the number of channels and the number of bytes per sample
 */
	nchans = [aSound channelCount];
	switch([aSound dataFormat]) {
		case SND_FORMAT_LINEAR_16:
			inbytes = inskip * nchans * 2;
			nbytes = nsamps * nchans * 2;
			break;
		case SND_FORMAT_FLOAT:
			inbytes = inskip * nchans * 4;
			nbytes = nsamps * nchans * 4;
			break;
		default:
			return -1;
	}

/* If this is not a fragmented sound, then just copy the samples
 * from one array to the other.
 */
	if (![aSound needsCompacting]) {
		outptr = (char *)[aSound data] + inbytes;
		if (outptr != samples)
			bcopy(samples,outptr,nbytes);
	}

/* Otherwise, distribute the samples among the fragments
 */
	else {
	/* Get the list of SoundStructs and seek into the sound
	 */
	 	for (slist = (SNDSoundStruct **)[aSound data]; 
		     inbytes > SIZE(*slist); 
		     slist++)
			inbytes -= SIZE(*slist);
	 	outptr = DATA(*slist) + inbytes;
		fragbytes = MIN((SIZE(*slist) - inbytes), nbytes);

	/* If we don't need to deal with fragmentation, then don't
	 */
		if (outptr == samples && fragbytes == nbytes)
			return 1;

	/* Copy the samples into the various sound fragments.
	 */
		while (nbytes > 0) {
			bcopy(samples,outptr,fragbytes);
			outptr += fragbytes;
			if ((nbytes -= fragbytes) <= 0)
				break;
			slist++;
			outptr = DATA(*slist);
			fragbytes = MIN(SIZE(*slist), nbytes);
		}
	}
	return 1;
}
