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
  Revision 1.1  2000/12/07 19:32:34  leigh
  Initial revision

  Revision 1.2  2000/05/05 22:43:56  leigh
  ensure we don't have boolean constants predefined

  Revision 1.1  2000/03/11 01:42:19  leigh
  Initial Release

  Revision 1.1.1.1  2000/01/14 00:14:34  leigh
  Initial revision

  Revision 1.1.1.1  1999/11/17 17:57:14  leigh
  Initial working version

  Revision 1.2  1999/07/21 19:19:42  leigh
  Single Sound playback working
*/

#define PERFORM_API 

// these don't seem to be defined anywhere standard - probably they
// are in GnuStep
typedef int BOOL;
#ifndef FALSE
#define FALSE 0
#define TRUE !(FALSE)
#endif

#include <stdlib.h> // for NULL definition
#include "soundstruct.h"

#ifdef __cplusplus
extern "C" {
#endif 

typedef int (*SNDNotificationFun)(SNDSoundStruct *s, int tag, int err);

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

PERFORM_API int SNDStartPlaying(SNDSoundStruct *soundStruct, int tag, int priority,  int preempt, 
  SNDNotificationFun beginFun, SNDNotificationFun endFun);

PERFORM_API int SNDStartRecording(SNDSoundStruct *soundStruct, int tag, int priority, int preempt, 
  SNDNotificationFun beginRecFun, SNDNotificationFun endRecFun);
 
PERFORM_API int SNDSamplesProcessed(int tag);

PERFORM_API void SNDStop(int tag);

PERFORM_API void SNDPause(int tag);

PERFORM_API void SNDResume(int tag);

PERFORM_API int SNDUnreserve(int dunno);

PERFORM_API void SNDTerminate(void);

#ifdef __cplusplus
}
#endif

