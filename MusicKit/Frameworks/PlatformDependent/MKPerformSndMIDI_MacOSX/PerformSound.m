/*
  $Id$

  Description:
    Defines the C entry points to the Sound Library.

    These routines used to emulate an internal SoundKit module.
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

#import <Foundation/Foundation.h>
#include <CoreAudio/CoreAudio.h>
#include "PerformSound.h"

#ifdef __cplusplus
extern "C" {
#endif

#define DEBUG_SQUAREWAVE    0  // generate a square wave, rather than the real audio data
#define DEBUG_DESCRIPTION   0  // dump the description of the audio device.
#define DEBUG_BUFFERSIZE    0  // dump the check of the audio buffer size.
#define DEBUG_SNDPLAYIOPROC 0  // dump the channel count etc while generating the buffer.
#define DEBUG_STARTSTOPMSG  0  // dump stream start/stop msgs
#define DEBUG_CALLBACK      0  // dump vendOutputBuffersToStreamManagerIOProc info.
#define DEBUG_IOPROCUSAGE   0  // dump the usage of AudioStreams by IOProcs.
#define CHECK_DEVICE_RUNNING_STATUS 0   

#define DEFAULT_BUFFERSIZE 16384  // The buffer size we want if we are not guessing the device.

// "class" variables
static BOOL initialised = FALSE;
static BOOL inputInit = FALSE;

static char         **driverList;
static unsigned int driverIndex = 0;
static int          numOfDevices;
static int          bufferSizeInFrames;
static long         bufferSizeInBytes = DEFAULT_BUFFERSIZE;

static AudioStreamBasicDescription outputStreamBasicDescription;
static AudioDeviceID outputDeviceID;
static AudioHardwareIOProcStreamUsage outputStreamIOProcUsage;
static AudioStreamBasicDescription inputStreamBasicDescription;
static AudioDeviceID inputDeviceID;
static AudioHardwareIOProcStreamUsage inputStreamIOProcUsage;

// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void          *streamUserData;
static double        firstSampleTime = -1.0; // indicates this has not been assigned.
static float         *fInputBuffer = NULL;
static BOOL          isMuted = FALSE;
static NSLock        *inputLock;

////////////////////////////////////////////////////////////////////////////////
// getCoreAudioErrorString
////////////////////////////////////////////////////////////////////////////////

static char *getCoreAudioErrorStr(OSStatus status)
{
    char *r = NULL;
    
    switch (status) {
	case kAudioHardwareNotRunningError:       r = "Hardware not running error";        break;
	case kAudioHardwareUnspecifiedError:	  r = "Hardware unspecified error";        break;
	case kAudioHardwareUnknownPropertyError:  r = "Hardware unknown property error";   break;
	case kAudioDeviceUnsupportedFormatError:  r = "Hardware unsupported format error"; break;
	case kAudioHardwareBadPropertySizeError:  r = "Hardware bad property size error";  break;
	case kAudioHardwareIllegalOperationError: r = "Hardware illegal operation";        break;
	case kAudioHardwareNoError:               r = "none";                              break;
	default:                                  r = "unknown";
    }
    return r;
}

////////////////////////////////////////////////////////////////////////////////
// vendOutputBuffersToStreamManagerIOProc
//
// We vend the output and input buffers in their native format to avoid 
// redundant conversions. This allows postponing the conversion to the last 
// possible moment. The SndConvertFormat() function in the SndKit makes for an 
// easy way to do the conversion without anyone writing their own converter.
// For CoreAudio, it's native format is floating point (the conversion to a
// resolution is done in the driver).
//
// IOProc's receive all AudioBuffers (as the AudioBufferLists inInputData and outOutputData)
// of all AudioStreams of an AudioDevice. We should only fulfill those AudioBuffers
// that apply for AudioStreams that have been specifically opened by us.
//
////////////////////////////////////////////////////////////////////////////////

static OSStatus vendOutputBuffersToStreamManagerIOProc(AudioDeviceID outDevice,
						       const AudioTimeStamp *inNow,
						       const AudioBufferList *inInputData,
						       const AudioTimeStamp *inInputTime,
						       AudioBufferList *outOutputData,
						       const AudioTimeStamp *inOutputTime,
						       void *inClientData)
{
    SNDStreamBuffer inStream, outStream;
    int bufferIndex;

#if DEBUG_CALLBACK
    fprintf(stderr,"[SND] starting vend...\n");
#endif

    if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
        fprintf(stderr, "sample time is not valid!\n");
    }
    if(firstSampleTime == -1.0) {
        firstSampleTime = inOutputTime->mSampleTime;
    }

#if DEBUG_CALLBACK
    fprintf(stderr, "vendOutputBuffersToStreamManagerIOProc number of buffers = input %ld, output %ld\n",
	    inInputData->mNumberBuffers, outOutputData->mNumberBuffers);    
#endif

    // The IO Proc should receive the same number of buffers as the number of AudioStreams, although only a subset
    // typically need to be filled.
    if(outOutputData->mNumberBuffers != outputStreamIOProcUsage.mNumberStreams) {
	fprintf(stderr, "assertion outOutputData->mNumberBuffers == outputStreamIOProcUsage.mNumberStreams failed %ld, %ld\n",
	    outOutputData->mNumberBuffers, outputStreamIOProcUsage.mNumberStreams);
    }
    
    for(bufferIndex = 0; bufferIndex < outOutputData->mNumberBuffers; bufferIndex++) {
        // TODO we should alter inStream and outStream to be the buffer's number of channels.
	//        int channelsPerFrame = outOutputData->mBuffers[bufferIndex].mNumberChannels;

        // to tell the client the format it is receiving.
        if (inputInit) {
            // inInputData->mNumberBuffers can differ from inputStreamIOProcUsage.mNumberStreams, since the former describes outDevices
            // number of input buffers, whereas the latter can describe the streams on potentially a different device.
	    // TODO The whole approach of using two vending IOProcs which initiate one stream manager callback needs rethinking.
            if(bufferIndex < inInputData->mNumberBuffers && inputStreamIOProcUsage.mStreamIsOn[bufferIndex]) {
		// TODO we only copy across the first buffers data to fInputBuffer.
                memcpy(fInputBuffer, inInputData->mBuffers[0].mData, bufferSizeInBytes);
	    }
            else {
                inStream.streamData = NULL;
            }
        }

#if DEBUG_CALLBACK
	fprintf(stderr,"[SND] vend middle...\n");
#endif

        if(outputStreamIOProcUsage.mStreamIsOn[bufferIndex]) {
            // to tell the client the format it should send.

	    SNDStreamNativeFormat(&outStream.streamFormat);
	    SNDStreamNativeFormat(&inStream.streamFormat);

	    inStream.streamData  = fInputBuffer;
	    outStream.streamData = outOutputData->mBuffers[bufferIndex].mData;

	    [inputLock lock];

	    if (!inputInit) {
#if DEBUG_CALLBACK
		fprintf(stderr,"[SND] vend no input initialized zeroing input buffer...\n");
#endif		
		memset(fInputBuffer, 0, bufferSizeInBytes);
	    }

	    // hand over the stream buffers to the processor/stream manager.
	    // the output time goes out as a relative time, noted from the
	    // first sample time we first receive.

	    (*streamProcessor)(inOutputTime->mSampleTime - firstSampleTime,
			&inStream, &outStream, streamUserData);

	    [inputLock unlock];

	    if (isMuted) {
		memset(outStream.streamData, 0, bufferSizeInBytes);
	    }
        }
        else {
	    outStream.streamData = NULL;
	}
    }
#if DEBUG_CALLBACK
    fprintf(stderr,"[SND] ending vend...\n");
#endif

    return 0; // TODO need better definition...
}

// TODO This is only retrieving the audio buffer from the CoreAudio API, it does not hand the buffer
// onto the streamProcessor() function within the SndKit, that is done in vendOutputBuffersToStreamManagerIOProc.
static OSStatus vendInputBuffersToStreamManagerIOProc(AudioDeviceID inDevice,
                          const AudioTimeStamp *inNow,
                          const AudioBufferList *inInputData,
                          const AudioTimeStamp *inInputTime,
                          AudioBufferList *outOutputData,
                          const AudioTimeStamp *inOutputTime,
                          void *inClientData)
{
    
#if DEBUG_CALLBACK    
    fprintf(stderr,"[SND] starting vendInputBuffersToStreamManagerIOProc...\n");
#endif
    if (fInputBuffer) {
      SNDStreamBuffer inStream; //, outStream;
      int bufferIndex;

      if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
        fprintf(stderr, "sample time is not valid!\n");
      }
      if(firstSampleTime == -1.0) {
        firstSampleTime = inOutputTime->mSampleTime;
      }

      for(bufferIndex = 0; bufferIndex < 1 /* outOutputData->mNumberBuffers */ ; bufferIndex++) {
        if (inputInit) {
            if (inInputData->mNumberBuffers == 0)
                inStream.streamData = NULL;
            else {
                [inputLock lock];
                memcpy(fInputBuffer, inInputData->mBuffers[0].mData, bufferSizeInBytes);
                [inputLock unlock];
            }
        }
      }
    }
    else {
#if DEBUG_CALLBACK    
      fprintf(stderr,"[SND] input vend: input buffer is NULL!\n");
#endif
    }
    
