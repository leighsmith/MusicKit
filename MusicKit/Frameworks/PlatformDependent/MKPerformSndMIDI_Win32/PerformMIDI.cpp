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
    Even if did, it would mean for any other system (such as mi_d) to use this library would
    need to use the Apple frameworks, which is nearly as bad as having to use MS API, but
    twice as bad if you have to have both development systems to compile this!

    2. It remains to be determined if Apple's ActiveX.framework has been stress tested 
    dealing with 200ms duration MIDI buffers.
  
    3. We only export C function names (not C++) to allow linking against gcc as
    name mangling - "decorating" in MS jargon - differs between the compilers.

  Original Author: Leigh M. Smith, <leigh@tomandandy.com>, tomandandy music inc.

  30 July 1999, Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.

  Just to cover my ass: DirectMusic, DirectSound and DirectX are registered trademarks
  of Microsoft Corp and they can have them.
*/
/*
 $Log$
 Revision 1.1  1999/11/17 17:57:14  leigh
 Initial revision

*/
#include "stdafx.h"
#include <stdio.h>
// According to comments in objbase.h, if initguid.h is included after it, then the
// DEFINE_GUID is magically defined which seems to stop the linking of the DLL
// from complaining about missing IID definitions, specifically IID_IDirectMusic.
// This is all new functionality of VC++6.0 which breaks the  compilation of 
// MS's own DirectMusic 6.1 demos! Hey Bill spend some of your $$ on quality control!
#include <objbase.h>
#include <initguid.h>
#include <dmusicc.h>  // for Core Layer DirectMusic class definitions
#include <dmusici.h>
#include "PerformMIDI.h"
#include "PerformSoundPrivate.h" 

#ifdef FUNCLOG
extern FILE *debug;
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define PLAYBUFFER_SIZE 2048

// MS-Wisdom: "If nothing else, be sure to link with the multithreaded libraries."

// Our "instance variables"
static IDirectMusicBuffer *bufferForPlay;
static IDirectMusicPort *playPort;
static IDirectMusicPerformance *performance;
// actually there should be several of these as there will be several instruments downloaded.
static IDirectMusicDownloadedInstrument *downloadedInstrument;
static IReferenceClock *masterClock;
static IDirectMusic *dm;

// list of available output ports, the currently selected one and its DLS capabilities.
#define PORTDESCRIPTION_MAX 80     // Number of chars per description, more than enough.
static char **portList;
static int portListSize = 0;       // portListSize != 0 indicates the DLL has been initialised.
static int defaultPortIndex = 0;   // defaultPort is that nominated by the user across applications
static int selectedPortIndex = 0;  // which may be overriden per application.
static BOOL selectedPortSupportsDLS;

// retrieves the default MS General MIDI DirectMusicCollection
static HRESULT getGMCollection(IDirectMusicLoader *pILoader, IDirectMusicCollection **ppICollection)
{
    HRESULT hr;
    DMUS_OBJECTDESC desc;

    desc.dwSize = sizeof(DMUS_OBJECTDESC);
    desc.guidClass = CLSID_DirectMusicCollection;
    desc.guidObject = GUID_DefaultGMCollection;
    desc.dwValidData = (DMUS_OBJ_CLASS | DMUS_OBJ_OBJECT);
    hr = pILoader->GetObject(&desc, IID_IDirectMusicCollection,(void **) ppICollection);
    return hr;
}

static void listInstruments(IDirectMusicCollection *pCollection)
 
{
    HRESULT hr = S_OK;
    DWORD dwPatch;
    WCHAR wszName[MAX_PATH];
    DWORD dwIndex;

    for (dwIndex = 0; hr == S_OK; dwIndex++) {
        hr = pCollection->EnumInstrument(dwIndex, &dwPatch, wszName, MAX_PATH);
        if (hr == S_OK) {
#ifdef FUNCLOG
           fprintf(debug, "Patch 0x%lx is %S\n",dwPatch,wszName);
#endif
        }
    }
}

