/*
  $Id$

  Description:
    Defines the C entry points to the Sound Library.

    These routines used to emulate an internal SoundKit module.
    This is intended to hide all the operating system evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C SndKit interface rather this one...do yourself a favour, 
    learn ObjC - it's simple, its fun, its better than Java..

  Original Author: Leigh M. Smith, <leigh@leighsmith.com>

  10 July 1999, Copyright (c) 1999 The MusicKit Project.

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
static unsigned int numOfDevices;
static int          bufferSizeInFrames;
static long         bufferSizeInBytes = DEFAULT_BUFFERSIZE;

static AudioStreamBasicDescription outputStreamBasicDescription;
static AudioDeviceID outputDeviceID;
static AudioHardwareIOProcStreamUsage *outputStreamIOProcUsage;
static AudioStreamBasicDescription inputStreamBasicDescription;
static AudioDeviceID inputDeviceID;
static AudioHardwareIOProcStreamUsage *inputStreamIOProcUsage;

// Stream processing data.
static SNDStreamProcessor streamProcessor;
static void          *streamUserData;
static double        firstSampleTime = -1.0; // indicates this has not been assigned.
static float         *inputBuffer = NULL;
static BOOL          isMuted = FALSE;
static NSLock        *inputLock = nil;

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
    unsigned int bufferIndex;

#if DEBUG_CALLBACK
    NSLog(@"[SND] starting vend...\n");
#endif

    if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
        NSLog(@"[SND] sample time is not valid!\n");
    }
    if(firstSampleTime == -1.0) {
        firstSampleTime = inOutputTime->mSampleTime;
    }

#if DEBUG_CALLBACK
    NSLog(@"[SND] vendOutputBuffersToStreamManagerIOProc number of buffers = input %ld, output %ld\n",
	    inInputData->mNumberBuffers, outOutputData->mNumberBuffers);    
#endif

    // The IO Proc should receive the same number of buffers as the number of AudioStreams, although only a subset
    // typically need to be filled.
    if(outOutputData->mNumberBuffers != outputStreamIOProcUsage->mNumberStreams) {
	NSLog(@"[SND] assertion outOutputData->mNumberBuffers == outputStreamIOProcUsage->mNumberStreams failed %ld, %ld\n",
	    outOutputData->mNumberBuffers, outputStreamIOProcUsage->mNumberStreams);
    }
    
    for(bufferIndex = 0; bufferIndex < outOutputData->mNumberBuffers; bufferIndex++) {
        // TODO we should alter inStream and outStream to be the buffer's number of channels.
	//        int channelsPerFrame = outOutputData->mBuffers[bufferIndex].mNumberChannels;

        // to tell the client the format it is receiving.
        if (inputInit) {
            // inInputData->mNumberBuffers can differ from inputStreamIOProcUsage->mNumberStreams, since the former describes outDevices
            // number of input buffers, whereas the latter can describe the streams on potentially a different device.
	    // TODO The whole approach of using two vending IOProcs which initiate one stream manager callback needs rethinking.
            if(bufferIndex < inInputData->mNumberBuffers && inputStreamIOProcUsage->mStreamIsOn[bufferIndex]) {
		// TODO we only copy across the first buffers data to inputBuffer.
                memcpy(inputBuffer, inInputData->mBuffers[0].mData, bufferSizeInBytes);
	    }
            else {
                inStream.streamData = NULL;
            }
        }

#if DEBUG_CALLBACK
	NSLog(@"[SND] vend middle...\n");
#endif

        if(outputStreamIOProcUsage->mStreamIsOn[bufferIndex]) {
            // to tell the client the format it should send.

	    SNDStreamNativeFormat(&outStream);
	    SNDStreamNativeFormat(&inStream);

	    inStream.streamData  = inputBuffer;
	    outStream.streamData = outOutputData->mBuffers[bufferIndex].mData;
            
	    [inputLock lock];
            
	    if (!inputInit) {
#if DEBUG_CALLBACK
		NSLog(@"[SND] vend no input initialized zeroing input buffer...\n");
#endif		
		memset(inputBuffer, 0, bufferSizeInBytes);
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
    NSLog(@"[SND] ending vend...\n");
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
    NSLog(@"[SND] starting vendInputBuffersToStreamManagerIOProc...\n");
#endif
    if (inputBuffer) {
        SNDStreamBuffer inStream; //, outStream;
        int bufferIndex;

        if(inOutputTime->mFlags & kAudioTimeStampSampleTimeValid == 0) {
            NSLog(@"sample time is not valid!\n");
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
                    memcpy(inputBuffer, inInputData->mBuffers[0].mData, bufferSizeInBytes);
                    [inputLock unlock];
                }
            }
        }
    }
    else {
#if DEBUG_CALLBACK    
        NSLog(@"[SND] input vend: input buffer is NULL!\n");
#endif
    }
    
#if DEBUG_CALLBACK    
    NSLog(@"[SND] ending vend aux...\n");
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
    unsigned int driverIndex = 0;
    AudioDeviceID *allDeviceIDs;

    CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, &propertyWritable);
    // NSLog(@"AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
    //    (char *) &CAstatus, propertySize, propertyWritable);

    if (CAstatus) {
        NSLog(@"AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    if((allDeviceIDs = (AudioDeviceID *) malloc(propertySize)) == NULL) {
        NSLog(@"Unable to malloc device ids\n");
        return FALSE;
    }

    CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, allDeviceIDs);
    // NSLog(@"AudioHardwareGetProperty kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld\n", (char *) &CAstatus, propertySize);
    if (CAstatus) {
        NSLog(@"AudioDeviceGetProperty 1 returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    numOfDevices = propertySize / sizeof(AudioDeviceID);
    // NSLog(@"numOfDevices = %d\n", numOfDevices);

    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
        NSLog(@"Unable to malloc driver list\n");
        return FALSE;
    }
    
    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
        char *deviceName;
        CAstatus = AudioDeviceGetPropertyInfo(allDeviceIDs[driverIndex], 0, false,
                                            kAudioDevicePropertyDeviceName,
                                            &propertySize, &propertyWritable);
        //NSLog(@"output device CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
        //    getCoreAudioErrorStr(CAstatus), propertySize, propertyWritable);
            
        // malloc up enough memory for the name.
        if((deviceName = (char *) malloc(propertySize * sizeof(char))) == NULL) {
            NSLog(@"Unable to malloc deviceName string\n");
            return FALSE;
        }
        
        // get the name.
        CAstatus = AudioDeviceGetProperty(allDeviceIDs[driverIndex], 0, false,
                                        kAudioDevicePropertyDeviceName,
                                        &propertySize, deviceName);
        if (CAstatus) {
            NSLog(@"AudioDeviceGetProperty 2 returned %s\n", getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }

        // NSLog(@"DevID: %p   name: %s\n", allDeviceIDs[driverIndex], deviceName);
    
        driverList[driverIndex] = deviceName;
    }

    driverList[driverIndex] = NULL; // NULL terminate the list
    return TRUE;
}


// Find the output device ID in the driver list and return the driver list index.
// TODO we make the reasonably safe assumption that the sequence of deviceIDs and 
// driver names will be in the same order.
unsigned int findDeviceIDInDriverList(AudioDeviceID deviceIDToFind)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    unsigned int driverIndex = 0;
    AudioDeviceID *allDeviceIDs;

    CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, &propertyWritable);
    // NSLog(@"AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
    //    (char *) &CAstatus, propertySize, propertyWritable);

    if (CAstatus) {
        NSLog(@"AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    if((allDeviceIDs = (AudioDeviceID *) malloc(propertySize)) == NULL) {
        NSLog(@"Unable to malloc device ids\n");
        return FALSE;
    }

    CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, allDeviceIDs);
    // NSLog(@"AudioHardwareGetProperty kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld\n", (char *) &CAstatus, propertySize);
    if (CAstatus) {
        NSLog(@"AudioDeviceGetProperty 1 returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    if(numOfDevices != propertySize / sizeof(AudioDeviceID))
        NSLog(@"findDeviceIDInDriverList assertion failed! numOfDevices = %d vs. %d\n", numOfDevices, propertySize / sizeof(AudioDeviceID));

    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
        if(allDeviceIDs[driverIndex] == deviceIDToFind)
            return driverIndex;
    }
    NSLog(@"Couldn't find the driver ID %x out of %d devices\n", deviceIDToFind, numOfDevices);
    return 0; // Couldn't find it, default to the first
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
        NSLog(@"AudioDeviceGetPropertyInfo returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
                                    kAudioDevicePropertyDeviceIsRunning,
                                    &propertySize, &running);
    if (CAstatus) {
        NSLog(@"AudioDeviceGetProperty 3 returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    return running != 0;
}

////////////////////////////////////////////////////////////////////////////////
// dumpStreamDescription
////////////////////////////////////////////////////////////////////////////////

#if DEBUG_DESCRIPTION
static void dumpStreamDescription(AudioStreamBasicDescription *StrBasDesc)
{
    NSLog(@"samplerate:       %f\nformat:           %4s\nFormatFlags:      0x%X\n",
	    StrBasDesc->mSampleRate,		            // the native sample rate of the audio stream
	    (char *) &StrBasDesc->mFormatID,		    // the specific encoding type of audio stream
	    (unsigned int) StrBasDesc->mFormatFlags);	    // flags specific to each format
    NSLog(@"bytesPerPacket:   %li\nframesPerPacket:  %li\nBytesPerFrame:    %li\n",
	    StrBasDesc->mBytesPerPacket,                      // the number of bytes in a packet
	    StrBasDesc->mFramesPerPacket,                     // the number of frames in each packet
	    StrBasDesc->mBytesPerFrame);                      // the number of bytes in a frame
    NSLog(@"ChannelsPerFrame: %li\nBitsPerChannel:   %li\n",
	    StrBasDesc->mChannelsPerFrame,                    // the number of channels in each frame
	    StrBasDesc->mBitsPerChannel);
}
#endif

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
        NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyStreamFormat: %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
				      kAudioDevicePropertyStreamFormat,
				      &propertySize, audioStreamBasicDescription);

#if DEBUG_DESCRIPTION
    NSLog(@"device ID: %d\n", (unsigned int) deviceID);
    dumpStreamDescription(audioStreamBasicDescription);
#endif

    if (CAstatus) {
        NSLog(@"AudioDeviceGetProperty kAudioDevicePropertyStreamFormat: %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    
// check to see if the sample rate is changeable...
#if 0
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyRateScalar,
                                          &propertySize, &propertyWritable);
    NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyRateScalar  CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
	    getCoreAudioErrorStr(CAstatus), propertySize, propertyWritable);
#endif

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
				    kAudioDevicePropertyDeviceName,
				    &propertySize, &propertyWritable);

    if (CAstatus) {
	NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyDeviceName: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
				kAudioDevicePropertyDeviceName,
				&propertySize, deviceName);
    if (CAstatus) {
	NSLog(@"AudioDeviceGetProperty kAudioDevicePropertyDeviceName: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
	
#if DEBUG_DESCRIPTION
    NSLog(@"Devicename: %s\n", deviceName);
#endif
    
    return TRUE;
}


// Determine which AudioStreams of the AudioDevice should be serviced by our IOProc.
// If a stream is marked as not being used, the given IOProc will see a corresponding NULL buffer
// pointer in the AudioBufferList passed to it's IO proc.
static BOOL getAudioStreamsToVend(AudioDeviceID deviceID, AudioHardwareIOProcStreamUsage **ioProcStreamUsage,
					void *ioProc, BOOL isInput)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
					  kAudioDevicePropertyIOProcStreamUsage,
					  &propertySize, &propertyWritable);
    if (CAstatus) {
	NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

    if((*ioProcStreamUsage = (AudioHardwareIOProcStreamUsage *) malloc(propertySize)) == NULL) {
        NSLog(@"Unable to malloc ioProcStreamUsage buffer of %ld\n", propertySize);
        return FALSE;
    }

    (*ioProcStreamUsage)->mIOProc = ioProc;

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput,
				      kAudioDevicePropertyIOProcStreamUsage,
				      &propertySize, *ioProcStreamUsage);
    if (CAstatus) {
	NSLog(@"AudioDeviceGetProperty kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

#if DEBUG_IOPROCUSAGE
    {
	unsigned int i;

	NSLog(@"%s (*ioProcStreamUsage)->mNumberStreams = %ld\n", isInput ? "input" : "output", 
            (*ioProcStreamUsage)->mNumberStreams);
	for(i = 0; i < (*ioProcStreamUsage)->mNumberStreams; i++) {
	    NSLog(@"(*ioProcStreamUsage)->mStreamIsOn[%d] = %ld\n", i, (*ioProcStreamUsage)->mStreamIsOn[i]);
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
	NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

#if DEBUG_IOPROCUSAGE
    {
	unsigned int i;

	NSLog(@"setting %s ioProcStreamUsage->mNumberStreams = %ld\n", 
            isInput ? "input" : "output", ioProcStreamUsage->mNumberStreams);
	for(i = 0; i < ioProcStreamUsage->mNumberStreams; i++) {
	    NSLog(@"setting ioProcStreamUsage->mStreamIsOn[%d] = %ld\n", i, ioProcStreamUsage->mStreamIsOn[i]);
	}
    }
#endif

    CAstatus = AudioDeviceSetProperty(deviceID, NULL, 0, isInput,
				      kAudioDevicePropertyIOProcStreamUsage,
				      propertySize, ioProcStreamUsage);
    if (CAstatus) {
	NSLog(@"AudioDeviceGetProperty kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
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
        NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
				      &propertySize, &currentBufferSizeInBytes);

    if (CAstatus) {
        NSLog(@"AudioDeviceGetProperty kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
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
        NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    
    /* set the buffer size of the device */
    CAstatus = AudioDeviceSetProperty(deviceID, NULL, 0, isInput,
                                    kAudioDevicePropertyBufferSize,
                                    propertySize, &bufferSizeToSetInBytes);
    if (CAstatus) {
        NSLog(@"AudioDeviceSetProperty (output) returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    /* fetch the buffer size to check */
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyBufferSize,
                                          &propertySize, &propertyWritable);
    if (CAstatus) {
        NSLog(@"AudioDeviceGetPropertyInfo (output) kAudioDevicePropertyBufferSize returned %d\n", (int) CAstatus);
        return FALSE;
    }
        
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyBufferSize,
                                    &propertySize, &bufferSizeInBytes);
    if (CAstatus) {
        NSLog(@"AudioDeviceGetProperty (output) BufferSize returned %d\n", (int) CAstatus);
        return FALSE;
    }

