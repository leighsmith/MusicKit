/******************************************************************************
LEGAL:
This framework and all source code supplied with it, except where specified, 
are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free 
to use the source code for any purpose, including commercial applications, as 
long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be 
error free.  Further, we will not be liable to you if the Software is not fit 
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL 
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES 
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD 
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our 
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, 
LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR 
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE 
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED 
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS 
OF THIS AGREEMENT.

******************************************************************************/

#ifndef __SNDDISPLAYDATA_H__
#define __SNDDISPLAYDATA_H__

#import <AppKit/AppKit.h>

/*!
@class SndDisplayData
@abstract
@discussion For internal use of the SndView
*/

@interface SndDisplayData:NSObject
{
/*! @var pixelCount */  
	int pixelCount;
/*! @var startPixel */  
	int startPixel;
/*! @var maxArray   */  
	float *maxArray;
/*! @var minArray   */  
	float *minArray;
}
/*!
 @method pixelCount
 */
- (int) pixelCount;
/*!
 @method startPixel
 */
- (int)startPixel;
/*!
 @method
 */
- (int) endPixel;
/*!
 @method pixelDataMax
 */
- (float*) pixelDataMax;
/*!
 @method pixelDataMin
 */
- (float*) pixelDataMin;

/*!
 @method setPixelDataMax:min:count:start:
 */
- setPixelDataMax:(float *)data min:(float *)data2 count:(int)count start:(int)start;
/*!
 @method setPixelDataMax:count:start:
 */
- setPixelDataMax:(float *)data count:(int)count start:(int)start;
/*!
 @method setPixelDataMin:count:start:
 */
- setPixelDataMin:(float *)data count:(int)count start:(int)start;

/*!
 @method addPixelDataMax:min:count:from:
 */
- addPixelDataMax:(float *)data min:(float *)data2 count:(int)count from:(int)from;
/*!
 @method addPixelDataMax:count:from:
 */
- addPixelDataMax:(float *)data count:(int)count from:(int)from;
/*!
 @method addPixelDataMin:count:from:
 */
- addPixelDataMin:(float *)data count:(int)count from:(int)from;

/*!
 @method addDataFrom:
 */
- addDataFrom:(SndDisplayData *)anObject;
/*!
 @method truncateToLastPixel:
 */
- (BOOL)truncateToLastPixel:(int)pixel;
/*!
 @method truncateToFirstPixel:
 */
- (BOOL)truncateToFirstPixel:(int)pixel;
@end

#endif