/*
  MS Lore:
  "The only way to create a DirectMusicInstrument object for downloading an instrument is to 
  first create a DirectMusicCollection object, then call the IDirectMusicCollection::GetInstrument
  method. GetInstrument creates a DirectMusicInstrument object and returns its IDirectMusicInstrument
  interface pointer.

  "The following function, given a collection, a patch number, a port, and a range of notes, 
  retrieves the instrument from the collection and downloads it. It sets up an array of just one 
  DMUS_NOTERANGE structure and passes this to the IDirectMusicPort::DownloadInstrument method. Typically
  only a single range of notes will be specified, but it is possible to specify multiple ranges.
  If you pass NULL instead of a pointer to an array, the data for all regions is downloaded."

  "[One of] the key differences between a collection and a band are as follows:

  An instrument from a collection is not inherently associated with any particular performance channel (PChannel)
  of a segment. A band assigns the patch number of an instrument to each PChannel in a segment and assigns a
  voice priority to the channel."
*/
static HRESULT downloadInstrument(
    IDirectMusicDownloadedInstrument **ppDLInstrument,
    IDirectMusicCollection *pCollection,    // DLS collection
    IDirectMusicPort *pPort,                // Destination port
    DWORD dirMusicPatchNum,                 // Requested instrument patch number, according to the MS spec.
    DWORD lowNote,                          // Low note of range
    DWORD highNote)                         // High note of range
 
{
    HRESULT hr;
    IDirectMusicInstrument* pInstrument;

#ifdef FUNCLOG
    fprintf(debug,"downloading instrument %d\n", dirMusicPatchNum);
#endif
    hr = pCollection->GetInstrument(dirMusicPatchNum, &pInstrument);
    if (SUCCEEDED(hr)) {
        DMUS_NOTERANGE NoteRange[1];         // Optional note range
        NoteRange[0].dwLowNote = lowNote;
        NoteRange[0].dwHighNote = highNote;

        hr = pPort->DownloadInstrument(pInstrument, 
                ppDLInstrument, 
                NoteRange,   // Array of ranges
                1);          // Number of elements in array
        pInstrument->Release();
    }
    return hr;
}

// Download the listed patches
int PMDownloadDLSInstruments(unsigned int *patchesToDownload, int patchesUsed)
{
  CLSID CLSID_DMLoader;       // The object loader class identifier
  IDirectMusicLoader *loader; // MS sez there should only be one instance of this and should be used for 
                              // loading everything to enable caching. i.e. it should have been a class method.
  IDirectMusicCollection *dlsGMCollection;
  HRESULT hr;
  int patchIndex;
 
#ifdef FUNCLOG
  fprintf(debug, "In PMDownloadDLSInstruments\n");
#endif
  // This came from RegEdit, but it may as well have come from Mars...
  // HKEY_CLASSES_ROOT\CLSID\{D2AC2892-B39B-11D1-8704-00600893B1BD} = "Microsoft.DirectMusicLoader.1"
  // while you can use the text description, you can't guarantee it will be found, only the CLSID can be.

  CLSIDFromString(L"{D2AC2892-B39B-11D1-8704-00600893B1BD}", &CLSID_DMLoader);
  hr = CoCreateInstance(CLSID_DMLoader, NULL, CLSCTX_INPROC, IID_IDirectMusicLoader, (void**)&loader);

  hr = getGMCollection(loader, &dlsGMCollection);
  if(FAILED(hr)) {
    return FALSE;
  }

#ifdef FUNCLOG
  listInstruments(dlsGMCollection);
#endif

  /*
  "The IDirectMusicBand::Download method downloads the DLS data for instruments in the band to a
  performance object. The method downloads each instrument in the band by calling the
  IDirectMusicPerformance::DownloadInstrument method. DownloadInstrument, in turn, uses the PChannel
  of the instrument to find the appropriate port, and then calls the IDirectMusicPort::DownloadInstrument
  method on that port.

  Once a band has been downloaded, the instruments in the band may be selected, either individually
  with program change MIDI messages, or all at once by playing a band segment created through a call
  to the IDirectMusicBand::CreateSegment method."
  So why couldn't MS have created a method to download from a IDirectMusicBand to a port without requiring an
  entire IDirectMusicPerformance to be functional??
  */


  // TODO: determine the note ranges and the patch changes required.
  // attempt to download it.
  for(patchIndex = 0; patchIndex < patchesUsed; patchIndex++) {
    hr = downloadInstrument(&downloadedInstrument, dlsGMCollection, playPort, patchesToDownload[patchIndex], 1, 127);
    if(FAILED(hr)) {
      return FALSE;
    }
  }
  return TRUE;
}

