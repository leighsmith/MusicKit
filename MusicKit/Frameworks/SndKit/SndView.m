/******************************************************************************
$Id$

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

If a court finds that we are liable for death or personal injury caused by 
our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS 
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR 
POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE 
NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED 
DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS 
OF THIS AGREEMENT.

******************************************************************************/

#import "SndView.h"
#import <math.h>

#if !defined(QUARTZ_RENDERING) && !defined(GNUSTEP)
#define USE_PS_USER_PATHS
#define DISPLAY_SOUNDDEVICE_INFO
//#define DO_TIMING
#endif

#ifdef USE_PS_USER_PATHS
#import "UserPath.h"
#endif

/* For 250 pixels, on black m68k hardware, user paths take 1.872 s for 100 iterations.
 * Without user paths, the same operations take on average 8.4 seconds!
 * These timings were taken with the Timing class, bracketed around the part of
 * the drawing code that transfers numbers in the arrays to PostScript.
 */

#define startTimer(timer) if (!timer)  { timer = YES; [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.01];}

#define stopTimer(timer) if (timer) {[NSEvent stopPeriodicEvents];timer = NO;}

#define MOVE_MASK NSLeftMouseUpMask|NSLeftMouseDraggedMask

#define NXSoundPboardTypeOld @"NeXT sound pasteboard type"

@implementation SndView

+ (void) initialize
{
  if (self == [SndView class]) {
    (void) [SndView setVersion: (int)0];
  }

  return;
}

- (BOOL) acceptsFirstResponder
{
	return (!svFlags.disabled);
}

- (void) toggleCursor
{

  /*
    NSRect cursorRect = [self bounds];

    cursorRect.origin.x = (int) ( (float) NSMinX(selectionRect) /
				  (float)reductionFactor);

    cursorRect.size.width = 1;
    [self lockFocus];

    //    [selectionColour set];

    //    NSRectFillUsingOperation(cursorRect, NSCompositeSourceOver);

    //    NSHighlightRect(cursorRect);

    [self unlockFocus];
    [[self window] flushWindow];
    svFlags.cursorOn = !svFlags.cursorOn;
  */
}

- hideCursor
{
  /*
    if (teNum) {

      [teNum invalidate];
      [teNum release];
      teNum = NULL;

      if (svFlags.cursorOn)
	[self toggleCursor];

      svFlags.cursorOn = NO;
    }

  */
    return self;
}


- showCursor
{

  /*
  if (!teNum) {

    if (NSWidth(selectionRect) < 0.1) {

      if (!svFlags.cursorOn)
	[self toggleCursor];

      teNum = [[NSTimer scheduledTimerWithTimeInterval:0.5
			target:self
			selector:@selector(toggleCursor)
			userInfo:self
			repeats:YES] retain];
    }
  }

  */

  return self;
}

- (void) initVars
{
    NSArray * validSendTypes = [[[NSArray alloc]
				  initWithObjects:NXSoundPboardType,
				  NXSoundPboardTypeOld, nil] autorelease];

    NSArray * validReturnTypes = [[[NSArray alloc]
				    initWithObjects:NXSoundPboardType,
				    NXSoundPboardTypeOld, nil] autorelease];

    [NSApp registerServicesMenuSendTypes:validSendTypes
                             returnTypes:validReturnTypes];

    delegate = nil;
    _scratchSound = nil;
    sound = nil;
    _pasteboardSound = nil;

    /* set colors */

    //    selectionColour = [[NSColor controlHighlightColor] retain];
    //    selectionColour = [[NSColor purpleColor] retain];

    selectionColour = [[NSColor colorWithCalibratedRed:1. green:.875 blue:.875
    			alpha:1.] retain];

    //    backgroundColour = [[NSColor controlBackgroundColor] retain];
    //    backgroundColour = [[NSColor blackColor] retain];
    //    backgroundColour = [[NSColor clearColor] retain];

    //    backgroundColour = [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1]
    //		 retain];

    backgroundColour = [[NSColor colorWithCalibratedRed:.25 green:0 blue:0.
    			alpha:.1] retain];

    //    foregroundColour = [[NSColor blueColor] retain];//black

    foregroundColour = [[NSColor colorWithCalibratedRed:.6 green:.25 blue:1.
    			alpha:1.] retain];


    displayMode = NX_SOUNDVIEW_MINMAX;
    selectionRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    reductionFactor = 4.0; /* bogus */
    dataList = [[SndDisplayDataList alloc] init];

    svFlags.disabled=0;
    svFlags.continuous=0;
    svFlags.cursorOn=0;
    svFlags.drawsCrosses = 1;
    svFlags.autoscale=0;
    svFlags.bezeled=0;
    svFlags.notEditable=0;
    svFlags.notOptimizedForSpeed=0;
    optThreshold = FASTSKIPSTART;
    optSkip = FASTSKIPAMOUNT;
    peakFraction = TENPERCENT;
    stereoMode = SV_STEREOMODE;

    defaultRecordFormat = SND_FORMAT_MULAW_8;
    defaultRecordChannelCount = 1;
    defaultRecordSampleRate = SND_RATE_CODEC;
    defaultRecordSeconds = DEFAULT_RECORD_SECONDS;

    _lastCopyCount = _lastPasteCount = 0;
    teNum = 0;
    notProvidedData = NO;
    noSelectionDraw = NO;
    firstDraw = YES;

    selectionRect.origin.x = selectionRect.size.width = 0;
    
    return;
}

- (BOOL)scrollPointToVisible:(const NSPoint)point
{
    NSRect r;

    r.origin = point;
    r.size.width = r.size.height = 0.1;

    return [self scrollRectToVisible:r];
}

- (BOOL)resignFirstResponder
{
    return YES;
}
- (BOOL)becomeFirstResponder;
{
    return YES;
}

- (void)copy:(id)sender;
{
    NSPasteboard *pboard;
    NSArray *typesList=nil;
    pboard = [NSPasteboard generalPasteboard];
    [self writeSelectionToPasteboardNoProvide:pboard types:typesList];
    return;
}
- (void)cut:(id)sender;
{
    [self copy:sender];
    [self delete:sender];
    return;
}
- (void)delete:(id)sender;
{
    if (NSWidth(selectionRect) < 0.1) return;
    if (!sound) return;
    if ([sound sampleCount] < NSMaxX(selectionRect)) return;
    if (![sound isEditable]) return;
    if (svFlags.notEditable) return;
    [sound deleteSamplesAt:(int)((float)NSMinX(selectionRect) + 0.1)
                                          count:(int)((float)NSWidth(selectionRect) + 0.1)];
    [self invalidateCacheStartSample:(int)((float)NSMinX(selectionRect) + 0.1)
                  end:[sound sampleCount]];
    selectionRect.size.width = 0.0;
    if (!svFlags.autoscale) [self sizeToFit];
    else { /* scaleToFit does not autodisplay, but sizeToFit does */
            [self scaleToFit];
            [self setNeedsDisplay:YES];
            }

    /*
    [[self window] disableFlushWindow];
    [self showCursor];
    [[self window] enableFlushWindow];
    */

    [self tellDelegate:@selector(soundDidChange:)];
    return;
}
- (void) paste: (id) sender;
{
    NSPasteboard *pboard;

    pboard = [NSPasteboard generalPasteboard];
    [self readSelectionFromPasteboard:pboard];
}
- (void)selectAll:(id)sender;
{
    if (!sound) return;

/*
    [[self window] disableFlushWindow];
    [self hideCursor];
    [[self window] enableFlushWindow];
*/

    selectionRect.origin.x = 0;
    selectionRect.size.width = [sound sampleCount];
    [self setNeedsDisplay:YES];
//  printf("FINAL SELECTION %g, %g\n",NX_X(&selectionRect),NX_WIDTH(&selectionRect));
    return;
}
- delegate;
{
    return delegate;
}
- (int)displayMode;
{
    return displayMode;
}
- (void)setDisplayMode:(int)aMode /*NX_SOUNDVIEW_WAVE or NX_SOUNDVIEW_MINMAX*/
{
    if (displayMode != aMode) [self invalidateCache];
    else return;
    displayMode = aMode;
    [self setNeedsDisplay:YES];
    return;
}
- drawSamplesFrom:(int)first to:(int)last;
{
    return self;
}
/*
int bytesFromFormat(int format)
{
    int numBytes;
        switch (format) {
            case SND_FORMAT_MULAW_8:
            case SND_FORMAT_LINEAR_8:
                numBytes = 1;
                break;
            case SND_FORMAT_EMPHASIZED:
            case SND_FORMAT_COMPRESSED:
            case SND_FORMAT_COMPRESSED_EMPHASIZED:
            case SND_FORMAT_DSP_DATA_16:
            case SND_FORMAT_LINEAR_16:
                numBytes = 2;
                break;
            case SND_FORMAT_LINEAR_24:
            case SND_FORMAT_DSP_DATA_24:
                numBytes = 3;
                break;
            case SND_FORMAT_LINEAR_32:
            case SND_FORMAT_DSP_DATA_32:
                numBytes = 4;
                break;
            case SND_FORMAT_FLOAT:
                numBytes = sizeof(float);
                break;
            case SND_FORMAT_DOUBLE:
                numBytes = sizeof(double);
                break;
            default: // just in case 
                numBytes = 2;
                break;
        }
    return numBytes;
}
*/
void *getDataAddresses(int sample,
		SndSoundStruct *theSound,
		int *lastSampleInBlock,
		int *currentSample)
/* returns the base address of the block the sample resides in, with appropriate indices for the 
 * last sample the block holds. Indices count from 0 so they can be utilised directly.
 */
{
    int cc = theSound->channelCount;
    int df = theSound->dataFormat;
    int ds = theSound->dataSize;
    int numBytes;
    SndSoundStruct **ssList;
    SndSoundStruct *theStruct;
    int i=0,count=0,oldCount = 0;

    if (df == SND_FORMAT_INDIRECT)
        df = ((SndSoundStruct *)(*((SndSoundStruct **)(theSound->dataLocation))))->dataFormat;

    numBytes = SndSampleWidth(df);

    if ((theSound->dataFormat) != SND_FORMAT_INDIRECT) {
        *lastSampleInBlock = ds / cc / numBytes;
        *currentSample = sample;
        return (char *)theSound + theSound->dataLocation;
    }
    ssList = (SndSoundStruct **)theSound->dataLocation;
    while ((theStruct = ssList[i++]) != NULL) {
        count += ((theStruct->dataSize) / cc / numBytes);
        if (count > sample) {
            *lastSampleInBlock = ((theStruct->dataSize) / cc / numBytes);
            *currentSample = sample - oldCount;
            return (char *)theStruct + theStruct->dataLocation;
        }
        oldCount = count;
    }
    *currentSample = -1;
    *lastSampleInBlock = -1;
    return NULL;
}

