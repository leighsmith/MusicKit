#ifndef __MK_DSPConversion_H___
#define __MK_DSPConversion_H___
/* DSPConversion.h - Functions having to do with data type conversion
 * Copyright 1988-1992, NeXT Inc.  All rights reserved.
 * Author: Julius O. Smith III
 */

#include "MKDSPDefines.h"

MKDSP_API int DSPFix24ToInt(DSPFix24 ival);

MKDSP_API DSPFix24 DSPIntToFix24(int ival);

MKDSP_API int DSPFix24ToIntArray(
    DSPFix24 *fix24Array,
    int *intArray,
    int wordCount);

MKDSP_API int DSPIntToFix24Array(
    int *intArray,
    DSPFix24 *fix24Array,
    int wordCount);

MKDSP_API float DSPIntToFloat(int ival);

MKDSP_API int DSPFloatToIntCountClips(
    float fval,
    int *npc,			/* no. positive clips */
    int *nnc);			/* no. negative clips */

MKDSP_API int DSPFloatToInt(float fval);

MKDSP_API int DSPFloatToIntArray(
    float *floatArray,
    int *intArray,
    int wordCount);

MKDSP_API int DSPIntToFloatArray(
    int *intArray,
    float *floatArray,
    int wordCount);

MKDSP_API float DSPFix24ToFloat(int ival);

MKDSP_API DSPFix24 DSPFloatToFix24(float fval);

MKDSP_API int DSPFix24ToFloatArray(
    DSPFix24 *fix24Array,
    float *floatArray,
    int wordCount);

MKDSP_API int DSPFloatToFix24Array(
    float *floatArray,
    DSPFix24 *fix24Array,
    int wordCount);

MKDSP_API double DSPIntToDouble(int ival);

MKDSP_API int DSPDoubleToIntCountClips(
    double dval,
    int *npc,			/* no. positive clips */
    int *nnc);			/* no. negative clips */

MKDSP_API int DSPDoubleToInt(double dval);

MKDSP_API int DSPDoubleToIntArray(
    double *doubleArray,
    int *intArray,
    int wordCount);

MKDSP_API int DSPIntToDoubleArray(
    int *intArray,
    double *doubleArray,
    int wordCount);

MKDSP_API double DSPFix24ToDouble(int ival);

MKDSP_API int DSPFix24ToDoubleArray(
    DSPFix24 *fix24Array,
    double *doubleArray,
    int wordCount);

MKDSP_API DSPFix24 DSPDoubleToFix24(double dval);

MKDSP_API int DSPDoubleToFix24Array(
    double *doubleArray,
    DSPFix24 *fix24Array,
    int wordCount);


MKDSP_API int DSPFix48ToInt(register DSPFix48 *aFix48P);
/* 
 * Returns *aFix48P as an int, masking out the upper two bytes of the
 * DSPFix48 datum.  If aFix48P is NULL, it returns -1.
 */


MKDSP_API DSPFix48 *DSPIntToFix48(int ival);
/* 
 * Returns a pointer to a new DSPFix48 with the value as represented by ival.
 */


MKDSP_API DSPFix48 *DSPIntToFix48UseArg(
    unsigned ival,
    register DSPFix48 *aFix48P);
/* 
 * Returns, in *aFix48P, the value as represented by ival. 
 * aFix48P must point to a valid DSPFix48 struct. 
 */


MKDSP_API DSPFix48 *DSPDoubleToFix48UseArg(
    double dval,
    register DSPFix48 *aFix48P);
/* 
 * The double is assumed to be between -1.0 and 1.0.
 * Returns, in *aFix48P, the value as represented by dval. 
 * aFix48P must point to a valid DSPFix48 struct. 
 */


MKDSP_API DSPFix48 *DSPDoubleToFix48(double dval);
/* 
 * Returns, a pointer to a new DSPFix48 
 * with the value as represented by dval. 
 * The double is assumed to be between -1.0 and 1.0. 
 */


MKDSP_API double DSPFix48ToDouble(register DSPFix48 *aFix48P);
/* 
 * Returns *aFix48P as a double between 2^47 and -2^47.
 * If aFix48P is NULL, returns -1.0. 
 */


/********** Float <--> Short *************/

MKDSP_API  float DSPShortToFloat(short sval);

MKDSP_API  int DSPFloatToShortCountClips(
    float fval, 
    int *npc,
    int *nnc);

MKDSP_API  short DSPFloatToShort(float fval);

MKDSP_API int DSPFloatToShortArray(
    float *floatArray,
    short *shortArray,
    int wordCount);

MKDSP_API int DSPShortToFloatArray(
    short *shortArray,
    float *floatArray,
    int wordCount);

/********** Double <--> Short *************/

MKDSP_API  double DSPShortToDouble(short sval);

MKDSP_API  int DSPDoubleToShortCountClips(
    double dval,
    int *npc,
    int *nnc);

MKDSP_API  short DSPDoubleToShort(double dval);

MKDSP_API int DSPDoubleToShortArray(
    double *doubleArray,
    short *shortArray,
    int wordCount);

MKDSP_API int DSPShortToDoubleArray(
    short *shortArray,
    double *doubleArray,
    int wordCount);

#endif
