/* SignalProcessor.m ~ by Perry R. Cook */

#import "SignalProcessor.h"
#import <stdlib.h>
#import <stdio.h>
#import <math.h>
#import <string.h>
#define SRATE 22050
#define PI (double) 3.14159265358979323846264338327950
#define SQRT_TWO 1.414213562
#define TWO_PI (double)(2*3.14159265358979323846264338327950)
#define SQRT_HALF (double)(0.707106781186547524400844362104849)

@implementation SignalProcessor

- init
{
    self = [super init];
    if(self != nil) {
	lastLength = 0;	
    }
    return self;
}

/* Call with defaults Hanning and size/2 centered */
- window:(int)size array:(float *)array
{
    return [self window:size array:array type:@"Hanning" phase:0];
}

- window:(int)size array:(float *)array type:(NSString *)type
    /* Call with phase = NO */
{
    return [self window:size array:array type:type phase: NO];
}

- window:(int)size array:(float *)array type:(NSString *)type phase:(BOOL)phase

    /*	Window array of floats with window of type <"Triangle","Hanning","Hamming",
    "Blackman3","Blackman4","Kaiser"> with window centered at zero (phase=TRUE)
    or size/2 (phase=NO).
    */
{
    extern void triangle(int size, float* array, BOOL phase),
    hanning(int size, float* array, BOOL phase),
    hamming(int size, float* array, BOOL phase),
    blackman3(int size, float* array, BOOL phase),
    blackman4(int size, float* array, BOOL phase),
    kaiser(int size, float* array, BOOL phase);
    
    if ([type isEqualToString:@"Triangular"])			triangle(size, array, phase);
    else if ([type isEqualToString:@"Hanning"])			hanning(size, array, phase);
    else if ([type isEqualToString:@"Hamming"])			hamming(size, array, phase);
    else if ([type isEqualToString:@"Blackman3"])		blackman3(size, array, phase);
    else if ([type isEqualToString:@"Blackman4"])		blackman4(size, array, phase);
    else if ([type isEqualToString:@"Kaiser"])			kaiser(size, array, phase);
    
    /* add your own windows here!!! */
    
    return self;
}

void triangle(int size, float* array, BOOL phase)
{
    int i, scale = size/2;
    float w;
        
    if (phase) {
	for (i=0; i<size/2; i++) {
	    w = (float) (size/2 - i)/scale;
	    array[i] *= w;
	    array[size-i] *= w;
	}	
    }
    else {
	for (i=0; i<size/2; i++) {
	    w = (float) i/scale;
	    array[i] *= w;
	    array[size-i-1] *= w;
	}		
    }
}

void hanning(int size, float* array, BOOL phase)
{
    int i;
    float w, winFreq = TWO_PI / size;
    
    if (phase) {
	for (i=0; i<size/2; i++) {
	    w = 0.5 + 0.5 * cos(i * winFreq);
	    array[i] *= w;
	    array[size-i-1] *= w;
	}	
    }
    else {
	for (i=0; i<size/2; i++) {
	    w = 0.5 - 0.5 * cos(i * winFreq);
	    array[i] *= w;
	    array[size-i-1] *= w;
	}	
    }
}

void hamming(int size, float* array, BOOL phase)
{
    int i;
    float w, winFreq = TWO_PI / size;
    
    if (phase) {
	for (i=0; i<size/2; i++) {
	    w = 0.54 + 0.46 * cos(i * winFreq);
	    array[i] *= w;
	    array[size-i-1] *= w;
	}	
    }
    else {
	for (i=0; i<size/2; i++) {
	    w = 0.54 - 0.46 * cos(i * winFreq);
	    array[i] *= w;
	    array[size-i-1] *= w;
	}	
    }
}

void blackman3(int size, float* array, BOOL phase)
{
    int i;
    float w, winFreq = TWO_PI / size;
    
    if (phase) {
	for (i=0; i<size/2; i++) {
	    w = (0.42 + 0.5 * cos(i * winFreq) + 0.08 * cos(2 * i * winFreq));
	    array[i] *= w;
	    array[size-i-1] *= w;
	}	
    }
    else {
	for (i=0; i<size/2; i++) {
	    w = (0.42 - 0.5 * cos(i * winFreq) + 0.08 * cos(2 * i * winFreq));
	    array[size-i-1] *= w;
	    array[i] *= w;
	}	
    }
}

