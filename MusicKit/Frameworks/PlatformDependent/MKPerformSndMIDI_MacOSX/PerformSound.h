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
  Revision 1.6  2001/03/08 18:43:29  leigh
  Cleanup of includes

  Revision 1.5  2001/02/12 17:41:19  leigh
  Added streaming support

  Revision 1.4  2001/02/11 22:51:00  leigh
  First draft of simplistic working sound playing using CoreAudio

  Revision 1.3  2000/10/29 06:07:51  leigh
  Made BOOL typedef compatible with the standard.

  Revision 1.2  2000/05/05 22:43:56  leigh
  ensure we don't have boolean constants predefined

  Revision 1.1  2000/03/11 01:42:19  leigh
  Initial Release

*/

#define PERFORM_API 

#include <objc/objc.h> // for BOOL
#include "SndStruct.h"
#include "SndFormats.h"

#ifdef __cplusplus
extern "C" {
#endif 

typedef int (*SNDNotificationFun)(SndSoundStruct *s, int tag, int err);
typedef struct SNDStreamBuffer {
    SndSoundStruct streamFormat;
    void *streamData;
} SNDStreamBuffer;

// in and out are with respect to the audio hardware, i.e out == play
typedef void (*SNDStreamProcessor)(double sampleTime, SNDStreamBuffer *inStream, SNDStreamBuffer *outStream, void *userData);

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

PERFORM_API BOOL SNDStreamStart(SNDStreamProcessor newStreamProcessor, void *userData);

PERFORM_API BOOL SNDStreamStop(void);

#ifdef __cplusplus
}
#endif

