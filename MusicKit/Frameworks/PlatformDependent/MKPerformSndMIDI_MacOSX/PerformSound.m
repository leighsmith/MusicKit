/*
  $Id$

  Description:
    Defines the C entry points to the Sound Library.

    These routines used to emulate an internal SoundKit module.
    This is intended to hide all the operating system evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C SndKit interface rather this one.

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

#define DEBUG_DESCRIPTION     0  // dump the description of the audio device.
#define DEBUG_BUFFERSIZE      0  // dump the check of the audio buffer size.
#define DEBUG_STARTSTOPMSG    0  // dump stream start/stop msgs
#define DEBUG_OUTPUT_CALLBACK 0  // dump vendOutputBuffersToStreamManagerIOProc info for output.
#define DEBUG_INPUT_CALLBACK  0  // dump vendOutputBuffersToStreamManagerIOProc info for input.
#define DEBUG_IOPROCUSAGE     0  // dump the usage of AudioStreams by IOProcs.

#define CHECK_DEVICE_RUNNING_STATUS 0   

#define DEFAULT_BUFFERSIZE 16384  // The buffer size we want if we are not guessing the device.

// "class" variables
static BOOL initialised = FALSE;
static BOOL inputInit = FALSE;

static char         **speakerConfigurationList;
static unsigned int outputDriverIndex = 0;
static unsigned int inputDriverIndex = 0;

// TODO should probably become a structure.
static int  outputBufferSizeInFrames;
static long outputBufferSizeInBytes = DEFAULT_BUFFERSIZE;
static AudioStreamBasicDescription outputStreamBasicDescription;
static AudioDeviceID outputDeviceID;
static AudioHardwareIOProcStreamUsage *outputStreamIOProcUsage;
static BOOL outputInterleavedChannels = TRUE;
static int outputNumberOfStreams = 0;
#if defined(MAC_OS_X_VERSION_10_5) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
static AudioDeviceIOProcID outputDeviceProcID;
#endif

static int  inputBufferSizeInFrames;
static long inputBufferSizeInBytes = DEFAULT_BUFFERSIZE;
static AudioStreamBasicDescription inputStreamBasicDescription;
static AudioDeviceID inputDeviceID;
static AudioHardwareIOProcStreamUsage *inputStreamIOProcUsage;
static BOOL inputInterleavedChannels = TRUE;
static int inputNumberOfStreams = 0;
#if defined(MAC_OS_X_VERSION_10_5) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
static AudioDeviceIOProcID inputDeviceProcID;
#endif

// Stream processing data.
static SNDStreamProcessor streamProcessor = NULL;
static void   *streamUserData;
static double firstSampleTime = -1.0; // indicates this has not been assigned.
static float  *inputBuffer = NULL;
static BOOL   isMuted = FALSE;
static NSLock *inputLock = nil;

////////////////////////////////////////////////////////////////////////////////
// getCoreAudioErrorString
////////////////////////////////////////////////////////////////////////////////

static char *getCoreAudioErrorStr(OSStatus status)
{
    char *errorMessage = NULL;
    
    switch (status) {
	case kAudioHardwareNotRunningError:       errorMessage = "Hardware not running error";        break;
	case kAudioHardwareUnspecifiedError:	  errorMessage = "Hardware unspecified error";        break;
	case kAudioHardwareUnknownPropertyError:  errorMessage = "Hardware unknown property error";   break;
	case kAudioDeviceUnsupportedFormatError:  errorMessage = "Hardware unsupported format error"; break;
	case kAudioHardwareBadPropertySizeError:  errorMessage = "Hardware bad property size error";  break;
	case kAudioHardwareIllegalOperationError: errorMessage = "Hardware illegal operation";        break;
	case kAudioHardwareNoError:               errorMessage = "none";                              break;
	default:                                  errorMessage = "unknown";
    }
    return errorMessage;
}

// General routine to retrieve a device property, performing error checking.
static BOOL getDeviceProperty(AudioObjectID deviceID, BOOL forOutputDevice, AudioObjectPropertySelector propertyType, void *buffer, int maxBufferSize)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    AudioObjectPropertyAddress devicePropertyAddress;

    // NSLog(@"getDeviceProperty of \'%4.4s\'\n", (char *) (&propertyType));    

    // AudioObjectPropertySelector values that apply to AudioDevice objects.
    // AudioDevices have four scopes: kAudioDevicePropertyScopeGlobal,
    // kAudioDevicePropertyScopeInput, kAudioDevicePropertyScopeOutput and
    // kAudioDevicePropertyScopePlayThrough. They have a master element and an element
    // for each channel in each stream numbered according to the starting channel number of each stream.
	
    // The property selector specifies the general classification of the property such as volume, stream format, latency, etc. 
    // Note that each class has a different set of selectors. A subclass inherits it's super class's set of selectors, although 
    // it may not implement them all.
    devicePropertyAddress.mSelector = propertyType;
    devicePropertyAddress.mScope = forOutputDevice ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    devicePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    CAstatus = AudioObjectGetPropertyDataSize(deviceID, &devicePropertyAddress, 0, NULL, &propertySize);
    if (CAstatus) {
        NSLog(@"getDeviceProperty AudioObjectGetPropertyDataSize for property \'%4.4s\': %s\n", (char *) (&propertyType), getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    if(propertySize > maxBufferSize) {
        NSLog(@"getDeviceProperty property \'%4.4s\': size %d larger than available buffer size %d\n",
            (char *) (&propertyType), propertySize, maxBufferSize);
        return FALSE;
    }
    
    CAstatus = AudioObjectGetPropertyData(deviceID, &devicePropertyAddress, 0, NULL, &propertySize, buffer);
    if (CAstatus) {
        NSLog(@"getDeviceProperty AudioObjectGetPropertyData \'%4.4s\': %s\n", (char *) (&propertyType), getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    return TRUE;
}

// TODO this should be a good candidate for altivec using vec_perm, except that when deinterleaving
// streams beyond two channels, the increment across the sample frame exceeds the vector size.
// This means that for deinterleaving greater than two channel (e.g quad, 5.1) buffers, only two samples per channel
// could be deinterleaved per iteration. This then requires a lot of work to compute the permutation
// vector, particularly if there are other than a dyadic (power of 2) number of channels, such as 5.1. In that case,
// we need to check at each iteration which permutation vector to choose and which two data vectors to choose.
// This takes a lot of code for at best a factor of two increase in speed (assuming cost of scalar addition
// equals vec_perm memory store). For now I'm sacrificing speed for clarity.
static void deinterleaveChannel(int channel, int channelCount, float *fromStream, float *toStream, unsigned int frameCount)
{
    unsigned int frameIndex;
    unsigned int sampleIndex = channel;

    for(frameIndex = 0; frameIndex < frameCount; frameIndex++) {	
	toStream[frameIndex] = fromStream[sampleIndex];
	sampleIndex += channelCount;
    }    
}

// Almost identical to deinterleaving, just differs in the indices used for reading and writing. So we could parameterise this into a single function.
static void interleaveChannel(int channel, int channelCount, float *fromStream, float *toStream, unsigned int frameCount)
{
    unsigned int frameIndex;
    unsigned int sampleIndex = channel;
    
    for(frameIndex = 0; frameIndex < frameCount; frameIndex++) {
	toStream[sampleIndex] = fromStream[frameIndex];
	// NSLog(@"storing to [%d] = %f, from [%d] = %f", sampleIndex, toStream[sampleIndex], frameIndex, fromStream[frameIndex]);
	sampleIndex += channelCount;
    }    
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
    unsigned int interleavedStreamIndex;

#if DEBUG_OUTPUT_CALLBACK
    NSLog(@"[vendOutputBuffersToStreamManagerIOProc] starting vend...\n");
#endif

    if(inOutputTime->mFlags & kAudioTimeStampHostTimeValid == 0) {
        NSLog(@"[vendOutputBuffersToStreamManagerIOProc] host time is not valid!\n");
    } 
    else if(firstSampleTime == -1.0) {
        firstSampleTime = AudioConvertHostTimeToNanos(inOutputTime->mHostTime);
    }

#if DEBUG_OUTPUT_CALLBACK
    NSLog(@"[vendOutputBuffersToStreamManagerIOProc] number of buffers = input %ld, output %ld\n",
	    inInputData->mNumberBuffers, outOutputData->mNumberBuffers);    
#endif

    // The IO Proc should receive the same number of buffers as the number of AudioStreams, although only a subset
    // typically need to be filled.
    if(outOutputData->mNumberBuffers != outputStreamIOProcUsage->mNumberStreams) {
	NSLog(@"[vendOutputBuffersToStreamManagerIOProc] assertion outOutputData->mNumberBuffers (%ld) == outputStreamIOProcUsage->mNumberStreams (%ld) failed\n",
	    outOutputData->mNumberBuffers, outputStreamIOProcUsage->mNumberStreams);
    }
    
    // TODO we need to determine if the streams are themselves interleaved and if so iterate through them.
    interleavedStreamIndex = 0; 
    // for(interleavedStreamIndex = 0; interleavedStreamIndex < outputStreamIOProcUsage->mNumberStreams; interleavedStreamIndex++) 
    {
	// to tell the client the format it should send.
	SNDStreamNativeFormat(&outStream, TRUE);
	SNDStreamNativeFormat(&inStream, FALSE);
	
	if(outputStreamIOProcUsage->mStreamIsOn[interleavedStreamIndex]) {
	    if(outputInterleavedChannels)
		outStream.streamData = outOutputData->mBuffers[interleavedStreamIndex].mData;
	    else
		// If we must pass non-interleaved streams to CoreAudio, we need memory to receive the always interleaved streams from the
		// SndStreamManager. We calloc this to ensure it is zero in case the streamProcessor does nothing with it.
		outStream.streamData = calloc(outStream.frameCount * outStream.channelCount, sizeof(float));	
	}
	else {
	    outStream.streamData = NULL;
	}
	
	[inputLock lock];
	
	// to tell the client the format it is receiving.
	if (!inputInit) {
#if DEBUG_OUTPUT_CALLBACK
	    NSLog(@"[vendOutputBuffersToStreamManagerIOProc] no input initialized, zeroing input buffer...\n");
#endif		
	    memset(inputBuffer, 0, inputBufferSizeInBytes);
	}
	//NSLog(@"inStream dataFormat %d frameCount %ld channelCount %d sampleRate %lf\n",
	//      inStream.dataFormat, inStream.frameCount, inStream.channelCount, inStream.sampleRate);
	      
	// TODO The whole approach of using two vending IOProcs which initiate one stream manager callback may need 
	// rethinking so that there are two stream manager callbacks.
	inStream.streamData = inputStreamIOProcUsage->mStreamIsOn[0] ? inputBuffer : NULL;
	
	// hand over the stream buffers to the processor/stream manager.
	// the output time goes out as a relative time in seconds, with a datum from the
	// first sample time we first receive.
	// TODO perhaps inOutputTime->mSampleTime - firstSampleTime would work
	// TODO or (inOutputTime->mSampleTime - firstSampleTime) / sampleRate
	(*streamProcessor)((AudioConvertHostTimeToNanos(inOutputTime->mHostTime) - firstSampleTime) / 1.0e9,
			   &inStream, &outStream, streamUserData);
	
	[inputLock unlock];
	
	// If the hardware only accepts non-interleaved buffers, deinterleave the SndStreamManager generated buffer into each output stream.
	if(!outputInterleavedChannels) {
	    unsigned int bufferIndex;

	    for(bufferIndex = 0; bufferIndex < outOutputData->mNumberBuffers; bufferIndex++) {
		if (isMuted) {
		    memset(outOutputData->mBuffers[bufferIndex].mData, 0, outputBufferSizeInBytes);
		}
		else {
#if DEBUG_OUTPUT_CALLBACK
		    NSLog(@"[vendOutputBuffersToStreamManagerIOProc] deinterleaving to buffer[%d] channels = %d\n", bufferIndex, outOutputData->mBuffers[bufferIndex].mNumberChannels);
		    NSLog(@"[vendOutputBuffersToStreamManagerIOProc] stream is on = %d\n", outputStreamIOProcUsage->mStreamIsOn[bufferIndex]);
#endif	    		
		    deinterleaveChannel(bufferIndex, 
					outStream.channelCount, 
					(float *) outStream.streamData, 
					(float *) outOutputData->mBuffers[bufferIndex].mData,
					outStream.frameCount);
		}
	    }
	    free(outStream.streamData);
	}
	else {
	    if (isMuted) {
		memset(outOutputData->mBuffers[interleavedStreamIndex].mData, 0, outputBufferSizeInBytes);
	    }	
	}
    }
    
#if DEBUG_OUTPUT_CALLBACK
    NSLog(@"[vendOutputBuffersToStreamManagerIOProc] ending vend...\n");
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
    
#if DEBUG_INPUT_CALLBACK    
    NSLog(@"[SND] starting vendInputBuffersToStreamManagerIOProc...\n");
#endif
    if (inputBuffer) {
        int bufferIndex;
	SNDStreamBuffer inStream;
	
	SNDStreamNativeFormat(&inStream, FALSE);
	
        if(inOutputTime->mFlags & kAudioTimeStampHostTimeValid == 0) {
            NSLog(@"sample time is not valid!\n");
        }
        else if(firstSampleTime == -1.0) {
	    firstSampleTime = AudioConvertHostTimeToNanos(inOutputTime->mHostTime);
        }

        for(bufferIndex = 0; bufferIndex < inInputData->mNumberBuffers; bufferIndex++) {
            if (inputInit && inInputData->mNumberBuffers != 0) {
		[inputLock lock];
#if DEBUG_INPUT_CALLBACK
		NSLog(@"[SND] vend input interleaving %d to buffer[%d] channels = %d\n", 
		      inputInterleavedChannels, bufferIndex, inInputData->mBuffers[bufferIndex].mNumberChannels);
		NSLog(@"[SND] stream is on = %d\n", inputStreamIOProcUsage->mStreamIsOn[bufferIndex]);
		NSLog(@"[SND] channel count = %d, frame count = %d\n", inStream.channelCount, inStream.frameCount);
#endif	    		
		if(!inputInterleavedChannels) {
		    interleaveChannel(bufferIndex, 
				      inStream.channelCount, 
				      (float *) inInputData->mBuffers[bufferIndex].mData,
				      (float *) inputBuffer, 
				      inStream.frameCount);
		}
		else {
#if 0 // silence the input to see if the data input is being starved by locking.
		    memset(inputBuffer, 0, inputBufferSizeInBytes);
#else
		    memcpy(inputBuffer, inInputData->mBuffers[bufferIndex].mData, inputBufferSizeInBytes);
#endif
		}
		[inputLock unlock];
            }
        }
    }
    else {
#if DEBUG_INPUT_CALLBACK    
        NSLog(@"[SND] input vendInputBuffersToStreamManagerIOProc: input buffer is NULL!\n");
#endif
    }
    
#if DEBUG_INPUT_CALLBACK    
    NSLog(@"[SND] ending vendInputBuffersToStreamManagerIOProc...\n");
#endif
    
    return 0; // TODO need better definition...
}

// Retrieves the configuration of how many channels are situated within each stream.
// We use this to determine if the device is producing or consuming interleaved or non-interleaved buffers.
static BOOL getStreamChannelConfiguration(AudioDeviceID deviceID, BOOL forOutputDevice, BOOL *interleavedChannels, int *numberOfStreams)
{
    AudioBufferList *streamConfigurationList;
    AudioStreamID *streamIdentifiers;
    OSStatus CAstatus;
    UInt32 propertySize;
    int streamIndex;
    int maxChannelsPerStream = 0;
    AudioObjectPropertyAddress devicePropertyAddress;
    // int streamIDIndex;
    
    devicePropertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
    devicePropertyAddress.mScope = forOutputDevice ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    devicePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    CAstatus = AudioObjectGetPropertyDataSize(deviceID, &devicePropertyAddress, 0, NULL, &propertySize);
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreamConfiguration %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
    if((streamConfigurationList = (AudioBufferList *) malloc(propertySize)) == NULL) {
	NSLog(@"getStreamChannelConfiguration property: unable to malloc streamConfigurationList of size %d bytes.\n", propertySize);
	return FALSE;
    }
    
    CAstatus = AudioObjectGetPropertyData(deviceID, &devicePropertyAddress, 0, NULL, &propertySize, streamConfigurationList);
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreamConfiguration returned %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
#if DEBUG_DESCRIPTION
    NSLog(@"%d: %s streamConfigurationList number of streams %d\n", deviceID, forOutputDevice ? "output" : "input", streamConfigurationList->mNumberBuffers);
#endif
    for(streamIndex = 0; streamIndex < streamConfigurationList->mNumberBuffers; streamIndex++) {
#if DEBUG_DESCRIPTION
	NSLog(@"stream %d holds %d channels, buffer size %d bytes\n", streamIndex, 
	      streamConfigurationList->mBuffers[streamIndex].mNumberChannels, streamConfigurationList->mBuffers[streamIndex].mDataByteSize);
#endif
	if(streamConfigurationList->mBuffers[streamIndex].mNumberChannels > maxChannelsPerStream)
	    maxChannelsPerStream = streamConfigurationList->mBuffers[streamIndex].mNumberChannels;
    }
    
    *interleavedChannels = streamConfigurationList->mNumberBuffers <= 1 || maxChannelsPerStream > 1;
#if DEBUG_DESCRIPTION
    NSLog(@"interleavedChannels = %d, maxChannelsPerStream = %d\n", *interleavedChannels, maxChannelsPerStream);
#endif
    free(streamConfigurationList);
    
    devicePropertyAddress.mSelector = kAudioDevicePropertyStreams;
    devicePropertyAddress.mScope = forOutputDevice ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    devicePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    CAstatus = AudioObjectGetPropertyDataSize(deviceID, &devicePropertyAddress, 0, NULL, &propertySize);    
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreams %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
    if((streamIdentifiers = (AudioStreamID *) malloc(propertySize)) == NULL) {
	NSLog(@"getStreamChannelConfiguration: Unable to malloc streamIdentifiers of size %d bytes.\n", propertySize);
	return FALSE;
    }
    *numberOfStreams = propertySize / sizeof(AudioStreamID);
#if DEBUG_DESCRIPTION
    NSLog(@"number of streams = %d\n", *numberOfStreams);
#endif    
    CAstatus = AudioObjectGetPropertyData(deviceID, &devicePropertyAddress, 0, NULL, &propertySize, streamIdentifiers);
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreams returned %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
    // If I understand the CoreAudio documentation, starting channel should be the device channel each stream begins with.
    // Yet the values returned are always 1, hmm...
#if 0    
    for(streamIDIndex = 0; streamIDIndex < *numberOfStreams; streamIDIndex++) {
	UInt32 startingChannel;
	
	CAstatus = AudioStreamGetPropertyInfo(streamIdentifiers[streamIDIndex],
					      0,
					      kAudioStreamPropertyStartingChannel,
					      &propertySize,
					      &propertyWritable);                                                   
	if (CAstatus) {
	    NSLog(@"kAudioStreamPropertyStartingChannel returned %s\n", getCoreAudioErrorStr(CAstatus));
	    return FALSE;
	}
	
	if(propertySize != sizeof(startingChannel))
	    NSLog(@"assertion failure kAudioStreamPropertyStartingChannel property size != sizeof(startingChannel)");
	
	CAstatus = AudioStreamGetProperty(streamIdentifiers[streamIDIndex],
					  0,
					  kAudioStreamPropertyStartingChannel,
					  &propertySize,
					  &startingChannel);                                                       
	if (CAstatus) {
	    NSLog(@"kAudioStreamPropertyStartingChannel returned %s\n", getCoreAudioErrorStr(CAstatus));
	    return FALSE;
	}
	
	NSLog(@"starting channel = %d\n", startingChannel);
    }
#endif
    free(streamIdentifiers);
    
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// dumpStreamDescription
////////////////////////////////////////////////////////////////////////////////

#if DEBUG_DESCRIPTION
static void dumpStreamDescription(AudioStreamBasicDescription *StrBasDesc)
{
    NSLog(@"samplerate:       %f\nformat:           %4s\nFormatFlags:      0x%X\n" \
	  @"bytesPerPacket:   %li\nframesPerPacket:  %li\nBytesPerFrame:    %li\n" \
	  @"ChannelsPerFrame: %li\nBitsPerChannel:   %li\n",
	  StrBasDesc->mSampleRate,		            // the native sample rate of the audio stream
	  (char *) &StrBasDesc->mFormatID,		    // the specific encoding type of audio stream
	  (unsigned int) StrBasDesc->mFormatFlags,	    // flags specific to each format
	  StrBasDesc->mBytesPerPacket,                    // the number of bytes in a packet
	  StrBasDesc->mFramesPerPacket,                   // the number of frames in each packet
	  StrBasDesc->mBytesPerFrame,                     // the number of bytes in a frame
	  StrBasDesc->mChannelsPerFrame,                  // the number of channels in each frame
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
				      BOOL forOutputDevice)
{
#if DEBUG_DESCRIPTION
    char    deviceName[1024];
    
    if(!getDeviceProperty(deviceID, forOutputDevice, kAudioDevicePropertyDeviceName, deviceName, sizeof(deviceName))) {
	return FALSE;
    }
    
    NSLog(@"Devicename: %s\n", deviceName);
#endif
    
    if(!getDeviceProperty(deviceID, forOutputDevice, kAudioDevicePropertyStreamFormat, audioStreamBasicDescription, sizeof(AudioStreamBasicDescription))) {
	return FALSE;
    }
    
#if DEBUG_DESCRIPTION
    NSLog(@"device ID: %d\n", (unsigned int) deviceID);
    dumpStreamDescription(audioStreamBasicDescription);
#endif
    
#if 0
    AudioObjectPropertyAddress devicePropertyAddress;
    
    devicePropertyAddress.mSelector = kAudioDevicePropertyRateScalar;
    devicePropertyAddress.mScope = forOutputDevice ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    devicePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    // check to see if the sample rate is changeable... TODO this could be used to change the hardware rather than resampling.
    CAstatus = AudioObjectGetPropertyDataSize(deviceID, &devicePropertyAddress, 0, NULL, &propertySize);
    NSLog(@"AudioObjectGetPropertyDataSize kAudioDevicePropertyRateScalar  CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
	  getCoreAudioErrorStr(CAstatus), propertySize, propertyWritable);
    
    // TODO check kAudioDevicePropertyLatency
    
#endif
    
    return TRUE;
}
    
// This retrieves a list of device IDs, depending on input or output scope.
// The caller is responsible for freeing the array.
static AudioDeviceID *getDeviceIDs(BOOL forOutputDevices, unsigned int *numOfDevices)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    AudioDeviceID *deviceIDs;
    AudioDeviceID *allDeviceIDs;
    AudioObjectPropertyAddress hardwarePropertyAddress;
    unsigned int deviceIDIndex, allDevicesCount;
    
    hardwarePropertyAddress.mSelector = kAudioHardwarePropertyDevices;
    hardwarePropertyAddress.mScope = kAudioObjectPropertyScopeGlobal; // Always global.
    hardwarePropertyAddress.mElement = kAudioObjectPropertyElementMaster;

    *numOfDevices = 0; // ensure in the case of errors we have no devices.

    // get the device list    
    CAstatus = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &hardwarePropertyAddress, 0, NULL, &propertySize);    
    if (CAstatus) {
	NSLog(@"getDeviceIDs() AudioObjectGetPropertyDataSize kAudioHardwarePropertyDevices returned %s, propertySize = %ld\n", 
	      getCoreAudioErrorStr(CAstatus), propertySize);
	return NULL;
    }
    
    // Find out how many devices (input or output) are on the system.
    allDevicesCount = propertySize / sizeof(AudioDeviceID);

    // Allocate space for all the devices so that we can receive them from getting the property data.
    if((allDeviceIDs = (AudioDeviceID *) malloc(propertySize)) == NULL) {
	NSLog(@"Unable to malloc all device ids\n");
	return NULL;
    }
    
    CAstatus = AudioObjectGetPropertyData(kAudioObjectSystemObject, &hardwarePropertyAddress, 0, NULL, &propertySize, allDeviceIDs);
    if (CAstatus) {
	NSLog(@"getDeviceIDs() AudioObjectGetPropertyData returned %s, propertySize = %ld\n", getCoreAudioErrorStr(CAstatus), propertySize);
	free(allDeviceIDs);
	return NULL;
    }
    
    // Allocate space for the maximum condition that all devices are equally input and output devices.
    if((deviceIDs = (AudioDeviceID *) malloc(propertySize)) == NULL) {
	NSLog(@"Unable to malloc device ids\n");
	return NULL;
    }
    
    // Loop through the devices and check their input or output status.
    for(deviceIDIndex = 0; deviceIDIndex < allDevicesCount; deviceIDIndex++) {
	BOOL interleavedChannels;
	int numberOfStreams;
	
	getStreamChannelConfiguration(allDeviceIDs[deviceIDIndex], forOutputDevices, &interleavedChannels, &numberOfStreams);
	
	if(numberOfStreams > 0) {
	    deviceIDs[*numOfDevices] = allDeviceIDs[deviceIDIndex];
	    (*numOfDevices)++;
	}
    }    
    free(allDeviceIDs);
    
    return deviceIDs;  // Caller is responsible for freeing the array.
}    

////////////////////////////////////////////////////////////////////////////////
// retrieveDriverList
//
// Iterate through the possible devices and build a formatted list.
// A NULL char * terminates the list a la argv behaviour.
////////////////////////////////////////////////////////////////////////////////

static const char **retrieveDriverList(BOOL forOutputDevice)
{
    AudioDeviceID *deviceIDs;
    char **driverList;
    unsigned int driverIndex = 0;
    unsigned int numOfDevices;

    if((deviceIDs = getDeviceIDs(forOutputDevice, &numOfDevices)) == NULL)
	return NULL;
    
    if((driverList = (char **) malloc(sizeof(char *) * (numOfDevices + 1))) == NULL) {
        NSLog(@"Unable to malloc driver list for %s\n", forOutputDevice ? "output" : "input");
	free(deviceIDs);
        return NULL;
    }
        
    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
	NSString *deviceName;
	const char *utf8DeviceName;
	UInt32 propertySize;
	OSStatus CAstatus;
	AudioObjectPropertyAddress deviceNamePropertyAddress;

	deviceNamePropertyAddress.mSelector = kAudioObjectPropertyName;
	deviceNamePropertyAddress.mScope = forOutputDevice ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
	deviceNamePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
	propertySize = sizeof(NSString *);
	
        // get the name.
	CAstatus = AudioObjectGetPropertyData(deviceIDs[driverIndex], &deviceNamePropertyAddress, 0, NULL, &propertySize, &deviceName);
        if (CAstatus) {
            NSLog(@"AudioObjectGetPropertyData device name returned %s, propertySize = %ld\n", getCoreAudioErrorStr(CAstatus), propertySize);
	    free(deviceIDs);
            return NULL;
        }
	
        // NSLog(@"DevID: %d   name: %@\n", deviceIDs[driverIndex], deviceName);
	utf8DeviceName = [deviceName UTF8String];
        driverList[driverIndex] = (char *) malloc(strlen(utf8DeviceName) + 1);
	strcpy((char *) driverList[driverIndex], utf8DeviceName);
    }
    free(deviceIDs);
    
    driverList[driverIndex] = NULL; // NULL terminate the list
    return (const char **) driverList;
}

// Find the output device ID in the driver list and return the driver list index.
// TODO we make the reasonably safe assumption that the sequence of deviceIDs and 
// driver names will be in the same order. Returns 0 if unable to find the device.
static unsigned int findDeviceInDriverList(AudioDeviceID deviceIDToFind, BOOL forOutputDevice)
{
    unsigned int driverIndex = 0;
    unsigned int numOfDevices;
    AudioDeviceID *deviceIDs = getDeviceIDs(forOutputDevice, &numOfDevices);
    
    if(deviceIDs == NULL)
        return 0;
        
    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
        if(deviceIDs[driverIndex] == deviceIDToFind) {
            free(deviceIDs);
            return driverIndex;
        }
    }
    
    NSLog(@"Couldn't find the driver ID %x out of %d devices\n", deviceIDToFind, numOfDevices);
    free(deviceIDs);

    return 0; // If we couldn't find it, default to the first.
}

static AudioDeviceID deviceIDOfDriverIndex(unsigned int driverIndexToFind, BOOL forOutputDevice)
{
    AudioDeviceID deviceIDToFind;
    unsigned int numOfDevices;
    AudioDeviceID *deviceIDs = getDeviceIDs(forOutputDevice, &numOfDevices);
    
    if(deviceIDs == NULL || driverIndexToFind >= numOfDevices)
        return 0;
        
    deviceIDToFind = deviceIDs[driverIndexToFind];
    free(deviceIDs);
    return deviceIDToFind;
}

////////////////////////////////////////////////////////////////////////////////
// isDeviceRunning
////////////////////////////////////////////////////////////////////////////////

static BOOL isDeviceRunning(AudioDeviceID deviceID, BOOL forOutputDevice)
{
    UInt32 running = 0;

    /* check the device is running */
    if(!getDeviceProperty(deviceID, forOutputDevice, kAudioDevicePropertyDeviceIsRunning, &running, sizeof(running))) {
        return FALSE;
    }

    return running != 0;
}