#if DEBUG_CALLBACK    
    fprintf(stderr,"[SND] ending vend aux...\n");
#endif
    
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

    CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, &propertyWritable);
    // fprintf(stderr, "AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
    //    (char *) &CAstatus, propertySize, propertyWritable);

    if (CAstatus) {
        fprintf(stderr, "AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    allDeviceIDs = (AudioDeviceID *) malloc(propertySize);

    CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, allDeviceIDs);
    // fprintf(stderr, "AudioHardwareGetProperty kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld\n", (char *) &CAstatus, propertySize);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty 1 returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    numOfDevices = propertySize / sizeof(AudioDeviceID);
    // fprintf(stderr, "numOfDevices = %d\n", numOfDevices);

    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
        fprintf(stderr, "Unable to malloc driver list\n");
        return FALSE;
    }
    
    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
        char *deviceName;
        CAstatus = AudioDeviceGetPropertyInfo(allDeviceIDs[driverIndex], 0, false,
                                            kAudioDevicePropertyDeviceName,
                                            &propertySize, &propertyWritable);
        //fprintf(stderr, "output device CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
        //    getCoreAudioErrorStr(CAstatus), propertySize, propertyWritable);
            
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

        // fprintf(stderr,"DevID: %p   name: %s\n", allDeviceIDs[driverIndex], deviceName);
    
        driverList[driverIndex] = deviceName;
    }

    driverList[driverIndex] = NULL; // NULL terminate the list
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// isDeviceRunning
////////////////////////////////////////////////////////////////////////////////

