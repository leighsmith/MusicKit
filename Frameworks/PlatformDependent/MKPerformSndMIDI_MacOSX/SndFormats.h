/*
 $Id$
 
 Description:
   Enumerates and describes the various sound sample data formats which can processed
   by the MusicKit and SndKit.
 
 Original Author: Stephen Brandon

 Copyright (c) 1999 Stephen Brandon and the University of Glasgow
 Additions Copyright (c) 2004, The MusicKit Project.  All rights reserved.
 
 Legal Statement Covering Additions by Stephen Brandon and the University of Glasgow:

 This framework and all source code supplied with it, except where specified, are
 Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use
 the source code for any purpose, including commercial applications, as long as you
 reproduce this notice on all such software.
 
 Software production is complex and we cannot warrant that the Software will be error free.
 Further, we will not be liable to you if the Software is not fit for the purpose for which
 you acquired it, or of satisfactory quality. 
 
 WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED
 BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR
 PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.
 
 If a court finds that we are liable for death or personal injury caused by our negligence our
 liability shall be unlimited.  
 
 WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA,
 LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE
 OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE
 OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS
 OF THIS AGREEMENT.
 
 Legal Statement Covering Additions by The MusicKit Project:

 Permission is granted to use and modify this code for commercial and
 non-commercial purposes so long as the author attribution and copyright
 messages remain intact and accompany all relevant code.
 
 */
/*!
  @header SndFormats
 
  @brief Enumerates and describes the various sound sample data formats which can processed
  by the MusicKit and SndKit.
 */

#ifndef __SNDFORMATS__
#define __SNDFORMATS__

/*!
  @enum       SndSampleFormat
  @brief   Various sound sample data formats
  @constant   SND_FORMAT_UNSPECIFIED
  @constant   SND_FORMAT_MULAW_8  u-law encoding.
  @constant   SND_FORMAT_LINEAR_8  Linear 8 bits.
  @constant   SND_FORMAT_LINEAR_16   Linear 16 bits.
  @constant   SND_FORMAT_LINEAR_24   Linear 24 bits.
  @constant   SND_FORMAT_LINEAR_32   Linear 32 bits.
  @constant   SND_FORMAT_FLOAT       IEEE Floating Point 32 bits.
  @constant   SND_FORMAT_DOUBLE      Floating Point 64 bits, could even be IEEE 80 bit Floating Point.
  @constant   SND_FORMAT_INDIRECT    Fragmented.
  @constant   SND_FORMAT_NESTED
  @constant   SND_FORMAT_DSP_CORE
  @constant   SND_FORMAT_DSP_DATA_8
  @constant   SND_FORMAT_DSP_DATA_16
  @constant   SND_FORMAT_DSP_DATA_24
  @constant   SND_FORMAT_DSP_DATA_32
  @constant   SND_FORMAT_DISPLAY
  @constant   SND_FORMAT_MULAW_SQUELCH
  @constant   SND_FORMAT_EMPHASIZED
  @constant   SND_FORMAT_COMPRESSED Julius O. Smith III's SoundKit compressed format.
  @constant   SND_FORMAT_COMPRESSED_EMPHASIZED Julius O. Smith III's SoundKit compressed format.
  @constant   SND_FORMAT_DSP_COMMANDS MC56001 DSP instruction opcodes.
  @constant   SND_FORMAT_DSP_COMMANDS_SAMPLES audio data in a format suitable for MC56001 DSP use?
  @constant   SND_FORMAT_ADPCM_G721  GSM compressed format.
  @constant   SND_FORMAT_ADPCM_G722  GSM compressed format.
  @constant   SND_FORMAT_ADPCM_G723_3  GSM compressed format.
  @constant   SND_FORMAT_ADPCM_G723_5  GSM compressed format.
  @constant   SND_FORMAT_ALAW_8  a-law encoding.
  @constant   SND_FORMAT_AES  a format specified by the Audio Engineering Society?
  @constant   SND_FORMAT_DELTA_MULAW_8
  @constant   SND_FORMAT_MP3  MPEG-1 Layer 3 audio format.
  @constant   SND_FORMAT_AAC  MPEG-4 Advanced Audio Coder.
  @constant   SND_FORMAT_AC3  Dolby AC3 A/52 encoding.
  @constant   SND_FORMAT_VORBIS  Ogg/Vorbis compressed format.
 */
typedef enum {
    SND_FORMAT_UNSPECIFIED           = 0,
    SND_FORMAT_MULAW_8               = 1, /* u-law encoding */
    SND_FORMAT_LINEAR_8              = 2, /* Linear 8 bits */
    SND_FORMAT_LINEAR_16             = 3, /* Linear 16 bits */
    SND_FORMAT_LINEAR_24             = 4, /* Linear 24 bits */
    SND_FORMAT_LINEAR_32             = 5, /* Linear 32 bits */
    SND_FORMAT_FLOAT                 = 6, /* IEEE Floating Point 32 bits */
    SND_FORMAT_DOUBLE                = 7, /* Floating Point 64 bits, could even be IEEE 80 bit Floating Point */
    SND_FORMAT_INDIRECT              = 8, /* Fragmented */
    SND_FORMAT_NESTED                = 9,
    SND_FORMAT_DSP_CORE              = 10,
    SND_FORMAT_DSP_DATA_8            = 11,
    SND_FORMAT_DSP_DATA_16           = 12,
    SND_FORMAT_DSP_DATA_24           = 13,
    SND_FORMAT_DSP_DATA_32           = 14,
    SND_FORMAT_DISPLAY               = 16,
    SND_FORMAT_MULAW_SQUELCH         = 17,
    SND_FORMAT_EMPHASIZED            = 18,
    SND_FORMAT_COMPRESSED            = 19, /* Julius O. Smith III's SoundKit compressed format */
    SND_FORMAT_COMPRESSED_EMPHASIZED = 20, /* Julius O. Smith III's SoundKit compressed format */
    SND_FORMAT_DSP_COMMANDS          = 21, /* MC56001 DSP instruction opcodes */
    SND_FORMAT_DSP_COMMANDS_SAMPLES  = 22, /* audio data in a format suitable for MC56001 DSP use? */
    SND_FORMAT_ADPCM_G721            = 23, /* GSM compressed format */
    SND_FORMAT_ADPCM_G722            = 24, /* GSM compressed format */
    SND_FORMAT_ADPCM_G723_3          = 25, /* GSM compressed format */
    SND_FORMAT_ADPCM_G723_5          = 26, /* GSM compressed format */
    SND_FORMAT_ALAW_8                = 27, /* a-law encoding */
    SND_FORMAT_AES                   = 28, /* a format specified by the Audio Engineering Society? */
    SND_FORMAT_DELTA_MULAW_8	     = 29,
    SND_FORMAT_MP3                   = 30, /* MPEG-1 Layer 3 audio format */
    SND_FORMAT_AAC                   = 31, /* MPEG-4 Advanced Audio Coder */
    SND_FORMAT_AC3                   = 32, /* Dolby AC3 A/52 encoding */
    SND_FORMAT_VORBIS                = 33, /* Ogg/Vorbis compressed format */
} SndSampleFormat;

#endif
