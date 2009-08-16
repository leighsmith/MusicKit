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
  @brief A library of functions originally intended to be compatible with NeXTs now defunct SoundKit.
  
  Nowdays, compatibility with NeXT SoundKit functions is not enforced, only the OO class API
	  aims for compatibility to the SoundKit.
 */

/* We #import this file regardless of the setting of
   HAVE_CONFIG_H so that other applications compiling against this
   header don't have to define it. If you are seeing errors for
   SndKitConfig.h not found when compiling the MusicKit, you haven't
   run ./configure 
*/
#import "SndKitConfig.h"
#import "SndFormat.h"

#import <Foundation/Foundation.h>

#import "SndError.h"
#import "SndEndianFunctions.h"

#if HAVE_LIBSNDFILE
# import <sndfile.h> /* for libsndfile SNDFILE declaration */
#else
#define SNDFILE void
#endif

/*!
  @brief Returns a NSString description of the sound format. 
  @param format A SndFormat structure containing the sound format parameters.
  @return Returns a NSString description of the sound format.
 */
SNDKIT_API NSString *SndFormatDescription(SndFormat format);

/*!
  @brief Returns a NSString description of the sound. 
  @param sound A SndStructSound containing the Snd
  @return Returns a NSString description of the sound.
 */
SNDKIT_API NSString *SndStructDescription(SndSoundStruct *sound);

/*!
  @brief Prints a description of the sound to stderr.
  @param sound A SndStructSound containing the Snd.
 */
SNDKIT_API void	SndPrintStruct(SndSoundStruct *sound);

/*!
  @brief Prints, to stdout, a description of the data fragments in the sound.
  @param sound A SndStructSound containing the sound data.
  @return Returns?
 */
SNDKIT_API int	SndPrintFrags(SndSoundStruct *sound);

/*!
  @brief Returns and NSString describing the data format, in either a terse or verbose manner.
  @param dataFormat The sample format enumerated integer. See ? for a description.
  @param verbose YES returns the verbose description, NO returns the terse description.
  @return Returns an NSString description of the sample data format.
 */
SNDKIT_API NSString *SndFormatName(SndSampleFormat dataFormat, BOOL verbose);

/*!
  @brief Returns the size of a sample frame, that is, the number of bytes comprising a sample times the number of channels.
  @param sound A SndFormat describing the format of a sound.
  @return Returns the size of a sample frame in bytes.
 */
SNDKIT_API int SndFrameSize(SndFormat sound);

/*!
  @brief Returns the maximum amplitude of the format, that is, the maximum positive value of a sample.
  @param dataFormat The sample format enumerated integer. See ?  for a description.
  @return Returns the maximum value of a sample.
 */
SNDKIT_API double SndMaximumAmplitude(SndSampleFormat dataFormat);

/*!
  @brief Returns the size of a sample in bytes for the given format code. 
  @param dataFormat The sample format enumerated integer. See ?  for a description.
  @return Returns the size of a sample in bytes.
 */
SNDKIT_API int SndSampleWidth(SndSampleFormat dataFormat);

/*!
  @brief Given the data size in bytes, the number of channels and the data format, return the number of samples.
  @param byteCount The size of sample data in bytes.
  @param channelCount The number of audio channels.
  @param dataFormat The sample data encoding format.
  @return Return the number of samples
*/
SNDKIT_API int SndBytesToFrames(int byteCount,
                                int channelCount,
                                SndSampleFormat dataFormat);

/*!
  @brief Calculates the number of bytes needed to store the data specified by the parameters
  @param sampleCount
  @param channelCount
  @param dataFormat
  @return The size of the sample data in bytes.
 */
SNDKIT_API long SndFramesToBytes(long sampleCount, int channelCount, SndSampleFormat dataFormat);

/*!
  @brief Returns the format of a SNDStreamBuffer.
  @param streamBuffer A pointer to a SNDStreamBuffer. 
  @return A SndFormat structure holding valid frame and channel counts and the data format.
 */
SNDKIT_API SndFormat SndFormatOfSNDStreamBuffer(SNDStreamBuffer *streamBuffer);

/*!
  @brief Calculates the number of bytes needed to store the sample data specified by the format.
  @param format A SndFormat structure holding valid frame and channel counts and the data format.
  @return The size of the sample data in bytes.
 */
SNDKIT_API long SndDataSize(SndFormat format);

/*!
  @brief Converts the relative deciBel [-oo,0] level dB to a linear amplitude in the range [0,1];
  @param db parameter in deciBels.
  @return The linear equivalent of the relative deciBel level dB
 */
SNDKIT_API float SndConvertDecibelsToLinear(float db);

/*!
  @brief Converts a linear amplitude in the range [0,1] to relative deciBels [-oo,0]
  @param linearAmplitude An amplitude in the range [0, 1].
  @return The relative decibel equivalent of linearAmplitude.
 */
SNDKIT_API float SndConvertLinearToDecibels(float linearAmplitude);

/*!
  @brief returns the number of samples in the Snd
  @param sound A SndStructSound containing the Snd
  @return
 */
SNDKIT_API int SndFrameCount(const SndSoundStruct *sound);

/*!
  @brief Frees the sound contained in the structure sound
  @param sound A SndStructSound containing the Snd
  @return
 */
SNDKIT_API int SndFree(SndSoundStruct *sound);

/*!
  @brief Allocates a sound as specified by the parameters.
  @param sound The address of a SndStructSound pointer in which to alloc the Snd
  @param dataSize
  @param dataFormat
  @param samplingRate
  @param channelCount
  @param infoSize
  @return
 */
SNDKIT_API int SndAlloc(SndSoundStruct **sound,
                                   int dataSize,
                                   SndSampleFormat dataFormat,
                                   int samplingRate,
                                   int channelCount,
                                   int infoSize);

/*!
  @brief To come 
  @param sfp
  @param soundData
  @param soundDataFormat
  @return
 */
SNDKIT_API int SndWriteSampleData(SNDFILE *sfp, void *soundData, SndFormat soundDataFormat);

/*!
  @brief Swaps the sound data in big endian format to host (native) format.
  
  Sound data is held internally in the SndKit in "host" or "native" format, either big or little endian,
  depending on the processor architecture. The SndSwapBigEndianSoundToHost() function will
  convert the supplied data from big endian format, typically received by network reception or some other
  application where the endian format is known to the most efficient native format. This is a no-op on big endian machines.
  @param dest
  @param src
  @param sampleCount
  @param channelCount
  @param dataFormat
  @return
 */
SNDKIT_API int SndSwapBigEndianSoundToHost(void *dest,
					   void *src,
                                           int sampleCount,
                                           int channelCount,
                                           SndSampleFormat dataFormat);

/*!
  @brief Swaps the sound data in host (native) format to big endian format.
  
  Sound data is held internally in the SndKit in "host" or "native" format, either big or little endian,
  depending on the processor architecture. The SndSwapHostToBigEndianSound() function will
			  convert the supplied data to big endian format, typically suitable for network transmission or some other
			  application where the endian format must be known. This is a no-op on big endian machines.
  @param dest
  @param src
  @param sampleCount
  @param channelCount
  @param dataFormat
  @return 
 */
SNDKIT_API int SndSwapHostToBigEndianSound(void *dest,
                                  void *src,
                                   int sampleCount,
                                   int channelCount,
                                   SndSampleFormat dataFormat);
