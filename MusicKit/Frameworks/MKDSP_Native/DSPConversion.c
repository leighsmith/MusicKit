/* DSPConversion.c - numerical conversion between host and DSP data formats.
   Copyright 1988-1992, NeXT Inc.  All rights reserved.
   Modification history:
       05/01/88/jos - created.
       09/27/88/jos - Added warning on fixed-point overflow in DSPIntToFix24.
       06/04/89/jos - Removed use of DSP_I_MAXNEG
       04/23/90/jos - flushed unsupported entry points.
       08/15/91/jos - Added INLINE.
       10/01/93/daj - Removed INLINE.  Causes trouble with compiler in 3.1
*/

#ifdef SHLIB
#include "shlib.h"
#endif

#include "_dsp.h"
#include <math.h>		/* DSPDoubleToFix48() */

// #ifdef DEBUG
// #define INLINE
// #else
// #define INLINE inline
#define INLINE
// #endif

#define DSP_MAX_POSITIVE 0x7FFFFF

/************************** FIXED-POINT <--> INT *****************************/

INLINE int DSPFix24ToInt(DSPFix24 ival)
{
    int ivalr;
    if (ival &	0x800000)
      ivalr = ival | 0xFF000000; /* sign extend */
    else
      ivalr = ival;
    return(ivalr);
}

INLINE DSPFix24 DSPIntToFix24(int ival)
{
    DSPFix24 ivalr;
    ivalr = ival & DSP_WORD_MASK; /* strip off sign extension, if any */
    if (ival > DSP_MAX_POSITIVE || ival < -DSP_MAX_POSITIVE-1)	
      _DSPError(DSP_EFPOVFL,"DSPIntToFix24: 24-bit fixed-point overflow");
    return(ivalr);
}

INLINE int DSPFix24ToIntArray( 
    DSPFix24 *fix24Array,
    int *intArray,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      intArray[i] = DSPFix24ToInt(fix24Array[i]);
    return(0);
}

INLINE int DSPIntToFix24Array(
    int *intArray,
    DSPFix24 *fix24Array,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      fix24Array[i] = DSPIntToFix24(intArray[i]);
    return(0);
}

/****************************** FLOAT <--> INT *******************************/

INLINE float DSPIntToFloat(int ival)
{
    double dval;
    dval = (double) ival;
    dval *= DSP_TWO_TO_M_23;
    return((float)dval);
}


INLINE int DSPFloatToIntCountClips(
    float fval,
    int *npc,
    int *nnc)
{
    int ival;
    if (fval > DSP_F_MAXPOS) { /* cf. dsp.h */
	fval = DSP_F_MAXPOS;
	*npc += 1;
    }
    else if (fval < DSP_F_MAXNEG) {
	fval = DSP_F_MAXNEG;
	*nnc += 1;
    }
    ival = DSP_FLOAT_TO_INT(fval);
    return(ival);
}


INLINE int DSPFloatToInt(float fval)
{
    int npc,nnc,ival;
    ival = DSPFloatToIntCountClips(fval,&npc,&nnc);
    return(ival);
}


INLINE int DSPFloatToIntArray(
    float *floatArray,
    int *intArray,
    int wordCount)
{
    int i;
    int npc = 0;
    int nnc = 0;
    for (i=0; i<wordCount; i++)
      intArray[i] = DSPFloatToIntCountClips(floatArray[i],&npc,&nnc);
    if (npc>0)
      _DSPError1(EDOM,"DSPFloatToIntArray: Clipped to +1 %s times",
		 _DSPCVS(npc));
    if (nnc>0)
      _DSPError1(EDOM,"DSPFloatToIntArray: Clipped to -1 %s times",
		 _DSPCVS(nnc));
    return(npc+nnc);
}


INLINE int DSPIntToFloatArray(
    int *intArray,
    float *floatArray,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      floatArray[i] = ((float)intArray[i]) * (float)DSP_TWO_TO_M_23;
    return(0);
}

/****************************** FLOAT <--> SHORT *******************************/

INLINE float DSPShortToFloat(short sval)
{
    double dval;
    dval = (double) sval;
    dval *= DSP_TWO_TO_M_15;
    return((float)dval);
}


INLINE int DSPFloatToShortCountClips(
    float fval,
    int *npc,
    int *nnc)
{
    short sval;
    if (fval > DSP_F_MAXPOS) { /* cf. dsp.h */
	fval = DSP_F_MAXPOS;
	*npc += 1;
    }
    else if (fval < DSP_F_MAXNEG) {
	fval = DSP_F_MAXNEG;
	*nnc += 1;
    }
    sval = DSP_FLOAT_TO_SHORT(fval);
    return(sval);
}


