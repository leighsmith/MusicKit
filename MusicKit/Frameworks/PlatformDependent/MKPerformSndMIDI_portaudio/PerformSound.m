/*
  $Id$

  Description:
    Defines the C entry points to the Sound Library.

    These routines emulate an internal SoundKit module.
    This is intended to hide all the operating system evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C SndKit interface rather this one...do yourself a favour, 
    learn ObjC - it's simple, its fun, its better than Java..

  Original Author: Leigh M. Smith, <leigh@tomandandy.com>, tomandandy music inc.

  10 July 1999, Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
/*
// $Log$
// Revision 1.5  2001/09/12 11:28:11  sbrandon
// added audio input routines (easier than I thought!)
//
// Revision 1.4  2001/09/05 10:07:39  sbrandon
// - because of changes to SndStreamManager.m we can now properly stop streams
//   in SNDStreamStop - therefore we now call Pa_CloseStream after Pa_StopStream
// - implemented SNDSetMute and SndIsMuted, by zeroing out buffers as they are
//   about to get sent off to the portaudio engine, if requested.
// - changes to allow correct querying of driver list, and setting of selected
//   driver
//
// Revision 1.3  2001/09/03 17:19:41  sbrandon
// - increased default buffer size to 16k in line with MacOSX version
// - properly implemented retrieveDriverList() for SNDGetAvailableDriverNames
//
// Revision 1.2  2001/09/03 15:09:12  sbrandon
// implemented SNDSetBufferSizeInBytes method for portaudio
//
// Revision 1.1  2001/07/18 12:47:08  sbrandon
// - renamed PerformSound.c, so I can include ObjC style NSLogs etc.
// - a number of changes to implement more of the API. Streaming now works.
// - Note: as of this release, SNDStreamStart() requires 16 bit sounds to
//   have been byte swapped to host order back in the sndkit (though this
//   function actually only works with float streams at this time), whereas
//   SNDStartPlaying takes a SndSoundStruct in big-endian (network) order
//   and byte swaps internally. This will change in the next release.
//
// Revision 1.1  2001/07/02 22:03:48  sbrandon
// - initial revision. Still a work in progress, but does allow the MusicKit
//   and SndKit to compile on GNUstep.
//
//
*/

#import <Foundation/Foundation.h>
#include "PerformSoundPrivate.h"
#include "sounderror.h"
#include "portaudio.h"
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif 


#define SQUAREWAVE_DEBUG 0
#define PADDING 3          // make sure this matches PADFORMAT changes below (including \0)
#define PADFORMAT "%s: %s"

#define PA_DEFAULT_SAMPLE_RATE     (44100)
#define PA_DEFAULT_OUT_CHANNELS    (2)
#define PA_DEFAULT_IN_CHANNELS     (2)
/* Note: if changing the default buffer size, ensure it is exactly
 * divisible by PA_BYTES_PER_FRAME (which is 8 for stereo, 4 byte
 * floats).
 */
#define PA_DEFAULT_BUFFERSIZE      (16384)
#define PA_DEFAULT_DATA_FORMAT     (SND_FORMAT_FLOAT)
#define PA_BYTES_PER_FRAME         (sizeof(float) * PA_DEFAULT_OUT_CHANNELS)
#define PA_DEFAULT_BUFFER_SIZE_IN_FRAMES ( bufferSizeInBytes \
        / PA_BYTES_PER_FRAME )

// A linked list of sounds currently playing.
typedef struct _audioStream {
  int            playTag;    // the means to refer to this sound.
  BOOL           isPlaying;

  // We have to be careful copying a SndSoundStruct as it has allocated unsigned char data that
  // is appended after the structure itself. The stucture doesn't actually include it.
  SndSoundStruct *snd;

  // Number of samples per frame (frame = 1 or more channels per time instant) so we
  // can keep track of time inbetween GenAudio calls.
  int          sampleFramesGenerated; 
  int          sampleToPlay;

  SNDNotificationFun finishedPlayFun;
  SNDNotificationFun startedPlayFun;
  struct _audioStream *next;   // Link to other playing sounds.
} SNDPlayingSound;


// "class variables" 
static BOOL             initialised = FALSE;
static char             **driverList;
static unsigned int     driverIndex = 0;

static int              numOfDevices;
static BOOL             inputInit = FALSE;

// new ones for portaudio
static int              bufferSizeInFrames;
static long             bufferSizeInBytes = PA_DEFAULT_BUFFERSIZE;
static SNDPlayingSound  singlePlayingSound;
static PortAudioStream  *stream;
static BOOL             isMuted = FALSE;

// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void *streamUserData;
static int /*should be double*/ firstSampleTime = -1.0; // indicates this has not been assigned.
static float *fInputBuffer = NULL;


