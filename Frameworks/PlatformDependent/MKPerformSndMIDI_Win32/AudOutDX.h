//////////////////////////////////////////////////////////////////////////////
//
// CAudOutDX - DirectX implementation of CAudOut
//
// SKoT McDonald / Vellocet
// skot@vellocet.ii.net
// (c) 1999 Vellocet 
// All rights reserved.
//
// Last change: 14 July 1999
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __VELLOCET_AUDOUTDX_H
#define __VELLOCET_AUDOUTDX_H

#include "dsound.h"
#include "audout.h"

//////////////////////////////////////////////////////////////////////////////

class CAudOutDX : public CAudOut
{
  enum {
    maxDSDev = 32 // An arbitrary number
  };
  // members

protected:
  HANDLE               *m_dsbe;
  DSCAPS                m_dsCaps;
  DSBCAPS               m_dsBCaps;
  DWORD                 m_dwMaxDS;
  LPGUID               *m_pGUID;
  char                **m_ppchDSDesc;     // description of DS driver
  char                **m_ppchDSModule;   // DS module name
  IDirectSoundBuffer   *m_pDSBuffer;
  IDirectSoundBuffer   *m_pDSBufferPrimary;
  LPDIRECTSOUND         m_pDS;
  IDirectSoundNotify   *m_pDSNotify;
  DSBPOSITIONNOTIFY    *m_DSPosNotify;
  DSBUFFERDESC          m_dsbd;
  DSBUFFERDESC          m_dsbdPrimary;

public:

  HWND                  m_hWnd;
                       // Parent app window, for directSound
                       //SetCoordinationLevel call
// Methods

protected:

  bool    GetDSSystemCaps (void);
  static BOOL CALLBACK DSEnumCallback (LPGUID lpGuid, LPCSTR lpcstrDescription, LPCSTR lpcstrModule, LPVOID lpContext);
  bool    ProcessDXReturn (HRESULT r);
  bool    Open (short iDevID); 
  bool    FreeBuffers     (void);
  bool    Close(void);

  static void __cdecl AudioThread(void* pThis);

public:

  CAudOutDX();
  ~CAudOutDX();

  bool    FreeMem(void);
  bool    AllocateBuffers (DWORD dwNumBuffers, DWORD dwBufferSize); // get chans from m_wfx
  bool    Initialise(void (*GenAudio)(float**, DWORD, DWORD, DWORD), DWORD dwGenAudioData);

  char*   GetDevName      (DWORD n);

  void    SetGenAudioData (DWORD dwGenAudioData) { m_dwGenAudioData = dwGenAudioData;};
  void    SetGenAudio     (void (*GenAudio)(float**, DWORD, DWORD, DWORD))
  {
    m_GenAudio = GenAudio;
  };

  bool    SetCurDev(short iDevID);

  bool    Start(void);

  LPDIRECTSOUND GetDirectSound(void);
};

//////////////////////////////////////////////////////////////////////////////

#endif