#if DEBUG_BUFFERSIZE // only needed for debugging
    NSLog(@"get buffer size CAstatus:%s, bufferSizeInBytes = %ld\n", getCoreAudioErrorStr(CAstatus), bufferSizeInBytes);
#endif
    
    if (bufferSizeInBytes != bufferSizeToSetInBytes) {
        NSLog(@"device did not set desired buffer size\n");
        NSLog(@"desired: %d\nactual: %d\n", (int) bufferSizeToSetInBytes,
                (int) bufferSizeInBytes);
        return FALSE;
    }
    bufferSizeInFrames = bufferSizeInBytes / outputStreamBasicDescription.mBytesPerFrame;

    return TRUE;
}

BOOL SNDSetBufferSizeInBytes(long newBufferSizeInBytes)
{
    if (isDeviceRunning(outputDeviceID, FALSE))
	return FALSE;
    bufferSizeInBytes = newBufferSizeInBytes;
    if(!setBufferSize(outputDeviceID, bufferSizeInBytes, false)) {
	NSLog(@"output device - error setting buffer size\n");
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
	    NSLog(@"SNDInit() Output: AudioHardwareGetPropertyInfo returned %s\n", getCoreAudioErrorStr(CAstatus));
	    return FALSE;
	}
	CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
				     &propertySize, &outputDeviceID);
        if (CAstatus) {
            NSLog(@"SNDInit() Output: AudioHardwareGetProperty kAudioHardwarePropertyDefaultOutputDevice returned %s\n",
                    getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }
        CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultInputDevice,
                                                &propertySize, &propertyWritable);
        if (CAstatus) {
            NSLog(@"SNDInit() Input: AudioHardwareGetPropertyInfo kAudioHardwarePropertyDefaultInputDevice returned %s\n",
		    getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }

        CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
					    &propertySize, &inputDeviceID);
        if (CAstatus) {
            NSLog(@"SNDInit() Input: AudioHardwareGetProperty kAudioHardwarePropertyDefaultInputDevice returned %s\n",
		    getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }

	// If we are guessing the device, retrieve and use the standard buffer size.
	bufferSizeInBytes = getBufferSize(outputDeviceID, NO);

#if DEBUG_BUFFERSIZE
	NSLog(@"get buffer size bufferSizeInBytes = %ld\n", bufferSizeInBytes);
#endif
        // find the default output device ID in the driver list and return its index
        driverIndex = findDeviceIDInDriverList(outputDeviceID);  
    }
    else {
        NSLog(@"SNDInit() Didn't guess the device\n");
        driverIndex = 0;
    }

