/******************************************************************************
LEGAL:
This example application and all source code supplied with it, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#import <AppKit/AppKit.h>

@interface SndDisplayData:NSObject
{
	int pixelCount;
	int startPixel;
	float *maxArray;
	float *minArray;
}
- (int)pixelCount;
- (int)startPixel;
- (int)endPixel;
- (float *)pixelDataMax;
- (float *)pixelDataMin;

- setPixelDataMax:(float *)data min:(float *)data2 count:(int)count start:(int)start;
- setPixelDataMax:(float *)data count:(int)count start:(int)start;
- setPixelDataMin:(float *)data count:(int)count start:(int)start;

- addPixelDataMax:(float *)data min:(float *)data2 count:(int)count from:(int)from;
- addPixelDataMax:(float *)data count:(int)count from:(int)from;
- addPixelDataMin:(float *)data count:(int)count from:(int)from;

- addDataFrom:(SndDisplayData *)anObject;
- (BOOL)truncateToLastPixel:(int)pixel;
- (BOOL)truncateToFirstPixel:(int)pixel;
@end
