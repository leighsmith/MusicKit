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
  @abstract A library of functions intended to be compatible with NeXTs now defunct SoundKit.
 */

//#define USE_MACH_MEMORY_ALLOCATION
#import <MKPerformSndMIDI/PerformSound.h>
#import "SndKitDefines.h"

#ifdef GNUSTEP
# import <Foundation/NSArray.h>
# import "sounderror.h"
# include <objc/objc.h> /* for BOOL, YES, NO, TRUE, FALSE */
# include <stdio.h>     /* for FILE */
#else
# ifndef USE_NEXTSTEP_SOUND_IO
#  import <Foundation/Foundation.h>
#  import "sounderror.h"
# endif
#endif /* GNUSTEP */

#import "SndEndianFunctions.h"

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
SNDKIT_API NSString *SndFormatName(int dataFormat, BOOL verbose);

/*!
  @function SndFrameSize
  @abstract Returns the size of a sample frame, that is, the number of bytes comprising a sample times the number of channels.
  @param sound A SndStructSound containing the Snd
  @result Returns the size of a sample frame in bytes.
 */
SNDKIT_API int SndFrameSize(SndSoundStruct* sound);

/*!
  @function SndSampleWidth
  @abstract Returns the size of a sample in bytes for the given format code. 
  @param format The sample format enumerated integer. See ?  for a description.
  @result Returns the size of a sample in bytes.
 */
SNDKIT_API int  SndSampleWidth(int format);

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
                                  int dataFormat);

/*!
@function SndSamplesToBytes
 @abstract Calculates the number of bytes needed to store the data specified by the parameters
 @param sampleCount
 @param channelCount
 @param dataFormat
 @result A number of bytes
 */
SNDKIT_API int  SndSamplesToBytes(int sampleCount,
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
@function SndGetDataAddresses
 @abstract Get data address and statistics for fragmented or non-fragmented
           SndSoundStructs
 @discussion For fragmented sounds, you often need to be able to find the
             block of data that a certain sample resides in. You then often
             need to know which is the last sample in that fragment (block),
             indexed from the start of the block
             The sample indices referred to are channel independent.
 @param sample    The index of the sample you wish to find the block for,
                  indexed from the beginning of the sound
 @param theSound  The SndSoundStruct
 @param lastSampleInBlock returns by reference the index of the last sample
                          in the block, indexed from the start of the block
 @param currentSample     returns by reference the index of the sample supplied,
                          indexed from the start of the block
 @result the memory address of the first sample in the block.
 */
SNDKIT_API void   *SndGetDataAddresses(int sample,
                    const SndSoundStruct *theSound,
                                     int *lastSampleInBlock,
                                     int *currentSample);

/*!
@function SndFrameCount
 @abstract returns the number of samples in the Snd
 @param sound A SndStructSound containing the Snd
 @result
 */
SNDKIT_API int SndFrameCount(const SndSoundStruct *sound);

/*!
@function SndGetDataPointer
 @abstract    Gets data address and number of samples in SndSoundStruct
 @discussion  <B>This function is deprecated and ripe for removal, use it only in the process of abandoning SndSoundStructs!</B>
              SndGetDataPointer is only useful for non-fragmented sounds.
 @param sound A SndStructSound containing the Snd
 @param ptr   returns the char* pointer to the audio data
 @param size  returns the number of samples (divide by number of channels
              to get number of channel-independent frames)
 @param width returns the number of bytes per sample
 @result
 */
SNDKIT_API int SndGetDataPointer(const SndSoundStruct *sound,
                                  char **ptr,
                                   int *size, 
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
SNDKIT_API int SndDeleteSamples(SndSoundStruct *sound,
                                            int startSample,
                                            int sampleCount);

/*!
  @function SndFileExtensions
  @abstract Returns an NSArray of valid file extensions to read or write.
  @result Returns an NSArray of NSStrings of file extensions.
 */
NSArray *SndFileExtensions(void);

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

int SndReadSoundfileRange(NSString *path, SndSoundStruct **sound, int startFrame, int frameCount, BOOL bReadData);

/*!
  @function SndWriteSoundfile
  @abstract Writes a soundStruct to the named file. The extension is used to determine the format of the output file.
  @discussion  Expects the sound to not be fragmented, and to be in host order.
  @param path An NSString formatted path.
  @param sound An SndSoundStruct containing the format of the data and a pointer to the data itself.
  @result Returns SND_ERR_NONE if the writing went correctly, otherwise an error value.
 */
SNDKIT_API int SndWriteSoundfile(NSString *path, SndSoundStruct *sound);

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
