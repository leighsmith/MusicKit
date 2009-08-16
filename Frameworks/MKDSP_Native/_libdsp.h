#ifndef __MK__libdsp_H___
#define __MK__libdsp_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* _libdsp.h - private functions in libdsp_s.a

	01/13/90/jos - Replaced _DSPMessage.h expansion by explicit import.
*/

#include "MKDSPDefines.h"

#import "_DSPTransfer.h"
#import "_DSPObject.h"
#import "_DSPMach.h"
#import "_DSPMessage.h"

/* ============================= _DSPRelocate.c ============================ */

MKDSP_API int _DSPReloc(DSPDataRecord *data, DSPFixup *fixups,
    int fixupCount, int *loadAddresses);
/* 
 * dataRec is assumed to be a P data space. Fixes it up in place. 
 * This is a private libdsp method used by _DSPSendUGTimed and
 * _DSPRelocate. 
 */

MKDSP_API int _DSPRelocate();
MKDSP_API int _DSPRelocateUser();

/* ============================= DSPControl.c ============================== */
MKDSP_API int _DSPCheckMappedMode();
MKDSP_API int _DSPEnterMappedMode();
MKDSP_API int _DSPEnterMappedModeNoCheck();
MKDSP_API int _DSPEnterMappedModeNoPing();
MKDSP_API int _DSPExitMappedMode();
MKDSP_API int _DSPReadSSI();
MKDSP_API int _DSPSetSCISCR();
MKDSP_API int _DSPSetSCISCCR();
MKDSP_API int _DSPSetSSICRA();
MKDSP_API int _DSPSetSSICRB();
MKDSP_API int _DSPSetStartTimed();
MKDSP_API int _DSPSetTime();
MKDSP_API int _DSPSetTimeFromInts();
MKDSP_API int _DSPSineTest();
MKDSP_API int _DSPStartTimed();
MKDSP_API DSPDatum _DSPGetValue();

/* ============================= DSPReadFile.c ============================= */
MKDSP_API char *_DSPFGetRecord();
MKDSP_API int _DSPGetIntHexStr6();
MKDSP_API int _DSPLnkRead();
MKDSP_API char *_DSPAddSymbol();
MKDSP_API int _DSPGetRelIntHexStr();
MKDSP_API char *_DSPUniqueName();

/* ============================ DSPStructMisc.c ============================ */

MKDSP_API int _DSPCheckingFWrite( int *ptr, int size, int nitems, FILE *stream);
MKDSP_API int _DSPWriteString(char *str, FILE *fp);
MKDSP_API int _DSPReadString(char **spp, FILE *fp);
MKDSP_API int _DSPFreeString(char *str);
MKDSP_API char *_DSPContiguousMalloc(unsigned size);
MKDSP_API int _DSPContiguousFree(char *ptr);
MKDSP_API void DSPMemMapInit(_DSPMemMap *mm);
MKDSP_API void DSPMemMapPrint(_DSPMemMap *mm);

MKDSP_API char *_DSPContiguousMalloc(unsigned size);
/*
 *	Same as malloc except allocates in one contiguous piece of
 *	memory.	 Calls realloc as necessary to extend the block.
 */


/* ============================ _DSPUtilities.c ============================ */
MKDSP_API void _DSPErr();
MKDSP_API char *_DSPFirstReadableFile(char *fn,...);
MKDSP_API char *_DSPGetBody();
MKDSP_API char _DSPGetField();
MKDSP_API int _DSPGetFilter();
MKDSP_API float _DSPGetFloatStr();
MKDSP_API char *_DSPGetHead();
MKDSP_API void _DSPGetInputFile();
MKDSP_API void _DSPGetInputOutputFiles();
MKDSP_API int _DSPGetIntStr();
MKDSP_API char *_DSPGetLineStr();
MKDSP_API void _DSPGetOutputFile();
MKDSP_API char *_DSPGetSN();
MKDSP_API char *_DSPGetTail();
MKDSP_API char *_DSPGetTokStr();
MKDSP_API int _DSPInInt();
MKDSP_API int _DSPIndexS();
MKDSP_API char *_DSPIntToChar();
MKDSP_API int *_DSPMakeArray();
MKDSP_API FILE *_DSPMyFopen();
MKDSP_API char *_DSPPadStr();
MKDSP_API void _DSPParseName();
MKDSP_API void _DSPPutFilter();
MKDSP_API char *_DSPRemoveHead();
MKDSP_API char *_DSPRemoveTail();
MKDSP_API int _DSPSaveMatD();
MKDSP_API int _DSPSezYes();
MKDSP_API char *_DSPSkipToWhite();
MKDSP_API char *_DSPSkipWhite();
MKDSP_API DSP_BOOL _DSPGetFile();
MKDSP_API DSPLocationCounter _DSPGetMemStr();
MKDSP_API DSP_BOOL _DSPNotBlank();

