/*
 * PortAudio Portable Real-Time Audio Library
 * Latest Version at: http://www.portaudio.com
 * Linux OSS Implementation by douglas repetto and Phil Burk
 *
 * Copyright (c) 1999-2000 Phil Burk
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * Any person wishing to distribute modifications to the Software is
 * requested to send the modifications to the original developer so that
 * they can be incorporated into the canonical version.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */
/*
Modfication History
  1/2001 - Phil Burk - initial hack for Linux
  2/2001 - Douglas Repetto - many improvements, initial query support
  4/2/2001 - Phil - stop/abort thread control, separate in/out native buffers
  5/28/2001 - Phil - use pthread_create() instead of clone(). Thanks Stephen Brandon!
		     use pthread_join() after thread shutdown.
  5/29/2001 - Phil - query for multiple devices, multiple formats,
                     input mode and input+output mode working,
		     Pa_GetCPULoad() implemented,
TODO
O- set fragment size based on user selected numBuffers, and maybe on environment variable
O- change Pa_StreamTime() to query device
O- put semaphore lock around shared data?
O- handle native formats better
*/

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <math.h>
#include "portaudio.h"
#include "pa_host.h"
#include "pa_trace.h"

#include <sys/ioctl.h>
#include <sys/time.h>
#include <fcntl.h> 
#include <unistd.h> 
#include <signal.h> 
#include <stdio.h> 
#include <stdlib.h> 
#include <linux/soundcard.h> 
#include <sched.h> 
#include <pthread.h> 
                           
#define PRINT(x)   { printf x; fflush(stdout); }
#define ERR_RPT(x) PRINT(x)
#define DBUG(x)     PRINT(x)
#define DBUGX(x)    PRINT(x)

#define BAD_DEVICE_ID (-1)

#define MIN_TIMEOUT_MSEC   (100)
#define MAX_TIMEOUT_MSEC   (1000)

/************************************************* Definitions ********/
#define DEVICE_NAME_BASE            "/dev/audio"
#define MAX_CHARS_DEVNAME           (32)
#define MAX_SAMPLE_RATES            (10)
typedef struct internalPortAudioDevice
{
	struct internalPortAudioDevice *pad_Next; /* Singly linked list. */
	double          pad_SampleRates[MAX_SAMPLE_RATES]; /* for pointing to from pad_Info */
	char            pad_DeviceName[MAX_CHARS_DEVNAME];
	PaDeviceInfo    pad_Info;
} internalPortAudioDevice;

/* Define structure to contain all OSS and Linux specific data. */
typedef struct PaHostSoundControl
{
	int              pahsc_OutputHandle;
	int              pahsc_InputHandle;
	pthread_t        pahsc_ThreadPID;
	short           *pahsc_NativeInputBuffer;
	short           *pahsc_NativeOutputBuffer;
	unsigned int     pahsc_BytesPerInputBuffer;    /* native buffer size in bytes */
	unsigned int     pahsc_BytesPerOutputBuffer;   /* native buffer size in bytes */
/* For measuring CPU utilization. */
	struct itimerval pahsc_EntryTime;
	struct itimerval pahsc_LastExitTime;
	long             pahsc_InsideCountSum;
	long             pahsc_TotalCountSum;
} PaHostSoundControl;

/************************************************* Shared Data ********/
/* FIXME - put Mutex around this shared data. */
static int sNumDevices = 0;
static int sDeviceIndex = 0;
static internalPortAudioDevice *sDeviceList = NULL;
static int sDefaultInputDeviceID = paNoDevice;
static int sDefaultOutputDeviceID = paNoDevice;
static int sEnumerationError;
static int sPaHostError = 0;

/************************************************* Prototypes **********/

static internalPortAudioDevice *Pa_GetInternalDevice( PaDeviceID id );
static Pa_QueryDevices( void );
static PaError Pa_QueryDevice( const char *deviceName, internalPortAudioDevice *pad );
static PaError Pa_SetupDeviceFormat( int devHandle, int numChannels, int sampleRate );

