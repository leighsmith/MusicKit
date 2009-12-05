//////////////////////////////////////////////////////////////////////////////
// 
// CAudOut - implementation of base audio stream methods
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

// Needed for MS Visual C++ MFC projects
#include "stdafx.h"

#include <process.h>
#include "audout.h"
#include "mmsystem.h"
#include "mmreg.h"


//////////////////////////////////////////////////////////////////////////////
// @CAudOut()
//
// Parameters:
//   None.
//
// Remarks:
//   Constructor
//
// Inheritance notes:
//   None.
//
// Returns:
//   Nothing.
//////////////////////////////////////////////////////////////////////////////

CAudOut::CAudOut()
{
  m_bInit               = false;
  m_bActive             = false;
  m_err                 = err_none;
  m_dwNumBuffers        = defNumBuffers;
  m_dwNumSamples        = defBufferSize;
  m_ppfGenBuffer        = NULL;
  m_iCurDev             = 0;
  m_dwMode              = modeNone;
  m_dwNumDev            = 0;
  m_hAudThread          = NULL;
  m_iAudThreadPriority  = THREAD_PRIORITY_HIGHEST;

  m_wfx.wFormatTag      = defFormat;
  m_wfx.nChannels       = defNumChans;     
  m_wfx.wBitsPerSample  = defBitsPerSam; 
  m_wfx.nSamplesPerSec  = defSamRate; 
  m_wfx.nBlockAlign     = (m_wfx.wBitsPerSample / 8) * m_wfx.nChannels;     
  m_wfx.nAvgBytesPerSec = m_wfx.nSamplesPerSec * m_wfx.nBlockAlign;     
  m_wfx.cbSize          = 0; 
}

//////////////////////////////////////////////////////////////////////////////
// @~CAudOut()
//
// Parameters:
//   None.
//
// Remarks:
//   Destructor.
//
// Inheritance notes:
//   None.
//
// Returns:
//   Nothing.
//////////////////////////////////////////////////////////////////////////////

CAudOut::~CAudOut()
{
  if (m_bActive)
  {
    Stop();
    Sleep(1000); // give threads time to stop
  }
  FreeBuffers();
}

