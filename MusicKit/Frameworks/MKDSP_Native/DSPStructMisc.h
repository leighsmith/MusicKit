#ifndef __MK_DSPStructMisc_H___
#define __MK_DSPStructMisc_H___
/* DSPStrucMisc.h - Functions having to do with DSP assembly data structures.
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

/************************* INITIALIZATION FUNCTIONS **************************/


extern void DSPDataRecordInit(DSPDataRecord *dr);


extern void DSPSectionInit(DSPSection *sec);
/* 
 * Initialize all fields to NULL.
 */


extern void DSPLoadSpecInit(DSPLoadSpec *dsp);
/* 
 * Initialize all fields to NULL.
 */


/**************************** PRINTING FUNCTIONS *****************************/

extern void DSPSymbolPrint(DSPSymbol sym);
extern void DSPDataRecordPrint(DSPDataRecord *dr);
extern void DSPSectionPrint(DSPSection *section);
extern void DSPLoadSpecPrint(DSPLoadSpec *dsp);

/****************************** ARCHIVING FUNCTIONS **************************/

extern int DSPDataRecordWrite(DSPDataRecord *dr, FILE *fp);
extern int DSPSymbolWrite(DSPSymbol sym, FILE *fp);
extern int DSPFixupWrite(DSPFixup fxp, FILE *fp);
extern int DSPSectionWrite(DSPSection *sec, FILE *fp);
extern int DSPLoadSpecWrite(DSPLoadSpec *dsp, FILE *fp);

extern int DSPLoadSpecWriteFile(
    DSPLoadSpec *dspptr,		/* struct containing  DSP load image */
    char *dspfn);			/* file name */
/*
 * Writes struct of type DSPLoadSpec to a binary file.
 * Writes file to be read by DSPLoadSpecReadFile().
 * Loading is much faster in this case than by using _DSPLnkRead().
 */

/********************************** readDSPx *********************************/

extern int DSPSymbolRead(DSPSymbol *symp, FILE *fp);
extern int DSPFixupRead(DSPFixup *fxpp, FILE *fp);
extern int DSPSectionRead(DSPSection **secpp, FILE *fp);
extern int DSPLoadSpecRead(DSPLoadSpec **dpp, FILE *fp);

extern int DSPDataRecordRead(
    DSPDataRecord **drpp,
    FILE *fp,
    DSPSection *sp);	/* pointer to section owning this data record */


extern int DSPLoadSpecReadFile(
    DSPLoadSpec **dspptr,		/* struct containing DSP load image */
    char *dspfn);			/* DSPLoadSpecWriteFile output file */
/*
 * Loads struct of type DSPLoadSpec from a binary ".dsp", ".lod", or ".lnk"
 * file.  Reads file written by DSPLoadSpecWriteFile().
 */

extern int DSPDataRecordFree(DSPDataRecord *dr); 
/* 
 * Recursively frees entire data record chain.
 */

extern int DSPSymbolFree(DSPSymbol *sym);
extern int DSPFixupFree(DSPFixup *fxp);
extern int DSPSectionFree(DSPSection *sec);
extern int DSPLoadSpecFree(DSPLoadSpec *dsp);

/******************************* MISCELLANEOUS *******************************/

extern DSPSection *DSPGetUserSection(DSPLoadSpec *dspStruct);
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

extern DSPAddress DSPGetFirstAddress(DSPLoadSpec *dspStruct, 
				     DSPLocationCounter locationCounter);

extern DSPAddress DSPGetLastAddress(DSPLoadSpec *dspStruct,
				    DSPLocationCounter locationCounter);

extern int DSPDataRecordInsert(DSPDataRecord *dr,
			       DSPDataRecord **head,
			       DSPDataRecord **tail);  
/* 
 * Insert new data record such that load addresses are sorted 
 */


extern int DSPDataRecordMerge(DSPDataRecord *dr);
/*
 * Merge contiguous, sorted dataRecords within a DSP memory space.
 * Arg is a pointer to first data record in linked list.
 */

extern int DSPCopyLoadSpec(DSPLoadSpec **dspPTo,DSPLoadSpec *dspFrom);

#endif
