/*
  $Id$
  Description:
    This is basically a bare-bones duplicate of NeXT/Apples' performsound module
    functionality. Compilable with VC++ 6.0 and typically for interface with 
    Objective C routines, in particular, the SndKit.

    Only C functions are exported to avoid different C++ name mangling between VC++ and gcc

  Original Author: Leigh Smith <leigh@tomandandy.com>

  Copyright (C) 1999 Permission is granted to use this code for commercial and
  non-commercial purposes so long as this copyright statement (noting the author) is
  preserved.
*/
/*
  $Log$
  Revision 1.1  2001/07/02 22:03:48  sbrandon
  - initial revision. Still a work in progress, but does allow the MusicKit
    and SndKit to compile on GNUstep.

  Revision 1.2  2001/05/12 08:51:48  sbrandon
  - various header importing changes
  - added some gsdoc comments from the MacOSX framework
  - added SNDStream function declarations from the MacOSX framework

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version

  Revision 1.2  1999/07/21 19:19:42  leigh
  Single Sound playback working
*/

#ifndef __PERFORMSOUND__
#define __PERFORMSOUND__

#define PERFORM_API 

// these don't seem to be defined anywhere standard - probably they
// are in GnuStep
//typedef int BOOL;
#ifndef FALSE
#define FALSE 0
#define TRUE !(FALSE)
#endif
#include <objc/objc.h>

#include <stdlib.h> // for NULL definition
#include "SndStruct.h"
#include "SndFormats.h"

#ifdef __cplusplus
extern "C" {
#endif 

/*!
    @typedef SNDNotificationFun
    @param s
    @param tag
    @param err
    @result
*/
typedef int (*SNDNotificationFun)(SndSoundStruct *s, int tag, int err);

/*!
    @typedef SNDStreamBuffer
    @abstract Describes the format and the data in a limited length buffer used operating a stream.
    @field streamFormat The format describing sample rate, number of channels etc. The field offset
                        is not used since the streamData pointer can be used to refer to non-contiguous
                        data.
    @field streamData A pointer to the data itself. 
*/
typedef struct SNDStreamBuffer {
    SndSoundStruct streamFormat;
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
    @defined SND_NULL_FUN
    @discussion Indicates no function is to be called.
*/

#define SND_NULL_FUN ((SNDNotificationFun)0)

PERFORM_API BOOL SNDInit(BOOL guessTheDevice);

// retrieve a list of available driver descriptions
PERFORM_API char **SNDGetAvailableDriverNames(void);

// assign currently active driver
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex);

// return the index into driverList currently selected.
PERFORM_API unsigned int SNDGetAssignedDriverIndex(void);

PERFORM_API void SNDGetVolume(float *left, float * right);

PERFORM_API void SNDSetVolume(float left, float right);

PERFORM_API BOOL SNDIsMuted(void);

PERFORM_API void SNDSetMute(BOOL aFlag);

PERFORM_API int SNDStartPlaying(SndSoundStruct *soundStruct, int tag, int priority,  int preempt, 
  SNDNotificationFun beginFun, SNDNotificationFun endFun);

PERFORM_API int SNDStartRecording(SndSoundStruct *soundStruct, int tag, int priority, int preempt, 
  SNDNotificationFun beginRecFun, SNDNotificationFun endRecFun);
 
PERFORM_API int SNDSamplesProcessed(int tag);

PERFORM_API void SNDStop(int tag);

PERFORM_API void SNDPause(int tag);

PERFORM_API void SNDResume(int tag);

PERFORM_API int SNDUnreserve(int dunno);

PERFORM_API void SNDTerminate(void);

PERFORM_API void SNDStreamNativeFormat(SndSoundStruct *streamFormat);

/*!
    @function       SNDStreamStart
    @abstract       .
    @param          newStreamProcessor
                        .
    @param          userData
                        
    @result         Returns YES if ?, NO if ?.
*/
PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *userData);

/*!
    @function       SNDStreamStop 
    @abstract       .
    @result         Returns YES if ?, NO if ?.
*/
PERFORM_API BOOL SNDStreamStop(void);


#ifdef __cplusplus
}
#endif

#endif