double getSoundValue(void *myData,int myType,int myActualSample)
{
    double theValue;
    switch (myType) {
        case SND_FORMAT_LINEAR_8:
            theValue = ((char *)myData)[myActualSample];
            break;
        case SND_FORMAT_MULAW_8:
            theValue = SndiMulaw(((char *)myData)[myActualSample]);
            break;
        case SND_FORMAT_EMPHASIZED:
        case SND_FORMAT_COMPRESSED:
        case SND_FORMAT_COMPRESSED_EMPHASIZED:
        case SND_FORMAT_DSP_DATA_16:
        case SND_FORMAT_LINEAR_16:
            theValue = (signed short)NSSwapBigShortToHost(((short *)myData)[myActualSample]);
            break;
        case SND_FORMAT_LINEAR_24:
        case SND_FORMAT_DSP_DATA_24:
            theValue = ((short *)myData)[myActualSample];
            break; /* don't know how to get 24 bit number! */
        case SND_FORMAT_LINEAR_32:
        case SND_FORMAT_DSP_DATA_32:
            theValue = (signed int)NSSwapBigIntToHost(((int *)myData)[myActualSample]);
            break;
        case SND_FORMAT_FLOAT:
#ifdef __LITTLE_ENDIAN__
            theValue = (float)NSConvertSwappedFloatToHost(((NSSwappedFloat *)myData)[myActualSample]);
#else
            theValue = ((float *)myData)[myActualSample];
#endif
            break;
        case SND_FORMAT_DOUBLE:
#ifdef __LITTLE_ENDIAN__
            theValue = NSConvertSwappedDoubleToHost(((NSSwappedDouble *)myData)[myActualSample]);
#else
            theValue = ((double *)myData)[myActualSample];
#endif
            break;
        default: /* just in case */
            theValue = (signed short)NSSwapBigShortToHost(((short *)myData)[myActualSample]);
            break;
    }
    return theValue;
}
double getSoundValueStereo(void *myData,int myType,int myActualSample)
{
    double theValue;
    switch (myType) {
        case SND_FORMAT_LINEAR_8:
            theValue = (((char *)myData)[myActualSample] +
                    ((char *)myData)[myActualSample + 1]) * 0.5;
            break;
        case SND_FORMAT_MULAW_8:
            theValue = SndiMulaw(((char *)myData)[myActualSample]);
            break;
        case SND_FORMAT_EMPHASIZED:
        case SND_FORMAT_COMPRESSED:
        case SND_FORMAT_COMPRESSED_EMPHASIZED:
        case SND_FORMAT_DSP_DATA_16:
        case SND_FORMAT_LINEAR_16:
            theValue = (int)(((signed short)NSSwapBigShortToHost(((short *)myData)[myActualSample]) + 
                    (signed short)NSSwapBigShortToHost(((short *)myData)[myActualSample + 1])) * 0.5);
            break;
        case SND_FORMAT_LINEAR_24:
        case SND_FORMAT_DSP_DATA_24:
            theValue = ((signed int)NSSwapBigIntToHost(((int *)myData)[myActualSample]) +
                    (signed int)NSSwapBigIntToHost(((int *)myData)[myActualSample + 1])) * 0.5;
            break; /* don't know how to get 24 bit number! */
        case SND_FORMAT_LINEAR_32:
        case SND_FORMAT_DSP_DATA_32:
            theValue = ((signed int)NSSwapBigIntToHost(((int *)myData)[myActualSample]) +
                    (signed int)NSSwapBigIntToHost(((int *)myData)[myActualSample + 1])) * 0.5;
            break;
        case SND_FORMAT_FLOAT:
#ifdef __LITTLE_ENDIAN__
            theValue = 0.5 * (NSConvertSwappedFloatToHost(((NSSwappedFloat *)myData)[myActualSample])
                    + NSConvertSwappedFloatToHost(((NSSwappedFloat *)myData)[myActualSample + 1]));
#else
            theValue = 0.5 * (((float *)myData)[myActualSample] +
                    ((float *)myData)[myActualSample + 1]);
#endif
            break;
        case SND_FORMAT_DOUBLE:
#ifdef __LITTLE_ENDIAN__
            theValue = 0.5 * (NSConvertSwappedDoubleToHost(((NSSwappedDouble *)myData)[myActualSample])
                    + NSConvertSwappedDoubleToHost(((NSSwappedDouble *)myData)[myActualSample + 1]));
#else
            theValue = 0.5 * (((double *)myData)[myActualSample] +
                    ((double *)myData)[myActualSample + 1]);
#endif
            break;
        default: /* just in case */
            theValue = 0.5 * ((signed short)NSSwapBigShortToHost(((short *)myData)[myActualSample]) +
                    (signed short)NSSwapBigShortToHost(((short *)myData)[myActualSample + 1]));
            break;
    }
    return theValue;
}

- (BOOL)invalidateCacheStartSample:(int)start end:(int)end
{
    int startPixel = start/reductionFactor;
    int endPixel = end / reductionFactor;
    if (startPixel < 0 || endPixel < startPixel) return NO;
    return [self invalidateCacheStartPixel:startPixel end:endPixel];
}
- (BOOL)invalidateCacheStartPixel:(int)start end:(int)end
{
    int startOfCache;
    int startpix,endpix;
    int i;
    SndDisplayData *theObj,*newObj;
    if (!dataList) return YES;
    if ((end != -1 && end < start) || start < 0) return NO;
    if (end == -1) end = NSWidth([self bounds]) - 1;

    for (i = [(NSMutableArray *)dataList count] - 1;i >= 0 ; i--) {
        theObj = [(NSMutableArray *)dataList objectAtIndex:i];
        startpix = [theObj startPixel];
        endpix = [theObj endPixel];
        if (startpix > end) continue; /* this cache is higher than region */
        if (endpix < start) break; /* this cache is lower than region */
        if (startpix >= start && startpix <= end &&
            endpix >= start && endpix <= end) { /* cache is enclosed in region, and deleted */
                [(NSMutableArray *)dataList removeObjectAtIndex: i];
                continue;
        }
        if (startpix < start && endpix >= start && endpix <= end) {
            /* cache starts before deletion region, so we chop off the end */
            [theObj truncateToLastPixel:start-1];
            break; /* assume this will be the last cache to consider */
        }
        if (startpix >= start && startpix <= end && endpix > end) {
            /* tail end of cache lies outside region, so we lop off the first part */
            [theObj truncateToFirstPixel:end + 1];
            continue;
        }
        /* only option left: cache encloses region, so we must create new cache
                    * for end, and truncate the first one
                    */
        startOfCache = [theObj startPixel];
        newObj = [[SndDisplayData alloc] init];
        [newObj setPixelDataMax:&[theObj pixelDataMax][end + 1 - startOfCache]
                min:&[theObj pixelDataMin][end + 1 - startOfCache]
                count:[theObj endPixel] - end
                start:end+1];
        [(NSMutableArray *)dataList insertObject:newObj atIndex:i+1];
        [theObj truncateToLastPixel:start-1];
    }
    return YES;
}

- (void)invalidateCache /* blast 'em all away */
{
    if (!dataList) return;
    [(NSMutableArray *)dataList removeAllObjects];
}

- (BOOL)isOpaque
{  return YES;	}
    
