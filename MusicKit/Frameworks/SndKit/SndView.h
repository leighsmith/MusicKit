/********************************************************************************
$Id$

LEGAL:
This framework and all source code supplied with it, except where specified, are Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use the source code for any purpose, including commercial applications, as long as you reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be error free.  Further, we will not be liable to you if the Software is not fit for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

********************************************************************************/

#ifndef __SNDVIEW_H__
#define __SNDVIEW_H__

#import <AppKit/AppKit.h>
#import "SndKit.h"

#if macosx
#define QUARTZ_RENDERING
#endif

#ifdef QUARTZ_RENDERING
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "SndDisplayDataList.h"
#import "SndDisplayData.h"
#import "Snd.h"

#define SV_LEFTONLY 0
#define SV_RIGHTONLY 1
#define SV_STEREOMODE 256
/* (open the way for up to 8 channel sound) */

#define TENPERCENT 0.05
#define FASTSKIPSTART 29
#define FASTSKIPAMOUNT 8
#define CROSSTHRESH 0.34

#define SND_SOUNDVIEW_MINMAX 0
#define SND_SOUNDVIEW_WAVE 1

#define NX_SOUNDVIEW_MINMAX SND_SOUNDVIEW_MINMAX
#define NX_SOUNDVIEW_WAVE SND_SOUNDVIEW_WAVE

#define DEFAULT_RECORD_SECONDS 5

@interface SndView:NSView
{
    Snd*       	sound;
    Snd* 	_scratchSound;
    Snd*	_pasteboardSound;
    id 		delegate;
    NSRect	selectionRect;
    int		displayMode;

    NSColor	*selectionColour;
    NSColor	*backgroundColour;
    NSColor	*foregroundColour;

    float	reductionFactor;
    struct {
        unsigned int  disabled:1;
        unsigned int  continuous:1;
        unsigned int  cursorOn:1;
        unsigned int  drawsCrosses:1;
        unsigned int  autoscale:1;
        unsigned int  bezeled:1;
        unsigned int  notEditable:1;
        unsigned int  notOptimizedForSpeed:1;
    } svFlags;
    NSTimer 	*teNum; /* for flashing cursor */
    int		optThreshold;
    int		optSkip;
    int		stereoMode;
    float	peakFraction;

    int		defaultRecordFormat;
    int		defaultRecordChannelCount;
    double	defaultRecordSampleRate;
    float	defaultRecordSeconds;
    SndSoundStruct *recordingSound;

    NSRect	selCacheRect;

    int		_lastPasteCount;
    int		_lastCopyCount;
    BOOL 	notProvidedData;
    BOOL	noSelectionDraw;
    BOOL	firstDraw;

    SndDisplayDataList *dataList;
}