#if DEBUG_DESCRIPTION
    NSLog(@"OUTPUT ===========\n");
#endif

    /* check the returned device */
    if (outputDeviceID == kAudioDeviceUnknown) {
        NSLog(@"SNDInit() outputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(!determineBasicDescription(outputDeviceID, &outputStreamBasicDescription, false)) {
        NSLog(@"SNDInit() output device - error determining basic description\n");
        return FALSE;
    }
    if(!guessTheDevice) {
	if(!setBufferSize(outputDeviceID, bufferSizeInBytes, NO)) {
	    NSLog(@"SNDInit() output device - error setting buffer size\n");
	    return FALSE;
	}
    }
    else
	bufferSizeInFrames = bufferSizeInBytes / outputStreamBasicDescription.mBytesPerFrame;


#if DEBUG_DESCRIPTION
    NSLog(@"INPUT ===========\n");
#endif

    if (inputDeviceID == kAudioDeviceUnknown) {
        NSLog(@"SNDInit() inputDeviceID is kAudioDeviceUnknown\n");
    }
    else if(!determineBasicDescription(inputDeviceID, &inputStreamBasicDescription, true)) {
        NSLog(@"SNDInit() input device - error determining basic setup\n");
    }
    else if(!setBufferSize(inputDeviceID, bufferSizeInBytes, YES)) {
        NSLog(@"SNDInit() input device - error setting buffer size\n");
    }
    else {
	inputInit = TRUE;
    }

#if CHECK_DEVICE_RUNNING_STATUS
    if(isDeviceRunning(outputDeviceID, false)) {
	NSLog(@"SNDInit() output device is already running... but this is ok in CoreAudio land\n");
    }
    if(isDeviceRunning(inputDeviceID, true)) {
	NSLog(@"SNDInit() Input device is already running... but this is ok in CoreAudio land\n");
    }
#endif

    return TRUE;
}

