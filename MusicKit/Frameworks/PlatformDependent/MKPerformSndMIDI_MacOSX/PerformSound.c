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
// Revision 1.9  2001/04/06 18:16:06  skotmcdonald
// Added input stream functionality to SndStreaming system. Note that as
// MacOSX reports the default audio in as a separate device to the audio out,
// CoreAudio generates two callbacks to the vendBuffersToStreamManagerIOProc
// function. To achieve synchronous IO in this case, the input buffer is
// stored in a local buffer until the next output buffer callback occurs, at
// which time both the local input and the core audio output buffers are sent
// upward together. Note this assumes the input and output buffers have been
// sent to the same size!!! (have to add some enforcing code later...)
//
// Many coreaudio interfacing functions made in/out dual purpose, some extra
// feedback fns added too.
//
// Revision 1.8  2001/03/21 02:59:43  leigh
// Removed old debugging info
//
// Revision 1.7  2001/03/12 19:15:58  leigh
// Cleaned up debugging info
//
// Revision 1.6  2001/03/08 18:48:30  leigh
// controlled debugging info, adopted 4K46 CoreAudio buffer use
//
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

#include <CoreAudio/CoreAudio.h>
#include <c.h>         // for FALSE etc
#include <stdlib.h>    // for NULL definition
#include <stdio.h>     // for stderr
#include "PerformSound.h"

