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

#define DEBUG_DESCRIPTION   0  // dump the description of the audio device.
#define DEBUG_BUFFERSIZE    0  // dump the check of the audio buffer size.
#define DEBUG_STARTSTOPMSG  0  // dump stream start/stop msgs
#define DEBUG_CALLBACK      0  // dump vendOutputBuffersToStreamManagerIOProc info.
#define DEBUG_IOPROCUSAGE   0  // dump the usage of AudioStreams by IOProcs.
#define CHECK_DEVICE_RUNNING_STATUS 0   

#define DEFAULT_BUFFERSIZE 16384  // The buffer size we want if we are not guessing the device.

// "class" variables
static BOOL initialised = FALSE;
static BOOL inputInit = FALSE;

static char         **driverList;
static char         **speakerConfigurationList;
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
static void   *streamUserData;
static double firstSampleTime = -1.0; // indicates this has not been assigned.
static float  *inputBuffer = NULL;
static BOOL   isMuted = FALSE;
static NSLock *inputLock = nil;
static BOOL   interleavedChannels = YES;
static int    numberOfStreams = 0;

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

// General routine to retrieve a device property, performing error checking.
static BOOL getDeviceProperty(AudioDeviceID deviceID, BOOL isInput, AudioDevicePropertyID propertyType, void *buffer, int maxBufferSize)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;

    // NSLog(@"getDeviceProperty test AudioDeviceGetProperty \'%4.4s\'\n", (char *) (&propertyType));    

    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput, propertyType, &propertySize, &propertyWritable);
    if (CAstatus) {
        NSLog(@"getDeviceProperty AudioDeviceGetPropertyInfo property \'%4.4s\': %s\n", (char *) (&propertyType), getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    if(propertySize > maxBufferSize) {
        NSLog(@"getDeviceProperty property \'%4.4s\': size %d larger than available buffer size %d\n",
            (char *) (&propertyType), propertySize, maxBufferSize);
        return FALSE;
    }
    
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, propertyType, &propertySize, buffer);
    
    if (CAstatus) {
        NSLog(@"getDeviceProperty AudioDeviceGetProperty \'%4.4s\': %s\n", (char *) (&propertyType), getCoreAudioErrorStr(CAstatus));
        return FALSE;
    }

    return TRUE;
}

