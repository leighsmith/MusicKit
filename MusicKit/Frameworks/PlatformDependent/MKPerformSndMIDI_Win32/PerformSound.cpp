/*
  $Id$

  Description:
    Defines the C entry points for the DLL application.

    These routines emulate an internal SoundKit module.
    This is intended to hide all the Windows evil behind a banal C function interface.
    However, it is intended that developers will use the higher level 
    Objective C SndKit interface rather this one...do yourself a favour, 
    learn ObjC - it's simple, its fun, its better than Java..

    Why this library even exists at all:
 
    1. We only export C function names (not C++) to allow linking against gcc as
       name mangling - "decorating" in MS jargon - differs between the compilers.
    2. The MMSYSTEM.DLL is a 16 bit DLL which has a different format and does not have the symbols
       we require to link against it directly.
    3. We could use COM via the OpenStep ActiveX.framework (assuming it works) to talk to
    DirectSound but some of the higher quality multichannel audio cards 
    (i.e the Event Darla/Gina/Layla) only have WaveOut/ASIO drivers.
    This will no doubt one day change where DirectSound is used by all and sundry.
    It remains to be determined if Apple's ActiveX.framework has been stress tested 
    dealing with multichannel audio.

  Original Author: Leigh M. Smith, <leigh@tomandandy.com>, tomandandy music inc.

  10 July 1999, Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
/*
// $Log$
// Revision 1.3  2000/01/03 20:33:26  leigh
// initialises the SND API before attempting to retrieve the DirectSound object
//
// Revision 1.2  1999/11/17 22:10:51  leigh
// Added the VS-1 audio routines into project
//
// Revision 1.1.1.1  1999/11/17 17:57:14  leigh
// Initial working version
//
// Revision 1.5  1999/07/24 23:20:17  leigh
// multiple channel DirectSound Playback
//
// Revision 1.4  1999/07/21 23:34:13  leigh
// Fixed startup not initialising audio, reduced buffers to 4
//
// Revision 1.3  1999/07/21 19:19:42  leigh
// Single Sound playback working
//
*/

#include "stdafx.h"
#include "dsound.h"
#include "PerformSoundPrivate.h"
// SKoT's combined WaveOut and DirectX routines.
#include "AudOutWO.h" // these should be in a standard place
#include "AudOutDX.h"
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
  BOOL	         dxmode;     // when using DirectSound mode
  CAudOutWO      *audioOutWO;
  CAudOutDX      *audioOutDX;

  // We have to be careful copying a SNDSoundStruct as it has allocated unsigned char data that
  // is appended after the structure itself. The stucture doesn't actually include it.
  SNDSoundStruct *snd;

  // Number of samples per frame (frame = 1 or more channels per time instant) so we
  // can keep track of time inbetween GenAudio calls.
  DWORD          sampleFramesGenerated; 
  DWORD          sampleToPlay;

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

static CAudOutWO    audioOutWO;
static CAudOutDX    audioOutDX;
static BOOL	        dxmode;     // when using DirectSound mode
static AudioStream  head;       // the first is statically allocated.

// Iterate through the linked list until we find the tag.
// Yep, exhaustive searches are inefficient. We should eventually replace this with
// a hashing function.
AudioStream *findStreamForTag(int tag)
{
  AudioStream *listPtr;

  // start at head of the linked list and traverse it.
  for(listPtr = &head; listPtr != NULL; listPtr = listPtr->next)
    if(listPtr->playTag == tag)
       return listPtr;
  return NULL;
}