static BOOL retrieveDriverList(void)
{
    int driverIndex = 0;
    numOfDevices = Pa_CountDevices();

    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
        fprintf(stderr, "Unable to malloc driver list\n");
        return FALSE;
    }
    for (driverIndex = 0 ; driverIndex < numOfDevices ; driverIndex++) {
        const char *name = Pa_GetDeviceInfo(driverIndex)->name;
        char *deviceName;
        if((deviceName = (char *) malloc((strlen(name) + 1) * sizeof(char))) == NULL) {
            NSLog(@"Unable to malloc deviceName string\n");
            return FALSE;
        }
        strcpy(deviceName,name);
        driverList[driverIndex] = deviceName;
    }
    driverList[driverIndex]=NULL;
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// sndPlayIOProc
//
// Routine to play a single sound. This could be generalised using the link-list 
// behaviour to do multiple sound channels, but instead we will adopt the stream 
// operation within the SndKit itself.
// The basis of this was snaffled from MKPerformSndMIDI_MacOSX, then modded for
// portaudio semantics.
/////////////////////////////////////////////////////////////////////////////////

static int paSKCallback( void *inputBuffer,
                         void *outputBuffer,
                unsigned long framesPerBuffer,
                  PaTimestamp outTime,
                         void *userData )

//need to ascertain nmber of channels,

{
    int deviceChannel;
    int frameIndex;
    unsigned int sampleToPlay;
    SndSoundStruct *snd = singlePlayingSound.snd;
    int bytesPerSample = 2;// TODO assume its a short (2 byte / WORD format) needs checking dataFormat.
    int bytesPerFrame = bytesPerSample * snd->channelCount;

    int channelsPerFrame = snd->channelCount; // FIXME is this right?

    for (frameIndex = 0; frameIndex < framesPerBuffer; frameIndex++) {
        unsigned int byteToPlayFrom = singlePlayingSound.sampleFramesGenerated * bytesPerFrame;
        sampleToPlay = frameIndex * channelsPerFrame;
            
        // check if the sound has been played to the end.
        if(byteToPlayFrom < (unsigned) snd->dataSize && singlePlayingSound.isPlaying) {
            for(deviceChannel = 0; deviceChannel < channelsPerFrame; deviceChannel++) {
#if SQUAREWAVE_DEBUG
                if (singlePlayingSound.sampleFramesGenerated % 500 > 250) {
                    ((float *)outputBuffer)[sampleToPlay] = 0.4f;
                }
                else {
                    ((float *)outputBuffer)[sampleToPlay] = -0.4f;
                }
#else
                unsigned char *grabDataFrom;
                signed short sampleWord;
    
                grabDataFrom = (unsigned char *) snd + snd->dataLocation + byteToPlayFrom;
                // obtain data from big-endian ordered words
                sampleWord = (((signed short) grabDataFrom[0]) << 8) + (grabDataFrom[1] & 0xff);
                // make a float, do any other sounds, normalize and then write it.
                if (!isMuted) {
                    ((float *)outputBuffer)[sampleToPlay] = sampleWord / 32768.0f;
                }
                else ((float *)outputBuffer)[sampleToPlay] = 0.0f;

                if(snd->channelCount != 1)	// play mono by sending same sample to all channels
                    byteToPlayFrom += bytesPerSample;
#endif
                sampleToPlay++;
            }
            singlePlayingSound.sampleFramesGenerated++;
        }
        else {
            for(deviceChannel = 0; deviceChannel < channelsPerFrame; deviceChannel++) {
                // if at end of sound, play silence on all channels
                ((float *)outputBuffer)[sampleToPlay] = 0.0f;
                sampleToPlay++;
            }
            // Signal back to the rest of the world that we've finished playing the sound.
            if(singlePlayingSound.finishedPlayFun != NULL && singlePlayingSound.isPlaying) {
                // Mark this sound as finished, but it is up to the delegate to stop things?
                (*(singlePlayingSound.finishedPlayFun))(snd, singlePlayingSound.playTag, 0);
            }
            singlePlayingSound.isPlaying = FALSE;
        }
    }
    return 0; // TODO need better definition...
}

BOOL SNDSetBufferSizeInBytes(long liBufferSizeInBytes)
{
  if (Pa_StreamActive(stream))
      return FALSE;
  if ((float)liBufferSizeInBytes/(float)8 != (int)(liBufferSizeInBytes/8)) {
      fprintf(stderr, "output device - error setting buffer size. Buffer must be multiple of 8\n");
      return FALSE;
  }
  bufferSizeInBytes = liBufferSizeInBytes;
  return TRUE;
}

// Takes a parameter indicating whether to guess the device to select.
// This allows us to hard code devices or use heuristics to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
PERFORM_API BOOL SNDInit(BOOL guessTheDevice)
{
    if(!retrieveDriverList())
        return FALSE;
    if(!initialised)
        initialised = TRUE;   // SNDSetDriverIndex() needs to think we're initialised.
    inputInit = TRUE;

    return TRUE;
}


