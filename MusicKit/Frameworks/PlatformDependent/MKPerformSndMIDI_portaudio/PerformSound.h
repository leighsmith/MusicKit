/*
  $Id$
  Description:
    This is basically a bare-bones duplicate of NeXT/Apples' performsound module
    functionality using the PortAudio library. Compilable with VC++
    6.0 or MinGW and typically for interface with Objective C
    routines, in particular, the SndKit.

    Only C functions are exported to avoid different C++ name mangling between VC++ and gcc

  Original Author: Leigh Smith <leigh@leighsmith.com>

  Copyright (C) 1999 Permission is granted to use this code for commercial and
  non-commercial purposes so long as this copyright statement (noting the author) is
  preserved.
*/

#ifndef __PERFORMSOUND__
#define __PERFORMSOUND__

/* We #include this file regardless of the setting of
   HAVE_CONFIG_H so that other applications compiling against this
   header don't have to define it. If you are seeing errors for
   MKPerformSndMIDIConfig.h not found, you haven't run ./configure 
 */
#include "MKPerformSndMIDIConfig.h"
#include <objc/objc.h> // for BOOL

/* these don't seem to be defined anywhere standard - probably they
   are in GnuStep */
#ifndef FALSE
#define FALSE 0
#define TRUE !(FALSE)
#endif

#if STDC_HEADERS
# include <stdlib.h> // for NULL definition
#endif
#include "SndStruct.h"
#include "SndFormats.h"

#define MKPERFORMSND_USE_STREAMING       1  // Uses the newer streaming API

#ifdef __cplusplus
extern "C" {
#endif 

/*!
  @brief Describes the format and the data in a limited length buffer used for operating on a stream.
*/
typedef struct SNDStreamBuffer {
    /*! dataFormat The format describing the number of bytes for one sample and it's format, signed, float etc. */
    SndSampleFormat dataFormat;
    /*! frameCount The number of sample frames (i.e channel independent) in the buffer. */
    long frameCount;
    /*! channelCount The number of channels. */
    int channelCount;
    /*! The sampling rate in Hz. */
    double sampleRate;
    /*! A pointer to the data itself. */
    void *streamData;
} SNDStreamBuffer;

/*!
  @typedef SNDStreamProcessor
  @brief The descriptors "in" and "out" are with respect to the audio hardware, i.e out == play
  @param sampleTime The time the buffer will be played in seconds.
  @param inStream Pointer to a SNDStreamBuffer containing the received sample data.
  @param outStream Pointer to a SNDStreamBuffer containing the sample data to be played.
  @param userData An untyped pointer to data supplied when calling SNDStreamStart().
*/
typedef void (*SNDStreamProcessor)(double sampleTime, SNDStreamBuffer *inStream, SNDStreamBuffer *outStream, void *userData);

/*!
  @function       SNDInit
  @brief       Initialise the Sound hardware.
  @param          guessTheDevice
  Indicates whether to guess the device to select using the system default.
  
  The <tt>guessTheDevice</tt> parameter allows hard coding devices or using heuristics
  to prevent the user having to always select the best device to use.
  Whether guessing or not, a driver is still initialised.
  @return         Returns a YES if initialised correctly, NO if unable to initialise the device,
  such as an unavailable sound interface.
*/
PERFORM_API BOOL SNDInit(BOOL guessTheDevice);

/*!
  @function       SNDTerminate
  @brief       Terminate the connection to the Sound hardware initialised with SNDInit.
  @return         Returns YES if terminated correctly, NO if unable to terminate the device,
  such as an unavailable sound interface.
 */
PERFORM_API BOOL SNDTerminate(void);

/*!
  @function       SNDGetAvailableDriverNames
  @brief          Retrieve a list of available driver descriptions.
  @param	  outputDrivers Set to YES to retrieve only names of output drivers, NO to retrieve only names of input drivers.
  @return         Returns a NULL terminated array of readable strings of each driver's name.
*/
PERFORM_API const char **SNDGetAvailableDriverNames(BOOL outputDrivers);

/*!
  @function       SNDSetDriverIndex
  @brief          Assign currently active driver.
  @param          selectedIndex The 0 base index into the driver table returned by SNDGetAvailableDriverNames
  @param	  outputDrivers Set to YES to set the assigned driver index of output drivers only, NO to set the index of input drivers only.
  @return         Returns YES if able to set the index, no if unable (for example selectedIndex out of bounds).
*/
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex, BOOL outputDrivers);