// *** This is the audio generating function ***
// All it actually does is do convert the data stream to the float format and return.
// DirectSound Play_Buffer can do the same thing for us, but SKoT's code provides the
// opportunity to do low-latency synthesis at some later date. Other features like
// looping between markers and other funky manipulation become possible this way.
static void GenAudio(float** ppfBuffer, DWORD dwLen, DWORD channelsToPlay, DWORD audStreamPtr)
{
/*
	float *left  = ppfBuffer[0]; 
	float *right = ppfBuffer[1];
	float pan    = 1;
	float ipan   = 1 - pan;
*/
  float mixedSample;
	int bytesPerSample;
	DWORD byteToPlayFrom;
	DWORD channel;
  unsigned char *grabDataFrom;
  signed short sampleWord;
  AudioStream *playing = (AudioStream *) audStreamPtr;
  SNDSoundStruct *snd = playing->snd;

	bytesPerSample = 2; // TODO assume its a short (2 byte / WORD format) needs checking dataFormat.
	
  // we do each sample individually so we have the option of mixing using floating point.
	for (DWORD sampBufferIndex = 0; sampBufferIndex < dwLen; sampBufferIndex++) {
    if(playing->isPlaying)  // we can arrive here trying to play a finished sample, if so just play silence.
      playing->sampleToPlay = playing->sampleFramesGenerated * snd->channelCount;
		for(channel = 0; channel < channelsToPlay; channel++) {
			byteToPlayFrom = playing->sampleToPlay * bytesPerSample;
      if(playing->isPlaying) {
        // check if the sound has been played to the end.
        if(byteToPlayFrom < (unsigned) snd->dataSize) {
          grabDataFrom = (unsigned char *) snd + snd->dataLocation + byteToPlayFrom;
          // obtain data from big-endian ordered words
          sampleWord = (((signed short) grabDataFrom[0]) << 8) + (grabDataFrom[1] & 0xff);
          mixedSample = sampleWord / 32768.0f;  // make a float, do any other sounds, normalize and then write it.
#if SQUAREWAVE_DEBUG
          if (playing->sampleFramesGenerated % 44 > 22) {
            mixedSample = 0.4f;
          }
          else {
            mixedSample = -0.4f;
          }
#endif
        }
        else {
          mixedSample = 0.0f;   // if at end of sound, play silence
          // Signal back to the rest of the world that we've finished playing the sound.
          if(playing->finishedPlayFun != SND_NULL_FUN && playing->isPlaying) {
            // Mark this sound as finished, but its up to the delegate to stop things?
            (*(playing->finishedPlayFun))(snd, playing->playTag, SND_ERR_NONE);
          }
          playing->isPlaying = FALSE;
        }
      }
      else {
        mixedSample = 0.0f;
      }
      ppfBuffer[channel][sampBufferIndex] = mixedSample;  // * pan;
      if(snd->channelCount != 1)	// play mono by sending same sample to both channels
        playing->sampleToPlay++;
    }
		playing->sampleFramesGenerated++; // This is number of samples per time-frame.
	}
}

// Iterate through the possible devices and build a formatted list.
// We determine the names from the AudOut subclasses, and annotate the names with a prefix 
// to indicate if it's DirectSound or not. The application can prune the list as needed.
// A NULL char * terminates the list a la argv behaviour.
static void retrieveDriverList(void)
{
  char *devName;
  DWORD directSoundIndex;
  DWORD waveIndex;
  int driverIndex = 0;

  driverList = (char **) malloc(sizeof(char *) * (audioOutDX.NumDev() + audioOutWO.NumDev() + 1));

	// DirectSound seems to be the latest new world order by dear MS, so try that first
	for (directSoundIndex = 0; directSoundIndex < audioOutDX.NumDev(); directSoundIndex++) {
		devName = audioOutDX.GetDevName(directSoundIndex);
    driverList[driverIndex] = (char *) malloc(strlen(devName) + strlen(directSoundPrefix) + PADDING);
    sprintf(driverList[driverIndex], PADFORMAT, directSoundPrefix, devName);
    driverIndex++;
	}
  for (waveIndex = 0; waveIndex < audioOutWO.NumDev(); waveIndex++) {
    devName = audioOutWO.GetDevName(waveIndex);
    driverList[driverIndex] = (char *) malloc(strlen(devName) + strlen(waveOutPrefix) + PADDING);
    sprintf(driverList[driverIndex], PADFORMAT, waveOutPrefix, devName);
    driverIndex++;
  }
  driverList[driverIndex] = NULL;
}