#ifdef __cplusplus
extern "C" {
#endif 

#define DEBUG_SQUAREWAVE    0  // generate a square wave, rather than the real audio data
#define DEBUG_DESCRIPTION   0  // dump the description of the audio device.
#define DEBUG_BUFFERSIZE    0  // dump the check of the audio buffer size.
#define DEBUG_SNDPLAYIOPROC 0  // dump the channel count etc while generating the buffer.

#define PADDING 3          // make sure this matches PADFORMAT changes below (including \0)
#define PADFORMAT "%s: %s"

#define ENABLE_INPUT

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

static char         **driverList;
static unsigned int driverIndex = 0;
static int          numOfDevices;
static SNDPlayingSound singlePlayingSound;
static int          bufferSizeInFrames;

static AudioStreamBasicDescription outputStreamBasicDescription;
static AudioDeviceID outputDeviceID;
#ifdef ENABLE_INPUT
static AudioStreamBasicDescription inputStreamBasicDescription;
static AudioDeviceID inputDeviceID;
#endif

// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void *streamUserData;
static double firstSampleTime = -1.0; // indicates this has not been assigned.

////////////////////////////////////////////////////////////////////////////////
// getCoreAudioErrorString
////////////////////////////////////////////////////////////////////////////////

static char *getCoreAudioErrorStr(OSStatus status)
{
  char *r = NULL;
  switch (status)
  {
    case kAudioHardwareNotRunningError:		    r = "Hardware not running error";        break;
    case kAudioHardwareUnspecifiedError:		  r = "Hardware unspecified error";        break;
    case kAudioHardwareUnknownPropertyError:	r = "Hardware unknown property error";   break;
    case kAudioDeviceUnsupportedFormatError:	r = "Hardware unsupported format error"; break;
    case kAudioHardwareBadPropertySizeError:	r = "Hardware bad property size error";  break;
    case kAudioHardwareIllegalOperationError:	r = "Hardware illegal operation";        break;
    case kAudioHardwareNoError:               r = "none";                              break;
    default:                                  r = "unknown";
  }
  return r;
}

////////////////////////////////////////////////////////////////////////////////
// sndPlayIOProc
//
// Routine to play a single sound. This could be generalised using the link-list 
// behaviour to do multiple sound channels, but instead we will adopt the stream 
// operation within the SndKit itself.
/////////////////////////////////////////////////////////////////////////////////

static OSStatus sndPlayIOProc(AudioDeviceID inDevice,
                         const AudioTimeStamp *inNow,
                         const AudioBufferList *inInputData,
			 const AudioTimeStamp *inInputTime,
                         AudioBufferList  *outOutputData,
                         const AudioTimeStamp *inOutputTime,
			 void *inClientData)
{
    float *outputBuffer;
    int deviceChannel;
    int frameIndex;
    unsigned int sampleToPlay;
    SndSoundStruct *snd = singlePlayingSound.snd;
    int bytesPerSample = 2;    // TODO assume its a short (2 byte / WORD format) needs checking dataFormat.
    int bufferIndex;

    for(bufferIndex = 0; bufferIndex < outOutputData->mNumberBuffers; bufferIndex++) {
        int channelsPerFrame = outOutputData->mBuffers[bufferIndex].mNumberChannels;
        outputBuffer = outOutputData->mBuffers[bufferIndex].mData;
#if DEBUG_SNDPLAYIOPROC
        fprintf(stderr, "channelsPerFrame = %d\n", channelsPerFrame);
        fprintf(stderr, "bufferSizeInFrames = %d, mDataByteSize = %ld\n", bufferSizeInFrames, outOutputData->mBuffers[bufferIndex].mDataByteSize);
        fprintf(stderr, "sampleFramesGenerated = %d\n", singlePlayingSound.sampleFramesGenerated);
#endif

        for (frameIndex = 0; frameIndex < bufferSizeInFrames; frameIndex++) {
            int bytesPerFrame = bytesPerSample * snd->channelCount;
            unsigned int byteToPlayFrom = singlePlayingSound.sampleFramesGenerated * bytesPerFrame;
            sampleToPlay = frameIndex * channelsPerFrame;
            
            // check if the sound has been played to the end.
            if(byteToPlayFrom < (unsigned) snd->dataSize && singlePlayingSound.isPlaying) {
                for(deviceChannel = 0; deviceChannel < channelsPerFrame; deviceChannel++) {
#if DEBUG_SQUAREWAVE
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
                for(deviceChannel = 0; deviceChannel < channelsPerFrame; deviceChannel++) {
                    outputBuffer[sampleToPlay] = 0.0f;   // if at end of sound, play silence on all channels
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
    }
    return 0; // TODO need better definition...
}

////////////////////////////////////////////////////////////////////////////////
// vendBuffersToStreamManagerIOProc
//
// We vend the output and input buffers in their native format to avoid 
// redundant conversions. This allows postponing the conversion to the last 
// possible moment. The SndConvertFormat() function in the SndKit makes for an 
// easy way to do the conversion without anyone writing their own converter.
////////////////////////////////////////////////////////////////////////////////

float fBlatantHackBuffer[10000];

static OSStatus vendBuffersToStreamManagerIOProc(AudioDeviceID inDevice,
                          const AudioTimeStamp *inNow,
                          const AudioBufferList *inInputData,
                          const AudioTimeStamp *inInputTime,
                          AudioBufferList *outOutputData,
                          const AudioTimeStamp *inOutputTime,
                          void *inClientData)
{
    SNDStreamBuffer inStream, outStream;
    int bufferIndex;

    if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
        fprintf(stderr, "sample time is not valid!\n");
    }
    if(firstSampleTime == -1.0) {
        firstSampleTime = inOutputTime->mSampleTime;
    }

    // fprintf(stderr, "vendBuffersToStreamManagerIOProc number of buffers = %ld\n", outOutputData->mNumberBuffers);
    // 4K46 occasionally sends us a wierd number of buffers
    
    for(bufferIndex = 0; bufferIndex < 1 /* outOutputData->mNumberBuffers */ ; bufferIndex++) {
        // TODO we should alter inStream and outStream to be the buffer's number of channels.
//        int channelsPerFrame = outOutputData->mBuffers[bufferIndex].mNumberChannels;
        
        /*
        fprintf(stderr, "InBuffs: %li  OutBuffs: %li\n",
                inInputData->mNumberBuffers,outOutputData->mNumberBuffers);  
        */
        
        // to tell the client the format it is receiving.
        
        if (inInputData->mNumberBuffers == NULL)
          inStream.streamData = NULL;
        else {
          memcpy(fBlatantHackBuffer, inInputData->mBuffers[0].mData, 32768);
        }
        // to tell the client the format it should send.
        
        if (outOutputData->mNumberBuffers == 0)
          outStream.streamData = NULL;
        else {
        
          SNDStreamNativeFormat(&outStream.streamFormat);   
          SNDStreamNativeFormat(&inStream.streamFormat);    
        
          inStream.streamData  = fBlatantHackBuffer;  
          outStream.streamData = outOutputData->mBuffers[bufferIndex].mData;
        
          // hand over the stream buffers to the processor/stream manager.
          // the output time goes out as a relative time, noted from the 
          // first sample time we first receive.
          (*streamProcessor)(inOutputTime->mSampleTime - firstSampleTime, 
                             &inStream, &outStream, streamUserData);
        }
    }
    return 0; // TODO need better definition...
}

////////////////////////////////////////////////////////////////////////////////
// retrieveDriverList
//
// Iterate through the possible devices and build a formatted list.
// A NULL char * terminates the list a la argv behaviour.
////////////////////////////////////////////////////////////////////////////////

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
    // fprintf(stderr, "AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
    //    (char *) &CAstatus, propertySize, propertyWritable);

    if (CAstatus) {
        fprintf(stderr, "AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDevices,
                    &propertySize, &allDeviceIDs);
    // fprintf(stderr, "AudioHardwareGetProperty kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld\n", (char *) &CAstatus, propertySize);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty 1 returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    // fprintf(stderr, "numOfDevices = %ld\n", propertySize / sizeof(AudioDeviceID));
    // allDeviceIDs = %d\n", allDeviceIDs);

    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
        fprintf(stderr, "Unable to malloc driver list\n");
        return FALSE;
    }
    
#if 0
    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
        char* deviceName;
        CAstatus = AudioDeviceGetPropertyInfo(allDeviceIDs[driverIndex], 0, false,
                                            kAudioDevicePropertyDeviceName,
                                            &propertySize, &propertyWritable);
        fprintf(stderr, "output device CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
            getCoreAudioErrorStr(CAstatus), propertySize, propertyWritable);
            
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
            fprintf(stderr, "AudioDeviceGetProperty 2 returned %s\n", getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }
        else
          fprintf(stderr,"DevID: %p   name: %s\n", allDeviceIDs[driverIndex], deviceName);
    
        driverList[driverIndex] = deviceName;
    }
#endif

    driverList[driverIndex] = NULL; // NULL terminate the list
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// isDeviceRunning
////////////////////////////////////////////////////////////////////////////////

static BOOL isDeviceRunning(AudioDeviceID deviceID, bool isInput)
{
    UInt32 running;
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    /* check the device is running */    
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyDeviceIsRunning,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
                                    kAudioDevicePropertyDeviceIsRunning,
                                    &propertySize, &running);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty 3 returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    return running != 0;
}

////////////////////////////////////////////////////////////////////////////////
// dumpStreamDescription
////////////////////////////////////////////////////////////////////////////////

void dumpStreamDescription(AudioStreamBasicDescription *StrBasDesc)
{
  fprintf(stderr,"samplerate:      %f\nformat:           %li\nFormatflags:     %X\n",
  StrBasDesc->mSampleRate,		    //	the native sample rate of the audio stream
  StrBasDesc->mFormatID,		  	  //	the specific encoding type of audio stream
  (unsigned int)StrBasDesc->mFormatFlags);		  //	flags specific to each format
  fprintf(stderr,"bytesPerPacket:  %li\nframesPerPacket: %li\nBytesPerFrame:   %li\n",
  StrBasDesc->mBytesPerPacket,	  //	the number of bytes in a packet
  StrBasDesc->mFramesPerPacket,  	//	the number of frames in each packet
  StrBasDesc->mBytesPerFrame);	  //	the number of bytes in a frame
  fprintf(stderr,"ChannelsPerFrame:%li\nBitsPerChannel:  %li\n",
  StrBasDesc->mChannelsPerFrame,	//	the number of channels in each frame
  StrBasDesc->mBitsPerChannel);
}

////////////////////////////////////////////////////////////////////////////////
// determineBasicDescription
//
// We use some of the fields for filling buffers.
////////////////////////////////////////////////////////////////////////////////

static BOOL determineBasicDescription(AudioDeviceID deviceID, 
                                      AudioStreamBasicDescription* audStrBasDesc,
                                      BOOL isInput)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyStreamFormat,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyStreamFormat: %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
                                    kAudioDevicePropertyStreamFormat,
                                    &propertySize, audStrBasDesc);

#if DEBUG_DESCRIPTION
    fprintf(stderr,"device ID: %p\n", deviceID);
    dumpStreamDescription(audStrBasDesc);
#endif

    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    

// check to see if the sample rate is changeable...     
#if 0
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyRateScalar,
                                          &propertySize, &propertyWritable);
    fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyRateScalar  CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
        getCoreAudioErrorStr(CAstatus), propertySize, propertyWritable);