/********************************* BEGIN CPU UTILIZATION MEASUREMENT ****/
static void Pa_StartUsageCalculation( internalPortAudioStream   *past )
{
	struct itimerval itimer;
	PaHostSoundControl *pahsc = (PaHostSoundControl *) past->past_DeviceData;
	if( pahsc == NULL ) return;
/* Query system timer for usage analysis and to prevent overuse of CPU. */
	getitimer( ITIMER_REAL, &pahsc->pahsc_EntryTime );
}

static long SubtractTime_AminusB( struct itimerval *timeA, struct itimerval *timeB )
{
	long secs = timeA->it_value.tv_sec - timeB->it_value.tv_sec;
	long usecs = secs * 1000000;
	usecs += (timeA->it_value.tv_usec - timeB->it_value.tv_usec);
	return usecs;
}

static void Pa_EndUsageCalculation( internalPortAudioStream   *past )
{
	struct itimerval currentTime;
	long  insideCount;
	long  totalCount;
/*
** Measure CPU utilization during this callback.
*/
#define LOWPASS_COEFFICIENT_0   (0.95)
#define LOWPASS_COEFFICIENT_1   (0.99999 - LOWPASS_COEFFICIENT_0)

	PaHostSoundControl *pahsc = (PaHostSoundControl *) past->past_DeviceData;
	if( pahsc == NULL ) return;

	if( getitimer( ITIMER_REAL, &currentTime ) == 0 )
	{
		if( past->past_IfLastExitValid )
		{
			insideCount = SubtractTime_AminusB( &pahsc->pahsc_EntryTime, &currentTime );
			pahsc->pahsc_InsideCountSum += insideCount;
			totalCount =  SubtractTime_AminusB( &pahsc->pahsc_LastExitTime, &currentTime );
			pahsc->pahsc_TotalCountSum += totalCount;
			DBUG(("insideCount = %d, totalCount = %d\n", insideCount, totalCount ));
/* Low pass filter the result because sometimes we get called several times in a row.
 * That can cause the TotalCount to be very low which can cause the usage to appear
 * unnaturally high. So we must filter numerator and denominator separately!!!
 */
 			if( pahsc->pahsc_InsideCountSum > 0 )
			{
				past->past_AverageInsideCount = (( LOWPASS_COEFFICIENT_0 * past->past_AverageInsideCount) +
					(LOWPASS_COEFFICIENT_1 * pahsc->pahsc_InsideCountSum));
				past->past_AverageTotalCount = (( LOWPASS_COEFFICIENT_0 * past->past_AverageTotalCount) +
					(LOWPASS_COEFFICIENT_1 * pahsc->pahsc_TotalCountSum));
					
				past->past_Usage = past->past_AverageInsideCount / past->past_AverageTotalCount;
				
				pahsc->pahsc_InsideCountSum = 0;
				pahsc->pahsc_TotalCountSum = 0;
			}
		}
		past->past_IfLastExitValid = 1;
	}
	
	pahsc->pahsc_LastExitTime.it_value.tv_sec = 100;
	pahsc->pahsc_LastExitTime.it_value.tv_usec = 0;
	setitimer( ITIMER_REAL, &pahsc->pahsc_LastExitTime, NULL );
	past->past_IfLastExitValid = 1;
}
/****************************************** END CPU UTILIZATION *******/

/*********************************************************************
 * Try to open the named device.
 * If it opens, try to set various rates and formats and fill in 
 * the device info structure.
 */