// allocates the playback buffer
BOOL PMCreateBuffer()
{
  DMUS_BUFFERDESC bufferDescription;

  bufferDescription.dwSize = sizeof(bufferDescription);
  // bufferDescription.dwFlags; // No flags are defined. 
  // The value GUID_NULL represents KSDATAFORMAT_SUBTYPE_DIRECTMUSIC
  bufferDescription.guidBufferFormat = GUID_NULL;
  bufferDescription.cbBuffer = PLAYBUFFER_SIZE; // size of the buffer
  if(FAILED(dm->CreateMusicBuffer(&bufferDescription, &bufferForPlay, NULL))) {
    return FALSE;
  }
  else
    return TRUE;
}

// Release the port indexed by portNum.
// At the moment, all we do is release the last created port.
BOOL PMReleaseMIDIPortNum(int portNum)
{
  if(playPort != NULL) {  // in case we had to release things ourselves in PMSetMIDIPort.
    playPort->Release(); // playPort
    playPort = NULL;
  }
  return TRUE;
}

// Set the device. Enumerate thru the list, match against the chosen one,
// use its guidPort to create the port.
// Ports created here need to be released before a new port is created 
// otherwise they will be unable to be created a second time.
BOOL PMSetMIDIPort(char *newPortDescription)
{
  int portIndex;
  DMUS_PORTPARAMS portParameters;
  DMUS_PORTCAPS portCapabilities;
  HRESULT hr;
  char portDescriptionStr[PORTDESCRIPTION_MAX];

  portIndex = 0;
  do {

		memset(&portCapabilities, 0, sizeof(portCapabilities));
		portCapabilities.dwSize = sizeof(DMUS_PORTCAPS);

		hr = dm->EnumPort(portIndex, &portCapabilities);

		// Don't add input ports. Need to check to see if port is output
		if (hr == S_OK && portCapabilities.dwClass == DMUS_PC_OUTPUTCLASS) {
			WideCharToMultiByte(CP_ACP, 0, portCapabilities.wszDescription, -1,
													portDescriptionStr, PORTDESCRIPTION_MAX, 0, 0);

      if (strcmp(newPortDescription, portDescriptionStr) == 0) {
        memset(&portParameters, 0, sizeof(portParameters));
        portParameters.dwSize = sizeof(DMUS_PORTPARAMS);
        portParameters.dwChannelGroups = 1;
        portParameters.dwValidParams = DMUS_PORTPARAMS_CHANNELGROUPS;

        // If the port has not been released with an explict call to PMReleaseMIDIPortNum, do it now.
        // This can happen because the dealloc method of MKMidi has yet to be called (due to autorelease)
        // after releasing a MKMidi instance. dealloc should close the MIDI device, and therefore release
        // the claim of the MIDI unit.
        if(playPort != NULL)  
          PMReleaseMIDIPortNum(portIndex); // Not right TODO

        if(FAILED(dm->CreatePort(portCapabilities.guidPort, &portParameters, &playPort, NULL)))
          return FALSE;

        selectedPortIndex = portIndex;
        selectedPortSupportsDLS = (portCapabilities.dwFlags & DMUS_PC_DLS);
        return TRUE;
      }
		} 
		else if ((hr != S_FALSE) && (portCapabilities.dwClass != DMUS_PC_INPUTCLASS)) {
			// EnumPort will return S_FALSE when all ports have been enumerated.
			return FALSE;
		}
		portIndex++;
 	} while (hr == S_OK);

  return FALSE;
}