- (void)drawRect:(NSRect)rects
{
    NSRect newRect,insetBounds,scaledSelRect;
    int i,j=0;
    BOOL frag=NO;
    float thisMax,thisMin,maxNinety=0,minNinety=0,theValue,lastValue=0;
    int direction = 0; /* 0 for up, 1 for down */
    float ampScaler=1;/* bogus */
    int type;
    double maxAmp=32767;
    void *theData;
    int chanCount;
    int sampCount;
    int sampleSize=1;
    int skipFactor=1,startX,endX;
    float halfHeight=[self bounds].size.height * 0.5;
    BOOL doStereo;
    int whichChannel=0;
    /* for stepping through data */
    int actualBase,firstOfNext;
    float actualBaseF,fONBase;
    /* for working through caching: */
    int currStartPoint,arrayPointer,cacheIndex;
    /* holds the data to be drawn. Calculated from caches, or from examining sound data */
    float 	*cacheMaxArray,*cacheMinArray;
    BOOL optimize = (!svFlags.notOptimizedForSpeed && reductionFactor > optThreshold);
    int m1,c1; /* max point and current counter in current fragged sound data segment */
    SndDisplayData *currentCacheObject;	
#ifdef USE_PS_USER_PATHS
    UserPath *arect; /* for DPSUser Paths, if used */
#endif
#ifdef DO_TIMING
    id t4 = [Timing newWithTag:4];
    int numTimingPasses = 100;
#endif
#ifdef QUARTZ_RENDERING
    NSGraphicsContext *graphicsContext;
    CGContextRef ctx;

    graphicsContext = [NSGraphicsContext currentContext];
    [graphicsContext setShouldAntialias:FALSE];
    ctx = [graphicsContext graphicsPort];
    CGContextSetRGBStrokeColor(ctx, 1,0,0,1);
    CGContextSetLineWidth(ctx, 1.0);

    
#endif

    /*
    [[self window] disableFlushWindow];
    [self hideCursor];
    [[self window] enableFlushWindow];
    */

    insetBounds = [self bounds];
//        printf("from %g to %g, size %d\n",NSMinX(rects),NSMaxX(rects),(int)NSWidth(rects));

    [backgroundColour set];

    newRect = rects;
    newRect = NSIntersectionRect(insetBounds , newRect);

    if (firstDraw) {

      NSRectFill([self frame]);
      firstDraw = NO;
    }

    else
      NSRectFill(newRect);

//        printf("filling %g , %g, w %d h %d\n",NSMinX(newRect),NSMinY(newRect),(int)NSWidth(newRect),(int)NSHeight(newRect));

    if (svFlags.bezeled) {
      NSRectEdge mySides[] = {NSMinYEdge, NSMaxYEdge,
			      NSMaxXEdge, NSMaxYEdge, 
			      NSMinXEdge, NSMinYEdge, 
			      NSMinXEdge, NSMaxXEdge};
      float myGrays[] = { NSWhite, NSDarkGray,
			  NSWhite, NSDarkGray,
			  NSDarkGray, NSLightGray, 
			  NSDarkGray, NSLightGray};
      insetBounds = [self bounds];
      insetBounds  = NSDrawTiledRects(insetBounds , rects , mySides, myGrays, 8);
    }



    if (!sound)
      return;

    sampCount = [sound sampleCount];

    if (sampCount <= 0)
      return;


 /* do I need to do any other cleanup here? */

    if (!sampCount)
      return;

    /* draw sound data */

    type = [sound dataFormat];

    frag = (((SndSoundStruct *) [sound soundStruct])->dataFormat ==
	    SND_FORMAT_INDIRECT);

    if (type == SND_FORMAT_LINEAR_8) {
      maxAmp = 127;
      sampleSize = 1;
    }

    else

      if (type == SND_FORMAT_LINEAR_24 || type == SND_FORMAT_DSP_DATA_24) {
	maxAmp = (2 << 23) - 1;
	sampleSize = 3;
      }

      else

	if (type == SND_FORMAT_LINEAR_32 || type == SND_FORMAT_DSP_DATA_32) {
            maxAmp = (2 << 31) - 1;
	    sampleSize = 4;
	}

	else

	  if (type == SND_FORMAT_MULAW_8 || 
                    type == SND_FORMAT_LINEAR_16 || 
                    type == SND_FORMAT_EMPHASIZED || 
                    type == SND_FORMAT_COMPRESSED || 
                    type == SND_FORMAT_COMPRESSED_EMPHASIZED || 
                    type == SND_FORMAT_DSP_DATA_16) {
	    maxAmp = 32767;
	    sampleSize = 2;
	  }

 /* floating point: should search for max value */

	  else {
	    maxAmp = 32767;
	    sampleSize = 4;
	  };

    /* mulaw has only one sample, but a maxAmp of 32767 */

    if (type == SND_FORMAT_MULAW_8)
      sampleSize = 1;

    chanCount = [sound channelCount];
    theData = [(Snd *)sound data];
    ampScaler = [self bounds].size.height * .5 / maxAmp;

    /* check to see if user desires L&R channels summed.
       If so, check to see if there are 2 channels to sum.
       If sound is mono, just do 'left' channel
    */

    doStereo = (stereoMode == SV_STEREOMODE);

    if (!doStereo) {
      if (stereoMode > chanCount - 1)
	whichChannel = chanCount-1;

      else
	whichChannel = stereoMode;
    }

    if (doStereo)

      if (chanCount < 2) {
	doStereo = NO;
	whichChannel = 0;
      }

    /* does the following:
          * 1. set up loop from frame left to right, stepping 1 pixel
          * 2. scan sound data for time equiv to 1 pixel, finding max and min vals
          * 3. plot max and min values, and remember last ones.
          */

    cacheMaxArray = (float *)malloc(sizeof(float) * (NSWidth(rects) + 3));
    cacheMinArray = (float *)malloc(sizeof(float) * (NSWidth(rects) + 3));

#ifndef QUARTZ_RENDERING
    PSsetlinewidth(0.0);//:ps:
#else
    {
        CGContextSetLineWidth(ctx, 1);
    }
#endif

    if (reductionFactor > 1) {
      startX = NSMinX(rects);

      /* we need to draw a line leading to first pixel */

      if (NSMinX(rects) > 0.9)
	startX--;

      endX = NSMaxX(rects);

      /* we need to draw a line from last pixel */

      if (displayMode == NX_SOUNDVIEW_MINMAX && endX < NSMaxX([self frame]))
	endX++;

/* STARTING MAIN CACHE LOOP HERE */

        currStartPoint = startX;
        arrayPointer = 0;

	while (currStartPoint <= endX) {
        
	  int nextCache;
	  int localMax;
	  int leadsOnFrom;

        /* following returns leadsOn == YES iff cacheIndex == -1 && (currStartPoint - 1) is in previous cache */

	  cacheIndex = [dataList findObjectContaining:currStartPoint
				 next:&nextCache leadsOnFrom:&leadsOnFrom];

        if (cacheIndex != -1) {
            int k,numToMove,cachedStart;
            float *maxVals,*minVals;
//			printf("Using cached data %d\n",cacheIndex);
            currentCacheObject = (SndDisplayData *)[(NSMutableArray *)dataList objectAtIndex:cacheIndex];
            numToMove = [currentCacheObject endPixel];
            cachedStart = [currentCacheObject startPixel];
            if (numToMove > endX) numToMove = endX - currStartPoint + 1;
            else numToMove = numToMove - currStartPoint + 1;
            maxVals = [currentCacheObject pixelDataMax];
            minVals = [currentCacheObject pixelDataMin];
//		     printf("reading cache from %d, for %d\n", currStartPoint - cachedStart, numToMove);
            for (k=0;k<numToMove;k++) {
                    cacheMaxArray[currStartPoint + k - startX] = maxVals[k + currStartPoint - cachedStart];
                    cacheMinArray[currStartPoint + k - startX] = minVals[k + currStartPoint - cachedStart];
                    }
            currStartPoint += k;
            continue;
        }
        if (nextCache != -1) {
            localMax = [[(NSMutableArray *)dataList objectAtIndex:nextCache] startPixel] - 1;
            if (localMax > endX) localMax = endX;
        }
        else localMax = endX;

        /* set up first read point in sound data */
        actualBaseF =  (float)currStartPoint * reductionFactor;
        if ((int)actualBaseF != ceil(actualBaseF)) actualBase = ceil(actualBaseF);
        else actualBase = (int)(actualBaseF);
        j = firstOfNext = actualBase; /* just initialise it for now */
        theData = getDataAddresses(actualBase,
                        [sound soundStruct],
                        &m1, 
                        &c1);

        for (i = currStartPoint;i<=localMax;i++) {
            BOOL first=YES;
            thisMax = 0.0;
            thisMin = 0.0;
            if (i * reductionFactor >= sampCount) break;
            skipFactor = 1;
            fONBase = (float)(i+1) * reductionFactor;
            if ((int)fONBase != ceil(fONBase)) firstOfNext = ceil(fONBase);
            else firstOfNext = (int)(fONBase);

            c1 += (actualBase - j); /* have to increment c1 by same amount as j
                                                                        * although we can simply assign j
                                                                        */
            j = actualBase;
            /* need to establish initial values for base and counter here, for fragged sounds */
            while (j < firstOfNext) {
                if (c1 >= m1) theData = getDataAddresses(actualBase,
                                                [sound soundStruct],&m1,&c1);
                if (j < sampCount)
                    theValue = doStereo ? 
                            getSoundValueStereo(theData,type,c1 * chanCount) :
                            getSoundValue(theData, type, c1 * chanCount + whichChannel);
                else theValue = 0;
                if (first) {
                    minNinety = thisMin = theValue;
                    maxNinety = thisMax = theValue;
                    first = NO;
                }
                else {
                    if (theValue < thisMin) {
                        thisMin = theValue;
                        if (optimize) minNinety = thisMin + peakFraction * abs((int)thisMin);
                    }
                    else if (theValue > thisMax) {
                        thisMax = theValue;
                        if (optimize) maxNinety = thisMax - peakFraction * abs((int) thisMax);
                    }
                }
                if (optimize) {
                    direction = (theValue < lastValue);
                    if ((!direction && (theValue > maxNinety))
                            || (direction && (theValue < minNinety))) skipFactor = 1;
                    else skipFactor = optSkip;
                    }
                lastValue = theValue;
                j += skipFactor;
                c1 += skipFactor;
            }
            cacheMaxArray[i-startX] = thisMax;
            cacheMinArray[i-startX] = thisMin;
            actualBase = firstOfNext;
        } /* 'for' loop for creating new cache data */
        /* now do the following:
                    * if we are following on from last cache, append our data to that cache
                    *   otherwise create new cache...
                    * Increase currStartPoint
                    * Continue...
                    */
        if (leadsOnFrom != -1) { /* we have calculated a new region which exactly appends an existing cache */
            SndDisplayData * cacheToExtend = 
                (SndDisplayData *)[(NSMutableArray *)dataList objectAtIndex:leadsOnFrom];
            [cacheToExtend addPixelDataMax:&cacheMaxArray[currStartPoint - startX]
                                       min:&cacheMinArray[currStartPoint - startX]
                                     count:localMax - currStartPoint + 1
                                      from:[cacheToExtend endPixel] + 1];
//	printf("adding to cache: from %d count %d\n", [cacheToExtend endPixel] + 1, localMax - currStartPoint + 1);
        }
        else {
            SndDisplayData *newCache = [[SndDisplayData alloc] init];
            [newCache setPixelDataMax:&cacheMaxArray[currStartPoint - startX]
                                  min:&cacheMinArray[currStartPoint - startX]
                                count:localMax - currStartPoint + 1
                                start:(int)currStartPoint];
            [(NSMutableArray *)dataList addObject:newCache];
            [dataList sort];
//	printf("setting new cache: start %d count %d\n", currStartPoint, localMax - currStartPoint + 1);
        }
        /* now see if we should join up to following cache */
        cacheIndex = [dataList findObjectContaining:localMax + 1 next:&nextCache leadsOnFrom:&leadsOnFrom];
        if (cacheIndex != -1 && leadsOnFrom != -1) {
            [[(NSMutableArray *)dataList objectAtIndex:leadsOnFrom] 
                addDataFrom:[(NSMutableArray *)dataList objectAtIndex:cacheIndex]];
            [(NSMutableArray *)dataList removeObjectAtIndex:cacheIndex];
//	printf("Compacted %d with %d. Now %d caches\n", leadsOnFrom, cacheIndex,[dataList count]);
        }

        currStartPoint = localMax + 1;
                } /* while loop for caching */
#ifdef DO_TIMING
    [t4 reset];
    for (; numTimingPasses ; numTimingPasses--) {
        [t4 enter:PSTIME];
#endif
#ifndef QUARTZ_RENDERING
  #ifdef USE_PS_USER_PATHS
        //:ps:
        arect = newUserPath();
        beginUserPath(arect,NO);

        if (displayMode == NX_SOUNDVIEW_WAVE) {
            float max1 = cacheMaxArray[0] * ampScaler + halfHeight;
            float min1 = cacheMinArray[0] * ampScaler + halfHeight;
            if (endX >= NSWidth([self frame])) endX = NSWidth([self frame]) - 1;
            for (i = startX;i<=endX;i++) {
                float max2 = cacheMaxArray[i + 1 - startX] * ampScaler + halfHeight;
                float min2 = cacheMinArray[i + 1 - startX] * ampScaler + halfHeight;
                UPmoveto(arect, i + 0.5, max1);
                UPlineto(arect, i + 0.5, min1);
                if (i < endX) {/* still one more cached point */
                    if ((min2 <= max1 && min2 >= min1) 			/* if part of the line          */
                        || (max2 >= min1 && max2 <= max1) 		/*    is outside the one before */
                        || (max2 >= max1 && min2 <= min1)) {		/* if both points encompass */
                        max1 = max2; min1 = min2;
                        continue;
                    }
                    /* so we draw line from appropriate end, to start of next line */
                    if (min2 > max1 && max1 != min1) UPmoveto(arect, i+0.5, max1); /*reverse to top if necessary */
                    UPlineto(arect, i+1+0.5, (min2 > max1) ? min2 : max2);
                    max1 = max2; min1 = min2;
                }
            }
        }
        else {
            UPmoveto(arect,startX+0.5, cacheMaxArray[0] * ampScaler + halfHeight);
            for (i = startX;i<endX;i++) {
                UPlineto(arect, i+0.5, cacheMaxArray[i - startX]* ampScaler + halfHeight);
            }
            UPmoveto(arect, startX+0.5, cacheMinArray[0] * ampScaler + halfHeight);
            for (i = startX;i<endX;i++) {
                UPlineto(arect, i+0.5, cacheMinArray[i - startX] * ampScaler + halfHeight);
            }
        }
        endUserPath(arect,dps_ustroke);
        [foregroundColour set];
        sendUserPath(arect);
        freeUserPath(arect);
  #else
        PSnewpath();
        if (displayMode == NX_SOUNDVIEW_WAVE) {
            float max1 = cacheMaxArray[0] * ampScaler + halfHeight;
            float min1 = cacheMinArray[0] * ampScaler + halfHeight;
            if (endX >= NSWidth([self frame])) endX = NSWidth([self frame]) - 1;
            for (i = startX;i<endX;i++) {
                float max2 = cacheMaxArray[i + 1 - startX] * ampScaler + halfHeight;
                float min2 = cacheMinArray[i + 1 - startX] * ampScaler + halfHeight;
                PSmoveto(i+0.5, max1);
                PSlineto(i+0.5, min1);
                if (i < endX) {/* still one more cached point */
                    if ((min2 <= max1 && min2 >= min1) 			/* if part of the line          */
                        || (max2 >= min1 && max2 <= max1) 		/*    is outside the one before */
                        || (max2 >= max1 && min2 <= min1)) {		/* if both points encompass */
                        max1 = max2; min1 = min2;
                        continue;
                    }
                    /* so we draw line from appropriate end, to start of next line */
                    if (min2 > max1 && max1 != min1) PSmoveto(i+0.5, max1); /*reverse to top if necessary */
                    PSlineto(i+1+0.5, (min2 > max1) ? min2 : max2);
                    max1 = max2; min1 = min2;
                }
            }
        }
        else {
            PSmoveto(startX+0.5, cacheMaxArray[0] * ampScaler + halfHeight);
            for (i = startX;i<endX;i++) {
                PSlineto(i+0.5, cacheMaxArray[i - startX]* ampScaler + halfHeight);
            }
            PSmoveto(startX+0.5, cacheMinArray[0] * ampScaler + halfHeight);
            for (i = startX;i<endX;i++) {
                PSlineto(i+0.5, cacheMinArray[i - startX]* ampScaler + halfHeight);
            }
        }
        [foregroundColour set];
        PSstroke();
  #endif
#else
//QUARTZ_RENDERING

    CGContextBeginPath(ctx);

    if (displayMode == NX_SOUNDVIEW_WAVE) {

        float max1 = cacheMaxArray[0] * ampScaler + halfHeight;
        float min1 = cacheMinArray[0] * ampScaler + halfHeight;

        if (endX >= NSWidth([self frame]))
	  endX = NSWidth([self frame]) - 1;

        for (i = startX;i<endX;i++) {

            float max2 = cacheMaxArray[i + 1 - startX] *
			ampScaler + halfHeight;

            float min2 = cacheMinArray[i + 1 - startX] *
			ampScaler + halfHeight;

            CGContextMoveToPoint(ctx, i+0.5, max1);
            CGContextAddLineToPoint(ctx, i+0.5, min1);

	    /* still one more cached point */

            if (i < endX) {

/* if part of the line is outside the one before if both points encompass */

                if ((min2 <= max1 && min2 >= min1) 			
                    || (max2 >= min1 && max2 <= max1) 		
                    || (max2 >= max1 && min2 <= min1)) {		
                    max1 = max2; min1 = min2;
                    continue;
                }

/* so we draw line from appropriate end, to start of next line */

                if (min2 > max1 && max1 != min1) {

		  /*reverse to top if necessary */

		  CGContextMoveToPoint(ctx, i+0.5, max1);
		}

                CGContextAddLineToPoint(ctx, i + 1 + 0.5,
					(min2 > max1) ? min2 : max2);

                max1 = max2; min1 = min2;
            }
        }
    }

    else {
      CGContextMoveToPoint(ctx, startX + 0.5,
			cacheMaxArray[0] * ampScaler + halfHeight);

        for (i = startX;i<endX;i++) {
	  CGContextAddLineToPoint(ctx, i + 0.5,
			cacheMaxArray[i - startX]* ampScaler + halfHeight);
        }

        CGContextMoveToPoint(ctx, startX + 0.5,
			     cacheMinArray[0] * ampScaler + halfHeight);

        for (i = startX;i<endX;i++) {

            CGContextAddLineToPoint(ctx, i + 0.5,
			cacheMinArray[i - startX]* ampScaler + halfHeight);
        }
    }

    [foregroundColour set];

    CGContextStrokePath(ctx);

#endif

#ifdef DO_TIMING

    [t4 leave];
    }
        printf("Timing: walltime %g apptime %g PStime %g\n",[t4 cumWallTime],[t4 cumAppTime],[t4 cumPSTime]);

#endif

    }

    else { /* I don't bother caching here, as it's so quick to grab actual data */
        int myLast;
        float theValue;

	/* first sample */

        i = (int)((float)NSMinX(rects) * (float)reductionFactor);

        if (i > 0)
	  i--;

        theData = getDataAddresses(i,
                        [sound soundStruct],
                        &m1, 
                        &c1);

	/* last sample */
	
        myLast = (int)((float)(NSMaxX(rects)) * (float)reductionFactor) + 1;

        if (myLast >= sampCount)
	  myLast = sampCount - 1;

        theValue = doStereo ? 
	  getSoundValueStereo(theData,type, c1 * chanCount) :
	  getSoundValue(theData, type, c1 * chanCount + whichChannel);

        theValue = theValue * ampScaler + halfHeight;

        /* establish initial point */

        j = (float)((float)i / (float)reductionFactor);

#ifndef QUARTZ_RENDERING

        PSmoveto((int)j + 0.5, theValue);

#else

        CGContextMoveToPoint(ctx, (int) j + 0.5, theValue);

#endif

        while (i <= myLast) {

	  if (c1 >= m1)
	    theData = getDataAddresses(i, [sound soundStruct],
				       &m1,&c1);
	  theValue = doStereo ? 
                getSoundValueStereo(theData,type,c1 * chanCount) :
                getSoundValue(theData, type, c1 * chanCount + whichChannel);

	  theValue = theValue * ampScaler + halfHeight;		

	  j = (float)((float)i / (float)reductionFactor);

#ifndef QUARTZ_RENDERING

	  PSlineto((int)j+0.5, theValue);

	  if (svFlags.drawsCrosses && reductionFactor <= CROSSTHRESH) {

	    PSrmoveto(0,3);
	    PSrlineto(0,-6);
	    PSrmoveto(0,3);
	  }
#else
	  CGContextAddLineToPoint(ctx, (int) j + 0.5, theValue);

	  if (svFlags.drawsCrosses && reductionFactor <= CROSSTHRESH) {
	    
	    CGContextMoveToPoint(ctx, (int) j + 0.5, theValue+4);
	    CGContextAddLineToPoint(ctx, (int) j + 0.5, theValue-4);
	    CGContextMoveToPoint(ctx, (int) j + 0.5, theValue);
	  }

#endif
	  i++;
	  c1++;
        }

        [foregroundColour set];

#ifndef QUARTZ_RENDERING

        PSstroke();

#else

        CGContextStrokePath(ctx);

#endif

    }

    free(cacheMaxArray);
    free(cacheMinArray);

    if (NSWidth(selectionRect) < 0.1) {

      /*
      [[self window] disableFlushWindow];
      [self showCursor];
      [[self window] enableFlushWindow];
      */

 /* zero compare not good idea? */
      return;
    }

    /* draw selection rect */

    scaledSelRect = selectionRect;
    scaledSelRect.origin.x = (int)((float)NSMinX(selectionRect) /
			   (float)reductionFactor);

    scaledSelRect.size.width = (int)((NSMaxX(selectionRect) - 1) /
			     reductionFactor) - NSMinX(scaledSelRect) + 1;

    if (!((NSMinX(scaledSelRect) >= NSMinX(rects) &&
	   NSMinX(scaledSelRect) <= NSMaxX(rects)) ||
	  (NSMaxX(scaledSelRect) >= NSMinX(rects) && 
	   NSMaxX(scaledSelRect) <= NSMaxX(rects)) ||
        (NSMinX(scaledSelRect) <= NSMinX(rects) &&
	 NSMaxX(scaledSelRect) >= NSMaxX(rects)) ) || noSelectionDraw)
      return;

    else {

      NSRect highlightRect = [self bounds];

      /*
    		fprintf(stderr,"HIGHLIGHTing scaled sel rect... %g to %g\n",
			NX_X(&scaledSelRect),NX_MAXX(&scaledSelRect));

		fprintf(stderr,"HIGHLIGHTing rects... %g to %g\n",
			NX_X(rects),NX_MAXX(rects));
      */

      highlightRect.origin.x = (int)((NSMinX(scaledSelRect) >= NSMinX(rects)) ?
			     NSMinX(scaledSelRect) : NSMinX(rects));

      highlightRect.size.width = (int)(((NSMaxX(scaledSelRect) <=
			NSMaxX(rects)) ? NSMaxX(scaledSelRect) :
			NSMaxX(rects) )   - NSMinX(highlightRect) + 0.1);

      [selectionColour set];

      NSRectFillUsingOperation(highlightRect, NSCompositeDestinationOver);

      //      NSHighlightRect(highlightRect);

		printf("HIGHLIGHT %g to %g\n",NSMinX(highlightRect),
			NSMaxX(highlightRect));
    }

    return;
}

