/******************************************************************************
$Id$

LEGAL:
This framework and all source code supplied with it, except where specified,
are Copyright Stephen Brandon and the University of Glasgow, 1999. You are
free to use the source code for any purpose, including commercial applications,
as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be
error free.  Further, we will not be liable to you if the Software is not fit
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

//#define USE_MACH_MEMORY_ALLOCATION
#include <MKPerformSndMIDI/PerformSound.h>
#include "SndKitDefines.h"

#ifdef GNUSTEP
# include "sounderror.h"
#else
# ifndef USE_NEXTSTEP_SOUND_IO
#  import "sounderror.h"
# endif
#endif /* GNUSTEP */

#include "SndEndianFunctions.h"
#include <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */
#include <stdio.h>     /* for FILE */

@class NSString;

	/*
	 *   functions.h
	 * A library of functions intended to be compatible with NeXTs
	 * now defunct SoundKit.
	 *
	 *		Stephen Brandon, 1999
	 *		stephen@brandonitconsulting.co.uk
	 */

/*!
@function SndStructDescription
 @abstract To come 
 @param sound A SndStructSound containing the Snd
 @result Returns a pointer to a c-string description of the sound.
 */
SNDKIT_API NSString *SndStructDescription(SndSoundStruct *sound);

/*!
@function SndPrintStruct
 @abstract To come 
 @param sound A SndStructSound containing the Snd
 @result prints a description of the sound to stderr. 
 */
SNDKIT_API void	SndPrintStruct(SndSoundStruct *sound);

/*!
@function SndPrintFrags
 @abstract To come 
 @param sound A SndStructSound containing the Snd
 @result Prints, to stdout, a description of the data fragments in the sound.
 */
SNDKIT_API int	SndPrintFrags(SndSoundStruct *sound);

/*!
@function SndFrameSize
 @abstract To come 
 @param sound A SndStructSound containing the Snd
 @result Returns the size of a sample frame in bytes.
 */
SNDKIT_API int SndFrameSize(SndSoundStruct* sound);

/*!
@function SndSampleWidth
 @abstract To come 
 @param format 
 @result Returns the size of a sample in bytes.
 */
SNDKIT_API int	SndSampleWidth(int format);

/*!
@function SndBytesToSamples
 @abstract Given the data size in bytes, the number of channels and the data format, return the number of samples.
 @param byteCount The size of sample data in bytes.
 @param channelCount The number of audio channels.
 @param dataFormat The sample data encoding format.
 @result Return the number of samples
*/
SNDKIT_API int	SndBytesToSamples(int byteCount,
                                  int channelCount,
                                  int dataFormat);

/*!
@function SndSamplesToBytes
 @abstract Calculates the number of bytes needed to store the data specified by the parameters
 @param sampleCount
 @param channelCount
 @param dataFormat
 @result A number of bytes
 */
SNDKIT_API int	SndSamplesToBytes(int sampleCount,
                                  int channelCount,
                                  int dataFormat);

/*!
@function SndConvertDecibelsToLinear
 @abstract Converts the relative deciBel [-oo,0] level dB to a linear amplitude in the range [0,1];
 @param db
 @result The linear equivalent of the relative deciBel level dB
 */
SNDKIT_API float SndConvertDecibelsToLinear(float db);

/*!
@function SndConvertLinearToDecibels
 @abstract Converts a linear amplitude in the range [0,1] to relative deciBels [-oo,0]
 @param lin
 @result The relative decibel equivalent of lin
 */
SNDKIT_API float SndConvertLinearToDecibels(float lin);

/*!
@function SndConvertSound
 @abstract To come 
 @param fromSound
 @param toSound
 @result
 */
SNDKIT_API int SndConvertSound(const SndSoundStruct *fromSound,
                                     SndSoundStruct **toSound);

/*!
@function SndConvertSoundGoodQuality
 @abstract To come 
 @param fromSound
 @param toSound
 @result
 */
SNDKIT_API int SndConvertSoundGoodQuality(const SndSoundStruct *fromSound,
                                                SndSoundStruct **toSound);

/*!
@function SndConvertSoundHighQuality
 @abstract To come 
 @param fromSound
 @param toSound
 @result
 */
SNDKIT_API int SndConvertSoundHighQuality(const SndSoundStruct *fromSound,
                                                SndSoundStruct **toSound);

/*!
@function SndGetDataAddresses
 @abstract To come 
 @param sample
 @param theSound
 @param lastSampleInBlock
 @param currentSample
 @result
 */
SNDKIT_API void	*SndGetDataAddresses(int sample,
                    const SndSoundStruct *theSound,
                                     int *lastSampleInBlock,
                                     int *currentSample);

/*!
@function SndSampleCount
 @abstract returns the number of samples in the Snd
 @param sound A SndStructSound containing the Snd
 @result
 */
SNDKIT_API int SndSampleCount(const SndSoundStruct *sound);

/*!
@function SndGetDataPointer
 @abstract To come 
 @discussion SndGetDataPointer is only useful for non-fragmented sounds
 @param sound A SndStructSound containing the Snd
 @param ptr
 @param size
 @param width
 @result
 */
SNDKIT_API int SndGetDataPointer(const SndSoundStruct *sound, char **ptr, int *size, 
			int *width);

/*!
@function SndFree
 @abstract Frees the sound contained in the structure sound
 @param sound A SndStructSound containing the Snd
 @result
 */
SNDKIT_API int SndFree(SndSoundStruct *sound);

/*!
@function SndAlloc
 @abstract Allocates a sound as specified by the parameters.
 @param sound The address of a SndStructSound pointer inwhich to alloc the Snd
 @param dataSize
 @param dataFormat
 @param samplingRate
 @param channelCount
 @param infoSize
 @result
 */
