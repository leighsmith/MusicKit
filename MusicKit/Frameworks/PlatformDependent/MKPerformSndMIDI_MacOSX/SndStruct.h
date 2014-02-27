/*
  $Id$
  Description:
    Defines the NeXT/Sun audio header structure that will be represented in memory and on disk.
    
  Original Author: Stephen Brandon

  Copyright (C) 1999 This framework and all source code supplied with it, except where specified,
  are Copyright Stephen Brandon and the University of Glasgow, 1999. 
  You are free to use the source code for any purpose, including commercial applications, as long
  as you reproduce this notice on all such software.

  Software production is complex and we cannot warrant that the Software will be error free.
  Further, we will not be liable to you if the Software is not fit for the purpose for which you
  acquired it, or of satisfactory quality. 

  WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW
  INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND
  NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

  If a court finds that we are liable for death or personal injury caused by our negligence our liability
  shall be unlimited.  

  WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL,
  OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.
  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH
  USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.
*/
/*!
  @header SndStruct
  
  Defines the NeXT/Sun audio header structure that will be represented in memory and on disk.
*/
#ifndef __SNDSTRUCT__
#define __SNDSTRUCT__

/*!
  @defined SND_MAGIC
  @brief Magic cookie for NeXT/Sun audio files.
*/
#define SND_MAGIC ((int)0x2e736e64)

/*!
  @brief Each raw event consists of a MIDI message byte and a time stamp.
*/
typedef struct {
    /*! Must be equal to SND_MAGIC. */
    int magic;
    /*! Offset or pointer to the raw data. */
    int dataLocation;
    /*! Number of bytes of data in the raw data. */
    int dataSize;
    /*! The data format code. */
    int dataFormat;
    /*! The sampling rate. */
    int samplingRate;
    /*! The number of channels. */
    int channelCount;
    /*! Textual information relating to the sound. */
    char info[4];
} SndSoundStruct;

/* ensure we don't conflict with SoundKit defs */
#ifndef SND_CFORMAT_BITS_DROPPED 

/*!
  @defined SND_CFORMAT_BITS_DROPPED
  @brief Lossy compression.
*/
#define SND_CFORMAT_BITS_DROPPED        (0)

/*!
  @defined SND_CFORMAT_BIT_FAITHFUL
  @brief No Loss compression.
*/
#define SND_CFORMAT_BIT_FAITHFUL        (1)

/*!
  @defined SND_CFORMAT_ATC
  @brief Audio Transform Compression.
*/
#define SND_CFORMAT_ATC                 (2)

/*!
  @defined ATC_FRAME_SIZE
  @brief Size in samples of each frame used during ATC compression.
*/
#define ATC_FRAME_SIZE (256)

/*
 * Sampling rates directly supported in hardware.
 */
/*!
  @defined SND_RATE_CODEC
  @brief Sampling rate for voice quality CODECs.
*/
#define SND_RATE_CODEC          (8012.8210513)

/*!
  @defined SND_RATE_LOW
  @brief Sampling rate for low quality music.
*/
#define SND_RATE_LOW            (22050.0)

/*!
  @defined SND_RATE_HIGH
  @brief Sampling rate for high quality music.
*/
#define SND_RATE_HIGH           (44100.0)

/*!
  @defined SND_RATE_LOW_PC
  @brief Sampling rate for very low quality music on PCs.
*/
#define SND_RATE_LOW_PC         (11025.0)

#endif

#endif // __SNDSTRUCT__