- (void)setBackgroundColor:(NSColor *)color
{
    [backgroundColour release];
    backgroundColour = [color copy];
    [self setNeedsDisplay:YES];
}
- (NSColor *)backgroundColor;
{
    return backgroundColour;
}

- (void) setSelectionColor : (NSColor *) color
{
    [selectionColour release];
    selectionColour = [color copy];

    [self setNeedsDisplay:YES];
}

- (NSColor *) selectionColor
{
    return selectionColour;
}

- (void)setForegroundColor:(NSColor *)color
{
    [foregroundColour release];
    foregroundColour = [color copy];
    [self setNeedsDisplay:YES];
}
- (NSColor *)foregroundColor
{
    return foregroundColour;
}

- (void)dealloc
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
//	printf("Freeing SndView\n");
    [self tellDelegate:@selector(willFree:)];

    /*
    [self hideCursor];
    */

    if ((_lastCopyCount == [pboard changeCount]) && notProvidedData) {
    /* i.e. we were the last ones to put something on the pasteboard, but
          * have not provided it yet
          */
        [self pasteboard:pboard provideDataForType:NXSoundPboardType];
    }
    [_pasteboardSound release];
    [_scratchSound release];
    [backgroundColour release];
    [foregroundColour release];
    if (recordingSound) SndFree(recordingSound);/* just in case */
    if (dataList) {
        [(NSMutableArray *)dataList removeAllObjects];
        [(NSMutableArray *)dataList release];
    }
    [super dealloc];
    return;
}
- getSelection:(int *)firstSample size:(int *)sampleCount
{
    *firstSample = (int)selectionRect.origin.x;
    *sampleCount = (int)selectionRect.size.width;
    return self;
}
- (void)setSelection:(int)firstSample size:(int)sampleCount
{
    NSRect scaledSelection = selectionRect;


    //    [self hideCursor];

    scaledSelection.origin.x  = scaledSelection.origin.x / reductionFactor - 1;
    scaledSelection.size.width = scaledSelection.size.width / reductionFactor + 2;
    scaledSelection.origin.y = 0;
    scaledSelection.size.height = [self bounds].size.height;
    scaledSelection = NSIntersectionRect (scaledSelection,[self visibleRect]);
    if (!NSEqualRects(scaledSelection,NSZeroRect)) [self setNeedsDisplayInRect:scaledSelection];
    
    selectionRect.origin.x = firstSample;
    selectionRect.size.width = sampleCount;
    
    scaledSelection = selectionRect;
    scaledSelection.origin.x  = scaledSelection.origin.x / reductionFactor - 1;
    scaledSelection.size.width = scaledSelection.size.width / reductionFactor + 2;
    scaledSelection.origin.y = 0;
    scaledSelection.size.height = [self bounds].size.height;
    scaledSelection = NSIntersectionRect (scaledSelection,[self visibleRect]);
    if (!NSEqualRects(scaledSelection,NSZeroRect)) [self setNeedsDisplayInRect:scaledSelection];
    return;
}

- initWithFrame:(NSRect)frameRect
{
    [self initVars];
    return [super initWithFrame:frameRect];
}
- (BOOL)isAutoScale
{
    return svFlags.autoscale;
}
- (BOOL)isBezeled
{
    return svFlags.bezeled;
}
- (BOOL)isContinuous
{
    return svFlags.continuous;
}
- (BOOL)isEditable
{
    return !(svFlags.notEditable);
}
- (BOOL)isEnabled
{
    return !(svFlags.disabled);
}
- (BOOL)isOptimizedForSpeed
{
    return !(svFlags.notOptimizedForSpeed);
}
- (BOOL)isPlayable
{
    if (!sound) return NO;
    return YES;/* hmmm. What is required here? */
}
- (BOOL)drawsCrosses
{
    return svFlags.drawsCrosses;
}
- (int)getOptThreshold
{
    return optThreshold;
}
- (int)getOptSkip
{
    return optSkip;
}
- (int)getStereoMode
{
    return stereoMode;
}
- (float)getPeakFraction
{
    return peakFraction;
}
- (float)getDefaultRecordTime
{
    return defaultRecordSeconds;
}

