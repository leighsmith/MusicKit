/* 
  $Id$
  Description:
    MusicKit DirectMusic access routines.

    These routines emulate the functions of the MusicKit Mach MIDI driver.
    This is intended to hide all the Windows evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C MusicKit interface rather this one...do yourself a favour, 
    learn ObjC - it's simple, its fun, its better than Java...

    Despite this being an emulation of a device driver, the access routines are a
    pretty high-level interface which gives you an idea of how right the NeXT engineers
    got it, way back in 1989, considering the NeXT MIDI device driver was a 
    network transparent device driver that didn't require god-awful CLSIDs.

    "The problem with Microsoft is they just have no taste" (S. Jobs)

    Why this library even exists at all:
  
    1. It seems that only the DirectMusic, not DirectMusicPort and DirectMusicBuffer
    interfaces have been registered, so it does not seem possible to use COM via the
    OpenStep ActiveX.framework (assuming it works) to talk to the _core_ DirectMusic layer.
    Even if did, it would require any other system (such as mi_d) to use this library would
    need to use the Apple frameworks, which is nearly as bad as having to use MS API, but
    twice as bad if you have to have both development systems to compile this!

    2. It remains to be determined if Apple's ActiveX.framework has been stress tested 
    dealing with 200ms duration MIDI buffers.
  
    3. We only export C function names (not C++) to allow linking against gcc as
    name mangling - "decorating" in MS jargon - differs between the compilers.

  Original Author: Leigh M. Smith, tomandandy <leigh@tomandandy.com>

  30 July 1999, Copyright (c) 1999 tomandandy.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.

  Just to cover my ass: DirectMusic and DirectX are registered trademarks
  of Microsoft Corp and they can have them.
*/
/*
 $Log$
 Revision 1.2  2000/01/03 20:38:38  leigh
 comments improved

 Revision 1.1.1.1  1999/11/17 17:57:14  leigh
 Initial working version

*/
// #define FUNCLOG 1 // define this to log function calls to a text file.

#ifdef FUNCLOG
#include <stdio.h> // for fprintf and debug
#endif

#ifdef __cplusplus
extern "C" {
#endif 

int PMinitialise(void);

int PMGetAvailableQueueSize(int *size);

int PMPackMessageForPlay(REFERENCE_TIME time, unsigned char *channelMessage, int msgLength);

REFERENCE_TIME PMGetCurrentTime();

BOOL PMSetMIDIPortNum(int portNum);

BOOL PMSetMIDIPort(char *newPortDescription);

BOOL PMReleaseMIDIPortNum(int portNum);

int PMactivate(void);

int PMdeactivate(void);

int PMPlayBuffer(void);

int PMterminate(void);

int PMDownloadDLSInstruments(unsigned int *patchesToDownload, int patchesUsed);

const char **PMGetAvailableMIDIPorts(unsigned int *selectedPortIndexPtr);

#ifdef __cplusplus
}
#endif