// TODO this should be a good candidate for altivec using vec_perm, except that when deinterleaving
// streams beyond two channels, the increment across the sample frame exceeds the vector size.
// This means that for deinterleaving greater than two channel (e.g quad, 5.1) buffers, only two samples per channel
// could be deinterleaved per iteration. This then requires a lot of work to compute the permutation
// vector, particularly if there are other than a binary number of channels, such as 5.1. In that case,
// we need to check at each iteration which permutation vector to choose and which two data vectors to choose.
// This takes a lot of code for at best a factor of two increase in speed (assuming cost of scalar addition
// equals vec_perm memory store). For now I'm sacrificing speed for clarity.
static void deinterleaveChannel(int channel, int channelCount, float *fromStream, float *toStream, unsigned int frameCount)
{
    unsigned int frameIndex;
    unsigned int sampleIndex;

    for(frameIndex = 0, sampleIndex = 0; frameIndex < frameCount; frameIndex++) {	
	toStream[frameIndex] = fromStream[sampleIndex + channel];
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
	NSLog(@"[SND] assertion outOutputData->mNumberBuffers (%ld) == outputStreamIOProcUsage->mNumberStreams (%ld) failed\n",
	    outOutputData->mNumberBuffers, outputStreamIOProcUsage->mNumberStreams);
    }

    // to tell the client the format it is receiving.
    if (inputInit) {
	// inInputData->mNumberBuffers can differ from inputStreamIOProcUsage->mNumberStreams, since the former describes outDevices
	// number of input buffers, whereas the latter can describe the streams on potentially a different device.
	// TODO The whole approach of using two vending IOProcs which initiate one stream manager callback needs rethinking.
	if(inputStreamIOProcUsage->mStreamIsOn[0] &&
	   inInputData->mBuffers[0].mData != NULL) {
	    // TODO we only copy across the first buffers data to inputBuffer.
	    memcpy(inputBuffer, inInputData->mBuffers[0].mData, bufferSizeInBytes);
	}
	else {
	    inStream.streamData = NULL;
	}
    }
    
    // TODO we need to determine if the streams are themselves interleaved and if so iterate through them.
    interleavedStreamIndex = 0; 
    // for(interleavedStreamIndex = 0; interleavedStreamIndex < outputStreamIOProcUsage->mNumberStreams; interleavedStreamIndex++) 
    {
	// to tell the client the format it should send.
	SNDStreamNativeFormat(&outStream, YES);
	SNDStreamNativeFormat(&inStream, NO);
	
	inStream.streamData = inputBuffer;
	if(outputStreamIOProcUsage->mStreamIsOn[interleavedStreamIndex]) {
	    if(interleavedChannels)
		outStream.streamData = outOutputData->mBuffers[interleavedStreamIndex].mData;
	    else
		// If we must pass non-interleaved streams to CoreAudio, we need memory to receive the always interleaved streams from the
		// SndStreamManager.
		outStream.streamData = malloc(outStream.frameCount * outStream.channelCount * sizeof(float));	
	}
	else {
	    outStream.streamData = NULL;
	}
	
	[inputLock lock];
	
	if (!inputInit) {
#if DEBUG_CALLBACK
	    NSLog(@"[SND] vend no input initialized, zeroing input buffer...\n");
#endif		
	    memset(inputBuffer, 0, bufferSizeInBytes);
	}
	
	// hand over the stream buffers to the processor/stream manager.
	// the output time goes out as a relative time, noted from the
	// first sample time we first receive.
	
	(*streamProcessor)(inOutputTime->mSampleTime - firstSampleTime,
			   &inStream, &outStream, streamUserData);
	
	[inputLock unlock];
	
	// If the hardware only accepts non-interleaved buffers, deinterleave the SndStreamManager buffer
	// into each output stream.
	if(!interleavedChannels) {
	    unsigned int bufferIndex;

	    for(bufferIndex = 0; bufferIndex < outOutputData->mNumberBuffers; bufferIndex++) {
		if (isMuted) {
		    memset(outOutputData->mBuffers[bufferIndex].mData, 0, bufferSizeInBytes);
		}
		else {
#if DEBUG_CALLBACK
		    NSLog(@"[SND] vend deinterleaving to buffer[%d] channels = %d\n", bufferIndex, outOutputData->mBuffers[bufferIndex].mNumberChannels);
		    NSLog(@"[SND] stream is on = %d\n", outputStreamIOProcUsage->mStreamIsOn[bufferIndex]);
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
		memset(outOutputData->mBuffers[interleavedStreamIndex].mData, 0, bufferSizeInBytes);
	    }	
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

static BOOL retrieveDriverList(BOOL isInput)
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
        NSLog(@"AudioHardwareGetProperty 1 returned %s\n", getCoreAudioErrorStr(CAstatus));
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
        CAstatus = AudioDeviceGetPropertyInfo(allDeviceIDs[driverIndex], 0, isInput,
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
        CAstatus = AudioDeviceGetProperty(allDeviceIDs[driverIndex], 0, isInput,
                                        kAudioDevicePropertyDeviceName,
                                        &propertySize, deviceName);
        if (CAstatus) {
            NSLog(@"AudioDeviceGetProperty 2 returned %s\n", getCoreAudioErrorStr(CAstatus));
            return FALSE;
        }

        // NSLog(@"DevID: %d   name: %s\n", allDeviceIDs[driverIndex], deviceName);
    
        driverList[driverIndex] = deviceName;
    }

    driverList[driverIndex] = NULL; // NULL terminate the list
    return TRUE;
}

AudioDeviceID *getAllDeviceIDs(void)
{
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    AudioDeviceID *allDeviceIDs;

    CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &propertySize, &propertyWritable);
    // NSLog(@"AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
    //    (char *) &CAstatus, propertySize, propertyWritable);

    if (CAstatus) {
        NSLog(@"getAllDeviceIDs() AudioHardwareGetPropertyInfo kAudioHardwarePropertyDevices returned %s\n", getCoreAudioErrorStr(CAstatus));
        return NULL;
    }

    if((allDeviceIDs = (AudioDeviceID *) malloc(propertySize)) == NULL) {
        NSLog(@"Unable to malloc device ids\n");
        return NULL;
    }

    CAstatus = AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &propertySize, allDeviceIDs);
    // NSLog(@"AudioHardwareGetProperty kAudioHardwarePropertyDevices CAstatus:%s, propertySize = %ld\n", (char *) &CAstatus, propertySize);
    if (CAstatus) {
        NSLog(@"getAllDeviceIDs() AudioHardwareGetProperty returned %s\n", getCoreAudioErrorStr(CAstatus));
        return NULL;
    }

    if(numOfDevices != propertySize / sizeof(AudioDeviceID))
        NSLog(@"findDeviceInDriverList assertion failed! numOfDevices = %d vs. %d\n", numOfDevices, propertySize / sizeof(AudioDeviceID));

    return allDeviceIDs;  // Caller is responsible for freeing the array.
}

// Find the output device ID in the driver list and return the driver list index.
// TODO we make the reasonably safe assumption that the sequence of deviceIDs and 
// driver names will be in the same order. Returns 0 if unable to find the device.
unsigned int findDeviceInDriverList(AudioDeviceID deviceIDToFind)
{
    unsigned int driverIndex = 0;
    AudioDeviceID *allDeviceIDs = getAllDeviceIDs();
    
    if(allDeviceIDs == NULL)
        return 0;
        
    for(driverIndex = 0; driverIndex < numOfDevices; driverIndex++) {
        if(allDeviceIDs[driverIndex] == deviceIDToFind) {
            free(allDeviceIDs);
            return driverIndex;
        }
    }
    
    NSLog(@"Couldn't find the driver ID %x out of %d devices\n", deviceIDToFind, numOfDevices);
    free(allDeviceIDs);

    return 0; // Couldn't find it, default to the first
}

AudioDeviceID deviceIDOfDriverIndex(unsigned int driverIndexToFind)
{
    AudioDeviceID deviceIDToFind;
    AudioDeviceID *allDeviceIDs = getAllDeviceIDs();
    
    if(allDeviceIDs == NULL)
        return 0;
        
    deviceIDToFind = allDeviceIDs[driverIndexToFind];
    free(allDeviceIDs);
    return deviceIDToFind;
}

////////////////////////////////////////////////////////////////////////////////
// isDeviceRunning
////////////////////////////////////////////////////////////////////////////////

static BOOL isDeviceRunning(AudioDeviceID deviceID, BOOL isInput)
{
    UInt32 running = 0;

    /* check the device is running */
    if(!getDeviceProperty(deviceID, isInput, kAudioDevicePropertyDeviceIsRunning, &running, sizeof(running))) {
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
                                      BOOL isInput)
{
#if DEBUG_DESCRIPTION
    char    deviceName[1024];

    if(!getDeviceProperty(deviceID, isInput, kAudioDevicePropertyDeviceName, deviceName, sizeof(deviceName))) {
        return FALSE;
    }
        
    NSLog(@"Devicename: %s\n", deviceName);
#endif

    if(!getDeviceProperty(deviceID, isInput, kAudioDevicePropertyStreamFormat, audioStreamBasicDescription, sizeof(AudioStreamBasicDescription))) {
        return FALSE;
    }

#if DEBUG_DESCRIPTION
    NSLog(@"device ID: %d\n", (unsigned int) deviceID);
    dumpStreamDescription(audioStreamBasicDescription);
#endif
    
#if 0
    // check to see if the sample rate is changeable... TODO this could be used to change the hardware rather than resampling.
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput,
                                          kAudioDevicePropertyRateScalar,
                                          &propertySize, &propertyWritable);
    NSLog(@"AudioDeviceGetPropertyInfo kAudioDevicePropertyRateScalar  CAstatus:%s, propertySize = %ld, propertyWritable = %d\n",
	    getCoreAudioErrorStr(CAstatus), propertySize, propertyWritable);
#endif

    // TODO check kAudioDevicePropertyLatency
    	
    return TRUE;
}

// Retrieves the configuration of how many channels are situated within each stream.
// We use this to determine if the device is producing or consuming interleaved or non-interleaved buffers.
static BOOL getStreamChannelConfiguration(AudioDeviceID deviceID, BOOL isInput)
{
    AudioBufferList *streamConfigurationList;
    AudioStreamID *streamIdentifiers;
    OSStatus CAstatus;
    UInt32 propertySize;
    Boolean propertyWritable;
    int streamIndex;
    int maxChannelsPerStream = 0;
    // int streamIDIndex;
    
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput, kAudioDevicePropertyStreamConfiguration, &propertySize, &propertyWritable);
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreamConfiguration %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
    if((streamConfigurationList = (AudioBufferList *) malloc(propertySize)) == NULL) {
	NSLog(@"Unable to malloc streamConfigurationList\n");
	return FALSE;
    }
    
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyStreamConfiguration, &propertySize, streamConfigurationList);	
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreamConfiguration returned %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
#if DEBUG_DESCRIPTION
    NSLog(@"streamConfigurationList number of streams %d\n", streamConfigurationList->mNumberBuffers);