- (void)mouseDown:(NSEvent *)theEvent 
{
    NSPoint		mouseDownLocation, /*mouseUpLocation,*/ mouseLocation,timerMouseLocation;
    NSRect		visibleRect, adjSelRect, lastRect, lastAdjRect;
    NSPoint		selPoint;
    float		oldx=0, dx=0;
    //    float		frameDiff, lastFrameDiff;
    NSEvent *event;
    BOOL timer = NO;
    BOOL useTimerLocation = NO;
    BOOL		scrolled = NO;
    int 		hilStart=-1,hilEnd=-1; /* which pixels are currently highlighted */
    int			realStart = ((float)NSMinX(selectionRect) + .1);
    int			realEnd = ((float)NSMaxX(selectionRect) + .1) - 1;
    BOOL		direction;
    BOOL		firstDragEvent = YES;
    
	
	/* in order to preserve the start and end points of a selection when
	 * only the 'other' end is moved, we keep the original values here.
	 * This is important because the original endpoints may not lie on
	 * pixel boundaries when reductionFactor > 1.
	 * When we are about to change the endpoints, we check to see if the
	 * 'changed' start or end has moved away from the original value. If so,
	 * we discard the remembered value. If not, we keep it.
	 */
	
  /* if the Control key isn't down, show normal behavior */
//    if (!(theEvent->flags & NX_CONTROLMASK)) {
//	return [super mouseDown:theEvent];
//    }

    //    [self hideCursor];

    [[self window] makeFirstResponder:self];

/* so nothing can be highlighted etc if there is no sound */

    if (!sound)
      return;

    if ( [sound sampleCount] <= 0 )
      return;

    /* hmmmmm ..... */

    /* invalidate previous selection rect */

    if (selCacheRect.size.width > 0.) {
      [self setNeedsDisplayInRect:selCacheRect];
    }

    if ([theEvent clickCount] == 3) {
            [self selectAll:self];
            return;
    }

    [self lockFocus];

  /* we're now interested in mouse dragged events */

    [[self window] setAcceptsMouseMovedEvents:YES];

    
    mouseDownLocation = [theEvent locationInWindow];
    mouseDownLocation = [self convertPoint:mouseDownLocation fromView:nil];
    mouseLocation.x--;
    oldx = mouseDownLocation.x;
//	printf("Converted mouse location - 1 = %g\n",oldx);
    adjSelRect = selectionRect;
    adjSelRect.origin.y = NSMinY([self bounds]);
    adjSelRect.size.height = NSHeight([self bounds]);

    if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
        realStart = realEnd = -1; /* we don't need to remember the old selection */
        adjSelRect.origin.x = (int)((float)NSMinX(adjSelRect) / (float)reductionFactor);
        adjSelRect.size.width = ((int)((float)NSMaxX(selectionRect) - 0.9) /
                (float)reductionFactor);

        if ((int)adjSelRect.size.width == ceil(adjSelRect.size.width))
                adjSelRect.size.width += 1;
        else adjSelRect.size.width = ceil(adjSelRect.size.width);
        adjSelRect.size.width -= NSMinX(adjSelRect);

	/* HMMMMM .... */

	/* to zap current selection */

        if (NSWidth(selectionRect) > 0.1) {
	  //	  NSHighlightRect(adjSelRect);
	  //	  [self setNeedsDisplay:YES];
	  /* remember our rect for future erasure */
	  selCacheRect = adjSelRect;
	  [selectionColour set];
	  // NSRectFillUsingOperation(adjSelRect, NSCompositeDestinationOver);
          //			printf("zapping %g to %g\n",NX_X(&adjSelRect),NX_MAXX(&adjSelRect));
	  selectionRect = NSMakeRect(mouseDownLocation.x, 0.0, 0.0, 0.0);
	}
    }

    /* if zero selection, (insertion point) what do we do? */

    else {
      if (NSWidth(selectionRect) > 0.1) {

	hilStart = ((int)((float)NSMinX(selectionRect) + 0.01) /
		    reductionFactor);
	hilEnd = (((int)((float)NSMaxX(selectionRect) + 0.01) - 1) /
		  reductionFactor);
	if (oldx < (hilStart + hilEnd) / 2)
	  oldx = hilStart;
	else
	  oldx = hilEnd + 1;
//			printf("extending selection\n");
      }
      else {
	if (oldx < ((float)NSMinX(selectionRect) / (float)reductionFactor)) {
            oldx = (int)((float)NSMinX(selectionRect) /
                        (float)reductionFactor) + 1;
        } else {
            oldx = (int)((float)NSMinX(selectionRect) / (float)reductionFactor);
        }

	//			printf("zero selection, extending\n");

      }
    }

    event = theEvent;

/***************************************/
/******** START MAIN MOUSE LOOP ********/
/***************************************/
    while ([event type] != NSLeftMouseUp) {
        visibleRect = [self visibleRect];
        if (!useTimerLocation)
            mouseLocation = [event locationInWindow];
        else
            mouseLocation = timerMouseLocation;
        mouseLocation = [self convertPoint:mouseLocation fromView:nil];
        selPoint = mouseLocation;

/* selFrame needs to be 'correct' for scrolling but actual selection is -1 */
        mouseLocation.x--;

        if (mouseLocation.x < -1) {
            mouseLocation.x = -1;
            selPoint.x = 0;
        }
        if (selPoint.x >= NSMaxX([self bounds])) {
            selPoint.x = (int)NSMaxX([self bounds]);
            mouseLocation.x = selPoint.x - 1;
    //			printf("max'd mouseLocation: %g\n",mouseLocation.x);
        }

        /* make sure the selection will be entirely visible */
        if (!NSPointInRect(selPoint , visibleRect) &&
                (selPoint.x != NSMaxX(visibleRect))) {
            [[self window] disableFlushWindow];
            [self scrollPointToVisible:selPoint];
            [[self window] enableFlushWindow];
            /*
              printf("scrolled to: %g %g\n",selPoint.x, selPoint.y);
              printf("visibleRect: %g %g %g %g\n",NX_X(&visibleRect),
                    NX_Y(&visibleRect), NX_WIDTH(&visibleRect),
                    NX_HEIGHT(&visibleRect));
            */
            /* note that we scrolled and start generating timer events for
               autoscrolling */
            scrolled = YES;
            startTimer(timer);
        }
        else { /* no scrolling, so stop any timer */
            stopTimer(timer);
        }

        dx = mouseLocation.x - oldx + 1;
        direction = (dx > 0);
        adjSelRect.origin.x = mouseLocation.x - dx + 1;
      
        if (dx < 0) {
            dx = -dx;
            adjSelRect.origin.x -= dx;
        }
        adjSelRect.size.width = dx;
      
        /* HMMMMMM ...... */
        if (dx) {   
	    /*
	    [selectionColour set];
	    NSRectFillUsingOperation(adjSelRect, NSCompositeDestinationOver);
	    */

	    //	      NSHighlightRect(adjSelRect);
	    //	      [self setNeedsDisplay:YES];

	    /* adjust the size of selCacheRect to be the size of the union
	       of selCacheRect and adjSelRect */

	    //	      selCacheRect = NSUnionRect( selCacheRect, adjSelRect);
        }

        if (NSMinX(adjSelRect) < 0) {
            adjSelRect.size.width += NSMinX(adjSelRect);
            adjSelRect.origin.x = 0;
        }

        if (dx) {
            if (hilStart == -1) {
                hilStart = NSMinX(adjSelRect);  //				printf("(0)");
                hilEnd = (float)NSMaxX(adjSelRect) - 1.0;
            }
	    else if (NSMinX(adjSelRect) < hilStart) {/* new start point. need to adjust end? */
                /* if endpoint of selection is within current sel, we must have
                   backtracked right over the current selection, highlighting a new portion,
                   but unhighlighting the latter parts of the old selection.
                 */
    //				printf("(1)");
                if (NSMaxX(adjSelRect) - 1 >= hilStart) {
                    hilEnd = hilStart - 1;
                }
                hilStart = NSMinX(adjSelRect);
                
            } else if (NSMaxX(adjSelRect) > hilEnd + 1) {
                /* tack on new addition to selection */
                if (NSMinX(adjSelRect) <= hilEnd)
                    hilStart = hilEnd + 1;
                hilEnd = NSMaxX(adjSelRect) -1;//					printf("(2)");
                
            } else if (NSMinX(adjSelRect) <= hilEnd &&
                    NSMinX(adjSelRect) >= hilStart) {
                /* we have shortened selection, by backtracking from end */
                if (!direction) {
                    hilEnd = NSMinX(adjSelRect) - 1;  //				printf("(3)");
                }
                /* shorten selection by forward tracking from start */
                else { 
                    hilStart = NSMaxX(adjSelRect);  //					printf("(4)");
                }
                /* empty selection */
                if (hilEnd < hilStart) {
                    hilStart = hilEnd = -1;  //						printf("(5)");
                }
            }
	      
    //				else printf("(6)");
            if (hilStart != -1) {  //							printf("(7)");
                selectionRect.origin.x = ceil((float)hilStart * (float)reductionFactor);
                selectionRect.size.width = (float)reductionFactor * (float)(hilEnd + 1);

                if ((int)selectionRect.size.width == 
                    ceil(selectionRect.size.width)) {
                    selectionRect.size.width -= 1;
                }

                else {
                    selectionRect.size.width = (int)selectionRect.size.width;
                }
                selectionRect.size.width -= (ceil(reductionFactor * hilStart) - 1);
            }

            else {//				printf("(8)");
                selectionRect.origin.x = ceil((float)NSMinX(adjSelRect) * (float)reductionFactor);
                selectionRect.size.width = 0;
            }

            /* now check to see if we need to adjust to original values.
	     * First, check to see if initial point has changed. If not, set
	     * original start, and adjust length. If so, discard 'original' point
	     */
    //				printf("rs %d re %d ",realStart,realEnd);

            if ((realStart != -1) && hilStart == (int)(realStart / reductionFactor)) {
    //				printf("(9)");
                selectionRect.size.width = ceil((hilEnd + 1) * reductionFactor) - realStart;
                selectionRect.origin.x = realStart;
            }
            else realStart = -1;
            if ((realEnd != -1) && hilEnd == (int)(realEnd / reductionFactor)) {
    //				printf("(a)");
                selectionRect.size.width = (int)(realEnd - NSMinX(selectionRect)) + 1;
	    }
            else realEnd = -1;

            /* Finally, adjust selection width down to sound size, if it ends on last pixel.
             * When the num of pixels is not a direct multiple of redfact, the calculation
             * for selectionRect, based on the last pixel highlighted, will come out with
             * a figure slightly too high.
             */

            if ((int)((float)NSMaxX(selectionRect) + 0.1) > [sound sampleCount]) {
                selectionRect.size.width = [sound sampleCount] - NSMinX(selectionRect);
            }
    //      printf("selection changed to %g, %g\n",NX_X(&selectionRect),NX_WIDTH(&selectionRect));
            if (svFlags.continuous) {
                [self tellDelegate:@selector(selectionChanged:)];
            }
        }

    //  printf("adjselrect start,end %g %g, dx %g, hs %d he %d oldx1 %g ",
    //      NX_X(&adjSelRect), NX_MAXX(&adjSelRect), dx, hilStart, hilEnd, oldx);

        [selectionColour set];
        NSRectFillUsingOperation(adjSelRect, NSCompositeDestinationOver);
	      //	      NSHighlightRect(adjSelRect);
	      //	      [self setNeedsDisplay:YES];
        /* adjust the size of selCacheRect to be the size of the union
           of selCacheRect and adjSelRect */
        selCacheRect = NSUnionRect( selCacheRect, adjSelRect);

        /* if we have backtracked, invalidate rects that have been selected
           during this drag */
        if ( !firstDragEvent &&
            selectionRect.size.width < lastRect.size.width ) {
            NSRect	selectDiff;

            /*
            fprintf(stderr,"selectionRect:	%5.f:%5.f	%5.f,%5.f\n",
                    (selectionRect.origin.x), (selectionRect.origin.y),
                    (selectionRect.size.width), (selectionRect.size.height));
    
            fprintf(stderr,"adjSelRect:	%5.f:%5.f	%5.f,%5.f\n",
                    adjSelRect.origin.x, adjSelRect.origin.y,
                    adjSelRect.size.width, adjSelRect.size.height);
    
            fprintf(stderr,"lastRect:	%5.f:%5.f	%5.f,%5.f\n",
                    lastRect.origin.x, lastRect.origin.y,
                    lastRect.size.width, lastRect.size.height);
    
            fprintf(stderr,"lastAdjRect:	%5.f:%5.f	%5.f,%5.f\n",
                    lastAdjRect.origin.x, lastAdjRect.origin.y,
                    lastAdjRect.size.width, lastAdjRect.size.height);
            */

            if ( selectionRect.origin.x == lastRect.origin.x ) {//	  fprintf(stderr,"above\n");
                selectDiff.size.width = (lastAdjRect.origin.x -
                                adjSelRect.origin.x) + 
                                lastAdjRect.size.width + 1;

                selectDiff.size.height = adjSelRect.size.height;
                selectDiff.origin.x = adjSelRect.origin.x;
                selectDiff.origin.y = adjSelRect.origin.y;
            }
            else {//	  fprintf(stderr,"below\n");
                selectDiff.size.width = (adjSelRect.origin.x - 
                                lastAdjRect.origin.x) + 2;
                selectDiff.size.height = adjSelRect.size.height;
                selectDiff.origin.x = lastAdjRect.origin.x - 1;
                selectDiff.origin.y = adjSelRect.origin.y;
            }
	/*
            fprintf(stderr,"selectDiff:	%5.f:%5.f	%5.f,%5.f\n\n",
		selectDiff.origin.x, selectDiff.origin.y,
		selectDiff.size.width, selectDiff.size.height);
	*/
            selectDiff = NSIntersectionRect( selectDiff, [self bounds] );
            noSelectionDraw=YES;
            [self setNeedsDisplayInRect:selectDiff];
            noSelectionDraw=NO;
        }

        /* now show what we've done */
        [[self window] flushWindow];
        /*
          if we autoscrolled, flush any lingering window server events to make
          the scrolling smooth
        */
        if (scrolled) {
	// PSWait();
            scrolled = NO;
        }
      
        /* save the current mouse location, just in case we need it again */
        oldx = mouseLocation.x + 1;//		printf(" oldx2: %g\n",oldx);
        lastRect = selectionRect;
        lastAdjRect = adjSelRect;
        firstDragEvent = NO;

        if (!useTimerLocation) {
            mouseLocation = [event locationInWindow];
        }
        else {
            mouseLocation = timerMouseLocation;
        }

        if (![[self window] nextEventMatchingMask:MOVE_MASK
                                        untilDate:[NSDate date]
                                           inMode:NSEventTrackingRunLoopMode
                                          dequeue:NO]) {

/* no mouseMoved or mouseUp event immediately available, so take mouseMoved,
   mouseUp, or timer */

            event = [[self window] nextEventMatchingMask:MOVE_MASK|NSPeriodicMask];
        }

        else { /* get the mouseMoved or mouseUp event in the queue */
            event = [[self window] nextEventMatchingMask:MOVE_MASK];
        }

        /* if a timer event, mouse location isn't valid, so we'll set it */
        if ([event type] == NSPeriodic) {
            timerMouseLocation = mouseLocation;
            useTimerLocation = YES;
        }
        else {
            useTimerLocation = NO;
        }
    } /* while ([event type] != NSLeftMouseUp) */

