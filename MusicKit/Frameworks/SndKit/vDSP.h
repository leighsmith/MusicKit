/*!
  @brief Replacement DSP functions emulating the behaviour of Apple's vDSP library

  This is gcc specific.
 */

/*!
  @brief Adds vector A to vector B and leaves the result in vector C; single precision.

  This performs the following operation:

  $C_{n}{K} = A_{n}{I} + B{m}{J} n = {0, N-1}$
 */
inline void vDSP_vadd(const float input1[], unsigned int stride1,
		      const float input2[], unsigned int stride2,
		      float result[], unsigned int strideResult,
		      unsigned int size);