static PaError Pa_QueryDevice( const char *deviceName, internalPortAudioDevice *pad )
{
	int numBytes;
	int tempDevHandle;
	int numChannels, maxNumChannels;
	int format;
	int numSampleRates;
	int sampleRate;
	int numRatesToTry = 7;
	int ratesToTry[7] = {96000, 48000, 44100, 32000, 22050, 11025, 8000};
	int i;

/* douglas: 
	we have to do this querying in a slightly different order. apparently
	some sound cards will give you different info based on their settins. 
	e.g. a card might give you stereo at 22kHz but only mono at 44kHz.
	the correct order for OSS is: format, channels, sample rate

*/
	if ( (tempDevHandle = open(deviceName,O_WRONLY))  == -1 )
	{
		DBUG(("Pa_QueryDevice: could not open %s\n", deviceName ));
		return paHostError;
	}
	
/*  Ask OSS what formats are supported by the hardware. */
	pad->pad_Info.nativeSampleFormats = 0;
	if (ioctl(tempDevHandle, SNDCTL_DSP_GETFMTS, &format) == -1)
	{
		ERR_RPT(("Pa_QueryDevice: could not get format info\n" ));
		return 0;
	}
	if( format & AFMT_U8 )     pad->pad_Info.nativeSampleFormats |= paUInt8;
	if( format & AFMT_S16_NE ) pad->pad_Info.nativeSampleFormats |= paInt16;

/* Start with 16 as a hard coded upper number of channels.
	numChannels should return the actual upper limit.
   Stephen Brandon: causes problems on my machine -- I'll start with 2
 */
	numChannels = 2;
	if (ioctl(tempDevHandle, SNDCTL_DSP_CHANNELS, &numChannels) == -1)
	{
		ERR_RPT(("Pa_QueryDevice: SNDCTL_DSP_CHANNELS failed\n" ));
		return paHostError;
	}
	pad->pad_Info.maxOutputChannels = numChannels;
	DBUG(("Pa_QueryDevice: maxOutputChannels = %d\n", 
		pad->pad_Info.maxOutputChannels))
		
/* FIXME - for now, assume maxInputChannels = maxOutputChannels.
 *    Eventually do separate queries for O_WRONLY and O_RDONLY
*/
	pad->pad_Info.maxInputChannels = pad->pad_Info.maxOutputChannels;
	
	DBUG(("Pa_QueryDevice: maxInputChannels = %d\n", 
		pad->pad_Info.maxInputChannels))


/* douglas:
	again, i'm not sure if there's any way other than brute force to
	do this. i'll do: 96k, 48k, 44.1k, 32k, 22050, 11025 and 8k
*/

	numSampleRates = 0;

	for (i = 0; i < numRatesToTry; i++)
	{
		sampleRate = ratesToTry[i];
		
		if (ioctl(tempDevHandle, SNDCTL_DSP_SPEED, &sampleRate) == -1)
		{
			ERR_RPT(("Pa_QueryDevice: SNDCTL_DSP_SPEED ioctl call failed.\n" ));
			return paHostError;
		}
		
		if (sampleRate == ratesToTry[i])
		{
			DBUG(("Pa_QueryDevice: got sample rate: %d\n", sampleRate))
			pad->pad_SampleRates[numSampleRates] = (float)ratesToTry[i];
			numSampleRates++;
		}
	}

	DBUG(("Pa_QueryDevice: final numSampleRates = %d\n", numSampleRates))

	pad->pad_Info.numSampleRates = numSampleRates;
	pad->pad_Info.sampleRates = pad->pad_SampleRates;
	
	pad->pad_Info.name = deviceName;

/* We MUST close the handle here or we won't be able to reopen it later!!!  */
	close(tempDevHandle);

	return paNoError;
}

/*********************************************************************
 * Determines the number of available devices by trying to open
 * each "/dev/dsp#" in order until it fails.
 * Add each working device to a singly linked list of devices.
 */