/*************************************/
/******** END MAIN MOUSE LOOP ********/
/*************************************/
    
    /* mouseUp, so stop any timer and unlock focus */
    stopTimer(timer);
    [self unlockFocus];

    /* if we weren't left with a selection,
     * stick insertion point in new place
     */
    if (NSWidth(selectionRect) < 0.1) {  
        selectionRect.origin.x = ceil(mouseDownLocation.x * (float)reductionFactor);
        selectionRect.size.width = 0;
    }
//	printf("FINAL SELECTION %g, %g\n",NX_X(&selectionRect),NX_WIDTH(&selectionRect));
    [[self window] setAcceptsMouseMovedEvents:NO];
    if (reductionFactor < 1) [self setNeedsDisplay:YES]; /* to align to sample boundaries! */

    //    if (NSWidth(selectionRect) < 0.1)  [self showCursor];
    [self tellDelegate:@selector(selectionChanged:)];
}

- (void) pasteboard:(NSPasteboard *)thePasteboard provideDataForType:(NSString *)pboardType
{
	BOOL ret;

	/*
	printf("provide data (SndView): %p type: %s (%s)\n",
	thePasteboard, pboardType, NXSoundPboardType);
	printf("length %d\n",[sound sampleCount]);
	*/

	if (!([NXSoundPboardType isEqualToString:pboardType] ||
	      [NXSoundPboardTypeOld isEqualToString:pboardType]))
	  return;

	if (!_pasteboardSound)
	  printf("nil sound for paste\n");

	[_pasteboardSound compactSamples];

	/*
	printf("Pasting size %d %d\n",
		[_pasteboardSound dataSize],
		[_pasteboardSound soundStructSize]);
	*/

	/* sound data and full header must be sent to the pasteboard here */

        ret = [thePasteboard setData:
		[NSData dataWithBytes:(char *)[_pasteboardSound soundStruct]
			length:(int)[_pasteboardSound soundStructSize]]
			forType:pboardType];
	
	notProvidedData = NO;

	if (!ret)
	  printf("Sound paste error\n");
}

- (void)play:sender
{
    int beginSample = (int)((float)NSMinX(selectionRect) + 0.1);
    int sampleCount = (int)((float)NSWidth(selectionRect) + 0.1);

    [self stop:self];
    [sound setDelegate:self];

    if (NSWidth(selectionRect) < 0.1)
        [sound play:self];    
    else
        [sound play:self beginSample:beginSample sampleCount:sampleCount];
}

- (void)pause:sender
{
    int stat;
    if (_scratchSound) {
        stat = [_scratchSound status];
        if (stat == SND_SoundPlaying || stat == SND_SoundPlayingPending)
                [_scratchSound pause];
    }
    if (sound) {
      [sound pause];
    }
    return;
}

- (void)resume:sender
{
    int stat;
    if (_scratchSound)  {
        stat = [_scratchSound status];
        if (stat == SND_SoundPlayingPaused)
            [_scratchSound resume];
    }
    if (sound) {
      [sound resume];
    }
    return;
}

int startRecord(SndSoundStruct *sound, int tag, int err)
{
    id theObj = (id)*(id *)sound->info;
//  printf("startRecord %p\n", theObj);
    [(SndView *)theObj willRecord:theObj];
    return 1;
}

int endRecord(SndSoundStruct *sound, int tag, int err)
{
    id theObj = (id)*(id *)sound->info;
//  printf("endRecord %p\n", theObj);
    [(SndView *)theObj didRecord:theObj];
    return 1;
}

- (void)record:sender
{
#ifdef NEXT_RECORDING_ENABLED
    int ds=0,df=0,cc=0;
	double sr=0;
	float hi=0.0,lo=0.0;
	float *rates;
	int *encodings;
	unsigned int numEncodings;
	unsigned int numRates;
	int i;
	unsigned int ccLimit;
	/*
	 * NeXT hardware output: Allowable encoding: NX_SoundStreamDataEncoding_Linear16 (600)
	 * 			 44100 or 22050 acceptable rates
	 *			 Max number of channels: 2
	 *			 Accepts continuous sampling rate: NO
	 *
	 *		input:	 Input source: Microphone (standard)
	 *			 Accepts continuous sampling rate: NO
	 *			 Allowable rate: 8012
	 *			 Max number of channels: 1
	 *			 Allowable encoding: NX_SoundStreamDataEncoding_Mulaw8 (602)
	 *
	 * SBSoundMIDI driver input:	Input source: LineIn
	 *				Accepts continuous sampling rate: YES
	 *				Continuous rates allowed from 4000 to 44100
	 *				Max number of channels: 2
	 *				Allowable encoding: 600	(NX_SoundStreamDataEncoding_Linear16)
	 *		output:		Accepts continuous sampling rate: YES
	 *				Continuous rates allowed from 4000 to 44100
	 *				Max number of channels: 2
	 *				Allowable encoding: 600
	 *
	 */
	NXSoundIn *theSoundIn = [[NXSoundIn alloc] init];
	BOOL cr = [theSoundIn acceptsContinuousStreamSamplingRates];
	
#ifdef DISPLAY_SOUNDDEVICE_INFO
	NXSoundParameters *theParameters = [theSoundIn parameters];
	int theDevice = [theParameters
		intValueForParameter:NX_SoundDeviceAnalogInputSource];

	if (theDevice == NX_SoundDeviceAnalogInputSource_Microphone)
		printf("Input source: Microphone\n");
	else printf("Input source: LineIn\n");
	printf("Accepts continuous sampling rate: %s\n", cr ? "YES" : "NO");
#endif
	if (!cr) {
		[theSoundIn getStreamSamplingRates:(const float **)&rates
			count:(unsigned int *)&numRates];
#ifdef DISPLAY_SOUNDDEVICE_INFO
		for (i = 0; i < numRates; i++) {
			printf("Allowable rate: %g\n",rates[i]);
		}
#endif
	}
	else {
		[theSoundIn getStreamSamplingRatesLow:(float *)&lo
			high:(float *)&hi];
#ifdef DISPLAY_SOUNDDEVICE_INFO
		printf("Continuous rates allowed from %g to %g\n",lo,hi);
#endif
	}
	ccLimit = [theSoundIn streamChannelCountLimit];
#ifdef DISPLAY_SOUNDDEVICE_INFO
	printf("Max number of channels: %d\n",ccLimit);
#endif
	[theSoundIn getStreamDataEncodings:
		(const NXSoundParameterTag **)&encodings
		count:(unsigned int *)&numEncodings];
#ifdef DISPLAY_SOUNDDEVICE_INFO
	for (i = 0; i < numEncodings; i++) {
		printf("Allowable encoding: %d\n", encodings[i]);
	}
#endif
	/*
	 NX_SoundDeviceAnalogInputSource_Microphone
	 NX_SoundDeviceAnalogInputSource_LineIn 
	 */
	
	if (sound) {
		BOOL possible = YES,formatPossible = NO;
		df = [sound dataFormat];
		cc = [sound channelCount];
		sr = [sound samplingRate];
		
		if (cc > ccLimit) cc = ccLimit; /* adjust to number of channels available*/
		if (cr) {			/* continuous rates -- is current rate supported? */
			if (sr < lo || sr > hi) sr = hi; /* we'll convert later */
		}
		else {		/* oops, we need to conform to exact rate! (esp. NeXT codec) */
			possible = NO;
			for (i = 0; i < numRates;i++) {
				if (rates[i] == sr) possible = YES;
			}
			/* if we didn't find one that matches our rate, we take highest
			 * and convert later
			 */
			if (!possible && numRates) {
				sr = rates[numRates-1];
				possible = YES;
			}
		}
		for (i = 0; i < numEncodings;i++) {
			int anEncoding = encodings[i];
			if (anEncoding == NX_SoundStreamDataEncoding_Mulaw8 &&
				df == SND_FORMAT_MULAW_8) formatPossible = YES;
			else if (anEncoding == NX_SoundStreamDataEncoding_Linear8 &&
				df == SND_FORMAT_LINEAR_8) formatPossible = YES;
			else if (anEncoding == NX_SoundStreamDataEncoding_Linear16 &&
				df == SND_FORMAT_LINEAR_16) formatPossible = YES;
		}
		if (!formatPossible && numEncodings) { /* if our encoding not there, take 
							* best encoding hardware supports
							* and convert later
							*/
			formatPossible = YES;
			df = encodings[numEncodings - 1];
			if (df == NX_SoundStreamDataEncoding_Mulaw8) df = SND_FORMAT_MULAW_8;
			else if (df == NX_SoundStreamDataEncoding_Linear8) df = SND_FORMAT_LINEAR_8;
			else if (df == NX_SoundStreamDataEncoding_Linear16) df = SND_FORMAT_LINEAR_16;
			else formatPossible = NO;
		}
		if (!possible || !formatPossible) {
			printf("recording format impossible\n");
			[theSoundIn release];
			return;
		}
		ds = (float)sr * (float)cc * (float)(df == SND_FORMAT_LINEAR_16 ? 2.0 : 1.0) *
			(float)defaultRecordSeconds;
	}
	else {
		df = defaultRecordFormat;
		cc = defaultRecordChannelCount;
		sr = defaultRecordSampleRate;
		ds = (float)sr * (float)cc * (float)(df == SND_FORMAT_LINEAR_16 ? 2.0 : 1.0) *
			(float)defaultRecordSeconds;
	}

	[theSoundIn release];// this frees the parameters too
	
	[self stop:self];

    if (recordingSound) SndFree(recordingSound);/* just in case */
    SndAlloc(&recordingSound,ds,df,sr,cc,4);
//	printf("ds %d df %d sr %d cc %d\n",(int)ds,(int)df,(int)sr,(int)cc);

	*(id *)(recordingSound->info) = self;
//	printf("self == %p\n",self);
    SndStartRecording(recordingSound,1,2,0, startRecord,endRecord);
	return;
#endif /* NEXT_RECORDING_ENABLED */
}