INLINE short DSPFloatToShort(float fval)
{
    int npc,nnc;
    short sval;
    sval = DSPFloatToShortCountClips(fval,&npc,&nnc);
    return(sval);
}


INLINE int DSPFloatToShortArray(
    float *floatArray,
    short *shortArray,
    int wordCount)
{
    int i;
    int npc = 0;
    int nnc = 0;
    for (i=0; i<wordCount; i++)
      shortArray[i] = DSPFloatToShortCountClips(floatArray[i],&npc,&nnc);
    if (npc>0)
      _DSPError1(EDOM,"DSPFloatToShortArray: Clipped to +1 %s times",
		 _DSPCVS(npc));
    if (nnc>0)
      _DSPError1(EDOM,"DSPFloatToShortArray: Clipped to -1 %s times",
		 _DSPCVS(nnc));
    return(npc+nnc);
}


INLINE int DSPShortToFloatArray(
    short *shortArray,
    float *floatArray,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      floatArray[i] = ((float)shortArray[i]) * (float)DSP_TWO_TO_M_15;
    return(0);
}

/****************************** DOUBLE <--> SHORT *******************************/

INLINE double DSPShortToDouble(short sval)
{
    double dval;
    dval = (double) sval;
    dval *= DSP_TWO_TO_M_15;
    return((double)dval);
}


INLINE int DSPDoubleToShortCountClips(
    double dval,
    int *npc,
    int *nnc)
{
    short sval;
    if (dval > DSP_F_MAXPOS) { /* cf. dsp.h */
	dval = DSP_F_MAXPOS;
	*npc += 1;
    }
    else if (dval < DSP_F_MAXNEG) {
	dval = DSP_F_MAXNEG;
	*nnc += 1;
    }
    sval = DSP_DOUBLE_TO_SHORT(dval);
    return(sval);
}


INLINE short DSPDoubleToShort(double dval)
{
    int npc,nnc;
    short sval;
    sval = DSPDoubleToShortCountClips(dval,&npc,&nnc);
    return(sval);
}


INLINE int DSPDoubleToShortArray(
    double *doubleArray,
    short *shortArray,
    int wordCount)
{
    int i;
    int npc = 0;
    int nnc = 0;
    for (i=0; i<wordCount; i++)
      shortArray[i] = DSPDoubleToShortCountClips(doubleArray[i],&npc,&nnc);
    if (npc>0)
      _DSPError1(EDOM,"DSPDoubleToShortArray: Clipped to +1 %s times",
		 _DSPCVS(npc));
    if (nnc>0)
      _DSPError1(EDOM,"DSPDoubleToShortArray: Clipped to -1 %s times",
		 _DSPCVS(nnc));
    return(npc+nnc);
}


INLINE int DSPShortToDoubleArray(
    short *shortArray,
    double *doubleArray,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      doubleArray[i] = ((double)shortArray[i]) * (double)DSP_TWO_TO_M_15;
    return(0);
}

/************************** DSPFix24 <--> FLOAT ******************************/


INLINE float DSPFix24ToFloat(int ival)
{
    return(DSPIntToFloat(DSPFix24ToInt(ival)));
}


INLINE DSPFix24 DSPFloatToFix24(float fval)
{
    return(DSPIntToFix24(DSPFloatToInt(fval)));
}


INLINE int DSPFix24ToFloatArray(
    DSPFix24 *fix24Array,
    float *floatArray,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      floatArray[i] = DSPFix24ToFloat(fix24Array[i]);
    return(0);
}


INLINE int DSPFloatToFix24Array(
    float *floatArray,
    DSPFix24 *fix24Array,
    int wordCount)
{
    int i,ec;
    ec = DSPFloatToIntArray(floatArray,fix24Array,wordCount);
    for (i=0; i<wordCount; i++)
      fix24Array[i] = DSPIntToFix24(fix24Array[i]);
    return(ec);
}

/***************************** DOUBLE <--> INT *******************************/

INLINE double DSPIntToDouble(int ival)
{
    double dval;
    dval = (double) DSPIntToFloat(ival);
    return(dval);
}


INLINE int DSPDoubleToIntCountClips(
    double dval,
    int *npc,
    int *nnc)
{
    int ival;
    if (dval > DSP_F_MAXPOS) { /* cf. dsp.h */
	dval = DSP_F_MAXPOS;
	*npc += 1;
    }
    else if (dval < DSP_F_MAXNEG) {
	dval = DSP_F_MAXNEG;
	*nnc += 1;
    }
    ival = DSP_DOUBLE_TO_INT(dval);
    return(ival);
}


INLINE int DSPDoubleToInt(double dval)
{
    int npc,nnc,ival;
    ival = DSPDoubleToIntCountClips(dval,&npc,&nnc);
    return(ival);
}