// set the port using just a numeric port index
BOOL PMSetMIDIPortNum(int portNum)
{
  return PMSetMIDIPort(portList[portNum]);
}

// Return the available port names and the index of the current selected port.
// A NULL char * terminates the list a la argv behaviour.
const char **PMGetAvailableMIDIPorts(unsigned int *selectedPortIndexPtr)
{
  int i = 0;

  if(portListSize == 0) { // yet to initialise DirectMusic, so do it now.
    PMinitialise();
  }
#ifdef FUNCLOG
  for(i = 0; i < portListSize; i++) {
    fprintf(debug, "port[%d] = %s\n", i, portList[i]);
  }
#endif
#ifdef FUNCLOG
  fprintf(debug, "defaultPort = %d  selected = %d, supports DLS = %d\n", defaultPortIndex, selectedPortIndex,
    selectedPortSupportsDLS);
#endif
  *selectedPortIndexPtr = selectedPortIndex;
  return (const char **) portList; // make a const for export
}

// Initialise the DirectMusic interface. We check this is not done twice.
int PMinitialise()
{
  CLSID CLSID_DirectMusic;   // The object class identifier
  DMUS_PORTPARAMS portParameters;
	DMUS_PORTCAPS portCapabilities;
//  IDirectMusicPort *defaultPort;
  GUID guidDefaultPort;
  GUID guidPlayPort;
  int portIndex = 0;         // the index into the enumerated music ports.
  LPDIRECTSOUND dirSndObj;
  HRESULT hr;

  if(portListSize != 0) { // check in case we are attempting to initialise twice.
    return TRUE;
  }

  // Da MS-Man Sez:
  // "Unlike other components of DirectX, the DirectMusic application programming
  // interface (API) is completely COM-based and does not contain any library functions
  // such as helper functions to create COM objects. As a result, there is no Dmusic.lib
  // file to link to during the build."
  // The end effect is we have to stuff around just to access the object.

  // Initialise the COM, so we can create a DirectMusic object.
  if(FAILED(CoInitialize(NULL))) {
    return FALSE;
  }

  // This came from RegEdit, but it may well have come from Mars...
  // HKEY_CLASSES_ROOT\CLSID\{636B9F10-0C7D-11D1-95B2-0020AFDC7421} = Microsoft.DirectMusic.1

  CLSIDFromString(L"{636B9F10-0C7D-11D1-95B2-0020AFDC7421}", &CLSID_DirectMusic);
  //::CLSIDFromProgID(L"Microsoft.DirectMusic", &CLSID_DirectMusic); // So do you feel lucky, punk?
  // We should be able to attach to anything claiming to be DirectMusic (i.e. supporting the interface)
  // and then make decisions about what differences to work around dependent on the version, rather than
  // playing 20 questions to figure out which version of DM is actually on the system so we can connect to it
  // before we can talk to it...
  if (FAILED(CoCreateInstance(CLSID_DirectMusic, NULL, CLSCTX_INPROC_SERVER,  IID_IDirectMusic, (LPVOID*)&dm))) {
    return FALSE;
  }

  // "The specified DirectSound object will be the one used for rendering
  // audio on all ports. This default can be overridden by using the 
  // IDirectMusicPort::SetDirectSound method.
  // If this parameter is NULL, the method creates its own DirectSound object.
  // (It is an error to call SetDirectSound on an active port.)"

  // TODO: Need to retrieve the DirectSound pointer from the PerformSound library.
  // this is actually a bugger to do properly...
  dirSndObj = SNDGetDirectSound();
#ifdef FUNCLOG
  fprintf(debug, "SNDGetDirectSound = %x\n", dirSndObj);
#endif

  // This will take care of the windowHandle parameter.
  if(FAILED(dm->SetDirectSound(NULL, NULL))) {
    return FALSE;
  }

  // Da MS-Man Sez:
  // "It is good practice to obtain the default port (i.e. the one selected by the user in
  // the DirectMusic control panel application) by a call to IDirectMusic::GetDefaultPort,
  // then check its capabilities by using the IDirectMusicPort::GetCaps method.
  // If the port does not meet the needs of your application, you can use the 
  // IDirectMusic::EnumPort method to find the Microsoft Software Synthesizer or another port."
  if(FAILED(dm->GetDefaultPort(&guidDefaultPort))) {
    return FALSE;
  }

  if(!PMCreateBuffer()) {
    return FALSE;
  }

  // Here's where we examine the capabilities of each of the MIDI ports and assign defaultPort. 
  // We select the default port now, but the MK may request a change of port (from a user selection).
  // To allow user selections, we build up an array of strings (portList) and the array index that corresponds
  // to the defaultPort.
/*
  "The actual number of notes that can be played simultaneously is limited by the number of
  voices available on the port. (This number can be determined from the dwVoices member of
  the DMUS_PORTPARAMS structure.) A voice is a set of resources dedicated to the synthesis of
  a single note being played on a channel."
  Need to determine the maximum polyphony so we can determine how much to synthesize.
*/
  portListSize = 0;
  // TODO kludged maximum
  if((portList = (char **) malloc(25 * sizeof(char *))) == NULL) {
    fprintf(stderr, "PMInitialise allocation error\n");
  }
	do {
		// need to determine if we need to keep each of these or not.
		memset(&portCapabilities, 0, sizeof(portCapabilities));
		portCapabilities.dwSize = sizeof(DMUS_PORTCAPS);

		hr = dm->EnumPort(portIndex, &portCapabilities);

		// Don't add input ports. Need to check to see if port is output
		if (hr == S_OK && portCapabilities.dwClass == DMUS_PC_OUTPUTCLASS) {
			if((portList[portListSize] = (char *) malloc(PORTDESCRIPTION_MAX)) == NULL) {
				fprintf(stderr, "PMInitialise allocation error\n");
			}
			WideCharToMultiByte(CP_ACP, 0, portCapabilities.wszDescription, -1,
													portList[portListSize], PORTDESCRIPTION_MAX, 0, 0);

			if (IsEqualGUID(portCapabilities.guidPort, guidDefaultPort)) {
				// this is the default port that the index number should be returned
				defaultPortIndex = selectedPortIndex = portListSize;
        // to tell that we have a DLS port
        selectedPortSupportsDLS = (portCapabilities.dwFlags & DMUS_PC_DLS);
			}
			portListSize++;
		} 
		else if ((hr != S_FALSE) && (portCapabilities.dwClass != DMUS_PC_INPUTCLASS)) {
			// EnumPort will return S_FALSE when all ports have been enumerated.
			return FALSE;
		}
		portIndex++;
	} while (hr == S_OK);
  portList[portListSize] = NULL; // terminating NULL a la argv

  /* "Reference to (C++) or address of (C) the GUID that identifies the port for
     which the IDirectMusicPort interface is to be created. The GUID is retrieved
     through the IDirectMusic::EnumPort method. If it is GUID_NULL, then the returned
     port will be the default port."
     For more information, see "Default Port" in the MS DirMus doco.
  */
  guidPlayPort = GUID_NULL;

  /* create the DirectMusicPort for playback */
  memset(&portParameters, 0, sizeof(portParameters));
  portParameters.dwSize = sizeof(portParameters); 
  portParameters.dwValidParams = 0; // don't be too choosy about what we need. 

  // TODO: probably assign more channel groups here

  // "If [fShare is] TRUE, all ports use the channel groups assigned to this port.
  // If FALSE, the port is opened in exclusive mode and the use of the same channel
  // groups by other ports is forbidden." 
  portParameters.fShare = TRUE;

  if(FAILED(dm->CreatePort(guidPlayPort, &portParameters, &playPort, NULL))) {
    return FALSE;
  }

  // We now have assigned the port to play from.
  // "A port is a device that sends or receives musical data. It may correspond to a 
  // hardware device, a software synthesizer, or a software filter."
  // The port is the means to download instruments, get the latency clock, etc.

  /*
  "The next step is to download the instruments. This is necessary even for playing a simple
  MIDI file, because the default software synthesizer needs the DLS data for the General MIDI
  instrument set. If you skip this step, the MIDI file will play silently."
  ...Grrr...A silent instrument, now that's a logical default...How about a sine tone???
  */
#ifdef FUNCLOG
  fprintf(debug, "calling PMDownloadDLSInstruments\n");
#endif
  unsigned int patches[] = {12, 3, 0, 0x200034};
  //  PMDownloadDLSInstruments(patches, 4);

  // "Most applications will not need to call SetMasterClock. It should not be called
  // unless there is a need to synchronize tightly with a hardware timer other than
  // the system clock".
  // LMS sez: This is probably only used for external clock slaving such as to SMPTE 
  // or word-clock.

  // We do need to retrieve the MasterClock so we can compute absolute times for playback scheduling.
  dm->GetMasterClock(NULL, &masterClock);

  return TRUE;
}