#ifdef USE_NEXTSTEP_SOUND_IO
char *SndSoundError(int err);
#endif

- (void)stop:(id)sender
{
  [sound stop:self];  // TODO should self be sender?
  return;
}

- (float)reductionFactor
{
	return reductionFactor;
}
- (BOOL)setReductionFactor:(float)redFactor
{
    if (svFlags.autoscale) return NO;
    if (!sound) return NO;
    if (redFactor < 0.04) return NO;
    if (reductionFactor != redFactor) [self invalidateCache];
    reductionFactor = redFactor;
    [[self window] disableFlushWindow];

    //    [self hideCursor];

    [self sizeToFit];
    //    [self showCursor];
    [[self window] enableFlushWindow];
    return YES;
}
- scaleToFit
/* here I think I must be careful about nil sounds, and 0-length sounds.
 * What do I expect to happen if this is the case?
 */
{	
    NSRect newFrame = [self frame];
    int sc = [sound sampleCount];
    if (newFrame.size.width < 1.1) newFrame.size.width = 5; /* at least give a little space! */
    if (sc && sound) reductionFactor = sc / newFrame.size.width;
    [self setFrame:newFrame];
    [self invalidateCache];
    [self setNeedsDisplay:YES];
    return self;
}

- (void)sizeToFit
{

    float aWidth;

    NSRect newFrame = [self frame];
    NSRect zapRect = [self bounds];


    [[self window] disableFlushWindow];

    //    [self hideCursor];

    if (!sound)
      aWidth = 5;

    if (![sound sampleCount])
      aWidth = 5;

    else {

      aWidth = ([sound sampleCount] - 1.0) / reductionFactor;

      if ((int)aWidth == ceil(aWidth))
	aWidth += 1;

      else
	aWidth = ceil(aWidth);
    }

    if (aWidth < newFrame.size.width) {
      zapRect.origin.x = aWidth;
      zapRect = NSIntersectionRect(zapRect,[self visibleRect]);
      
      if (!NSEqualRects(zapRect,NSZeroRect)) {
	[self lockFocus];

#ifndef QUARTZ_RENDERING
	PSsetgray(NSDarkGray);
	NSRectFill(zapRect);
#else
	{
	  NSGraphicsContext *graphicsContext;
	  CGContextRef ctx;
	  //CGPoint point;

	  graphicsContext = [NSGraphicsContext currentContext];
	  ctx = [graphicsContext graphicsPort];

	  [backgroundColour set];
	  NSRectFill(zapRect);
	}
#endif

	[self unlockFocus];
      }
    }

    [self setFrameSize:NSMakeSize(aWidth, [self frame].size.height)];
    //    [self showCursor];
    [[self window] enableFlushWindow];
    [self setNeedsDisplay:YES];
}



- (void)sizeToFit: (BOOL) withAutoscaling
{

    int sc = [sound sampleCount];

    float aWidth;

    NSRect newFrame = [self frame];
    NSRect zapRect = [self bounds];

    [[self window] disableFlushWindow];

    //    [self hideCursor];

    if (!sound)
      aWidth = 5;

    if (![sound sampleCount])
      aWidth = 5;

    else {

      aWidth = ([sound sampleCount] - 1.0) / reductionFactor;

      if ((int)aWidth == ceil(aWidth))
	aWidth += 1;

      else
	aWidth = ceil(aWidth);
    }

    if (aWidth < newFrame.size.width) {

      if  (!withAutoscaling) {
	zapRect.origin.x = aWidth;
	zapRect = NSIntersectionRect(zapRect,[self visibleRect]);
      
	if (!NSEqualRects(zapRect,NSZeroRect)) {
	  [self lockFocus];

#ifndef QUARTZ_RENDERING
	  PSsetgray(NSDarkGray);
	  NSRectFill(zapRect);
#else
	  {
	    NSGraphicsContext *graphicsContext;
	    CGContextRef ctx;
	    //CGPoint point;
	    
	    graphicsContext = [NSGraphicsContext currentContext];
	    ctx = [graphicsContext graphicsPort];
	    
	    [backgroundColour set];
	    NSRectFill(zapRect);
	  }
#endif

	  [self unlockFocus];
	}
      }
    
    /* do autoscaling */


      else {

	/* at least give a little space! */

	if (newFrame.size.width < 1.1)
	  newFrame.size.width = 5;

	if (sc && sound)
	  reductionFactor = sc / newFrame.size.width;

	[self setFrame:newFrame];
	[self invalidateCache];
	[[self window] enableFlushWindow];
	[self setNeedsDisplay:YES];

	return;
      }
    }

    [self setFrameSize:NSMakeSize(aWidth, [self frame].size.height)];
    //    [self showCursor];
    [[self window] enableFlushWindow];
    [self setNeedsDisplay:YES];
}



- setAutoscale:(BOOL)aFlag
{
    svFlags.autoscale = aFlag;
    return self;
}

- (void)setBezeled:(BOOL)aFlag
{
	svFlags.bezeled = aFlag;
        [self setNeedsDisplay:YES];
}

- (void)setContinuous:(BOOL)aFlag
{
	svFlags.continuous = aFlag;
}

- (void)setDelegate:(id)anObject
{
	delegate = anObject;
}

- (void)setDefaultRecordTime:(float)seconds
{
	if (seconds <= 0) defaultRecordSeconds = 0.1;
	else defaultRecordSeconds = seconds;
}

- (void)setEditable:(BOOL)aFlag
{
	svFlags.notEditable = !aFlag;
}

- (void)setEnabled:(BOOL)aFlag
{
	svFlags.disabled = !aFlag;
}
- (void)setOptimizedForSpeed:(BOOL)aFlag
{
	if (aFlag == svFlags.notOptimizedForSpeed && svFlags.notOptimizedForSpeed == aFlag) [self invalidateCache];
	svFlags.notOptimizedForSpeed = !aFlag;
        if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}
- (void)setDrawsCrosses:(BOOL)aFlag
{
	svFlags.drawsCrosses = aFlag;
    if ( reductionFactor <= CROSSTHRESH) [self setNeedsDisplay:YES];
}
- (void)setOptThreshold:(int)threshold
{
	if (reductionFactor >= optThreshold && optThreshold != threshold) [self invalidateCache];
	optThreshold = threshold;
        if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}
- (void)setOptSkip:(int)skip
{
	if (optSkip != skip && reductionFactor >= optThreshold) [self invalidateCache];
	optSkip = skip;
        if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}
- (void)setPeakFraction:(float)fraction
{
	if (peakFraction != fraction && reductionFactor >= optThreshold) [self invalidateCache];
	peakFraction = fraction;
        if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}
- (BOOL)setStereoMode:(int)aMode
{
	if ((aMode < 0 || aMode > 2) && aMode != SV_STEREOMODE) return NO;
	if (stereoMode != aMode) [self invalidateCache];
	stereoMode = aMode;
        [self setNeedsDisplay:YES];
	return YES;
}
- (void)setSound:(Snd *)aSound
{
	sound = aSound;
	[self invalidateCache]; /* setSound will always invalidate cache, even if same sound */
	if (!svFlags.autoscale) {
		if (sound && [sound sampleCount]) reductionFactor = [sound samplingRate] / 184; /* to imitate SoundView! */
		else reductionFactor = 1;
		[self sizeToFit];
	}
	else { /* scaleToFit does not autodisplay, but sizeToFit does */
		[self scaleToFit];
            [self setNeedsDisplay:YES];
	}
}

- sound
{	return sound;}

- (void)setFrameSize:(NSSize)_newSize
/*sb: complicated business here. If a SndView is not in a proper scrollview, and it is set to (for example)
    auto-resize, I assume that it should autoscale (the redfactor should change).
    Therefore any SndView NOT in a functioning scrollview should have the autoscale flag explicity set.
    The complication is that if you stick a SndView inside a box in InterfaceBuilder, it is given a scrollview,
    but not a "functional" one. hence the explicit check for autoscale below. Of course, if you have a free-standing
    SndView in a window, it has no scrollview, and I asssume that we must autoscale whether explicitly set or not.
*/
{
    if (![self enclosingScrollView] || svFlags.autoscale) {
        int sc = [sound sampleCount];
        if (_newSize.width < 1.1) _newSize.width = 5; /* at least give a little space! */
        if (sc && sound && (_newSize.width > 0.0)) reductionFactor = sc / _newSize.width;
    }
    [super setFrameSize:_newSize];
    [self invalidateCache];
    [self setNeedsDisplay:YES];
    return;
}
- soundBeingProcessed
{ return _scratchSound; }

- (void)tellDelegate:(SEL)theMessage
{
    if (delegate)
        if ([delegate respondsToSelector:theMessage])
                    [delegate performSelector:theMessage withObject:self];
//  printf("SndView tellDelegate...\n");
}

// delegations which are nominated per performance.
- (void) tellDelegate:(SEL)theMessage duringPerformance: (SndPerformance *) performance
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject: self withObject: performance];
        }
    }
}

- (void)willPlay:sender duringPerformance: performance
{
//  printf("will play\n");
    [self tellDelegate:@selector(willPlay:duringPerformance:) duringPerformance: performance];
    return;
}
- (void)willRecord:sender
{
//  printf("will record\n");
    [self tellDelegate:@selector(willRecord:)];
    return;
}
- didPlay:sender duringPerformance: performance
{
//  printf("did play\n");
    [self tellDelegate:@selector(didPlay:duringPerformance:) duringPerformance: performance];
    return self;
}
- didRecord:sender
{
    BOOL isCompat = NO;
    SndSoundStruct *convertedSound;
	
    [[self window] disableFlushWindow];

    //    [self hideCursor];/* maybe isn't on, but just in case */

    [[self window] enableFlushWindow];
    if (sound && NSWidth(selectionRect) > 0.1) {
        [sound deleteSamplesAt:(int)((float)NSMinX(selectionRect) + 0.1)
                count:(int)((float)NSWidth(selectionRect) + 0.1)];
    }

    if (!sound) {
        sound = [[Snd alloc] init];
        if (!svFlags.autoscale)
                reductionFactor = recordingSound->samplingRate / 184;
        if (!reductionFactor) reductionFactor = 1;
        [sound setDataSize:0 dataFormat:recordingSound->dataFormat
                            samplingRate:recordingSound->samplingRate
                            channelCount:recordingSound->channelCount infoSize:4];
        selectionRect.origin.x = 0;
    }

    isCompat = (	recordingSound->dataFormat == [sound dataFormat] &&
                    recordingSound->samplingRate == [sound samplingRate] &&
                    recordingSound->channelCount == [sound channelCount] );
    if (!isCompat) {
        SndAlloc(&convertedSound, 0, [sound dataFormat],
                    [sound samplingRate], [sound channelCount], 4);
        SndConvertSound(recordingSound,&convertedSound);
        SndInsertSamples([sound soundStruct], convertedSound,(int)((float)NSMinX(selectionRect) + 0.1));
        selectionRect.size.width = SndSampleCount(convertedSound);
        SndFree(convertedSound);
    }
    else {
        SndInsertSamples([sound soundStruct], recordingSound,(int)((float)NSMinX(selectionRect) + 0.1));
        selectionRect.size.width = SndSampleCount(recordingSound);
    }
    SndFree(recordingSound);
    recordingSound = NULL;
    [self tellDelegate:@selector(didRecord:)];
    [self invalidateCacheStartSample:(int)((float)NSMinX(selectionRect) + 0.1)
            end:[sound sampleCount]];
    if (!svFlags.autoscale) [self sizeToFit];
    else { /* scaleToFit does not autodisplay, but sizeToFit does */
        [self scaleToFit];
        [self setNeedsDisplay:YES];
    }
    return self;
}
- hadError:sender
{
    printf("SndView HAD ERROR %d: %s\n",[sender processingError], SndSoundError([sender processingError]));
	return self;
}