static PaError Pa_QueryDevices( void )
{
	internalPortAudioDevice *pad, *lastPad;
	int      numBytes;
	int      go = 1;
	PaError  testResult;
	PaError  result = paNoError;
	
	sDefaultInputDeviceID = paNoDevice;
	sDefaultOutputDeviceID = paNoDevice;

	sNumDevices = 0;
	lastPad = NULL;
	
	while( go )
	{
/* Allocate structure to hold device info. */
		pad = PaHost_AllocateFastMemory( sizeof(internalPortAudioDevice) );
		if( pad == NULL ) return paInsufficientMemory;
		memset( pad, 0, sizeof(internalPortAudioDevice) );
		
/* Build name for device. */
		if( sNumDevices == 0 )
		{
			sprintf( pad->pad_DeviceName, DEVICE_NAME_BASE);
		}
		else
		{
			sprintf( pad->pad_DeviceName, DEVICE_NAME_BASE "%d", sNumDevices );
		}
		
		DBUG(("Try device %s\n", pad->pad_DeviceName ));
		testResult = Pa_QueryDevice( pad->pad_DeviceName, pad );
		DBUG(("Pa_QueryDevice returned %d\n", testResult ));
		if( testResult != paNoError )
		{
			if( lastPad == NULL )
			{
				result = testResult; /* No good devices! */
			}
			go = 0;
			PaHost_FreeFastMemory( pad, sizeof(internalPortAudioDevice) );
		}
		else
		{
			sNumDevices += 1;
		/* Add to linked list of devices. */
			if( lastPad )
			{
				lastPad->pad_Next = pad;
			}
			else
			{
				sDeviceList = pad; /* First element in linked list. */
			}
			lastPad = pad;
		}
	}
	
	return result;
	
}

/*************************************************************************/
int Pa_CountDevices()
{
	if( sNumDevices <= 0 ) Pa_Initialize();
	return sNumDevices;
}

static internalPortAudioDevice *Pa_GetInternalDevice( PaDeviceID id )
{
	internalPortAudioDevice *pad;
	if( (id < 0) || ( id >= Pa_CountDevices()) ) return NULL;
	pad = sDeviceList;
	while( id > 0 ) pad = pad->pad_Next;
	return pad;
}

/*************************************************************************/
const PaDeviceInfo* Pa_GetDeviceInfo( PaDeviceID id )
{
	internalPortAudioDevice *pad;
	if( (id < 0) || ( id >= Pa_CountDevices()) ) return NULL;
	pad = Pa_GetInternalDevice( id );
	return  &pad->pad_Info ;
}

static PaError Pa_MaybeQueryDevices( void )
{
	if( sNumDevices == 0 )
	{
		return Pa_QueryDevices();
	}
	return 0;
}

PaDeviceID Pa_GetDefaultInputDeviceID( void )
{
	//return paNoDevice;
	return 0;
}

PaDeviceID Pa_GetDefaultOutputDeviceID( void )
{
	return 0;
}

/**********************************************************************
** Make sure that we have queried the device capabilities.
*/

PaError PaHost_Init( void )
{
	return Pa_MaybeQueryDevices();
}

/*******************************************************************************************/
static PaError Pa_AudioThreadProc( internalPortAudioStream   *past )
{
	PaError				result = 0;
	PaHostSoundControl             *pahsc;
 	short				bytes_read = 0;
	//sbrandon: for GNUSTEP, register thread
#ifdef GNUSTEP
	GSRegisterCurrentThread();
#endif
 	
	pahsc = (PaHostSoundControl *) past->past_DeviceData;
	if( pahsc == NULL ) return paInternalError;

	past->past_IsActive = 1;
	DBUG(("entering thread.\n"));
	
	while( (past->past_StopNow == 0) && (past->past_StopSoon == 0) )
	{

		DBUG(("go!\n"));
	/* Read data from device */
		if(pahsc->pahsc_NativeInputBuffer)
		{
	           	bytes_read = read(pahsc->pahsc_InputHandle,
				(void *)pahsc->pahsc_NativeInputBuffer,
				pahsc->pahsc_BytesPerInputBuffer);  
            	
			DBUG(("bytes_read: %d\n", bytes_read));
		}
	
		Pa_StartUsageCalculation( past );
	/* Convert 16 bit native data to user data and call user routine. */
		DBUG(("converting...\n"));
		result = Pa_CallConvertInt16( past,
				pahsc->pahsc_NativeInputBuffer,
				pahsc->pahsc_NativeOutputBuffer );

		Pa_EndUsageCalculation( past );
		if( result != 0) 
		{
			DBUG(("hmm, Pa_CallConvertInt16() says: %d. i'm bailing.\n",
				result));
			break;
		}

	/* Write data to device. */
		if( pahsc->pahsc_NativeOutputBuffer )
		{
{int i; for ( i = 0; i < 100 ; i++) {printf("%d ",((short*)(pahsc->pahsc_NativeOutputBuffer))[i] );}}
            		write(pahsc->pahsc_OutputHandle,
				(void *)pahsc->pahsc_NativeOutputBuffer,
            			pahsc->pahsc_BytesPerOutputBuffer);  	
		}
	}

	past->past_IsActive = 0;
	DBUG(("leaving thread.\n"));
#ifdef GNUSTEP
	GSUnregisterCurrentThread();
#endif
	return 0;
}

