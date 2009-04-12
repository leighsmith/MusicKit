/*
  $Id$

  Description:
    Defines the C entry points to the Sound Library.

    These routines emulate an internal SoundKit module.
    This is intended to hide all the operating system evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C SndKit interface rather this one...

  Original Author: Leigh M. Smith, <leigh@leighsmith.com>

  10 July 1999, Copyright (c) 1999 The MusicKit Project.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/

#import <Foundation/Foundation.h>
#include "PerformSoundPrivate.h"
#if HAVE_PORTAUDIO_H
# include <portaudio.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif 


#define SQUAREWAVE_DEBUG 0
#define DEBUG_VENDBUFFER 0

#define DEFAULT_SAMPLE_RATE     (44100)
#define DEFAULT_OUT_CHANNELS    (2)
#define DEFAULT_IN_CHANNELS     (2)
/* Note: if changing the default buffer size, ensure it is exactly
 * divisible by BYTES_PER_FRAME (which is 8 for stereo, 4 byte
 * floats).
 */
#define DEFAULT_BUFFER_SIZE      (512)  // in Frames
#define DEFAULT_DATA_FORMAT      (SND_FORMAT_FLOAT)
#define BYTES_PER_FRAME          (sizeof(float) * DEFAULT_OUT_CHANNELS)

// "class variables" 
static BOOL             initialised = FALSE;
static char             **driverList;
static unsigned int     driverIndex = 0;
static char             **speakerConfigurationList;

static int              numOfDevices;
static BOOL             inputInit = FALSE;

// portaudio specific variables
static long             bufferSizeInFrames = DEFAULT_BUFFER_SIZE;
static PaStream         *stream;
static BOOL             isMuted = FALSE;
static BOOL             useNativeBufferSize = TRUE;

// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void *streamUserData;
static PaTime firstSampleTime = -1.0; // indicates this has not been assigned.
static float *lastRecvdInputBuffer = NULL;


static BOOL retrieveDriverList(void)
{
    int driverIndex = 0;
    numOfDevices = Pa_GetDeviceCount();

    NSLog(@"Number of portaudio devices %d\n", numOfDevices);
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

BOOL SNDSetBufferSizeInBytes(long newBufferSizeInBytes)
{
    long newBufferSizeInFrames = newBufferSizeInBytes / BYTES_PER_FRAME;

    if (Pa_IsStreamActive(stream))
        return FALSE;
    if ((float)newBufferSizeInBytes /(float) BYTES_PER_FRAME != newBufferSizeInFrames) {
        NSLog(@"output device - error setting buffer size. Buffer must be multiple of %d\n", BYTES_PER_FRAME);
        return FALSE;
    }
    bufferSizeInFrames = newBufferSizeInFrames;
    // if we set the size, we force the streaming to use it, not the
    // native size.
    useNativeBufferSize = FALSE;  
    return TRUE;
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
                                            void *userData)
{
    SNDStreamBuffer inStream, outStream;
    unsigned long vendBufferSizeInBytes = framesPerBuffer * BYTES_PER_FRAME;

    // TODO We modify the saved buffer size here, before
    // SNDStreamNativeFormat() is called.
    // bufferSizeInFrames = framesPerBuffer; 
#if DEBUG_VENDBUFFER
    NSLog(@"framesPerBuffer now %ld\n", framesPerBuffer);
#endif
//    if(statusFlags) {
//        NSLog(@"Problem in callback: %x\n", statusFlags);
//    }
    if(firstSampleTime == -1.0) {
        firstSampleTime = timeInfo->outputBufferDacTime; /* I assume this will be 0, but interesting to find out. */
    }

    // to tell the client the format it is receiving.

    if (inputInit) {
        memcpy(lastRecvdInputBuffer, inputBuffer, vendBufferSizeInBytes);
    }

    // to tell the client the format it should send.
        
    SNDStreamNativeFormat(&outStream, YES);
    SNDStreamNativeFormat(&inStream, NO);

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
        memset(outputBuffer, 0, vendBufferSizeInBytes);
    }

    return paContinue; // returning 1 stops the stream
}


