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
// Revision 1.5  2001/02/23 03:17:41  leigh
// Converted times from absolute to relative
//
// Revision 1.4  2001/02/12 17:41:19  leigh
// Added streaming support
//
// Revision 1.3  2001/02/11 22:50:05  leigh
// First draft of simplistic working sound playing using CoreAudio
//
// Revision 1.2  2000/05/05 22:42:48  leigh
// ensure we don't have boolean constants predefined
//
// Revision 1.1  2000/03/11 01:42:19  leigh
// Initial Release
//
// Revision 1.1.1.1  2000/01/14 00:14:33  leigh
// Initial revision
//
*/

#include "PerformSound.h"
#include <CoreAudio/AudioHardware.h>
//#include <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif 


#define SQUAREWAVE_DEBUG 0
#define PADDING 3          // make sure this matches PADFORMAT changes below (including \0)
#define PADFORMAT "%s: %s"

// A linked list of sounds currently playing.
typedef struct _audioStream {
  int            playTag;    // the means to refer to this sound.
  BOOL           isPlaying;

  // We have to be careful copying a SndSoundStruct as it has allocated unsigned char data that
  // is appended after the structure itself. The stucture doesn't actually include it.
  SndSoundStruct *snd;

  // Number of samples per frame (frame = 1 or more channels per time instant) so we
  // can keep track of time inbetween sndPlayIOProc calls.
  int          sampleFramesGenerated; 
  int          sampleToPlay;

  SNDNotificationFun finishedPlayFun;
  SNDNotificationFun startedPlayFun;
  struct _audioStream *next;   // Link to other playing sounds.
} SNDPlayingSound;

// "class" variables
static BOOL         initialised = FALSE;
static AudioDeviceID outputDeviceID;
static char         **driverList;
static unsigned int driverIndex = 0;
static int          numOfDevices;
static SNDPlayingSound singlePlayingSound;
static int          bufferSizeInFrames;
static AudioStreamBasicDescription outputStreamBasicDescription;
// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void *streamUserData;
static double firstSampleTime = -1.0; // indicates this has not been assigned.

// Routine to play a single sound. This could be generalised using the link-list behaviour
// to do multiple sound channels, but instead we will adopt the stream operation within the
// SndKit itself.
static OSStatus sndPlayIOProc(AudioDeviceID inDevice,
                         const AudioTimeStamp *inNow,
                         const void *inInputData,
			 const AudioTimeStamp *inInputTime,
                         void  *outOutputData,
                         const AudioTimeStamp *inOutputTime,
			 void *inClientData)
{
    float *outputBuffer = outOutputData;
    int deviceChannel;
    int frameIndex;
    unsigned int sampleToPlay;
    unsigned int byteToPlayFrom;
    SndSoundStruct *snd = singlePlayingSound.snd;
    int bytesPerSample = 2;    // TODO assume its a short (2 byte / WORD format) needs checking dataFormat.
    int bytesPerFrame = bytesPerSample * snd->channelCount; 

    for (frameIndex = 0; frameIndex < bufferSizeInFrames; frameIndex++) {
        byteToPlayFrom = singlePlayingSound.sampleFramesGenerated * bytesPerFrame;
        sampleToPlay = frameIndex * outputStreamBasicDescription.mChannelsPerFrame;
        // check if the sound has been played to the end.
        if(byteToPlayFrom < (unsigned) snd->dataSize && singlePlayingSound.isPlaying) {
            for(deviceChannel = 0; deviceChannel < outputStreamBasicDescription.mChannelsPerFrame; deviceChannel++) {
#if SQUAREWAVE_DEBUG
                if (singlePlayingSound.sampleFramesGenerated % 500 > 250) {
                    outputBuffer[sampleToPlay] = 0.4f;
                }
                else {
                    outputBuffer[sampleToPlay] = -0.4f;
                }
#else
                unsigned char *grabDataFrom;
                signed short sampleWord;

                grabDataFrom = (unsigned char *) snd + snd->dataLocation + byteToPlayFrom;
                // obtain data from big-endian ordered words
                sampleWord = (((signed short) grabDataFrom[0]) << 8) + (grabDataFrom[1] & 0xff);
                outputBuffer[sampleToPlay] = sampleWord / 32768.0f;  // make a float, do any other sounds, normalize and then write it.
                if(snd->channelCount != 1)	// play mono by sending same sample to all channels
                    byteToPlayFrom += bytesPerSample;
#endif
                sampleToPlay++;
            }
            singlePlayingSound.sampleFramesGenerated++;
        }
        else {
            for(deviceChannel = 0; deviceChannel < outputStreamBasicDescription.mChannelsPerFrame; deviceChannel++) {
                outputBuffer[sampleToPlay] = 0.0f;   // if at end of sound, play silence on all channels
                sampleToPlay++;
            }
            // Signal back to the rest of the world that we've finished playing the sound.
            if(singlePlayingSound.finishedPlayFun != NULL && singlePlayingSound.isPlaying) {
                // Mark this sound as finished, but its up to the delegate to stop things?
                (*(singlePlayingSound.finishedPlayFun))(snd, singlePlayingSound.playTag, 0);
            }
            singlePlayingSound.isPlaying = FALSE;
        }
    }
    return 0; // TODO need better definition...
}

