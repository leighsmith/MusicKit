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

/* For 250 pixels, on black m68k hardware, user paths take 1.872 s for 100 iterations.
 * Without user paths, the same operations take on average 8.4 seconds!
 * These timings were taken with the NSDate class, bracketed around the
 * drawFromCacheMax:min:fromStart:toEnd:channel: method.
 * For 276 pixels on a 667Mhz G4, user paths take 1.989s for 1000 iterations.
 */
// #define DO_TIMING

#define MOVE_MASK (NSLeftMouseUpMask | NSLeftMouseDraggedMask)

#if defined(NeXT)
#define PlatformSoundPasteboardType @"NXSoundPboardType"
#endif

// debugging
// #define DEBUG_MOUSE(x) NSLog(@"Debug mouse: %@\n", (x))
#define DEBUG_MOUSE(x)
// #define DEBUG_SNDVIEW
// #define DEBUG_SELECTION_DRAWING

#define CURSOR_TIMER_HALF_PERIOD 0.5 // in seconds.
#define CURSOR_WIDTH 1 // in pixels

#define DEFAULT_RECORD_SECONDS 5

#define TENPERCENT 0.05
#define FASTSKIPSTART 29
#define FASTSKIPAMOUNT 8
#define CROSSTHRESH 0.34

// Imitates the SoundView initial reduction factor when divided by the sample rate.
#define SAMPLE_RATE_REDUCTION 184 

// Tried NSCompositeDestinationIn, NSCompositePlusLighter, NSCompositeDestinationOver
// TODO to try: NSCompositeDestinationOut, NSCompositeClear
// This works well if the background is slightly transparent and either light or dark.
#define SELECTION_DRAWING_COMPOSITE NSCompositeDestinationAtop

@implementation SndView

+ (void) initialize
{
    if (self == [SndView class]) {
	[SndView setVersion: (int) 0]; // TODO this should be 1, but because this is in initialize, it screws up the decoded version.
    }
}

- (void) toggleCursor
{
    NSRect cursorRect = [self bounds];
    
    cursorRect.origin.x = (int) ((float) selectedFrames.location / (float) reductionFactor);
    cursorRect.size.width = CURSOR_WIDTH;
    
    if(svFlags.cursorOn) {
	if([self lockFocusIfCanDraw]) {
	    [selectionColour set];
	    NSRectFillUsingOperation(cursorRect, NSCompositeCopy);  // overwrite with cursor since we restore it on next phase of duty cycle.
	    NSHighlightRect(cursorRect);
	    [self unlockFocus];	
	}
    }
    else {
	[self setNeedsDisplayInRect: cursorRect];	
    }

    [[self window] flushWindow];
    svFlags.cursorOn = !svFlags.cursorOn;
}

- hideCursor
{
    if (cursorFlashTimer) {
	[cursorFlashTimer invalidate];
	[cursorFlashTimer release];
	cursorFlashTimer = nil;
	
	// If the cursor is currently off, it means we previously drew a cursor, so force a cleanup.
	if (!svFlags.cursorOn)
	    [self toggleCursor];
	
	svFlags.cursorOn = NO;
    }
    
    return self;
}

- showCursor
{
    if (!cursorFlashTimer) {
	if (selectedFrames.length < 1) {
	    // Start the cursor on so we don't wait a cursor timer half period before we see a cursor - instant gratification.
	    svFlags.cursorOn = YES; 
	    [self toggleCursor];
	    // Blinks the cursor on for the half period, off for the half period
	    cursorFlashTimer = [[NSTimer scheduledTimerWithTimeInterval: CURSOR_TIMER_HALF_PERIOD
								 target: self
							       selector: @selector(toggleCursor)
							       userInfo: self
								repeats: YES] retain];
	}
    }
    
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
    if (selectedFrames.length < 1) return;
    if (!sound) return;
    if ([sound lengthInSampleFrames] < NSMaxRange(selectedFrames)) return;
    if (![sound isEditable]) return;
    if (![self isEditable]) return;
    [sound deleteSamplesInRange: selectedFrames];
    [self invalidateCacheStartSample: selectedFrames.location
				 end: [sound lengthInSampleFrames]];
    selectedFrames.length = 0;
    if (!svFlags.autoscale)
	[self resizeToFit];
    else { /* scaleToFit does not autodisplay, but resizeToFit does */
	[self scaleToFit];
	[self setNeedsDisplay: YES];
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

    selectedFrames = NSMakeRange(0, [sound lengthInSampleFrames]);
    [self setNeedsDisplay: YES];
//  NSLog(@"FINAL SELECTION %u, %u\n", selectedFrames.location, selectedFrames.length);
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
    [self setNeedsDisplay: YES];
}

// TODO this should removed once we can use the Snd method.
// retrieve a sound value at the given frame, for a specified channel, or average over all channels.
// channelNumber is 0 - channelCount to retrieve a single channel, channelCount to average all channels
// SndSampleAtFrame()
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

- (BOOL) invalidateCacheStartSample: (int) start end: (int) end
{
    int startPixel = start / reductionFactor;
    int endPixel = end / reductionFactor;
    
    if (startPixel < 0 || endPixel < startPixel) return NO;
    return [self invalidateCacheStartPixel: startPixel end: endPixel];
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
        theObj = [(NSMutableArray *) dataList objectAtIndex: i];
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
            [theObj truncateToLastPixel: start-1];
            break; /* assume this will be the last cache to consider */
        }
        if (startpix >= start && startpix <= end && endpix > end) {
            /* tail end of cache lies outside region, so we lop off the first part */
            [theObj truncateToFirstPixel: end + 1];
            continue;
        }
        /* only option left: cache encloses region, so we must create new cache
	 * for end, and truncate the first one
	 */
        startOfCache = [theObj startPixel];
        newObj = [[SndDisplayData alloc] init];
        [newObj setPixelDataMax: &[theObj pixelDataMax][end + 1 - startOfCache]
			    min: &[theObj pixelDataMin][end + 1 - startOfCache]
			  count: [theObj endPixel] - end
			  start: end + 1];
        [(NSMutableArray *) dataList insertObject: newObj atIndex: i + 1];
        [theObj truncateToLastPixel: start - 1];
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
    NSRect scaledSelRect;
    
    scaledSelRect.origin.x = (int) ((float) selectedFrames.location / (float) reductionFactor);
    scaledSelRect.size.width = (int) ((NSMaxRange(selectedFrames) - 1) / reductionFactor) - NSMinX(scaledSelRect) + 1;
    
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
		 NSMinX(scaledSelRect),NSMaxX(scaledSelRect));
	 
	 NSLog(@"HIGHLIGHTing rects... %g to %g\n",
		 NSMinX(rects),NX_MAXX(rects));
	 */
	
	highlightRect.origin.x = (int) ((NSMinX(scaledSelRect) >= NSMinX(rects)) ?
					NSMinX(scaledSelRect) : NSMinX(rects));
	
	highlightRect.size.width = (int) (((NSMaxX(scaledSelRect) <= NSMaxX(rects)) ?
					   NSMaxX(scaledSelRect) : NSMaxX(rects) )   - NSMinX(highlightRect) + 0.1);
	
	[selectionColour set];
	
	NSRectFillUsingOperation(highlightRect, SELECTION_DRAWING_COMPOSITE);
	
	// NSHighlightRect(highlightRect);
	// NSLog(@"HIGHLIGHT %g to %g\n",NSMinX(highlightRect), NSMaxX(highlightRect));
    }    
}

