/*
  Replacement DSP functions emulating the behaviour of Apple's vDSP library

  $Id:$

  should be compiled with -msse
*/
#include "vDSP.h"

#define FLOATS_PER_REGISTER 4

inline void vDSP_vadd(const float input1[], unsigned int input1Stride, 
		      const float input2[], unsigned int input2Stride, 
		      float result[], unsigned int resultStride, 
		      unsigned int size)
{
     typedef float v4sf __attribute__ ((vector_size (16)));
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
