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

  10 July 1999, Copyright (c) 1999 The MusicKit Project.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
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

// "class variables" 
static BOOL             initialised = FALSE;
static char             **driverList;
static unsigned int     driverIndex = 0;

static int              numOfDevices;
static BOOL             inputInit = FALSE;

// new ones for portaudio
static int              bufferSizeInFrames;
static long             bufferSizeInBytes = PA_DEFAULT_BUFFERSIZE;
static PaStream         *stream;
static BOOL             isMuted = FALSE;

// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void *streamUserData;
static int /*should be double*/ firstSampleTime = -1.0; // indicates this has not been assigned.
static float *lastRecvdInputBuffer = NULL;


static BOOL retrieveDriverList(void)
{
    int driverIndex = 0;
    numOfDevices = Pa_GetDeviceCount();

    if(numOfDevices < 0) { // Error getting devices.
        NSLog(@"PortAudio Error retrieving number of devices %s\n", Pa_GetErrorText(numOfDevices));
        return FALSE;
    }
    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
          NSLog(@"Unable to malloc driver list for %d devices\n", numOfDevices);
          return FALSE;
    }
    for (driverIndex = 0 ; driverIndex < numOfDevices ; driverIndex++) {
        const char *name = Pa_GetDeviceInfo(driverIndex)->name;
        char *deviceName;

        if((deviceName = (char *) malloc((strlen(name) + 1) * sizeof(char))) == NULL) {
            NSLog(@"Unable to malloc deviceName string\n");
            return FALSE;
        }
        strcpy(deviceName, name);
        driverList[driverIndex] = deviceName;
    }
    driverList[driverIndex] = NULL;
    return TRUE;
}

BOOL SNDSetBufferSizeInBytes(long liBufferSizeInBytes)
{
  if (Pa_IsStreamActive(stream))
      return FALSE;
  if ((float)liBufferSizeInBytes/(float)8 != (int)(liBufferSizeInBytes/8)) {
      NSLog(@"output device - error setting buffer size. Buffer must be multiple of 8\n");
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
    PaError err = Pa_Initialize();

    if (err != paNoError) {
        NSLog(@"PortAudio error: %s\n", Pa_GetErrorText(err));
        return FALSE;
    }
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

PERFORM_API BOOL SNDIsMuted(void)
{
    return isMuted;
}

PERFORM_API void SNDSetMute(BOOL aFlag)
{
    isMuted = aFlag;
}


////////////////////////////////////////////////////////////////////////////////
// vendBuffersToStreamManagerIOProc
//
// We vend the output and input buffers in their native format to avoid 
// redundant conversions. This allows postponing the conversion to the last 
// possible moment. The SndConvertFormat() function in the SndKit makes for an 
// easy way to do the conversion without anyone writing their own converter.
////////////////////////////////////////////////////////////////////////////////

static int vendBuffersToStreamManagerIOProc(const void *inputBuffer,
                                            void *outputBuffer,
                                   unsigned long framesPerBuffer,
				   const PaStreamCallbackTimeInfo *timeInfo,
                                     PaStreamCallbackFlags statusFlags,
                                            void *userData )
{
    SNDStreamBuffer inStream, outStream;

//    if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
//        NSLog(@"sample time is not valid!\n");
//    }
    if(firstSampleTime == -1.0) {
        firstSampleTime = timeInfo->outputBufferDacTime; /* I assume this will be 0, but interesting to find out. */
    }

    // to tell the client the format it is receiving.

    if (inputInit) {
        memcpy(lastRecvdInputBuffer, inputBuffer, bufferSizeInBytes);
    }

    // to tell the client the format it should send.
        
    SNDStreamNativeFormat(&outStream.streamFormat);   
    SNDStreamNativeFormat(&inStream.streamFormat);    

    inStream.streamData  = lastRecvdInputBuffer;
    outStream.streamData = outputBuffer;
        
    // hand over the stream buffers to the processor/stream manager.
    // the output time goes out as a relative time, noted from the 
    // first sample time we first receive.

#ifdef GNUSTEP
    // If we are using a GNUstep system, the thread of the callback
    // hasn't yet been registered with GNUstep which it must be before
    // we can create NSAutoreleasePools.
    GSRegisterCurrentThread();
#endif
    (*streamProcessor)(timeInfo->outputBufferDacTime - firstSampleTime, 
                       &inStream, &outStream, streamUserData);
    if (isMuted) {
        memset(outputBuffer, 0, bufferSizeInBytes);
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
        if ((lastRecvdInputBuffer = (float *) malloc(bufferSizeInBytes)) == NULL)
            return FALSE;
        memset(lastRecvdInputBuffer, 0, bufferSizeInBytes);
    }

    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  

    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;

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
        free(lastRecvdInputBuffer);
        lastRecvdInputBuffer = NULL;
    }
    // NSLog(@"SNDStreamStopped\n" );
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

PERFORM_API BOOL SNDTerminate(void)
{
    PaError err = Pa_Terminate();

    if (err != paNoError) {
        NSLog(@"PortAudio Pa_StartStream error: %s\n", Pa_GetErrorText(err));
	return FALSE;
    }
    return TRUE;
}

#ifdef __cplusplus
}
#endif