// According to MS whenever the app loses focus we should manually deactivate the music!
// This should be the bloody OS's job! I think if we leave it activated, it will
// continue to play in the background?
int PMactivate()
{
    // This should initiate playback on the opened output ports.
  if(FAILED(dm->Activate(TRUE)))
    return FALSE;
  else
    return TRUE;
}

int PMdeactivate()
{
    // This should initiate playback on the opened output ports.
  if(FAILED(dm->Activate(FALSE))) {
    return FALSE;
  }
  // According to MS whenever the app loses focus we should manually deactivate the music!
  // This should be the bloody OS's job! I think if we leave it activated, it will
  // continue to play in the background?
  return TRUE;
}

/* Routine MDGetAvailableQueueSize */
int PMGetAvailableQueueSize(int *size)
{
  DWORD dwSize;
#if 0
  fprintf(debug, "PMGetAvailableQueueSize called\n");
#endif
  // return the queue size
  if(FAILED(bufferForPlay->GetMaxBytes(&dwSize))) {
    return FALSE;
  }

  // "At least 32 bytes (the size of DMUS_EVENTHEADER plus dwChannelMessage) must be free in the buffer."
  *size = (int) dwSize - 32;

  return TRUE;
}

// I presume the value returned is running ahead of time and latency time will report a value closer to
// the present, represented as a REFERENCE_TIME.
// "Reference time is the time returned by the master clock. It is a 64-bit value defined
// as type REFERENCE_TIME. Reference time is measured in units of 100 nanoseconds, more or less,
// so the clock ticks about 10 million times each second. The value returned by the
// IReferenceClock::GetTime method is relative to an arbitrary start time."
REFERENCE_TIME PMGetCurrentTime()
{
  REFERENCE_TIME currentTime;

  masterClock->GetTime(&currentTime);
  return currentTime;
}

