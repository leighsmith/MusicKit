#ifndef __SNDSTRUCT__
#define __SNDSTRUCT__
#define SND_MAGIC ((int)0x2e736e64)

typedef struct {
    int magic;          /* must be equal to SND_MAGIC */
    int dataLocation;   /* Offset or pointer to the raw data */
    int dataSize;       /* Number of bytes of data in the raw data */
    int dataFormat;     /* The data format code */
    int samplingRate;   /* The sampling rate */
    int channelCount;   /* The number of channels */
    char info[4];       /* Textual information relating to the sound. */
} SndSoundStruct;

/* ensure we don't conflict with SoundKit defs */
#ifndef SND_CFORMAT_BITS_DROPPED 

#define SND_CFORMAT_BITS_DROPPED        (0)
#define SND_CFORMAT_BIT_FAITHFUL        (1)
#define SND_CFORMAT_ATC                 (2) /* Audio Transform Compression*/

#define ATC_FRAME_SIZE (256)

/*
 * Sampling rates directly supported in hardware.
 */
#define SND_RATE_CODEC          (8012.8210513)
#define SND_RATE_LOW            (22050.0)
#define SND_RATE_HIGH           (44100.0)
#define SND_RATE_LOW_PC         (11025.0)

#endif

#endif __SNDSTRUCT__