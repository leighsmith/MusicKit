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

#import <math.h>
#import "SndView.h"
#import "SndFunctions.h"
#import "SndMuLaw.h"
#import "SndAudioBuffer.h"
#import "SndPasteboard.h"

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

#if defined(NeXT)
#define PlatformSoundPasteboardType @"NXSoundPboardType"
#endif

// Imitates the SoundView initial reduction factor when divided by the sample rate.
#define SOUNDVIEW_SR_REDUCTION 184 

@implementation SndView

+ (void) initialize
{
    if (self == [SndView class]) {
	(void) [SndView setVersion: (int) 0];
    }
}

- (void) toggleCursor
{

#ifdef SV_ENABLE_CURSOR
    NSRect cursorRect = [self bounds];

    cursorRect.origin.x = (int) ( (float) NSMinX(selectionRect) /
				  (float) reductionFactor);

    cursorRect.size.width = 1;
    [self lockFocus];

    //    [selectionColour set];

    //    NSRectFillUsingOperation(cursorRect, NSCompositeSourceOver);

    //    NSHighlightRect(cursorRect);

    [self unlockFocus];
    [[self window] flushWindow];
    svFlags.cursorOn = !svFlags.cursorOn;
#endif
}

- hideCursor
{
#ifdef SV_ENABLE_CURSOR
    if (teNum) {

      [teNum invalidate];
      [teNum release];
      teNum = NULL;

      if (svFlags.cursorOn)
	[self toggleCursor];

      svFlags.cursorOn = NO;
    }

#endif
    return self;
}


- showCursor
{
#ifdef SV_ENABLE_CURSOR
  if (!teNum) {

    if (NSWidth(selectionRect) < 0.1) {

      if (!svFlags.cursorOn)
	[self toggleCursor];

      teNum = [[NSTimer scheduledTimerWithTimeInterval: 0.5
			target: self
			selector: @selector(toggleCursor)
			userInfo: self
			repeats: YES] retain];
    }
  }

#endif
  return self;
}

- (BOOL) scrollPointToVisible: (const NSPoint) point
{
    NSRect r;

    r.origin = point;
    r.size.width = r.size.height = 0.1;

    return [self scrollRectToVisible: r];
}

- (BOOL) resignFirstResponder
{
    return YES;
}

- (BOOL) acceptsFirstResponder
{
    return (!svFlags.disabled);
}

- (BOOL) becomeFirstResponder;
{
    return YES;
}

- (void) copy: (id) sender;
{
    NSArray *typesList = nil;
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    
    [self writeSelectionToPasteboardNoProvide: pboard types: typesList];
}

- (void) cut: (id) sender;
{
    [self copy: sender];
    [self delete: sender];
}

- (void) delete: (id) sender;
{
    if (NSWidth(selectionRect) < 0.1) return;
    if (!sound) return;
    if ([sound lengthInSampleFrames] < NSMaxX(selectionRect)) return;
    if (![sound isEditable]) return;
    if (svFlags.notEditable) return;
    [sound deleteSamplesAt: (int) ((float) NSMinX(selectionRect) + 0.1)
		     count: (int) ((float) NSWidth(selectionRect) + 0.1)];
    [self invalidateCacheStartSample: (int) ((float) NSMinX(selectionRect) + 0.1)
				 end: [sound lengthInSampleFrames]];
    selectionRect.size.width = 0.0;
    if (!svFlags.autoscale)
	[self sizeToFit];
    else { /* scaleToFit does not autodisplay, but sizeToFit does */
	[self scaleToFit];
	[self setNeedsDisplay:YES];
    }

    /*
    [[self window] disableFlushWindow];
    [self showCursor];
    [[self window] enableFlushWindow];
    */

    [self tellDelegate: @selector(soundDidChange:)];
}

- (void) paste: (id) sender;
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    
    [self readSelectionFromPasteboard: pboard];
}

- (void) selectAll: (id) sender;
{
    if (!sound) return;

/*
    [[self window] disableFlushWindow];
    [self hideCursor];
    [[self window] enableFlushWindow];
*/

    selectionRect.origin.x = 0;
    selectionRect.size.width = [sound lengthInSampleFrames];
    [self setNeedsDisplay:YES];
//  NSLog(@"FINAL SELECTION %g, %g\n",NX_X(&selectionRect) ,NX_WIDTH(&selectionRect));
}

- delegate;
{
    return delegate;
}

- (int) displayMode;
{
    return displayMode;
}

- (void) setDisplayMode: (int) aMode /*SND_SOUNDVIEW_WAVE or SND_SOUNDVIEW_MINMAX*/
{
    if (displayMode != aMode)
	[self invalidateCache];
    else
	return;
    displayMode = aMode;
    [self setNeedsDisplay:YES];
}

- drawSamplesFrom: (int) first to: (int) last;
{
    return self;
}

