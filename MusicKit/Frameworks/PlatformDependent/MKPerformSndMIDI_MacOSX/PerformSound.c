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

#include "PerformSoundPrivate.h"
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

  // We have to be careful copying a SNDSoundStruct as it has allocated unsigned char data that
  // is appended after the structure itself. The stucture doesn't actually include it.
  SndSoundStruct *snd;

  // Number of samples per frame (frame = 1 or more channels per time instant) so we
  // can keep track of time inbetween GenAudio calls.
  int          sampleFramesGenerated; 
  int          sampleToPlay;

  SNDNotificationFun finishedPlayFun;
  SNDNotificationFun startedPlayFun;
  struct _audioStream *next;   // Link to other playing sounds.
} SNDAudioStream;


// "class" variables
static BOOL         initialised = FALSE;
static AudioDeviceID outputDeviceID;
static char         **driverList;
static unsigned int driverIndex = 0;
static int          numOfDevices;
SNDAudioStream      singleAudioStream;
static int          bufferSizeInFrames;
static AudioStreamBasicDescription outputStreamBasicDescription;

// We vend the output and input buffers in their native format to avoid redundant conversions.
// This allows postponing the conversion to the last possible moment. The SndConvertFormat()
// function in the SndKit makes for an easy way to do the conversion without anyone write their
// own converter.
static OSStatus vendBuffersToStreamManagerIOProc(AudioDeviceID inDevice,
                         const AudioTimeStamp *inNow,
                         const void *inInputData,
			 const AudioTimeStamp *inInputTime,
                         void  *outOutputData,
                         const AudioTimeStamp *inOutputTime,
			 void *inClientData)
{
#if 1 // PLAYsingleAudioStream.
    float *inputBuffer;
    float *outputBuffer = outOutputData;
    int deviceChannel;
    int frameIndex;
    unsigned int sampleToPlay;
    unsigned int byteToPlayFrom;
    SndSoundStruct *snd = singleAudioStream.snd;
    int bytesPerSample = 2;    // TODO assume its a short (2 byte / WORD format) needs checking dataFormat.
    int bytesPerFrame = bytesPerSample * snd->channelCount; 

    for (frameIndex = 0; frameIndex < bufferSizeInFrames; frameIndex++) {
        byteToPlayFrom = singleAudioStream.sampleFramesGenerated * bytesPerFrame;
        sampleToPlay = frameIndex * outputStreamBasicDescription.mChannelsPerFrame;
        // check if the sound has been played to the end.
        if(byteToPlayFrom < (unsigned) snd->dataSize && singleAudioStream.isPlaying) {
            for(deviceChannel = 0; deviceChannel < outputStreamBasicDescription.mChannelsPerFrame; deviceChannel++) {
#if SQUAREWAVE_DEBUG
                if (singleAudioStream.sampleFramesGenerated % 500 > 250) {
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
            singleAudioStream.sampleFramesGenerated++;
        }
        else {
            for(deviceChannel = 0; deviceChannel < outputStreamBasicDescription.mChannelsPerFrame; deviceChannel++) {
                outputBuffer[sampleToPlay] = 0.0f;   // if at end of sound, play silence on all channels
                sampleToPlay++;
            }
#if 1
            // Signal back to the rest of the world that we've finished playing the sound.
            if(singleAudioStream.finishedPlayFun != NULL && singleAudioStream.isPlaying) {
                // Mark this sound as finished, but its up to the delegate to stop things?
                (*(singleAudioStream.finishedPlayFun))(snd, singleAudioStream.playTag, 0);
            }
#endif
            singleAudioStream.isPlaying = FALSE;
        }
    }
#else
     SND_FORMAT_FLOAT 
#endif
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
    fprintf(stderr, "AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
        (char *) &CAstatus, propertySize, propertyWritable);

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

    propertySize = sizeof(outputStreamBasicDescription);
    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false,
                                    kAudioDevicePropertyStreamFormat,
                                    &propertySize, &outputStreamBasicDescription);

    fprintf(stderr, "get stream format CAstatus:%s\n", (char *) &CAstatus);

    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %d\n", (int) CAstatus);
        return FALSE;
    }
    
    fprintf(stderr, "device channels: %d\n", 
                            (int) outputStreamBasicDescription.mChannelsPerFrame);
    fprintf(stderr, "native sample rate: %f\n", outputStreamBasicDescription.mSampleRate);
    fprintf(stderr, "encoding type of audio stream %x\n", (int) outputStreamBasicDescription.mFormatID);
    fprintf(stderr, "bytes in a packet %d\n", (int) outputStreamBasicDescription.mBytesPerPacket);
    fprintf(stderr, "number of frames in each packet %d\n", (int) outputStreamBasicDescription.mFramesPerPacket);
    fprintf(stderr, "number of bytes in a frame %d\n", (int) outputStreamBasicDescription.mBytesPerFrame);
    fprintf(stderr, "number of bits in each channel %d\n", (int) outputStreamBasicDescription.mBitsPerChannel);

    /* check the sample rate is changeable */    
    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false,
                                          kAudioDevicePropertyRateScalar,
                                          &propertySize, &propertyWritable);
    fprintf(stderr, "kAudioDevicePropertyRateScalar PropertyInfo CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
        (char *) &CAstatus, propertySize, propertyWritable);
    return TRUE;
}