// Pack the message into the buffer, requires PM 
int PMPackMessageForPlay(REFERENCE_TIME time, unsigned char *channelMessage, int msgLength)
{
  DWORD channelGroup = 1; // TODO at the moment everything is to the first channel group.
//  DWORD channelMessage;
  int numOfBytes;
#if 0
  DWORD numChanGroups;
  DWORD usedBytes;
  DMUS_SYNTHSTATS synthStats;
#endif
  HRESULT hr;
  unsigned char *mp;
  DWORD message = 0;
  int msgIndex;

  /*
   "Buffer objects are completely independent of port objects until the buffer is passed to
   the port by a call to the IDirectMusicPort::PlayBuffer or IDirectMusicPort::Read method.
   The application is then free to reuse the buffer."
  */
  if(!PMGetAvailableQueueSize(&numOfBytes)) {
    return FALSE;
  }

  if(numOfBytes < msgLength) {
    return FALSE;
  }

#if 0
  // check how many we've used
  if(FAILED(bufferForPlay->GetUsedBytes(&usedBytes))) {
    return FALSE;
  }
  fprintf(debug, "Used bytes = %d\n", usedBytes);

  if(FAILED(playPort->GetNumChannelGroups(&numChanGroups))) {
    return FALSE;
  }
  fprintf(debug,"number of channel groups = %d\n", numChanGroups);

  // "The dwSize member of this structure must be properly initialized before the method is called."
  synthStats.dwSize = sizeof(synthStats);

  if(FAILED(playPort->GetRunningStats(&synthStats))) {
    return FALSE;
  }
#endif

  // "The time parameter must contain the absolute time at which the data is to
  // be sent to the port."

  // MS didn't document the encoding of a channel message in a four byte (DWORD) integer but
  // from trial and error it turns out naturally to be little endian, thus the 
  // note-on unsigned char array {0x90, 0x45 0x23} will be cast to an int, i.e 0x00234590
  if(msgLength <= 4) {
    mp = (unsigned char *) &message;
    // TODO generate the expanded channel message
    for(msgIndex = 0; msgIndex < msgLength; msgIndex++)
      mp[msgIndex] = channelMessage[msgIndex];
#ifdef FUNCLOG
    fprintf(debug,"time = %I64d, message = 0x%x\n", time, message);
#endif
    hr = bufferForPlay->PackStructured(time, channelGroup, message);
  }
  // if playing a sysex
  //  hr = bufferForPlay->PackUnStructured(time, channelGroup, channelMessage);
    
  if(FAILED(hr)) {
#ifdef FUNCLOG
    if(hr == DMUS_E_INVALID_EVENT) {
      fprintf(debug, "PMPackMessageForPlay: invalid event\n");
    }
    else if(hr == E_OUTOFMEMORY) {
      fprintf(debug, "PMPackMessageForPlay: out of memory\n");
    }
    else
      fprintf(debug, "PMPackMessageForPlay: error %d\n", hr);
#endif
    return FALSE;
  }
  else
    return TRUE;
}

int PMPlayBuffer(void)
{
  // once the buffer is filled, ship it.
  HRESULT hr = playPort->PlayBuffer(bufferForPlay);

  if(FAILED(hr)) {
#ifdef FUNCLOG
    if(hr == E_FAIL) {
      fprintf(debug, "PMPlayBuffer: fail\n");
    }
    else if(hr == E_INVALIDARG) {
      fprintf(debug, "PMPlayBuffer: invalid arg\n");
    }
    else if(hr == E_OUTOFMEMORY) {
      fprintf(debug, "PMPlayBuffer: out of memory\n");
    }
    else
      fprintf(debug, "PMPlayBuffer: error %d\n", hr);
#endif
    return FALSE;
  }
  else {
    // once we have handed over the buffer for play, we need to deallocate it and then reuse it
    // TODO!
    if(!PMCreateBuffer()) {
      return FALSE;
    }
    return TRUE;
  }
}

int PMterminate(void)
{
  // should release the DirectMusic object dm, masterClock, playPort
  dm->Activate(FALSE);

  // The MS-Man sez the wrath of Bill will be on you if you don't do this.
  CoUninitialize();
  return TRUE;
}


#ifdef __cplusplus
}
#endif