/*******************************************************************************************/
static PaError Pa_SetupDeviceFormat( int devHandle, int numChannels, int sampleRate )
{
	PaError result = paNoError;
	int     tmp;

/* Set fragment length to shorter than default so we get decent latency.
	(2<<16) - We want two fragments 
	13      - The size of fragment is 2^13 = 8192 bytes 
*/ 
	tmp=(2<<16)+13; 
	if(ioctl(devHandle,SNDCTL_DSP_SETFRAGMENT,&tmp) == -1)
	{
		ERR_RPT(("Pa_SetupDeviceFormat: could not SNDCTL_DSP_SETFRAGMENT\n" ));
		/* Don't return an error. Best to just continue and hope for the best. */
	}

	
/* Set data format. FIXME - handle more native formats. */
	tmp = AFMT_S16_NE;		
	if( ioctl(devHandle,SNDCTL_DSP_SETFMT,&tmp) == -1)
	{
		ERR_RPT(("Pa_SetupDeviceFormat: could not SNDCTL_DSP_SETFMT\n" ));
		return paHostError;
	}
	if( tmp != AFMT_S16_NE)
	{
		ERR_RPT(("Pa_SetupDeviceFormat: HW does not support AFMT_S16_NE\n" ));
		return paHostError;
	}
	

/* Set number of channels. */
	numChannels = 2;
	if (ioctl(devHandle, SNDCTL_DSP_CHANNELS, &numChannels) == -1)
	{
		ERR_RPT(("Pa_SetupDeviceFormat: could not SNDCTL_DSP_STEREO\n" ));
		return paHostError;
	}
	
/* Set playing frequency. 44100, 22050 and 11025 are safe bets. */
	tmp = sampleRate; 
	if( ioctl(devHandle,SNDCTL_DSP_SPEED,&tmp) == -1)
	{
		ERR_RPT(("Pa_SetupDeviceFormat: could not SNDCTL_DSP_STEREO\n" ));
		return paHostError;
	}
	
	return result;
}		

