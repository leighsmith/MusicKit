////////////////////////////////////////////////////////////////////////////////
//
// $Id$
//
//  Description:
//    A library of functions intended to be compatible with NeXTs now defunct SoundKit.
//
//  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
//
//  This framework and all source code supplied with it, except where specified,
//  are Copyright Stephen Brandon and the University of Glasgow, 1999. You are
//  free to use the source code for any purpose, including commercial applications,
//  as long as you reproduce this notice on all such software.
//
//  Software production is complex and we cannot warrant that the Software will be
//  error free.  Further, we will not be liable to you if the Software is not fit
//  for the purpose for which you acquired it, or of satisfactory quality. 
//
//  WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
//  WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
//  OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
//  PARTIES RIGHTS.
//
//  If a court finds that we are liable for death or personal injury caused by our
//  negligence our liability shall be unlimited.  
//
//  WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
//  OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR
//  POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
//  NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED
//  DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND
//  CONDITIONS OF THIS AGREEMENT.
//
//  Portions Copyright (c) 1999, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

/*!
  @header SndFunctions
  @abstract A library of functions originally intended to be compatible with NeXTs now defunct SoundKit.
  @discussion Nowdays, compatibility with NeXT SoundKit functions is not enforced, only the OO class API
	      aims for compatibility to the SoundKit.
 */

#import "SndKitDefines.h"
#import "SndFormat.h"

#ifdef GNUSTEP
# import <Foundation/NSArray.h>
# include <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */
# include <stdio.h>     /* for FILE */
#else
# ifndef USE_NEXTSTEP_SOUND_IO
#  import <Foundation/Foundation.h>
# endif
#endif /* GNUSTEP */

#import "SndError.h"
#import "SndEndianFunctions.h"

#import <sndfile.h> /* for libsndfile SNDFILE declaration */

/*!
  @function SndFormatDescription
  @abstract Returns a NSString description of the sound format. 
  @param format A SndFormat structure containing the sound format parameters.
  @result Returns a NSString description of the sound format.
 */
SNDKIT_API NSString *SndFormatDescription(SndFormat format);

/*!
  @function SndStructDescription
  @abstract Returns a NSString description of the sound. 
  @param sound A SndStructSound containing the Snd
  @result Returns a NSString description of the sound.
 */
SNDKIT_API NSString *SndStructDescription(SndSoundStruct *sound);

/*!
  @function SndPrintStruct
  @abstract Prints a description of the sound to stderr.
  @param sound A SndStructSound containing the Snd.
 */
SNDKIT_API void	SndPrintStruct(SndSoundStruct *sound);

/*!
  @function SndPrintFrags
  @abstract Prints, to stdout, a description of the data fragments in the sound.
  @param sound A SndStructSound containing the sound data.
  @result Returns?
 */
SNDKIT_API int	SndPrintFrags(SndSoundStruct *sound);

/*!
  @function SndFormatName
  @abstract Returns and NSString describing the data format, in either a terse or verbose manner.
  @param dataFormat The sample format enumerated integer. See ? for a description.
  @param verbose YES returns the verbose description, NO returns the terse description.
  @result Returns an NSString description of the sample data format.
 */
SNDKIT_API NSString *SndFormatName(SndSampleFormat dataFormat, BOOL verbose);

/*!
  @function SndFrameSize
  @abstract Returns the size of a sample frame, that is, the number of bytes comprising a sample times the number of channels.
  @param sound A SndFormat describing the format of a sound.
  @result Returns the size of a sample frame in bytes.
 */
SNDKIT_API int SndFrameSize(SndFormat sound);

/*!
  @function SndMaximumAmplitude
  @abstract Returns the maximum amplitude of the format, that is, the maximum positive value of a sample.
  @param dataFormat The sample format enumerated integer. See ?  for a description.
  @result Returns the maximum value of a sample.
 */
SNDKIT_API double SndMaximumAmplitude(SndSampleFormat dataFormat);

/*!
  @function SndSampleWidth
  @abstract Returns the size of a sample in bytes for the given format code. 
  @param dataFormat The sample format enumerated integer. See ?  for a description.
  @result Returns the size of a sample in bytes.
 */
SNDKIT_API int  SndSampleWidth(SndSampleFormat dataFormat);