void blackman4(int size, float* array, BOOL phase)
{
    int i;
    float w, winFreq;
    winFreq = TWO_PI / size;
    if (phase) {
	for (i=0; i<size/2; i++) {
	    w = (0.35875 + 0.48829 * cos(i * winFreq) + 
		 0.14128 * cos(2 * i * winFreq) + 0.01168 * cos(3 * i * winFreq));
	    array[i] *= w;
	    array[size-i-1] *= w;
	}	
    }
    else {
	for (i=0; i<size/2; i++) {
	    w = (0.35875 - 0.48829 * cos(i * winFreq) + 
		 0.14128 * cos(2 * i * winFreq) - 0.01168 * cos(3 * i * winFreq));
	    array[i] *= w;
	    array[size-i-1] *= w;
	}	
    }
}

void kaiser(int size, float* array, BOOL phase)
{
    blackman4(size, array, phase);		// I'm Cheating, see Harris, eq. 34
}

- logMag:(int)size array:(float *)f
{
    [self logMag:size array:f floor:-60.0];
    return self;
}

- log:(int)size array:(float *)f floor:(float)fl
{
    int i;
    float t1=0.0, t=0.0, t2;
    t2 = fl / 10.0;
    if (f[0] > t1)
	t1 = f[0];
    for (i=1; i<size; i++) {
	if (f[i]>t1)
	    t1 = f[i];
    }
    for (i=0; i<size; i++) {
	t = log10(f[i]/t1);
	if (t<t2)
	    t = t2;
	f[i] = 1 - t/t2;
    }
    return self;
}

- log:(int)size array:(float *)f floor:(float)fl ceiling:(float)ceiling
{
    int i;
    float t1, t=0.0, t2;
    t2 = fl / 10.0;
    t1 = ceiling;
    for (i=0; i<size; i++) {
	t = log10(f[i]/t1);
	if (t<t2)
	    t = t2;
	f[i] = 1 - t/t2;
    }
    return self;
}

- logMag:(int)size array:(float *)f floor:(float)fl
{
    int i;
    float t1=0.0, t=0.0, t2=-12;
    t2 = fl / 10.0;
    f[0] = 2 * fabs(f[0]);
    if (f[0] > t1)
	t1 = f[0];
    for (i=1; i<size/2; i++) {
	t = f[i]*f[i] + f[size-i]*f[size-i];
	f[i] = t;
	if (t>t1)
	    t1 = t;
    }
    for (i=0; i<size/2; i++) {
	t = log10(f[i]/t1);
	if (t<t2)
	    t = t2;
	f[i] = 1 - t/t2;
    }
    return self;
}

- logMag:(int)size array:(float *)f floor:(float)fl ceiling:(float)ceiling
{
    int i;
    float floorInDB = fl / 10.0;
    
    f[0] = 2 * fabs(f[0]);
    for (i = 1; i < size / 2; i++) {
	float t = f[i] * f[i] + f[size - i] * f[size - i];
	f[i] = t;
    }
    for (i = 0; i < size / 2; i++) {
	float t = log10(f[i] / ceiling);
	if (t < floorInDB)
	    t = floorInDB;
	f[i] = 1 - t / floorInDB;
    }
    return self;
}

- magnitude:(int)size array:(float *)array magOut:(float *)mag
{
    int i;
    mag[0] = 2 * fabs(array[0]);
    for (i=1; i<size/2; i++) {
	mag[i] = sqrt(array[i] * array[i] + array[size-i] * array[size-i]);
    }
    return self;
}

- squareMag:(int)size magnitudeIn:(float *)magIn squareMagOut:(float *)squareMagOut
{
    int i;
    for (i=0; i<size; i++) squareMagOut[i] = magIn[i] * magIn[i];
    return self;
}

- normalize:(int)size array:(float *)array;
{
    int i;
    float mx = 0.0;
    for (i=0; i<size; i++)
	if (fabs(array[i])>mx) mx=fabs(array[i]);
    if (mx!=0.0)
	for (i=0; i<size; i++) array[i] /= mx;
    return self;	
}

- dht:(float *)inputArray output:(float *)outputArray length:(int)length
{
    int i, j;
    float w;
    w = TWO_PI / length;
    for (i=0; i<length; i++) {
	outputArray[i] = 0.0;
	for (j=0; j<length; j++) {
	    outputArray[i] += inputArray[j] * (cos(w * i * j) + sin(w * i * j));
	}
    }
    return self;
}

- makeSines:(int)length
{
    int i;
    float freq, temp;
    if (length!=lastLength) {
	if (sines || cosines) {
	    free(sines);
	    free(cosines);
	}
	sines = (float *)malloc(length * sizeof(float));
	cosines = (float *)malloc(length * sizeof(float));
	lastLength = length;
	freq = 2.0 * PI / length;
	for (i=0; i<length; i++) {
	    temp = freq * i;
	    sines[i] = sin(temp);
	    cosines[i] = cos(temp);
	}
    }
    return self;
}

