/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* DSPGlobals.c - global variables and arrays among libdsp routines */

/* 10/01/90/jos - added #pragma line */

#ifdef SHLIB
#pragma CC_NO_MACH_TEXT_SECTIONS
#include "shlib.h"
#endif

#include "dsp.h"

// #include <sys/time.h> // LMS do we really need this?

extern const char LITERAL_N[];
extern const char LITERAL_X[];
extern const char LITERAL_XL[];
extern const char LITERAL_XH[];
extern const char LITERAL_Y[];
extern const char LITERAL_YL[];
extern const char LITERAL_YH[];
extern const char LITERAL_L[];
extern const char LITERAL_LL[];
extern const char LITERAL_LH[];
extern const char LITERAL_P[];
extern const char LITERAL_PL[];
extern const char LITERAL_PH[];
extern const char LITERAL_GLOBAL[];
extern const char LITERAL_SYSTEM[];
extern const char LITERAL_USER[];

/**** Global const data ****/

/* global arrays declared in dspstructs.h */

const char * const  DSPSectionNames[DSP_N_SECTIONS] =
	{ LITERAL_GLOBAL, LITERAL_SYSTEM, LITERAL_USER};

/* DSP Location Counter names */
const char * const DSPLCNames[DSP_LC_NUM] = { LITERAL_N,
			       LITERAL_X, LITERAL_XL, LITERAL_XH, 
			       LITERAL_Y, LITERAL_YL, LITERAL_YH, 
			       LITERAL_L, LITERAL_LL, LITERAL_LH, 
			       LITERAL_P, LITERAL_PL, LITERAL_PH};

// LMS: changed this from an array of strings to get around link problems with MS Win32 DLLs.
#if 0
const char * const DSPMemoryNames[(int)DSP_MS_Num] = {
		LITERAL_N, LITERAL_X, LITERAL_Y, LITERAL_L, LITERAL_P};
#else
const char * DSPMemoryNames(int memorySpaceNum)
{
    static const char *memNames[] = { LITERAL_N, LITERAL_X, LITERAL_Y, LITERAL_L, LITERAL_P };

    return memNames[memorySpaceNum];
}
#endif

#ifdef SHLIB
static const char _libdsp_constdata_pad1[172] = { 0 };
#endif

/**** Literal const data ****/
static const char LITERAL_N[] = "N";
static const char LITERAL_X[] = "X";
static const char LITERAL_XL[] = "XL";
static const char LITERAL_XH[] = "XH";
static const char LITERAL_Y[] = "Y";
static const char LITERAL_YL[] = "YL";
static const char LITERAL_YH[] = "YH";
static const char LITERAL_L[] = "L";
static const char LITERAL_LL[] = "LL";
static const char LITERAL_LH[] = "LH";
static const char LITERAL_P[] = "P";
static const char LITERAL_PL[] = "PL";
static const char LITERAL_PH[] = "PH";
static const char LITERAL_GLOBAL[] = "GLOBAL";
static const char LITERAL_SYSTEM[] = "SYSTEM";
static const char LITERAL_USER[] = "USER";

#ifdef SHLIB
static const char _libdsp_constdata_pad2[203] = { 0 };
#endif

/**** Global data ****/

/* global variables declared in dsp.h and _dsp.h */

int	 DSPErrorNo = 0;	/* Last DSP error */
int 	 DSPDefaultTimeLimit=1000; /* 1 second */
int	 DSPAPTimeLimit = 0;	/* Max time to wait for AP func execution */
DSPFix48 DSPMKTimeStamp0 = {0,0}; /* Denotes tick-synchronized untimed xfers */
int	_DSPTrace = 0;		/* Global trace control */
int	_DSPVerbose = 0;	/* nonzero for maximum verbiage */

int	DSPLCtoMS[DSP_LC_NUM] = {0,1,1,1,2,2,2,3,3,3,4,4,4};

char _libdsp_data_pad[416] = { 0 };