#endif
  {
    long    propertySize;
    Boolean propertyWritable;
    char    deviceName[1024];
    
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyDeviceName,
                                          &propertySize, &propertyWritable);

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
                                      kAudioDevicePropertyDeviceName,
                                      &propertySize, deviceName);
#if DEBUG_DESCRIPTION
    fprintf("Devicename: %s\n",deviceName);
#endif
  }
  return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// setBufferSize
////////////////////////////////////////////////////////////////////////////////

static BOOL setBufferSize(AudioDeviceID deviceID, 
                          long bufferSizeToSetInBytes, 
                          BOOL isInput)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    UInt32 bufferSizeInBytes;

    /* fetch the buffer size for informational purposes */
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
#if DEBUG_BUFFERSIZE // only needed for debugging
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
                                    &propertySize, &bufferSizeInBytes);
    
    fprintf(stderr, "get buffer size CAstatus:%s, bufferSizeInBytes = %ld\n", getCoreAudioErrorStr(CAstatus), bufferSizeInBytes);
    
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty 5 returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
#endif
    
    /* set the buffer size of the device */
    CAstatus = AudioDeviceSetProperty(deviceID, NULL, 0, isInput,
                                    kAudioDevicePropertyBufferSize,
                                    propertySize, &bufferSizeToSetInBytes);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceSetProperty (output) returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    /* fetch the buffer size to check */
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo (output) kAudioDevicePropertyBufferSize returned %d\n", (int) CAstatus);
        return FALSE;
    }
        
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
                                    &propertySize, &bufferSizeInBytes);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty (output) BufferSize returned %d\n", (int) CAstatus);
        return FALSE;
    }

