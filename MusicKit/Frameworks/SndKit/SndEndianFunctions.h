#ifndef __SND_ENDIAN_FUNCTIONS__
#define __SND_ENDIAN_FUNCTIONS__

typedef unsigned long int SndSwappedFloat;
typedef unsigned long long int SndSwappedDouble;

typedef union _SndSwappedFloatUnion {
	float aFloat;
	SndSwappedFloat theSwappedFloat;
	char ch[4];
} SndSwappedFloatUnion;

typedef union _SndSwappedDoubleUnion {
	double aDouble;
	SndSwappedDouble theSwappedDouble;
	char ch[8];
} SndSwappedDoubleUnion;

float 			SndSwapSwappedFloatToHost(SndSwappedFloat aSwappedFloat);
SndSwappedFloat SndSwapHostToSwappedFloat(float aFloat);
double 			SndSwapSwappedDoubleToHost(SndSwappedDouble aSwappedDouble);
SndSwappedDouble	SndSwapHostToSwappedDouble(double aDouble);

#endif
