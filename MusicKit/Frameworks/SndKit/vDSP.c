/*
  Replacement DSP functions emulating the behaviour of Apple's vDSP library

  $Id:$

  should be compiled with -msse2
*/
#include "vDSP.h"
#include <xmmintrin.h>

#define FLOATS_PER_REGISTER 4
#define USE_INTRINSICS 0

typedef float v4sf __attribute__ ((vector_size (16)));

inline void vDSP_vadd(const float input1[], unsigned int input1Stride, 
		      const float input2[], unsigned int input2Stride, 
		      float result[], unsigned int resultStride, 
		      unsigned int size)
{
    v4sf *in1 = (v4sf *) input1, *in2 = (v4sf *) input2, *out = (v4sf *) result;
    unsigned int index;

    for(index = 0; index < size / FLOATS_PER_REGISTER; index++) {
	*out = *in1 + *in2;
	/* *out = __builtin_ia32_addv4sf(*in1, *in2); */
        /* *out = __builtin_ia32_addss(*in1, *in2); */
	/* *out = __builtin_ia32_addps(*in1, *in2); */
	in1 += input1Stride;
	in2 += input2Stride;
	out += resultStride;
    }
}

inline void vDSP_vdiv(const float input1[], unsigned int input1Stride, 
		      const float input2[], unsigned int input2Stride,
		      float result[], unsigned int resultStride,
		      unsigned int size)
{
    v4sf *in1 = (v4sf *) input1, *in2 = (v4sf *) input2, *out = (v4sf *) result;
    unsigned int index;

    for(index = 0; index < size / FLOATS_PER_REGISTER; index++) {
	*out = *in1 / *in2;
	/* *out = __builtin_ia32_vdiv4sf(*in1, *in2); */
        /* *out = __builtin_ia32_addss(*in1, *in2); */
	/* *out = __builtin_ia32_addps(*in1, *in2); */
	in1 += input1Stride;
	in2 += input2Stride;
	out += resultStride;
    }
}

#if 0
inline void vDSP_vrsum(const float input[], unsigned int inputStride, const float scaling[], 
		       float result[], unsigned int resultStride, unsigned int size)
{
    v4sf *in = (v4sf *) input, *out = (v4sf *) result;
    unsigned int index;
    float previous;

    for(index = 0; index < size / FLOATS_PER_REGISTER; index++) {
	/* register */ float previous;
	v4sf shifted1;
	v4sf shifted2;
	v4sf half_sum;

        // TODO incorporate scaling.

	shifted1 = *in; // *in = a0, a1, a2, a3
	// shift 1 float to the left: 0, a0, a1, a2
	__builtin_ia32_pslld(shifted1, 4);
	// move in the previous vector wide summation: s, a0, a1, a2
	__builtin_ia32_movss(shifted1, previous);
	// Add 4 32bit single precision floats: a0 + s, a1 + a0, a2 + a1, a3 + a2 
	half_sum = __builtin_ia32_addps(*in, shifted1);
	// shift the summation two floats to the left: 0, 0, a0 + s, a1 + a0
	shifted2 = __builtin_ia32_pslld(half_sum, 8);
	// Add 4 32bit single precision floats: a0 + s, a1 + a0, a2 + a1 + a0 + s, a3 + a2 + a1 + a0
	*out = __builtin_ia32_addps(half_sum, shifted2);
	_builtin_ia32_movnti(previous, *out, 4);
	in += inputStride;
	out += resultStride;
    }
}

#else 

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
    register v4sf accumulator asm("%xmm1");
    v4sf scaling;
    const float *inputPtr = input + 1;
    float *resultPtr = result + 1;
#endif

    scaling = _mm_load_ss(scalingValue); 	/* load the scaling value into xmm2 */
    *result = 0.0f;

    // accumulator = 0.0f;  	/* Zero the accumulator xmm1 */
    accumulator = _mm_xor_ps(accumulator, accumulator);  	/* Zero the accumulator */
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


#endif