// Guess the device. Actually all we do for now is search through the list to find our
// recommended favourite first. Otherwise we revert to the first one. If DirectSound
// is enabled this will be the Primary Buffer, otherwise it will be the first WaveOut
// device.
static int guessDevice(char **driverList)
{
  char favourite[100];
  int driverIndex;

  // note! ensure both the prefix and favourite match
  sprintf(favourite, PADFORMAT, directSoundPrefix, "DirectSound (SB Live! Wave Out [4020])");

  for (driverIndex = 0; driverList[driverIndex] != NULL; driverIndex++) { 
    if(strcmp(driverList[driverIndex], favourite) == 0)
      return driverIndex;
  }
  return 0;
}

// Takes a parameter indicating whether to guess the device to select.
// This allows us to hard code devices or use heuristics to prevent the user
// having to always select the best device to use.
// If we guess or not, we still do get a driver initialised.
PERFORM_API BOOL SNDInit(BOOL guessTheDevice)
{
	if(!initialised) {
    head.next = NULL;
		dxmode = FALSE;  // by default don't do DirectSound until we know it will work.

    // WaveOut initialisation
		if (!audioOutWO.Initialise(GenAudio,0)) {
      AfxMessageBox("Error initialising WaveOut: " + audioOutWO.GetErrMsg());
			return FALSE;
		}
    // DirectSound initialisation
		if (!audioOutDX.Initialise(GenAudio,0)) {
			AfxMessageBox("Error initialising DirectSound: " + audioOutDX.GetErrMsg());
			return FALSE;
		}
    retrieveDriverList();

    if(guessTheDevice)
      driverIndex = guessDevice(driverList);
    else
      driverIndex = 0;

    // we probably need to decide these parameters based on our guessing.
#if 0
    if(!audioOutWO.SetAudThreadPriority(CAudOut.audpriorityHighest)) {
      AfxMessageBox("Unable to set WO thread priority");
      return FALSE;
    }
    if(!audioOutDX.SetAudThreadPriority(CAudOut.audpriorityHighest)) {
      AfxMessageBox("Unable to set DX thread priority");
      return FALSE;
    }
#endif
    initialised = TRUE;                   // SNDSetDriverIndex() needs to think we're initialised.
    SNDSetDriverIndex(driverIndex);       // Either set to our favourite or the first one which will
                                          // typically be DirectSound: Primary Sound Device.
	}
	return TRUE;
}


// Returns the DirectSound object, principally so DirectMusic can cooperate with it,
// per the DirectMusic::SetDirectSound method. Since we initialise the DirectSound whether we use it
// or not, for now we return it regardless of dxmode. The problem is dxmode is set when we are about
// to begin playing. Really we should check If we are not using DirectSound, NULL is returned.
LPDIRECTSOUND SNDGetDirectSound(void)
{
  if(!initialised) {
    SNDInit(TRUE);
  }
  return audioOutDX.GetDirectSound();
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
  else
    return driverList;
}


// Match the driverDescription against the driverList
PERFORM_API BOOL SNDSetDriverIndex(unsigned int selectedIndex)
{
  // This needs to be called after initialising.
  if(!initialised)
    return FALSE;
  else if(selectedIndex >= 0 && selectedIndex < (audioOutWO.NumDev() + audioOutDX.NumDev())) {
    driverIndex = selectedIndex;
    return TRUE;
  }
  return FALSE;
}

