//////////////////////////////////////////////////////////////////////////////
//
// CAudOut - Audio streaming base class
//  |
//  +- CAudOutWO 
//  +- CAudOutDX
//
// SKoT McDonald / Vellocet
// skot@vellocet.ii.net
// (c) 1999 Vellocet 
// All rights reserved.
//
// Last change: 14 July 1999
//
//////////////////////////////////////////////////////////////////////////////

#ifndef __VELLOCET_AUDOUT_H
#define __VELLOCET_AUDOUT_H

#include "dsound.h"

//////////////////////////////////////////////////////////////////////////////

class CAudOut
{
public:

  // Constant values

  enum
  {
    maxBuffers     = 16,  
    maxBufferSize  = 4096, 
    defFormat      = WAVE_FORMAT_PCM,
    defNumChans    = 2,
    defNumBuffers  = 4,
    defBufferSize  = 440, // ~ 1/100 of a sec
    defSamRate     = 44100,
    defBitsPerSam  = 16
  };

  enum audioMode
  {
    modeNone       = 0, // base class
    waveOut        = 1, // CAudOutWO
    directX        = 2, // CAudOutDX
    rewire         = 3, // not implemented yet
    cubaseVST      = 4, // not implemented yet
    lastMode       = 5
  };

  enum audPriority
  {
    audpriorityMin      = 0,
    audpriorityIdle     = 0,
    audpriorityLowest   = 1,
    audpriorityLow      = 2,
    audpriorityNormal   = 3,
    audpriorityHigh     = 4,
    audpriorityHighest  = 5,
    audpriorityTimeCrit = 6,
    audpriorityMax      = 6
  };
  // Error codes

  enum audioError 
  {
    err_none            = 0,
    err_badAlloc        = 1,
    err_notInit         = 2,
    err_badParam        = 3,
    err_notWhileActive  = 4,
    err_badDevID        = 5,
    err_badGenAudioPtr  = 6,
    err_badObjectState  = 7,
    err_alreadyInit     = 8
  };

protected:

  bool          m_bInit;
  DWORD         m_dwMode;
  CString       m_errstr;
  bool          m_bActive;

  WAVEFORMATEX  m_wfx;
  long          m_err;
  short         m_iCurDev;
  DWORD         m_dwNumDev;
  DWORD         m_dwBufferSize; // in bytes
  DWORD         m_dwNumBuffers;
  DWORD         m_dwNumSamples;
  float       **m_ppfGenBuffer; // the float based generation buffer
  void         (*m_GenAudio)(float**,DWORD,DWORD,DWORD);  
  DWORD         m_dwGenAudioData;

  HANDLE        m_hAudThread;
  short         m_iAudThreadPriority;

//////////////////////////////////////////////////////////////////////////////
// METHODS
//////////////////////////////////////////////////////////////////////////////

protected:

  bool PackOutput  (float** input, void* output); 
  bool Open        (short dwDevID);
  bool FreeBuffers (void);

public:

  CAudOut();
  ~CAudOut();

  virtual bool  Initialise (void (*GenAudio)(float**, DWORD, DWORD, DWORD), 
                            DWORD dwGenAudioData);
  virtual char* GetDevName (DWORD n) = 0; // pure virtual!
  virtual bool  Start(void) = 0;          // pure virtual!
  void          Stop(void);

  virtual bool  AllocateBuffers (DWORD dwNumBuffers, DWORD dwBufferSize);

  void SetGenAudioData (DWORD dwI) { m_dwGenAudioData = dwI;};
  bool SetGenAudio     (void (*GenAudio)(float**, DWORD, DWORD, DWORD));
  bool SetCurDev       (short iDevID);
  bool SetSampleRate   (DWORD r);

  bool  SetAudThreadPriority (short p);
  short GetAudThreadPriority (void);

  CString GetErrMsg    (void);
  void GetErrMsg       (char* pchErrText, DWORD len);

  inline short   GetCurDev(void)         { return m_iCurDev;            };
  inline DWORD   GetSampleRate(void)     { return m_wfx.nSamplesPerSec; };
  inline DWORD   GetMode(void)           { return m_dwMode;             };
  inline DWORD   NumDev()                { return m_dwNumDev;           };
  inline bool    IsInit(void)            { return m_bInit;              };
  inline bool    IsActive(void)          { return m_bActive;            };
  inline DWORD   NumBuffers(void)        { return m_dwNumBuffers;       };
  inline DWORD   NumChans(void)          { return m_wfx.nChannels;      };
  inline DWORD   BufferSizeBytes(void)   { return m_dwBufferSize;       };
  inline DWORD   BufferSizeSamples(void) { return m_dwNumSamples;       };
};

//////////////////////////////////////////////////////////////////////////////

#endif