/*
  $Id$
  Description:
    This is basically a bare-bones duplicate of NeXT/Apples' performsound module
    functionality.
 
  Original Author: Leigh Smith <leigh@tomandandy.com>

  Copyright (C) 1999 Permission is granted to use this code for commercial and
  non-commercial purposes so long as this copyright statement (noting the author) is
  preserved.
*/
/*!
    @header PerformSound
    
    @abstract This is basically a bare-bones duplicate of NeXT/Apples' performsound module functionality.
    It provides sound playback and recording, in either streaming (preferred) or single sound
    operation (where the operating system lacks streaming buffers). Streaming is controlled by the value
    of the MKPERFORMSND_USE_STREAMING macro.
    It draws inspiration (only) from Steinberg's ASIO.
    Compilable with VC++ 6.0 and typically for interface with
    Objective C routines, in particular, the SndKit.

    Only C functions are exported to avoid different C++ name mangling between VC++ and gcc.
*/

#ifndef __MKPERF_SND_MIDI_PERFORM_SOUND_H__
#define __MKPERF_SND_MIDI_PERFORM_SOUND_H__

/*!
    @defined PERFORM_API
    @discussion This allows us to introduce anything necessary for library declarations, namely for Windows. Unused in MacOS X.
*/
#define PERFORM_API 

#include <objc/objc.h> // for BOOL
#include "SndStruct.h"
#include "SndFormats.h"

#define MKPERFORMSND_USE_STREAMING       1  // Uses the newer streaming API

#ifdef __cplusplus
extern "C" {
#endif 

/*!
    @typedef SNDStreamBuffer
    @abstract Describes the format and the data in a limited length buffer used for operating on a stream.
    @field dataFormat The format describing the number of bytes for one sample and it's format, signed, float etc.
    @field frameCount The number of sample frames (i.e channel independent) in the buffer.
    @field channelCount The number of channels.
    @field sampleRate The sampling rate in Hz.
    @field streamData A pointer to the data itself. 
*/
typedef struct SNDStreamBuffer {
    SndSampleFormat dataFormat;
    long frameCount;
    int channelCount;
    double sampleRate;
    void *streamData;
} SNDStreamBuffer;

/*!
    @typedef SNDStreamProcessor
    @discussion The descriptors "in" and "out" are with respect to the audio hardware, i.e out == play
    @param sampleTime
    @param inStream
    @param outStream
    @param userData
*/
typedef void (*SNDStreamProcessor)(double sampleTime, SNDStreamBuffer *inStream, SNDStreamBuffer *outStream, void *userData);

/*!
    @function       SNDInit
    @abstract       Initialise the Sound hardware.
    @param          guessTheDevice
                        Indicates whether to guess the device to select using the system default.
    @discussion     The <tt>guessTheDevice</tt> parameter allows hard coding devices or using heuristics
                    to prevent the user having to always select the best device to use.
                    Whether guessing or not, a driver is still initialised.
    @result         Returns a YES if initialised correctly, NO if unable to initialise the device,
                    such as an unavailable sound interface.
*/
PERFORM_API BOOL SNDInit(BOOL guessTheDevice);

/*!
  @function       SNDTerminate
  @abstract       Terminate the connection to the Sound hardware initialised with SNDInit.
  @result         Returns YES if terminated correctly, NO if unable to terminate the device,
                  such as an unavailable sound interface.
 */
PERFORM_API BOOL SNDTerminate(void);

/*!
    @function       SNDGetAvailableDriverNames
    @abstract       Retrieve a list of available driver descriptions.
    @result         Returns a NULL terminated array of readable strings of each driver's name.
*/
PERFORM_API char **SNDGetAvailableDriverNames(void);

/*!
    @function       SNDSetDriverIndex
    @abstract       Assign currently active driver.
    @param          selectedIndex
                        The 0 base index into the driver table returned by SNDGetAvailableDriverNames
    @result         Returns YES if able to set the index, no if unable (for example selectedIndex out of bounds).
*/
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex);

/*!
    @function       SNDGetAssignedDriverIndex
    @abstract       Return the index into driverList currently selected.
    @result         Returns the index (0 base).
*/
PERFORM_API unsigned int SNDGetAssignedDriverIndex(void);

/*!
    @function       SNDIsMuted
    @abstract       Determine if all the sound output is muted.
    @result         Returns YES if the currently playing sound is muted.
*/
PERFORM_API BOOL SNDIsMuted(void);

/*!
    @function       SNDSetMute
    @abstract       Mute or unmute all sound output.
    @param          aFlag YES to mute, NO to unmute.
*/
PERFORM_API void SNDSetMute(BOOL aFlag);

/*!
    @function       SNDSetBufferSizeInBytes
    @abstract       Mute or unmute the currently playing sound..
    @param          liBufferSizeInBytes
                        Number of bytes in buffer. Note that current implementation
                        uses stereo float output buffers, which therefore take 8 bytes
                        per sample frame.
*/
PERFORM_API BOOL SNDSetBufferSizeInBytes(long liBufferSizeInBytes);

/*!
    @function SNDSpeakerConfiguration
    @abstract Returns an array of character pointers listing the names of each channel.
    @discussion There will be the same number of strings returned as the channel count, with a NULL terminating.
                The naming of all channels is system dependent, but is guaranteed to have two channels named
                "Left" and "Right" to ensure that stereo can always be used. On MacOS X, the naming is determined
                by the devices speaker configuration defined in the Audio/MIDI configuration application.
    @result Returns a constant array of strings (char *) with each string naming that channels speaker.
 */
PERFORM_API const char **SNDSpeakerConfiguration(void);

/*!
    @function       SNDStreamNativeFormat
    @abstract       Return in the SNDStreamBuffer, the format of the sound data preferred by the operating system.
    @param          streamFormat Pointer to an allocated block of memory into which to put the SNDStreamBuffer format parameters.
    @param          isOutputStream YES if the stream is for output, i.e. playback, NO if the stream is for input, i.e. recording.
    @discussion     Does not set streamData field of SNDStreamBuffer structure.
 */
PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat, BOOL isOutputStream);

/*!
    @function       SNDStreamStart
    @abstract       Starts the streaming.
    @param          newStreamProcessor Pointer to the function call-back for sending and receiving stream buffers.
    @param          userData Any parameter to be passed back in the call-back function parameter list.
    @result         Returns YES if streaming was able to start, NO if there was some problem starting streaming.
 */
PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *userData);

/*!
    @function       SNDStreamStop
    @abstract       Stops the streaming.
    @result         Returns YES if streaming was able to be stopped, NO if there was some problem stopping streaming.
 */
PERFORM_API BOOL SNDStreamStop(void);

#ifdef __cplusplus
}
#endif

#endif /*__MKPERF_SND_MIDI_PERFORM_SOUND_H__*/