// Returns an array of strings listing the available drivers.
// Returns NULL if the driver names were unobtainable.
// The client application should not attempt to free the pointers.
// TODO return driverIndex by reference
PERFORM_API char **SNDGetAvailableDriverNames(void)
{
    // We need the initialisation to retrieve the driver list.
    if(!initialised)
        SNDInit(TRUE);

    return driverList;
}


// Match the driverDescription against the driverList
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex)
{
  // This needs to be called after initialising.
  if(!initialised)
    return FALSE;
  else if(selectedIndex >= 0 && selectedIndex < numOfDevices) {
    driverIndex = selectedIndex;
    return TRUE;
  }
  return FALSE;
}

// Match the driverDescription against the driverList
PERFORM_API unsigned int SNDGetAssignedDriverIndex(void)
{
  return driverIndex;
}

PERFORM_API void SNDGetVolume(float *left, float * right)
{
    // TODO
}

PERFORM_API void SNDSetVolume(float left, float right)
{
    // TODO
}

PERFORM_API BOOL SNDIsMuted(void)
{
    return isMuted;
}

PERFORM_API void SNDSetMute(BOOL aFlag)
{
    isMuted = aFlag;
}

// Routine to begin playback
PERFORM_API int SNDStartPlaying(SndSoundStruct *soundStruct, 
                                           int tag,
                                           int priority,
                                           int preempt, 
                            SNDNotificationFun beginFun,
                            SNDNotificationFun endFun)
{
    PaError err;
    int data = 0;

    if(!initialised)
        return SND_ERR_NOT_RESERVED;  // invalid sound structure.
 
    if(soundStruct->magic != SND_MAGIC) {
        // probably SND_ERROR_NOT_SOUND is more descriptive, but this matches SoundKit specs.
        return SND_ERR_CANNOT_PLAY;
    }
    singlePlayingSound.playTag = tag;
    singlePlayingSound.snd = soundStruct;
    singlePlayingSound.sampleFramesGenerated = 0;
    singlePlayingSound.sampleToPlay = 0;
    singlePlayingSound.startedPlayFun = beginFun;
    singlePlayingSound.finishedPlayFun = endFun;
    singlePlayingSound.isPlaying = TRUE;
    singlePlayingSound.next = NULL;

    err = Pa_Initialize();
    if( err != paNoError ) {
        NSLog(@"PortAudio error: %s\n", Pa_GetErrorText( err ) );
        return SND_ERR_CANNOT_CONFIGURE;
    }

    err = Pa_OpenDefaultStream(
        &stream,                         /* passes back stream pointer */
        PA_DEFAULT_IN_CHANNELS,          /* stereo input */
        PA_DEFAULT_OUT_CHANNELS,         /* stereo output */
        paFloat32,                       /* 32 bit floating point output */
        PA_DEFAULT_SAMPLE_RATE,          /* sample rate */
        PA_DEFAULT_BUFFER_SIZE_IN_FRAMES,/* frames per buffer */
        0,              /* number of buffers, if zero then use default minimum */
        paSKCallback,                    /* specify our custom callback */
        &data );                         /* pass our data through to callback */
    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_OpenDefaultStream error: %s\n", Pa_GetErrorText( err ) );
        return SND_ERR_CANNOT_CONFIGURE;
    }
    err = Pa_StartStream( stream );
    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_StartStream error: %s\n", Pa_GetErrorText( err ) );
        return SND_ERR_CANNOT_CONFIGURE;
    }
    Pa_Sleep(2) ; /* seconds */
    return SND_ERR_NONE;
}


PERFORM_API int SNDStartRecording(SndSoundStruct *soundStruct, 
                                             int tag,
                                             int priority,
                                             int preempt, 
                              SNDNotificationFun beginRecFun,
                              SNDNotificationFun endRecFun)
{
    return FALSE; // TODO
}

 
PERFORM_API int SNDSamplesProcessed(int tag)
{
    return -1;
}

// Routine to stop
PERFORM_API void SNDStop(int tag)
{
}

PERFORM_API void SNDPause(int tag)
{
}

PERFORM_API void SNDResume(int tag)
{
// TODO - surely there is a AudOut equivalent?
}

PERFORM_API int SNDUnreserve(int dunno)
{
	return 0;
}

PERFORM_API void SNDTerminate(void)
{
    PaError err;
    err = Pa_Terminate();
    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_StartStream error: %s\n", Pa_GetErrorText( err ) );
    }
}