static BOOL isDeviceRunning(AudioDeviceID deviceID, BOOL isInput)
{
    UInt32 running = 0;
    OSStatus CAstatus = 0;
    UInt32 propertySize = 0;
    Boolean propertyWritable = 0;

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

static void dumpStreamDescription(AudioStreamBasicDescription *StrBasDesc)
{
    fprintf(stderr,"samplerate:       %f\nformat:           %4s\nFormatFlags:      0x%X\n",
	    StrBasDesc->mSampleRate,		            // the native sample rate of the audio stream
	    (char *) &StrBasDesc->mFormatID,		    // the specific encoding type of audio stream
	    (unsigned int) StrBasDesc->mFormatFlags);	    // flags specific to each format
    fprintf(stderr,"bytesPerPacket:   %li\nframesPerPacket:  %li\nBytesPerFrame:    %li\n",
	    StrBasDesc->mBytesPerPacket,                      // the number of bytes in a packet
	    StrBasDesc->mFramesPerPacket,                     // the number of frames in each packet
	    StrBasDesc->mBytesPerFrame);                      // the number of bytes in a frame
    fprintf(stderr,"ChannelsPerFrame: %li\nBitsPerChannel:   %li\n",
	    StrBasDesc->mChannelsPerFrame,                    // the number of channels in each frame
	    StrBasDesc->mBitsPerChannel);
}

////////////////////////////////////////////////////////////////////////////////
// determineBasicDescription
//
// We use some of the fields for filling buffers.
////////////////////////////////////////////////////////////////////////////////

static BOOL determineBasicDescription(AudioDeviceID deviceID,
                                      AudioStreamBasicDescription *audioStreamBasicDescription,
                                      BOOL isInput)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    char    deviceName[1024];

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyStreamFormat,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyStreamFormat: %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
				      kAudioDevicePropertyStreamFormat,
				      &propertySize, audioStreamBasicDescription);

#if DEBUG_DESCRIPTION
    fprintf(stderr, "device ID: %d\n", (unsigned int) deviceID);
    dumpStreamDescription(audioStreamBasicDescription);