- (void)toggleCursor;
- hideCursor;
- showCursor;
- (void)initVars;
- (BOOL)scrollPointToVisible:(const NSPoint)point;
- (BOOL)resignFirstResponder;
- (BOOL)becomeFirstResponder;
- (void)copy:(id)sender;
- (void)cut:(id)sender;
- (void)delete:(id)sender;
- (void)paste:(id)sender;
- (void)selectAll:(id)sender;
- delegate;
- didPlay:sender duringPerformance: performance;
- didRecord:sender;
- (int)displayMode;
- drawSamplesFrom:(int)first to:(int)last;
- (void)drawRect:(NSRect)rects;
- (void)dealloc;
- getSelection:(int *)firstSample size:(int *)sampleCount;
- (void)setSelection:(int)firstSample size:(int)sampleCount;
- hadError:sender;
- initWithFrame:(NSRect)frameRect;
- (BOOL)isAutoScale;
- (BOOL)isBezeled;
- (BOOL)isContinuous;
- (BOOL)isEditable;
- (BOOL)isEnabled;
- (BOOL)isOptimizedForSpeed;
- (BOOL)isPlayable;
- (float)getDefaultRecordTime;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)pasteboard:(NSPasteboard *)thePasteboard provideDataForType:(NSString *)pboardType;
- (void)pause:sender;
- (void)play:sender;
- (void)resume:sender;
- (void)record:sender;
- (void)stop:(id)sender;
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)thePasteboard;
- (float)reductionFactor;
- (BOOL)setReductionFactor:(float)redFactor;
- scaleToFit;
- (void)sizeToFit;
- (void)sizeToFit:(BOOL)withAutoscaling;
- setAutoscale:(BOOL)aFlag;
- (void)setBezeled:(BOOL)aFlag;
- (void)setContinuous:(BOOL)aFlag;
- (void)setDelegate:(id)anObject;
- (void)setDefaultRecordTime:(float)seconds;
- (void)setDisplayMode:(int)aMode; /*NX_SOUNDVIEW_WAVE or NX_SOUNDVIEW_MINMAX*/
- (void)setEditable:(BOOL)aFlag;
- (void)setEnabled:(BOOL)aFlag;
- (void)setOptimizedForSpeed:(BOOL)flag;
- (void)setSound:(Snd *)aSound;
- sound;
- (void)setFrameSize:(NSSize)_newSize;
- soundBeingProcessed;
- (void)tellDelegate:(SEL)theMessage;
- (void)tellDelegate:(SEL)theMessage duringPerformance: performance;
- validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType;
- (void)willPlay:sender duringPerformance: performance;
- (void)willRecord:sender;
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)thePasteboard types:(NSArray *)pboardTypes;
- (BOOL)writeSelectionToPasteboardNoProvide:thePasteboard types:(NSArray *)pboardTypes;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)encodeWithCoder:(NSCoder *)aCoder;


    /*************************
     * these methods are unique
     * to SndKit.
     *************************/

- (BOOL)invalidateCacheStartPixel:(int)start end:(int)end;
	/* if end == -1, invalidates to end of last cache*/
- (BOOL)invalidateCacheStartSample:(int)start end:(int)end;
	/* start and end are samples. Must be exact. */
- (void)invalidateCache; /* convenience method for above */
   /* invalidation: if you change the data of a sound which is being used
    * in a SndView in any way, you must inform the SndView. The easiest message
    * is -invalidateCache, but you can be more specific and tell it the
    * exact sample number with -invalidateCacheStartSample:(int)start end:(int)end
    */

- (void)setDrawsCrosses:(BOOL)aFlag; /* default YES */
    /* see README for explanation of optimisation thresholds and skips, and peak fractions */
- (void)setOptThreshold:(int)threshold;
- (void)setOptSkip:(int)skip;
- (void)setPeakFraction:(float)fraction;
- (BOOL)setStereoMode:(int)aMode;
- (BOOL)drawsCrosses;
- (int)getOptThreshold;
- (int)getOptSkip;
- (int)getStereoMode;
- (float)getPeakFraction;
- (void) setSelectionColor : (NSColor *) color;
- (NSColor *) selectionColor;


/********************************************
    Methods Implemented by the Delegate

    - didPlay:sender duringPerformance: (SndPerformance *) performance
    Sent to the delegate just after the SoundView's sound is played.

    - didRecord:sender
    Sent to the delegate just after the SoundView's sound is recorded into.

    - hadError:sender
    Sent to the delegate if an error is encountered during recording or 
            playback of the SoundView's sound.

    - selectionChanged:sender
    Sent to the delegate when the SoundView's selection changes.

    - soundDidChange:sender
    Sent to the delegate when the SoundView's sound data is edited.

    - willFree:sender
    Sent to the delegate when the SoundView is freed.

    - willPlay:sender duringPerformance: (SndPerformance *) performance
    Sent to the delegate just before the SoundView's sound is played.

    - willRecord:sender
    Sent to the delegate just before the SoundView's sound is recorded into.
********************************************/
@end

#endif
