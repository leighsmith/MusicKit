/*
  $Id$

  Description:
    Defines the C entry points for the DLL application.

    These routines emulate an internal SoundKit module.
    This is intended to hide all the operating system evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C SndKit interface rather this one...do yourself a favour, 
    learn ObjC - it's simple, its fun, its better than Java..

  Original Author: Leigh M. Smith, <leigh@tomandandy.com>, tomandandy music inc.

  10 July 1999, Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
/*
// $Log$
// Revision 1.1  2000/01/14 00:14:33  leigh
// Initial revision
//
*/

#include "PerformSoundPrivate.h"
#include "sounderror.h"

#ifdef __cplusplus
extern "C" {
#endif 


#define SQUAREWAVE_DEBUG 0
#define PADDING 3          // make sure this matches PADFORMAT changes below (including \0)
#define PADFORMAT "%s: %s"

// A linked list of sounds currently playing.
typedef struct _audioStream {
  int            playTag;    // the means to refer to this sound.
  BOOL           isPlaying;

  // We have to be careful copying a SNDSoundStruct as it has allocated unsigned char data that
  // is appended after the structure itself. The stucture doesn't actually include it.
  SNDSoundStruct *snd;

  // Number of samples per frame (frame = 1 or more channels per time instant) so we
  // can keep track of time inbetween GenAudio calls.
  int          sampleFramesGenerated; 
  int          sampleToPlay;

  SNDNotificationFun finishedPlayFun;
  SNDNotificationFun startedPlayFun;
  struct _audioStream *next;   // Link to other playing sounds.
} AudioStream;


// "class variables" 
static BOOL         initialised = FALSE;
static char         **driverList;
static unsigned int driverIndex = 0;
// text constants used in formatting the driver names.
static char         *directSoundPrefix = "DirectSound";
static char         *waveOutPrefix = "WaveOut";


// Takes a parameter indicating whether to guess the device to select.
// This allows us to hard code devices or use heuristics to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
PERFORM_API BOOL SNDInit(BOOL guessTheDevice)
{
    if(!initialised)
        initialised = TRUE;                   // SNDSetDriverIndex() needs to think we're initialised.

    return TRUE;
}


// Returns an array of strings listing the available drivers.
// Returns NULL if the driver names were unobtainable.
// The client application should not attempt to free the pointers.
// TODO return driverIndex by reference
PERFORM_API char **SNDGetAvailableDriverNames(void)
{
  // This needs to be called after initialising. TODO - probably should call the initialisation.
  if(!initialised)
    return NULL;
}


// Match the driverDescription against the driverList
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex)
{
  // This needs to be called after initialising.
  if(!initialised)
    return FALSE;
}

// Match the driverDescription against the driverList
PERFORM_API unsigned int SNDGetAssignedDriverIndex(void)
{
  return 0;
}

PERFORM_API void SNDGetVolume(float *left, float * right)
{
	// TODO
}

PERFORM_API void SNDSetVolume(float left, float right)
{
	// TODO
}

PERFORM_API BOOL SNDIsMuted(void)
{
	return FALSE; // TODO
}

PERFORM_API void SNDSetMute(BOOL aFlag)
{
	// TODO
}

// Routine to begin playback
PERFORM_API int SNDStartPlaying(SNDSoundStruct *soundStruct, 
								   int tag, int priority,  int preempt, 
								   SNDNotificationFun beginFun, SNDNotificationFun endFun)
{
  if(!initialised)
		return SND_ERR_NOT_RESERVED;  // invalid sound structure.
 
  if(soundStruct->magic != SND_MAGIC)
      return SND_ERR_CANNOT_PLAY; // probably SND_ERROR_NOT_SOUND is more descriptive, but this matches SoundKit specs.

  return SND_ERR_NONE;
}


PERFORM_API int SNDStartRecording(SNDSoundStruct *soundStruct, 
									 int tag, int priority, int preempt, 
									 SNDNotificationFun beginRecFun, SNDNotificationFun endRecFun)
{
	return FALSE; // TODO
}

 
PERFORM_API int SNDSamplesProcessed(int tag)
{
    return -1;
}

// Routine to stop
PERFORM_API void SNDStop(int tag)
{
}

PERFORM_API void SNDPause(int tag)
{
}

PERFORM_API void SNDResume(int tag)
{
// TODO - surely there is a AudOut equivalent?
}

PERFORM_API int SNDUnreserve(int dunno)
{
	return 0;
}

PERFORM_API void SNDTerminate(void)
{
}

#ifdef __cplusplus
}
#endif