// Determine which AudioStreams of the AudioDevice should be serviced by our IOProc.
// If a stream is marked as not being used, the given IOProc will see a corresponding NULL buffer
// pointer in the AudioBufferList passed to it's IO proc.
static BOOL getAudioStreamsToVend(AudioDeviceID deviceID,
				  AudioHardwareIOProcStreamUsage **ioProcStreamUsage,
				  void *ioProc,
				  BOOL forOutputDevice)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    AudioObjectPropertyAddress devicePropertyAddress;

    devicePropertyAddress.mSelector = kAudioDevicePropertyIOProcStreamUsage;
    devicePropertyAddress.mScope = forOutputDevice ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    devicePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    CAstatus = AudioObjectGetPropertyDataSize(deviceID, &devicePropertyAddress, 0, NULL, &propertySize);    
    if (CAstatus) {
	NSLog(@"AudioObjectGetPropertyDataSize kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

    if((*ioProcStreamUsage = (AudioHardwareIOProcStreamUsage *) malloc(propertySize)) == NULL) {
        NSLog(@"Unable to malloc ioProcStreamUsage buffer of %ld bytes\n", propertySize);
        return FALSE;
    }

    // Indicate which ioProc to retrieve stream usage information for.
    (*ioProcStreamUsage)->mIOProc = ioProc;

    CAstatus = AudioObjectGetPropertyData(deviceID, &devicePropertyAddress, 0, NULL, &propertySize, *ioProcStreamUsage);
    if (CAstatus) {
	NSLog(@"AudioObjectGetPropertyDataSize kAudioDevicePropertyIOProcStreamUsage: %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }

#if DEBUG_IOPROCUSAGE
    {
	unsigned int i;

	NSLog(@"%s (*ioProcStreamUsage)->mNumberStreams = %ld\n", forOutputDevice ? "output" : "input", 
            (*ioProcStreamUsage)->mNumberStreams);
	for(i = 0; i < (*ioProcStreamUsage)->mNumberStreams; i++) {
	    NSLog(@"(*ioProcStreamUsage)->mStreamIsOn[%d] = %ld\n", i, (*ioProcStreamUsage)->mStreamIsOn[i]);
	}
    }
#endif
    
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// getBufferSize
////////////////////////////////////////////////////////////////////////////////

static long getBufferSize(AudioDeviceID deviceID, BOOL forOutputDevice)
{
    long currentBufferSizeInBytes;
    int numberOfStreams = forOutputDevice ? outputNumberOfStreams : inputNumberOfStreams;
    BOOL notInterleaved = (forOutputDevice && !outputInterleavedChannels) || (!forOutputDevice && !inputInterleavedChannels);
    
    /* fetch the buffer size per stream */
    if (!getDeviceProperty(deviceID, forOutputDevice, kAudioDevicePropertyBufferSize, &currentBufferSizeInBytes, sizeof(currentBufferSizeInBytes))) {
	return 0;
    }
        
    // If the device is non-interleaved, we return the buffer size as it will be returned to the caller, i.e. always interleaved.
    // return currentBufferSizeInBytes * numberOfStreams;
    // TODO this is actually not right: We should be retrieving all streams and then returning them as a fully interleaved buffer.
    return notInterleaved ? currentBufferSizeInBytes * numberOfStreams : currentBufferSizeInBytes;
}

////////////////////////////////////////////////////////////////////////////////
// setBufferSize
////////////////////////////////////////////////////////////////////////////////

static BOOL setBufferSize(AudioDeviceID deviceID, 
                   long bufferSizeToSetInBytes, 
                   BOOL forOutputDevice)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    AudioObjectPropertyAddress bufferSizePropertyAddress;
    int numberOfStreams = forOutputDevice ? outputNumberOfStreams : inputNumberOfStreams;
    BOOL notInterleaved = (forOutputDevice && !outputInterleavedChannels) || (!forOutputDevice && !inputInterleavedChannels);
    long streamBufferSizeInBytes = notInterleaved ? bufferSizeToSetInBytes / numberOfStreams : bufferSizeToSetInBytes;
    long newStreamBufferSizeInBytes;
    long newBufferSizeInBytes;

    /* fetch the buffer size as another level of error checking. */
    bufferSizePropertyAddress.mSelector = kAudioDevicePropertyBufferSize;
    bufferSizePropertyAddress.mScope = forOutputDevice ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    bufferSizePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
    
    CAstatus = AudioObjectGetPropertyDataSize(deviceID, &bufferSizePropertyAddress, 0, NULL, &propertySize);
    if (CAstatus) {
        NSLog(@"AudioObjectGetPropertyDataSize kAudioDevicePropertyBufferSize returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

#if DEBUG_BUFFERSIZE // only needed for debugging
    NSLog(@"Setting the %s stream buffer size to %ld bytes\n", forOutputDevice ? "output" : "input", streamBufferSizeInBytes);
#endif

    /* set the buffer size of the device */
    CAstatus = AudioObjectSetPropertyData(deviceID, &bufferSizePropertyAddress, 0, NULL, propertySize, &streamBufferSizeInBytes);
    if (CAstatus) {
        NSLog(@"AudioObjectSetPropertyData (output) returned %s\n", getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }
    
    /* fetch the buffer size to check */
    if (!getDeviceProperty(deviceID, forOutputDevice, kAudioDevicePropertyBufferSize, &newStreamBufferSizeInBytes, sizeof(newStreamBufferSizeInBytes))) {
	return FALSE;
    }
    newBufferSizeInBytes = notInterleaved ? newStreamBufferSizeInBytes * numberOfStreams : newStreamBufferSizeInBytes;
    if(forOutputDevice)
	outputBufferSizeInBytes = newBufferSizeInBytes;
    else 
	inputBufferSizeInBytes = newBufferSizeInBytes;

#if DEBUG_BUFFERSIZE // only needed for debugging
    NSLog(@"after setting, %s buffer size (CAstatus:%s), bufferSizeInBytes = %ld\n", 
	  forOutputDevice ? "output" : "input", 
	  getCoreAudioErrorStr(CAstatus), 
	  newBufferSizeInBytes);
#endif
    
    if (newBufferSizeInBytes != bufferSizeToSetInBytes) {
        NSLog(@"device did not set desired buffer size\n");
        NSLog(@"desired: %d\nactual: %d\n", (int) bufferSizeToSetInBytes, (int) newBufferSizeInBytes);
        return FALSE;
    }
    if(forOutputDevice)
	outputBufferSizeInFrames = outputBufferSizeInBytes / (outputStreamBasicDescription.mBytesPerFrame * (notInterleaved ? numberOfStreams : 1));
    else 
	inputBufferSizeInFrames = inputBufferSizeInBytes / (inputStreamBasicDescription.mBytesPerFrame * (notInterleaved ? numberOfStreams : 1));
    
    return TRUE;
}

// Retrieve the channel assignments so we know which channels constitute left and right channels
static BOOL getSpeakerConfiguration(AudioDeviceID outputDeviceID)
{
    // unsigned char channelDescription[1024];
    UInt32 stereoChannels[2] = { 0, 1 }; // create defaults so we don't have problems if a device doesn't respond to the preferred channels property.
    int numOfChannels = 4;  // TODO hardwired
    // AudioChannelLayout channelLayout;
    
    if (!getDeviceProperty(outputDeviceID, TRUE, kAudioDevicePropertyPreferredChannelsForStereo, &stereoChannels, sizeof(stereoChannels))) {
	// In case a device doesn't respond to preferred channels for stereo, we create a default.
	numOfChannels = 2;
    }
    
    // NSLog(@"Preferred channels for stereo Left = %d, Right = %d\n", stereoChannels[0], stereoChannels[1]);

#if 0
    // TODO determine multichannel layouts. 
    if (!getDeviceProperty(outputDeviceID, TRUE, kAudioDevicePropertyPreferredChannelLayout, &channelLayout, sizeof(channelLayout))) {
	// In case a device doesn't respond to preferred channels for stereo, we create a default.
	numOfChannels = 2;
    }
#endif
    
    if(speakerConfigurationList != NULL)
	free(speakerConfigurationList);
    if((speakerConfigurationList = (char **) malloc(sizeof(char *) * (numOfChannels + 1))) == NULL) {
        NSLog(@"Unable to malloc speaker configuration list\n");
        return FALSE;
    }
	
    return TRUE;
}

// Doesn't actually change the device, just initialises our state 
static BOOL setOutputDevice(AudioDeviceID outputDeviceID)
{
#if DEBUG_DESCRIPTION
    NSLog(@"OUTPUT ===========\n");
#endif

    /* check the returned device */
    if (outputDeviceID == kAudioDeviceUnknown) {
        NSLog(@"setOutputDevice() outputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(!determineBasicDescription(outputDeviceID, &outputStreamBasicDescription, TRUE)) {
        NSLog(@"setOutputDevice() - error determining basic description\n");
        return FALSE;
    }

    if(!getSpeakerConfiguration(outputDeviceID)) {
	NSLog(@"couldn't retrieve speaker configuration\n");
	// return FALSE; // We should probably let this slide.
    }

#if CHECK_DEVICE_RUNNING_STATUS
    if(isDeviceRunning(outputDeviceID, TRUE)) {
	NSLog(@"SNDInit() output device is already running... but this is ok in CoreAudio land\n");
    }
#endif

    if(!getStreamChannelConfiguration(outputDeviceID, TRUE, &outputInterleavedChannels, &outputNumberOfStreams)) {
	NSLog(@"Couldn't retrieve output stream's channel configuration\n");
	// return FALSE; // We should probably let this slide.
    }
    // retrieve and use the device buffer size.
    outputBufferSizeInBytes = getBufferSize(outputDeviceID, TRUE);
    outputBufferSizeInFrames = outputInterleavedChannels ? outputBufferSizeInBytes / outputStreamBasicDescription.mBytesPerFrame :
							   outputBufferSizeInBytes / (outputStreamBasicDescription.mBytesPerFrame * outputNumberOfStreams);

    return TRUE;
}

// Doesn't actually change the device, just initialises our state 
static BOOL setInputDevice(AudioDeviceID inputDeviceID)
{
#if DEBUG_DESCRIPTION
    NSLog(@"INPUT =========== inputDeviceID = %d\n", inputDeviceID);
#endif

    if (inputDeviceID == kAudioDeviceUnknown) {
        NSLog(@"setInputDevice() inputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(!determineBasicDescription(inputDeviceID, &inputStreamBasicDescription, FALSE)) {
        NSLog(@"setInputDevice() - error determining basic setup\n");
        return FALSE;
    }

#if CHECK_DEVICE_RUNNING_STATUS
    if(isDeviceRunning(inputDeviceID, FALSE)) {
	NSLog(@"SNDInit() Input device is already running... but this is ok in CoreAudio land\n");
    }
#endif
    
    if(!getStreamChannelConfiguration(inputDeviceID, FALSE, &inputInterleavedChannels, &inputNumberOfStreams)) {
	NSLog(@"Couldn't retrieve input stream's channel configuration\n");
	// return FALSE; // We should probably let this slide.
    }
    inputBufferSizeInBytes = getBufferSize(inputDeviceID, FALSE);
    inputBufferSizeInFrames = inputInterleavedChannels ? inputBufferSizeInBytes / inputStreamBasicDescription.mBytesPerFrame :
							 inputBufferSizeInBytes / (inputStreamBasicDescription.mBytesPerFrame * inputNumberOfStreams);

    NSLog(@"setInputDevice() inputBufferSizeInBytes %d inputBufferSizeInFrames %d\n", inputBufferSizeInBytes, inputBufferSizeInFrames);
    return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// SNDInit
//
// Takes a parameter indicating whether to select the default device to use.
// This allows us to hard code devices or use default to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDInit(BOOL useDefaultDevice)
{
    if(!initialised) {
        initialised = TRUE;                   // SNDSetDriverIndex() needs to think we're initialised.
        inputLock   = [[NSLock alloc] init];
    }

    /* initialize CoreAudio device */
    if(useDefaultDevice) {
	BOOL noError;
	
        /* Get the default sound output device */
	noError = getDeviceProperty(kAudioObjectSystemObject, TRUE, kAudioHardwarePropertyDefaultOutputDevice, &outputDeviceID, sizeof(AudioDeviceID));
	// NSLog(@"Default output device ID %d\n", outputDeviceID);
	if(!noError) {
	    NSLog(@"SNDInit() Output: kAudioObjectSystemObject kAudioHardwarePropertyDefaultOutputDevice returned FALSE\n");
	    return FALSE;
	}
        // find the default output device ID in the driver list and assign its index
        outputDriverIndex = findDeviceInDriverList(outputDeviceID, TRUE);
	// NSLog(@"default output driver index = %d\n", outputDriverIndex);
	
        /* Get the default sound input device */
	noError = getDeviceProperty(kAudioObjectSystemObject, FALSE, kAudioHardwarePropertyDefaultInputDevice, &inputDeviceID, sizeof(AudioDeviceID));
	// NSLog(@"Default input device ID %d\n", inputDeviceID);
	if(!noError) {
	    NSLog(@"SNDInit() Input: kAudioObjectSystemObject kAudioHardwarePropertyDefaultInputDevice returned FALSE\n");
	    return FALSE;
	}
	// find the default input device ID in the driver list and assign its index
        inputDriverIndex = findDeviceInDriverList(inputDeviceID, FALSE);
	// NSLog(@"default input driver index = %d\n", inputDriverIndex);
    }
    else {
        NSLog(@"SNDInit() Didn't use default device, using first\n");
	outputDriverIndex = 0;
	inputDriverIndex = 0;
	outputDeviceID = deviceIDOfDriverIndex(outputDriverIndex, TRUE);
	// if we are not using the default device, we should set the buffer size.
	if(!setBufferSize(outputDeviceID, outputBufferSizeInBytes, TRUE)) {
	    NSLog(@"SNDInit() - error setting output buffer size\n");
	    return FALSE;
	}
	
	inputDeviceID = deviceIDOfDriverIndex(inputDriverIndex, FALSE);
	if(!setBufferSize(inputDeviceID, inputBufferSizeInBytes, FALSE)) {
	    NSLog(@"SNDInit() - error setting output buffer size\n");
	    return FALSE;
	}	
    }

    // We set the output and input devices to initialise the rest of the state.
    if(!setOutputDevice(outputDeviceID))
	return FALSE;
    
    // We have a condition that can cause confusion: if a device is opened and the buffer size is set different
    // from the default, and then only the opposite direction device is changed, if we initialise the buffer 
    // size from the hardware the size will remain set and probably not matching buffer sizes. This isn't always
    // a problem, depending on the client.
    // inputBufferSize = outputBufferSize;
    inputInit = setInputDevice(inputDeviceID);
    
#if DEBUG_BUFFERSIZE
    NSLog(@"SNDInit() outputBufferSizeInBytes = %ld, outputInterleavedChannels %d outputNumberOfStreams %d\n",
	  outputBufferSizeInBytes, outputInterleavedChannels, outputNumberOfStreams);
    NSLog(@"SNDInit() inputBufferSizeInBytes = %ld, inputInterleavedChannels %d inputNumberOfStreams %d\n",
	  inputBufferSizeInBytes, inputInterleavedChannels, inputNumberOfStreams);
#endif
    return inputInit;
}

// Shut down what we started up in SndInit();
PERFORM_API BOOL SNDTerminate(void)
{
    [inputLock release];
    inputLock = nil;
    initialised = FALSE;

    // CoreAudio doesn't need an explicit call to shut down/disengage/unreserve to our app.
    return TRUE;
}

// Returns an array of character pointers listing the names of each channel. There will be channel count number of strings returned, with a NULL terminated
// The naming is system dependent, but is guaranteed to have two
// channels named "Left" and "Right" to ensure that stereo can always be used.
PERFORM_API const char **SNDSpeakerConfiguration(void)
{
    // TODO should check if initialised so that the speaker configuration can be obtained for the assigned hardware.
    // if(!initialised)
    //    return FALSE;

    speakerConfigurationList[0] = "Left";
    speakerConfigurationList[1] = "Right";
    speakerConfigurationList[2] = NULL;

    return (const char **) speakerConfigurationList;
}

PERFORM_API BOOL SNDSetBufferSizeInBytes(long newBufferSizeInBytes, BOOL forOutputDevices)
{
    AudioDeviceID deviceId = forOutputDevices ? outputDeviceID : inputDeviceID;
    
    if (isDeviceRunning(deviceId, forOutputDevices)) {
	NSLog(@"SNDSetBufferSizeInBytes of %s device - error setting buffer size, already running\n", forOutputDevices ? "output" : "input", newBufferSizeInBytes);
	// return FALSE; // We disable exiting with an error if the device is running, we can have situations where it is better to try to change and see what happens.
    }
    if(!setBufferSize(deviceId, newBufferSizeInBytes, forOutputDevices)) {
	NSLog(@"SNDSetBufferSizeInBytes of %s device - error setting buffer size to %d bytes\n", forOutputDevices ? "output" : "input", newBufferSizeInBytes);
	return FALSE;
    }
    return TRUE;
}

PERFORM_API long SNDGetBufferSizeInBytes(BOOL forOutputDevices)
{
    AudioDeviceID deviceId = forOutputDevices ? outputDeviceID : inputDeviceID;
    long bufferSize;
    
    if(!(bufferSize = getBufferSize(deviceId, forOutputDevices))) {
	NSLog(@"%s device - error getting buffer size\n", forOutputDevices ? "output" : "input");
	return 0;
    }
    return bufferSize;
}
    
// Returns an array of strings listing the available drivers.
// Returns NULL if the driver names were unobtainable.
// The client application should not attempt to free the pointers.
PERFORM_API const char **SNDGetAvailableDriverNames(BOOL forOutputDrivers)
{    
    return retrieveDriverList(forOutputDrivers);
}

PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex, BOOL forOutputDrivers)
{
    // This needs to be called after initialising.
    if(initialised) {
	BOOL wasStreaming = streamProcessor != NULL; // we need to restart the streaming.
	SNDStreamProcessor savedStreamProcessor = streamProcessor;
        AudioDeviceID deviceID = deviceIDOfDriverIndex(selectedIndex, forOutputDrivers);

	if(deviceID != 0) {
	    if(wasStreaming)
		SNDStreamStop();
	    if(forOutputDrivers) {
		outputDeviceID = deviceID;
		outputDriverIndex = selectedIndex;
		
		if(!setOutputDevice(outputDeviceID))
		    return FALSE; // TODO this will leave the stream stopped.
	    }
	    else {
		inputDeviceID = deviceID;
		inputDriverIndex = selectedIndex;
		
		if(!(inputInit = setInputDevice(inputDeviceID)))
		    return FALSE; // TODO this will leave the stream stopped.
	    }

	    if(wasStreaming)
		SNDStreamStart(savedStreamProcessor, streamUserData);
	    return TRUE;
	}
    }
    return FALSE;
}

PERFORM_API unsigned int SNDGetAssignedDriverIndex(BOOL forOutputDrivers)
{
    return forOutputDrivers ? outputDriverIndex : inputDriverIndex;
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
PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat, BOOL isOutputStream)
{
    AudioStreamBasicDescription *streamBasicDescription;
    int numberOfStreams;
    BOOL interleavedChannels;
    
    if (!initialised)
	SNDInit(TRUE);
    
    if(isOutputStream) {
	streamBasicDescription = &outputStreamBasicDescription;
	interleavedChannels = outputInterleavedChannels;
	numberOfStreams = outputNumberOfStreams;
	// Number of channel independent sample frames in a buffer.
	streamFormat->frameCount = outputBufferSizeInFrames;
    }
    else {
	streamBasicDescription = &inputStreamBasicDescription;
	interleavedChannels = inputInterleavedChannels;
	numberOfStreams = inputNumberOfStreams;
	// Number of channel independent sample frames in a buffer.
	streamFormat->frameCount = inputBufferSizeInFrames;
    }
    
    // The bytes per frame is implicitly set by the dataFormat value.
    streamFormat->dataFormat   = SND_FORMAT_FLOAT;
    streamFormat->sampleRate   = streamBasicDescription->mSampleRate;
    // if it's a non-interleaved set of mono CoreAudio streams, count those, otherwise count the number of interleaved channels per frame.
    streamFormat->channelCount = interleavedChannels ? streamBasicDescription->mChannelsPerFrame : numberOfStreams;

    // Rather than setting the stream data explicitly NULL, we just leave it so the buffer can be reused.
    // streamFormat->streamData = NULL;
#if 0
    NSLog(@"SNDStreamNativeFormat for %s frameCount %d sampleRate %lf channels %d interleaved %d streams %d\n", 
	  isOutputStream ? "output" : "input",
	  streamFormat->frameCount, streamFormat->sampleRate, streamFormat->channelCount, interleavedChannels, numberOfStreams);
#endif
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStart
//
// Routine to begin playback/recording of a stream.
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *newUserData)
{
    BOOL streamStartedOK = TRUE;
    OSStatus CAstatus;
    
#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Beginning stream start...\n");
#endif    

    if(!initialised)
        return FALSE;  // invalid sound structure.

    // Even if we don't have input, we still need an input buffer to send up empty to the rest of the arch.
    if ((inputBuffer = (float *) malloc(inputBufferSizeInBytes)) == NULL) {
        NSLog(@"Unable to malloc input buffer of %ld\n", inputBufferSizeInBytes);
        return FALSE;
    }
    memset(inputBuffer, 0, inputBufferSizeInBytes);
    // indicate the first absolute sample time received from the call back needs to be marked as a
    // datum to use to convert subsequent absolute sample times to a relative time.
    firstSampleTime = -1.0;  

    streamProcessor = newStreamProcessor;
    streamUserData  = newUserData;

#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
    CAstatus = AudioDeviceAddIOProc(outputDeviceID, vendOutputBuffersToStreamManagerIOProc, NULL);
#else
    CAstatus = AudioDeviceCreateIOProcID(outputDeviceID, vendOutputBuffersToStreamManagerIOProc, NULL, &outputDeviceProcID);
#endif
    if (CAstatus) {
        NSLog(@"SNDStartStreaming: AudioDeviceAddIOProc returned %s for output\n", getCoreAudioErrorStr(CAstatus));
        streamStartedOK = FALSE;
    }
    if(!getAudioStreamsToVend(outputDeviceID, &outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, TRUE))
	return FALSE;

#if 0 // no longer needed. Kept for reference only.
    // We do indeed want all streams since several non-interleaved hardware devices expect audio as several mono streams.
    {
	unsigned int streamIndex;

	// TODO turn off all but the first stream. This isn't right in the general case, we should use what the
	// the user has nominated as the default AudioStream in the default AudioDevice, but there doesn't seem to be
	// a means to determine this. For now, we do what iTunes seems to do, use the first AudioStream. 
        // This only seems to manifest itself for some multichannel boxes and now they interpret streams more logically.
	for(streamIndex = 1; streamIndex < outputStreamIOProcUsage->mNumberStreams; streamIndex++)
	    outputStreamIOProcUsage->mStreamIsOn[streamIndex] = FALSE;
    }
    
    if(!setAudioStreamsToVend(outputDeviceID, outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, TRUE))
	return FALSE;
#endif

    if (inputInit) {
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
        CAstatus = AudioDeviceAddIOProc(inputDeviceID, vendInputBuffersToStreamManagerIOProc, NULL);  // MacOS 10.4 Cocoa
#else
	CAstatus = AudioDeviceCreateIOProcID(inputDeviceID, vendInputBuffersToStreamManagerIOProc, NULL, &inputDeviceProcID);
#endif
        if (CAstatus) {
            NSLog(@"SNDStartStreaming: AudioDeviceAddIOProc returned %s for input\n", getCoreAudioErrorStr(CAstatus));
            streamStartedOK = FALSE;
        }
	if(!getAudioStreamsToVend(inputDeviceID, &inputStreamIOProcUsage, vendInputBuffersToStreamManagerIOProc, FALSE))
	    return FALSE;
    }
    if (streamStartedOK) { // all is well so far...
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
        CAstatus = AudioDeviceStart(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);
#else
        CAstatus = AudioDeviceStart(outputDeviceID, outputDeviceProcID);
#endif
        if (CAstatus) {
            NSLog(@"SNDStartStreaming: AudioDeviceStart returned %s\n", getCoreAudioErrorStr(CAstatus));
            streamStartedOK = FALSE;
        }
        if (inputInit) {
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
            CAstatus = AudioDeviceStart(inputDeviceID, vendInputBuffersToStreamManagerIOProc);
#else
            CAstatus = AudioDeviceStart(inputDeviceID, inputDeviceProcID);
#endif
            if (CAstatus) {
                NSLog(@"SNDStartStreaming: AudioDeviceStart returned %s\n", getCoreAudioErrorStr(CAstatus));
                streamStartedOK = FALSE;
            }
        }
    }
    // printf("initialised stream start %d\n", streamStartedOK);
#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Stream Started: %s\n", streamStartedOK ? "OK":"ERR");
#endif
    return streamStartedOK;
}

////////////////////////////////////////////////////////////////////////////////
// SNDStreamStop
////////////////////////////////////////////////////////////////////////////////

PERFORM_API BOOL SNDStreamStop(void)
{
    BOOL streamStoppedOK = TRUE;
    OSStatus CAstatus = 0;

    // Close input stream before closing the output streams.
    if (inputInit) {
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
        CAstatus = AudioDeviceStop(inputDeviceID, vendInputBuffersToStreamManagerIOProc);
#else
        CAstatus = AudioDeviceStop(inputDeviceID, inputDeviceProcID);
#endif
        if (CAstatus) {
            NSLog(@"SNDStreamStop() input device stop returned: %s\n", getCoreAudioErrorStr(CAstatus));
            streamStoppedOK = FALSE;
        }
	// Disable the input IOProc
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
	// Disable the output IOProc for MacOS 10.4 or earlier
	CAstatus = AudioDeviceRemoveIOProc(inputDeviceID, vendInputBuffersToStreamManagerIOProc);  
#else
	CAstatus = AudioDeviceDestroyIOProcID(inputDeviceID, inputDeviceProcID);  
#endif
        if (CAstatus) {
           NSLog(@"SNDStreamStop() input IOProc destruction returned: %s\n", getCoreAudioErrorStr(CAstatus));
           streamStoppedOK = FALSE;
        }
    }

#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
    CAstatus = AudioDeviceStop(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);
#else
    CAstatus = AudioDeviceStop(outputDeviceID, outputDeviceProcID);
#endif

#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Begining stream shutdown...\n");
#endif    
    
    if (CAstatus) {
        NSLog(@"SNDStreamStop() output device stop returned %s\n", getCoreAudioErrorStr(CAstatus));
        streamStoppedOK = FALSE;
    }
    firstSampleTime = -1.0;  
    if (inputInit) {
        free(inputBuffer);
        inputBuffer = NULL;
    }
    // Disable the output IOProc
#if !defined(MAC_OS_X_VERSION_10_5) || (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5)
    // Disable the output IOProc for MacOS 10.4 or earlier
    CAstatus = AudioDeviceRemoveIOProc(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);  
#else
    CAstatus = AudioDeviceDestroyIOProcID(outputDeviceID, outputDeviceProcID);  
#endif
    if (CAstatus) {
        NSLog(@"SNDStreamStop() output IOProc destruction returned: %s\n", getCoreAudioErrorStr(CAstatus));
        streamStoppedOK = FALSE;
    }
    
    if(streamStoppedOK) {
	streamProcessor = NULL;	
    }
#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Stream Stopped: %s\n", streamStoppedOK ? "OK" : "ERR");
#endif
    return streamStoppedOK;
}

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
}
#endif