////////////////////////////////////////////////////////////////////////////////
// vendBuffersToStreamManagerIOProc
//
// We vend the output and input buffers in their native format to avoid 
// redundant conversions. This allows postponing the conversion to the last 
// possible moment. The SndConvertFormat() function in the SndKit makes for an 
// easy way to do the conversion without anyone writing their own converter.
////////////////////////////////////////////////////////////////////////////////


static int vendBuffersToStreamManagerIOProc(void *inputBuffer,
                                            void *outputBuffer,
                                   unsigned long framesPerBuffer,
                                     PaTimestamp outTime,
                                            void *userData )
{
    SNDStreamBuffer inStream, outStream;

//    if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
//        fprintf(stderr, "sample time is not valid!\n");
//    }
    if(firstSampleTime == -1.0) {
        firstSampleTime = outTime; /* I assume this will be 0, but interesting to find out. */
    }

    // to tell the client the format it is receiving.

    if (inputInit) {
        memcpy(fInputBuffer, inputBuffer, bufferSizeInBytes);
    }

    // to tell the client the format it should send.
        
    SNDStreamNativeFormat(&outStream.streamFormat);   
    SNDStreamNativeFormat(&inStream.streamFormat);    

    inStream.streamData  = fInputBuffer;  
    outStream.streamData = outputBuffer;
        
    // hand over the stream buffers to the processor/stream manager.
    // the output time goes out as a relative time, noted from the 
    // first sample time we first receive.

    (*streamProcessor)(outTime - firstSampleTime, 
                       &inStream, &outStream, streamUserData);
    if (isMuted) {
        memset(outputBuffer,0,bufferSizeInBytes);
    }

    return 0; // returning 1 stops the stream
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStart
//
// Routine to begin playback/recording of a stream.
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor,
                                              void *newUserData)
{
    PaError err;
    int data = 0;
    BOOL r = TRUE;
    
    if(!initialised)
        return FALSE;  // invalid sound structure.

    if (inputInit) {
        if ((fInputBuffer = (float*) malloc(bufferSizeInBytes)) == NULL)
            return FALSE;
        memset(fInputBuffer,0,bufferSizeInBytes);
    }

    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  

    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;

    err = Pa_Initialize();
    if( err != paNoError ) {
        NSLog(@"PortAudio error: %s\n", Pa_GetErrorText( err ) );
        r = FALSE;
    }
    err = Pa_OpenDefaultStream(
        &stream,                         /* passes back stream pointer */
        PA_DEFAULT_IN_CHANNELS,          /* stereo input */
        PA_DEFAULT_OUT_CHANNELS,         /* stereo output */
        paFloat32,                       /* 32 bit floating point output paFloat32 */
                                         /*  note: this value instructs portaudio
                                          *  what sample size to expect, which
                                          *  is a different constant to that used
                                          *  to talk to the SndKit (SND_FORMAT_*)
                                          */
        PA_DEFAULT_SAMPLE_RATE,          /* sample rate */
        PA_DEFAULT_BUFFER_SIZE_IN_FRAMES,/* frames per buffer */
        0,              /* number of buffers, if zero then use default minimum */
        vendBuffersToStreamManagerIOProc, /* specify our custom callback */
        &data );        /* pass our data through to callback */
    err = Pa_StartStream( stream );
    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_StartStream error: %s\n", Pa_GetErrorText( err ) );
        r = FALSE;
    }

    return r;
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStop
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStop(void)
{
    BOOL r = TRUE;
    PaError err;
    err = Pa_StopStream(stream);
    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_StopStream error: %s\n", Pa_GetErrorText( err ) );
        r = FALSE;
    }

    err = Pa_CloseStream(stream);
    if( err != paNoError ) {
        NSLog(@"PortAudio Pa_CloseStream error: %s\n", Pa_GetErrorText( err ) );
        r = FALSE;
    }

//    SNDTerminate();
    if (inputInit) {
        free(fInputBuffer);
        fInputBuffer = NULL;
    }
    NSLog(@"SNDStreamStopped\n" );
    return r;
}


////////////////////////////////////////////////////////////////////////////////
// SndStreamNativeFormat
////////////////////////////////////////////////////////////////////////////////

// Return in the struct the format of the sound data preferred by
// the operating system. For CoreAudio, we use the basicDescription.
PERFORM_API void SNDStreamNativeFormat(SndSoundStruct *streamFormat)
{
    streamFormat->magic        = SND_MAGIC;
    streamFormat->dataLocation = 0;   /* Offset or pointer to the raw data */
    /* Number of bytes of data in a buffer */
    streamFormat->dataSize     = bufferSizeInBytes;
    streamFormat->dataFormat   = PA_DEFAULT_DATA_FORMAT;
    streamFormat->samplingRate = PA_DEFAULT_SAMPLE_RATE;
    streamFormat->channelCount = PA_DEFAULT_OUT_CHANNELS;
    streamFormat->info[0]      = '\0';
}

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
}
#endif
