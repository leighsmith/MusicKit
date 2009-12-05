//////////////////////////////////////////////////////////////////////////////
//
// CAudOutWO - Win32 WaveOut API version of CAudOut
//
// SKoT McDonald / Vellocet
// skot@vellocet.ii.net
// (c) 1999 Vellocet 
// All rights reserved.
//
// Last change: 14 July 1999
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __VELLOCET_AUDOUTWO_H
#define __VELLOCET_AUDOUTWO_H

#include "AudOut.h"

//////////////////////////////////////////////////////////////////////////////

class CAudOutWO : public CAudOut
{
  // Members

private:
  // none

protected:
  HANDLE        m_hNextAudio;
  DWORD         m_dwCurBuffer; // current buffer to write to...
  DWORD         m_dwPlaBuffer; // current buffer being played
  WAVEOUTCAPS  *m_pWaveOutCaps;
  HWAVEOUT      m_hwo;
  WAVEHDR      *m_pwhdr;
  void        **m_ppBuffer;

public:
  // none
  
  // Methods

private:
  // none

protected:
  static void __cdecl AudioThread (void* pThis);
  bool        Close       (void);
  void        DoNextBuffer (void);
  bool        FreeBuffers (void);
  bool        Open        (short iDevID); 
  bool        ProcessMMReturn (MMRESULT r);

  static void CALLBACK waveOutProc (HWAVEOUT hwo, UINT uMsg, 
                           DWORD dwInstance, 
                           DWORD dwParam1, DWORD dwParam2);


public:
  CAudOutWO();
  ~CAudOutWO();

  bool    Initialise      (void (*GenAudio)(float**, DWORD, DWORD, DWORD), 
                           DWORD dwGenAudioData);
  bool    AllocateBuffers (DWORD dwNumBuffers, DWORD dwBufferSize); 

  char*   GetDevName      (DWORD n);

  bool    Start(void);

  // Class access cheapy functions

  WAVEOUTCAPS* GetCurDevCaps(void);

  // Three utility functions can be used to help build 
  // extended device info dialogs

  bool    GetCurDevManufacturer (char* text, long liLen);
  CString GetSupportsStr(void); 
  CString GetFormatsStr(void);

  // TODO: get rid of CString dependency
};

#endif

//////////////////////////////////////////////////////////////////////////////
