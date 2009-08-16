//////////////////////////////////////////////////////////////////////////////
//
// CAudOutWO - Implementation of waveOut win32 API version of CAudOut
//
// SKoT McDonald / Vellocet
// skot@vellocet.ii.net
// (c) 1999 Vellocet 
// All rights reserved.
//
// Last change: 14 July 1999
//
//////////////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include <process.h>
#include "audoutwo.h"
#include "mmsystem.h"
#include "mmreg.h"

//////////////////////////////////////////////////////////////////////////////
// @CAudOutWO()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

CAudOutWO::CAudOutWO() : CAudOut()
{
  m_pwhdr               = NULL;
  m_ppBuffer            = NULL;
  m_pWaveOutCaps        = NULL;
  m_hNextAudio          = NULL;

  m_dwMode              = CAudOut::waveOut;
  m_dwNumDev            = waveOutGetNumDevs ();
}

//////////////////////////////////////////////////////////////////////////////
// @~CAudOut()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

CAudOutWO::~CAudOutWO() 
{
  if (m_bInit)
    waveOutClose(m_hwo);

  if (m_pWaveOutCaps)
  {
    delete m_pWaveOutCaps;
    m_pWaveOutCaps = NULL;
  }
  FreeBuffers();
}

//////////////////////////////////////////////////////////////////////////////
// @Initialise()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::Initialise (void (*GenAudio)(float**, DWORD, DWORD, DWORD), 
                            DWORD dwGenAudioData)
{
  m_err = err_none;

  if (!CAudOut::Initialise(GenAudio, dwGenAudioData))
    return false;

  #ifdef _DEBUG
  m_errstr = "CAudOutWO::Initialise() ";
  #endif

  MMRESULT r = MMSYSERR_NOERROR;

  if (m_pWaveOutCaps == NULL)
  { 
    m_pWaveOutCaps = new WAVEOUTCAPS [m_dwNumDev];

    if (m_pWaveOutCaps == NULL)
    {
      m_err = err_badAlloc;
      return false;
    }
    else
    {
      for (DWORD i = 0; i < m_dwNumDev; i++)
      {
        r = waveOutGetDevCaps (i, &(m_pWaveOutCaps[i]), sizeof(WAVEOUTCAPS));
        if (!ProcessMMReturn(r))
        {
          delete [] m_pWaveOutCaps;
          m_pWaveOutCaps = NULL;
          return false;  
        }
      }
      if (AllocateBuffers(m_dwNumBuffers, m_dwNumSamples))
        m_bInit = true;
    }
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @AllocateBuffers()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::AllocateBuffers(DWORD dwNumBuffers, DWORD dwNumSamples)
{
  m_err = err_none;

  if (!CAudOut::AllocateBuffers(dwNumBuffers, dwNumSamples))
    return false;

  #ifdef _DEBUG
  m_errstr = "CAudOutWO::AllocateBuffers()";
  #endif

  m_ppBuffer     = new void*[m_dwNumBuffers];
  m_pwhdr        = new WAVEHDR[m_dwNumBuffers];

  if (!m_ppBuffer || !m_pwhdr)
    m_err = err_badAlloc;
  else
  {
    for (DWORD i=0; i < m_dwNumBuffers; i++)
    {
      m_ppBuffer[i] = (void*) new char [m_dwBufferSize];
      if (!m_ppBuffer[i])
        m_err = err_badAlloc;
      else
        memset(m_ppBuffer[i], 0, m_dwBufferSize);

      m_pwhdr[i].lpData         = (char*) m_ppBuffer[i];
      m_pwhdr[i].dwBufferLength = m_dwBufferSize;
      m_pwhdr[i].dwFlags        = 0;
    }
  }
  if (m_err != err_none)
  {
    FreeBuffers();
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @FreeBuffers()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::FreeBuffers(void)
{
  DWORD i;

  if (!CAudOut::FreeBuffers())
  {
    return false;
  }
  if (m_pwhdr)
  {
    delete [] m_pwhdr;
    m_pwhdr = NULL;
  }
  if (m_ppBuffer)
  {
    for (i=0; i < m_dwNumBuffers; i++)
      if (m_ppBuffer[i])
        delete [] m_ppBuffer[i];
    delete [] m_ppBuffer;
    m_ppBuffer = NULL;
  }
  return true;
}

//////////////////////////////////////////////////////////////////////////////
// @Open()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::Open (short iDevID)
{
  if (!CAudOut::Open(iDevID))
    return false;

  #ifdef _DEBUG
  m_errstr = "CAudOutWO::Open() ";
  #endif

  m_err = err_none;

  MMRESULT r;
  r = waveOutOpen ( &m_hwo, 
                    iDevID, &m_wfx, 
                    (DWORD) waveOutProc,
                    (DWORD) this, CALLBACK_FUNCTION);

  return ProcessMMReturn(r);
} 

//////////////////////////////////////////////////////////////////////////////
// @Start()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::Start(void)
{
  if (!Open(m_iCurDev))
    return false;

  #ifdef _DEBUG
  m_errstr = "CAudOut::Start()";
  #endif

  m_err = err_none;

  MMRESULT r = MMSYSERR_NOERROR;

  for (DWORD i = 0; i < m_dwNumBuffers; i++)
  {
    r = waveOutPrepareHeader (m_hwo, 
                              &(m_pwhdr[i]), 
                              sizeof(WAVEHDR)); 
  }
  m_dwCurBuffer = 0;
  m_dwPlaBuffer = 0;

  m_bActive = true;
  m_hNextAudio = CreateSemaphore(NULL,0,m_dwNumBuffers, "AudioThread");

  r = waveOutPause(m_hwo);
  if (!ProcessMMReturn(r))
    return false;

  // Queue up audio blocks

  for (i = 0; i < m_dwNumBuffers; i++)
    DoNextBuffer();

  r = waveOutRestart(m_hwo);

  // Start audio thread

  m_hAudThread = (HANDLE) _beginthread(AudioThread, 0, (void*) this);
  SetThreadPriority(m_hAudThread, m_iAudThreadPriority);


  return ProcessMMReturn(r);
}

//////////////////////////////////////////////////////////////////////////////
// @AudioThread()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

void CAudOutWO::AudioThread(void* pThis)
{
  ASSERT(pThis);

  CAudOutWO *pAO = (CAudOutWO*) pThis;

  while (pAO->m_bActive)
    if (WaitForSingleObject(pAO->m_hNextAudio, 10) == WAIT_OBJECT_0)
      pAO->DoNextBuffer();          

  CloseHandle(pAO->m_hNextAudio);   // destroy semaphore
  pAO->Close();                     // close waveouit device
  pAO->m_hAudThread = NULL;
  _endthread();
}

//////////////////////////////////////////////////////////////////////////////
// @waveOutProc
//
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
// static wave output callbcak function. dwInstance is a pointer
// to the CAudOut object
//////////////////////////////////////////////////////////////////////////////
 
void CALLBACK CAudOutWO::waveOutProc(HWAVEOUT hwo, UINT uMsg, 
    DWORD dwInstance, DWORD dwParam1, DWORD dwParam2) 
{
  ASSERT(dwInstance);

  switch (uMsg)
  {
  case WOM_CLOSE:
    break;  
  case WOM_OPEN:
    break;
  case WOM_DONE: 
    {
      CAudOutWO* pAudOut = pAudOut = (CAudOutWO*) dwInstance;
      if (pAudOut && pAudOut->m_bActive)
        ReleaseSemaphore(pAudOut->m_hNextAudio,1,NULL);
    }
    break;
  }
} 

//////////////////////////////////////////////////////////////////////////////
// @DoNextBuffer()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

void CAudOutWO::DoNextBuffer(void)
{
  WAVEHDR* pWhdr = &(m_pwhdr[m_dwCurBuffer]);
  DWORD i;

  waveOutUnprepareHeader (m_hwo, pWhdr,sizeof(WAVEHDR));

  pWhdr->lpData         = (char*) m_ppBuffer[m_dwCurBuffer];
  pWhdr->dwBufferLength = m_dwBufferSize;
  pWhdr->dwFlags        = 0;

  memset(m_ppBuffer[m_dwCurBuffer],0,m_dwBufferSize);

  for (i=0; i < m_wfx.nChannels; i++)
    memset(m_ppfGenBuffer[i],0,m_dwNumSamples*sizeof(float));

  m_GenAudio (m_ppfGenBuffer, m_dwNumSamples, NumChans(), m_dwGenAudioData);

  PackOutput(m_ppfGenBuffer, (void*) m_ppBuffer[m_dwCurBuffer]);
  waveOutPrepareHeader (m_hwo, pWhdr,sizeof(WAVEHDR));
  waveOutWrite (m_hwo, pWhdr, sizeof(WAVEHDR));
  m_dwCurBuffer = (m_dwCurBuffer + 1) % m_dwNumBuffers;
}

//////////////////////////////////////////////////////////////////////////////
// @Close()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::Close(void)
{
  waveOutReset(m_hwo);
  waveOutClose(m_hwo);

  return true;
}

//////////////////////////////////////////////////////////////////////////////
// @ProcessMMReturn()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::ProcessMMReturn(MMRESULT r)
{
  m_err = r;
  switch(r)
  {
  case MMSYSERR_NOERROR:
    m_err = err_none;
    break;
  case MMSYSERR_ALLOCATED:
    m_errstr += "Specified resource is already allocated";
    break;
  case MMSYSERR_BADDEVICEID:
    m_errstr += "Specified device identifier is out of range";
    break;
  case MMSYSERR_NODRIVER:
    m_errstr += "No device driver is present";
    break;
  case MMSYSERR_NOMEM:
    m_errstr += "Unable to allocate or lock memory";
    break;
  case WAVERR_BADFORMAT:
    m_errstr += "Attempted to open with an unsupported waveform-audio format.";
    break;
  case WAVERR_SYNC:
    m_errstr += "The device is synchronous but waveOutOpen was called without using the WAVE_ALLOWSYNC flag"; 
    break;
  case MMSYSERR_INVALHANDLE:
    m_errstr += "Specified device handle is invalid"; 
    break;
  case WAVERR_UNPREPARED:
    m_errstr += "Unprepared";
    break;
  default:
    m_errstr += "Unknown waveout error";
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @GetCurDevCaps()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

WAVEOUTCAPS* CAudOutWO::GetCurDevCaps(void)
{
  ASSERT (m_pWaveOutCaps && 
          m_iCurDev >=0  && 
          m_iCurDev < (long) m_dwNumDev);

  return &(m_pWaveOutCaps[m_iCurDev]); 
}

//////////////////////////////////////////////////////////////////////////////
// @GetDevName()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

char* CAudOutWO::GetDevName(DWORD n)
{
  #ifdef _DEBUG
  m_errstr = "CAudOutWO::GetDevName() ";
  #endif

  m_err    = err_none;

  char *r  = NULL;

  if (!m_pWaveOutCaps)
    m_err = err_notInit;

  else if (n >= m_dwNumDev)
    m_err = err_badParam;
  
  else
    r = m_pWaveOutCaps[n].szPname;

  return r;
}

//////////////////////////////////////////////////////////////////////////////
// @GetCurDevManufacturer()
//
// Parameters:
//
// Remarks:
//   To protect against any future reordering or reassigning of
//   defined constants to names, a switch statement has been used.
//   The manufacturer constants are defined in the Visual C++
//   file "mmreg.h". The values are somewhat sparse (not continuous)
//   which is another justification for this rather kludgey way of
//   mapping a string!
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

bool CAudOutWO::GetCurDevManufacturer(char* text, long liLen)
{
  m_err = err_none;

  #ifdef _DEBUG
  m_errstr = "CAudOutWO::GetCurDevManufacturer() ";
  #endif

  // Check all the data we are about to use

  if (!m_pWaveOutCaps)
  {
    m_err = err_notInit;
    return false;
  }
  if (m_iCurDev < 0 || m_iCurDev >= (long) m_dwNumDev)
  {
    m_err = err_badParam;
    return false;
  }
  if (text == NULL || liLen < 0)
  {
    m_err = err_badParam;
    return false;
  }

  switch (m_pWaveOutCaps[m_iCurDev].wMid)
  {
  case MM_MICROSOFT:        strncpy(text, "Microsoft Corporation", liLen);            break;
  case MM_CREATIVE:         strncpy(text, "Creative Labs", liLen);                    break;
  case MM_MEDIAVISION:      strncpy(text, "Media Vision", liLen);                     break;
  case MM_FUJITSU:          strncpy(text, "Fujitsu Corp.", liLen);                    break;
  case MM_ARTISOFT:         strncpy(text, "Artisoft", liLen);                         break;
  case MM_TURTLE_BEACH:     strncpy(text, "Turtle Beach", liLen);                     break;
  case MM_IBM:              strncpy(text, "IBM Corporation", liLen);                  break;
  case MM_VOCALTEC :        strncpy(text, "Vocaltec", liLen);                         break;
  case MM_ROLAND  :         strncpy(text, "Roland", liLen);                           break;
  case MM_DSP_SOLUTIONS:    strncpy(text, "DSP Solutions", liLen);                    break;
  case MM_NEC:              strncpy(text, "NEC", liLen);                              break;
  case MM_ATI:              strncpy(text, "ATI", liLen);                              break;
  case MM_WANGLABS:         strncpy(text, "Wang Laboratories", liLen);                break;
  case MM_TANDY:            strncpy(text, "Tandy Corporation", liLen);                break;
  case MM_VOYETRA:          strncpy(text, "Voyetra", liLen);                          break;
  case MM_ANTEX:            strncpy(text, "Antex Electronics Corporation", liLen);    break;
  case MM_ICL_PS:           strncpy(text, "ICL Personal Systems", liLen);             break;
  case MM_INTEL:            strncpy(text, "Intel Corporation", liLen);                break;
  case MM_GRAVIS:           strncpy(text, "Advanced Gravis", liLen);                  break;
  case MM_VAL:              strncpy(text, "Video Associates Labs", liLen);            break;
  case MM_INTERACTIVE:      strncpy(text, "InterActive", liLen);                      break;
  case MM_YAMAHA:           strncpy(text, "Yamaha Corporation of America", liLen);    break;
  case MM_EVEREX:           strncpy(text, "Everex Systems", liLen);                   break;
  case MM_ECHO:             strncpy(text, "Echo Speech Corporation", liLen);          break;
  case MM_SIERRA:           strncpy(text, "Sierra Semiconductor Corp", liLen);        break;
  case MM_CAT:              strncpy(text, "Computer Aided Technologies", liLen);      break;
  case MM_APPS:             strncpy(text, "APPS Software International", liLen);      break;
  case MM_DSP_GROUP:        strncpy(text, "DSP Group, Inc", liLen);                   break;
  case MM_MELABS:           strncpy(text, "microEngineering Labs", liLen);            break;
  case MM_COMPUTER_FRIENDS: strncpy(text, "Computer Friends", liLen);                 break;
  case MM_ESS:              strncpy(text, "ESS Technology", liLen);                   break;    
  case MM_AUDIOFILE:        strncpy(text, "Audio, Inc.", liLen);                      break;
  case MM_MOTOROLA:         strncpy(text, "Motorola, Inc.", liLen);                   break;
  case MM_CANOPUS:          strncpy(text, "Canopus, co., Ltd.", liLen);               break;
  case MM_EPSON:            strncpy(text, "Seiko Epson Corporation", liLen);          break;
  case MM_TRUEVISION:       strncpy(text, "Truevision", liLen);                       break;
  case MM_AZTECH:           strncpy(text, "Aztech Labs, Inc.", liLen);                break;
  case MM_VIDEOLOGIC:       strncpy(text, "Videologic", liLen);                       break;
  case MM_SCALACS:          strncpy(text, "SCALACS", liLen);                          break;
  case MM_KORG:             strncpy(text, "Toshihiko Okuhura, Korg", liLen);          break;
  case MM_APT:              strncpy(text, "Audio Processing Technology", liLen);      break;
  case MM_ICS:              strncpy(text, "Integrated Circuit Systems", liLen);       break;
  case MM_ITERATEDSYS:      strncpy(text, "Iterated Systems", liLen);                 break;
  case MM_METHEUS:          strncpy(text, "Metheus", liLen);                          break;
  case MM_LOGITECH:         strncpy(text, "Logitech, Inc.", liLen);                   break;
  case MM_WINNOV:           strncpy(text, "Winnov, Inc.", liLen);                     break;
  case MM_NCR:              strncpy(text, "NCR Corporation", liLen);                  break;
  case MM_EXAN:             strncpy(text, "EXAN", liLen);                             break;
  case MM_AST:              strncpy(text, "AST Research", liLen);                     break;
  case MM_WILLOWPOND:       strncpy(text, "Willow Pond Corporation", liLen);          break;
  case MM_SONICFOUNDRY:     strncpy(text, "Sonic Foundry", liLen);                    break;
  case MM_VITEC:            strncpy(text, "Vitec Multimedia", liLen);                 break;
  case MM_MOSCOM:           strncpy(text, "MOSCOM Corporation", liLen);               break;
  case MM_SILICONSOFT:      strncpy(text, "Silicon Soft", liLen);                     break;
  case MM_SUPERMAC:         strncpy(text, "Supermac", liLen);                         break;
  case MM_AUDIOPT:          strncpy(text, "Audio Processing Technology", liLen);      break;
  case MM_SPEECHCOMP:       strncpy(text, "Speech Compression", liLen);               break;
  case MM_DOLBY:            strncpy(text, "Dolby Laboratories", liLen);               break;
  case MM_OKI:              strncpy(text, "OKI", liLen);                              break;
  case MM_AURAVISION:       strncpy(text, "AuraVision Corporation", liLen);           break;
  case MM_OLIVETTI:         strncpy(text, "Olivetti", liLen);                         break;
  case MM_IOMAGIC:          strncpy(text, "I/O Magic Corporation", liLen);            break;
  case MM_MATSUSHITA:       strncpy(text, "Matsushita", liLen);                       break;
  case MM_CONTROLRES:       strncpy(text, "Control Resources Limited", liLen);        break;
  case MM_XEBEC:            strncpy(text, "Xebec Multimedia Solutions", liLen);       break;
  case MM_NEWMEDIA:         strncpy(text, "New Media Corporation", liLen);            break;
  case MM_NMS:              strncpy(text, "Natural MicroSystems", liLen);             break;
  case MM_LYRRUS:           strncpy(text, "Lyrrus Inc.", liLen);                      break;
  case MM_COMPUSIC:         strncpy(text, "Compusic", liLen);                         break;
  case MM_OPTI:             strncpy(text, "OPTi Computers Inc.", liLen);              break;
  case MM_DIALOGIC:         strncpy(text, "Dialogic Corporation", liLen);             break;
  default:
    sprintf(text, "Unknown [MID=%d]",m_pWaveOutCaps[m_iCurDev].wMid);      
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @GetSupportsStr()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

CString CAudOutWO::GetSupportsStr(void)
{
  CString s = "";

  if (m_pWaveOutCaps[m_iCurDev].dwSupport & WAVECAPS_LRVOLUME)
    s += " Sep. L/R volume"; 
 
  if (m_pWaveOutCaps[m_iCurDev].dwSupport & WAVECAPS_PITCH)
    s += " Pitch control";
 
  if (m_pWaveOutCaps[m_iCurDev].dwSupport & WAVECAPS_PLAYBACKRATE)
    s += " Playback rate control"; 
 
  if (m_pWaveOutCaps[m_iCurDev].dwSupport & WAVECAPS_SYNC)
    s += " Synchronous driver"; // blocks during buffer play!!
 
  if (m_pWaveOutCaps[m_iCurDev].dwSupport & WAVECAPS_VOLUME)
    s += " Volume control";
 
  if (m_pWaveOutCaps[m_iCurDev].dwSupport & WAVECAPS_SAMPLEACCURATE)
    s += " Sample-accurate"; // position information. 
 
  return s;
}

//////////////////////////////////////////////////////////////////////////////
// @GetFormatsStr()
//
// Parameters:
//
// Remarks:
//
// WaveOut notes:
//
// Returns:
//////////////////////////////////////////////////////////////////////////////

CString CAudOutWO::GetFormatsStr(void)
{
  CString s = "";
  if (!m_pWaveOutCaps)
    return s;
  DWORD f = m_pWaveOutCaps[m_iCurDev].dwFormats;

  if (f & (WAVE_FORMAT_1M08 | WAVE_FORMAT_1M16 
                                           | WAVE_FORMAT_1S08 | WAVE_FORMAT_1S16))
  {
    s += "[11.025kHz ";
    if (f & (WAVE_FORMAT_1M08 | WAVE_FORMAT_1M16)) 
    {
      s += "(mon ";
      if (f & WAVE_FORMAT_1M08)
        s += "8 ";
      if (f & WAVE_FORMAT_1M16)
        s += "16 ";
      s += ")";
    }
    if (f & (WAVE_FORMAT_1S08 | WAVE_FORMAT_1S16)) 
    {
      s += "(st ";
      if (f & WAVE_FORMAT_1S08)
        s += "8 ";
      if (f & WAVE_FORMAT_1S16)
        s += "16 ";
      s += ") ";
    }
    s +="] ";
  }
  if (f & (WAVE_FORMAT_2M08 | WAVE_FORMAT_2M16 | WAVE_FORMAT_2S08 | WAVE_FORMAT_2S16))
  {
    s += "[22.05kHz ";
    if (f & (WAVE_FORMAT_2M08 | WAVE_FORMAT_2M16)) 
    {
      s += "(mon ";
      if (f & WAVE_FORMAT_2M08)
        s += "8 ";
      if (f & WAVE_FORMAT_2M16)
        s += "16 ";
      s += ")";
    }
    if (f & (WAVE_FORMAT_2S08 | WAVE_FORMAT_2S16)) 
    {
      s += "(st ";
      if (f & WAVE_FORMAT_2S08)
        s += "8 ";
      if (f & WAVE_FORMAT_2S16)
        s += "16 ";
      s += ") ";
    }
    s +="] ";
  }
  if (f & (WAVE_FORMAT_4M08 | WAVE_FORMAT_4M16 | WAVE_FORMAT_4S08 | WAVE_FORMAT_4S16))
  {
    s += "[44.1kHz ";
    if (f & (WAVE_FORMAT_4M08 | WAVE_FORMAT_4M16)) 
    {
      s += "(mon ";
      if (f & WAVE_FORMAT_4M08)
        s += "8 ";
      if (f & WAVE_FORMAT_4M16)
        s += "16 ";
      s += ")";
    }
    if (f & (WAVE_FORMAT_4S08 | WAVE_FORMAT_4S16)) 
    {
      s += "(st ";
      if (f & WAVE_FORMAT_4S08)
        s += "8 ";
      if (f & WAVE_FORMAT_4S16)
        s += "16 ";
      s += ") ";
    }
    s +="] ";
  }
  return s;
}

//////////////////////////////////////////////////////////////////////////////