#endif

    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty kAudioDevicePropertyStreamFormat: %s\n", getCoreAudioErrorStr(CAstatus));
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

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
				    kAudioDevicePropertyDeviceName,
				    &propertySize, &propertyWritable);

    if (CAstatus) {
	fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyDeviceName: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
				kAudioDevicePropertyDeviceName,
				&propertySize, deviceName);
    if (CAstatus) {
	fprintf(stderr, "AudioDeviceGetProperty kAudioDevicePropertyDeviceName: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
	
#if DEBUG_DESCRIPTION
    fprintf(stderr, "Devicename: %s\n", deviceName);
#endif
    
    return TRUE;
}


// Determine which AudioStreams of the AudioDevice should be serviced by our IOProc.
// If a stream is marked as not being used, the given IOProc will see a corresponding NULL buffer
// pointer in the AudioBufferList passed to it's IO proc.
static BOOL getAudioStreamsToVend(AudioDeviceID deviceID, AudioHardwareIOProcStreamUsage *ioProcStreamUsage,
					void *ioProc, BOOL isInput)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
					  kAudioDevicePropertyIOProcStreamUsage,
					  &propertySize, &propertyWritable);
    if (CAstatus) {
	fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

    ioProcStreamUsage->mIOProc = ioProc;

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
				      kAudioDevicePropertyIOProcStreamUsage,
				      &propertySize, ioProcStreamUsage);
    if (CAstatus) {
	fprintf(stderr, "AudioDeviceGetProperty kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

#if DEBUG_IOPROCUSAGE
    {
	int i;

	fprintf(stderr, "ioProcStreamUsage->mNumberStreams = %ld\n", ioProcStreamUsage->mNumberStreams);
	for(i = 0; i < ioProcStreamUsage->mNumberStreams; i++) {
	    fprintf(stderr, "ioProcStreamUsage->mStreamIsOn[%d] = %ld\n", i, ioProcStreamUsage->mStreamIsOn[i]);
	}
    }
#endif
    
    return TRUE;
}

// Set which AudioStreams of the AudioDevice should be serviced by our IOProc.
// If a stream is marked as not being used, the given IOProc will see a corresponding NULL buffer
// pointer in the AudioBufferList passed to it's IO proc.
static BOOL setAudioStreamsToVend(AudioDeviceID deviceID, AudioHardwareIOProcStreamUsage *ioProcStreamUsage,
				  void *ioProc, BOOL isInput)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
					  kAudioDevicePropertyIOProcStreamUsage,
					  &propertySize, &propertyWritable);
    if (CAstatus) {
	fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

#if DEBUG_IOPROCUSAGE
    {
	int i;

	fprintf(stderr, "setting ioProcStreamUsage->mNumberStreams = %ld\n", ioProcStreamUsage->mNumberStreams);
	for(i = 0; i < ioProcStreamUsage->mNumberStreams; i++) {
	    fprintf(stderr, "setting ioProcStreamUsage->mStreamIsOn[%d] = %ld\n", i, ioProcStreamUsage->mStreamIsOn[i]);
	}
    }
#endif

    CAstatus = AudioDeviceSetProperty(deviceID, NULL, 0, isInput,
				      kAudioDevicePropertyIOProcStreamUsage,
				      propertySize, ioProcStreamUsage);
    if (CAstatus) {
	fprintf(stderr, "AudioDeviceGetProperty kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }


    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// getBufferSize
////////////////////////////////////////////////////////////////////////////////

static long getBufferSize(AudioDeviceID deviceID,
			  BOOL isInput)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    long currentBufferSizeInBytes;

    /* fetch the buffer size for informational purposes */
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
				      &propertySize, &currentBufferSizeInBytes);

    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetProperty kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    
    return currentBufferSizeInBytes;
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

    /* fetch the buffer size for informational purposes */
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        fprintf(stderr, "AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    
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

BOOL SNDSetBufferSizeInBytes(long liBufferSizeInBytes)
{
    if (isDeviceRunning(outputDeviceID, FALSE))
	return FALSE;
    bufferSizeInBytes = liBufferSizeInBytes;
    if(!setBufferSize(outputDeviceID, bufferSizeInBytes, false)) {
	fprintf(stderr, "output device - error setting buffer size\n");
	return FALSE;
    }
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

    if(!retrieveDriverList())
        return FALSE;

    if(!initialised) {
        initialised = TRUE;                   // SNDSetDriverIndex() needs to think we're initialised.
        inputLock   = [[NSLock alloc] init];
    }

    /* initialize CoreAudio device */
    if(guessTheDevice) {
        /* Get the default sound output device */
        CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultOutputDevice,
                                                &propertySize, &propertyWritable);
	if (CAstatus) {
	    fprintf(stderr, "SNDInit() Output: AudioHardwareGetPropertyInfo returned %s\n", getCoreAudioErrorStr(CAstatus));
	    return FALSE;
	}
	CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
				     &propertySize, &outputDeviceID);
        if (CAstatus) {
            fprintf(stderr, "SNDInit() Output: AudioHardwareGetProperty kAudioHardwarePropertyDefaultOutputDevice returned %s\n",
                    getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }
        CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultInputDevice,
                                                &propertySize, &propertyWritable);
        if (CAstatus) {
            fprintf(stderr, "SNDInit() Input: AudioHardwareGetPropertyInfo kAudioHardwarePropertyDefaultInputDevice returned %s\n",
		    getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }

        CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
					    &propertySize, &inputDeviceID);
        if (CAstatus) {
            fprintf(stderr, "SNDInit() Input: AudioHardwareGetProperty kAudioHardwarePropertyDefaultInputDevice returned %s\n",
		    getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }

	// If we are guessing the device, retrieve and use the standard buffer size.
	bufferSizeInBytes = getBufferSize(outputDeviceID, NO);

#if DEBUG_BUFFERSIZE
	fprintf(stderr, "get buffer size bufferSizeInBytes = %ld\n", bufferSizeInBytes);
#endif
        driverIndex = 0;  // TODO must find the default output device ID in the driver list and return its index
    }
    else {
        fprintf(stderr, "SNDInit() Didn't guess the device\n");
        driverIndex = 0;
    }

#if DEBUG_DESCRIPTION
    fprintf(stderr,"OUTPUT ===========\n");
#endif

    /* check the returned device */
    if (outputDeviceID == kAudioDeviceUnknown) {
        fprintf(stderr, "SNDInit() outputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(!determineBasicDescription(outputDeviceID, &outputStreamBasicDescription, false)) {
        fprintf(stderr, "SNDInit() output device - error determining basic description\n");
        return FALSE;
    }
    if(!guessTheDevice) {
	if(!setBufferSize(outputDeviceID, bufferSizeInBytes, NO)) {
	    fprintf(stderr, "SNDInit() output device - error setting buffer size\n");
	    return FALSE;
	}
    }
    else
	bufferSizeInFrames = bufferSizeInBytes / outputStreamBasicDescription.mBytesPerFrame;


#if DEBUG_DESCRIPTION
    fprintf(stderr,"INPUT ===========\n");
#endif

    if (inputDeviceID == kAudioDeviceUnknown) {
        fprintf(stderr, "SNDInit() inputDeviceID is kAudioDeviceUnknown\n");
    }
    else if(!determineBasicDescription(inputDeviceID, &inputStreamBasicDescription, true)) {
        fprintf(stderr, "SNDInit() input device - error determining basic setup\n");
    }
    else if(!setBufferSize(inputDeviceID, bufferSizeInBytes, YES)) {
        fprintf(stderr, "SNDInit() input device - error setting buffer size\n");
    }
    else {
	inputInit = TRUE;
    }

#if CHECK_DEVICE_RUNNING_STATUS
    if(isDeviceRunning(outputDeviceID, false)) {
	fprintf(stderr, "SNDInit() output device is already running... but this is ok in CoreAudio land\n");
    }
    if(isDeviceRunning(inputDeviceID, true)) {
	fprintf(stderr, "SNDInit() Input device is already running... but this is ok in CoreAudio land\n");
    }
#endif

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
// SndStreamNativeFormat
////////////////////////////////////////////////////////////////////////////////

// Return in a NULL stream buffer the format of the sound data preferred by
// the operating system. For CoreAudio, we use the basicDescription.
// TODO PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat)
PERFORM_API void SNDStreamNativeFormat(SndSoundStruct *streamFormat)
{
    if (!initialised)
	SNDInit(TRUE);

    streamFormat->magic        = SND_MAGIC;
    streamFormat->dataLocation = 0;   /* Offset or pointer to the raw data */
    /* Number of bytes of data in a buffer */
    streamFormat->dataSize     = bufferSizeInFrames * outputStreamBasicDescription.mBytesPerFrame;
    streamFormat->dataFormat   = SND_FORMAT_FLOAT;
    streamFormat->samplingRate = outputStreamBasicDescription.mSampleRate;
    streamFormat->channelCount = outputStreamBasicDescription.mChannelsPerFrame;
    streamFormat->info[0]      = '\0';
    
    // The bytes per frame is implicitly set by the dataFormat value.
    //streamFormat->dataFormat = SND_FORMAT_FLOAT;
    //streamFormat->frameCount = bufferSizeInFrames;
    //streamFormat->sampleRate = outputStreamBasicDescription.mSampleRate;
    //streamFormat->channelCount = outputStreamBasicDescription.mChannelsPerFrame;
    //streamFormat->streamData = NULL;
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
    
#if DEBUG_STARTSTOPMSG    
    fprintf(stderr,"[SND] Beginning stream start...\n");
#endif    

    if(!initialised)
        return FALSE;  // invalid sound structure.

    // Even if we don't have input, we still need an input buffer to send up empty to the rest of the arch.
    if ((fInputBuffer = (float*) malloc(bufferSizeInBytes)) == NULL)
        return FALSE;
    memset(fInputBuffer, 0, bufferSizeInBytes);
    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  

    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;
    
    CAstatus = AudioDeviceAddIOProc(outputDeviceID, vendOutputBuffersToStreamManagerIOProc, NULL);
    if (CAstatus) {
        fprintf(stderr, "SNDStartStreaming: AudioDeviceAddIOProc returned %s\n",
                getCoreAudioErrorStr(CAstatus));
        r = FALSE;
    }
    if(!getAudioStreamsToVend(outputDeviceID, &outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, NO))
	return FALSE;

    {
	int streamIndex;

	// TODO turn off all but the first stream. This isn't right in the general case, we should use what the
	// the user has nominated as the default AudioStream in the default AudioDevice, but there doesn't seem to be
	// a means to determine this. For now, we do what iTunes seems to do, use the first AudioStream.
	for(streamIndex = 1; streamIndex < outputStreamIOProcUsage.mNumberStreams; streamIndex++)
	    outputStreamIOProcUsage.mStreamIsOn[streamIndex] = NO;
    }

    if(!setAudioStreamsToVend(outputDeviceID, &outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, NO))
	return FALSE;

    if (inputInit) {
        CAstatus = AudioDeviceAddIOProc(inputDeviceID, vendInputBuffersToStreamManagerIOProc, NULL);
        if (CAstatus) {
            fprintf(stderr, "SNDStartStreaming: AudioDeviceAddIOProc returned %s\n",
         				getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
	if(!getAudioStreamsToVend(inputDeviceID, &inputStreamIOProcUsage, vendInputBuffersToStreamManagerIOProc, YES))
	    return FALSE;
    }
    if (r) { // all is well so far...
        CAstatus = AudioDeviceStart(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);
        if (CAstatus) {
            fprintf(stderr, "SNDStartStreaming: AudioDeviceStart returned %s\n",
                    getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
        if (inputInit) {
            CAstatus = AudioDeviceStart(inputDeviceID, vendInputBuffersToStreamManagerIOProc);
            if (CAstatus) {
                fprintf(stderr, "SNDStartStreaming: AudioDeviceStart returned %s\n", 
                        getCoreAudioErrorStr(CAstatus));
                r = FALSE;
            }
        }
    }
    // printf("initialised stream start %d\n", r);
#if DEBUG_STARTSTOPMSG    
    fprintf(stderr,"[SND] Stream Started: %s\n", r ? "OK":"ERR");
#endif
    return r;
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStop
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStop(void)
{
    BOOL r = TRUE;
    OSStatus CAstatus = 0;

    // Must close input first !
    if (inputInit) {
        CAstatus = AudioDeviceStop(inputDeviceID, vendOutputBuffersToStreamManagerIOProc);
        if (CAstatus) {
            fprintf(stderr, "SNDStreamStop: input dev stop returned %s\n", getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
    }

    CAstatus =  AudioDeviceStop(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);

#if DEBUG_STARTSTOPMSG    
    fprintf(stderr,"[SND] Begining stream shutdown...\n");
#endif    
    
    if (CAstatus) {
        fprintf(stderr, "SNDStreamStop: output dev stop returned %s\n", getCoreAudioErrorStr(CAstatus));
        r =  FALSE;
    }
    firstSampleTime = -1.0;  
    if (inputInit) {
        free(fInputBuffer);
        fInputBuffer = NULL;
    }
#if DEBUG_STARTSTOPMSG    
    fprintf(stderr,"[SND] Stream Stopped: %s\n", r ? "OK" : "ERR");
#endif    
    return r;
}

////////////////////////////////////////////////////////////////////////////////

#if !MKPERFORMSND_USE_STREAMING

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

static SNDPlayingSound singlePlayingSound;

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

		    ((float *)outputBuffer)[sampleToPlay] = !isMuted ? sampleWord / 32768.0f : 0.0f;

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
#endif


////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
}
#endif