/*!
 @function SndBytesToFrames
 @abstract Given the data size in bytes, the number of channels and the data format, return the number of samples.
 @param byteCount The size of sample data in bytes.
 @param channelCount The number of audio channels.
 @param dataFormat The sample data encoding format.
 @result Return the number of samples
*/
SNDKIT_API int  SndBytesToFrames(int byteCount,
                                  int channelCount,
                                  SndSampleFormat dataFormat);

/*!
@function SndFramesToBytes
 @abstract Calculates the number of bytes needed to store the data specified by the parameters
 @param sampleCount
 @param channelCount
 @param dataFormat
 @result The size of the sample data in bytes.
 */
SNDKIT_API long  SndFramesToBytes(long sampleCount, int channelCount, SndSampleFormat dataFormat);

/*!
  @function SndFormatOfSNDStreamBuffer
  @abstract Returns the format of a SNDStreamBuffer.
  @param streamBuffer A pointer to a SNDStreamBuffer. 
  @result A SndFormat structure holding valid frame and channel counts and the data format.
 */
SNDKIT_API SndFormat SndFormatOfSNDStreamBuffer(SNDStreamBuffer *streamBuffer);

/*!
  @function SndDataSize
  @abstract Calculates the number of bytes needed to store the sample data specified by the format.
  @param format A SndFormat structure holding valid frame and channel counts and the data format.
  @result The size of the sample data in bytes.
 */
SNDKIT_API long SndDataSize(SndFormat format);

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
@function SndFrameCount
 @abstract returns the number of samples in the Snd
 @param sound A SndStructSound containing the Snd
 @result
 */
SNDKIT_API int SndFrameCount(const SndSoundStruct *sound);

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
 @param sound The address of a SndStructSound pointer in which to alloc the Snd
 @param dataSize
 @param dataFormat
 @param samplingRate
 @param channelCount
 @param infoSize
 @result
 */
SNDKIT_API int SndAlloc(SndSoundStruct **sound,
                                   int dataSize,
                                   SndSampleFormat dataFormat,
                                   int samplingRate,
                                   int channelCount,
                                   int infoSize);

/*!
@function SndReadHeader
 @abstract To come 
 @param f
 @param sound
 @result
 */
SNDKIT_API int SndReadHeader(NSString *path,
                         SndSoundStruct **sound,
                             const char *fileTypeStr);

/*!
@function SndReadSoundfile
 @abstract To come 
 @param path
 @param sound
 @result
 */
SNDKIT_API int SndReadSoundfile(NSString *path, SndSoundStruct **sound);

SNDKIT_API int SndReadSoundfileRange(NSString *path, SndSoundStruct **sound, int startFrame, int frameCount, BOOL bReadData);

SNDKIT_API int SndDataFormatToSndFileEncoding(const char *extension, int sndFormatCode);

SNDKIT_API int SndWriteSampleData(SNDFILE *sfp, void *soundData, SndFormat soundDataFormat);

/*!
  @function SndSwapBigEndianSoundToHost
  @abstract Swaps the sound data in big endian format to host (native) format.
  @discussion Sound data is held internally in the SndKit in "host" or "native" format, either big or little endian,
              depending on the processor architecture. The SndSwapBigEndianSoundToHost() function will
              convert the supplied data from big endian format, typically received by network reception or some other
              application where the endian format is known to the most efficient native format. This is a no-op on big endian machines.
 @param dest
 @param src
 @param sampleCount
 @param channelCount
 @param dataFormat
 @result
 */
SNDKIT_API int SndSwapBigEndianSoundToHost(void *dest,
                                  void *src,
                                   int sampleCount,
                                   int channelCount,
                                   SndSampleFormat dataFormat);

/*!
  @function SndSwapHostToBigEndianSound
  @abstract Swaps the sound data in host (native) format to big endian format.
  @discussion Sound data is held internally in the SndKit in "host" or "native" format, either big or little endian,
              depending on the processor architecture. The SndSwapHostToBigEndianSound() function will
			  convert the supplied data to big endian format, typically suitable for network transmission or some other
			  application where the endian format must be known. This is a no-op on big endian machines.
 @param dest
 @param src
 @param sampleCount
 @param channelCount
 @param dataFormat
 @result 
 */
SNDKIT_API int SndSwapHostToBigEndianSound(void *dest,
                                  void *src,
                                   int sampleCount,
                                   int channelCount,
                                   SndSampleFormat dataFormat);
