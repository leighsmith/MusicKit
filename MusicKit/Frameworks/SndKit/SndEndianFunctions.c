#import "SndEndianFunctions.h"

float SndSwapSwappedFloatToHost(SndSwappedFloat aSwappedFloat)
{
	SndSwappedFloatUnion mySwappedFloat;
	char a,b;
	mySwappedFloat.theSwappedFloat = aSwappedFloat;
	a = mySwappedFloat.ch[0];
	b = mySwappedFloat.ch[1];
	mySwappedFloat.ch[0] = mySwappedFloat.ch[3];
	mySwappedFloat.ch[1] = mySwappedFloat.ch[2];
	mySwappedFloat.ch[2] = b;
	mySwappedFloat.ch[3] = a;
	return mySwappedFloat.aFloat;
}

SndSwappedFloat SndSwapHostToSwappedFloat(float aFloat)
{
	SndSwappedFloatUnion mySwappedFloat;
	char a,b;
	mySwappedFloat.aFloat = aFloat;
	a = mySwappedFloat.ch[0];
	b = mySwappedFloat.ch[1];
	mySwappedFloat.ch[0] = mySwappedFloat.ch[3];
	mySwappedFloat.ch[1] = mySwappedFloat.ch[2];
	mySwappedFloat.ch[2] = b;
	mySwappedFloat.ch[3] = a;
	return mySwappedFloat.theSwappedFloat;
}

double SndSwapSwappedDoubleToHost(SndSwappedDouble aSwappedDouble)
{
	SndSwappedDoubleUnion mySwappedDouble;
	char a,b,c,d;
	mySwappedDouble.theSwappedDouble = aSwappedDouble;
	a = mySwappedDouble.ch[0];
	b = mySwappedDouble.ch[1];
	c = mySwappedDouble.ch[2];
	d = mySwappedDouble.ch[3];
	mySwappedDouble.ch[0] = mySwappedDouble.ch[7];
	mySwappedDouble.ch[1] = mySwappedDouble.ch[6];
	mySwappedDouble.ch[2] = mySwappedDouble.ch[5];
	mySwappedDouble.ch[3] = mySwappedDouble.ch[4];
	mySwappedDouble.ch[4] = d;
	mySwappedDouble.ch[5] = c;
	mySwappedDouble.ch[6] = b;
	mySwappedDouble.ch[7] = a;
	return mySwappedDouble.aDouble;
}

SndSwappedDouble SndSwapHostToSwappedDouble(double aDouble)
{
	SndSwappedDoubleUnion mySwappedDouble;
	char a,b,c,d;
	mySwappedDouble.aDouble = aDouble;
	a = mySwappedDouble.ch[0];
	b = mySwappedDouble.ch[1];
	c = mySwappedDouble.ch[2];
	d = mySwappedDouble.ch[3];
	mySwappedDouble.ch[0] = mySwappedDouble.ch[7];
	mySwappedDouble.ch[1] = mySwappedDouble.ch[6];
	mySwappedDouble.ch[2] = mySwappedDouble.ch[5];
	mySwappedDouble.ch[3] = mySwappedDouble.ch[4];
	mySwappedDouble.ch[4] = d;
	mySwappedDouble.ch[5] = c;
	mySwappedDouble.ch[6] = b;
	mySwappedDouble.ch[7] = a;
	return mySwappedDouble.theSwappedDouble;
}