// retrieve a sound value at the given frame, for a specified channel, or average over all channels.
// channelNumber is 0 - channelCount to retrieve a single channel, channelCount to average all channels
static float getSoundValue(void *pcmData, SndSampleFormat sampleDataFormat, int frameNumber, int channelNumber, int channelCount)
{
    float theValue = 0.0;
    int averageOverChannels;
    int startingChannel;
    int sampleIndex;
    int sampleNumber;
    
    if (channelNumber == channelCount) {
	averageOverChannels = channelCount;
	startingChannel = 0;
    }
    else {
	averageOverChannels = 1;
	startingChannel = channelNumber;
    }
    sampleNumber = frameNumber * channelCount + startingChannel;

    for(sampleIndex = sampleNumber; sampleIndex < sampleNumber + averageOverChannels; sampleIndex++) {
	// TODO move this into a SndAudioBuffer method.
	switch (sampleDataFormat) {
	    case SND_FORMAT_LINEAR_8:
		theValue += ((char *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_MULAW_8:
		theValue += SndMuLawToLinear(((char *) pcmData)[sampleIndex]);
		break;
	    case SND_FORMAT_EMPHASIZED:
	    case SND_FORMAT_COMPRESSED:
	    case SND_FORMAT_COMPRESSED_EMPHASIZED:
	    case SND_FORMAT_DSP_DATA_16:
	    case SND_FORMAT_LINEAR_16:
		theValue += ((short *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_LINEAR_24:
	    case SND_FORMAT_DSP_DATA_24:
		// theValue = ((short *) pcmData)[frameNumber];
		theValue += *((int *) ((char *) pcmData + sampleIndex * 3)) >> 8;
		break;
	    case SND_FORMAT_LINEAR_32:
	    case SND_FORMAT_DSP_DATA_32:
		theValue += ((int *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_FLOAT:
		theValue += ((float *) pcmData)[sampleIndex];
		break;
	    case SND_FORMAT_DOUBLE:
		theValue += ((double *) pcmData)[sampleIndex];
		break;
	    default: /* just in case */
		theValue += ((short *) pcmData)[sampleIndex];
		NSLog(@"SndView getSoundValue: unhandled format %d\n", sampleDataFormat);
		break;
	}	
    }
    return (averageOverChannels > 1) ? theValue / averageOverChannels : theValue;
}


static double maximumAmplitude(SndSampleFormat type)
{
    switch (type) {
    case SND_FORMAT_LINEAR_8:
	return 128.0;
    case SND_FORMAT_LINEAR_24:
    case SND_FORMAT_DSP_DATA_24:
	return 8388608.0;
    case SND_FORMAT_LINEAR_32:
    case SND_FORMAT_DSP_DATA_32:
	return 2147483648.0;
    case SND_FORMAT_MULAW_8:
	return 32768.0;
    case SND_FORMAT_LINEAR_16:
    case SND_FORMAT_EMPHASIZED:
    case SND_FORMAT_COMPRESSED:
    case SND_FORMAT_COMPRESSED_EMPHASIZED:
    case SND_FORMAT_DSP_DATA_16:
    default:
	return 32768.0;
    case SND_FORMAT_FLOAT:
	return 1.0;
    case SND_FORMAT_DOUBLE:
	return 1.0;
    }
}

- (BOOL) invalidateCacheStartSample: (int) start end: (int) end
{
    int startPixel = start / reductionFactor;
    int endPixel = end / reductionFactor;
    
    if (startPixel < 0 || endPixel < startPixel) return NO;
    return [self invalidateCacheStartPixel:startPixel end:endPixel];
}

- (BOOL) invalidateCacheStartPixel: (int) start end: (int) end
{
    int startOfCache;
    int startpix, endpix;
    int i;
    SndDisplayData *theObj, *newObj;
    
    if (!dataList) return YES;
    if ((end != -1 && end < start) || start < 0) return NO;
    if (end == -1) end = NSWidth([self bounds]) - 1;

    for (i = [(NSMutableArray *) dataList count] - 1; i >= 0; i--) {
        theObj = [(NSMutableArray *) dataList objectAtIndex:i];
        startpix = [theObj startPixel];
        endpix = [theObj endPixel];
        if (startpix > end) continue; /* this cache is higher than region */
        if (endpix < start) break; /* this cache is lower than region */
        if (startpix >= start && startpix <= end &&
            endpix >= start && endpix <= end) { /* cache is enclosed in region, and deleted */
                [(NSMutableArray *) dataList removeObjectAtIndex: i];
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
        [(NSMutableArray *) dataList insertObject:newObj atIndex:i+1];
        [theObj truncateToLastPixel:start-1];
    }
    return YES;
}

- (void) invalidateCache /* blast 'em all away */
{
    if (!dataList) return;
    [(NSMutableArray *) dataList removeAllObjects];
}

- (BOOL) isOpaque
{
    return YES;
}

/* draw selection rect */
- (void) drawSelectionRectangleWithin: (NSRect) rects
{
    NSRect scaledSelRect = selectionRect;
    scaledSelRect.origin.x = (int) ((float) NSMinX(selectionRect) / (float) reductionFactor);
    
    scaledSelRect.size.width = (int) ((NSMaxX(selectionRect) - 1) / reductionFactor) - NSMinX(scaledSelRect) + 1;
    
    if (!((NSMinX(scaledSelRect) >= NSMinX(rects) &&
	   NSMinX(scaledSelRect) <= NSMaxX(rects)) ||
	  (NSMaxX(scaledSelRect) >= NSMinX(rects) && 
	   NSMaxX(scaledSelRect) <= NSMaxX(rects)) ||
	  (NSMinX(scaledSelRect) <= NSMinX(rects) &&
	   NSMaxX(scaledSelRect) >= NSMaxX(rects)) ) || noSelectionDraw) {
	return;	
    }
    else {
	NSRect highlightRect = [self bounds];
	
	/*
	 NSLog(@"HIGHLIGHTing scaled sel rect... %g to %g\n",
		 NX_X(&scaledSelRect),NX_MAXX(&scaledSelRect));
	 
	 NSLog(@"HIGHLIGHTing rects... %g to %g\n",
		 NX_X(rects),NX_MAXX(rects));
	 */
	
	highlightRect.origin.x = (int) ((NSMinX(scaledSelRect) >= NSMinX(rects)) ?
					NSMinX(scaledSelRect) : NSMinX(rects));
	
	highlightRect.size.width = (int) (((NSMaxX(scaledSelRect) <= NSMaxX(rects)) ?
					   NSMaxX(scaledSelRect) : NSMaxX(rects) )   - NSMinX(highlightRect) + 0.1);
	
	[selectionColour set];
	
	NSRectFillUsingOperation(highlightRect, NSCompositeDestinationIn /* NSCompositeSourceOver */);
	
	// NSHighlightRect(highlightRect);
	// NSLog(@"HIGHLIGHT %g to %g\n",NSMinX(highlightRect), NSMaxX(highlightRect));
    }    
}

- (void) cacheIntoMax: (float *) cacheMaxArray 
		  min: (float *) cacheMinArray
	    fromStart: (int) startX
		toEnd: (int) endX
	      channel: (int) whichChannel
{
    /* for working through caching: */
    int currStartPoint, arrayPointer, cacheIndex;
    SndDisplayData *currentCacheObject;	
    float actualBaseF, fONBase;
    /* for stepping through data */
    int actualBase, firstOfNext;
    int j; // TODO needs renaming
    int currentPixel;
    int skipFactor = 1;
    void *pcmData;
    int lastFrameInBlock, currentFrame; /* max point and current counter in current fragmented sound data segment */
    int frameCount = [sound lengthInSampleFrames];
    float thisMax, thisMin, maxNinety = 0, minNinety = 0, theValue, lastValue = 0;
    int directionDown = NO; /* NO for up, YES for down */
    BOOL optimize = (!svFlags.notOptimizedForSpeed && reductionFactor > optThreshold);
    int chanCount = [sound channelCount];
    SndSampleFormat dataFormat = [sound dataFormat];

    /* STARTING MAIN CACHE LOOP HERE */
    
    currStartPoint = startX;
    arrayPointer = 0;
    
    while (currStartPoint <= endX) {
	int nextCache;
	int localMax;
	int leadsOnFrom;
	
	/* following returns leadsOn == YES iff cacheIndex == -1 && (currStartPoint - 1) is in previous cache */
	
	cacheIndex = [dataList findObjectContaining: currStartPoint
					       next: &nextCache 
					leadsOnFrom: &leadsOnFrom];
	
	if (cacheIndex != -1) {
	    int k, numToMove, cachedStart;
	    float *maxVals, *minVals;
	    
	    // NSLog(@"Using cached data %d\n",cacheIndex);
	    currentCacheObject = (SndDisplayData *) [(NSMutableArray *) dataList objectAtIndex: cacheIndex];
	    numToMove = [currentCacheObject endPixel];
	    cachedStart = [currentCacheObject startPixel];
	    if (numToMove > endX) 
		numToMove = endX - currStartPoint + 1;
	    else 
		numToMove = numToMove - currStartPoint + 1;
	    maxVals = [currentCacheObject pixelDataMax];
	    minVals = [currentCacheObject pixelDataMin];
	    // NSLog(@"reading cache from %d, for %d\n", currStartPoint - cachedStart, numToMove);
	    for (k = 0; k < numToMove; k++) {
		cacheMaxArray[currStartPoint + k - startX] = maxVals[k + currStartPoint - cachedStart];
		cacheMinArray[currStartPoint + k - startX] = minVals[k + currStartPoint - cachedStart];
	    }
	    currStartPoint += k;
	    continue;
	}
	if (nextCache != -1) {
	    localMax = [[(NSMutableArray *) dataList objectAtIndex:nextCache] startPixel] - 1;
	    if (localMax > endX)
		localMax = endX;
	}
	else
	    localMax = endX;
	
	/* set up first read point in sound data */
	actualBaseF =  (float) currStartPoint * reductionFactor;
	if ((int) actualBaseF != ceil(actualBaseF))
	    actualBase = ceil(actualBaseF);
	else
	    actualBase = (int) (actualBaseF);
	j = firstOfNext = actualBase; /* just initialise it for now */
	pcmData = SndGetDataAddresses(actualBase, [sound soundStruct], &lastFrameInBlock, &currentFrame);
	
	for (currentPixel = currStartPoint; currentPixel <= localMax; currentPixel++) {
	    BOOL first = YES;
	    
	    thisMax = 0.0;
	    thisMin = 0.0;
	    if (currentPixel * reductionFactor >= frameCount)
		break;
	    skipFactor = 1;
	    fONBase = (float) (currentPixel+1) * reductionFactor;
	    if ((int) fONBase != ceil(fONBase))
		firstOfNext = ceil(fONBase);
	    else
		firstOfNext = (int) (fONBase);
	    
	    // have to increment currentFrame by same amount as j although we can simply assign j
	    currentFrame += (actualBase - j); 
	    j = actualBase;
	    
	    /* need to establish initial values for base and counter here, for fragged sounds */
	    while (j < firstOfNext) {
		if (currentFrame >= lastFrameInBlock) 
		    pcmData = SndGetDataAddresses(actualBase, [sound soundStruct], &lastFrameInBlock, &currentFrame);
		if (j < frameCount)
		    theValue = getSoundValue(pcmData, dataFormat, currentFrame, whichChannel, chanCount);
		else 
		    theValue = 0;
		if (first) {
		    minNinety = thisMin = theValue;
		    maxNinety = thisMax = theValue;
		    first = NO;
		}
		else {
		    if (theValue < thisMin) {
			thisMin = theValue;
			if (optimize) minNinety = thisMin + peakFraction * abs((int) thisMin);
		    }
		    else if (theValue > thisMax) {
			thisMax = theValue;
			if (optimize)
			    maxNinety = thisMax - peakFraction * abs((int) thisMax);
		    }
		}
		if (optimize) {
		    directionDown = (theValue < lastValue);
		    if ((!directionDown && (theValue > maxNinety))
			|| (directionDown && (theValue < minNinety)))
			skipFactor = 1;
		    else 
			skipFactor = optSkip;
		}
		lastValue = theValue;
		j += skipFactor;
		currentFrame += skipFactor;
	    }
	    cacheMaxArray[currentPixel - startX] = thisMax;
	    cacheMinArray[currentPixel - startX] = thisMin;
	    actualBase = firstOfNext;
	} /* 'for' loop for creating new cache data */

        // now do the following:
        // if we are following on from last cache, append our data to that cache
        //   otherwise create new cache...
        // Increase currStartPoint
        // Continue...

        if (leadsOnFrom != -1) { /* we have calculated a new region which exactly appends an existing cache */
            SndDisplayData *cacheToExtend = (SndDisplayData *) [(NSMutableArray *) dataList objectAtIndex: leadsOnFrom];
            [cacheToExtend addPixelDataMax: &cacheMaxArray[currStartPoint - startX]
                                       min: &cacheMinArray[currStartPoint - startX]
                                     count: localMax - currStartPoint + 1
                                      from: [cacheToExtend endPixel] + 1];
	    //	NSLog(@"adding to cache: from %d count %d\n", [cacheToExtend endPixel] + 1, localMax - currStartPoint + 1);
        }
	else {
	    SndDisplayData *newCache = [[SndDisplayData alloc] init];
	    [newCache setPixelDataMax: &cacheMaxArray[currStartPoint - startX]
				  min: &cacheMinArray[currStartPoint - startX]
				count: localMax - currStartPoint + 1
				start: (int) currStartPoint];
	    [(NSMutableArray *) dataList addObject: newCache];
	    [dataList sort];
	    //	NSLog(@"setting new cache: start %d count %d\n", currStartPoint, localMax - currStartPoint + 1);
	}
	/* now see if we should join up to following cache */
	cacheIndex = [dataList findObjectContaining:localMax + 1 next:&nextCache leadsOnFrom:&leadsOnFrom];
	if (cacheIndex != -1 && leadsOnFrom != -1) {
	    [[(NSMutableArray *) dataList objectAtIndex:leadsOnFrom] addDataFrom: [(NSMutableArray *) dataList objectAtIndex:cacheIndex]];
	    [(NSMutableArray *) dataList removeObjectAtIndex:cacheIndex];
	    //	NSLog(@"Compacted %d with %d. Now %d caches\n", leadsOnFrom, cacheIndex,[dataList count]);
	}
	
	currStartPoint = localMax + 1;
    } /* while loop for caching */
}

- (void) drawCrossAtX: (int) pixelX andY: (int) theValue
{
#ifndef QUARTZ_RENDERING
    PSrmoveto(0,3);
    PSrlineto(0,-6);
    PSrmoveto(0,3);
#else
    CGContextMoveToPoint(ctx,    (int) pixelX + 0.5, theValue + 4);
    CGContextAddLineToPoint(ctx, (int) pixelX + 0.5, theValue - 4);
    CGContextMoveToPoint(ctx,    (int) pixelX + 0.5, theValue);
#endif    
}

// draw sound amplitude plots from the supplied audio data, no reduction.
- (void) drawSound: (Snd *) soundToDraw within: (NSRect) rects channel: (int) whichChannel
{
    int lastFrameToDisplay;
    float theValue;
    int i, pixelX = 0;
    void *pcmData;
    int lastFrameInBlock, currentFrame; /* max point and current counter in current fragged sound data segment */
    int frameCount = [soundToDraw lengthInSampleFrames];
    SndSampleFormat dataFormat = [soundToDraw dataFormat];
    int chanCount = [soundToDraw channelCount];
    
    /* first sample */
    i = (int) ((float) NSMinX(rects) * (float) reductionFactor);
    
    if (i > 0)
	i--;
    
    pcmData = SndGetDataAddresses(i, [soundToDraw soundStruct], &lastFrameInBlock, &currentFrame);
    
    /* last sample */
    lastFrameToDisplay = (int) ((float) (NSMaxX(rects)) * (float) reductionFactor) + 1;
    
    if (lastFrameToDisplay >= frameCount)
	lastFrameToDisplay = frameCount - 1;
    
    theValue = getSoundValue(pcmData, dataFormat, currentFrame, whichChannel, chanCount);
    
    theValue = theValue * ampScaler + amplitudeDisplayHeight;
    
    /* establish initial point */
    pixelX = (float) ((float) i / (float) reductionFactor);
    
#ifndef QUARTZ_RENDERING
    PSmoveto((int) pixelX + 0.5, theValue);
#else
    CGContextMoveToPoint(ctx, (int) pixelX + 0.5, theValue);
#endif
    
    while (i <= lastFrameToDisplay) {
	if (currentFrame >= lastFrameInBlock)
	    pcmData = SndGetDataAddresses(i, [soundToDraw soundStruct], &lastFrameInBlock, &currentFrame);

	theValue = getSoundValue(pcmData, dataFormat, currentFrame, whichChannel, chanCount);
	theValue = theValue * ampScaler + amplitudeDisplayHeight;		
	
	pixelX = (float) ((float) i / (float) reductionFactor);
	
#ifndef QUARTZ_RENDERING
	PSlineto((int) pixelX+0.5, theValue);
#else
	CGContextAddLineToPoint(ctx, (int) pixelX + 0.5, theValue);
#endif
	// Draw crosses if we have zoomed in so far as to pass the cross threshold.
	if (svFlags.drawsCrosses && reductionFactor <= CROSSTHRESH) {
	    [self drawCrossAtX: pixelX andY: theValue];
	}	    
	i++;
	currentFrame++;
    }
    
    [foregroundColour set];
    
#ifndef QUARTZ_RENDERING
    PSstroke();
#else
    CGContextStrokePath(ctx);
#endif    
}

- (void) drawFromCacheMax: (float *) cacheMaxArray 
		      min: (float *) cacheMinArray 
		fromStart: (int) startX
		    toEnd: (int) endX
		  channel: (int) whichChannel
{
    int pixelIndex;
    // long startTime; // for some basic timing within Quartz version

#ifndef QUARTZ_RENDERING
#ifdef USE_PS_USER_PATHS
    //:ps:
    arect = newUserPath();
    beginUserPath(arect,NO);
    
    if (displayMode == SND_SOUNDVIEW_WAVE) {
	float max1 = cacheMaxArray[0] * ampScaler + amplitudeDisplayHeight;
	float min1 = cacheMinArray[0] * ampScaler + amplitudeDisplayHeight;
	if (endX >= NSWidth([self frame])) endX = NSWidth([self frame]) - 1;
	for (pixelIndex = startX;pixelIndex<=endX;pixelIndex++) {
	    float max2 = cacheMaxArray[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight;
	    float min2 = cacheMinArray[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight;
	    UPmoveto(arect, pixelIndex + 0.5, max1);
	    UPlineto(arect, pixelIndex + 0.5, min1);
	    if (pixelIndex < endX) {/* still one more cached point */
		if ((min2 <= max1 && min2 >= min1) 			/* if part of the line          */
		    || (max2 >= min1 && max2 <= max1) 		/*    is outside the one before */
		    || (max2 >= max1 && min2 <= min1)) {		/* if both points encompass */
		    max1 = max2; min1 = min2;
		    continue;
		}
		/* so we draw line from appropriate end, to start of next line */
		if (min2 > max1 && max1 != min1) UPmoveto(arect, pixelIndex+0.5, max1); /*reverse to top if necessary */
		UPlineto(arect, pixelIndex+1+0.5, (min2 > max1) ? min2 : max2);
		max1 = max2; min1 = min2;
	    }
	}
    }
    else {
	UPmoveto(arect,startX+0.5, cacheMaxArray[0] * ampScaler + amplitudeDisplayHeight);
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    UPlineto(arect, pixelIndex+0.5, cacheMaxArray[pixelIndex - startX]* ampScaler + amplitudeDisplayHeight);
	}
	UPmoveto(arect, startX+0.5, cacheMinArray[0] * ampScaler + amplitudeDisplayHeight);
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    UPlineto(arect, pixelIndex+0.5, cacheMinArray[pixelIndex - startX] * ampScaler + amplitudeDisplayHeight);
	}
    }
    endUserPath(arect,dps_ustroke);
    [foregroundColour set];
    sendUserPath(arect);
    freeUserPath(arect);
#else
    PSnewpath();
    if (displayMode == SND_SOUNDVIEW_WAVE) {
	float max1 = cacheMaxArray[0] * ampScaler + amplitudeDisplayHeight;
	float min1 = cacheMinArray[0] * ampScaler + amplitudeDisplayHeight;
	if (endX >= NSWidth([self frame])) endX = NSWidth([self frame]) - 1;
	for (pixelIndex = startX;pixelIndex<endX;pixelIndex++) {
	    float max2 = cacheMaxArray[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight;
	    float min2 = cacheMinArray[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight;
	    PSmoveto(pixelIndex+0.5, max1);
	    PSlineto(pixelIndex+0.5, min1);
	    if (pixelIndex < endX) {/* still one more cached point */
		if ((min2 <= max1 && min2 >= min1) 			/* if part of the line          */
		    || (max2 >= min1 && max2 <= max1) 		/*    is outside the one before */
		    || (max2 >= max1 && min2 <= min1)) {		/* if both points encompass */
		    max1 = max2; min1 = min2;
		    continue;
		}
		/* so we draw line from appropriate end, to start of next line */
		if (min2 > max1 && max1 != min1) PSmoveto(pixelIndex+0.5, max1); /*reverse to top if necessary */
		PSlineto(pixelIndex+1+0.5, (min2 > max1) ? min2 : max2);
		max1 = max2; min1 = min2;
	    }
	}
    }
    else {
	PSmoveto(startX+0.5, cacheMaxArray[0] * ampScaler + amplitudeDisplayHeight);
	for (pixelIndex = startX;pixelIndex<endX;pixelIndex++) {
	    PSlineto(pixelIndex+0.5, cacheMaxArray[pixelIndex - startX]* ampScaler + amplitudeDisplayHeight);
	}
	PSmoveto(startX+0.5, cacheMinArray[0] * ampScaler + amplitudeDisplayHeight);
	for (pixelIndex = startX;pixelIndex<endX;pixelIndex++) {
	    PSlineto(pixelIndex+0.5, cacheMinArray[pixelIndex - startX]* ampScaler + amplitudeDisplayHeight);
	}
    }
    [foregroundColour set];
    PSstroke();
#endif
#else    // QUARTZ_RENDERING
    // startTime = clock();

    CGContextBeginPath(ctx);

    if (displayMode == SND_SOUNDVIEW_WAVE) {
	float max1 = cacheMaxArray[0] * ampScaler + amplitudeDisplayHeight;
	float min1 = cacheMinArray[0] * ampScaler + amplitudeDisplayHeight;
	
	if (endX >= NSWidth([self frame])) {
	    endX = NSWidth([self frame]) - 1;
	}
	
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    float max2 = cacheMaxArray[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight;
	    float min2 = cacheMinArray[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight;
	    
	    CGContextMoveToPoint(ctx, pixelIndex + 0.5, max1);
	    CGContextAddLineToPoint(ctx, pixelIndex + 0.5, min1);
	    
	    /* still one more cached point */
	    
	    if (pixelIndex < endX) {
		/* if part of the line is outside the one before if both points encompass */
		if ((min2 <= max1 && min2 >= min1)
		    || (max2 >= min1 && max2 <= max1)
		    || (max2 >= max1 && min2 <= min1)) {
		    max1 = max2; 
		    min1 = min2;
		    continue;
		}
		
		/* so we draw line from appropriate end, to start of next line */
		if (min2 > max1 && max1 != min1) { /* reverse to top if necessary */
		    CGContextMoveToPoint(ctx, pixelIndex + 0.5, max1);
		}
		
		CGContextAddLineToPoint(ctx, pixelIndex + 1 + 0.5, (min2 > max1) ? min2 : max2);
		
		max1 = max2; 
		min1 = min2;
	    }
	}
    }
    else {
	CGContextMoveToPoint(ctx, startX + 0.5, cacheMaxArray[0] * ampScaler + amplitudeDisplayHeight);
	
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    CGContextAddLineToPoint(ctx, pixelIndex + 0.5, cacheMaxArray[pixelIndex - startX] * ampScaler + amplitudeDisplayHeight);
	}
	
	CGContextMoveToPoint(ctx, startX + 0.5, cacheMinArray[0] * ampScaler + amplitudeDisplayHeight);
	
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    CGContextAddLineToPoint(ctx, pixelIndex + 0.5, cacheMinArray[pixelIndex - startX] * ampScaler + amplitudeDisplayHeight);
	}
    }

    [foregroundColour set];

    // NSLog(@"before stroke time: %li\n",clock() -startTime);
    CGContextStrokePath(ctx);
    // NSLog(@"stroke time: %li (%d to %d = %d iterations)\n",clock() -startTime, startX, endX, endX-startX);
#endif
}

- (void) drawRect: (NSRect) rects
{
    NSRect newRect, insetBounds;
    BOOL fragmentedSound = NO;
    SndSampleFormat dataFormat;
    double maxAmp = 32767.0;
    void *pcmData;
    int chanCount;
    int frameCount;
    int startX, endX;
    int whichChannel = 0;
    /* holds the data to be drawn. Calculated from caches, or from examining sound data */
    float 	*cacheMaxArray, *cacheMinArray;
    
#ifdef USE_PS_USER_PATHS
    UserPath *arect; /* for DPSUser Paths, if used */
#endif
#ifdef DO_TIMING
    id t4 = [Timing newWithTag: 4];
    int numTimingPasses = 100;
#endif
#ifdef QUARTZ_RENDERING
    NSGraphicsContext *graphicsContext;
    // CGContextRef ctx;
    
    graphicsContext = [NSGraphicsContext currentContext];
    // [graphicsContext setShouldAntialias: FALSE];
    ctx = [graphicsContext graphicsPort];
    CGContextSetRGBStrokeColor(ctx, 1,0,0,1);
    // CGContextSetLineWidth(ctx, 1.0);
#endif
    
    /*
     [[self window] disableFlushWindow];
     [self hideCursor];
     [[self window] enableFlushWindow];
     */
    
    insetBounds = [self bounds];
    // NSLog(@"from %g to %g, size %d\n", NSMinX(rects), NSMaxX(rects), (int) NSWidth(rects));
    
    ampScaler = 1.0; /* bogus */
    amplitudeDisplayHeight = insetBounds.size.height * 0.5;

    [backgroundColour set];
    
    newRect = NSIntersectionRect(insetBounds, rects);
    
    if (firstDraw) {
	NSRectFill([self frame]);
	firstDraw = NO;
    }
    else
	NSRectFill(newRect);
    
    // NSLog(@"filling %g , %g, w %d h %d\n", NSMinX(newRect), NSMinY(newRect), (int) NSWidth(newRect), (int) NSHeight(newRect));
    
    if (svFlags.bezeled) {
	NSRectEdge mySides[] = { NSMinYEdge, NSMaxYEdge,
	    NSMaxXEdge, NSMaxYEdge, 
	    NSMinXEdge, NSMinYEdge, 
	    NSMinXEdge, NSMaxXEdge };
	float myGrays[] = { NSWhite, NSDarkGray,
	    NSWhite, NSDarkGray,
	    NSDarkGray, NSLightGray, 
	    NSDarkGray, NSLightGray };
	insetBounds = NSDrawTiledRects([self bounds], rects, mySides, myGrays, 8);
    }
    
    if (sound == nil)
	return;
    
    frameCount = [sound lengthInSampleFrames];
    if (frameCount <= 0)
	return;
    
    /* do I need to do any other cleanup here? */
        
    /* draw sound data */    
    dataFormat = [sound dataFormat];
    chanCount = [sound channelCount];
    pcmData = [sound data];
    fragmentedSound = [sound needsCompacting];
    
    maxAmp = maximumAmplitude(dataFormat);
    ampScaler = amplitudeDisplayHeight / maxAmp;

    // NSLog(@"ampScaler %f, amplitudeZoom %f\n", ampScaler, amplitudeZoom);
    
    // This is an attempt to optimise when the multiplication occurs, but we may be doing
    // more work comparing a float than just multiplying.
    if (amplitudeZoom != 1.0)  
	ampScaler *= amplitudeZoom;
    
    // check to see if user desires L&R channels summed.
    // If so, check to see if there are 2 channels to sum.
    // If sound is mono, just do 'left' channel
        
    if (stereoMode == SV_STEREOMODE) { // TODO rename for multiple channel sounds.
	if (chanCount < 2) {
	    whichChannel = 0;
	}
	else
	    whichChannel = chanCount;
    }
    else {
	if (stereoMode > chanCount - 1)
	    whichChannel = chanCount - 1;
	else
	    whichChannel = stereoMode;
    }
    
    /* does the following:
     * 1. set up loop from frame left to right, stepping 1 pixel
     * 2. scan sound data for time equiv to 1 pixel, finding max and min vals
     * 3. plot max and min values, and remember last ones.
     */
    
    cacheMaxArray = (float *) malloc(sizeof(float) * (NSWidth(rects) + 3));
    cacheMinArray = (float *) malloc(sizeof(float) * (NSWidth(rects) + 3));
    
#ifndef QUARTZ_RENDERING
    PSsetlinewidth(0.0);//:ps:
#else
    CGContextSetLineWidth(ctx, 1);
#endif
    
    if (reductionFactor > 1) {
	startX = NSMinX(rects);
	
	/* we need to draw a line leading to first pixel */
	if (NSMinX(rects) > 0.9)
	    startX--;
	
	endX = NSMaxX(rects);
	
	/* we need to draw a line from last pixel */
	if (displayMode == SND_SOUNDVIEW_MINMAX && endX < NSMaxX([self frame]))
	    endX++;

	// Cache
	[self cacheIntoMax: cacheMaxArray min: cacheMinArray fromStart: startX toEnd: endX channel: whichChannel];

#ifdef DO_TIMING
	[t4 reset];
	for (; numTimingPasses ; numTimingPasses--) {
	    [t4 enter:PSTIME];
#endif
	    [self drawFromCacheMax: cacheMaxArray min: cacheMinArray fromStart: startX toEnd: endX channel: whichChannel];
#ifdef DO_TIMING
	    [t4 leave];
	}
	NSLog(@"Timing: walltime %g apptime %g PStime %g\n",[t4 cumWallTime],[t4 cumAppTime],[t4 cumPSTime]);
#endif
	
    }
    else { /* I don't bother caching here, as it's so quick to grab actual data */
	[self drawSound: sound within: rects channel: whichChannel];
    }

    free(cacheMaxArray);
    free(cacheMinArray);

    if (NSWidth(selectionRect) >= 0.1) {	
	/*
	 [[self window] disableFlushWindow];
	 [self showCursor];
	 [[self window] enableFlushWindow];
	 */
	[self drawSelectionRectangleWithin: rects];
    }
}

- (void) setBackgroundColor: (NSColor *) color
{
    [backgroundColour release];
    backgroundColour = [color copy];
    [self setNeedsDisplay:YES];
}

- (NSColor *) backgroundColor;
{
    return backgroundColour;
}

- (void) setSelectionColor: (NSColor *) color
{
    [selectionColour release];
    selectionColour = [color copy];

    [self setNeedsDisplay:YES];
}

- (NSColor *) selectionColor
{
    return selectionColour;
}

- (void) setForegroundColor: (NSColor *) color
{
    [foregroundColour release];
    foregroundColour = [color copy];
    [self setNeedsDisplay:YES];
}

- (NSColor *) foregroundColor
{
    return foregroundColour;
}

- (void) dealloc
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
//	NSLog(@"Freeing SndView\n");
    [self tellDelegate:@selector(willFree:)];

    /*
    [self hideCursor];
    */

    if ((lastCopyCount == [pboard changeCount]) && notProvidedData) {
        /* i.e. we were the last ones to put something on the pasteboard, but
         * have not provided it yet
         */
        [self pasteboard: pboard provideDataForType: SndPasteboardType];
    }
    [pasteboardSound release];
    [scratchSound release];
    [backgroundColour release];
    [foregroundColour release];
    [recordingSound release];
    recordingSound = nil;
    [validPasteboardSendTypes release];
    validPasteboardSendTypes = nil;
    [validPasteboardReturnTypes release];
    validPasteboardReturnTypes = nil;
    if (dataList) {
        [(NSMutableArray *) dataList removeAllObjects];
        [(NSMutableArray *) dataList release];
    }
    [super dealloc];
}

- getSelection: (int *) firstSample size: (int *) sampleCount
{
    *firstSample = (int) selectionRect.origin.x;
    *sampleCount = (int) selectionRect.size.width;
    return self;
}

- (void) setSelection: (int) firstSample size: (int) sampleCount
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
    if (!NSEqualRects(scaledSelection, NSZeroRect)) [self setNeedsDisplayInRect:scaledSelection];
    return;
}

- (void) initVars
{
    // Some platforms have their own pasteboard type that we can interact with, otherwise we just declare our own.
#ifdef PlatformSoundPasteboardType
    validPasteboardSendTypes = [[NSArray alloc] initWithObjects: SndPasteboardType, PlatformSoundPasteboardType, nil];
    validPasteboardReturnTypes = [validPasteboardReturnTypes copy];
#else
    validPasteboardSendTypes = [[NSArray arrayWithObject: SndPasteboardType] retain];
    validPasteboardReturnTypes = [validPasteboardSendTypes copy];
#endif
    
    [NSApp registerServicesMenuSendTypes: validPasteboardSendTypes
			     returnTypes: validPasteboardReturnTypes];
    
    delegate = nil;
    scratchSound = nil;
    sound = nil;
    pasteboardSound = nil;
    recordingSound = nil;
    
    /* setcolors */
    
    // selectionColour = [[NSColor controlHighlightColor] retain];
    selectionColour = [[NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 0.8] retain];
    
    // backgroundColour = [[NSColor controlBackgroundColor] retain];
    backgroundColour = [[NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0] retain];
    
    // foregroundColour = [[NSColor blueColor] retain];//black
    foregroundColour = [[NSColor colorWithCalibratedRed: 0.6 green: 0.25 blue: 1.0 alpha: 0.7] retain];
    
    displayMode = SND_SOUNDVIEW_MINMAX;
    selectionRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    reductionFactor = 4.0; /* bogus */
    amplitudeZoom = 1.0; // Not bogus!
    dataList = [[SndDisplayDataList alloc] init];
    
    svFlags.disabled = 0;
    svFlags.continuous = 0;
    svFlags.cursorOn = 0;
    svFlags.drawsCrosses = 1;
    svFlags.autoscale = 0;
    svFlags.bezeled = 0;
    svFlags.notEditable = 0;
    svFlags.notOptimizedForSpeed = 0;
    optThreshold = FASTSKIPSTART;
    optSkip = FASTSKIPAMOUNT;
    peakFraction = TENPERCENT;
    stereoMode = SV_STEREOMODE;
    
    defaultRecordFormat = SND_FORMAT_MULAW_8;
    defaultRecordChannelCount = 1;
    defaultRecordSampleRate = SND_RATE_CODEC;
    defaultRecordSeconds = DEFAULT_RECORD_SECONDS;
    
    lastCopyCount = lastPasteCount = 0;
    teNum = 0;
    notProvidedData = NO;
    noSelectionDraw = NO;
    firstDraw = YES;
    
    selectionRect.origin.x = selectionRect.size.width = 0;
    [self allocateGState]; // attempt speed increase!    
}

- initWithFrame: (NSRect) frameRect
{
    NSLog(@"initWithFrame not called?\n");
    self = [super initWithFrame: frameRect];
    if (self) {
	[self initVars];
    }
    return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    int version = [aDecoder versionForClassName: @"SndView"];
    char b1, b2, b3, b4, b5, b6, b7, b8;
    
    [super initWithCoder: aDecoder];
    [self initVars]; // Create default versions and overwrite as necessary.
    
    if (version == 0) {
        sound = [[aDecoder decodeObject] retain];
        delegate = [[aDecoder decodeObject] retain];
        selectionRect = [aDecoder decodeRect];
        [aDecoder decodeValuesOfObjCTypes: "if", &displayMode, &reductionFactor];
	[backgroundColour release];
	[foregroundColour release];
        [aDecoder decodeValuesOfObjCTypes:  "@@", &backgroundColour, &foregroundColour];
        [aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
        svFlags.disabled = b1;
        svFlags.continuous = b2;
        svFlags.cursorOn = b3;
        svFlags.drawsCrosses = b4;
        svFlags.autoscale = b5;
        svFlags.bezeled = b6;
        svFlags.notEditable = b7;
        svFlags.notOptimizedForSpeed = b8;
	
        [aDecoder decodeValuesOfObjCTypes: "iiiifiidf", 
	    &teNum,
	    &optThreshold,
	    &optSkip,
	    &stereoMode,
            &peakFraction,
	    &defaultRecordFormat,
	    &defaultRecordChannelCount,
	    &defaultRecordSampleRate,
	    &defaultRecordSeconds];
	[dataList release];
        dataList = [[aDecoder decodeObject] retain];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{
    char b1, b2, b3, b4, b5, b6, b7, b8;
    
    [super encodeWithCoder: aCoder];
    [aCoder encodeObject: sound];
    [aCoder encodeConditionalObject: delegate];
    [aCoder encodeRect: selectionRect];
    [aCoder encodeValuesOfObjCTypes: "if", &displayMode, &reductionFactor];
    [aCoder encodeValuesOfObjCTypes: "@@", &backgroundColour, &foregroundColour];
    b1 = svFlags.disabled;
    b2 = svFlags.continuous;
    b3 = svFlags.cursorOn;
    b4 = svFlags.drawsCrosses;
    b5 = svFlags.autoscale;
    b6 = svFlags.bezeled;
    b7 = svFlags.notEditable;
    b8 = svFlags.notOptimizedForSpeed;
    [aCoder encodeValuesOfObjCTypes: "cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
    [aCoder encodeValuesOfObjCTypes: "iiiifiidf",
	&teNum,
	&optThreshold,
	&optSkip,
	&stereoMode, 
	&peakFraction,
	&defaultRecordFormat,
	&defaultRecordChannelCount,
	&defaultRecordSampleRate,
	&defaultRecordSeconds];
    [aCoder encodeObject: dataList];
    // [aCoder encodeValuesOfObjCTypes: "f", &amplitudeZoom]; // TODO should be encoded when versioning is managed.
}

- (BOOL) isAutoScale
{
    return svFlags.autoscale;
}
- (BOOL) isBezeled
{
    return svFlags.bezeled;
}
- (BOOL) isContinuous
{
    return svFlags.continuous;
}
- (BOOL) isEditable
{
    return !(svFlags.notEditable);
}
- (BOOL) isEnabled
{
    return !(svFlags.disabled);
}
- (BOOL) isOptimizedForSpeed
{
    return !(svFlags.notOptimizedForSpeed);
}
- (BOOL) isPlayable
{
    if (!sound) return NO;
    return YES;/* hmmm. What is required here? */
}
- (BOOL) drawsCrosses
{
    return svFlags.drawsCrosses;
}
- (int) getOptThreshold
{
    return optThreshold;
}
- (int) getOptSkip
{
    return optSkip;
}
- (int) getStereoMode
{
    return stereoMode;
}
- (float) getPeakFraction
{
    return peakFraction;
}
- (float) getDefaultRecordTime
{
    return defaultRecordSeconds;
}

- (void) mouseDown: (NSEvent *) theEvent 
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
    int			realStart = ((float) NSMinX(selectionRect) + .1);
    int			realEnd = ((float) NSMaxX(selectionRect) + .1) - 1;
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

    if ( [sound lengthInSampleFrames] <= 0 )
      return;

    /* hmmmmm ..... */

    /* invalidate previous selection rect */

    if (selCacheRect.size.width > 0.) {
      [self setNeedsDisplayInRect:selCacheRect];
    }

    if ([theEvent clickCount] == 3) {
            [self selectAll:self];
            selCacheRect = [self bounds];
            return;
    }

    [self lockFocus];

  /* we're now interested in mouse dragged events */

    [[self window] setAcceptsMouseMovedEvents:YES];

    
    mouseDownLocation = [theEvent locationInWindow];
    mouseDownLocation = [self convertPoint:mouseDownLocation fromView:nil];
    mouseLocation.x--;
    oldx = mouseDownLocation.x;
//	NSLog(@"Converted mouse location - 1 = %g\n",oldx);
    adjSelRect = selectionRect;
    adjSelRect.origin.y = NSMinY([self bounds]);
    adjSelRect.size.height = NSHeight([self bounds]);

    if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
        realStart = realEnd = -1; /* we don't need to remember the old selection */
        adjSelRect.origin.x = (int) ((float) NSMinX(adjSelRect) / (float) reductionFactor);
        adjSelRect.size.width = ((int) ((float) NSMaxX(selectionRect) - 0.9) /
                (float) reductionFactor);

        if ((int) adjSelRect.size.width == ceil(adjSelRect.size.width))
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
          //			NSLog(@"zapping %g to %g\n",NX_X(&adjSelRect),NX_MAXX(&adjSelRect));
	  selectionRect = NSMakeRect(mouseDownLocation.x, 0.0, 0.0, 0.0);
	}
    }

    /* if zero selection, (insertion point) what do we do? */

    else {
      if (NSWidth(selectionRect) > 0.1) {

	hilStart = ((int) ((float) NSMinX(selectionRect) + 0.01) /
		    reductionFactor);
	hilEnd = (((int) ((float) NSMaxX(selectionRect) + 0.01) - 1) /
		  reductionFactor);
	if (oldx < (hilStart + hilEnd) / 2)
	  oldx = hilStart;
	else
	  oldx = hilEnd + 1;
//			NSLog(@"extending selection\n");
      }
      else {
	if (oldx < ((float) NSMinX(selectionRect) / (float) reductionFactor)) {
            oldx = (int) ((float) NSMinX(selectionRect) /
                        (float) reductionFactor) + 1;
        } else {
            oldx = (int) ((float) NSMinX(selectionRect) / (float) reductionFactor);
        }

	//			NSLog(@"zero selection, extending\n");

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
            selPoint.x = (int) NSMaxX([self bounds]);
            mouseLocation.x = selPoint.x - 1;
    //			NSLog(@"max'd mouseLocation: %g\n",mouseLocation.x);
        }

        /* make sure the selection will be entirely visible */
        if (!NSPointInRect(selPoint , visibleRect) &&
                (selPoint.x != NSMaxX(visibleRect))) {
            [[self window] disableFlushWindow];
            [self scrollPointToVisible:selPoint];
            [[self window] enableFlushWindow];
            /*
              NSLog(@"scrolled to: %g %g\n",selPoint.x, selPoint.y);
              NSLog(@"visibleRect: %g %g %g %g\n",NX_X(&visibleRect),
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
                hilStart = NSMinX(adjSelRect);  //				NSLog(@"(0)");
                hilEnd = (float) NSMaxX(adjSelRect) - 1.0;
            }
	    else if (NSMinX(adjSelRect) < hilStart) {/* new start point. need to adjust end? */
                /* if endpoint of selection is within current sel, we must have
                   backtracked right over the current selection, highlighting a new portion,
                   but unhighlighting the latter parts of the old selection.
                 */
    //				NSLog(@"(1)");
                if (NSMaxX(adjSelRect) - 1 >= hilStart) {
                    hilEnd = hilStart - 1;
                }
                hilStart = NSMinX(adjSelRect);
                
            } else if (NSMaxX(adjSelRect) > hilEnd + 1) {
                /* tack on new addition to selection */
                if (NSMinX(adjSelRect) <= hilEnd)
                    hilStart = hilEnd + 1;
                hilEnd = NSMaxX(adjSelRect) -1;//					NSLog(@"(2)");
                
            } else if (NSMinX(adjSelRect) <= hilEnd &&
                    NSMinX(adjSelRect) >= hilStart) {
                /* we have shortened selection, by backtracking from end */
                if (!direction) {
                    hilEnd = NSMinX(adjSelRect) - 1;  //				NSLog(@"(3)");
                }
                /* shorten selection by forward tracking from start */
                else { 
                    hilStart = NSMaxX(adjSelRect);  //					NSLog(@"(4)");
                }
                /* empty selection */
                if (hilEnd < hilStart) {
                    hilStart = hilEnd = -1;  //						NSLog(@"(5)");
                }
            }
	      
    //				else NSLog(@"(6)");
            if (hilStart != -1) {  //							NSLog(@"(7)");
                selectionRect.origin.x = ceil((float) hilStart * (float) reductionFactor);
                selectionRect.size.width = (float) reductionFactor * (float) (hilEnd + 1);

                if ((int) selectionRect.size.width == 
                    ceil(selectionRect.size.width)) {
                    selectionRect.size.width -= 1;
                }

                else {
                    selectionRect.size.width = (int) selectionRect.size.width;
                }
                selectionRect.size.width -= (ceil(reductionFactor * hilStart) - 1);
            }

            else {//				NSLog(@"(8)");
                selectionRect.origin.x = ceil((float) NSMinX(adjSelRect) * (float) reductionFactor);
                selectionRect.size.width = 0;
            }

            /* now check to see if we need to adjust to original values.
	     * First, check to see if initial point has changed. If not, set
	     * original start, and adjust length. If so, discard 'original' point
	     */
    //				NSLog(@"rs %d re %d ",realStart,realEnd);

            if ((realStart != -1) && hilStart == (int) (realStart / reductionFactor)) {
    //				NSLog(@"(9)");
                selectionRect.size.width = ceil((hilEnd + 1) * reductionFactor) - realStart;
                selectionRect.origin.x = realStart;
            }
            else realStart = -1;
            if ((realEnd != -1) && hilEnd == (int) (realEnd / reductionFactor)) {
    //				NSLog(@"(a)");
                selectionRect.size.width = (int) (realEnd - NSMinX(selectionRect)) + 1;
	    }
            else realEnd = -1;

            /* Finally, adjust selection width down to sound size, if it ends on last pixel.
             * When the num of pixels is not a direct multiple of redfact, the calculation
             * for selectionRect, based on the last pixel highlighted, will come out with
             * a figure slightly too high.
             */

            if ((unsigned long) ((float) NSMaxX(selectionRect) + 0.1) > [sound lengthInSampleFrames]) {
                selectionRect.size.width = [sound lengthInSampleFrames] - NSMinX(selectionRect);
            }
    //      NSLog(@"selection changed to %g, %g\n",NX_X(&selectionRect),NX_WIDTH(&selectionRect));
            if (svFlags.continuous) {
                [self tellDelegate:@selector(selectionChanged:)];
            }
        }

    //  NSLog(@"adjselrect start,end %g %g, dx %g, hs %d he %d oldx1 %g ",
    //      NX_X(&adjSelRect), NX_MAXX(&adjSelRect), dx, hilStart, hilEnd, oldx);

        [selectionColour set];
        NSRectFillUsingOperation(adjSelRect, NSCompositeDestinationIn/*NSCompositeSourceOver*/);
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
            NSLog(@"selectionRect:	%5.f:%5.f	%5.f,%5.f\n",
                    (selectionRect.origin.x), (selectionRect.origin.y),
                    (selectionRect.size.width), (selectionRect.size.height));
    
            NSLog(@"adjSelRect:	%5.f:%5.f	%5.f,%5.f\n",
                    adjSelRect.origin.x, adjSelRect.origin.y,
                    adjSelRect.size.width, adjSelRect.size.height);
    
            NSLog(@"lastRect:	%5.f:%5.f	%5.f,%5.f\n",
                    lastRect.origin.x, lastRect.origin.y,
                    lastRect.size.width, lastRect.size.height);
    
            NSLog(@"lastAdjRect:	%5.f:%5.f	%5.f,%5.f\n",
                    lastAdjRect.origin.x, lastAdjRect.origin.y,
                    lastAdjRect.size.width, lastAdjRect.size.height);
            */

            if ( selectionRect.origin.x == lastRect.origin.x ) {//	  NSLog(@"above\n");
                selectDiff.size.width = (lastAdjRect.origin.x -
                                adjSelRect.origin.x) + 
                                lastAdjRect.size.width + 1;

                selectDiff.size.height = adjSelRect.size.height;
                selectDiff.origin.x = adjSelRect.origin.x;
                selectDiff.origin.y = adjSelRect.origin.y;
            }
            else {//	  NSLog(@"below\n");
                selectDiff.size.width = (adjSelRect.origin.x - 
                                lastAdjRect.origin.x) + 2;
                selectDiff.size.height = adjSelRect.size.height;
                selectDiff.origin.x = lastAdjRect.origin.x - 1;
                selectDiff.origin.y = adjSelRect.origin.y;
            }
	/*
            NSLog(@"selectDiff:	%5.f:%5.f	%5.f,%5.f\n\n",
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
        oldx = mouseLocation.x + 1;//		NSLog(@" oldx2: %g\n",oldx);
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
        selectionRect.origin.x = ceil(mouseDownLocation.x * (float) reductionFactor);
        selectionRect.size.width = 0;
    }
//	NSLog(@"FINAL SELECTION %g, %g\n",NX_X(&selectionRect),NX_WIDTH(&selectionRect));
    [[self window] setAcceptsMouseMovedEvents:NO];
    if (reductionFactor < 1) [self setNeedsDisplay:YES]; /* to align to sample boundaries! */

    //    if (NSWidth(selectionRect) < 0.1)  [self showCursor];
    [self tellDelegate:@selector(selectionChanged:)];
}

- (void) pasteboard: (NSPasteboard *) thePasteboard provideDataForType: (NSString *) pboardType
{
    BOOL ret;
    
    /*
     NSLog(@"provide data (SndView): %p type: %s (%s)\n",
	   thePasteboard, pboardType, SndPasteboardType);
     NSLog(@"length %d\n",[sound lengthInSampleFrames]);
     */
    
    //if (!([pboardType isEqualToString: SndPasteboardType] ||
    // [pboardType isEqualToString: PlatformSoundPasteboardType]))
    if (![validPasteboardSendTypes containsObject: pboardType])
	return;
    
    if (pasteboardSound != nil) {
	[pasteboardSound compactSamples];
	
	/*
	 NSLog(@"Pasting size %d %d\n",
	       [pasteboardSound dataSize],
	       [pasteboardSound soundStructSize]);
	 */
	
	/* sound data and full header must be sent to the pasteboard here */
	ret = [thePasteboard setData: [NSData dataWithBytes: (char *) [pasteboardSound soundStruct]
						     length: (int) [pasteboardSound soundStructSize]]
			     forType: pboardType];
	
	notProvidedData = NO;
	
	if (!ret)
	    NSLog(@"Sound paste error\n");
    }
    else
	NSLog(@"nil sound for paste\n");
}

- (void) play: sender
{
    int beginSample = (int) ((float) NSMinX(selectionRect) + 0.1);
    int sampleCount = (int) ((float) NSWidth(selectionRect) + 0.1);

    [self stop: self];
    [sound setDelegate: self];

    if (NSWidth(selectionRect) < 0.1)
        [sound play: self];    
    else
        [sound play: self beginSample: beginSample sampleCount: sampleCount];
}

- (void) pause: sender
{
    int stat;
    
    if (scratchSound) {
        stat = [scratchSound status];
        if (stat == SND_SoundPlaying || stat == SND_SoundPlayingPending) 
                [scratchSound pause];
    }
    if (sound) {
	[sound pause];
    }
    return;
}

- (void) resume: sender
{
    int stat;
    if (scratchSound)  {
        stat = [scratchSound status];
        if (stat == SND_SoundPlayingPaused)
            [scratchSound resume];
    }
    if (sound) {
      [sound resume];
    }
    return;
}

- (void) record: sender
{
#ifdef NEXT_RECORDING_ENABLED
    int df=0,cc=0;
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
	NSLog(@"Input source: Microphone\n");
    else NSLog(@"Input source: LineIn\n");
    NSLog(@"Accepts continuous sampling rate: %s\n", cr ? "YES" : "NO");
#endif
    if (!cr) {
	[theSoundIn getStreamSamplingRates: (const float **) &rates
				     count: (unsigned int *) &numRates];
#ifdef DISPLAY_SOUNDDEVICE_INFO
	for (i = 0; i < numRates; i++) {
	    NSLog(@"Allowable rate: %g\n",rates[i]);
	}
#endif
    }
    else {
	[theSoundIn getStreamSamplingRatesLow: (float *) &lo
					 high: (float *) &hi];
#ifdef DISPLAY_SOUNDDEVICE_INFO
	NSLog(@"Continuous rates allowed from %g to %g\n",lo,hi);
#endif
    }
    ccLimit = [theSoundIn streamChannelCountLimit];
#ifdef DISPLAY_SOUNDDEVICE_INFO
    NSLog(@"Max number of channels: %d\n",ccLimit);
#endif
    [theSoundIn getStreamDataEncodings:
	(const NXSoundParameterTag **) &encodings
				 count: (unsigned int *) &numEncodings];
#ifdef DISPLAY_SOUNDDEVICE_INFO
    for (i = 0; i < numEncodings; i++) {
	NSLog(@"Allowable encoding: %d\n", encodings[i]);
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
	
	if (cc > ccLimit) 
	    cc = ccLimit; /* adjust to number of channels available*/
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
	for (i = 0; i < numEncodings; i++) {
	    int anEncoding = encodings[i];
	    if (anEncoding == NX_SoundStreamDataEncoding_Mulaw8 &&
		df == SND_FORMAT_MULAW_8) formatPossible = YES;
	    else if (anEncoding == NX_SoundStreamDataEncoding_Linear8 &&
		     df == SND_FORMAT_LINEAR_8) formatPossible = YES;
	    else if (anEncoding == NX_SoundStreamDataEncoding_Linear16 &&
		     df == SND_FORMAT_LINEAR_16) formatPossible = YES;
	}
	if (!formatPossible && numEncodings) { 
	    /* if our encoding not there, take best encoding hardware supports and convert later */
	    formatPossible = YES;
	    df = encodings[numEncodings - 1];
	    if (df == NX_SoundStreamDataEncoding_Mulaw8) df = SND_FORMAT_MULAW_8;
	    else if (df == NX_SoundStreamDataEncoding_Linear8) df = SND_FORMAT_LINEAR_8;
	    else if (df == NX_SoundStreamDataEncoding_Linear16) df = SND_FORMAT_LINEAR_16;
	    else formatPossible = NO;
	}
	if (!possible || !formatPossible) {
	    NSLog(@"recording format impossible\n");
	    [theSoundIn release];
	    return;
	}
    }
    else {
	df = defaultRecordFormat;
	cc = defaultRecordChannelCount;
	sr = defaultRecordSampleRate;
    }

    [theSoundIn release]; // this frees the parameters too

    [self stop: self];

    [recordingSound release]; /* just in case */
    recordingSound = [[Snd alloc] initWithFormat: df
				    channelCount: cc
					  frames: defaultRecordSeconds * sr
				    samplingRate: sr];
    //	NSLog(@"df %d sr %d cc %d\n", (int) df, (int) sr, (int) cc);

    // TODO set self as recording delegate.
    [recordingSound record];
#endif /* NEXT_RECORDING_ENABLED */
}

- (void) stop: (id) sender
{
  [sound stop: self];  // TODO should self be sender?
  return;
}

- (float) reductionFactor
{
    return reductionFactor;
}

- (BOOL) setReductionFactor: (float) newReductionFactor
{
    if (svFlags.autoscale) return NO;
    if (!sound) return NO;
    if (newReductionFactor < 0.04) return NO;
    if (reductionFactor != newReductionFactor) [self invalidateCache];
    reductionFactor = newReductionFactor;
    [[self window] disableFlushWindow];

    // [self hideCursor];
    [self sizeToFit];
    // [self showCursor];
    [[self window] enableFlushWindow];
    return YES;
}

- (void) setAmplitudeZoom: (float) newAmplitudeZoom
{
    // Don't allow zero or negative zoom values. 
    if(newAmplitudeZoom > 0.0)
	amplitudeZoom = newAmplitudeZoom;
}

- (float) amplitudeZoom
{
    return amplitudeZoom;
}

/* here I think I must be careful about nil sounds, and 0-length sounds.
* What do I expect to happen if this is the case?
*/
- scaleToFit
{	
    NSRect newFrame = [self frame];
    int sc = [sound lengthInSampleFrames];
    
    if (newFrame.size.width < 1.1) newFrame.size.width = 5; /* at least give a little space! */
    if (sc && sound) reductionFactor = sc / newFrame.size.width;
    [self setFrame: newFrame];
    [self invalidateCache];
    [self setNeedsDisplay: YES];
    return self;
}

- (void) sizeToFit
{
    float aWidth;
    NSRect newFrame = [self frame];
    NSRect zapRect = [self bounds];

    [[self window] disableFlushWindow];

    // [self hideCursor];

    if (!sound)
      aWidth = 5;

    if (![sound lengthInSampleFrames])
      aWidth = 5;
    else {
      aWidth = ([sound lengthInSampleFrames] - 1.0) / reductionFactor;

      if ((int) aWidth == ceil(aWidth))
	aWidth += 1;
      else
	aWidth = ceil(aWidth);
    }

    if (aWidth < newFrame.size.width) {
      zapRect.origin.x = aWidth;
      zapRect = NSIntersectionRect(zapRect, [self visibleRect]);
      
      if (!NSEqualRects(zapRect, NSZeroRect)) {
	[self lockFocus];

#ifndef QUARTZ_RENDERING
	PSsetgray(NSDarkGray);
#else
	[backgroundColour set];
#endif
	NSRectFill(zapRect);

	[self unlockFocus];
      }
    }

    [self setFrameSize: NSMakeSize(aWidth, [self frame].size.height)];
    // [self showCursor];
    [[self window] enableFlushWindow];
    [self setNeedsDisplay: YES];
}

- (void) sizeToFit: (BOOL) withAutoscaling
{
    int sc = [sound lengthInSampleFrames];
    
    float aWidth;
    
    NSRect newFrame = [self frame];
    NSRect zapRect = [self bounds];
    
    [[self window] disableFlushWindow];
    
    // [self hideCursor];
    
    if (!sound)
	aWidth = 5;
    
    if (![sound lengthInSampleFrames])
	aWidth = 5;
    else {
	aWidth = ([sound lengthInSampleFrames] - 1.0) / reductionFactor;
	
	if ((int) aWidth == ceil(aWidth))
	    aWidth += 1;
	else
	    aWidth = ceil(aWidth);
    }
    
    if (aWidth < newFrame.size.width) {
	if (!withAutoscaling) {
	    zapRect.origin.x = aWidth;
	    zapRect = NSIntersectionRect(zapRect,[self visibleRect]);
	    
	    if (!NSEqualRects(zapRect,NSZeroRect)) {
		[self lockFocus];
		
#ifndef QUARTZ_RENDERING
		PSsetgray(NSDarkGray);
#else
		[backgroundColour set];
#endif
		NSRectFill(zapRect);
		
		[self unlockFocus];
	    }
	}
	else { 	/* do autoscaling */
	    /* at least give a little space! */
	    
	    if (newFrame.size.width < 1.1)
		newFrame.size.width = 5;
	    
	    if (sc && sound)
		reductionFactor = sc / newFrame.size.width;
	    
	    [self setFrame: newFrame];
	    [self invalidateCache];
	    [[self window] enableFlushWindow];
	    [self setNeedsDisplay: YES];
	    
	    return;
	}
    }
    
    [self setFrameSize: NSMakeSize(aWidth, [self frame].size.height)];
    // [self showCursor];
    [[self window] enableFlushWindow];
    [self setNeedsDisplay: YES];
}

- setAutoscale: (BOOL) aFlag
{
    svFlags.autoscale = aFlag;
    return self;
}

- (void) setBezeled: (BOOL) aFlag
{
    svFlags.bezeled = aFlag;
    [self setNeedsDisplay:YES];
}

- (void) setContinuous: (BOOL) aFlag
{
    svFlags.continuous = aFlag;
}

- (void) setDelegate: (id) anObject
{
    delegate = anObject;
}

- (void) setDefaultRecordTime: (float) seconds
{
    if (seconds <= 0) defaultRecordSeconds = 0.1;
    else defaultRecordSeconds = seconds;
}

- (void) setEditable: (BOOL) aFlag
{
    svFlags.notEditable = !aFlag;
}

- (void) setEnabled: (BOOL) aFlag
{
    svFlags.disabled = !aFlag;
}

- (void) setOptimizedForSpeed: (BOOL) aFlag
{
    if (aFlag == svFlags.notOptimizedForSpeed && svFlags.notOptimizedForSpeed == aFlag) [self invalidateCache];
    svFlags.notOptimizedForSpeed = !aFlag;
    if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}

- (void) setDrawsCrosses: (BOOL) aFlag
{
    svFlags.drawsCrosses = aFlag;
    if (reductionFactor <= CROSSTHRESH)
	[self setNeedsDisplay: YES];
}

- (void) setOptThreshold: (int) threshold
{
    if (reductionFactor >= optThreshold && optThreshold != threshold) [self invalidateCache];
    optThreshold = threshold;
    if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}

- (void) setOptSkip: (int) skip
{
    if (optSkip != skip && reductionFactor >= optThreshold) [self invalidateCache];
    optSkip = skip;
    if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}

- (void) setPeakFraction: (float) fraction
{
    if (peakFraction != fraction && reductionFactor >= optThreshold) [self invalidateCache];
    peakFraction = fraction;
    if (reductionFactor >= optThreshold) [self setNeedsDisplay:YES];
}

- (BOOL) setStereoMode: (int) aMode
{
    if ((aMode < 0 || aMode > 2) && aMode != SV_STEREOMODE)
	return NO;
    if (stereoMode != aMode)
	[self invalidateCache];
    stereoMode = aMode;
    [self setNeedsDisplay: YES];
    return YES;
}

- (void) setSound: (Snd *) aSound
{
    sound = aSound;
    [self invalidateCache]; /* setSound will always invalidate cache, even if same sound */
    if (!svFlags.autoscale) {
	if (sound && [sound lengthInSampleFrames])
	    reductionFactor = [sound samplingRate] / SOUNDVIEW_SR_REDUCTION; /* to imitate SoundView! */
	else reductionFactor = 1;
	[self sizeToFit];
    }
    else { /* scaleToFit does not autodisplay, but sizeToFit does */
	[self scaleToFit];
	[self setNeedsDisplay: YES];
    }
}

- (Snd *) sound
{
    return sound;
}

/*sb: complicated business here. If a SndView is not in a proper scrollview, and it is set to (for example)
    auto-resize, I assume that it should autoscale (the reduction factor should change).
    Therefore any SndView NOT in a functioning scrollview should have the autoscale flag explicity set.
    The complication is that if you stick a SndView inside a box in InterfaceBuilder, it is given a scrollview,
    but not a "functional" one. Hence the explicit check for autoscale below. Of course, if you have a free-standing
    SndView in a window, it has no scrollview, and I assume that we must autoscale whether explicitly set or not.
*/
- (void) setFrameSize: (NSSize) newSize
{
    if (![self enclosingScrollView] || svFlags.autoscale) {
        int sc = [sound lengthInSampleFrames];
        if (newSize.width < 1.1) newSize.width = 5; /* at least give a little space! */
        if (sc && sound && (newSize.width > 0.0)) reductionFactor = sc / newSize.width;
    }
    [super setFrameSize: newSize];
    [self invalidateCache];
    [self setNeedsDisplay: YES];
    return;
}

- (Snd *) soundBeingProcessed
{
    return scratchSound;
}

- (void) tellDelegate: (SEL) theMessage
{
    if (delegate)
        if ([delegate respondsToSelector: theMessage])
	    [delegate performSelector: theMessage withObject: self];
//  NSLog(@"SndView tellDelegate...\n");
}

// delegations which are nominated per performance.
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance
{
    if (delegate) {
        if ([delegate respondsToSelector:theMessage]) {
            [delegate performSelector:theMessage withObject: self withObject: performance];
        }
    }
}

- (void) willPlay: sender duringPerformance: (SndPerformance *) performance
{
//  NSLog(@"will play\n");
    [self tellDelegate: @selector(willPlay:duringPerformance:) duringPerformance: performance];
    return;
}

- (void) willRecord: sender
{
//  NSLog(@"will record\n");
    [self tellDelegate: @selector(willRecord:)];
    return;
}

- didPlay: sender duringPerformance: (SndPerformance *) performance
{
//  NSLog(@"did play\n");
    [self tellDelegate: @selector(didPlay:duringPerformance:) duringPerformance: performance];
    return self;
}

- didRecord: sender
{
    // [[self window] disableFlushWindow];
    // [self hideCursor]; /* maybe isn't on, but just in case */
    // [[self window] enableFlushWindow];
    
    if (sound && NSWidth(selectionRect) > 0.1) {
        [sound deleteSamplesAt: (int) ((float) NSMinX(selectionRect) + 0.1)
			 count: (int) ((float) NSWidth(selectionRect) + 0.1)];
    }

    if (sound == nil) {
        sound = [[Snd alloc] initWithFormat: [recordingSound dataFormat]
			       channelCount: [recordingSound channelCount]
				     frames: 0
			       samplingRate: [recordingSound samplingRate]];

        if (!svFlags.autoscale)
	    reductionFactor = [recordingSound samplingRate] / SOUNDVIEW_SR_REDUCTION;
        if (!reductionFactor)
	    reductionFactor = 1;
        selectionRect.origin.x = 0;
    }

    if (![recordingSound compatibleWithSound: sound]) {
        [recordingSound convertToFormat: [sound dataFormat]
			   samplingRate: [sound samplingRate]
			   channelCount: [sound channelCount]];
    }
    [sound insertSamples: recordingSound at: (int) ((float) NSMinX(selectionRect) + 0.1)];
    selectionRect.size.width = [recordingSound lengthInSampleFrames];
    
    [recordingSound release];
    recordingSound = nil;
    [self tellDelegate: @selector(didRecord:)];
    [self invalidateCacheStartSample: (int) ((float) NSMinX(selectionRect) + 0.1)
				 end: [sound lengthInSampleFrames]];
    if (!svFlags.autoscale) 
	[self sizeToFit];
    else { /* scaleToFit does not autodisplay, but sizeToFit does */
        [self scaleToFit];
        [self setNeedsDisplay: YES];
    }
    return self;
}

- hadError: sender
{
    NSLog(@"SndView HAD ERROR %d: %@\n", [sender processingError], SndSoundError([sender processingError]));
	return self;
}

- (BOOL) readSelectionFromPasteboard: (NSPasteboard *) pboard
{
    BOOL usedMyOwn = NO, createdSound = NO;
    Snd *pastedSound = nil;
    NSString *theType;

    if (svFlags.notEditable) 
	return YES;

    if (sound)
	if ([sound lengthInSampleFrames] != 0 && ![sound isEditable])
	    return YES;

    theType = [pboard availableTypeFromArray: validPasteboardReturnTypes];

    if (!theType)
	return YES;

    // Caching mechanism to avoid the pasteboard if possible.
    if (lastCopyCount == [pboard changeCount]) {
        pastedSound = pasteboardSound;
        usedMyOwn = YES;
    }
    else {
	// Create a Snd instance from the archived data on the pasteboard.
        NSData *sndData = [pboard dataForType: theType];
	
	// NSLog(@"sound data length %d\n", [sndData length]);
        if (sndData) {
	    pastedSound = [[Snd alloc] initWithData: sndData];
        }
    }

    /*
    [[self window] disableFlushWindow];
    [self hideCursor];
    [[self window] enableFlushWindow];
    */

    if (pastedSound != nil) {
        if (sound != nil) {
            if (![sound compatibleWithSound: pastedSound]) {
                if ([pastedSound convertToFormat: [sound dataFormat]
				    samplingRate: [sound samplingRate]
				    channelCount: [sound channelCount]] != SND_ERR_NONE) {
                    [self tellDelegate:@selector(hadError:)];
		    // [self showCursor];
                    return YES;
		    // TODO do I need to free anything else here?
		}
            }
        }
        if (sound == nil) {
            sound = [[Snd alloc] init];
            createdSound = YES;
            selectionRect.origin.x = selectionRect.size.width = 0;
            if (!svFlags.autoscale)
                reductionFactor = [pastedSound samplingRate] / SOUNDVIEW_SR_REDUCTION;
            if (!reductionFactor)
		reductionFactor = 1;
        }
        if (createdSound || [sound compatibleWithSound: pastedSound]) {
            if (!createdSound && (int) ((float) NSWidth(selectionRect) + 0.1)) {
                [sound deleteSamplesAt: (int) ((float) NSMinX(selectionRect) + 0.1)
                                 count: (int) ((float) NSWidth(selectionRect) + 0.1)];
            }
            if (!createdSound) {
                [sound insertSamples: pastedSound at: (int) selectionRect.origin.x];
                [self invalidateCacheStartSample: (int) selectionRect.origin.x
					     end: [sound lengthInSampleFrames]];
            }
            else {
		[sound release];
		sound = [pastedSound retain];
                [self invalidateCache];
            }
	    selectionRect.origin.x = (int) ((float) NSMinX(selectionRect) + 0.1 + [pastedSound lengthInSampleFrames]);
            selectionRect.size.width = 0;
            if (!svFlags.autoscale)
		[self sizeToFit: YES];
            else { /* scaleToFit does not autodisplay, but sizeToFit does */
                [self scaleToFit];
                [self setNeedsDisplay: YES];
            }
            [self tellDelegate: @selector(soundDidChange:)];
        }
    }
    else 
	NSRunAlertPanel(nil, @"Could not paste sound", nil, nil, nil);
    return YES;
}

/*
 * The usual time for this to be invoked is by the Services menu, which does
 * not actually require data to be placed on the pasteboard immediately. Here,
 * I DO place it on the pasteboard immediately, but maybe should not. Oh well.
 */
- (BOOL) writeSelectionToPasteboard: (NSPasteboard *) thePasteboard types: (NSArray *) pboardTypes
{
    if ([self writeSelectionToPasteboardNoProvide: thePasteboard types: pboardTypes]) {
        [self pasteboard: thePasteboard provideDataForType: SndPasteboardType];
            return YES;
    }
    else
	return NO;
}

- (BOOL) writeSelectionToPasteboardNoProvide: thePasteboard types: (NSArray *) pboardTypes
{
    if (NSWidth(selectionRect) < 0.1) 
	return NO;

    if (!sound)
	return NO;

    if ([sound lengthInSampleFrames] < NSMaxX(selectionRect))
	return NO;

    if (!pasteboardSound) 
	pasteboardSound = [[Snd alloc] init];

    if ([pasteboardSound copySamples: sound
				  at: (int) ((float) NSMinX(selectionRect) + 0.1)
			       count: (int) ((float) NSWidth(selectionRect) + 0.1)] != SND_ERR_NONE) {

	NSLog(@"there was a problem copying samples\n");
	return NO;
    }

    notProvidedData = YES;
    [thePasteboard declareTypes: validPasteboardSendTypes
                          owner: self];	

    lastCopyCount = [thePasteboard changeCount];
    return YES;
}

- validRequestorForSendType: (NSString *) typeSent returnType: (NSString *) typeReturned
{
    if (([SndPasteboardType isEqualToString: typeSent] || typeSent == NULL) &&
	([SndPasteboardType isEqualToString: typeReturned] || typeReturned == NULL) ) {
	
	if ( ((sound && (NSWidth(selectionRect) > 0.1)) || typeSent == NULL) &&
             ((!svFlags.notEditable) || typeReturned == NULL) ) {
            return self;
        }
    }
    return [super validRequestorForSendType: typeSent returnType: typeSent];
}

@end
