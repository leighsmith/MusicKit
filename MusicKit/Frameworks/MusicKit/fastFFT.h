/* fastFFT.h created by skot on Thu 05-Oct-2000 */

extern void fft_real_to_hermitian(double *z, int n);
/* Output is {Re(z^[0]),...,Re(z^[n/2),Im(z^[n/2-1]),...,Im(z^[1]).
   This is a decimation-in-time, split-radix algorithm.
 */

extern void fftinv_hermitian_to_real(double *z, int n);
/* Input is {Re(z^[0]),...,Re(z^[n/2),Im(z^[n/2-1]),...,Im(z^[1]).
   This is a decimation-in-frequency, split-radix algorithm.
 */
