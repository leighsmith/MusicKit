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
    @abstract Describes the format and the data in a limited length buffer used operating a stream.
    @field streamFormat The format describing sample rate, number of channels etc. The field offset
                        is not used since the streamData pointer can be used to refer to non-contiguous
                        data.
    @field streamData A pointer to the data itself. 
*/
// TODO SndSoundStruct's days are numbered, we should replace streamFormat with each of the parameters we use as indicated below.
typedef struct SNDStreamBuffer {
    SndSoundStruct streamFormat;
    // SndSampleFormat dataFormat;
    // long frameCount;
    // int channelCount;
    // double sampleRate;
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
    @function       SNDStreamNativeFormat
    @abstract       Return in the struct the format of the sound data preferred by the operating system.
    @param          streamFormat Pointer to an allocated block of memory into which to put the SndSoundStruct
 */
// TODO this should take a SNDStreamBuffer *streamFormat parameter, when SndSoundStruct goes.
PERFORM_API void SNDStreamNativeFormat(SndSoundStruct *streamFormat);

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

#if !MKPERFORMSND_USE_STREAMING

/*!
    @typedef SNDNotificationFun
    @param s
    @param tag
    @param err
 */
typedef int (*SNDNotificationFun)(SndSoundStruct *s, int tag, int err);

/*!
    @defined SND_NULL_FUN
    @discussion Indicates no function is to be called.
*/
#define SND_NULL_FUN ((SNDNotificationFun)0)

/*!
    @function       SNDStartPlaying
    @abstract       .
    @discussion	    This function need not be implemented if sound streaming is supported.
    @param          soundStruct
                        .
    @param          tag
    @param          priority
    @param          preempt
    @param          beginFun
    @param          endFun
    @result         Returns .
*/
PERFORM_API int SNDStartPlaying(SndSoundStruct *soundStruct, int tag, int priority,  int preempt,
  SNDNotificationFun beginFun, SNDNotificationFun endFun);

/*!
    @function       SNDStartRecording
    @abstract       .
    @discussion	    This function need not be implemented if sound streaming is supported.
    @param          soundStruct
                        .
    @param          tag
    @param          priority
    @param          preempt
    @param          beginRecFun
    @param          endRecFun
    @result         Returns .
*/
PERFORM_API int SNDStartRecording(SndSoundStruct *soundStruct, int tag, int priority, int preempt,
  SNDNotificationFun beginRecFun, SNDNotificationFun endRecFun);

/*!
    @function       SNDSamplesProcessed
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to inspect.
    @result         Returns the number of samples processed.
*/
PERFORM_API int SNDSamplesProcessed(int tag);

/*!
    @function       SNDStop
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to stop.
*/
PERFORM_API void SNDStop(int tag);

/*!
    @function       SNDPause
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to pause.
*/
PERFORM_API void SNDPause(int tag);

/*!
    @function       SNDResume
    @abstract       .
    @param          tag
                        The integer tag indicating the sound to resume.
*/
PERFORM_API void SNDResume(int tag);

/*!
    @function       SNDUnreserve
    @abstract       .
    @param          dunno
                        .
    @result         Returns a .
*/
PERFORM_API int SNDUnreserve(int dunno);
#endif

#ifdef __cplusplus
}
#endif

#endif /*__MKPERF_SND_MIDI_PERFORM_SOUND_H__*/
