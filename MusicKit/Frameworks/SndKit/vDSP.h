/*
  $Id$

  Description: 
    Replacement DSP functions emulating the behaviour of Apple's vDSP library on Intel
    SSE2 architecture. Should be compiled with -msse2.

  Original Author: Leigh M. Smith

  Copyright (c) 2010 The MusicKit Project. All Rights Reserved.
*/

/*!
  @brief Adds vector A to vector B and leaves the result in vector C; single precision.

  This performs the following operation:

  $C_{n}{K} = A_{n}{I} + B_{n}{J} n = {0, N-1}$
 */
inline void vDSP_vadd(const float input1[], unsigned int stride1,
		      const float input2[], unsigned int stride2,
		      float result[], unsigned int strideResult,
		      unsigned int size);

/*!
  @brief Adds vector A to vector B and leaves the result in vector C; single precision.

  This performs the following operation:

  $C_{n}{K} = A_{n}{I} - B_{n}{J} n = {0, N-1}$
 */
inline void vDSP_vsub(const float input1[], unsigned int stride1,
		      const float input2[], unsigned int stride2,
		      float result[], unsigned int strideResult,
		      unsigned int size);

/*!
  @brief Divides vector A by vector B and leaves the result in vector C; single precision.

  This performs the following operation:

  $C_{n}{K} = A_{n}{I} / B_{n}{J} n = {0, N-1}$
 */
inline void vDSP_vdiv(const float input1[], unsigned int input1Stride, 
		      const float input2[], unsigned int input2Stride,
		      float result[], unsigned int resultStride,
		      unsigned int size);

/*!
  @brief Creates a running sum from A leaving the result in vector C.

  The first element is not summed, and therefore zero.
  This performs the following operation:

  $C_{0} = 0$
  $C_{n}{K} = C_{n-1}{K} + SA_{n}{I} n = {1, N-1}$
 */
void vDSP_vrsum(const float *input, unsigned int inputStride,
		const float *scalingValue,
		float *result, unsigned int resultStride,
		unsigned int size);

/*!
 @brief Creates a monotonically increasing or decreasing vector result from an initial
 value and an increment.

 Performs the following operation:

 $C_{n}{k} = a + nb, n = {0, N-1}.

 Where C is the result, $a$ the initial value, $N$ the length, $b$ the increment.

 @param initialValue The initial value to begin the ramp.
 @param increment The increment (+ve) or decrement (-ve).
 @param result The output vector.
 @param resultStride The vector index jump for the result.
 @param The number of elements to generate in the resulting vector.
*/
void vDSP_vramp(float *initialValue,
		float *increment,
		float *result,
		unsigned int resultStride,
		unsigned int vectorLength);

/*!
  @brief Add the scalar value to each element in the vector.

  $C_{nK} = A_{nI} + B$ $n = {0, N-1}$

  where A  is the input, B the scalar operand, C the result, N the vector length, I and K
  are the strides for input and result respectively.
*/
void vDSP_vsadd(float *input,
		unsigned int inputStride,
		float *scalarOperand,
		float *result,
		unsigned int resultStride,
		unsigned int vectorLength);

/*!
  @brief Computes the dot product of vectors A and B and leaves the result in scalar *C.

 */
void vDSP_dotpr(const float input1[],
		unsigned int inputStride1,
		const float input2[],
		unsigned int inputStride2,
		float *result,
		unsigned int size);