- scramble:(int)length array:(float *)f
{
    int i, j, k;
    float temp;
    for (i=0, j=0; i<length-1;i++) {
	if (i<j) {
	    temp = f[j];
	    f[j] = f[i];
	    f[i] = temp;
	}
	k = length>>1;
	while (k<=j) {
	    j -= k;
	    k>>=1;
	}
	j += k;
    }
    return self;
}

- fftRX2:(int)powerOfTwo array:(float *)array
{
    /*	An in-place, decimation-in-time, split-radix FFT algorithm.  This code 
    was "lifted" from the file hfft.c in the CCRMA directory
    /dist/SignalProcessing/dspkit by Gary Scavone.
    */
    
    float *x, e;
    float cc1, ss1, cc3, ss3;
    int nn, is, iw, i0, i1, i2, i3, i4, i5, i6, i7, i8;
    float t1, t2, t3, t4, t5, t6;
    int n, n2, n4, n8, i, j, a, a3, pc;
    
    n = pow(2.0 , (double)powerOfTwo);
    nn = n>>1;
    if (n!=lastLength)	{
	[self makeSines:n];
	lastLength = n;
    }
    [self scramble:n array:array];
    x = array - 1;			/* FORTRAN indexing compatibility. */
    is = 1;
    iw = 4;
    do {
	for(i0=is; i0<=n; i0+=iw) {
	    i1 = i0+1;
	    e = x[i0];
	    x[i0] = e + x[i1];
	    x[i1] = e - x[i1];
	}
	is = (iw<<1)-1;
	iw <<= 2;
    } while(is<n);
    n2 = 2;
    while(nn>>=1) {
	n2 <<= 1;
	n4 = n2>>2;
	n8 = n2>>3;
	is = 0;
	iw = n2<<1;
	do {
	    for(i=is; i<n; i+=iw) {
		i1 = i+1;
		i2 = i1 + n4;
		i3 = i2 + n4;
		i4 = i3 + n4;
		t1 = x[i4]+x[i3];
		x[i4] -= x[i3];
		x[i3] = x[i1] - t1;
		x[i1] += t1;
		if(n4==1) continue;
		i1 += n8;
		i2 += n8;
		i3 += n8;
		i4 += n8;
		t1 = (x[i3]+x[i4]) * SQRT_HALF;
		t2 = (x[i3]-x[i4]) * SQRT_HALF;
		x[i4] = x[i2] - t1;
		x[i3] = -x[i2] - t1;
		x[i2] = x[i1] - t2;
		x[i1] += t2;
	    }
	    is = (iw<<1) - n2;
	    iw <<= 2;
	} while(is<n);
	a = pc = n/n2;
	for(j=2;j<=n8;j++) {
	    a3 = (a + (a<<1)) & (n-1);                        
	    cc1 = cosines[a];
	    ss1 = sines[a];
	    cc3 = cosines[a3];
	    ss3 = sines[a3];
	    a = (a+pc) & (n-1);
	    is = 0;
	    iw = n2<<1;
	    do {
		for(i=is; i<n; i+=iw) {
		    i1 = i+j;
		    i2 = i1 + n4;
		    i3 = i2 + n4;
		    i4 = i3 + n4;
		    i5 = i + n4 - j + 2;
		    i6 = i5 + n4;
		    i7 = i6 + n4;
		    i8 = i7 + n4;
		    t1 = x[i3]*cc1 + x[i7]*ss1;
		    t2 = x[i7]*cc1 - x[i3]*ss1;
		    t3 = x[i4]*cc3 + x[i8]*ss3;
		    t4 = x[i8]*cc3 - x[i4]*ss3;
		    t5 = t1 + t3;
		    t6 = t2 + t4;
		    t3 = t1 - t3;
		    t4 = t2 - t4;
		    x[i8] = x[i6] + t6;
		    x[i3] = t6 - x[i6];
		    x[i4] = x[i2] - t3;
		    x[i7] = -x[i2] - t3;
		    x[i6] = x[i1] - t5;
		    x[i1] += t5;
		    x[i2] = x[i5] + t4;
		    x[i5] -= t4;
		}
		is = (iw<<1) - n2;
		iw <<= 2;
	    } while(is<n);
	}
    }
    return self;
}

