/******************************************************************************
LEGAL:
This example application and all source code supplied with it, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#import "SndDisplayDataList.h"
#import "SndDisplayData.h"

@implementation SndDisplayDataList

static int docompare(const void *x, const void *y)
{
	int first = [(id)(*(SndDisplayData **)x) startPixel];
	int second = [(id)(*(SndDisplayData **)y) startPixel];
	if (first < second) return -1;
	if (first == second) return 0;
	return 1;
}

- sort
{
	qsort((SndDisplayData **)dataPtr, numElements, sizeof(id), docompare);
	return self;
}

- (int)findObjectContaining:(int)pixel next:(int *)next leadsOnFrom:(int *)leadsOnFrom
{
	int i;
	int theStart;
	[self sort];
	for (i = 0;i < numElements; i++) {
		theStart = [[self objectAt:i] startPixel];
		if (theStart > pixel) {
			*next = i;
			if (i > 0) {
				if ([[self objectAt:i-1] endPixel] == pixel - 1)
					*leadsOnFrom = i-1;
					else *leadsOnFrom = -1;
			}
			else *leadsOnFrom = -1;
			return -1; /* passed it without finding it */
			}
		if (theStart == pixel) {
			if (i == numElements - 1) *next = -1;
				else *next = i+1;
			if (i > 0) {
				if ([[self objectAt:i-1] endPixel] == pixel - 1)
					*leadsOnFrom = i-1;
					else *leadsOnFrom = -1;
			}
			else *leadsOnFrom = -1;
			return i; /* found it, bang on target */
			}
		if ([[self objectAt:i] endPixel] >= pixel) { /* cache spans this pixel */
			if (i == numElements - 1) *next = -1;
				else *next = i+1;
			if (i > 0) {
				if ([[self objectAt:i-1] endPixel] == [[self objectAt:i] startPixel] - 1)
					*leadsOnFrom = i-1;
					else *leadsOnFrom = -1;
			}
			else *leadsOnFrom = -1;
			 return i; /* found it */
			}
	}
	if (numElements > 0) {
		if ([[self objectAt:numElements - 1] endPixel] == pixel - 1)
			*leadsOnFrom = numElements - 1;
		else *leadsOnFrom = -1;
	}
	else *leadsOnFrom = -1;
	*next = -1;
	return -1; /* went through all caches and it's not there */
}
@end