// Cache the display data into cacheMinArray, cacheMaxArray.
// We iterate through the pixels and for each, we iterate through a subsampling of the sound data
// in order to determine the maximum and minimum value for each pixel. We access the initial fragment
// of sound data we need to from the first pixel and then we access the subsequent fragments on demand
// since retrieving a fragment may be an expensive operation.
- (void) storeIntoCacheMax: (float *) cacheMaxArray
		  cacheMin: (float *) cacheMinArray
		 fromPixel: (int) startPixel
		   toPixel: (int) endPixel // endPixel
		   channel: (int) whichChannel
{
    int currentPixel;
    int frameCount = [sound lengthInSampleFrames];
    float maxNinety = 0, minNinety = 0, theValue, previousValue = 0;
    float actualBaseF;
    /* for stepping through sound data */
    unsigned long baseFrameOfReductionRegion;
    unsigned long currentFrameWithinReductionRegion;
    BOOL optimize = (!svFlags.notOptimizedForSpeed && reductionFactor > optThreshold);
    int chanCount = [sound channelCount];
    // max point and current counter in current fragmented sound data segment
    unsigned long fragmentLength, currentFrameInFragment; 
    SndSampleFormat dataFormat;
    void *pcmData;
    
    /* set up first read point in sound data from the current pixel */
    actualBaseF = (float) startPixel * reductionFactor;
    if ((int) actualBaseF != ceil(actualBaseF))
	baseFrameOfReductionRegion = ceil(actualBaseF);
    else
	baseFrameOfReductionRegion = (int) (actualBaseF);
    
    currentFrameWithinReductionRegion = baseFrameOfReductionRegion; /* just initialise it for now */
    pcmData = [sound fragmentOfFrame: baseFrameOfReductionRegion
		     indexInFragment: &currentFrameInFragment
		      fragmentLength: &fragmentLength
			  dataFormat: &dataFormat];
    
    // NSLog(@"initial baseFrameOfReductionRegion %d currentFrameInFragment %d fragmentLength %d dataFormat %d\n",
    //   baseFrameOfReductionRegion, currentFrameInFragment, fragmentLength, dataFormat);		    
    // NSLog(@"creating cache from startPixel %d to endPixel %d, pcmData %p\n", startPixel, endPixel, pcmData);

    for (currentPixel = startPixel; currentPixel <= endPixel; currentPixel++) {
	BOOL firstPixel = YES;
	float thisMax = 0.0, thisMin = 0.0;
	
	baseFrameOfReductionRegion = currentPixel * reductionFactor;
		    
	// Check if we've hit the end of the sound, if so, skip retrieving sound data to zero out the remainder of the cache.
	if (baseFrameOfReductionRegion < frameCount) {
	    int skipFrames = 1; // default to examining each sample.
	    // determine the frame corresponding to the sound region to be reduced to a value for the next pixel.
	    unsigned long baseFrameOfNextReductionRegion = baseFrameOfReductionRegion + reductionFactor;
	    
	    // iterate across the reduction region of the sound, determing the extrema. 
	    // We skip skipFrames frames on each iteration to limit the retrieval (i.e display) time.
	    currentFrameWithinReductionRegion = baseFrameOfReductionRegion;
	    while (currentFrameWithinReductionRegion < baseFrameOfNextReductionRegion) {
		if (currentFrameInFragment >= fragmentLength - 1) {
		    pcmData = [sound fragmentOfFrame: currentFrameWithinReductionRegion
				     indexInFragment: &currentFrameInFragment
				      fragmentLength: &fragmentLength
					  dataFormat: &dataFormat];
		    // NSLog(@"currentPixel %d baseFrameOfReductionRegion %d currentFrameWithinReductionRegion %d  baseFrameOfNextReductionRegion %d currentFrameInFragment %d fragmentLength %d dataFormat %d\n",
		    //  currentPixel, baseFrameOfReductionRegion, currentFrameWithinReductionRegion, baseFrameOfNextReductionRegion, currentFrameInFragment, fragmentLength, dataFormat);
		    // NSLog(@"skipFrames = %d\n", skipFrames);
		}
		if (currentFrameWithinReductionRegion < frameCount)
		    theValue = getSoundValue(pcmData, dataFormat, currentFrameInFragment, whichChannel, chanCount);
		else 
		    theValue = 0;
		if (firstPixel) {
		    minNinety = thisMin = theValue;
		    maxNinety = thisMax = theValue;
		    firstPixel = NO;
		}
		else {
		    // determine extrema
		    if (theValue < thisMin) {
			thisMin = theValue;
			if (optimize) 
			    minNinety = thisMin + peakFraction * abs((int) thisMin);
		    }
		    else if (theValue > thisMax) {
			thisMax = theValue;
			if (optimize)
			    maxNinety = thisMax - peakFraction * abs((int) thisMax);
		    }
		}
		// This should be able to be factored outside the loop
		if (optimize) {
		    BOOL directionDown = (theValue < previousValue); /* NO for up, YES for down */

		    if ((!directionDown && (theValue > maxNinety)) || (directionDown && (theValue < minNinety))) {
			skipFrames = 1;			
		    }
		    else {
			// skipFrames = optSkip;
			// Modify skipFrames to keep the number of samples visited constant
			skipFrames = reductionFactor / 20; // 20 = Number of samples per reduction region to sample.
			if(skipFrames < 1) // catch if reductionFactor is less than 20.
			    skipFrames = 1;
		    }
		}
		previousValue = theValue;
		currentFrameInFragment += skipFrames;
		currentFrameWithinReductionRegion += skipFrames;
	    }
	}
	// NSLog(@"cache at %d thisMin %f thisMax %f\n", currentPixel - startPixel, thisMin, thisMax);
	cacheMaxArray[currentPixel - startPixel] = thisMax;
	cacheMinArray[currentPixel - startPixel] = thisMin;
    }     /* 'for' loop over the pixels to be cached. */
}

- (void) retrieveFromCacheIntoMax: (float *) cacheMaxArray 
			      min: (float *) cacheMinArray
			fromStart: (int) startX
			    toEnd: (int) endX
			  channel: (int) whichChannel
{
    SndDisplayData *currentCacheObject;	
    /* for working through caching: */
    int cacheIndex;
    int currStartPoint = startX;
    
    // Main cache loop
    while (currStartPoint <= endX) {
	int nextCache;
	int localMax;
	int leadsOnFrom;
	
	/* following returns leadsOnFrom == YES iff cacheIndex == -1 && (currStartPoint - 1) is in previous cache */
	cacheIndex = [dataList findObjectContaining: currStartPoint
					       next: &nextCache 
					leadsOnFrom: &leadsOnFrom];
	
	if (cacheIndex != -1) { // Copy the dataList cached pixel data into the current cache
	    // int frameIndex;
	    int numToMove, cachedStart;
	    float *maxVals, *minVals;
	    
	    // NSLog(@"Using cached data %d\n", cacheIndex);
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
#if 0
	    for (frameIndex = 0; frameIndex < numToMove; frameIndex++) {
		cacheMaxArray[currStartPoint + frameIndex - startX] = maxVals[frameIndex + currStartPoint - cachedStart];
		cacheMinArray[currStartPoint + frameIndex - startX] = minVals[frameIndex + currStartPoint - cachedStart];
	    }
#else
	    memcpy(cacheMaxArray + currStartPoint - startX, maxVals + currStartPoint - cachedStart, numToMove * sizeof(float));
	    memcpy(cacheMinArray + currStartPoint - startX, minVals + currStartPoint - cachedStart, numToMove * sizeof(float));
#endif	    
	    currStartPoint += numToMove;
	}
	else {
	    // NSLog(@"couldn't find cached data at currStartPoint %d, endX = %d\n", currStartPoint, endX);
	    if (nextCache != -1) {
		localMax = [[(NSMutableArray *) dataList objectAtIndex: nextCache] startPixel] - 1;
		if (localMax > endX)
		    localMax = endX;
	    }
	    else
		localMax = endX;
	    
	    [self storeIntoCacheMax: cacheMaxArray + (currStartPoint - startX)
			   cacheMin: cacheMinArray + (currStartPoint - startX)
			  fromPixel: currStartPoint
			    toPixel: localMax
			    channel: whichChannel];

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
		// NSLog(@"adding to cache: from %d count %d\n", [cacheToExtend endPixel] + 1, localMax - currStartPoint + 1);
	    }
	    else {
		SndDisplayData *newCache = [[SndDisplayData alloc] init];
		
		[newCache setPixelDataMax: &cacheMaxArray[currStartPoint - startX]
				      min: &cacheMinArray[currStartPoint - startX]
				    count: localMax - currStartPoint + 1
				    start: (int) currStartPoint];
		[(NSMutableArray *) dataList addObject: newCache];
		[dataList sort];
		// NSLog(@"setting new cache: start %d count %d\n", currStartPoint, localMax - currStartPoint + 1);
	    }
	    /* now see if we should join up to following cache */
	    cacheIndex = [dataList findObjectContaining: localMax + 1 next: &nextCache leadsOnFrom: &leadsOnFrom];
	    if (cacheIndex != -1 && leadsOnFrom != -1) {
		[[(NSMutableArray *) dataList objectAtIndex: leadsOnFrom] addDataFrom: [(NSMutableArray *) dataList objectAtIndex:cacheIndex]];
		[(NSMutableArray *) dataList removeObjectAtIndex: cacheIndex];
		// NSLog(@"Compacted %d with %d. Now %d caches\n", leadsOnFrom, cacheIndex,[dataList count]);
	    }
	    
	    currStartPoint = localMax + 1;
	}
    } /* while loop for caching */
}

// draw sound amplitude plots from the supplied audio data, where reduction factor is such that we must draw consecutive sample points.
- (void) drawSound: (Snd *) soundToDraw 
	    within: (NSRect) drawWithinRectangle 
	   channel: (int) whichChannel
{
    int lastFrameToDisplay;
    float theValue;
    int firstFrameToDisplay;
    void *pcmData;
    // max point and current counter in current fragged sound data segment
    unsigned long fragmentLength, currentFrameInFragment; 
    int frameCount = [soundToDraw lengthInSampleFrames];
    SndSampleFormat dataFormat;
    int chanCount = [soundToDraw channelCount];
    NSBezierPath *soundPath = [NSBezierPath bezierPath];
    NSPoint nextSoundPixel;
    
    /* first sample */
    firstFrameToDisplay = (int) ((float) NSMinX(drawWithinRectangle) * (float) reductionFactor);
    
    if (firstFrameToDisplay > 0)
        firstFrameToDisplay--;
    
    pcmData = [soundToDraw fragmentOfFrame: firstFrameToDisplay 
			   indexInFragment: &currentFrameInFragment
			    fragmentLength: &fragmentLength
				dataFormat: &dataFormat];

    /* last sample */
    lastFrameToDisplay = (int) ((float) (NSMaxX(drawWithinRectangle)) * (float) reductionFactor) + 1;
    
    if (lastFrameToDisplay >= frameCount)
        lastFrameToDisplay = frameCount - 1;
    
    theValue = getSoundValue(pcmData, dataFormat, currentFrameInFragment, whichChannel, chanCount);
    
    /* establish initial point */
    nextSoundPixel.y = theValue * ampScaler + amplitudeDisplayHeight;    
    nextSoundPixel.x = (float) ((float) firstFrameToDisplay / (float) reductionFactor);
    
    [soundPath moveToPoint: nextSoundPixel];
    
    while (firstFrameToDisplay <= lastFrameToDisplay) {
        if (currentFrameInFragment >= fragmentLength - 1)
	    pcmData = [soundToDraw fragmentOfFrame: firstFrameToDisplay 
				   indexInFragment: &currentFrameInFragment 
				    fragmentLength: &fragmentLength
					dataFormat: &dataFormat];
	
        theValue = getSoundValue(pcmData, dataFormat, currentFrameInFragment, whichChannel, chanCount);

	nextSoundPixel.y = theValue * ampScaler + amplitudeDisplayHeight;
	nextSoundPixel.x = (float) ((float) firstFrameToDisplay / (float) reductionFactor) + 0.5;
	[soundPath lineToPoint: nextSoundPixel];
	
        // Draw crosses if we have zoomed in so far as to pass the cross threshold.
        if (svFlags.drawsCrosses && reductionFactor <= CROSSTHRESH) {
	    NSPoint crossPoint = nextSoundPixel;
	    
	    crossPoint.y -= 4;
	    [soundPath moveToPoint: crossPoint];
	    crossPoint.y += 8;
	    [soundPath lineToPoint: crossPoint];
	    [soundPath moveToPoint: nextSoundPixel];
        }           
        firstFrameToDisplay++;
        currentFrameInFragment++;
    }
    
    [foregroundColour set];
    
    [soundPath stroke];
}

