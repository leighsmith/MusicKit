/******************************************************************************
LEGAL:
This framework and all source code supplied with it, except where specified, are 
Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to 
use the source code for any purpose, including commercial applications, as long 
as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be 
error free.  Further, we will not be liable to you if the Software is not fit 
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL 
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF 
QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES 
RIGHTS.

If a court finds that we are liable for death or personal injury caused by our 
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS 
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR 
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED 
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS 
OF THIS AGREEMENT.

******************************************************************************/

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

float 			     SndSwapSwappedFloatToHost  (SndSwappedFloat aSwappedFloat);
SndSwappedFloat  SndSwapHostToSwappedFloat  (float aFloat);
double 			     SndSwapSwappedDoubleToHost (SndSwappedDouble aSwappedDouble);
SndSwappedDouble SndSwapHostToSwappedDouble (double aDouble);

/*! @function SndSwap_Convert16BitNative2LittleEndian
    @param si 2 byte native word to be byte swapped (if needed) to Little Endian
    @result Pointer to the byte swapped value. Do NOT store this!  
*/
char* SndSwap_Convert16BitNative2LittleEndian(unsigned short si);
/*! @function SndSwap_Convert32BitNative2LittleEndian
    @param li 4 byte native word to be byte swapped (if needed) to Little Endian
    @result Pointer to the byte swapped value. Do NOT store this!  
*/
char* SndSwap_Convert32BitNative2LittleEndian(unsigned long  li);


#endif