#endif
    for(streamIndex = 0; streamIndex < streamConfigurationList->mNumberBuffers; streamIndex++) {
#if DEBUG_DESCRIPTION
	NSLog(@"stream %d holds %d channels\n", streamIndex, streamConfigurationList->mBuffers[streamIndex].mNumberChannels);
#endif
	if(streamConfigurationList->mBuffers[streamIndex].mNumberChannels > maxChannelsPerStream)
	    maxChannelsPerStream = streamConfigurationList->mBuffers[streamIndex].mNumberChannels;
    }
    
    interleavedChannels = streamConfigurationList->mNumberBuffers <= 1 || maxChannelsPerStream > 1;
#if DEBUG_DESCRIPTION
    NSLog(@"interleavedChannels = %d\n", interleavedChannels);
#endif
    
    CAstatus = AudioDeviceGetPropertyInfo(deviceID, 0, isInput, kAudioDevicePropertyStreams, &propertySize, &propertyWritable);
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreams %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
    if((streamIdentifiers = (AudioStreamID *) malloc(propertySize)) == NULL) {
	NSLog(@"Unable to malloc streamConfigurationList\n");
	return FALSE;
    }
    numberOfStreams = propertySize / sizeof(AudioStreamID);
    
    CAstatus = AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyStreams, &propertySize, streamIdentifiers);	
    if (CAstatus) {
	NSLog(@"kAudioDevicePropertyStreams returned %s\n", getCoreAudioErrorStr(CAstatus));
	return FALSE;
    }
    