#if DEBUG_BUFFERSIZE // only needed for debugging
    fprintf(stderr, "get buffer size CAstatus:%s, bufferSizeInBytes = %ld\n", getCoreAudioErrorStr(CAstatus), bufferSizeInBytes);
#endif
    
    if (bufferSizeInBytes != bufferSizeToSetInBytes) {
        fprintf(stderr, "device did not set desired buffer size\n");
        fprintf(stderr, "desired: %d\nactual: %d\n", (int) bufferSizeToSetInBytes,
                (int) bufferSizeInBytes);
        return FALSE;
    }
    bufferSizeInFrames = bufferSizeInBytes / outputStreamBasicDescription.mBytesPerFrame;

    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// SNDInit
//
// Takes a parameter indicating whether to guess the device to select.
// This allows us to hard code devices or use heuristics to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDInit(BOOL guessTheDevice)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    
    memset(fBlatantHackBuffer, 0, sizeof(float)*10000);

    if(!retrieveDriverList())
        return FALSE;
    
    if(!initialised)
        initialised = TRUE;                   // SNDSetDriverIndex() needs to think we're initialised.

    /* initialize CoreAudio device */
    if(guessTheDevice) {
        /* Get the default sound output device */    
        CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultOutputDevice, 
                                                &propertySize, &propertyWritable);
        CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
                                            &propertySize, &outputDeviceID);
        if (CAstatus) {
            fprintf(stderr, "Output: AudioHardwareGetProperty returned %s\n",
                    getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }
        CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultInputDevice, 
                                                &propertySize, &propertyWritable);
        CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
                                                &propertySize, &inputDeviceID);
        if (CAstatus) {
            fprintf(stderr, "Input: AudioHardwareGetProperty returned %s\n", getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }
        driverIndex = 0;  // TODO must find the default output device ID in the driver list and return its index
    }
    else {
        fprintf(stderr, "Didn't guess the device\n");
        driverIndex = 0;
    }
    