// Match the driverDescription against the driverList
PERFORM_API unsigned int SNDGetAssignedDriverIndex(void)
{
  return driverIndex;
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
  AudioStream *newChannel;
  AudioStream *listPtr;

  // find the end of the linked list.
  for(listPtr = &head; listPtr->next != NULL; listPtr = listPtr->next)
    ;

  if(!initialised)
		return SND_ERR_NOT_RESERVED;  // invalid sound structure.
 
  if(soundStruct->magic != SND_MAGIC)
      return SND_ERR_CANNOT_PLAY; // probably SND_ERROR_NOT_SOUND is more descriptive, but this matches SoundKit specs.

  // Allocate and retain a copy of the sound structure in an array playingSounds,
  // accessed by tag.
  newChannel = (AudioStream *) malloc(sizeof(AudioStream));
  listPtr->next = newChannel;
  newChannel->playTag = tag;
  newChannel->snd = soundStruct;
  newChannel->sampleFramesGenerated = 0;
  newChannel->sampleToPlay = 0;
  newChannel->startedPlayFun = beginFun;
  newChannel->finishedPlayFun = endFun;
  newChannel->isPlaying = TRUE;
  newChannel->next = NULL;

  newChannel->dxmode = driverIndex < audioOutDX.NumDev();

  if (!newChannel->dxmode) {
    // WaveOut initialisation  
    newChannel->audioOutWO = new CAudOutWO();
    if (!newChannel->audioOutWO->Initialise(GenAudio, (DWORD) newChannel)) {
      AfxMessageBox("Error initialising WO: " + newChannel->audioOutWO->GetErrMsg());
      return FALSE;
	  }
    newChannel->audioOutWO->SetCurDev((short) (driverIndex - audioOutDX.NumDev()));
    if (!newChannel->audioOutWO->IsActive())
      if (!newChannel->audioOutWO->Start())
        AfxMessageBox(newChannel->audioOutWO->GetErrMsg());
  }
  else {
    // DirectSound initialisation
    newChannel->audioOutDX = new CAudOutDX;
    if (!newChannel->audioOutDX->Initialise(GenAudio, (DWORD) newChannel)) {
      AfxMessageBox("Error initialising DX: " + newChannel->audioOutDX->GetErrMsg());
      return FALSE;
    }
    newChannel->audioOutDX->AllocateBuffers(4, 2048);
    newChannel->audioOutDX->SetCurDev((short) driverIndex);
    if (!newChannel->audioOutDX->IsActive())
      if (!newChannel->audioOutDX->Start())
        AfxMessageBox(newChannel->audioOutDX->GetErrMsg());
  }
  // this probably should be fired when GenAudio is first called, but that would still incur
  // a latency as GenAudio only indicates when the code is being synthesised, not played.
  if(newChannel->startedPlayFun != SND_NULL_FUN)
    (*(newChannel->startedPlayFun))(newChannel->snd, newChannel->playTag, SND_ERR_NONE);

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
  AudioStream *audStream = findStreamForTag(tag);

  if(audStream != NULL)
    return audStream->sampleFramesGenerated;
  else {
    return -1;
  }
}

// Routine to stop
PERFORM_API void SNDStop(int tag)
{
  AudioStream *listPtr;
  AudioStream *prevPtr;

  // start at head of the linked list and traverse it to find the tag.
  // stop the appropriate AudOut instance then delete the element.
  for(prevPtr = &head, listPtr = head.next; listPtr != NULL; prevPtr = listPtr, listPtr = listPtr->next) {
    if(listPtr->playTag == tag && listPtr->isPlaying)  {
      if (!listPtr->dxmode) {
        if (listPtr->audioOutWO->IsActive())
          listPtr->audioOutWO->Stop();
//        delete listPtr->audioOutWO;       // delete the object now we no longer need it.
      }
      else {
        if (listPtr->audioOutDX->IsActive())
          listPtr->audioOutDX->Stop();
//        delete listPtr->audioOutDX;       // delete the object now we no longer need it.
      }
      listPtr->isPlaying = FALSE;
      // reassign the pointers skipping the listPtr referenced AudioStream
      prevPtr->next = listPtr->next;
      // free the memory.
//      free(listPtr);
      return;                             // our work is done...
    }
  }
}

PERFORM_API void SNDPause(int tag)
{
  AudioStream *audStream = findStreamForTag(tag);

	// TODO - surely there is a AudOut equivalent?
}

PERFORM_API void SNDResume(int tag)
{
  AudioStream *audStream = findStreamForTag(tag);

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