- (void) drawMaxPixels: (float *) maximumPixels 
	     minPixels: (float *) minimumPixels 
	     fromStart: (int) startX
		 toEnd: (int) endX
	       channel: (int) whichChannel
{
    int pixelIndex;
    NSBezierPath *soundPath = [NSBezierPath bezierPath];

    if (displayMode == SND_SOUNDVIEW_WAVE) {
	float maxY1 = maximumPixels[0] * ampScaler + amplitudeDisplayHeight;
	float minY1 = minimumPixels[0] * ampScaler + amplitudeDisplayHeight;
	
	if (endX >= NSWidth([self frame])) {
	    endX = NSWidth([self frame]) - 1;
	}
	
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    NSPoint max2 = { pixelIndex + 0.5, maximumPixels[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight };
	    NSPoint min2 = { pixelIndex + 0.5, minimumPixels[pixelIndex + 1 - startX] * ampScaler + amplitudeDisplayHeight };
	    NSPoint max1 = { pixelIndex + 0.5, maxY1 };
	    NSPoint min1 = { pixelIndex + 0.5, minY1 };
	    
	    [soundPath moveToPoint: max1];
	    [soundPath lineToPoint: min1];
	    
	    /* still one more cached point */
	    
	    if (pixelIndex < endX) {
		/* if part of the line is outside the one before if both points encompass */
		if ((min2.y <= maxY1 && min2.y >= minY1) ||
		    (max2.y >= minY1 && max2.y <= maxY1) ||
		    (max2.y >= maxY1 && min2.y <= minY1)) {
		    maxY1 = max2.y; 
		    minY1 = min2.y;
		    continue;
		}
		
		/* so we draw line from appropriate end, to start of next line */
		if (min2.y > maxY1 && maxY1 != minY1) { /* reverse to top if necessary */
		    NSPoint reverse = { pixelIndex + 0.5, maxY1 };
		    [soundPath moveToPoint: reverse];
		}
		
		NSPoint startOfNextSample = { pixelIndex + 1 + 0.5, (min2.y > maxY1) ? min2.y : max2.y };
		
		[soundPath lineToPoint: startOfNextSample];
		
		maxY1 = max2.y; 
		minY1 = min2.y;
	    }
	}
    }
    else { // Draw the minimum and maximum outline.
	NSPoint startLineFrom = { startX + 0.5, maximumPixels[0] * ampScaler + amplitudeDisplayHeight };
	
	[soundPath moveToPoint: startLineFrom];
	
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    NSPoint nextMaximumPoint = { pixelIndex + 0.5, maximumPixels[pixelIndex - startX] * ampScaler + amplitudeDisplayHeight };
	    [soundPath lineToPoint: nextMaximumPoint];
	}
	
	startLineFrom.y = minimumPixels[0] * ampScaler + amplitudeDisplayHeight;
	[soundPath moveToPoint: startLineFrom];
	
	for (pixelIndex = startX; pixelIndex < endX; pixelIndex++) {
	    NSPoint nextMinimumPoint = { pixelIndex + 0.5, minimumPixels[pixelIndex - startX] * ampScaler + amplitudeDisplayHeight };
	    [soundPath lineToPoint: nextMinimumPoint];
	}
    }

    [foregroundColour set];

    [soundPath stroke];
}

- (void) drawRect: (NSRect) drawWithinRectangle
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
    float *cacheMaxArray, *cacheMinArray;
    
#ifdef DO_TIMING
    NSDate *timeBeforeTest;
    int numTimingPasses;
#endif
        
    insetBounds = [self bounds];
    
    amplitudeDisplayHeight = insetBounds.size.height * 0.5;

    [backgroundColour set];
    
    newRect = NSIntersectionRect(insetBounds, drawWithinRectangle);

#ifdef DEBUG_SNDVIEW
    NSLog(@"drawWithinRectangle %g to %g, size %d\n", NSMinX(drawWithinRectangle), NSMaxX(drawWithinRectangle), (int) NSWidth(drawWithinRectangle));
    NSLog(@"insetBounds %g to %g, size %d\n", NSMinX(insetBounds), NSMaxX(insetBounds), (int) NSWidth(insetBounds));
    NSLog(@"newRect %g to %g, size %d\n", NSMinX(newRect), NSMaxX(newRect), (int) NSWidth(newRect));
    NSLog(@"visibleRect %g to %g, size %d\n", NSMinX([self visibleRect]), NSMaxX([self visibleRect]), (int) NSWidth([self visibleRect]));
#endif
    
    if (firstDraw) {
	NSRectFill([self frame]);
	firstDraw = NO;
    }
    else {
	NSRectFill(newRect);	
    }
    
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
	insetBounds = NSDrawTiledRects([self bounds], drawWithinRectangle, mySides, myGrays, 8);
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
    
    maxAmp = [sound maximumAmplitude];
    ampScaler = amplitudeDisplayHeight / maxAmp;

    // NSLog(@"ampScaler %f, amplitudeZoom %f\n", ampScaler, amplitudeZoom);
    
    // This is an attempt to optimise when the multiplication occurs, but we may be doing
    // more work comparing a float than just multiplying.
    if (amplitudeZoom != 1.0)  
	ampScaler *= amplitudeZoom;
    
    // check to see if user desires L&R channels summed.
    // If so, check to see if there are 2 channels to sum.
    // If sound is mono, just do 'left' (0'th) channel
        
    if (stereoMode == SNDVIEW_STEREOMODE) { // TODO rename for multiple channel sounds.
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
    
    cacheMaxArray = (float *) malloc(sizeof(float) * (NSWidth(drawWithinRectangle) + 3));
    cacheMinArray = (float *) malloc(sizeof(float) * (NSWidth(drawWithinRectangle) + 3));
    
    // NSLog(@"cache array width in samples %g\n", (NSWidth(drawWithinRectangle) + 3));
    
    if (reductionFactor > 1) {
	startX = NSMinX(drawWithinRectangle);
	
	/* we need to draw a line leading to first pixel */
	if (NSMinX(drawWithinRectangle) > 0.9)
	    startX--;
	
	endX = NSMaxX(drawWithinRectangle);
	
	/* we need to draw a line from last pixel */
	if (displayMode == SND_SOUNDVIEW_MINMAX && endX < NSMaxX([self frame]))
	    endX++;

	// retrieve pixel data from cache.
	[self retrieveFromCacheIntoMax: cacheMaxArray
				   min: cacheMinArray
			     fromStart: startX
				 toEnd: endX
			       channel: whichChannel];

#ifdef DO_TIMING
	timeBeforeTest = [NSDate date];
	for (numTimingPasses = 1000; numTimingPasses; numTimingPasses--) {
#endif
	    [self drawMaxPixels: cacheMaxArray
		      minPixels: cacheMinArray
		      fromStart: startX
			  toEnd: endX
			channel: whichChannel];
#ifdef DO_TIMING
	}
	NSLog(@"Timing: walltime %g\n", (float) [[NSDate date] timeIntervalSinceDate: timeBeforeTest]);
#endif
	
    }
    else { /* Don't bother retrieving from the cache here, as it's so quick to grab actual data */
	[self drawSound: sound within: drawWithinRectangle channel: whichChannel];
    }

    free(cacheMaxArray);
    free(cacheMinArray);

    if (selectedFrames.length > 0) {	// redraw the selected region.
	[self drawSelectionRectangleWithin: drawWithinRectangle];
    }
}

- (void) setBackgroundColor: (NSColor *) color
{
    [backgroundColour release];
    backgroundColour = [color copy];
    [self setNeedsDisplay: YES];
}

- (NSColor *) backgroundColor;
{
    return backgroundColour;
}

- (void) setSelectionColor: (NSColor *) color
{
    [selectionColour release];
    selectionColour = [color copy];

    [self setNeedsDisplay: YES];
}

- (NSColor *) selectionColor
{
    return selectionColour;
}

- (void) setForegroundColor: (NSColor *) color
{
    [foregroundColour release];
    foregroundColour = [color copy];
    [self setNeedsDisplay: YES];
}

- (NSColor *) foregroundColor
{
    return foregroundColour;
}

- (void) dealloc
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    
//  NSLog(@"Freeing SndView\n");
    [self tellDelegate: @selector(willFree:)];
    [self hideCursor];

    if ((lastCopyCount == [pboard changeCount]) && notProvidedData) {
        /* i.e. we were the last ones to put something on the pasteboard, but
         * have not provided it yet
         */
        [self pasteboard: pboard provideDataForType: SndPasteboardType];
    }
    [pasteboardSound release];
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

- (void) getSelection: (unsigned int *) firstSample size: (unsigned int *) sampleCount
{
    *firstSample = selectedFrames.location;
    *sampleCount = selectedFrames.length;
}

- (void) setSelection: (int) firstSample size: (int) sampleCount
{
    NSRect scaledSelection;

    //    [self hideCursor];

    scaledSelection.origin.x  = selectedFrames.location / reductionFactor - 1;
    scaledSelection.size.width = selectedFrames.length / reductionFactor + 2;
    scaledSelection.origin.y = 0;
    scaledSelection.size.height = [self bounds].size.height;
    scaledSelection = NSIntersectionRect (scaledSelection, [self visibleRect]);
    if (!NSEqualRects(scaledSelection, NSZeroRect)) 
	[self setNeedsDisplayInRect: scaledSelection];
    
    selectedFrames.location = firstSample;
    selectedFrames.length = sampleCount;
    
    scaledSelection.origin.x  = selectedFrames.location / reductionFactor - 1;
    scaledSelection.size.width = selectedFrames.length / reductionFactor + 2;
    scaledSelection.origin.y = 0;
    scaledSelection.size.height = [self bounds].size.height;
    scaledSelection = NSIntersectionRect (scaledSelection,[self visibleRect]);
    if (!NSEqualRects(scaledSelection, NSZeroRect)) 
	[self setNeedsDisplayInRect: scaledSelection];
}

