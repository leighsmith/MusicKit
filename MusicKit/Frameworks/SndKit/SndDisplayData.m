/******************************************************************************
$Id$

Description: Hold-all for displaying a sound.

Original Author: Stephen Brandon

LEGAL:
This framework and all source code supplied with it, except where specified, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

******************************************************************************/

#import "SndDisplayData.h"

@implementation SndDisplayData
+ (void)initialize
{
  if (self == [SndDisplayData class])
  {
    [self setVersion: 0];
  }
  return;
}
-init
{
	[super init];
	pixelCount = startPixel = 0;
	maxArray = minArray = NULL;
	return self;
}
- (void) free
{
    [self dealloc];
}
- (void)dealloc
{
	if (maxArray) free(maxArray);
	if (minArray) free(minArray);
	{ [super dealloc]; return; };
}

- (int)pixelCount
{
	return pixelCount;
}
- (int)startPixel
{
	return startPixel;
}
- (int)endPixel
{
	return startPixel + pixelCount - 1;
}
- (float *)pixelDataMax
{
	return maxArray;
}
- (float *)pixelDataMin
{
	return minArray;
}
- setPixelDataMax:(float *)data min:(float *)data2 count:(int)count start:(int)start
{
	if (![self setPixelDataMax:(float *)data count:(int)count start:(int)start])
		return nil;
	if (![self setPixelDataMin:(float *)data2 count:(int)count start:-1])
		return nil;
	return self;
}
- setPixelDataMax:(float *)data count:(int)count start:(int)start
{
	if (maxArray) {
		free(maxArray);
		maxArray = NULL;
		}
	maxArray = (float *)malloc(count * sizeof(float));
	if (maxArray) {
		pixelCount = count;
		memmove(maxArray,data, count * sizeof(float));
		if (start != -1) startPixel = start;
		return self;
	}
	return nil;
}
- setPixelDataMin:(float *)data count:(int)count start:(int)start
{
	if (minArray) {
		free(minArray);
		minArray = NULL;
		}
	minArray = (float *)malloc(count * sizeof(float));
	if (minArray) {
		pixelCount = count;
		memmove(minArray,data, count * sizeof(float));
		if (start != -1) startPixel = start;
		return self;
	}
	return nil;
}
- addPixelDataMax:(float *)data min:(float *)data2 count:(int)count from:(int)from
{
 /* 'from' is expressed in terms of the position within the sound being cached.
  * It's not a direct index into the alloc'ed arrays.
  */
	if (![self addPixelDataMax:(float *)data count:count from:from - startPixel])
		return nil;
	if (![self addPixelDataMin:(float *)data2 count:count from:from - startPixel])
		return nil;
	return self;
}
- addPixelDataMax:(float *)data count:(int)count from:(int)from
{ /* here, from is a direct index into our array */
	int newSize = from + count;
	maxArray = (float *) realloc(maxArray,newSize * sizeof(float));
	if (maxArray) {
		pixelCount = newSize;
		memmove(maxArray + from ,data, count * sizeof(float));
		return self;
	}
	return nil;
}
- addPixelDataMin:(float *)data count:(int)count from:(int)from
{/* here, from is a direct index into our array */
	int newSize = from + count;
	minArray = (float *) realloc(minArray,newSize * sizeof(float));
	if (minArray) {
		pixelCount = newSize;
		memmove(minArray + from ,data, count * sizeof(float));
		return self;
	}
	return nil;
}
- addDataFrom:(SndDisplayData *)anObject
{
	float *newMaxArray,*newMinArray;
	int newStartPoint,newCount;
	if (!anObject) return nil;
	newMaxArray = [anObject pixelDataMax];
	newMinArray = [anObject pixelDataMin];
	newCount = [anObject pixelCount];
	newStartPoint = [anObject startPixel];
	
	if (!newMinArray || !newMaxArray) return nil;
	if (!newCount) return self; /* consider it done... */
	if (newStartPoint > pixelCount + startPixel) {
		printf("SndDisplayData: discontinuous data append (expected %d got %d)\n",
			pixelCount + startPixel,newStartPoint);
		return nil;
		}
	if (newStartPoint < pixelCount + startPixel)
		printf("SndDisplayData: new data overlaps, but continuing (expected %d got %d)\n",
			pixelCount + startPixel,newStartPoint);
	[self addPixelDataMax:newMaxArray min:newMinArray count:(int)newCount
		from:(int)newStartPoint];
	return self;
}
- (BOOL)truncateToLastPixel:(int)pixel;
{
	pixelCount = pixel - startPixel + 1;
	maxArray = (float *) realloc(maxArray, pixelCount * sizeof(float));
	minArray = (float *) realloc(minArray, pixelCount * sizeof(float));
	return (maxArray != NULL && minArray != NULL);
}

- (BOOL)truncateToFirstPixel:(int)pixel
{
	int newBase = pixel - startPixel;
	int newCount = pixelCount - newBase;
	int i;
	if (!maxArray || !minArray) return NO;
	for (i = 0;i < newCount; i++) {
		maxArray[i] = maxArray[newBase + i];
		minArray[i] = minArray[newBase + i];
	} /* shove all data from area which will survive, down into bottom of array */
	maxArray = (float *) realloc(maxArray, newCount * sizeof(float));
	minArray = (float *) realloc(minArray, newCount * sizeof(float));
	startPixel = pixel;
	pixelCount = newCount;
	return (maxArray != NULL && minArray != NULL);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	int v = [aDecoder versionForClassName:@"SndView"];
	if (v == 0) {
		[aDecoder decodeValuesOfObjCTypes:"ii", &pixelCount, &startPixel];
		
		maxArray = (float *)malloc(pixelCount * sizeof(float));
		minArray = (float *)malloc(pixelCount * sizeof(float));
		[aDecoder decodeArrayOfObjCType:"f" count:pixelCount at:maxArray];
		[aDecoder decodeArrayOfObjCType:"f" count:pixelCount at:minArray];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

	[aCoder encodeValuesOfObjCTypes:"ii", &pixelCount, &startPixel];
	[aCoder encodeArrayOfObjCType:"f" count:pixelCount at:maxArray];
	[aCoder encodeArrayOfObjCType:"f" count:pixelCount at:minArray];
}

@end