/*******************************************************************/
PaError PaHost_OpenStream( internalPortAudioStream   *past )
{
	PaError          result = paNoError;
	PaHostSoundControl *pahsc;
	int tmp;
	int flags;
	int              numBytes, maxChannels;
	unsigned int     minNumBuffers;
	internalPortAudioDevice *pad;
	DBUG(("PaHost_OpenStream() called.\n" ));

/* Allocate and initialize host data. */
	pahsc = (PaHostSoundControl *) malloc(sizeof(PaHostSoundControl));
	if( pahsc == NULL )
	{
		result = paInsufficientMemory;
		goto error;
	}
	memset( pahsc, 0, sizeof(PaHostSoundControl) );
	past->past_DeviceData = (void *) pahsc;

	pahsc->pahsc_OutputHandle = BAD_DEVICE_ID; /* No device currently opened. */
	pahsc->pahsc_InputHandle = BAD_DEVICE_ID;
	
/* Allocate native buffers. */
	pahsc->pahsc_BytesPerInputBuffer = past->past_FramesPerUserBuffer *
		past->past_NumInputChannels * sizeof(short);
	if( past->past_NumInputChannels > 0)
	{
		pahsc->pahsc_NativeInputBuffer = (short *) malloc(pahsc->pahsc_BytesPerInputBuffer);
		if( pahsc->pahsc_NativeInputBuffer == NULL )
		{
			result = paInsufficientMemory;
			goto error;
		}
	}
	pahsc->pahsc_BytesPerOutputBuffer = past->past_FramesPerUserBuffer *
		past->past_NumOutputChannels * sizeof(short);
	if( past->past_NumOutputChannels > 0)
	{
		pahsc->pahsc_NativeOutputBuffer = (short *) malloc(pahsc->pahsc_BytesPerOutputBuffer);
		if( pahsc->pahsc_NativeOutputBuffer == NULL )
		{
			result = paInsufficientMemory;
			goto error;
		}
	}
	
	//DBUG(("PaHost_OpenStream: pahsc_MinFramesPerHostBuffer = %d\n", pahsc->pahsc_MinFramesPerHostBuffer ));
	minNumBuffers = Pa_GetMinNumBuffers( past->past_FramesPerUserBuffer, past->past_SampleRate );
	past->past_NumUserBuffers = ( minNumBuffers > past->past_NumUserBuffers ) ? minNumBuffers : past->past_NumUserBuffers;

/* ------------------------- OPEN DEVICE -----------------------*/
	    
	/* just output */
	if (past->past_OutputDeviceID == past->past_InputDeviceID)
	{
	
		if ((past->past_NumOutputChannels > 0) && (past->past_NumInputChannels > 0) )
		{
			pad = Pa_GetInternalDevice( past->past_OutputDeviceID );
			DBUG(("PaHost_OpenStream: attempt to open %s for O_RDWR\n", pad->pad_DeviceName ));
			pahsc->pahsc_OutputHandle = pahsc->pahsc_InputHandle =
				open(pad->pad_DeviceName,O_RDWR); 
			if(pahsc->pahsc_InputHandle==-1)
			{
				ERR_RPT(("PaHost_OpenStream: could not open %s for O_RDWR\n", pad->pad_DeviceName ));
				result = paHostError;
				goto error;
			} 
			result = Pa_SetupDeviceFormat( pahsc->pahsc_OutputHandle,
				past->past_NumOutputChannels, (int)past->past_SampleRate );
		}
	}
	else
	{
		if (past->past_NumOutputChannels > 0)
		{	    
			pad = Pa_GetInternalDevice( past->past_OutputDeviceID );
			DBUG(("PaHost_OpenStream: attempt to open %s for O_WRONLY\n", pad->pad_DeviceName ));
			pahsc->pahsc_OutputHandle = open(pad->pad_DeviceName,O_WRONLY); 
			if(pahsc->pahsc_OutputHandle==-1)
			{
				ERR_RPT(("PaHost_OpenStream: could not open %s for O_WRONLY\n", pad->pad_DeviceName ));
				result = paHostError;
				goto error;
			} 
			result = Pa_SetupDeviceFormat( pahsc->pahsc_OutputHandle,
				past->past_NumOutputChannels, (int)past->past_SampleRate );
		}

		if (past->past_NumInputChannels > 0)
		{	    
			pad = Pa_GetInternalDevice( past->past_InputDeviceID );
			DBUG(("PaHost_OpenStream: attempt to open %s for O_RDONLY\n", pad->pad_DeviceName ));
			pahsc->pahsc_InputHandle = open(pad->pad_DeviceName,O_RDONLY); 
			if(pahsc->pahsc_InputHandle==-1)
			{
				ERR_RPT(("PaHost_OpenStream: could not open %s for O_RDONLY\n", pad->pad_DeviceName ));
				result = paHostError;
				goto error;
			} 
			result = Pa_SetupDeviceFormat( pahsc->pahsc_InputHandle,
				past->past_NumInputChannels, (int)past->past_SampleRate );
		}
	}
 		
 
	DBUG(("PaHost_OpenStream: SUCCESS - result = %d\n", result ));
	return result;
	
error:
	ERR_RPT(("PaHost_OpenStream: ERROR - result = %d\n", result ));
	PaHost_CloseStream( past );
	return result;
}