INLINE int DSPDoubleToIntArray(
    double *doubleArray,
    int *intArray,
    int wordCount)
{
    int i;
    int npc = 0;
    int nnc = 0;
    for (i=0; i<wordCount; i++)
      intArray[i] = DSPDoubleToIntCountClips(doubleArray[i],&npc,&nnc);
    if (npc>0)
      _DSPError1(EDOM,"DSPDoubleToIntArray: Clipped to +1 %s times",
		 _DSPCVS(npc));
    if (nnc>0)
      _DSPError1(EDOM,"DSPDoubleToIntArray: Clipped to -1 %s times",
		 _DSPCVS(nnc));
    return(npc+nnc);
}


INLINE int DSPIntToDoubleArray(
    int *intArray,
    double *doubleArray,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      doubleArray[i] = DSPIntToDouble(intArray[i]);
    return(0);
}

/*********************** FIXED-POINT <--> DOUBLE *****************************/

INLINE double DSPFix24ToDouble(int ival)
{
    return(DSPIntToDouble(DSPFix24ToInt(ival)));
}


INLINE int DSPFix24ToDoubleArray(
    DSPFix24 *fix24Array,
    double *doubleArray,
    int wordCount)
{
    int i;
    for (i=0; i<wordCount; i++)
      doubleArray[i] = DSPFix24ToDouble(fix24Array[i]);
    return(0);
}


INLINE DSPFix24 DSPDoubleToFix24(double dval)
{
    return(DSPIntToFix24(DSPDoubleToInt(dval)));
}


INLINE int DSPDoubleToFix24Array(
    double *doubleArray,
    DSPFix24 *fix24Array,
    int wordCount)
{
    int i,ec;
    ec = DSPDoubleToIntArray(doubleArray,fix24Array,wordCount);
    for (i=0; i<wordCount; i++)
      fix24Array[i] = DSPIntToFix24(fix24Array[i]);
    return(ec);
}

/**************************** DSPFix48 <--> Int ******************************/

INLINE int DSPFix48ToInt(register DSPFix48 *aFix48P)
{
    unsigned v; 
    if (!aFix48P)
      return -1;
    return (v = (0xff & (aFix48P->high24 << 24)) | (aFix48P->low24));
}


INLINE DSPFix48 *DSPIntToFix48UseArg(
    unsigned ival,
    register DSPFix48 *aFix48P)
{
    aFix48P->low24 = ival & 0xffffff;
    aFix48P->high24 = ival >> 24;
    return aFix48P;
}


INLINE DSPFix48 *DSPIntToFix48(int ival)
{
    DSPFix48 *aFix48P;
    DSP_MALLOC(aFix48P,DSPFix48,1);
    return DSPIntToFix48UseArg(ival ,aFix48P);
}

/**************************** DSPFix48 <--> DOUBLE ***************************/

INLINE DSPFix48 *DSPDoubleToFix48UseArg(
    double dval,
    register DSPFix48 *aFix48P)
{
    /* FIXME Eventually make a faster conversion here which extracts mantissa
       and breaks into two pieces according to exponent without multiply. 
       */
    double hi24;

    dval = (dval < DSP_F_MAXNEG) ? DSP_F_MAXNEG : dval;
    dval = (dval > DSP_F_MAXPOS) ? DSP_F_MAXPOS : dval;
    hi24 = dval * DSP_TWO_TO_23; /* Trunc not rnd like DSP_DOUBLE_TO_INT() */
    aFix48P->high24 = (int)hi24;
    aFix48P->low24 = (int)((hi24-((double)aFix48P->high24))*DSP_TWO_TO_24);
    return aFix48P;
}

/*
 * FIXME Eventually make a faster conversion here which extracts mantissa
 * and breaks into two pieces according to exponent without multiply. 
 */

INLINE DSPFix48 *_DSPDoubleIntToFix48UseArg(double dval,DSPFix48 *aFix48P)
{
    double shiftedDval;
    shiftedDval = dval * DSP_TWO_TO_M_24;
    aFix48P->high24 = (int)shiftedDval;
    aFix48P->low24 = 
      (int)((shiftedDval-(double)aFix48P->high24)*DSP_TWO_TO_24);
    return aFix48P;
}


INLINE DSPFix48 *DSPDoubleToFix48(double dval)
{
    DSPFix48 *aFix48P;
    DSP_MALLOC(aFix48P,DSPFix48,1);
    return DSPDoubleToFix48UseArg(dval,aFix48P);
}


INLINE double DSPFix48ToDouble(register DSPFix48 *aFix48P)
{
    if (!aFix48P)
      return -1.0; /* FIXME or some other value */
    return ((double) aFix48P->high24)*DSP_TWO_TO_24+((double)(aFix48P->low24));
}