// We vend the output and input buffers in their native format to avoid redundant conversions.
// This allows postponing the conversion to the last possible moment. The SndConvertFormat()
// function in the SndKit makes for an easy way to do the conversion without anyone writing their
// own converter.
static OSStatus vendBuffersToStreamManagerIOProc(AudioDeviceID inDevice,
                         const AudioTimeStamp *inNow,
                         const void *inInputData,
			 const AudioTimeStamp *inInputTime,
                         void  *outOutputData,
                         const AudioTimeStamp *inOutputTime,
			 void *inClientData)
{
    SNDStreamBuffer inStream, outStream;

    if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
        fprintf(stderr, "sample time is not valid!\n");
    }
    if(firstSampleTime == -1.0)
        firstSampleTime = inOutputTime->mSampleTime;
    SNDStreamNativeFormat(&inStream.streamFormat);    // to tell the client the format it is receiving.
    inStream.streamData = (void *) inInputData;  // this will generate a warning since we use the same type for both streams.
    SNDStreamNativeFormat(&outStream.streamFormat);   // to tell the client the format it should send.
    outStream.streamData = outOutputData;
    
    // hand over the stream buffers to the processor/stream manager.
    // the output time goes out as a relative time, noted from the first sample time we first receive.
    (*streamProcessor)(inOutputTime->mSampleTime - firstSampleTime, &inStream, &outStream, streamUserData);
    return 0; // TODO need better definition...
}

// Iterate through the possible devices and build a formatted list.
// A NULL char * terminates the list a la argv behaviour.
static BOOL retrieveDriverList(void)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    int driverIndex = 0;
    AudioDeviceID *allDeviceIDs;

    // TODO for now, fudge we have only one driver, the default. We should retrieve the full list.
    numOfDevices = 1; // TODO assume there is at least one.

    CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, &propertyWritable);
//    fprintf(stderr, "AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
//        (char *) &CAstatus, propertySize, propertyWritable);

    if (CAstatus) {
        fprintf(stderr, "AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices returned %s\n", (char *) &CAstatus);
        return FALSE;
    }

    CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDevices,
                    &propertySize, &allDeviceIDs);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %s\n", (char *) &CAstatus);
        return FALSE;
    }

    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
        fprintf(stderr, "Unable to malloc driver list\n");
        return FALSE;
    }
    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