/* ============================ DSPConversion.c ============================ */

MKDSP_API DSPFix48 *_DSPDoubleIntToFix48UseArg(double dval,DSPFix48 *aFix48P);
/* 
 * The double is assumed to be between -2^47 and 2^47.
 *  Returns, in *aFix48P, the value as represented by dval. 
 *  aFix48P must point to a valid DSPFix48 struct. 
 */

/* ============================= _DSPError.c =============================== */

MKDSP_API int _DSPCheckErrorFP(void);
/*
 * Check error file-pointer.
 * If nonzero, return.
 * If zero, open /tmp/dsperrors and return file-pointer for it.
 * Also, write DSP interlock info to dsperrors.
 */


MKDSP_API int _DSPErrorV(int errorcode,char *fmt,...);


MKDSP_API int _DSPError1(
    int errorcode,
    char *msg,
    char *arg);


MKDSP_API int _DSPError(
    int errorcode,
    char *msg);


MKDSP_API void _DSPFatalError(
    int errorcode,
    char *msg);


MKDSP_API int _DSPMachError(
    int error,
    char *msg);


MKDSP_API int _DSPCheckErrorFP(void);
/*
 * Check error file-pointer.
 * If nonzero, return.
 * If zero, open /tmp/dsperrors and return file-pointer for it.
 * Also, write DSP interlock info to dsperrors.
 */


MKDSP_API int _DSPErrorV(int errorcode,char *fmt,...);


MKDSP_API int _DSPError1(
    int errorcode,
    char *msg,
    char *arg);


MKDSP_API int _DSPError(
    int errorcode,
    char *msg);


MKDSP_API void _DSPFatalError(
    int errorcode,
    char *msg);


MKDSP_API int _DSPMachError(
    int error,
    char *msg);

/* ============================== _DSPCV.c ================================= */

MKDSP_API char *_DSPCVAS(
    int n,			/* number to be converted */
    int fmt);			/* 0=decimal, 1=hex format */
/* 
 * Convert integer to decimal or hex string 
 */


MKDSP_API char *_DSPCVS(int n);
/* 
 * Convert integer to decimal string 
 */


MKDSP_API char *_DSPCVHS(int n);
/* 
 * Convert integer to hex string 
 */


MKDSP_API char *_DSPCVDS(float d);
/* 
 * Convert double to hex string 
 */


MKDSP_API char *_DSPCVFS(float f);
/* 
 * Convert float to hex string 
 */


MKDSP_API char *_DSPIntToChar(int i);
/* 
 * Convert digit between 0 and 9 to corresponding character.
 */

/* ============================ _DSPString.c =============================== */

MKDSP_API char *_DSPNewStr(int size);
/*
 * Create string of given total length in bytes.
 */


MKDSP_API char *_DSPMakeStr(
    int size,			/* size = total length incl \0 */
    char *init);		/* initialization string */
/* 
 * create new string initialized by given string.
 */


MKDSP_API char *_DSPCat(
    char *f1,
    char *f2);
/*
 * Concatenate two strings 
 */


MKDSP_API char *_DSPReCat(
    char *f1,
    char *f2);
/*
 * append second string to first via realloc 
 */


MKDSP_API char *_DSPCopyStr(char *s);
/*
 * Copy string s into freshly malloc'd storage.
 */


MKDSP_API char *_DSPToLowerStr(
    char *s);			/* input string = output string */
/*
 * Convert all string chars to lower case.
 */


MKDSP_API char *_DSPToUpperStr(
    char *s);			/* input string = output string */
/*
 * Convert all string chars to upper case.
 */

MKDSP_API char *_DSPCopyToUpperStr(
    char *s);			/* input string = output string */
/*
 * Efficient combo of _DSPCopyStr and _DSPToUpperStr 
 */

MKDSP_API int _DSPStrCmpI(char *mixedCaseStr,char *upperCaseStr) ;
/* like strcmp but assumes first arg is mixed case and second is upper case
 * and does a case-independent compare.
 *
 * _DSPStrCmpI compares its arguments and returns an integer greater
 * than, equal to, or less than 0, according as mixedCaseStr is lexico-
 * graphically greater than, equal to, or less than upperCaseStr.
 */

#endif