SNDKIT_API int SndAlloc(SndSoundStruct **sound,
                                   int dataSize,
                                   int dataFormat,
                                   int samplingRate,
                                   int channelCount,
                                   int infoSize);

/*!
@function SndCompactSamples
 @abstract To come
 @discussion
  There's a wee bit of a problem when compacting sounds. That is the info
  string. When a sound isn't fragmented, the size of the info string is held
  in "dataLocation" by virtue of the fact that the info will always
  directly precede the dataLocation. When a sound is fragmented though,
  dataLocation is taken over for use as a pointer to the list of fragments.
  What NeXTSTEP does is to then set the dataSize of the main SNDSoundStruct
  to 8192 -- a page of VM. Therefore, there is no longer any explicit
  record of how long the info string was. When the sound is compacted, bytes
  seem to be read off the main SNDSoundStruct until a NULL is reached, and
  that is assumed to be the end of the info string.
  Therefore I am doing things differently. In a fragmented sound, dataSize
  will be the length of the SndSoundStruct INCLUDING the info string, and
  adjusted to the upper 4-byte boundary.
 
 @param toSound
 @param fromSound
 @result
 */
SNDKIT_API int SndCompactSamples(SndSoundStruct **toSound,
                                 SndSoundStruct *fromSound);

/*!
@function SndCopySound
 @abstract To come 
 @param toSound
 @param fromSound
 @result
 */
SNDKIT_API int SndCopySound(SndSoundStruct **toSound,
                      const SndSoundStruct *fromSound);

/*!
@function SndCopySamples
 @abstract To come 
 @param toSound
 @param fromSound
 @param startSample
 @param sampleCount
 @result
 */
SNDKIT_API int SndCopySamples(SndSoundStruct **toSound,
                              SndSoundStruct *fromSound,
                                         int startSample,
                                         int sampleCount);

/*!
@function SndInsertSamples
 @abstract To come 
 @param toSound
 @param fromSound
 @param startSample
 @result
 */
SNDKIT_API int SndInsertSamples(SndSoundStruct *toSound,
                          const SndSoundStruct *fromSound, 
                                           int startSample);

/*!
@function _SndCopyFrag
 @abstract To come 
 @param fromSoundFrag
 @result
 */
SNDKIT_API SndSoundStruct * _SndCopyFrag(const SndSoundStruct *fromSoundFrag);


/*!
@function _SndCopyFragBytes
 @abstract To come
 @discussion
  _SndCopyFragBytes Does the same as _SndCopyFrag, but used for `partial' frags
  that occur whenyou insert or delete data from a SndStruct.
  If byteCount == -1, uses all data from startByte to end of frag.
  Does not make copy of fragged sound. Info string should therefore be only 4 bytes,
  but this takes account of longer info strings if they exist.
 @param fromSoundFrag
 @param startByte
 @param byteCount
 @result
 */
SNDKIT_API SndSoundStruct * _SndCopyFragBytes(SndSoundStruct *fromSoundFrag,
                                                         int startByte,
                                                         int byteCount);

/*!
@function SndDeleteSamples
 @abstract To come 
 @param sound
 @param startSample
 @param sampleCount
 @result
 */
SNDKIT_API int	SndDeleteSamples(SndSoundStruct *sound,
                                            int startSample,
                                            int sampleCount);

/*!
@function SndMulaw
 @abstract To come 
 @param linearValue
 @result
 */
SNDKIT_API unsigned char SndMulaw(short linearValue);

/*!
@function SndiMulaw
 @abstract To come 
 @param mulawValue
 @result
 */
SNDKIT_API short SndiMulaw(unsigned char mulawValue);

/*!
@function SndRead
 @abstract To come 
 @param fp
 @param sound
 @param filetype
 @result
 */
SNDKIT_API int SndRead(FILE *fp,
             SndSoundStruct **sound,
                 const char *filetype);

/*!
@function SndReadHeader
 @abstract To come 
 @param f
 @param sound
 @result
 */
SNDKIT_API int SndReadHeader(const char *path,
                         SndSoundStruct **sound,
                             const char *fileTypeStr);

/*!
@function SndReadSoundfile
 @abstract To come 
 @param path
 @param sound
 @result
 */
SNDKIT_API int SndReadSoundfile(const char *path,
                            SndSoundStruct **sound);

int SndReadSoundfileRange(const char *path, SndSoundStruct **sound, int startFrame, int frameCount, BOOL bReadData);

/*!
@function SndWriteHeader
 @abstract To come 
 @param fd
 @param sound
 @result
 */
SNDKIT_API int SndWriteHeader(int fd,
                   SndSoundStruct *sound);

/*!
@function SndWrite
 @abstract To come 
 @param fd
 @param sound
 @result
 */
SNDKIT_API int SndWrite(int fd,
             SndSoundStruct *sound);

/*!
@function SndWriteSoundfile
 @abstract To come 
 @param path
 @param sound
 @result
 */
SNDKIT_API int SndWriteSoundfile(NSString *path,
                             SndSoundStruct *sound);

/*!
@function SndSwapSoundToHost
 @abstract To come 
 @param dest
 @param src
 @param sampleCount
 @param channelCount
 @param dataFormat
 @result
 */
SNDKIT_API int SndSwapSoundToHost(void *dest,
                                  void *src,
                                   int sampleCount,
                                   int channelCount,
                                   int dataFormat);

/*!
@function  SndSwapHostToSound
 @abstract To come 
 @param dest
 @param src
 @param sampleCount
 @param channelCount
 @param dataFormat
 @result 
 */
SNDKIT_API int SndSwapHostToSound(void *dest,
                                  void *src,
                                   int sampleCount,
                                   int channelCount,
                                   int dataFormat);