#if 0
        CAstatus = AudioDeviceGetPropertyInfo(allDeviceIDs[driverIndex], 0, false,
                                            kAudioDevicePropertyDeviceName,
                                            &propertySize, &propertyWritable);
        fprintf(stderr, "output device CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
            (char *) &CAstatus, propertySize, propertyWritable);
            
        // malloc up enough memory for the name.
        if((deviceName = (char *) malloc(propertySize * sizeof(char))) == NULL) {
            fprintf(stderr, "Unable to malloc deviceName string\n");
            return FALSE;
        }
        
        // get the name.
        CAstatus = AudioDeviceGetProperty(allDeviceIDs[driverIndex], 0, false,
                                        kAudioDevicePropertyDeviceName,
                                        &propertySize, deviceName);
        if (CAstatus) {
            fprintf(stderr, "AudioDeviceGetProperty returned %s\n", (char *) &CAstatus);
            return FALSE;
        }
    
        driverList[driverIndex] = deviceName;
#endif
    }
    driverList[driverIndex] = NULL; // NULL terminate the list
    return TRUE;
}

static BOOL isDeviceRunning(AudioDeviceID outputDeviceID)
{
    UInt32 running;
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    /* check the device is running */    
    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false,
                                          kAudioDevicePropertyDeviceIsRunning,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo returned %d\n", (int) CAstatus);
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
                                    kAudioDevicePropertyDeviceIsRunning,
                                    &propertySize, &running);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %d\n", (int) CAstatus);
        return FALSE;
    }
    return running != 0;
}

// determine basic description, we use some of the fields for filling buffers.
static BOOL determineBasicDescription(AudioDeviceID outputDeviceID)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false,
                                          kAudioDevicePropertyStreamFormat,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyStreamFormat %d\n", (int) CAstatus);
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
                                    kAudioDevicePropertyStreamFormat,
                                    &propertySize, &outputStreamBasicDescription);

//    fprintf(stderr, "get stream format CAstatus:%s\n", (char *) &CAstatus);

    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %d\n", (int) CAstatus);
        return FALSE;
    }

#if 0
    fprintf(stderr, "device channels: %d\n", 
                            (int) outputStreamBasicDescription.mChannelsPerFrame);
    fprintf(stderr, "native sample rate: %f\n", outputStreamBasicDescription.mSampleRate);
    fprintf(stderr, "encoding type of audio stream %x\n", (int) outputStreamBasicDescription.mFormatID);
    fprintf(stderr, "bytes in a packet %d\n", (int) outputStreamBasicDescription.mBytesPerPacket);
    fprintf(stderr, "number of frames in each packet %d\n", (int) outputStreamBasicDescription.mFramesPerPacket);
    fprintf(stderr, "number of bytes in a frame %d\n", (int) outputStreamBasicDescription.mBytesPerFrame);
    fprintf(stderr, "number of bits in each channel %d\n", (int) outputStreamBasicDescription.mBitsPerChannel);
#endif

    /* check the sample rate is changeable */    
#if 0
    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false,
                                          kAudioDevicePropertyRateScalar,
                                          &propertySize, &propertyWritable);
    fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyRateScalar  CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
        (char *) &CAstatus, propertySize, propertyWritable);
#endif
    return TRUE;
}

static BOOL setBufferSize(long int bufferSizeToSetInBytes)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    UInt32 bufferSizeInBytes;

    /* fetch the buffer size for informational purposes */
#if 0 // only needed for debugging
    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false, kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize returned %d\n", (int) CAstatus);
        return FALSE;
    }
    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false, kAudioDevicePropertyBufferSize,
                                    &propertySize, &bufferSizeInBytes);
    
    fprintf(stderr, "get buffer size CAstatus:%s, bufferSizeInBytes = %ld\n", (char *) &CAstatus, bufferSizeInBytes);
    
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %d\n", (int) CAstatus);
        return FALSE;
    }
#endif
    
    /* set the buffer size of the device */
    CAstatus = AudioDeviceSetProperty(outputDeviceID, NULL, 0, false,
                                    kAudioDevicePropertyBufferSize,
                                    propertySize, &bufferSizeToSetInBytes);
    
//    fprintf(stderr, "set buffer size CAstatus:%s\n", (char *) &CAstatus);
    
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceSetProperty returned %d\n", (int) CAstatus);
        return FALSE;
    }
    
    /* fetch the buffer size to check */
    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false,
                                          kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize returned %d\n", (int) CAstatus);
        return FALSE;
    }
