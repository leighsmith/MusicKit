#import "_Sndlibst.h"

//#define USE_MACH_MEMORY_ALLOCATION

#ifndef SND_FORMAT_UNSPECIFIED
#import "SndFormats.h"
#ifndef USE_NEXTSTEP_SOUND_IO
#import "sounderror.h"
#endif
#endif

#import "SndStruct.h"
#import "SndEndianFunctions.h"
#import <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */

#import <stdio.h> // for FILE

	/*
	 *   functions.h
	 * A library of functions intended to be compatible with NeXTs
	 * now defunct SoundKit.
	 *
	 *		Stephen Brandon, 1999
	 *		S.Brandon@music.gla.ac.uk
	 */
 
int		SndPrintFrags(SndSoundStruct *sound);
int		SndSampleWidth(int format);
int		SndBytesToSamples(int byteCount, int channelCount, int dataFormat);
int		SndSamplesToBytes(int sampleCount, int channelCount, int dataFormat);
float	SndConvertDecibelsToLinear(float db);
float	SndConvertLinearToDecibels(float lin);
int		SndConvertSound(const SndSoundStruct *fromSound, SndSoundStruct **toSound);
int		SndConvertSoundGoodQuality(const SndSoundStruct *fromSound, SndSoundStruct **toSound);
int		SndConvertSoundHighQuality(const SndSoundStruct *fromSound, SndSoundStruct **toSound);
void	*SndGetDataAddresses(int sample,
			const SndSoundStruct *theSound,
			int *lastSampleInBlock,
			int *currentSample);
int		SndSampleCount(const SndSoundStruct *sound);
int		SndGetDataPointer(const SndSoundStruct *sound, char **ptr, int *size, 
			int *width);
/* only useful for non-fragmented sounds */
int		SndFree(SndSoundStruct *sound);
extern int		SndAlloc(SndSoundStruct **sound, int dataSize, int dataFormat,
			int samplingRate, int channelCount, int infoSize);
int		SndCompactSamples(SndSoundStruct **toSound, SndSoundStruct *fromSound);
/* There's a wee bit of a problem when compacting sounds. That is the info
 * string. When a sound isn't fragmented, the size of the info string is held
 * in "dataLocation" by virtue of the fact that the info will always
 * directly precede the dataLocation. When a sound is fragmented though,
 * dataLocation is taken over for use as a pointer to the list of fragments.
 * What NeXTSTEP does is to then set the dataSize of the main SNDSoundStruct
 * to 8192 -- a page of VM. Therefore, there is no longer any explicit
 * record of how long the info string was. When the sound is compacted, bytes
 * seem to be read off the main SNDSoundStruct until a NULL is reached, and
 * that is assumed to be the end of the info string.
 * Therefore I am doing things differently. In a fragmented sound, dataSize
 * will be the length of the SndSoundStruct INCLUDING the info string, and
 * adjusted to the upper 4-byte boundary.
 */
int		SndCopySound(SndSoundStruct **toSound, const SndSoundStruct *fromSound);
int		SndCopySamples(SndSoundStruct **toSound, SndSoundStruct *fromSound,
		int startSample, int sampleCount);
int		SndInsertSamples(SndSoundStruct *toSound, const SndSoundStruct *fromSound, 
		int startSample);
SndSoundStruct * _SndCopyFrag(const SndSoundStruct *fromSoundFrag);
SndSoundStruct * _SndCopyFragBytes(SndSoundStruct *fromSoundFrag, int startByte, int byteCount);
/* Does the same as _SndCopyFrag, but used for `partial' frags that occur when 
 * you insert or delete data from a SndStruct.
 * If byteCount == -1, uses all data from startByte to end of frag.
 * Does not make copy of fragged sound. Info string should therefore be only 4 bytes,
 * but this takes account of longer info strings if they exist.
 */
int		SndDeleteSamples(SndSoundStruct *sound, int startSample, int sampleCount);
unsigned char SndMulaw(short linearValue);
short	SndiMulaw(unsigned char mulawValue);
int		SndRead(FILE *fp, SndSoundStruct **sound, char *filetype);
int		SndReadHeader(int fd, SndSoundStruct **sound);
int		SndReadSoundfile(const char *path, SndSoundStruct **sound);
int		SndWriteHeader(int fd, SndSoundStruct *sound);
int		SndWrite(int fd, SndSoundStruct *sound);
int		SndWriteSoundfile(const char *path, SndSoundStruct *sound);
int		SndSwapSoundToHost(void *dest, void *src, int sampleCount, int channelCount, int dataFormat);
int		SndSwapHostToSound(void *dest, void *src, int sampleCount, int channelCount, int dataFormat);