/*!
  @function       SNDGetAssignedDriverIndex
  @brief          Return the index into driverList currently selected.
  @param	  outputDrivers Set to YES to retrieve the assigned driver index of output drivers only, NO to retrieve the index of input drivers only.
  @return         Returns the index (0 base).
*/
PERFORM_API unsigned int SNDGetAssignedDriverIndex(BOOL outputDrivers);

/*!
  @function       SNDIsMuted
  @brief       Determine if the currently playing sound is muted.
  @return         Returns YES if the currently playing sound is muted.
*/
PERFORM_API BOOL SNDIsMuted(void);

/*!
  @function       SNDSetMute
  @brief       Mute or unmute the currently playing sound..
  @param          muted YES to mute, NO to unmute.
*/
PERFORM_API void SNDSetMute(BOOL muted);

/*!
  @function       SNDSetBufferSizeInBytes
  @brief          Changes the buffer size used for input or output.
  @param          newBufferSizeInBytes  Number of bytes in buffer. 
  @param          forOutputDevices TRUE to change the output buffer size, FALSE to change the input buffer size.

  Note that current implementation uses stereo float output buffers, which therefore take
  8 bytes per sample frame.
*/
PERFORM_API BOOL SNDSetBufferSizeInBytes(long newBufferSizeInBytes, BOOL forOutputDevices);

/*!
  @function       SNDGetBufferSizeInBytes
  @brief          Returns the buffer size used for input or output in bytes.
  @param          forOutputDevices TRUE to return the output buffer size, FALSE to return the input buffer size.
  @return	  Returns buffer size in bytes, or 0 if unable to retrieve the buffer size.
 
  Note that current implementation uses stereo float output buffers, which therefore take
  8 bytes per sample frame.
 */
PERFORM_API long SNDGetBufferSizeInBytes(BOOL forOutputDevices);

/*!
  @function       SNDStreamNativeFormat
  @brief       Return in the SNDStreamBuffer, the format of the sound data preferred by the operating system.
  @param          streamFormat Pointer to an allocated block of memory into which to put the SNDStreamBuffer format parameters.
  @param          isOutputStream YES if the stream is for output, i.e. playback, NO if the stream is for input, i.e. recording.
  
  Does not set streamData field of SNDStreamBuffer structure.
 */
PERFORM_API void SNDStreamNativeFormat(SNDStreamBuffer *streamFormat,
				       BOOL isOutputStream);

/*!
  @function       SNDGetLatency
  @brief          Returns the latency of the input or output stream in seconds.
  @param          forOutputDevices TRUE to return the output latency, FALSE to return the input latency.
  @return	  Returns latency in seconds, or 0 if unable to retrieve the latency measure.
 */
PERFORM_API float SNDGetLatency(BOOL forOutputDevices);

/*!
  @function       SNDStreamStart
  @brief       Starts the streaming.
  @param          newStreamProcessor Pointer to the function call-back for sending and receiving stream buffers.
  @param          userData Any parameter to be passed back in the call-back function parameter list.
  @return         Returns YES if streaming was able to start, NO if there was some problem starting streaming.
 */
PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *userData);

/*!
  @function       SNDStreamStop
  @brief       Stops the streaming.
  @return         Returns YES if streaming was able to be stopped, NO if there was some problem stopping streaming.
 */
PERFORM_API BOOL SNDStreamStop(void);

/*!
  @function SNDSpeakerConfiguration
  @brief Returns an array of strings describing each audio channel's speaker assignment.
  @return Returns an array of character pointers, with NULL terminating
  the list.
 */
PERFORM_API const char **SNDSpeakerConfiguration(void);

#ifdef __cplusplus
}
#endif

#endif