- fhtRX4:(int)powerOfFour array:(float *)array
{
    /*	In place Fast Hartley Transform of floating point data in array.
    Size of data array must be power of four. Lots of sets of four 
    inline code statements, so it is verbose and repetitive, but fast. 
    A 1024 point FHT takes approximately 80 milliseconds on the NeXT computer
    (not in the DSP 56001, just in compiled C as shown here).
    
    The Fast Hartley Transform algorithm is patented, and is documented
    in the book "The Hartley Transform", by Ronald N. Bracewell.
    This routine was converted to C from a BASIC routine in the above book,
    that routine Copyright 1985, The Board of Trustees of Stanford University
    */
    
    register int j=0, i=0, k=0, L=0;
    int n=0, n4=0, d1=0, d2=0, d3=0, d4=0, d5=1, d6=0, d7=0, d8=0, d9=0;
    int L1=0, L2=0, L3=0, L4=0, L5=0, L6=0, L7=0, L8=0;
    int nOverD3;
    float r=0.0;
    int a1=0, a2=0, a3=0;
    float t=0.0, t1=0.0, t2=0.0, t3=0.0, t4=0.0, t5=0.0, t6=0.0, t7=0.0;
    float t8=0.0, t9=0.0, t0=0.0;
    n = pow(4.0 , (double)powerOfFour);
    if (n!=lastLength)	{
	[self makeSines:n];
	lastLength = n;
    }
    n4 = n / 4;
    r = SQRT_TWO;
    j = 1;
    i = 0;
    while (i<n-1) {
	i++;
	if (i<j) {
	    t = array[j-1];
	    array[j-1] = array[i-1];
	    array[i-1] = t;
    	}
	k = n4;
	while ((3*k)<j)	{
	    j -= 3 * k;
	    k /= 4;
	}
	j += k;
    }
    for (i=0; i<n; i += 4) {
	t5 = array[i];
	t6 = array[i+1];
	t7 = array[i+2];
	t8 = array[i+3];
	t1 = t5 + t6;
	t2 = t5 - t6;
	t3 = t7 + t8;
	t4 = t7 - t8;
	array[i] = t1 + t3;
	array[i+1] = t1 - t3;
	array[i+2] = t2 + t4;
	array[i+3] = t2 - t4;
    }
    for (L=2; L<=powerOfFour; L++) {
	d1 = pow(2.0 , L+L-3.0);
	d2=d1+d1;
	d3=d2+d2;
	nOverD3 = n / 2 / d3;
	d4=d2+d3;
	d5=d3+d3;
	for (j=0; j<n; j += d5) {
	    t5 = array[j];
	    t6 = array[j+d2];
	    t7 = array[j+d3];
	    t8 = array[j+d4];
	    t1 = t5+t6;
	    t2 = t5-t6;
	    t3 = t7+t8;
	    t4 = t7-t8;
	    array[j] = t1 + t3;
	    array[j+d2] = t1 - t3;
	    array[j+d3] = t2 + t4;
	    array[j+d4] = t2 - t4;
	    d6 = j+d1;
	    d7 = j+d1+d2;
	    d8 = j+d1+d3;
	    d9 = j+d1+d4;
	    t1 = array[d6];
	    t2 = array[d7] * r;
	    t3 = array[d8];
	    t4 = array[d9] * r;
	    array[d6] = t1 + t2 + t3;
	    array[d7] = t1 - t3 + t4;
	    array[d8] = t1 - t2 + t3;
	    array[d9] = t1 - t3 - t4;
	    for (k=1; k<d1; k++) {
		L1 = j + k;
		L2 = L1 + d2;
		L3 = L1 + d3;
		L4 = L1 + d4;
		L5 = j + d2 - k;
		L6 = L5 + d2;
		L7 = L5 + d3;
		L8 = L5 + d4;
		a1 = (int) (k * nOverD3) % n;
		a2 = (a1 + a1) % n;
		a3 = (a1 + a2) % n;
		t5 = array[L2] * cosines[a1] + array[L6] * sines[a1];
		t6 = array[L3] * cosines[a2] + array[L7] * sines[a2];
		t7 = array[L4] * cosines[a3] + array[L8] * sines[a3];
		t8 = array[L6] * cosines[a1] - array[L2] * sines[a1];
		t9 = array[L7] * cosines[a2] - array[L3] * sines[a2];
		t0 = array[L8] * cosines[a3] - array[L4] * sines[a3];
		t1 = array[L5] - t9;
		t2 = array[L5] + t9;
		t3 = - t8 - t0;
		t4 = t5 - t7;
		array[L5] = t1 + t4;
		array[L6] = t2 + t3;
		array[L7] = t1 - t4;
		array[L8] = t2 - t3;
		t1 = array[L1] + t6;
		t2 = array[L1] - t6;
		t3 = t8 - t0;
		t4 = t5 + t7;
		array[L1] = t1 + t4;
		array[L2] = t2 + t3;
		array[L3] = t1 - t4;
		array[L4] = t2 - t3;
	    }
	}
    }		  
    return self;
}

@end