//////////////////////////////////////////////////////////////////////////////
// @Initialise()
//
// Parameters:
//   GenAudio       - pointer to audio generation function.
//   dwGenAudioData - data to be supplied to GenAudio
//
// Remarks:
//   Initialises object variables. 
//
// Inheritance notes:
//   Call from within derived classes' Initialise() as their first operation.
//   The derived Initialise() should get the names of all devices it is 
//   supposed to support, and set m_dwNumDev to the number of devices found.
//
// Returns:
//   True if all is well.
//   False if GenAudio is NULL.
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::Initialise (void (*GenAudio)(float**, DWORD, DWORD, DWORD), 
                            DWORD dwGenAudioData)
{
  m_err   = err_none;
  m_bInit = false;

  if (GenAudio == NULL)
  {
    m_err = err_badGenAudioPtr;
  }
  else
  {
    m_GenAudio            = GenAudio;
    m_dwGenAudioData      = dwGenAudioData;
    m_wfx.wFormatTag      = defFormat;
    m_wfx.nChannels       = defNumChans;     
    m_wfx.wBitsPerSample  = defBitsPerSam; 
    m_wfx.nBlockAlign     = (m_wfx.wBitsPerSample / 8) * m_wfx.nChannels;     
    m_wfx.nAvgBytesPerSec = m_wfx.nSamplesPerSec * m_wfx.nBlockAlign;     
    m_wfx.cbSize          = 0; 

    // m_bInit is still false - MUST do init in derived class
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @SetSampleRate()
//
// Parameters:
//   GenAudio - Pointer to your audio generation function.
//
// Remarks:
//   Sets GenAudio function pointer.
//
// Inheritance notes:
//   None.
//
// Returns:
//   True if all is well.
//   False if GenAudio is NULL
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::SetGenAudio (void (*GenAudio)(float**, DWORD, DWORD, DWORD))
{
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::SetGenAudio()";
#endif

  if (GenAudio == NULL)
    m_err = err_badGenAudioPtr;
  else
    m_GenAudio = GenAudio;
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @SetSampleRate()
//
// Parameters:
//   dwSamRate - Sample rate
//
// Remarks:
//
// Inheritance notes:
//
// Returns:
//   True if all is well.
//   False if the sample rate isn't supported.
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::SetSampleRate(DWORD dwSamRate)  
{ 
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::SetSamplerate()";
#endif

  if (dwSamRate != 44100) // other rates not supported yet!
  {
    m_err = err_badParam;
  }
  else
  {
    m_wfx.nSamplesPerSec = dwSamRate; 
    m_wfx.nAvgBytesPerSec = m_wfx.nSamplesPerSec * m_wfx.nBlockAlign;     
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @AllocateBuffers()
//
// Parameters:
//   dwNumBuffers - number of queued buffers
//   dwNumSamples - length of buffers in samples
//
// Remarks:
//   Allocates the generation buffers passed to your GenAudio().
//
// Inheritance notes:
//   dwNumBuffers is only relevant for derived classes. CAudOut only ever has
//   one audio generation buffer, which GenAudio() fills with its output.
//
// Returns:
//   True if all is well.
//   False if an error occured during allocation.
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::AllocateBuffers(DWORD dwNumBuffers, DWORD dwNumSamples)
{
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::AllocateBuffers()";
#endif

  if (m_bActive)
    m_err = err_notWhileActive;
  else if (dwNumBuffers > CAudOut::maxBuffers)
    m_err = err_badParam;
  else if (dwNumSamples > CAudOut::maxBufferSize)
    m_err = err_badParam;
  else if (FreeBuffers())
  {
    m_dwNumSamples = dwNumSamples;
    m_dwNumBuffers = dwNumBuffers;
    m_dwBufferSize = m_dwNumSamples * m_wfx.nBlockAlign; // chans * bits / 8

    m_ppfGenBuffer = new float*[m_wfx.nChannels];
    if (m_ppfGenBuffer == NULL)
      m_err = err_badAlloc;
    else
    {
      for (DWORD i=0; i < m_wfx.nChannels; i++)
      {
        m_ppfGenBuffer[i] = new float [m_dwNumSamples];
        if (!m_ppfGenBuffer[i])
          m_err = err_badAlloc;
        else
          memset(m_ppfGenBuffer[i], 0, m_dwNumSamples * sizeof(float));
      }
    }
  }
  if (m_err != err_none)
    FreeBuffers();

  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @FreeBuffers()
//
// Parameters:
//   None.
//
// Remarks:
//
// Inheritance notes:
//   Should be called in derived classes FreeBuffers() to deallocate the
//   generation buffers.
//
// Returns:
//   True if all is well.
//   False if FreeBuffers() was called during active playback!
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::FreeBuffers(void)
{
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::FreeBuffers()";
#endif
 
  DWORD i;

  if (m_bActive)
  {
    m_err = err_notWhileActive;
  }
  else if (m_ppfGenBuffer)
  {
    for (i=0; i < m_wfx.nChannels; i++)
      if (m_ppfGenBuffer[i])
        delete [] m_ppfGenBuffer[i];
    delete [] m_ppfGenBuffer;
    m_ppfGenBuffer = NULL;
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @Open()
//
// Parameters:
//   iDevID         - ID of audio deive being opened.
//   GenAudio       - Pointer to audio generating function
//   dwGenAudioData - Data to be passed to GenAudio
//   dwSamRate      - The sample rate.
//
// Remarks:
//   Called by the Start() functions. Shouldn't need to be called by the user.
//
// Inheritance notes: 
//   Actually open a device. CAudOut::Open() will check that the parameters 
//   are valid, and setup miscellaneous object data.
//
// Returns: 
//   True if all is well. 
//   False if either iDevID is out of device range [0,m_dwNumDev-1]
//     or GenAudio function pointer is NULL.
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::Open (short iDevID)
{
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::Open()";
#endif

  if (m_bActive)
    m_err = err_notWhileActive;
  if (iDevID < 0 || iDevID >= (short) m_dwNumDev)
    m_err = err_badDevID;

  return (m_err == err_none);
} 

//////////////////////////////////////////////////////////////////////////////
// @Stop()
//
// Parameters:
//   None.
//
// Remarks:
//   Your AudioThread() should loop whilst m_bActive is true. Playback is 
//   is thus stopped when Stop() m_bActive to false. 
//
// Inheritance notes:
//   Shouldn't need inheriting.
//
// Returns: 
//   Nothing.
//////////////////////////////////////////////////////////////////////////////

void CAudOut::Stop(void)
{
  m_bActive = false;
}

//////////////////////////////////////////////////////////////////////////////
// @SetCurDev()
//
// Parameters:
//   iDevID - ID ofdevice in range [0, m_dwNumdev-1].
//
// Remarks:
//   None.
//
// Inheritance notes:
//   Shouldn't need inheriting.
//
// Returns: 
//   True if all is well, 
//   False is device is active or iDevID is out of range.
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::SetCurDev(short iDevID)
{
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::SetCurDev()";
#endif

  if (IsActive())
    m_err = err_notWhileActive;
  else if (iDevID < 0 || iDevID >= (short) m_dwNumDev)
    m_err = err_badDevID;
  else
    m_iCurDev = iDevID;

  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @PackOutput()
//
// Parameters:
//   input - array of channels, each an array of floats.
//   output - packed array of whatever the current device's output format is.
//
// Remarks:
//   Expects float values in the range [-1,1], will convert into the current
//   output format. (16/8 bit, mono/stereo, PCM only at the moment)
//
// Inheritence notes:
//   None. Shouldn't need to be inherited. You should call PackOutput() as
//   the final act of your AudioThread loop, to translate the output of 
//   your GenAudio() into the output format of the current device.
//
// Returns: 
//   True if all is well.
//   False if any of the arguments are NULL pointers
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::PackOutput(float** input, void* output)
{
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::PackOutput()";
#endif

  ASSERT(input);
  ASSERT(output);
  ASSERT(input[0] && input[1]);

  DWORD len;

  len = m_dwNumSamples;

  // Ensure all arguments are valid

  if (!(input && output))
  {
    m_err = err_badParam;
    return false;
  }
  switch (m_wfx.nChannels)
  {
  case 2:
    if (!input[1])
    {
      m_err = err_badParam;
      return false;
    }
  default: 
    if (!input[0])
    {
      m_err = err_badParam;
      return false;
    }
  }

  // Pack the input buffers into the output

  DWORD   i = 0;

  switch (m_wfx.wBitsPerSample)
  {
  case 8:                                                  // 8 bit output
    {
      char *pch = (char*) output;

      switch (m_wfx.nChannels)
      {
      case 1:                                              // mono
        for (i = 0; i < len; i++)
          pch[i] = (char) (127.0f * input[0][i]);
        break;
      case 2:                                              // stereo
        for (i = 0; i < len; i++)
        {
          pch [i*2 + 0] = (char) (127.0f * input[0][i]);
          pch [i*2 + 1] = (char) (127.0f * input[1][i]);
        }
        break;
      default:                                             // multi = error
        ASSERT(0);                                       
      }
    }
    break;
  case 16:                                                 // 16 bit output 
    {
      short *psh = (short*) output;

      switch (m_wfx.nChannels)
      {
      case 1:                                              // mono
        for (i = 0; i < len; i++)
          psh[i] = (short) (32768.0f * input[0][i]);
        break;
      case 2:                                              // stereo
        for (i = 0; i < len; i++)
        {
          psh [i*2 + 0] = (short) (32768.0f * input[0][i]);
          psh [i*2 + 1] = (short) (32768.0f * input[1][i]);
        }
        break;
      default:
        ASSERT(0);                                         // multi = error
      }
    }
    break;
  }
  return (m_err == err_none);
}

//////////////////////////////////////////////////////////////////////////////
// @GetErrMsg
//
// Parameters:
//   None.
//
// Remarks:
//   Uses current value of m_err to select error message.
//
// Inheritance notes:
//   None.
//
// Returns:
//   An MFC CString object for the moment, with error description.
//////////////////////////////////////////////////////////////////////////////

CString CAudOut::GetErrMsg(void)
{
  switch (m_err)
  {
  case err_none:
    m_errstr += "none"; break;
  case err_badAlloc:        
    m_errstr += "bad memory allocation"; break;
  case err_notInit:
    m_errstr += "not initialised"; break;
  case err_badParam:
    m_errstr += "bad parameter"; break;
  case err_notWhileActive:
    m_errstr += "Can't perform operation while active"; break;
  case err_badDevID:
    m_errstr += "Bad device ID"; break;
  case err_badGenAudioPtr:
    m_errstr += "Bad GenAudio pointer"; break;
  case err_badObjectState:
    m_errstr += "Bad object state"; break;
  case err_alreadyInit:
    m_errstr += "Already initialised"; break;
  default:
    m_errstr += "unknown";
  }
  return m_errstr;
}

//////////////////////////////////////////////////////////////////////////////
// @GetErrMsg
//
// Parameters:
//   pchErrTest - pointer to text buffer to copy err msg into
//   len        - size of the text buffer
//
// Remarks:
//   Uses current value of m_err to select error message.
//
// Inheritance notes:
//   None.
//
// Returns:
//   Nothing.
//////////////////////////////////////////////////////////////////////////////

void CAudOut::GetErrMsg (char* pchErrText, DWORD len)
{
  ASSERT (pchErrText != NULL);

  pchErrText[0] ='\0';
  strncat(pchErrText, m_errstr.GetBuffer(0), len);
  DWORD l = len - strlen(pchErrText);
  switch (m_err)
  {
  case err_none:
    strncat(pchErrText, "none", l); break;
  case err_badAlloc:        
    strncat(pchErrText, "bad memory allocation", l); break;
  case err_notInit:
    strncat(pchErrText, "not initialised", l); break;
  case err_badParam:
    strncat(pchErrText, "bad parameter", l); break;
  case err_notWhileActive:
    strncat(pchErrText, "Can't perform operation while active", l); break;
  case err_badDevID:
    strncat(pchErrText, "Bad device ID", l); break;
  case err_badGenAudioPtr:
    strncat(pchErrText, "Bad GenAudio pointer", l); break;
  case err_badObjectState:
    strncat(pchErrText, "Bad object state", l); break;
  case err_alreadyInit:
    strncat(pchErrText, "Already initialised", l); break;
  default:
    strncat(pchErrText, "unknown", l);
  }
}

//////////////////////////////////////////////////////////////////////////////
// @SetAudThreadPriority
//
// Parameters:
//
// Remarks:
//   Only call if you want to change the Audio Thread's priority.
//   By default, the thread is set to the second highest priority.
//   Note that p should be in the range specified by the CAudOut
//   enumerated type audPriority.
//
// Inheritance notes:
//   None.
//
// Returns:
//   True if priority successfully changed
//////////////////////////////////////////////////////////////////////////////

bool CAudOut::SetAudThreadPriority(short p)
{
  m_err = err_none;

#ifdef _DEBUG
  m_errstr = "CAudOut::SetAudThreadPriority()";
#endif

  if (p < audpriorityMin || p > audpriorityMax)
  {
    m_err = err_badParam;
    return false;
  }

  switch (p)
  { 
  case audpriorityIdle:
    m_iAudThreadPriority = THREAD_PRIORITY_IDLE; 
    break;
  case audpriorityLowest:
    m_iAudThreadPriority = THREAD_PRIORITY_LOWEST; 
    break;
  case audpriorityLow:
    m_iAudThreadPriority = THREAD_PRIORITY_BELOW_NORMAL; 
    break;
  case audpriorityNormal:
    m_iAudThreadPriority = THREAD_PRIORITY_NORMAL; 
    break;
  case audpriorityHighest:
    m_iAudThreadPriority = THREAD_PRIORITY_HIGHEST; 
    break;
  case audpriorityTimeCrit:
    m_iAudThreadPriority = THREAD_PRIORITY_TIME_CRITICAL; 
    break;
  case audpriorityHigh:
  default:
    m_iAudThreadPriority = THREAD_PRIORITY_ABOVE_NORMAL; 
  }
  if (m_bActive && m_hAudThread)
  {
    SetThreadPriority(m_hAudThread, m_iAudThreadPriority);
  }
  return true;
}

//////////////////////////////////////////////////////////////////////////////
// @GetAudThreadPriority
//
// Parameters:
//
// Remarks:
//
// Inheritance notes:
//   None.
//
// Returns:
//   
//////////////////////////////////////////////////////////////////////////////

short CAudOut::GetAudThreadPriority (void)
{
  short i = 0;

  switch (m_iAudThreadPriority)
  {
  case THREAD_PRIORITY_IDLE:
    i = audpriorityIdle;
    break;
  case THREAD_PRIORITY_LOWEST:
    i = audpriorityLowest;
    break;
  case THREAD_PRIORITY_BELOW_NORMAL:
    i = audpriorityLow;
    break;
  case THREAD_PRIORITY_NORMAL:
    i = audpriorityNormal;
    break;
  case THREAD_PRIORITY_HIGHEST:
    i = audpriorityHighest;
    break;
  case THREAD_PRIORITY_TIME_CRITICAL:
    i = audpriorityTimeCrit;
    break;
  case THREAD_PRIORITY_ABOVE_NORMAL:
  default:
    i = audpriorityHigh;
  }
  return i;
}