// Shut down what we started up in SndInit();
PERFORM_API BOOL SNDTerminate(void)
{
    // CoreAudio doesn't need an explicit call to shut down/disengage/unreserve to our app.
    return YES;
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
PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat)
{
    if (!initialised)
	SNDInit(TRUE);

    // The bytes per frame is implicitly set by the dataFormat value.
    streamFormat->dataFormat   = SND_FORMAT_FLOAT;
    /* Number of channel independent sample frames in a buffer */
    streamFormat->frameCount   = bufferSizeInFrames;
    streamFormat->sampleRate   = outputStreamBasicDescription.mSampleRate;
    streamFormat->channelCount = outputStreamBasicDescription.mChannelsPerFrame;
    // Rather than setting the stream data explicitly NULL, we just leave it.
    // streamFormat->streamData = NULL;
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
    NSLog(@"[SND] Beginning stream start...\n");
#endif    

    if(!initialised)
        return FALSE;  // invalid sound structure.

    // Even if we don't have input, we still need an input buffer to send up empty to the rest of the arch.
    if ((inputBuffer = (float*) malloc(bufferSizeInBytes)) == NULL) {
        NSLog(@"Unable to malloc input buffer of %ld\n", bufferSizeInBytes);
        return FALSE;
    }
    memset(inputBuffer, 0, bufferSizeInBytes);
    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  

    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;

    CAstatus = AudioDeviceAddIOProc(outputDeviceID, vendOutputBuffersToStreamManagerIOProc, NULL);
    if (CAstatus) {
        NSLog(@"SNDStartStreaming: AudioDeviceAddIOProc returned %s\n",
                getCoreAudioErrorStr(CAstatus));
        r = FALSE;
    }
    if(!getAudioStreamsToVend(outputDeviceID, &outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, NO))
	return FALSE;

    {
	unsigned int streamIndex;

	// TODO turn off all but the first stream. This isn't right in the general case, we should use what the
	// the user has nominated as the default AudioStream in the default AudioDevice, but there doesn't seem to be
	// a means to determine this. For now, we do what iTunes seems to do, use the first AudioStream.
	for(streamIndex = 1; streamIndex < outputStreamIOProcUsage->mNumberStreams; streamIndex++)
	    outputStreamIOProcUsage->mStreamIsOn[streamIndex] = NO;
    }

    if(!setAudioStreamsToVend(outputDeviceID, outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, NO))
	return FALSE;

    if (inputInit) {
        CAstatus = AudioDeviceAddIOProc(inputDeviceID, vendInputBuffersToStreamManagerIOProc, NULL);
        if (CAstatus) {
            NSLog(@"SNDStartStreaming: AudioDeviceAddIOProc returned %s\n",
         				getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
	if(!getAudioStreamsToVend(inputDeviceID, &inputStreamIOProcUsage, vendInputBuffersToStreamManagerIOProc, YES))
	    return FALSE;
    }
    if (r) { // all is well so far...
        CAstatus = AudioDeviceStart(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);
        if (CAstatus) {
            NSLog(@"SNDStartStreaming: AudioDeviceStart returned %s\n",
                    getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
        if (inputInit) {
            CAstatus = AudioDeviceStart(inputDeviceID, vendInputBuffersToStreamManagerIOProc);
            if (CAstatus) {
                NSLog(@"SNDStartStreaming: AudioDeviceStart returned %s\n", 
                        getCoreAudioErrorStr(CAstatus));
                r = FALSE;
            }
        }
    }
    // printf("initialised stream start %d\n", r);
#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Stream Started: %s\n", r ? "OK":"ERR");
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
            NSLog(@"SNDStreamStop: input dev stop returned %s\n", getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
    }

    CAstatus =  AudioDeviceStop(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);

#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Begining stream shutdown...\n");
#endif    
    
    if (CAstatus) {
        NSLog(@"SNDStreamStop: output dev stop returned %s\n", getCoreAudioErrorStr(CAstatus));
        r = FALSE;
    }
    firstSampleTime = -1.0;  
    if (inputInit) {
        free(inputBuffer);
        inputBuffer = NULL;
    }
#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Stream Stopped: %s\n", r ? "OK" : "ERR");
#endif    
    return r;
}

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
}
#endif