//    fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
//        (char *) &CAstatus, propertySize, propertyWritable);

    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false, kAudioDevicePropertyBufferSize,
                                    &propertySize, &bufferSizeInBytes);

//    fprintf(stderr, "get buffer size CAstatus:%s, bufferSizeInBytes = %ld\n", (char *) &CAstatus, bufferSizeInBytes);
    
    if (bufferSizeInBytes != bufferSizeToSetInBytes) {
        fprintf(stderr, "device did not set desired buffer size\n");
        fprintf(stderr, "desired: %d\nactual: %d\n", (int) bufferSizeToSetInBytes,
                (int) bufferSizeInBytes);
        return FALSE;
    }
    bufferSizeInFrames = bufferSizeInBytes / outputStreamBasicDescription.mBytesPerFrame;

    return TRUE;
}

// Takes a parameter indicating whether to guess the device to select.
// This allows us to hard code devices or use heuristics to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
PERFORM_API BOOL SNDInit(BOOL guessTheDevice)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    if(!initialised)
        initialised = TRUE;                   // SNDSetDriverIndex() needs to think we're initialised.

    if(!retrieveDriverList())
        return FALSE;
    
    /* initialize CoreAudio device */
    if(guessTheDevice) {
        /* Get the default sound output device */    
        CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultOutputDevice, &propertySize, &propertyWritable);
        CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                        &propertySize, &outputDeviceID);
    
        if (CAstatus) {
            fprintf(stderr, "AudioHardwareGetProperty returned %d\n", (int) CAstatus);
            return FALSE;
        }
        driverIndex = 0;  // TODO must find the default output device ID in the driver list and return its index
    }
    else {
        fprintf(stderr, "Didn't guess the device\n");
        driverIndex = 0;
    }
    
    /* check the returned device */    
    if (outputDeviceID == kAudioDeviceUnknown) {
        fprintf(stderr, "outputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    
    if(isDeviceRunning(outputDeviceID)) {
        fprintf(stderr, "device is already running\n");
        return FALSE;
    }
    if(!determineBasicDescription(outputDeviceID))
        return FALSE;
    if(!setBufferSize(32768))
        return FALSE;
        
    return TRUE;
}

// Returns an array of strings listing the available drivers.
// Returns NULL if the driver names were unobtainable.
// The client application should not attempt to free the pointers.
// TODO return driverIndex by reference
PERFORM_API char **SNDGetAvailableDriverNames(void)
{
    char *deviceName;
    OSStatus CAstatus;
    UInt32 propertySize = 256;
    
    // This needs to be called after initialising. TODO - probably should call the initialisation.
    if(!initialised)
        return NULL;

// TODO all this should move into retrieveDriverList
    if((deviceName = (char *) malloc(propertySize * sizeof(char))) == NULL) {
        fprintf(stderr, "Unable to malloc deviceName string\n");
        return NULL;
    }
    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
                                    kAudioDevicePropertyDeviceName,
                                    &propertySize, deviceName);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %s\n", (char *) &CAstatus);
        return NULL;
    }

    driverList[driverIndex] = deviceName;
// TODO

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
    return FALSE; // TODO
}

PERFORM_API void SNDSetMute(BOOL aFlag)
{
    // TODO
}