static BOOL setBufferSize(long int bufferSizeToSetInBytes)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    UInt32 bufferSizeInBytes;

    /* fetch the buffer size for informational purposes */
    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false, kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false, kAudioDevicePropertyBufferSize,
                                    &propertySize, &bufferSizeInBytes);
    
    fprintf(stderr, "get buffer size CAstatus:%s, bufferSizeInBytes = %ld\n", (char *) &CAstatus, bufferSizeInBytes);
    
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %d\n", (int) CAstatus);
        return FALSE;
    }
    
    /* set the buffer size of the device */
    CAstatus = AudioDeviceSetProperty(outputDeviceID, NULL, 0, false,
                                    kAudioDevicePropertyBufferSize,
                                    propertySize, &bufferSizeToSetInBytes);
    
    fprintf(stderr, "set buffer size CAstatus:%s\n", (char *) &CAstatus);
    
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceSetProperty returned %d\n", (int) CAstatus);
        return FALSE;
    }
    
    /* fetch the buffer size to check */
    CAstatus = AudioDeviceGetPropertyInfo(outputDeviceID, 0, false,
                                          kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
        (char *) &CAstatus, propertySize, propertyWritable);

    CAstatus = AudioDeviceGetProperty(outputDeviceID, 0, false, kAudioDevicePropertyBufferSize,
                                    &propertySize, &bufferSizeInBytes);

    fprintf(stderr, "get buffer size CAstatus:%s, bufferSizeInBytes = %ld\n", (char *) &CAstatus, bufferSizeInBytes);
    
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
    
    fprintf(stderr, "running = %d\n", isDeviceRunning(outputDeviceID));
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

// Routine to begin playback
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
            
    CAstatus = AudioDeviceAddIOProc(outputDeviceID, vendBuffersToStreamManagerIOProc, NULL);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceAddIOProc returned %d\n", (int) CAstatus);
        return 0;
    }

    singleAudioStream.playTag = tag;
    singleAudioStream.snd = soundStruct;
    singleAudioStream.sampleFramesGenerated = 0;
    singleAudioStream.sampleToPlay = 0;
    singleAudioStream.startedPlayFun = beginFun;
    singleAudioStream.finishedPlayFun = endFun;
    singleAudioStream.isPlaying = TRUE;
    singleAudioStream.next = NULL;

    CAstatus = AudioDeviceStart(outputDeviceID, vendBuffersToStreamManagerIOProc);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceStart returned %d\n", (int) CAstatus);
        return 0;
    }

    /* detach thread */
    
//    pthread_create( &soundThread, NULL, playSoundFunc, (void *) self );

    // TODO this should be fired when vendBuffersToStreamManagerIOProc is first called.
//    if(singleAudioStream.startedPlayFun != SND_NULL_FUN)
//        (*(singleAudioStream.startedPlayFun))(singleAudioStream.snd, singleAudioStream.playTag, SND_ERR_NONE);
    if(singleAudioStream.startedPlayFun != SND_NULL_FUN)
        (*(singleAudioStream.startedPlayFun))(singleAudioStream.snd, singleAudioStream.playTag, 0);
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
    return singleAudioStream.sampleFramesGenerated;
}

// stop audio playback
PERFORM_API void SNDStop(int tag)
{
    OSStatus CAstatus;

    CAstatus = AudioDeviceStop(outputDeviceID, vendBuffersToStreamManagerIOProc);
    
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceStop returned %d\n", (int) CAstatus);
	return;  // Doesn't have an error code return ability
    }
    
    singleAudioStream.isPlaying = FALSE;
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

#ifdef __cplusplus
}
#endif