#if DEBUG_DESCRIPTION
//    fprintf(stderr,"OUTPUT ===========\n");
#endif
    
    /* check the returned device */    
    if (outputDeviceID == kAudioDeviceUnknown) {
        fprintf(stderr, "outputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(isDeviceRunning(outputDeviceID, false)) {
        fprintf(stderr, "output device is already running\n");
        return FALSE;
    }
    if(!determineBasicDescription(outputDeviceID, &outputStreamBasicDescription, false))
        return FALSE;

#if DEBUG_DESCRIPTION
//    fprintf(stderr,"INPUT ===========\n");
#endif

    if (inputDeviceID == kAudioDeviceUnknown) {
        fprintf(stderr, "inputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(isDeviceRunning(inputDeviceID, true)) {
        fprintf(stderr, "input device is already running\n");
        return FALSE;
    }
    if(!determineBasicDescription(inputDeviceID, &inputStreamBasicDescription, true))
        return FALSE;

    if(!setBufferSize(outputDeviceID, 16384, false))
        return FALSE;
    if(!setBufferSize(inputDeviceID, 16384, true))
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
        fprintf(stderr, "AudioDeviceGetProperty 7 returned %s\n", getCoreAudioErrorStr(CAstatus));
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
        fprintf(stderr, "AudioDeviceAddIOProc returned %s\n", getCoreAudioErrorStr(CAstatus));
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
        fprintf(stderr, "AudioDeviceStart returned %s\n", getCoreAudioErrorStr(CAstatus));
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
            fprintf(stderr, "AudioDeviceStop returned %s\n", getCoreAudioErrorStr(CAstatus));
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
    streamFormat->dataSize     = bufferSizeInFrames * outputStreamBasicDescription.mBytesPerFrame;
    streamFormat->dataFormat   = SND_FORMAT_FLOAT;
    streamFormat->samplingRate = outputStreamBasicDescription.mSampleRate;
    streamFormat->channelCount = outputStreamBasicDescription.mChannelsPerFrame;
    streamFormat->info[0]      = '\0';
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStart
//
// Routine to begin playback/recording of a stream.
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *newUserData)
{
    BOOL r = TRUE;
    OSStatus CAstatus;

    if(!initialised)
        return FALSE;  // invalid sound structure.
 
    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;
    
    CAstatus = AudioDeviceAddIOProc(outputDeviceID, vendBuffersToStreamManagerIOProc, NULL);
    if (CAstatus) {
        fprintf(stderr, "SNDStartStreaming: AudioDeviceAddIOProc returned %s\n",
                getCoreAudioErrorStr(CAstatus));
        r = FALSE;
    }
    CAstatus = AudioDeviceAddIOProc(inputDeviceID, vendBuffersToStreamManagerIOProc, NULL);
    if (CAstatus) {
        fprintf(stderr, "SNDStartStreaming: AudioDeviceAddIOProc returned %s\n",
         				getCoreAudioErrorStr(CAstatus));
        r = FALSE;
    }
    if (r) { // all is well so far...
      CAstatus = AudioDeviceStart(outputDeviceID, vendBuffersToStreamManagerIOProc);
      if (CAstatus) {
          fprintf(stderr, "SNDStartStreaming: AudioDeviceStart returned %s\n",
                  getCoreAudioErrorStr(CAstatus));
          r = FALSE;
      }
      CAstatus = AudioDeviceStart(inputDeviceID, vendBuffersToStreamManagerIOProc);
      if (CAstatus) {
          fprintf(stderr, "SNDStartStreaming: AudioDeviceStart returned %s\n", 
                  getCoreAudioErrorStr(CAstatus));
          r = FALSE;
      }

    }
    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  
    return r;
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStop
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStop(void)
{
    BOOL r = TRUE;
    OSStatus CAstatus;

    CAstatus = AudioDeviceStop(outputDeviceID, vendBuffersToStreamManagerIOProc);
    if (CAstatus) {
        fprintf(stderr, "SNDStreamStop: output dev stop returned %s\n", getCoreAudioErrorStr(CAstatus));
        r =  FALSE;
    }
    CAstatus = AudioDeviceStop(inputDeviceID, vendBuffersToStreamManagerIOProc);
    if (CAstatus) {
        fprintf(stderr, "SNDStreamStop: input dev stop returned %s\n", getCoreAudioErrorStr(CAstatus));
        r = FALSE;
    }
    firstSampleTime = -1.0;  
    return r;
}

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
}
#endif
