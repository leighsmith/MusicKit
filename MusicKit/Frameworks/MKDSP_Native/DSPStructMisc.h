#ifndef __MK_DSPStructMisc_H___
#define __MK_DSPStructMisc_H___
/* DSPStrucMisc.h - Functions having to do with DSP assembly data structures.
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

#include "MKDSPDefines.h"

/************************* INITIALIZATION FUNCTIONS **************************/


MKDSP_API void DSPDataRecordInit(DSPDataRecord *dr);


MKDSP_API void DSPSectionInit(DSPSection *sec);
/* 
 * Initialize all fields to NULL.
 */


MKDSP_API void DSPLoadSpecInit(DSPLoadSpec *dsp);
/* 
 * Initialize all fields to NULL.
 */


/**************************** PRINTING FUNCTIONS *****************************/

MKDSP_API void DSPSymbolPrint(DSPSymbol sym);
MKDSP_API void DSPDataRecordPrint(DSPDataRecord *dr);
MKDSP_API void DSPSectionPrint(DSPSection *section);
MKDSP_API void DSPLoadSpecPrint(DSPLoadSpec *dsp);

/****************************** ARCHIVING FUNCTIONS **************************/

MKDSP_API int DSPDataRecordWrite(DSPDataRecord *dr, FILE *fp);
MKDSP_API int DSPSymbolWrite(DSPSymbol sym, FILE *fp);
MKDSP_API int DSPFixupWrite(DSPFixup fxp, FILE *fp);
MKDSP_API int DSPSectionWrite(DSPSection *sec, FILE *fp);
MKDSP_API int DSPLoadSpecWrite(DSPLoadSpec *dsp, FILE *fp);

MKDSP_API int DSPLoadSpecWriteFile(
    DSPLoadSpec *dspptr,		/* struct containing  DSP load image */
    char *dspfn);			/* file name */
/*
 * Writes struct of type DSPLoadSpec to a binary file.
 * Writes file to be read by DSPLoadSpecReadFile().
 * Loading is much faster in this case than by using _DSPLnkRead().
 */

/********************************** readDSPx *********************************/

MKDSP_API int DSPSymbolRead(DSPSymbol *symp, FILE *fp);
MKDSP_API int DSPFixupRead(DSPFixup *fxpp, FILE *fp);
MKDSP_API int DSPSectionRead(DSPSection **secpp, FILE *fp);
MKDSP_API int DSPLoadSpecRead(DSPLoadSpec **dpp, FILE *fp);

MKDSP_API int DSPDataRecordRead(
    DSPDataRecord **drpp,
    FILE *fp,
    DSPSection *sp);	/* pointer to section owning this data record */


MKDSP_API int DSPLoadSpecReadFile(
    DSPLoadSpec **dspptr,		/* struct containing DSP load image */
    char *dspfn);			/* DSPLoadSpecWriteFile output file */
/*
 * Loads struct of type DSPLoadSpec from a binary ".dsp", ".lod", or ".lnk"
 * file.  Reads file written by DSPLoadSpecWriteFile().
 */

MKDSP_API int DSPDataRecordFree(DSPDataRecord *dr); 
/* 
 * Recursively frees entire data record chain.
 */

MKDSP_API int DSPSymbolFree(DSPSymbol *sym);
MKDSP_API int DSPFixupFree(DSPFixup *fxp);
MKDSP_API int DSPSectionFree(DSPSection *sec);
MKDSP_API int DSPLoadSpecFree(DSPLoadSpec *dsp);

/******************************* MISCELLANEOUS *******************************/

MKDSP_API DSPSection *DSPGetUserSection(DSPLoadSpec *dspStruct);
/*
 * Return DSPSection containing user's symbols, code, and data.
 * There is a separate section for the user (labeled "USER" in
 * DSP assembly language) only if relative assembly was used.
 * 
 * If the DSPLoadSpec was assembled in absolute mode (.lod file),
 * or if it came from a relative assembly (.lnk file) with no sections, 
 * then everything is in the GLOBAL section, and that is returned
 * instead.
 *
 * Equivalent to 
 * 			return ((*dspStruct->type == 'A')? 
 *	 			dspStruct->globalSection : 
 *				dspStruct->userSection);
 */

MKDSP_API DSPAddress DSPGetFirstAddress(DSPLoadSpec *dspStruct, 
				     DSPLocationCounter locationCounter);

MKDSP_API DSPAddress DSPGetLastAddress(DSPLoadSpec *dspStruct,
				    DSPLocationCounter locationCounter);

MKDSP_API int DSPDataRecordInsert(DSPDataRecord *dr,
			       DSPDataRecord **head,
			       DSPDataRecord **tail);  
/* 
 * Insert new data record such that load addresses are sorted 
 */


MKDSP_API int DSPDataRecordMerge(DSPDataRecord *dr);
/*
 * Merge contiguous, sorted dataRecords within a DSP memory space.
 * Arg is a pointer to first data record in linked list.
 */

MKDSP_API int DSPCopyLoadSpec(DSPLoadSpec **dspPTo,DSPLoadSpec *dspFrom);

#endif