/*************************************************************************/
PaError PaHost_StartOutput( internalPortAudioStream *past )
{
	return paNoError;
}

/*************************************************************************/
PaError PaHost_StartInput( internalPortAudioStream *past )
{
	return paNoError;
}

/*************************************************************************/
PaError PaHost_StartEngine( internalPortAudioStream *past )
{
	PaHostSoundControl *pahsc;
	PaError             result = paNoError;
	int                 hres;
	
	pahsc = (PaHostSoundControl *) past->past_DeviceData;

	past->past_StopSoon = 0;
	past->past_StopNow = 0;
        past->past_IsActive = 1; 

/* Use pthread_create() instead of __clone() because:
 *   - pthread_create also works for other UNIX systems like Solaris,
 *   - the Java HotSpot VM crashes in pthread_setcanceltype() when using __clone()
 */
	hres = pthread_create(&(pahsc->pahsc_ThreadPID),
		NULL /*pthread_attr_t * attr*/,
		(void*)Pa_AudioThreadProc, past);
	if( hres != 0 )
	{
		result = paHostError;
		sPaHostError = hres;
		goto error;
	}

error:
	return result;
}

/*************************************************************************/
PaError PaHost_StopEngine( internalPortAudioStream *past, int abort )
{
	int                 hres;
	long                timeOut;
	PaError             result = paNoError;
	PaHostSoundControl *pahsc = (PaHostSoundControl *) past->past_DeviceData;
	
	if( pahsc == NULL ) return paNoError;
 
/* Tell background thread to stop generating more data and to let current data play out. */
        past->past_StopSoon = 1;
/* If aborting, tell background thread to stop NOW! */
        if( abort ) past->past_StopNow = 1;

/* Join thread to recover memory resources. */
	if( pahsc->pahsc_ThreadPID != -1 )
	{
		hres = pthread_join( pahsc->pahsc_ThreadPID, NULL );
		if( hres != 0 )
		{
			result = paHostError;
			sPaHostError = hres;
		}
		pahsc->pahsc_ThreadPID = -1;
	}
	
        past->past_IsActive = 0;      

	return result;
}

/*************************************************************************/
PaError PaHost_StopInput( internalPortAudioStream *past, int abort )
{
	return paNoError;
}

/*************************************************************************/
PaError PaHost_StopOutput( internalPortAudioStream *past, int abort )
{
	return paNoError;
}

/*******************************************************************/
PaError PaHost_CloseStream( internalPortAudioStream   *past )
{
	PaHostSoundControl *pahsc;
	if( past == NULL ) return paBadStreamPtr;
	pahsc = (PaHostSoundControl *) past->past_DeviceData;
	if( pahsc == NULL ) return paNoError;

	if( pahsc->pahsc_OutputHandle != BAD_DEVICE_ID )
	{
		int err;
		DBUG(("PaHost_CloseStream: attempt to close output device handle = %d\n",
			pahsc->pahsc_OutputHandle ));
		err = close(pahsc->pahsc_OutputHandle);
		if( err < 0 )
		{
			ERR_RPT(("PaHost_CloseStream: warning, closing output device failed.\n"));
		}
	}
	
	if( (pahsc->pahsc_InputHandle != BAD_DEVICE_ID) &&
	    (pahsc->pahsc_InputHandle != pahsc->pahsc_OutputHandle) )
	{
		int err;
		DBUG(("PaHost_CloseStream: attempt to close input device handle = %d\n",
			pahsc->pahsc_InputHandle ));
		err = close(pahsc->pahsc_InputHandle);
		if( err < 0 )
		{
			ERR_RPT(("PaHost_CloseStream: warning, closing input device failed.\n"));
		}
	}
	pahsc->pahsc_OutputHandle = BAD_DEVICE_ID;
	pahsc->pahsc_InputHandle = BAD_DEVICE_ID;
	
	if( pahsc->pahsc_NativeInputBuffer )
	{
		free( pahsc->pahsc_NativeInputBuffer );
		pahsc->pahsc_NativeInputBuffer = NULL;
	}
	if( pahsc->pahsc_NativeOutputBuffer )
	{
		free( pahsc->pahsc_NativeOutputBuffer );
		pahsc->pahsc_NativeOutputBuffer = NULL;
	}

	free( pahsc );
	past->past_DeviceData = NULL;
	return paNoError;
}

