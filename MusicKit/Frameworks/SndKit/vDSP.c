/*
  $Id$

  Description: 
    Replacement DSP functions emulating the behaviour of Apple's vDSP library on Intel
    SSE2 architecture. Currently this is gcc specific. Should be compiled with -msse2.

  Original Author: Leigh M. Smith

  Copyright (c) 2010 The MusicKit Project. All Rights Reserved.
*/
#include "vDSP.h"
#include <xmmintrin.h>

#define FLOATS_PER_REGISTER 4
/* The non-intrinsics version is much faster on Windows, at least */
#define USE_INTRINSICS 0

typedef float v4sf __attribute__ ((vector_size (16)));

#ifdef __cplusplus
extern "C" {
#endif 

void vDSP_vadd(const float input1[], unsigned int input1Stride, 
		      const float input2[], unsigned int input2Stride, 
		      float result[], unsigned int resultStride, 
		      unsigned int size)
{
    v4sf *in1 = (v4sf *) input1, *in2 = (v4sf *) input2, *out = (v4sf *) result;
    unsigned int index;

    for(index = 0; index < size / FLOATS_PER_REGISTER; index++) {
	*out = *in1 + *in2;
	/* *out = __builtin_ia32_addv4sf(*in1, *in2); */
	/* *out = __builtin_ia32_addps(*in1, *in2); */
	in1 += input1Stride;
	in2 += input2Stride;
	out += resultStride;
    }
}

void vDSP_vsub(const float input1[], unsigned int input1Stride, 
		      const float input2[], unsigned int input2Stride, 
		      float result[], unsigned int resultStride, 
		      unsigned int size)
{
    v4sf *in1 = (v4sf *) input1, *in2 = (v4sf *) input2, *out = (v4sf *) result;
    unsigned int index;

    for(index = 0; index < size / FLOATS_PER_REGISTER; index++) {
	*out = *in2 - *in1;
	/* *out = __builtin_ia32_subps(*in1, *in2); */
	in1 += input1Stride;
	in2 += input2Stride;
	out += resultStride;
    }
}

void vDSP_vdiv(const float input1[], unsigned int input1Stride, 
		      const float input2[], unsigned int input2Stride,
		      float result[], unsigned int resultStride,
		      unsigned int size)
{
    v4sf *in1 = (v4sf *) input1, *in2 = (v4sf *) input2, *out = (v4sf *) result;
    unsigned int index;

    for(index = 0; index < size / FLOATS_PER_REGISTER; index++) {
	*out = *in2 / *in1;
	/* *out = __builtin_ia32_vdiv4sf(*in1, *in2); */
	in1 += input1Stride;
	in2 += input2Stride;
	out += resultStride;
    }
}

void vDSP_vrsum(const float *input, unsigned int inputStride,
	     const float *scalingValue,
	     float *result, unsigned int resultStride,
	     unsigned int size)
{
#if USE_INTRINSICS
    register unsigned int vectorIndex;
    register v4sf accumulator asm("%xmm1");
    register v4sf scaling asm("%xmm2");
    register v4sf currentValue asm("%xmm0");
    register const float *inputPtr = input + 1;
    register float *resultPtr = result + 1;
#else
    register unsigned int vectorIndex;
    v4sf scaling;
    const float *inputPtr = input + 1;
    float *resultPtr = result + 1;
#endif

    scaling = _mm_load_ss(scalingValue); 	/* load the scaling value into xmm2 */
    *result = 0.0f;

#if USE_INTRINSICS
    accumulator = _mm_setzero_ps();  	/* Zero the accumulator */
#else
    asm volatile ("xorps %%xmm1, %%xmm1\n\t"
		  : /* no output */
		  : /* no input */
		  : "%xmm1");
#endif
    for(vectorIndex = 0; vectorIndex < size - 1; vectorIndex++) {
#if USE_INTRINSICS
	currentValue = _mm_load_ss(inputPtr); /* read from input into currentValue */
	currentValue = _mm_mul_ss(scaling, currentValue); /* multiply by the scaling factor, store back in currentValue. */
	accumulator = _mm_add_ss(currentValue, accumulator); /* add to accumulator, saving there.*/
	_mm_store_ss(resultPtr, accumulator); /* write to result from accumulator. */
#else
	asm volatile ("movss %1, %%xmm0\n\t"
		      "mulss %2, %%xmm0\n\t" /* multiply by the scaling factor, store back in currentValue. */
		      "addss %%xmm0, %%xmm1\n\t"  /* add to accumulator, saving there.*/
		      "movss %%xmm1, %0\n\t"  /* write to result from accumulator. */
		      : "=m"(*resultPtr)
		      : "m"(*inputPtr), "m"(scaling)
		      : "%xmm0", "%xmm1");
#endif
	resultPtr += resultStride;
	inputPtr += inputStride;
    }
}

void vDSP_vramp(float *initialValue,
		float *increment,
		float *result,
		unsigned int resultStride,
		unsigned int vectorLength)
{
    register v4sf increments;
    register v4sf current_base;
    v4sf *out = (v4sf *) result;
    unsigned int index;
    static float  __attribute__ ((aligned (16))) incrementInitialiser[4] = { 1.0f, 2.0f, 3.0f, 4.0f };

    /* Create a set of 4 increments */
    increments = *((v4sf *) incrementInitialiser) * _mm_set_ps1(*increment);
    current_base = _mm_set_ps1(*initialValue - *increment);

    for(index = 0; index < vectorLength / FLOATS_PER_REGISTER; index++) {
	current_base = current_base + increments;
	*out = current_base;
	current_base = _mm_shuffle_ps(current_base, current_base, 0xff);
	out += resultStride;
    }
}

void vDSP_vsadd(float *input,
		unsigned int inputStride,
		float *scalarOperand,
		float *result,
		unsigned int resultStride,
		unsigned int vectorLength)
{
    register v4sf base;
    v4sf *in = (v4sf *) input, *out = (v4sf *) result;
    unsigned int index;

    /* Create a set of 4 increments */
    base = _mm_set_ps1(*scalarOperand);

    for(index = 0; index < vectorLength / FLOATS_PER_REGISTER; index++) {
	*out = base + *in;
	out += resultStride;
	in += inputStride;
    }
}

/* We do it the old fashioned SSE2 way, rather than use the DPPS instruction to support older hardware */
void vDSP_dotpr(const float input1[],
		unsigned int input1Stride,
		const float input2[],
		unsigned int input2Stride,
		float *result,
		unsigned int size)
{
    v4sf *in1 = (v4sf *) input1, *in2 = (v4sf *) input2;
#if USE_INTRINSICS
    /* We need to declare this static, since declaring it a register doesn't guarantee
     * it isn't demoted to an auto, which can create a hairy situation that the
     * accumulator's location on the stack may not be properly aligned. */
    static __attribute__ ((aligned (16))) v4sf accumulator;
#endif
    float finalSummation[4];
    unsigned int index;

#if USE_INTRINSICS
    accumulator = _mm_setzero_ps();  	/* Zero the accumulator */
#else
    asm volatile ("xorps %%xmm2, %%xmm2\n\t"
		  : /* no output */
		  : /* no input */
		  : "%xmm2");
#endif
    for(index = 0; index < size / FLOATS_PER_REGISTER; index++) {
#if USE_INTRINSICS
	accumulator = _mm_add_ps(accumulator, _mm_mul_ps(*in1, *in2));
#else
	asm volatile ("movaps %0, %%xmm0\n\t" /* load in1 */
		      "movaps %1, %%xmm1\n\t" /* load in2 */
		      "mulps %%xmm0, %%xmm1\n\t" /* multiply both, store in xmm1. */
		      "addps %%xmm1, %%xmm2\n\t"  /* add to accumulator (xmm2), saving there.*/
		      : /* no output */
		      : "m"(*in1), "m"(*in2)
		      : "%xmm0", "%xmm1", "%xmm2");

#endif
	in1 += input1Stride;
	in2 += input2Stride;
    }
#if USE_INTRINSICS
    _mm_storeu_ps(finalSummation, accumulator);
#else
    asm volatile ("movups %%xmm2, %0\n\t"
		  : "=m"(finalSummation)
		  : /* no inputs */
		  : "%xmm2");
#endif
    /* Now sum the 4 floats in the vector */
    *result = finalSummation[0] + finalSummation[1] + finalSummation[2] + finalSummation[3];
}

#ifdef __cplusplus
}
#endif