// If I understand the CoreAudio documentation, starting channel should be the device channel each stream begins with.
// Yet the values returned are always 1, hmm...
#if 0    
    for(streamIDIndex = 0; streamIDIndex < numberOfStreams; streamIDIndex++) {
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
    
    return TRUE;
}


// Determine which AudioStreams of the AudioDevice should be serviced by our IOProc.
// If a stream is marked as not being used, the given IOProc will see a corresponding NULL buffer
// pointer in the AudioBufferList passed to it's IO proc.
static BOOL getAudioStreamsToVend(AudioDeviceID deviceID,
				  AudioHardwareIOProcStreamUsage **ioProcStreamUsage,
				  void *ioProc,
				  BOOL isInput)
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

    // Indicate which ioProc to retrieve stream usage information for.
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

#if 0 // disable not need since we no longer turn off all but the first stream.
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
	    NSLog(@"setting ioProcStreamUsage->mStreamIsOn[%d] to %ld\n", i, ioProcStreamUsage->mStreamIsOn[i]);
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
#endif

////////////////////////////////////////////////////////////////////////////////
// getBufferSize
////////////////////////////////////////////////////////////////////////////////

static long getBufferSize(AudioDeviceID deviceID, BOOL isInput)
{
    long currentBufferSizeInBytes;

    /* fetch the buffer size for informational purposes */
    if (!getDeviceProperty(deviceID, isInput, kAudioDevicePropertyBufferSize, &currentBufferSizeInBytes, sizeof(currentBufferSizeInBytes))) {
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
    if (!getDeviceProperty(deviceID, isInput, kAudioDevicePropertyBufferSize, &bufferSizeInBytes, sizeof(bufferSizeInBytes))) {
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

// Retrieve the channel assignments so we know which channels constitute left and right channels
static BOOL getSpeakerConfiguration(AudioDeviceID outputDeviceID)
{
    // unsigned char channelDescription[1024];
    UInt32 stereoChannels[2] = { 0, 1 }; // create defaults so we don't have problems if a device doesn't respond to the preferred channels property.
    int numOfChannels = 4;  // TODO hardwired
    // AudioChannelLayout channelLayout;
    
    if (!getDeviceProperty(outputDeviceID, false, kAudioDevicePropertyPreferredChannelsForStereo, &stereoChannels, sizeof(stereoChannels))) {
	// In case a device doesn't respond to preferred channels for stereo, we create a default.
	numOfChannels = 2;
    }
    
    // NSLog(@"Preferred channels for stereo Left = %d, Right = %d\n", stereoChannels[0], stereoChannels[1]);

#if 0
    // TODO determine multichannel layouts. 
    if (!getDeviceProperty(outputDeviceID, false, kAudioDevicePropertyPreferredChannelLayout, &channelLayout, sizeof(channelLayout))) {
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

BOOL setOutputDevice(AudioDeviceID outputDeviceID, BOOL setTheBufferSize)
{
#if DEBUG_DESCRIPTION
    NSLog(@"OUTPUT ===========\n");
#endif

    /* check the returned device */
    if (outputDeviceID == kAudioDeviceUnknown) {
        NSLog(@"setOutputDevice() outputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(!determineBasicDescription(outputDeviceID, &outputStreamBasicDescription, false)) {
        NSLog(@"setOutputDevice() - error determining basic description\n");
        return FALSE;
    }
    if(setTheBufferSize) {
	if(!setBufferSize(outputDeviceID, bufferSizeInBytes, NO)) {
	    NSLog(@"setOutputDevice() - error setting buffer size\n");
	    return FALSE;
	}
    }
    else
	bufferSizeInFrames = bufferSizeInBytes / outputStreamBasicDescription.mBytesPerFrame;

    if(!getSpeakerConfiguration(outputDeviceID)) {
	NSLog(@"couldn't retrieve speaker configuration\n");
	// return FALSE; // We should probably let this slide.
    }

#if CHECK_DEVICE_RUNNING_STATUS
    if(isDeviceRunning(outputDeviceID, false)) {
	NSLog(@"SNDInit() output device is already running... but this is ok in CoreAudio land\n");
    }
#endif

    if(!getStreamChannelConfiguration(outputDeviceID, false)) {
	NSLog(@"Couldn't retrieve output stream's channel configuration\n");
	// return FALSE; // We should probably let this slide.
    }
    
    return TRUE;
}

BOOL setInputDevice(AudioDeviceID inputDeviceID, BOOL setTheBufferSize)
{
#if DEBUG_DESCRIPTION
    NSLog(@"INPUT =========== inputDeviceID = %d\n", inputDeviceID);
#endif

    if (inputDeviceID == kAudioDeviceUnknown) {
        NSLog(@"setInputDevice() inputDeviceID is kAudioDeviceUnknown\n");
        return FALSE;
    }
    if(!determineBasicDescription(inputDeviceID, &inputStreamBasicDescription, true)) {
        NSLog(@"setInputDevice() - error determining basic setup\n");
        return FALSE;
    }
    if(setTheBufferSize) {
        if(!setBufferSize(inputDeviceID, bufferSizeInBytes, YES)) {
            NSLog(@"setInputDevice() - error setting buffer size\n");
            return FALSE;
        }
    }

#if CHECK_DEVICE_RUNNING_STATUS
    if(isDeviceRunning(inputDeviceID, true)) {
	NSLog(@"SNDInit() Input device is already running... but this is ok in CoreAudio land\n");
    }
#endif
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

    if(!retrieveDriverList(FALSE))
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
	CAstatus = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDefaultInputDevice, &propertySize, &propertyWritable);
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
        driverIndex = findDeviceInDriverList(outputDeviceID);  
    }
    else {
        NSLog(@"SNDInit() Didn't guess the device\n");
        driverIndex = 0;
    }

    if(!setOutputDevice(outputDeviceID, !guessTheDevice))
        return FALSE;

    inputInit = setInputDevice(inputDeviceID, YES);

    return TRUE;
}

// Shut down what we started up in SndInit();
PERFORM_API BOOL SNDTerminate(void)
{
    [inputLock release];
    inputLock = nil;
    initialised = FALSE;

    // CoreAudio doesn't need an explicit call to shut down/disengage/unreserve to our app.
    return YES;
}

// Returns an array of character pointers listing the names of each channel. There will be channel count number of strings returned, with a NULL terminated
// The naming is system dependent, but is guaranteed to have two
// channels named "Left" and "Right" to ensure that stereo can always be used.
PERFORM_API const char **SNDSpeakerConfiguration(void)
{
    speakerConfigurationList[0] = "Left";
    speakerConfigurationList[1] = "Right";
    speakerConfigurationList[2] = NULL;

    return (const char **) speakerConfigurationList;
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
        
        outputDeviceID = deviceIDOfDriverIndex(driverIndex);

        if(!setOutputDevice(outputDeviceID, NO))
            return FALSE;

        inputInit = setInputDevice(inputDeviceID, TRUE);
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
PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat, BOOL isOutputStream)
{
    AudioStreamBasicDescription *streamBasicDescription;
    
    if (!initialised)
	SNDInit(TRUE);
    
    streamBasicDescription = isOutputStream ? &outputStreamBasicDescription : &inputStreamBasicDescription;
    
    // The bytes per frame is implicitly set by the dataFormat value.
    streamFormat->dataFormat   = SND_FORMAT_FLOAT;
    // Number of channel independent sample frames in a buffer.
    streamFormat->frameCount   = bufferSizeInFrames;
    streamFormat->sampleRate   = streamBasicDescription->mSampleRate;
    // if it's a non-interleaved set of mono CoreAudio streams, count those, otherwise count the number of interleaved channels per frame.
    streamFormat->channelCount = interleavedChannels ? streamBasicDescription->mChannelsPerFrame : numberOfStreams;
    // Rather than setting the stream data explicitly NULL, we just leave it.
    // streamFormat->streamData = NULL;
#if 0
    NSLog(@"SNDStreamNativeFormat for %s frameCount %d sampleRate %lf channels %d\n", 
	  isOutputStream ? "output" : "input",
	  streamFormat->frameCount, streamFormat->sampleRate, streamFormat->channelCount);
#endif   
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
    if ((inputBuffer = (float *) malloc(bufferSizeInBytes)) == NULL) {
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
        NSLog(@"SNDStartStreaming: AudioDeviceAddIOProc returned %s for output\n", getCoreAudioErrorStr(CAstatus));
        r = FALSE;
    }
    if(!getAudioStreamsToVend(outputDeviceID, &outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, NO))
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
	    outputStreamIOProcUsage->mStreamIsOn[streamIndex] = NO;
    }
    
    if(!setAudioStreamsToVend(outputDeviceID, outputStreamIOProcUsage, vendOutputBuffersToStreamManagerIOProc, NO))
	return FALSE;
#endif

    if (inputInit) {
        CAstatus = AudioDeviceAddIOProc(inputDeviceID, vendInputBuffersToStreamManagerIOProc, NULL);
        if (CAstatus) {
            NSLog(@"SNDStartStreaming: AudioDeviceAddIOProc returned %s for input\n", getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
	if(!getAudioStreamsToVend(inputDeviceID, &inputStreamIOProcUsage, vendInputBuffersToStreamManagerIOProc, YES))
	    return FALSE;
    }
    if (r) { // all is well so far...
        CAstatus = AudioDeviceStart(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);
        if (CAstatus) {
            NSLog(@"SNDStartStreaming: AudioDeviceStart returned %s\n", getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
        if (inputInit) {
            CAstatus = AudioDeviceStart(inputDeviceID, vendInputBuffersToStreamManagerIOProc);
            if (CAstatus) {
                NSLog(@"SNDStartStreaming: AudioDeviceStart returned %s\n", getCoreAudioErrorStr(CAstatus));
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

    // Close input stream before closing the output streams.
    if (inputInit) {
        CAstatus = AudioDeviceStop(inputDeviceID, vendInputBuffersToStreamManagerIOProc);
        if (CAstatus) {
            NSLog(@"SNDStreamStop() input device stop returned: %s\n", getCoreAudioErrorStr(CAstatus));
            r = FALSE;
        }
	// Disable the input IOProc
	// CAstatus = AudioDeviceRemoveIOProc(inputDeviceID, vendInputBuffersToStreamManagerIOProc);  
        // if (CAstatus) {
        //    NSLog(@"SNDStreamStop() input IOProc removal returned: %s\n", getCoreAudioErrorStr(CAstatus));
        //    r = FALSE;
        // }
    }

    CAstatus = AudioDeviceStop(outputDeviceID, vendOutputBuffersToStreamManagerIOProc);

#if DEBUG_STARTSTOPMSG    
    NSLog(@"[SND] Begining stream shutdown...\n");
#endif    
    
    if (CAstatus) {
        NSLog(@"SNDStreamStop() output device stop returned %s\n", getCoreAudioErrorStr(CAstatus));
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