/*************************************************************************
** Determine minimum number of buffers required for this host based
** on minimum latency. Latency can be optionally set by user by setting
** an environment variable. For example, to set latency to 200 msec, put:
**
**    set PA_MIN_LATENCY_MSEC=200
**
** in the AUTOEXEC.BAT file and reboot.
** If the environment variable is not set, then the latency will be determined
** based on the OS. Windows NT has higher latency than Win95.
*/
#define PA_LATENCY_ENV_NAME  ("PA_MIN_LATENCY_MSEC")

int Pa_GetMinNumBuffers( int framesPerBuffer, double sampleRate )
{

	return 2;
}

/*************************************************************************/
PaError PaHost_Term( void )
{
/* Free all of the linked devices. */
	internalPortAudioDevice *pad, *nextPad;
	pad = sDeviceList;
	while( pad != NULL )
	{
		nextPad = pad->pad_Next;
		DBUG(("PaHost_Term: freeing %s\n", pad->pad_DeviceName ));
		PaHost_FreeFastMemory( pad, sizeof(internalPortAudioDevice) );
		pad = nextPad;
	}
	sDeviceList = NULL;
	sNumDevices = 0;
	return 0;
}

/*************************************************************************
 * Sleep for the requested number of milliseconds.
 */
void Pa_Sleep( long msec )
{
#if 0
	struct timeval timeout;
	timeout.tv_sec = msec / 1000;
	timeout.tv_usec = (msec % 1000) * 1000;
	select( 0, NULL, NULL, NULL, &timeout );
#else
	long usecs = msec * 1000;
	usleep( usecs );
#endif
}

/*************************************************************************
 * Allocate memory that can be accessed in real-time.
 * This may need to be held in physical memory so that it is not
 * paged to virtual memory.
 * This call MUST be balanced with a call to PaHost_FreeFastMemory().
 */
void *PaHost_AllocateFastMemory( long numBytes )
{
	void *addr = malloc( numBytes ); /* FIXME - do we need physical memory? */
	if( addr != NULL ) memset( addr, 0, numBytes );
	return addr;
}

/*************************************************************************
 * Free memory that could be accessed in real-time.
 * This call MUST be balanced with a call to PaHost_AllocateFastMemory().
 */
void PaHost_FreeFastMemory( void *addr, long numBytes )
{
	if( addr != NULL ) free( addr );
}


/***********************************************************************/
PaError PaHost_StreamActive( internalPortAudioStream   *past )
{
	PaHostSoundControl *pahsc;
	if( past == NULL ) return paBadStreamPtr;
	pahsc = (PaHostSoundControl *) past->past_DeviceData;
	if( pahsc == NULL ) return paInternalError;
	return (PaError) (past->past_IsActive != 0);
}

/***********************************************************************/
PaTimestamp Pa_StreamTime( PortAudioStream *stream )
{
	internalPortAudioStream *past = (internalPortAudioStream *) stream; 
/* FIXME - return actual frames played, not frames generated.
** Need to query the output device somehow.
*/
	return past->past_FrameCount;
}