BOOL SndCompatibleWith(const SndSoundStruct *sound1, const SndSoundStruct *sound2)
{

    int df1 = sound1->dataFormat;
    int df2 = sound2->dataFormat;
    BOOL formatsOk;
    if (df1 == SND_FORMAT_INDIRECT)
        df1 = ((SndSoundStruct *)(*((SndSoundStruct **)(sound1->dataLocation))))->dataFormat;
    if (df2 == SND_FORMAT_INDIRECT)
        df2 = ((SndSoundStruct *)(*((SndSoundStruct **)(sound2->dataLocation))))->dataFormat;
    formatsOk = ((df1 == df2) && df1 != SND_FORMAT_INDIRECT);

    if (!sound1 || !sound2) return YES;
    return (sound1->channelCount == sound2->channelCount &&
            formatsOk &&
            sound1->samplingRate == sound2->samplingRate );
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard
{
    BOOL usedMyOwn = NO,createdSound = NO,didConversion1 = NO,didConversion2 = NO;
    const SndSoundStruct *sndDataBytes = NULL;
    SndSoundStruct *convertedPasteSound1 = NULL,*convertedPasteSound2 = NULL;

    NSArray *acceptable =
        [[[NSArray alloc] initWithObjects:NXSoundPboardType,NXSoundPboardTypeOld,nil] autorelease];

    NSString *theType;

    if (svFlags.notEditable) return YES;

    if (sound)
      if ([sound soundStruct]->dataSize != 0 && ![sound isEditable])
	return YES;

    theType = [pboard availableTypeFromArray:acceptable];

    if (!theType)
      return YES;

    if (_lastCopyCount == [pboard changeCount]) {
        sndDataBytes = [_pasteboardSound soundStruct];
        usedMyOwn = YES;
    }

    if (!sndDataBytes) {
        NSData *sndData = [pboard dataForType:theType];
//        printf("sound data length %d\n",[sndData length]);
        if (sndData) {
            sndDataBytes = [sndData bytes];
//            pasteSound = [[Sound alloc] initFromPasteboard:pboard];
        }
    }

    /*
    [[self window] disableFlushWindow];
    [self hideCursor];
    [[self window] enableFlushWindow];
    */

    if (sndDataBytes) {
        if (sound) {
            if (!SndCompatibleWith([sound soundStruct],sndDataBytes)) {
                SndAlloc(&convertedPasteSound1,0,
                                [sound dataFormat],(int)[sound samplingRate],
                                [sound channelCount],4);
                didConversion1 = YES;
                if (SndConvertSound(sndDataBytes, &convertedPasteSound1) != SND_ERR_NONE ) {
                    [self tellDelegate:@selector(hadError:)];
		    //                    [self showCursor];
                    if (convertedPasteSound1) SndFree(convertedPasteSound1);
                    return YES;
			    // FIXME do I need to free anything else here?
                    }
                sndDataBytes = convertedPasteSound1;
            }
            /* THIS IS A REAL PAIN! some conversions have to be done twice. eg mulaw to 16bit stereo
             * will not be done in one step! I wonder if any take 3 steps???
             */
            if (!SndCompatibleWith([sound soundStruct],sndDataBytes)) {
                SndAlloc(&convertedPasteSound2,0,
                                [sound dataFormat],(int)[sound samplingRate],
                                [sound channelCount],4);
                didConversion2 = YES;
                if (SndConvertSound(sndDataBytes, &convertedPasteSound2) != SND_ERR_NONE ) {
                    [self tellDelegate:@selector(hadError:)];
		    //                    [self showCursor];
                    if (convertedPasteSound1) SndFree(convertedPasteSound1);
                    if (convertedPasteSound2) SndFree(convertedPasteSound2);
                    return YES;
                    }
                sndDataBytes = convertedPasteSound2;
            }
        }
        if (!sound) {
            sound = [[Snd alloc] init];
            createdSound = YES;
            selectionRect.origin.x = selectionRect.size.width = 0;
            if (!svFlags.autoscale)
                reductionFactor = sndDataBytes->samplingRate / 184;
            if (!reductionFactor) reductionFactor = 1;
        }
        if (createdSound || SndCompatibleWith([sound soundStruct],sndDataBytes)) {
            if (!createdSound && (int)((float)NSWidth(selectionRect) + 0.1)) {
                [sound deleteSamplesAt: (int)((float)NSMinX(selectionRect) + 0.1)
                                 count:(int)((float)NSWidth(selectionRect) + 0.1)];
            }
            if (!createdSound) {
                SndInsertSamples([sound soundStruct] ,sndDataBytes, (int)selectionRect.origin.x);
                [self invalidateCacheStartSample:(int)selectionRect.origin.x
                                end:[sound sampleCount]];
            }
            else {
                SndSoundStruct *newSoundStruct;
                SndCopySound(&newSoundStruct, sndDataBytes);
                [sound setSoundStruct: newSoundStruct
                      soundStructSize:sndDataBytes->dataSize + sndDataBytes->dataLocation];
                [self invalidateCache];
            }
            selectionRect.origin.x = (int)((float)NSMinX(selectionRect) + 0.1 +
                                           SndSampleCount(sndDataBytes));
            selectionRect.size.width = 0;
            if (!svFlags.autoscale) [self sizeToFit:YES];
            else { /* scaleToFit does not autodisplay, but sizeToFit does */
                [self scaleToFit];
                [self setNeedsDisplay:YES];
            }
            [self tellDelegate:@selector(soundDidChange:)];
        }
    }
    else NSRunAlertPanel(@"SndView", @"Could not paste sound", @"", nil, nil);
    if (convertedPasteSound1) SndFree(convertedPasteSound1);
    if (convertedPasteSound2) SndFree(convertedPasteSound2);
    return YES;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)thePasteboard types:(NSArray *)pboardTypes
/*
 * The usual time for this to be invoked is by the Services menu, which does
 * not actually require data to be placed on the pasteboard immediately. Here,
 * I DO place it on the pasteboard immediately, but maybe should not. Oh well.
 */
{
    if ([self writeSelectionToPasteboardNoProvide:thePasteboard types:pboardTypes]) {
        [self pasteboard:thePasteboard provideDataForType:NXSoundPboardType];
            return YES;
    }
    else return NO;
}

- (BOOL)writeSelectionToPasteboardNoProvide:thePasteboard types:(NSArray *)pboardTypes
{

    if (NSWidth(selectionRect) < 0.1) return NO;

    if (!sound)
      return NO;

    if ([sound sampleCount] < NSMaxX(selectionRect))
      return NO;

    if (!_pasteboardSound) 
            _pasteboardSound = [[Snd alloc] init];

    if ( [_pasteboardSound copySamples:sound
		      at:(int)((float)NSMinX(selectionRect) + 0.1)
		      count:(int)((float)NSWidth(selectionRect) + 0.1)] !=
	 SND_ERR_NONE ) {

      fprintf(stderr,"there was a problem copying samples\n");
      return NO;
    }

    notProvidedData = YES;
    [thePasteboard declareTypes:
        [NSArray arrayWithObjects:NXSoundPboardType,NXSoundPboardTypeOld,nil]
                          owner:self];	

    _lastCopyCount = [thePasteboard changeCount];
    return YES;
}

- validRequestorForSendType:(NSString *)typeSent returnType:(NSString *)typeReturned
{
    if ( ([NXSoundPboardType isEqualToString:typeSent] || typeSent == NULL) &&
        	([NXSoundPboardType isEqualToString:typeReturned] || typeReturned == NULL) ) {
	
	if ( ((sound && (NSWidth(selectionRect) > 0.1)) || typeSent == NULL) &&
             ((!svFlags.notEditable) || typeReturned == NULL) ) {
            return self;
        }
    }
    return [super validRequestorForSendType:typeSent returnType:typeSent];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    int v = [aDecoder versionForClassName:@"SndView"];
    char b1, b2, b3, b4, b5, b6, b7, b8;
    [super initWithCoder:aDecoder];
    if (v == 0) {
        sound = [[aDecoder decodeObject] retain];
        delegate = [[aDecoder decodeObject] retain];
        selectionRect = [aDecoder decodeRect];
        [aDecoder decodeValuesOfObjCTypes:"if", &displayMode, &reductionFactor];
        [aDecoder decodeValuesOfObjCTypes:"@@", &backgroundColour, &foregroundColour];
        [aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
        svFlags.disabled = b1;
        svFlags.continuous = b2;
        svFlags.cursorOn = b3;
        svFlags.drawsCrosses = b4;
        svFlags.autoscale = b5;
        svFlags.bezeled = b6;
        svFlags.notEditable = b7;
        svFlags.notOptimizedForSpeed = b8;

        [aDecoder decodeValuesOfObjCTypes:"iiiifiidf", &teNum, &optThreshold, &optSkip, &stereoMode, 
                &peakFraction, &defaultRecordFormat, &defaultRecordFormat,
                &defaultRecordSampleRate,&defaultRecordSeconds];
        dataList = [[aDecoder decodeObject] retain];
        /* and initialize: */
        _scratchSound = nil;
        _pasteboardSound = nil;
        recordingSound = NULL;
        _lastPasteCount = 0;
        _lastCopyCount = 0;
        notProvidedData = NO;
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    char b1, b2, b3, b4, b5, b6, b7, b8;
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:sound];
    [aCoder encodeConditionalObject:delegate];
    [aCoder encodeRect:selectionRect];
    [aCoder encodeValuesOfObjCTypes:"if", &displayMode, &reductionFactor];
    [aCoder encodeValuesOfObjCTypes:"@@", &backgroundColour, &foregroundColour];
    b1 = svFlags.disabled;
    b2 = svFlags.continuous;
    b3 = svFlags.cursorOn;
    b4 = svFlags.drawsCrosses;
    b5 = svFlags.autoscale;
    b6 = svFlags.bezeled;
    b7 = svFlags.notEditable;
    b8 = svFlags.notOptimizedForSpeed;
    [aCoder encodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
    [aCoder encodeValuesOfObjCTypes:"iiiifiidf", &teNum, &optThreshold, &optSkip, &stereoMode, 
            &peakFraction, &defaultRecordFormat, &defaultRecordFormat,
            &defaultRecordSampleRate,&defaultRecordSeconds];
    [aCoder encodeObject:dataList];
}

@end