// Routine to begin playback of a sound struct
PERFORM_API int SNDStartPlaying(SndSoundStruct *soundStruct, 
                                int tag, int priority,  int preempt, 
                                SNDNotificationFun beginFun, SNDNotificationFun endFun)
{
    OSStatus CAstatus;

    if(!initialised)
        return 1;  // invalid sound structure.
 
    if(soundStruct->magic != SND_MAGIC)
        return 1;  // probably SND_ERROR_NOT_SOUND is more descriptive, but this matches SoundKit specs.
    
//    playBegin = 0;
//    playEnd = [self sampleCount];
            
    CAstatus = AudioDeviceAddIOProc(outputDeviceID, sndPlayIOProc, NULL);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceAddIOProc returned %d\n", (int) CAstatus);
        return 0;
    }

    singlePlayingSound.playTag = tag;
    singlePlayingSound.snd = soundStruct;
    singlePlayingSound.sampleFramesGenerated = 0;
    singlePlayingSound.sampleToPlay = 0;
    singlePlayingSound.startedPlayFun = beginFun;
    singlePlayingSound.finishedPlayFun = endFun;
    singlePlayingSound.isPlaying = TRUE;
    singlePlayingSound.next = NULL;

    CAstatus = AudioDeviceStart(outputDeviceID, sndPlayIOProc);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceStart returned %d\n", (int) CAstatus);
        return 0;
    }

    // TODO this should be fired when sndPlayIOProc is first called.
    if(singlePlayingSound.startedPlayFun != SND_NULL_FUN)
        (*(singlePlayingSound.startedPlayFun))(singlePlayingSound.snd, singlePlayingSound.playTag, 0);
    return 0;
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

// TODO So are the number of samples processed, the number of frames, or the number of samples per channel?
PERFORM_API int SNDSamplesProcessed(int tag)
{
    return singlePlayingSound.sampleFramesGenerated;
}

// stop audio playback
PERFORM_API void SNDStop(int tag)
{
    OSStatus CAstatus;

    if(singlePlayingSound.isPlaying) {
        CAstatus = AudioDeviceStop(outputDeviceID, sndPlayIOProc);
        
        if (CAstatus) {
            fprintf(stderr, "AudioDeviceStop returned %d\n", (int) CAstatus);
            return;  // Doesn't have an error code return ability
        }
    }
        
    singlePlayingSound.isPlaying = FALSE;
}

PERFORM_API void SNDPause(int tag)
{
}

PERFORM_API void SNDResume(int tag)
{
// TODO
}

PERFORM_API int SNDUnreserve(int dunno)
{
    return 0;
}

PERFORM_API void SNDTerminate(void)
{
}

// 

// Return in the struct the format of the sound data preferred by
// the operating system. For CoreAudio, we use the basicDescription.
PERFORM_API void SNDStreamNativeFormat(SndSoundStruct *streamFormat)
{
    streamFormat->magic = SND_MAGIC;
    streamFormat->dataLocation = 0;   /* Offset or pointer to the raw data */
    /* Number of bytes of data in a buffer */
    streamFormat->dataSize = bufferSizeInFrames * outputStreamBasicDescription.mBytesPerFrame;
    streamFormat->dataFormat = SND_FORMAT_FLOAT;
    streamFormat->samplingRate = outputStreamBasicDescription.mSampleRate;
    streamFormat->channelCount = outputStreamBasicDescription.mChannelsPerFrame;
    streamFormat->info[0] = '\0';
}

// Routine to begin playback/recording of a stream.
PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *newUserData)
{
    OSStatus CAstatus;

    if(!initialised)
        return FALSE;  // invalid sound structure.
 
    streamProcessor = newStreamProcessor;
    streamUserData = newUserData;
    
    CAstatus = AudioDeviceAddIOProc(outputDeviceID, vendBuffersToStreamManagerIOProc, NULL);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceAddIOProc returned %d\n", (int) CAstatus);
        return FALSE;
    }

    CAstatus = AudioDeviceStart(outputDeviceID, vendBuffersToStreamManagerIOProc);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceStart returned %d\n", (int) CAstatus);
        return FALSE;
    }
    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  
    return TRUE;
}

PERFORM_API BOOL SNDStreamStop(void)
{
    OSStatus CAstatus;

    CAstatus = AudioDeviceStop(outputDeviceID, vendBuffersToStreamManagerIOProc);
    
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceStop returned %d\n", (int) CAstatus);
	return FALSE;
    }
    firstSampleTime = -1.0;  
    return TRUE;
}

#ifdef __cplusplus
}
#endif