- (void) initVars
{
    // Some platforms have their own pasteboard type that we can interact with, otherwise we just declare our own.
#ifdef PlatformSoundPasteboardType
    validPasteboardSendTypes = [[NSArray alloc] initWithObjects: SndPasteboardType, PlatformSoundPasteboardType, nil];
    validPasteboardReturnTypes = [validPasteboardSendTypes copy];
#else
    validPasteboardSendTypes = [[NSArray arrayWithObject: SndPasteboardType] retain];
    validPasteboardReturnTypes = [validPasteboardSendTypes copy];
#endif
    
    [NSApp registerServicesMenuSendTypes: validPasteboardSendTypes
			     returnTypes: validPasteboardReturnTypes];
    
    delegate = nil;
    sound = nil;
    pasteboardSound = nil;
    recordingSound = nil;
    dragIcon = nil; // default to visible selection when dragging.
    
    /* set colors */
    // selectionColour = [[NSColor controlHighlightColor] retain];
    selectionColour = [[NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 0.8] retain];
    
    // backgroundColour = [[NSColor controlBackgroundColor] retain];
    backgroundColour = [[NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0] retain];
    
    // foregroundColour = [[NSColor blueColor] retain];//black
    foregroundColour = [[NSColor colorWithCalibratedRed: 0.6 green: 0.25 blue: 1.0 alpha: 0.7] retain];
    
    displayMode = SND_SOUNDVIEW_MINMAX;
    selectedFrames = NSMakeRange(0, 0);
    reductionFactor = 4.0; /* bogus */
    amplitudeZoom = 1.0; // Not bogus!
    dataList = [[SndDisplayDataList alloc] init];
    
    svFlags.disabled = NO;
    svFlags.continuousSelectionUpdates = NO;
    svFlags.cursorOn = NO;
    svFlags.drawsCrosses = 1;
    svFlags.autoscale = NO;
    svFlags.bezeled = NO;
    svFlags.notEditable = NO;
    svFlags.notOptimizedForSpeed = NO;
    optThreshold = FASTSKIPSTART;
    optSkip = FASTSKIPAMOUNT;
    peakFraction = TENPERCENT;
    stereoMode = SNDVIEW_STEREOMODE;
    
    defaultRecordFormat = SND_FORMAT_MULAW_8;
    defaultRecordChannelCount = 1;
    defaultRecordSampleRate = SND_RATE_CODEC;
    defaultRecordSeconds = DEFAULT_RECORD_SECONDS;
    
    lastCopyCount = lastPasteCount = 0;
    cursorFlashTimer = 0;
    notProvidedData = NO;
    noSelectionDraw = NO;
    firstDraw = YES;
    
    selectedFrames.location = selectedFrames.length = 0;
    [self allocateGState]; // attempt speed increase!    
}