// Takes a parameter indicating whether to guess the device to select.
// This allows us to hard code devices or use heuristics to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
PERFORM_API BOOL SNDInit(BOOL guessTheDevice)
{
    PaError err = Pa_Initialize();

    if (err != paNoError) {
        NSLog(@"SNDInit: PortAudio initialisation error: %s\n", Pa_GetErrorText(err));
        return FALSE;
    }

    // Debugging
    { 
	const PaHostApiInfo *hostAPIInfo;
	NSLog(@"Default Host API index %d\n", Pa_GetDefaultHostApi());
	
	hostAPIInfo = Pa_GetHostApiInfo(Pa_GetDefaultHostApi());
	NSLog(@"Host API named: %s\n", hostAPIInfo->name);
    }

    if(!retrieveDriverList())
        return FALSE;
    if(!initialised)
        initialised = TRUE;   // SNDSetDriverIndex() needs to think we're initialised.
    inputInit = TRUE;

    // If we guess the device, then we retrieve the buffer size of the 
    // default device and use that, rather than using the buffer size
    // defined in DEFAULT_BUFFER_SIZE.
    if(guessTheDevice) {
#if 0
         const PaStreamInfo *streamInfo;

         err = Pa_OpenDefaultStream(
 				   &stream,                         /* passes back stream pointer */
 				   DEFAULT_IN_CHANNELS,          /* stereo input */
 				   DEFAULT_OUT_CHANNELS,         /* stereo output */
 				   paFloat32,                       /* 32 bit floating point output paFloat32 */
                                          /*  note: this value instructs portaudio
                                           *  what sample size to expect, which
                                           *  is a different constant to that used
                                           *  to talk to the SndKit (SND_FORMAT_*)
                                           */
 	DEFAULT_SAMPLE_RATE,          /* sample rate */
         paFramesPerBufferUnspecified, /* frames per buffer */
         vendBuffersToStreamManagerIOProc, /* specify our custom callback */
         NULL);        /* pass our data through to callback */

 	streamInfo = Pa_GetStreamInfo(stream);
 	bufferSizeInFrames = streamInfo->outputLatency * streamInfo->sampleRate;

 	NSLog(@"outputLatency = %lf seconds, sample rate %lf, bufferSize in Frames = %ld\n",
 	      streamInfo->outputLatency, streamInfo->sampleRate, bufferSizeInFrames);

 	Pa_CloseStream(stream);
	useNativeBufferSize = TRUE;
#else
	useNativeBufferSize = FALSE;
#endif
    }
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

    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  

    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;

    err = Pa_OpenDefaultStream(
        &stream,		/* passes back stream pointer */
        DEFAULT_IN_CHANNELS,	/* stereo input */
        DEFAULT_OUT_CHANNELS,	/* stereo output */
        paFloat32,		/* 32 bit floating point output paFloat32 */
				/* note: this value instructs portaudio
                                   what sample size to expect, which
                                   is a different constant to that used
                                   to talk to the SndKit (SND_FORMAT_*)
                                 */
        DEFAULT_SAMPLE_RATE,	/* sample rate */
        useNativeBufferSize ? paFramesPerBufferUnspecified : bufferSizeInFrames, /* frames per buffer */
        vendBuffersToStreamManagerIOProc, /* specify our custom callback */
        &data);        /* pass our data through to callback */

    if(err != paNoError) {
        NSLog(@"SNDStreamStart: PortAudio Pa_OpenDefaultStream error: %s\n", Pa_GetErrorText(err));
        return FALSE;
    }

    if (inputInit) {
        long bufferSizeInBytes = bufferSizeInFrames * BYTES_PER_FRAME;
        if ((lastRecvdInputBuffer = (float *) malloc(bufferSizeInBytes)) == NULL)
            return FALSE;
        memset(lastRecvdInputBuffer, 0, bufferSizeInBytes);
    }
 
    err = Pa_StartStream(stream);
    if(err != paNoError) {
        NSLog(@"SNDStreamStart: PortAudio Pa_StartStream error: %s\n", Pa_GetErrorText(err));
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

// Return in the stream buffer the format of the sound data preferred by
// the operating system.
PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat, BOOL isOutputStream)
{
    if (!initialised)
	SNDInit(TRUE);

    /* The bytes per frame is implicitly set by the dataFormat value. */
    streamFormat->frameCount   = bufferSizeInFrames;
    streamFormat->dataFormat   = DEFAULT_DATA_FORMAT;
    streamFormat->sampleRate   = DEFAULT_SAMPLE_RATE;
    streamFormat->channelCount = isOutputStream ? DEFAULT_OUT_CHANNELS : DEFAULT_IN_CHANNELS;
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

// Returns an array of character pointers listing the names of each channel.
// There will be channel count number of strings returned, with a NULL terminated
// The naming is system dependent, but is guaranteed to have two
// channels named "Left" and "Right" to ensure that stereo can always be used.
PERFORM_API const char **SNDSpeakerConfiguration(void)
{
    speakerConfigurationList[0] = "Left";
    speakerConfigurationList[1] = "Right";
    speakerConfigurationList[2] = NULL;

    return (const char **) speakerConfigurationList;
}

#ifdef __cplusplus
}
#endif
