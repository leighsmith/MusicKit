/******************************************************************************
LEGAL:

This framework and all source code supplied with it, except where
specified, are Copyright Stephen Brandon and the University of
Glasgow, 1999. You are free to use the source code for any purpose,
including commercial applications, as long as you reproduce this
notice on all such software.

Software production is complex and we cannot warrant that the Software
will be error free.  Further, we will not be liable to you if the
Software is not fit for the purpose for which you acquired it, or of
satisfactory quality.

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS
ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED
WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND
NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury
caused by our negligence our liability shall be unlimited.

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF
CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY
ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED
DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF
THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN
COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#include "SndEndianFunctions.h"

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

unsigned char *SndSwap_Convert16BitNative2LittleEndian(unsigned short si)
{
    static unsigned char pch[2];
    
    pch[0] = (si & 0x00FF);
    pch[1] = (si & 0xFF00) >> 8;
    return pch;
}

unsigned char *SndSwap_Convert32BitNative2LittleEndian(unsigned long li)
{
    static unsigned char pch[4];
    
    pch[0] = (li & 0x000000FF);
    pch[1] = (li & 0x0000FF00) >> 8;
    pch[2] = (li & 0x00FF0000) >> 16;
    pch[3] = (li & 0xFF000000) >> 24;
    return pch;
}