- initWithFrame: (NSRect) frameRect
{
    self = [super initWithFrame: frameRect];
    if (self) {
	[self initVars];
    }
    return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    self = [super initWithCoder: aDecoder];
    [self initVars]; // Create default versions and overwrite as necessary.
    
    // Check if decoding a newer keyed coding archive
    if([aDecoder allowsKeyedCoding]) {
	sound = [[aDecoder decodeObjectForKey: @"SndView_sound"] retain];
	delegate = [[aDecoder decodeObjectForKey: @"SndView_delegate"] retain];
	selectedFrames.location = [aDecoder decodeIntForKey: @"SndView_selectionRangeLocation"];
	selectedFrames.length = [aDecoder decodeIntForKey: @"SndView_selectionRangeLength"];
	displayMode = [aDecoder decodeIntForKey: @"SndView_displayMode"];
	reductionFactor = [aDecoder decodeFloatForKey: @"SndView_reductionFactor"];
	[backgroundColour release];
	backgroundColour = [[aDecoder decodeObjectForKey: @"SndView_backgroundColour"] retain];
	[foregroundColour release];
	foregroundColour = [[aDecoder decodeObjectForKey: @"SndView_foregroundColour"] retain];
	[selectionColour release];
	selectionColour = [[aDecoder decodeObjectForKey: @"SndView_selectionColour"] retain];
	// Decode the flags
	svFlags.disabled = [aDecoder decodeBoolForKey: @"SndView_disabled"];
	svFlags.continuousSelectionUpdates = [aDecoder decodeBoolForKey: @"SndView_continuous"];
	svFlags.cursorOn = [aDecoder decodeBoolForKey: @"SndView_cursorOn"];
	svFlags.drawsCrosses = [aDecoder decodeBoolForKey: @"SndView_drawsCrosses"];
	svFlags.autoscale = [aDecoder decodeBoolForKey: @"SndView_autoscale"];
	svFlags.bezeled = [aDecoder decodeBoolForKey: @"SndView_bezeled"];
	svFlags.notEditable = [aDecoder decodeBoolForKey: @"SndView_notEditable"];
	svFlags.notOptimizedForSpeed = [aDecoder decodeBoolForKey: @"SndView_notOptimizedForSpeed"];
		
	// [cursorFlashTimer timerRate: [aDecoder decodeIntForKey: @"SndView_cursorFlashInterval"]];
	optThreshold = [aDecoder decodeIntForKey: @"SndView_optThreshold"];
	optSkip = [aDecoder decodeIntForKey: @"SndView_optSkip"];
	stereoMode = [aDecoder decodeIntForKey: @"SndView_stereoMode"];
	
	peakFraction = [aDecoder decodeFloatForKey: @"SndView_peakFraction"];
	defaultRecordFormat = [aDecoder decodeIntForKey: @"SndView_defaultRecordFormat"];
	defaultRecordChannelCount = [aDecoder decodeIntForKey: @"SndView_defaultRecordChannelCount"];
	defaultRecordSampleRate = [aDecoder decodeDoubleForKey: @"SndView_defaultRecordSampleRate"];
	defaultRecordSeconds = [aDecoder decodeFloatForKey: @"SndView_defaultRecordLength"];
	
	[dataList release];
	dataList = [[aDecoder decodeObjectForKey: @"SndView_dataList"] retain];
	amplitudeZoom = [aDecoder decodeFloatForKey: @"SndView_amplitudeZoom"];
    }
    else { // older serialized archive
	char b1, b2, b3, b4, b5, b6, b7, b8;
	NSRect selectionRect;
	
	sound = [[aDecoder decodeObject] retain];
	delegate = [[aDecoder decodeObject] retain];
	selectionRect = [aDecoder decodeRect];
	selectedFrames.location = selectionRect.origin.x;
	selectedFrames.length = selectionRect.size.width;
	    
	[aDecoder decodeValuesOfObjCTypes: "if", &displayMode, &reductionFactor];
	[backgroundColour release];
	[foregroundColour release];
	[aDecoder decodeValuesOfObjCTypes:  "@@", &backgroundColour, &foregroundColour];
	[aDecoder decodeValuesOfObjCTypes:"cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
	svFlags.disabled = b1;
	svFlags.continuousSelectionUpdates = b2;
	svFlags.cursorOn = b3;
	svFlags.drawsCrosses = b4;
	svFlags.autoscale = b5;
	svFlags.bezeled = b6;
	svFlags.notEditable = b7;
	svFlags.notOptimizedForSpeed = b8;
	
	[aDecoder decodeValuesOfObjCTypes: "iiiifiidf", 
	    &cursorFlashTimer,
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
    [super encodeWithCoder: aCoder];
    // Check if decoding a newer keyed coding archive
    if([aCoder allowsKeyedCoding]) {
	[aCoder encodeObject: sound forKey: @"SndView_sound"];
	[aCoder encodeConditionalObject: delegate forKey: @"SndView_delegate"];
	[aCoder encodeInt: selectedFrames.location forKey: @"SndView_selectionRangeLocation"];
	[aCoder encodeInt: selectedFrames.length forKey: @"SndView_selectionRangeLength"];
	[aCoder encodeInt: displayMode forKey: @"SndView_displayMode"];
	[aCoder encodeFloat: reductionFactor forKey: @"SndView_reductionFactor"];
	[aCoder encodeObject: backgroundColour forKey: @"SndView_backgroundColour"];
	[aCoder encodeObject: foregroundColour forKey: @"SndView_foregroundColour"];
	[aCoder encodeObject: selectionColour forKey: @"SndView_selectionColour"];
	// encode all the flags
	[aCoder encodeBool: svFlags.disabled forKey: @"SndView_disabled"];
	[aCoder encodeBool: svFlags.continuousSelectionUpdates forKey: @"SndView_continuous"];
	[aCoder encodeBool: svFlags.cursorOn forKey: @"SndView_cursorOn"];
	[aCoder encodeBool: svFlags.drawsCrosses forKey: @"SndView_drawsCrosses"];
	[aCoder encodeBool: svFlags.autoscale forKey: @"SndView_autoscale"];
	[aCoder encodeBool: svFlags.bezeled forKey: @"SndView_bezeled"];
	[aCoder encodeBool: svFlags.notEditable forKey: @"SndView_notEditable"];
	[aCoder encodeBool: svFlags.notOptimizedForSpeed forKey: @"SndView_notOptimizedForSpeed"];

	// [aCoder encodeInt: [cursorFlashTimer timerRate] forKey: @"SndView_cursorFlashInterval"];
	[aCoder encodeInt: optThreshold forKey: @"SndView_optThreshold"];
	[aCoder encodeInt: optSkip forKey: @"SndView_optSkip"];
	[aCoder encodeInt: stereoMode forKey: @"SndView_stereoMode"];
	
	[aCoder encodeFloat: peakFraction forKey: @"SndView_peakFraction"];
	[aCoder encodeInt: defaultRecordFormat forKey: @"SndView_defaultRecordFormat"];
	[aCoder encodeInt: defaultRecordChannelCount forKey: @"SndView_defaultRecordChannelCount"];
	[aCoder encodeDouble: defaultRecordSampleRate forKey: @"SndView_defaultRecordSampleRate"];
	[aCoder encodeFloat: defaultRecordSeconds forKey: @"SndView_defaultRecordLength"];
	[aCoder encodeObject: dataList forKey: @"SndView_dataList"];
	[aCoder encodeFloat: amplitudeZoom forKey: @"SndView_amplitudeZoom"];
    }
    else { // older serialized archiving.
	char b1, b2, b3, b4, b5, b6, b7, b8;

	[aCoder encodeObject: sound];
	[aCoder encodeConditionalObject: delegate];
	[aCoder encodeValuesOfObjCTypes: "uu", &selectedFrames.location, &selectedFrames.length];
	[aCoder encodeValuesOfObjCTypes: "if", &displayMode, &reductionFactor];
	[aCoder encodeValuesOfObjCTypes: "@@", &backgroundColour, &foregroundColour];
	b1 = svFlags.disabled;
	b2 = svFlags.continuousSelectionUpdates;
	b3 = svFlags.cursorOn;
	b4 = svFlags.drawsCrosses;
	b5 = svFlags.autoscale;
	b6 = svFlags.bezeled;
	b7 = svFlags.notEditable;
	b8 = svFlags.notOptimizedForSpeed;
	[aCoder encodeValuesOfObjCTypes: "cccccccc", &b1, &b2, &b3, &b4, &b5, &b6, &b7, &b8];
	[aCoder encodeValuesOfObjCTypes: "iiiifiidf",
	    &cursorFlashTimer,
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
}

- (BOOL) isAutoScale
{
    return svFlags.autoscale;
}

- (BOOL) isBezeled
{
    return svFlags.bezeled;
}

- (BOOL) isContinuousSelectionUpdates
{
    return svFlags.continuousSelectionUpdates;
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

- (enum SndViewStereoMode) getStereoMode
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

// Return the rectangle in pixels constituting the selected range of frames.
- (NSRect) selectionRect
{
    NSRect selectionRect;
    
    selectionRect.origin.x = (int) ((float) selectedFrames.location / (float) reductionFactor);
    selectionRect.size.width = (int) ((float) selectedFrames.length / (float) reductionFactor);
    selectionRect.origin.y = NSMinY([self bounds]); // extend the y selection to the bounds of the view.
    selectionRect.size.height = NSHeight([self bounds]);
    
    if ((int) selectionRect.size.width == ceil(selectionRect.size.width))
	selectionRect.size.width += 1;
    else 
	selectionRect.size.width = ceil(selectionRect.size.width);
    return selectionRect;
}

- (void) setDragIcon: (NSImage *) newDragIcon
{
    [dragIcon release];
    dragIcon = [newDragIcon retain];
}

- (NSImage *) dragIcon
{
    return [[dragIcon retain] autorelease];
}

// generate an NSImage from the visible selected region of the view.
- (NSImage *) dragImageFromSelection
{
    // TODO This isn't correct with scrollable SndViews, needs fixing.
    NSRect selectionVisible = NSIntersectionRect([self visibleRect], [self selectionRect]);
    /* create an empty image of the size of the visible selection. */
    NSImage *dragImage = [[NSImage alloc] initWithSize: selectionVisible.size];
    
    // lock focus on the image so that drawing happens into the image
    [dragImage lockFocus];
    // tell the view to draw itself in the appropriate rectangle
    [self drawRect: selectionVisible];
    // unlock focus from the image to make sure the next drawing does _not_ get done into it.
    [dragImage unlockFocus];
    return [dragImage autorelease];
}

- (void) mouseDragged: (NSEvent *) theEvent
{
    // Determine the location on the keyboard, which key that is being dragged.
    // Locates the cursor's hot spot in the coordinate system of the receiver's NSWindow.
    // Convert it to the NSView's coordinate system.
    NSPoint mouseLocation = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    BOOL isInside = [self mouse: mouseLocation inRect: [self bounds]];
    
    if(isInside) {
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	
	// Write data to the pasteboard
	if ([self writeSelectionToPasteboardNoProvide: pboard types: nil]) {
	    // I dunno why, but the example code subtracts 16 off the mouse location, presumably to compensate
	    // the hot spot for a flipped coordinate axis?
	    mouseLocation.x -= 16;
	    mouseLocation.y -= 16;
	    [self dragImage: dragIcon == nil ? [self dragImageFromSelection] : dragIcon
			 at: mouseLocation
		     offset: NSZeroSize
		      event: theEvent
		 pasteboard: pboard
		     source: self
		  slideBack: YES];
	}
    }
}

#if 0
- selectionDragged: (NSEvent *) currentEvent
//	 fromPoint: oldx
{
}
#endif

// Default operation is to inform the delegate. This allows subclasses to know when selections change.
- (void) selectionChanged
{
    [self tellDelegate: @selector(selectionChanged:)];    
}

// TODO check if this can be unified with drawSelectionRectangleWithin:
- (void) drawSelectedRegionRect: (NSRect) selectedRegionRect
	   previousSelectedRect: (NSRect) previousSelectedRegionRect
{
    /* if we have backtracked, invalidate rects that have been selected during this drag for redraw. */
    if (selectedFrames.length < previousSelectedFrames.length || 
	(selectedFrames.location >= previousSelectedFrames.location + previousSelectedFrames.length && previousSelectedFrames.length != 0)) {
	NSRect invalidateRect;
	
#ifdef DEBUG_SELECTION_DRAWING
	if(selectedFrames.location >= previousSelectedFrames.location + previousSelectedFrames.length)
	    NSLog(@"Jumped ahead of the end of the selection\n");
	NSLog(@"selectedRegionRect:         %5.f:%5.f %5.f,%5.f\n",
	      selectedRegionRect.origin.x, selectedRegionRect.origin.y,
	      selectedRegionRect.size.width, selectedRegionRect.size.height);
	
	NSLog(@"previousSelectedRegionRect: %5.f:%5.f %5.f,%5.f\n",
	      previousSelectedRegionRect.origin.x, previousSelectedRegionRect.origin.y,
	      previousSelectedRegionRect.size.width, previousSelectedRegionRect.size.height);
#endif
	
	// Check if we are changing the length only, if so we know we are ahead of the start frame of the selection, moving the end of the selection.
	if (selectedFrames.location == previousSelectedFrames.location) {
	    // DEBUG_MOUSE(@"ahead of selection start frame, changing end of selection");
	    invalidateRect.size.width = (previousSelectedRegionRect.origin.x - selectedRegionRect.origin.x) + previousSelectedRegionRect.size.width + 1;
	    invalidateRect.origin.x = selectedRegionRect.origin.x;
	}
	else { 
	    // If we drag the end of selection past the beginning (typically by dragging quickly), then the location will differ from the 
	    // previousSelectedRegionRect's location.
	    if(selectedRegionRect.origin.x < previousSelectedRegionRect.origin.x) {
		// DEBUG_MOUSE(@"dragged end of selection past beginning");
		invalidateRect.size.width = (previousSelectedRegionRect.origin.x - selectedRegionRect.origin.x) + 2;
		invalidateRect.origin.x = selectedRegionRect.origin.x - 1;
	    }
	    else { // if the location changes and we didn't cross the end past the beginning, we are therefore 
		// moving the beginning of the selection.
		// DEBUG_MOUSE(@"before the selection start frame, changing start of selection");
		invalidateRect.size.width = (selectedRegionRect.origin.x - previousSelectedRegionRect.origin.x) + 2;
		// If we jumped ahead of the end of the selection, we need to invalidate the current selection width also.
		if(selectedFrames.location >= previousSelectedFrames.location + previousSelectedFrames.length)
		    invalidateRect.size.width += selectedRegionRect.size.width;
		invalidateRect.origin.x = previousSelectedRegionRect.origin.x - 1;
	    }
	    
	}
	invalidateRect.size.height = selectedRegionRect.size.height;
	invalidateRect.origin.y = selectedRegionRect.origin.y;
#ifdef DEBUG_SELECTION_DRAWING
	NSLog(@"invalidateRect:             %5.f:%5.f %5.f,%5.f\n",
	      invalidateRect.origin.x, invalidateRect.origin.y,
	      invalidateRect.size.width, invalidateRect.size.height);
#endif
	invalidateRect = NSIntersectionRect(invalidateRect, [self bounds]); // clip within the window bounds.
	noSelectionDraw = YES;
	[self setNeedsDisplayInRect: invalidateRect];
	noSelectionDraw = NO;
#if 0 // DEBUG_SELECTION_DRAWING
	[[NSColor redColor] set];
	NSFrameRect(invalidateRect);
	[[NSColor blueColor] set];
	NSFrameRect(selectedRegionRect);
#endif
    }

#ifdef DEBUG_SELECTION_DRAWING
    NSLog(@"selectedRegionRect (%g, %g)\n", selectedRegionRect.origin.x, selectedRegionRect.size.width);
    NSLog(@"selectedFrames:             %5u %5u\n",
	  selectedFrames.location, selectedFrames.length);
    
    NSLog(@"previousSelectedFrames:     %5u %5u\n",
	  previousSelectedFrames.location, previousSelectedFrames.length);
#endif
    
    [selectionColour set];
    NSRectFillUsingOperation(selectedRegionRect, SELECTION_DRAWING_COMPOSITE);
    
    /* adjust the size of cachedSelectionRect to be the size of the union of cachedSelectionRect and selectedRegionRect */
    cachedSelectionRect = NSUnionRect(cachedSelectionRect, selectedRegionRect);
}

- (void) mouseDown: (NSEvent *) theEvent 
{
    NSPoint timerMouseLocation;
    BOOL useTimerLocation = NO;
    BOOL scrolled = NO;
    BOOL timer = NO;
    BOOL forwardDirection;
    float dx = 0; // change in x coordinate from each drag
    NSRect previousSelectedRegionRect;
    // The selection rectangle, adjusted by the dragging.
    NSRect draggedSelectionRect = [self selectionRect];
    NSRect currentSelectionRect;
    
    NSEvent *currentEvent;
    
    NSPoint mouseDownLocation;
    float oldx = 0;
    int hilightStartPixel = -1, hilightEndPixel = -1; /* which pixels are currently highlighted */
    int realStartFrame = selectedFrames.location;
    int realEndFrame = NSMaxRange(selectedFrames) - 1;
    BOOL clickedWithinPreviousSelection = NO;
    
    /* in order to preserve the start and end points of a selection when
     * only the 'other' end is moved, we keep the original values here.
     * This is important because the original endpoints may not lie on
     * pixel boundaries when reductionFactor > 1.
     * When we are about to change the endpoints, we check to see if the
     * 'changed' start or end has moved away from the original value. If so,
     * we discard the remembered value. If not, we keep it.
     */
    
    /* if the Control key isn't down, show normal behavior */
    // if (!(theEvent->flags & NSControlKeyMask)) {
    // return [super mouseDown:theEvent];
    // }
    
    [self hideCursor];
    
    [[self window] makeFirstResponder: self];
    
    /* so nothing can be highlighted etc if there is no sound or its empty. */
    if (sound == nil)
	return;
    
    if ([sound lengthInSampleFrames] <= 0)
	return;
    
    // Allow selecting the entire sound by triple clicking in the window.
    if ([theEvent clickCount] == 3) {
	[self selectAll: self];
	cachedSelectionRect = [self selectionRect];
	return;
    }
        
    mouseDownLocation = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    oldx = mouseDownLocation.x;
    // NSLog(@"Converted mouse location - 1 = %g\n",oldx);
    
    currentSelectionRect = [self selectionRect];
    
    // Check to append to the region selected if shift key pressed.
    if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
	// Shift key not pressed, starting a new selection.
        realStartFrame = realEndFrame = -1; /* we don't need to remember the old selection */
	
	// Invalidate previous selection rect if the mouse is clicked outside the previous selection. 
        clickedWithinPreviousSelection = NSPointInRect(mouseDownLocation, currentSelectionRect);
	//NSLog(@"clicked within previous selection %d mouseDownLocation %f currentSelectionRect %f %f\n", 
	//      clickedWithinPreviousSelection, mouseDownLocation.x, currentSelectionRect.origin.x, currentSelectionRect.size.width);
	// If it's clicked within a selection, not a cursor, we don't update until after the release of the drag.
	if (selectedFrames.length > 0) {
	    //NSLog(@"cachedSelectionRect.origin.x = %f cachedSelectionRect.size.width = %f selection.location = %d selection.length = %d\n",
	    //      cachedSelectionRect.origin.x, cachedSelectionRect.size.width, selectedFrames.location, selectedFrames.length);
	    if(!clickedWithinPreviousSelection) {
		DEBUG_MOUSE(@"clicked outside previous selection, setting setNeedsDisplayInRect\n");
		[self setNeedsDisplayInRect: cachedSelectionRect];
	    }
	    // If we have clicked within the existing selection, we either wish to drag a sound (on the drag pasteboard)
	    // or to cancel the selection (if releasing the mouse without dragging). These two cases are covered by
	    // mouseDragged: and mouseUp: respectively, we just need to early exit to not manage mouse dragging.
	    else {
		DEBUG_MOUSE(@"clicked within previous selection, waiting for drag\n");
		return;
	    }	    
	} 	
	
	// Now erase current selection range and highlighted pixels.
        if (selectedFrames.length > 0) {
	    /* remember our rect for future erasure */
	    cachedSelectionRect = currentSelectionRect;
	    selectedFrames = NSMakeRange(0, 0); // reset our selection range before redrawing.
	    [self setNeedsDisplayInRect: currentSelectionRect]; 
	}
    }
    else { // Shift key pressed
	// - appendSelection
	/* if zero selection, (insertion point) what do we do? */
	if (selectedFrames.length > 0) {
	    hilightStartPixel = ((int) ((float) selectedFrames.location + 0.01) / reductionFactor);
	    hilightEndPixel = (((int) ((float) NSMaxRange(selectedFrames) + 0.01) - 1) / reductionFactor);
	    if (oldx < (hilightStartPixel + hilightEndPixel) / 2)
		oldx = hilightStartPixel;
	    else
		oldx = hilightEndPixel + 1;
	    DEBUG_MOUSE(@"extending selection");
	}
	else {
	    if (oldx < ((float) selectedFrames.location / (float) reductionFactor)) {
		oldx = (int) ((float) selectedFrames.location / (float) reductionFactor) + 1;
	    } 
	    else {
		oldx = (int) ((float) selectedFrames.location / (float) reductionFactor);
	    }
	    DEBUG_MOUSE(@"zero selection, extending");
	}
    }
    
    // [self selectionDragged: theEvent]
    currentEvent = theEvent;
    
    // Manage dragging to modify selection range
    [self lockFocus];
    
    /* we're now interested in mouse dragged events */
    [[self window] setAcceptsMouseMovedEvents: YES];
    
    // Start the previous selection range the same so the first test is valid.
    previousSelectedFrames = selectedFrames;
    
    /***************************************/
    /******** START MAIN MOUSE LOOP ********/
    /***************************************/
    // iterate through mouse events until the left mouse button is released.
	
    while ([currentEvent type] != NSLeftMouseUp) {
	NSPoint mouseLocation;
	NSRect visibleRect;
	NSPoint selPoint; // starting point for a dragged selection.
	
        visibleRect = [self visibleRect];
	mouseLocation = !useTimerLocation ? [currentEvent locationInWindow] : timerMouseLocation;
	// mouse coordinates now in view coordinates.
        mouseLocation = [self convertPoint: mouseLocation fromView: nil];
        selPoint = mouseLocation;
	
	/* selPoint needs to be 'correct' for scrolling but actual selection is -1 */
        mouseLocation.x--;
	
        if (mouseLocation.x < -1) {
            mouseLocation.x = -1;
            selPoint.x = 0;
        }
        if (selPoint.x >= NSMaxX([self bounds])) {
            selPoint.x = (int) NSMaxX([self bounds]);
            mouseLocation.x = selPoint.x - 1;
	    // NSLog(@"max'd mouseLocation: %g\n",mouseLocation.x);
        }
	
        /* make sure the selection will be entirely visible */
        if (!NSPointInRect(selPoint, visibleRect) && (selPoint.x != NSMaxX(visibleRect))) {
            [[self window] disableFlushWindow];
            [self scrollPointToVisible: selPoint];
            [[self window] enableFlushWindow];
#if 0
	     NSLog(@"scrolled to: %g %g\n", selPoint.x, selPoint.y);
	     NSLog(@"visibleRect: %g %g %g %g\n", NSMinX(visibleRect), NSMinY(visibleRect), NSWidth(visibleRect), NSHeight(visibleRect));
#endif
            /* note that we scrolled and start generating timer events for autoscrolling */
            scrolled = YES;
	    if (!timer) {
		timer = YES;
		[NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.01];
	    }
        }
        else { /* no scrolling, so stop any timer */
	    if (timer) {
		[NSEvent stopPeriodicEvents];
		timer = NO;
	    }
        }
	
        dx = mouseLocation.x - oldx + 1;
        forwardDirection = (dx > 0);
        draggedSelectionRect.origin.x = mouseLocation.x - dx + 1;
	
        if (dx < 0) {
            dx = -dx;
            draggedSelectionRect.origin.x -= dx;
        }
        draggedSelectionRect.size.width = dx;
		
        if (NSMinX(draggedSelectionRect) < 0) {
            draggedSelectionRect.size.width += NSMinX(draggedSelectionRect);
            draggedSelectionRect.origin.x = 0;
        }
		
        if (dx) { // dragged mouse by dx pixels
            if (hilightStartPixel == -1) {
		DEBUG_MOUSE(@"0: No new highlight start");
                hilightStartPixel = NSMinX(draggedSelectionRect);  
                hilightEndPixel = (float) NSMaxX(draggedSelectionRect) - 1.0;
            }
	    else if (NSMinX(draggedSelectionRect) < hilightStartPixel) { /* new start point. need to adjust end? */
                /* if endpoint of selection is within current sel, we must have
		 * backtracked right over the current selection, highlighting a new portion,
		 * but unhighlighting the latter parts of the old selection.
		 */
                DEBUG_MOUSE(@"1: tack on new addition to selection from start");
                if (NSMaxX(draggedSelectionRect) - 1 >= hilightStartPixel) {
                    hilightEndPixel = hilightStartPixel - 1;
                }
                hilightStartPixel = NSMinX(draggedSelectionRect);
            } 
	    else if (NSMaxX(draggedSelectionRect) > hilightEndPixel + 1) {
                /* tack on new addition to selection */
                if (NSMinX(draggedSelectionRect) <= hilightEndPixel)
                    hilightStartPixel = hilightEndPixel + 1;
                hilightEndPixel = NSMaxX(draggedSelectionRect) -1;
		DEBUG_MOUSE(@"2: tack on new addition to selection to end");
            }
	    else if (NSMinX(draggedSelectionRect) <= hilightEndPixel && NSMinX(draggedSelectionRect) >= hilightStartPixel) {
                /* we have shortened selection, by backtracking from end */
                if (!forwardDirection) {
		    DEBUG_MOUSE(@"3: shortened selection, by backtracking from end");
                    hilightEndPixel = NSMinX(draggedSelectionRect) - 1;
                }
                /* shorten selection by forward tracking from start */
                else { 
		    DEBUG_MOUSE(@"4: shorten selection by forward tracking from start");
                    hilightStartPixel = NSMaxX(draggedSelectionRect);
                }
                /* empty selection */
                if (hilightEndPixel < hilightStartPixel) {
		    DEBUG_MOUSE(@"5: empty selection");
                    hilightStartPixel = hilightEndPixel = -1;
                }
            }
	    else
		DEBUG_MOUSE(@"6: Fell through all tests, shouldn't happen");
	    
            if (hilightStartPixel != -1) {  
		DEBUG_MOUSE(@"7: Modify the selection record with new highlight region");
                selectedFrames.location = ceil((float) hilightStartPixel * (float) reductionFactor);
                selectedFrames.length = (float) reductionFactor * (float) (hilightEndPixel + 1);
		selectedFrames.length -= (ceil(reductionFactor * hilightStartPixel) - 1);
            }
            else {
		DEBUG_MOUSE(@"8");
                selectedFrames.location = ceil((float) NSMinX(draggedSelectionRect) * (float) reductionFactor);
                selectedFrames.length = 0;
            }
	    
            /* now check to see if we need to adjust to original values.
	     * First, check to see if initial point has changed. If not, set
	     * original start, and adjust length. If so, discard 'original' point
	     */
	    // NSLog(@"rs %d re %d ", realStartFrame, realEndFrame);
	    
            if ((realStartFrame != -1) && hilightStartPixel == (int) (realStartFrame / reductionFactor)) {
		DEBUG_MOUSE(@"9");
                selectedFrames.length = ceil((hilightEndPixel + 1) * reductionFactor) - realStartFrame;
                selectedFrames.location = realStartFrame;
            }
            else
		realStartFrame = -1;
            if ((realEndFrame != -1) && hilightEndPixel == (int) (realEndFrame / reductionFactor)) {
		DEBUG_MOUSE(@"10");
                selectedFrames.length = (unsigned int) (realEndFrame - selectedFrames.location) + 1;
	    }
            else 
		realEndFrame = -1;
	    
            /* Finally, adjust selection width down to sound size, if it ends on last pixel.
 	     * When the num of pixels is not a direct multiple of reduction factor, the calculation
	     * for selectedFrames, based on the last pixel highlighted, will come out with
	     * a figure slightly too high.
	     */
	    
            if (NSMaxRange(selectedFrames) > [sound lengthInSampleFrames]) {
                selectedFrames.length = [sound lengthInSampleFrames] - selectedFrames.location;
            }
            // NSLog(@"selection changed to %u, %u\n", selectedFrames.location, selectedFrames.length);
            if (svFlags.continuousSelectionUpdates) {
                [self selectionChanged];
            }
        } // dx != 0

#if 0 // DEBUG_MOUSE
	NSLog(@"dx %g, hilight (%d, %d) oldx %g ",
	      dx, hilightStartPixel, hilightEndPixel, oldx);
#endif

	[self drawSelectedRegionRect: draggedSelectionRect previousSelectedRect: previousSelectedRegionRect];

	/* now show what we've done */
	[[self window] flushWindow];

	// if we autoscrolled, flush any lingering window server events to make the scrolling smooth
	if (scrolled) {
	    scrolled = NO;
	}

	/* save the current mouse location, just in case we need it again */
	oldx = mouseLocation.x + 1;//		NSLog(@" oldx2: %g\n",oldx);
	previousSelectedFrames = selectedFrames;
	previousSelectedRegionRect = draggedSelectionRect;

	mouseLocation = !useTimerLocation ? [currentEvent locationInWindow] : timerMouseLocation;

	if (![[self window] nextEventMatchingMask: MOVE_MASK
					untilDate: [NSDate date]
					   inMode: NSEventTrackingRunLoopMode
					  dequeue: NO]) {
	    
	    /* no mouseMoved or mouseUp event immediately available, so take mouseMoved, mouseUp, or timer */
	    currentEvent = [[self window] nextEventMatchingMask: MOVE_MASK | NSPeriodicMask];
	}
	else { /* get the mouseMoved or mouseUp event in the queue */
	    currentEvent = [[self window] nextEventMatchingMask: MOVE_MASK];
	}

	/* if a timer event, mouse location isn't valid, so we'll set it */
	if ([currentEvent type] == NSPeriodic) {
	    timerMouseLocation = mouseLocation;
	    useTimerLocation = YES;
	}
	else {
	    useTimerLocation = NO;
	}
    } /* while ([currentEvent type] != NSLeftMouseUp) */     // loops until dragging stops (mouse up).

    /*************************************/
    /******** END MAIN MOUSE LOOP ********/
    /*************************************/

    /* mouseUp, so stop any timer and unlock focus */
    if (timer) {
	[NSEvent stopPeriodicEvents];
	timer = NO;
    }
    [self unlockFocus];
    [[self window] setAcceptsMouseMovedEvents: NO];
    
    // if we weren't left with a selection, stick insertion point in new place
    if (selectedFrames.length < 1) {  
	selectedFrames.location = ceil(mouseDownLocation.x * (float) reductionFactor);
	selectedFrames.length = 0;
	/* invalidate previous selection rect */
	if (cachedSelectionRect.size.width > 0.) {
	    DEBUG_MOUSE(@"cachedSelectionRect setNeedsDisplayInRect after selection\n");
	    [self setNeedsDisplayInRect: cachedSelectionRect];
	}	
    }
#if 0
    NSLog(@"FINAL SELECTION start at frame: %u length %u frames\n", selectedFrames.location, selectedFrames.length);
#endif
    if (reductionFactor < 1) 
	[self setNeedsDisplay: YES]; /* to align to sample boundaries! */

    if (selectedFrames.length < 1)
	[self showCursor];
    [self selectionChanged];
}

// This will only get called when mouseDown: returned prematurely because the mouse was clicked within the selection range
// or the user triple clicked the view selecting all the sound. If it wasn't triple clicked, we set the selection range
// for the cursor to be the location clicked.
- (void) mouseUp: (NSEvent *) theEvent
{
    NSPoint mouseDownLocation = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    
    if ([theEvent clickCount] != 3) {
	selectedFrames.location = ceil((float) mouseDownLocation.x * (float) reductionFactor);
	selectedFrames.length = 0; // invalidate the selection region so it becomes a cursor.
    }
    [self showCursor];
    DEBUG_MOUSE(@"mouseUp: setting setNeedsDisplayInRect of cachedSelectionRect\n");
    [self setNeedsDisplayInRect: cachedSelectionRect];
    cachedSelectionRect = [self selectionRect];
}

- (void) pasteboard: (NSPasteboard *) thePasteboard provideDataForType: (NSString *) pboardType
{
    if (![validPasteboardSendTypes containsObject: pboardType])
	return;
    
    if (pasteboardSound != nil) {
	BOOL ret;

	[pasteboardSound compactSamples];
	
	// NSLog(@"provide data (SndView): %@ type: %@ of %@\n",
	//      thePasteboard, pboardType, pasteboardSound);
		
	/* sound data and full header must be sent to the pasteboard here */
	ret = [thePasteboard setData: [pasteboardSound dataEncodedAsFormat: [Snd defaultFileExtension]]
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
    [self stop: self];
    [sound setDelegate: self];

    if (selectedFrames.length < 1)
        [sound play: self];    
    else
        [sound play: self beginSample: selectedFrames.location sampleCount: selectedFrames.length];
}

- (void) pause: sender
{
    if (sound != nil) {
	[sound pause];
    }
}

- (void) resume: sender
{
    if (sound) {
	[sound resume];
    }
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
    [self resizeToFit: NO];
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

- (void) scaleTo: (float) scaleRatio
{	
    NSRect newFrame = [self frame];
    unsigned long lengthInFrames = [sound lengthInSampleFrames];
    NSScrollView *scrollView = [self enclosingScrollView];
    
    if (scrollView) {
//	newFrame = [scrollView documentVisibleRect];
    }
    NSLog(@"autoscale %d visible width %f\n", svFlags.autoscale, [scrollView documentVisibleRect].size.width);
    if (newFrame.size.width < 1.1) newFrame.size.width = 5; /* at least give a little space! */
    NSLog(@"reductionFactor %f lengthInFrames %ld scaleRatio %f newFrame.size.width %f\n", reductionFactor, lengthInFrames, scaleRatio, newFrame.size.width);
    if (lengthInFrames && sound) reductionFactor = lengthInFrames * scaleRatio / newFrame.size.width;
    NSLog(@"reductionFactor %f\n", reductionFactor);
    [self setFrame: newFrame];
    [self invalidateCache];
    [self setNeedsDisplay: YES];
}

/* here I think I must be careful about nil sounds, and 0-length sounds.
* What do I expect to happen if this is the case?
*/
- (void) scaleToFit
{
#if 1
    [self scaleTo: 1.0]; // Scale so the entire sound is within the window
#else
    NSRect newFrame = [self frame];
    int soundLength = [sound lengthInSampleFrames];
    
    if (newFrame.size.width < 1.1) newFrame.size.width = 5; /* at least give a little space! */
    if (soundLength && sound) reductionFactor = soundLength / newFrame.size.width;
    [self setFrame: newFrame];
    [self invalidateCache];
    [self setNeedsDisplay: YES];
#endif
}

- (void) resizeToScale: (float) scaleRatio
{    
    NSScrollView *scrollView = [self enclosingScrollView];
    
    if (scrollView != nil) {
	NSRect visibleRegion = [scrollView documentVisibleRect];
	float newFrameWidth = visibleRegion.size.width / scaleRatio;
    
	NSLog(@"visibleRegion.size.width %f scaleRatio %f newFrameWidth %f\n", visibleRegion.size.width, scaleRatio, newFrameWidth);
	[[self window] disableFlushWindow];
	[self setFrameSize: NSMakeSize(newFrameWidth, [self frame].size.height)];
	[self invalidateCache];
	[[self window] enableFlushWindow];
	[self setNeedsDisplay: YES];    
    }
}

// This changes the frame size so that any enclosing NSScrollView's NSScroller changes.
- (void) resizeToFit: (BOOL) withAutoscaling
{
    unsigned long soundLength = [sound lengthInSampleFrames];
    float pixelWidthOfEntireSound;
    NSRect newFrame = [self frame];
    
    // [[self window] disableFlushWindow];
    
    // [self hideCursor];
    
    if (sound && soundLength) {
	pixelWidthOfEntireSound = (soundLength - 1.0) / reductionFactor;
	
	if ((int) pixelWidthOfEntireSound == ceil(pixelWidthOfEntireSound))
	    pixelWidthOfEntireSound += 1;
	else
	    pixelWidthOfEntireSound = ceil(pixelWidthOfEntireSound);	
    }
    else {
	pixelWidthOfEntireSound = 5;
    }
    
    if (pixelWidthOfEntireSound < newFrame.size.width) {
	if (!withAutoscaling) {
	    NSRect visibleRect = [self visibleRect];
	    
	    // NSLog(@"visible Rect %g %g %g %g\n", NSMinX(visibleRect), NSMinY(visibleRect), NSWidth(visibleRect), NSHeight(visibleRect));
	    // Check if there is space at the end of the sound, if so, set the frame to the visible region.
	    if (pixelWidthOfEntireSound < NSWidth(visibleRect)) {
		// NSLog(@"pixelWidthOfEntireSound %g set frame to visibleRect\n", pixelWidthOfEntireSound);
		[self setFrame: visibleRect];
	    }
	    else {
		// NSLog(@"exiting with new frame pixelWidthOfEntireSound %g wide\n", pixelWidthOfEntireSound);
		[self setFrameSize: NSMakeSize(pixelWidthOfEntireSound, [self frame].size.height)];
	    }
	}
	else { 	/* do autoscaling */
	    /* at least give a little space! */
	    if (newFrame.size.width < 1.1)
		newFrame.size.width = 5;
	    
	    if (soundLength && sound)
		reductionFactor = soundLength / newFrame.size.width;
	    
	    [self setFrame: newFrame];
	    [self invalidateCache];
	}
    }
    else {
	[self setFrameSize: NSMakeSize(pixelWidthOfEntireSound, [self frame].size.height)];
    }

    // [self showCursor];
    // [[self window] enableFlushWindow];
    [self setNeedsDisplay: YES];
}

- (void) resizeToFit
{
    // [self resizeToFit: NO];
    [self resizeToFit: YES];
}

- (BOOL) isEntireSoundVisible
{
    NSScrollView *scrollView = [self enclosingScrollView];
    NSRect visibleFrame = [scrollView documentVisibleRect];
    
    // NSLog(@"frame width %g scrollView visible frame %g\n", [self frame].size.width, visibleFrame.size.width);
    return visibleFrame.size.width > 0 ? [self frame].size.width <= visibleFrame.size.width : YES;
}

- setAutoscale: (BOOL) aFlag
{
    svFlags.autoscale = aFlag;
    return self;
}

- (void) setBezeled: (BOOL) aFlag
{
    svFlags.bezeled = aFlag;
    [self setNeedsDisplay: YES];
}

- (void) setContinuousSelectionUpdates: (BOOL) aFlag
{
    svFlags.continuousSelectionUpdates = aFlag;
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
    if (reductionFactor >= optThreshold) [self setNeedsDisplay: YES];
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
    if (reductionFactor >= optThreshold) [self setNeedsDisplay: YES];
}

- (void) setOptSkip: (int) skip
{
    if (optSkip != skip && reductionFactor >= optThreshold) [self invalidateCache];
    optSkip = skip;
    if (reductionFactor >= optThreshold) [self setNeedsDisplay: YES];
}

- (void) setPeakFraction: (float) fraction
{
    if (peakFraction != fraction && reductionFactor >= optThreshold) [self invalidateCache];
    peakFraction = fraction;
    if (reductionFactor >= optThreshold) [self setNeedsDisplay: YES];
}

- (BOOL) setStereoMode: (enum SndViewStereoMode) aMode
{
    if ((aMode < 0 || aMode > 2) && aMode != SNDVIEW_STEREOMODE)
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
	    reductionFactor = [sound samplingRate] / SAMPLE_RATE_REDUCTION; /* to imitate SoundView! */
	else
	    reductionFactor = 1;
	[self resizeToFit: NO];
    }
    else { /* scaleToFit does not autodisplay, but resizeToFit does */
	[self scaleToFit];
	[self setNeedsDisplay: YES];
    }
}

- (Snd *) soundBeingProcessed
{
    return [self sound];  // basically redundant.
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

LMS: Nowdays we want to rescale to fit the entire sound into the view, regardless of it being a ScrollView or not.
*/
- (void) setFrameSize: (NSSize) newSize
{
    // NSLog(@"reductionFactor = %f newSize = %f,%f\n", reductionFactor, newSize.width, newSize.height);
    //if (![self enclosingScrollView] || svFlags.autoscale) {
        int soundLength = [sound lengthInSampleFrames];
        if (newSize.width < 1.1) newSize.width = 5; /* at least give a little space! */
        if (soundLength && sound && (newSize.width > 0.0)) reductionFactor = soundLength / newSize.width;
    //}
    [super setFrameSize: newSize];
    [self invalidateCache];
    [self setNeedsDisplay: YES];
    return;
}

- (void) tellDelegate: (SEL) theMessage
{
    if (delegate)
        if ([delegate respondsToSelector: theMessage])
	    [delegate performSelector: theMessage withObject: self];
    // NSLog(@"SndView tellDelegate...\n");
}

// delegations which are nominated per performance.
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance
{
    if (delegate) {
        if ([delegate respondsToSelector: theMessage]) {
            [delegate performSelector: theMessage withObject: self withObject: performance];
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
    
    if (sound && selectedFrames.length > 1) {
        [sound deleteSamplesInRange: selectedFrames];
    }

    if (sound == nil) {
        sound = [[Snd alloc] initWithFormat: [recordingSound dataFormat]
			       channelCount: [recordingSound channelCount]
				     frames: 0
			       samplingRate: [recordingSound samplingRate]];

        if (!svFlags.autoscale)
	    reductionFactor = [recordingSound samplingRate] / SAMPLE_RATE_REDUCTION;
        if (!reductionFactor)
	    reductionFactor = 1;
        selectedFrames.location = 0;
    }

    if (![recordingSound compatibleWithSound: sound]) {
        [recordingSound convertToSampleFormat: [sound dataFormat]
			   samplingRate: [sound samplingRate]
			   channelCount: [sound channelCount]];
    }
    [sound insertSamples: recordingSound at: selectedFrames.location];
    selectedFrames.length = [recordingSound lengthInSampleFrames];
    
    [recordingSound release];
    recordingSound = nil;
    [self tellDelegate: @selector(didRecord:)];
    [self invalidateCacheStartSample: selectedFrames.location
				 end: [sound lengthInSampleFrames]];
    if (!svFlags.autoscale) 
	[self resizeToFit];
    else { /* scaleToFit does not autodisplay, but resizeToFit does */
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

    if (![self isEditable]) 
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
                if ([pastedSound convertToSampleFormat: [sound dataFormat]
				    samplingRate: [sound samplingRate]
				    channelCount: [sound channelCount]] != SND_ERR_NONE) {
                    [self tellDelegate: @selector(hadError:)];
		    // [self showCursor];
                    return YES;
		    // TODO do I need to free anything else here?
		}
            }
        }
        if (sound == nil) {
            sound = [[Snd alloc] init];
            createdSound = YES;
            selectedFrames.location = selectedFrames.length = 0;
            if (!svFlags.autoscale)
                reductionFactor = [pastedSound samplingRate] / SAMPLE_RATE_REDUCTION;
            if (!reductionFactor)
		reductionFactor = 1;
        }
        if (createdSound || [sound compatibleWithSound: pastedSound]) {
            if (!createdSound && selectedFrames.length > 0) {
                [sound deleteSamplesInRange: selectedFrames];
            }
            if (!createdSound) {
                [sound insertSamples: pastedSound at: selectedFrames.location];
                [self invalidateCacheStartSample: selectedFrames.location
					     end: [sound lengthInSampleFrames]];
            }
            else {
		[sound release];
		sound = [pastedSound retain];
                [self invalidateCache];
            }
	    selectedFrames.location = selectedFrames.location + [pastedSound lengthInSampleFrames];
            selectedFrames.length = 0;
            if (!svFlags.autoscale)
		[self resizeToFit: YES];
            else { /* scaleToFit does not autodisplay, but resizeToFit does */
                [self scaleToFit];
                [self setNeedsDisplay: YES];
            }
            [self tellDelegate: @selector(soundDidChange:)];
        }
    }
    else {
	NSLog(@"Could not paste sound\n");
	return NO;
    }
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

- (BOOL) writeSelectionToPasteboardNoProvide: (NSPasteboard *) thePasteboard types: (NSArray *) pboardTypes
{
    if (selectedFrames.length < 1) 
	return NO;

    if (!sound)
	return NO;

    if ([sound lengthInSampleFrames] < NSMaxRange(selectedFrames))
	return NO;
    
    [pasteboardSound release];
    pasteboardSound = [[sound soundFromSamplesInRange: selectedFrames] retain];
    if (pasteboardSound == nil) {
	NSLog(@"there was a problem copying samples\n");
	return NO;
    }
    
    [pasteboardSound setName: [[sound name] stringByAppendingString: @" region"]];
    [pasteboardSound setInfo: [pasteboardSound name]]; // TODO kludge to duplicate name to info for transport.

    // NSLog(@"pasteboard sound %@\n", pasteboardSound);
    
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
	
	if ( ((sound && (selectedFrames.length > 0)) || typeSent == NULL) &&
             ((!svFlags.notEditable) || typeReturned == NULL) ) {
            return self;
        }
    }
    return [super validRequestorForSendType: typeSent returnType: typeSent];
}

// Indicates what forms of dragging are allowed, dependent on whether the dragging is local
// (i.e. another SndView) or not.
// If it's local, then we allow rearranging sounds by default (i.e dependent on the destination,
// using NSDragOperationGeneric) and copying sounds if using the modifiers between keys.
// If it's not local, we're dragging onto the file system or another application. In this case we
// always produce copies.
- (NSDragOperation) draggingSourceOperationMaskForLocal: (BOOL) isLocal
{
    // NSLog(@"draggingSourceOperationMaskForLocal: isLocal %d\n", isLocal);
    return isLocal ? NSDragOperationGeneric | NSDragOperationMove | NSDragOperationCopy : NSDragOperationCopy;
}

// To prevent modifiers from altering the mask
- (BOOL) ignoreModifierKeysWhileDragging
{
   return YES;
}

@end
