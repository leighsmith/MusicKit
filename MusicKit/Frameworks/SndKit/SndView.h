////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description: Class defining an AppKit view of a Snd object.
//
//  Original Author: Stephen Brandon
//
//  Design substantially based on ideas from Sound Kit, Release 2.0, Copyright (c) 1988, 1989, 1990, NeXT, Inc.  All rights reserved.
//  Additions Copyright (c) 1999 Stephen Brandon and the University of Glasgow
//  Additions Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Legal Statement Covering Additions by Stephen Brandon and the University of Glasgow:
//
//  This framework and all source code supplied with it, except where specified, are
//  Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use
//  the source code for any purpose, including commercial applications, as long as you
//  reproduce this notice on all such software.
//
//  Software production is complex and we cannot warrant that the Software will be
//  error free.  Further, we will not be liable to you if the Software is not fit
//  for the purpose for which you acquired it, or of satisfactory quality. 
//
//  WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
//  WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
//  OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
//  PARTIES RIGHTS.
//
//  If a court finds that we are liable for death or personal injury caused by our
//  negligence our liability shall be unlimited.  
//
//  WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
//  OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION
//  OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY
//  IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH
//  USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.
//
// Legal Statement Covering Additions by The MusicKit Project:
//
//    Permission is granted to use and modify this code for commercial and
//    non-commercial purposes so long as the author attribution and copyright
//    messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

/*!
 @class SndView

 @abstract SndView is responsible for displaying a amplitude/time plot of Snd data.
 
 @discussion 

A SndView object provides a graphical representation of sound
data. This data is taken from an associated Snd object. In addition
to displaying a Snd object's data, a SndView provides methods that
let you play and record into the Snd object, and perform simple cut,
copy, and paste editing of its data. A cursor into the display is
provided, allowing the user to set the insertion point and to create a
selection over the sound data.

<b>Sound Display</b>

Sounds are displayed on a two-dimensional graph. The amplitudes of
individual samples are measured vertically and plotted against time,
which proceeds left to right along the horizontal axis. A SndView's
coordinate system is scaled and translated (vertically) so full
amplitude fits within the bounds rectangle with 0.0 amplitude running
through the center of the view.

For many sounds, the length of the sound data in samples is greater
than the horizontal measure of the bounds rectangle. A SndView
employs a reduction factor to determine the ratio of samples to
display units and plots the minimum and maximum amplitude values of
the samples within that ratio. For example, a reduction factor of 10.0
means that the minimum and maximum values among the first ten samples
are plotted in the first display unit, the minimum and maximum values
of the next ten samples are displayed in the second display unit and
so on.

Lines are drawn between the chosen values to yield a continuous
shape. Two drawing modes are provided:
<UL>
<LI> In SND_SOUNDVIEW_WAVE mode, the drawing is rendered in an
oscilloscopic fashion.

<LI> In SND_SOUNDVIEW_MINMAX mode, two lines are drawn, one to
connect the maximum values, and one to connect the minimum values.
</UL>

As you zoom in (as the reduction factor decreases), the two drawing
modes become indistinguishable.

<B>Autoscaling the Display</B>

When a SndView's sound data changes (due to editing or recording),
the manner in which the SndView is redisplayed depends on its
<b>autoscale</b> flag. With autoscaling disabled, the SndView's
frame grows or shrinks (horizontally) to fit the new sound data and
the reduction factor is unchanged. If autoscaling is enabled, the
reduction factor is automatically recomputed to maintain a constant
frame size. By default, autoscaling is disabled; this is to
accommodate the use of a SndView object as the document of an
NSScrollView.

<B>Methods Implemented by the Delegate</B>

 - didPlay:sender duringPerformance: (SndPerformance *) performance
 Sent to the delegate just after the SndView's sound is played.

 - didRecord:sender
 Sent to the delegate just after the SndView's sound is recorded into.

 - hadError:sender
 Sent to the delegate if an error is encountered during recording or
 playback of the SndView's sound.

 - selectionChanged:sender
 Sent to the delegate when the SndView's selection changes.

 - soundDidChange:sender
 Sent to the delegate when the SndView's sound data is edited.

 - willFree:sender
 Sent to the delegate when the SndView is freed.

 - willPlay:sender duringPerformance: (SndPerformance *) performance
 Sent to the delegate just before the SndView's sound is played.

 - willRecord:sender
 Sent to the delegate just before the SndView's sound is recorded into.

 <H2>SndView Adds These Features:</H2>
 <UL>
 <LI> Configurable speed optimizations (see below)
 <LI> Non-integer reduction factors (r.f), and r.f. down to 0.04 (1 sample per 25 pixels) [SoundView only goes as low as 1]
 <LI> For 0.04 <= r.f < 0.34, SndView can be instructed to draw small horizontal bars at each sample (this is the default). This allows for great accuracy in specifying selections for copy/paste operations.
 <LI> Configurable maximum recording time
 <LI> Intelligent recording - converts recorded sounds to the format of the rest of the displayed sound if the format is not compatible. Queries hardware for allowable sampling rates/formats [NOT CURRENTLY SUPPORTED ON ANY PLATFORM]
 <LI> Can be instructed to display only left channel, only right channel, or average of both channels
 <LI> Triple-click does a Select-All
 </UL>

 <H2>SndView fixes these bugs:</H2>
 <UL>
 <LI> SndView is not susceptable to the "info length" bug (I think...)
 <LI> SndView copes a lot better with recording into the sound [NOT CURRENTLY SUPPORTED ON ANY PLATFORM]
 <LI> SndView displays "Waveform" view perfectly, without the PostScript errors that plague SoundView
 <LI> SndView is scrupulous about floating point numbers and rounding, and should never leave cursor "turds" on the screen
 <LI> SndView does not alter the length of the selection if you change r.f. Even if you extend the selection at a r.f. different to the one you created the selection at, the sample at the non-changed end will remain the same.
 </UL>

 <H2>SndView has these bugs:</H2>
 <UL>
 <LI> If SndView is destroyed without freeing it, and it has told the pasteboard that it has data ready for pasting (from a Copy or Cut operation) the application that requested the data will probably crash. If the application containing SndView quits normally, SndView does provide the data though (as does SoundView, I think).
 <LI>  With r.f. <= 1, reducing the selection while auto-scrolling leaves a horrible mess on the screen, until you take your finger off the mouse. This is because when a section of the view is drawn, it highlights the part of the new section that it thinks is within the selection rectangle. For r.f <= 1, this is not immediately obvious, and I need to force the start and end of selection rectangle in this case to be midway between samples.
 </UL>

 <H2>SndView is incompatible in these ways:</H2>
 <UL>
 <LI> The bounds rectangle is not scaled the same as SoundView's is. SoundView scales it's bounds so that (y = 0) runs through the centre of the view, and the maximum +y and -y limits
      correspond to the limits of the format of the sound it is displaying. SndView does not scale at all. It could be changed quite easily. As it is, this breaks any subclasses of 
      SoundView that draw into the view.
 <LI> "drawSamples from:to:" is not implemented (yet). But all you would have to do would be to invalidate the caches for that area (if necessary), and -display: the SndView
 <LI> Because of the caching mechanism, if you change samples "behind SndView's back" you must invalidate the cache for the affected samples, with "invalidateCacheStartSample:end:" before displaying.
 <LI> SoundView considers the left and right channels of the sound individually when it comes to finding maximum and minimum values for display. 
      This makes display at some resolutions look very odd, and it's not really intuitive, although at low resolutions it does have the side effect of in fact showing both channels
      (one as maximum and 1 as minimum). SndView on the other hand shows either only one channel, or the average of both channels. Ideally it should have the option of showing both.
 </UL>

 <H2>The optimization mechanism:</H2>
 When the r.f. starts to climb, more samples are crammed into each horizontal pixel in the view. Each pixel shows the maximum and minimum value represented within that number of samples.

 To display a very large sound in a small view, the r.f. may be in the 1000's. This means that eg 10,000 samples may need to be read, times the width of the view (perhaps 300).
 SndView seeks to reduce this number of reads by skipping samples when they are nowhere near its current maximum or minimum.

 <UL>
 <LI> optimization only kicks in when r.f > "threshold"
 <LI> At the start of the read for any particular pixel, SndView single-steps through the samples until it finds a local maximum/minimum. Thereafter it calculates 5% of the top of the peaks (or bottom of troughs), and if a particular sample is not within this "hot region", it takes bigger jumps until it finds a sample that is within the region. Once it finds this, it goes back to looking at every sample, until it moves out of the hot region again.
 <LI> "peak fraction" sets the percentage of the hot region (0.05 == 5%, default). Theoretically, the smaller this region, the faster the calculation, but in practice it doesn't make a lot of difference.
 <LI> "skip" should ideally increase in some sort of proportion to the r.f. At present it is a fixed value, but a controller object could set it to, say, sqrroot(r.f). I have not really tested this, but that's what this test application is for!
 </UL>

 <H2>The caching mechanism</H2>
 <UL>
 <LI> When r.f > 1, all display data is cached using the SndDisplayData and SndDisplayDataList classes.
 <LI> If r.f. changes, the caches are destroyed.
 <LI> Caches for display data after the origin of a paste or cut operation are destroyed.
 <LI> Adjacent caches are joined together as the user scrolls through the view
 <LI> Caching can make it hard to test the optimization mechanism
 </UL>

 <H2>Other Features of the Source Code</H2>
 <UL>
 <LI> There are #ifdefs for turning on/off the SndView timing. There's not much reason to use the timing any more really.
 <LI> I have put any thought into the setting of zones. If anyone would like to advise on this I'd be happy to hear from you.
 <LI> The mechanism for retrieving data from fragmented sound files is (I think) rather elegant and should be really fast.
 <LI> The archival -read and -write methods are untested.
 <LI> Support for "floating point" and "double" sound format files is included.
 </UL>

 <H2>Future Enhancements for SndView</H2>
 <UL>
 <LI> Support for direct from disk Snd subclasses. Saves having to load the entire file into memory before it is displayed 
 (though once it has been displayed, there's no difference to the amount of actual memory/swap space used).
 <LI> SndView should utilise a control/cell paradigm so that channels can be displayed separately within the view.
 </UL>
 
*/

#ifndef __SNDVIEW_H__
#define __SNDVIEW_H__

#import <AppKit/AppKit.h>

#import "SndDisplayDataList.h"
#import "SndDisplayData.h"
#import "Snd.h"

enum SndViewStereoMode {
    SNDVIEW_LEFTONLY = 0,
    SNDVIEW_RIGHTONLY = 1,
    SNDVIEW_STEREOMODE = 256  /* (open the way for up to 8 channel sound) */
};

#define SND_SOUNDVIEW_MINMAX 0
#define SND_SOUNDVIEW_WAVE 1

// Legacy definitions
#define NX_SOUNDVIEW_MINMAX SND_SOUNDVIEW_MINMAX
#define NX_SOUNDVIEW_WAVE SND_SOUNDVIEW_WAVE

@interface SndView: NSView <NSCoding>
{
    /*! @var sound The sound to display. */
    Snd       	*sound;
    /*! @var pasteboardSound The region of the sound currently held on the pasteboard. */
    Snd		*pasteboardSound;
    /*! @var The delegate receiving notification of SndView state changes. */
    id 		delegate;
    /*! @var selectionRange The region of the sound (in frames) selected (and displayed highlighted) for copy/paste/drag operations. */
    NSRange	selectionRange;
    /*! @var displayMode The form of display, either SND_SOUNDVIEW_MINMAX or SND_SOUNDVIEW_WAVE */
    int		displayMode;
    /*! @var backgroundColour Colour used as a non image background. */
    NSColor	*backgroundColour;
    /*! @var foregroundColour Colour used when drawing the amplitude of each pixel. */
    NSColor	*foregroundColour;
    /*! @var selectionColour Colour used when user selects a region of sound. */
    NSColor	*selectionColour;
    /*! @var reductionFactor Reduction in the horizontal time axis */
    float	reductionFactor;
    /*! @var amplitudeZoom Zoom in the vertical amplitude axis */
    float       amplitudeZoom;

    /*! @struct svFlags 
	@field autoscale With autoscaling NO, the SndView's frame grows or shrinks (horizontally) to fit
	the new sound data and the reduction factor is unchanged. If autoscaling is enabled, the
	reduction factor is automatically recomputed to maintain a constant frame size.
	*/
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
    
    /*! @cursorFlashTimer The NSTimer used for flashing the cursor. */
    NSTimer 	*cursorFlashTimer;
    /*! @var dragIcon The image used when dragging a selection from a SndView. If nil, then the visible region of a selection is used. */
    NSImage     *dragIcon;
    
    int		optThreshold;
    int		optSkip;
    int		stereoMode;
    float	peakFraction;

    int		defaultRecordFormat;
    int		defaultRecordChannelCount;
    double	defaultRecordSampleRate;
    float	defaultRecordSeconds;
    /*! @var recordingSound A Snd instance holding the sound recorded from an input source. */
    Snd *recordingSound;
    
    /*! @var cachedSelectionRect An NSRect holding the pixel region of the SndView which has been selected.
	Holds the previous selection after selectionRange has been changed in order to redraw just that region now deselected. */
    NSRect	cachedSelectionRect;

    int		lastPasteCount;
    int		lastCopyCount;
    BOOL 	notProvidedData;
    BOOL	noSelectionDraw;
    BOOL	firstDraw; // flag indicating lack of initialisation within drawRect:

    /*! @var dataList A SndDisplayDataList instance which holds all of the SndDisplayData instances caching drawn views. */
    SndDisplayDataList *dataList;
    
@private
    float ampScaler;
    float amplitudeDisplayHeight;
    /*! @var validPasteboardSendTypes valid pasteboard types. */
    NSArray *validPasteboardSendTypes;
    NSArray *validPasteboardReturnTypes;
}

/*!
  @method hideCursor
  @abstract Hides the SndView's cursor.
*/
- hideCursor;

/*!
  @method showCursor
  @abstract Displays the SndView's cursor.
*/
- showCursor;

/*!
  @method resignFirstResponder
  @result Returns a BOOL.
  @abstract Resigns the position of first responder. 
  @discussion Returns YES.
*/
- (BOOL) resignFirstResponder;

/*!
  @method becomeFirstResponder
  @result Returns a BOOL.
  @abstract Promotes the SndView to first responder, and returns YES. 
  @discussion You never invoke this method directly.
*/
- (BOOL) becomeFirstResponder;

/*!
  @method copy:
  @param  sender is an id.
  @discussion Copies the current selection to the pasteboard.
*/
- (void) copy: (id) sender;

/*!
  @method cut:
  @param  sender is an id.
  @discussion Deletes the current selection from the SndView, copies it to the
              pasteboard, and sends a <b>soundDidChange:</b> message to the
              delegate. The insertion point is positioned to where the selection
              used to start.
*/
- (void) cut: (id) sender;

/*!
  @method delete:
  @param  sender is an id.
  @discussion Deletes the current selection from the SndView's Snd and sends
              the <b>soundDidChange:</b> message to the delegate. The deletion
              isn't placed on the pasteboard.
*/
- (void) delete: (id) sender;

/*!
  @method paste:
  @param  sender is an id.
  @abstract Replaces the current selection with a copy of the sound data
            currently on the pasteboard. 
  @discussion If there is no selection the pasteboard data is inserted at the cursor position. 
              The pasteboard data must be compatible with the SndView's data, as determined by the Snd
              method <b>compatibleWithSound:</b>. If the paste is successful, the
              <b>soundDidChange:</b> message is sent to the delegate.
*/
- (void) paste: (id) sender;

/*!
  @method selectAll:
  @param  sender is an id.
  @abstract Creates a selection over the SndView's entire Snd.
*/
- (void) selectAll: (id) sender;

/*!
  @method delegate
  @result Returns an id.
  @abstract Returns the SndView's delegate object.
*/
- delegate;

/*!
  @method didPlay:
  @param  sender is an id.
  @param  performance is a SndPerformance.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- didPlay: (id) sender duringPerformance: (SndPerformance *) performance;

/*!
  @method didRecord:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- didRecord: (id) sender;

/*!
  @method displayMode
  @result Returns an int.
  @discussion Returns the SndView's display mode, one of SND_SOUNDVIEW_WAVE
              (oscilloscopic display) or SND_SOUNDVIEW_MINMAX (minimum/maximum
              display; this is the default).
*/
- (int) displayMode;

/*!
  @method drawRect:
  @param  rects is a NSRect.
  @discussion Displays the SndView's sound data. The selection is highlighted
              and the cursor is drawn (if it isn't currently hidden).
                            
              You never send the <b>drawRect:</b> message directly
              to a SndView object. To cause a SndView to draw itself, send it
              one of the display messages defined by the NSView
              class.
*/
- (void) drawRect: (NSRect) rects;

/*!
  @method getSelection:size:
  @param  firstSample is an unsigned int *.
  @param  sampleCount is an unsigned int *.
  @discussion Returns the selection by reference. The index of the selection's
              first sample (counting from 0) is returned in <i>firstSample</i>.
              The size of the selection in samples is returned in
              <i>sampleCount</i>. 
*/
- (void) getSelection: (unsigned int *) firstSample size: (unsigned int *) sampleCount;

/*!
  @method setSelection:size:
  @param  firstSample is an int.
  @param  sampleCount is an int.
  @discussion Sets the selection to be <i>sampleCount</i> samples wide, starting
              with sample <i>firstSample</i> (samples are counted from 0).
*/
- (void) setSelection: (int) firstSample size: (int) sampleCount;

/*!
  @method hadError:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- hadError: sender;

/*!
  @method initWithFrame:
  @param  frameRect is a NSRect.
  @result Returns <b>self</b>.
  @abstract Initializes the SndView, fitting the object within the rectangle given by <i>frameRect</i>. 
  @discussion The initialized SndView doesn't contain any sound data.   
*/
- initWithFrame: (NSRect) frameRect;

/*!
  @method isAutoScale
  @result Returns a BOOL.
  @abstract Returns YES if the SndView is in autoscaling mode, otherwise returns NO.
*/
- (BOOL) isAutoScale;

/*!
  @method isBezeled
  @result Returns a BOOL.
  @abstract Returns YES if the SndView has a bezeled border, otherwise returns NO (the default).
*/
- (BOOL) isBezeled;

/*!
  @method isContinuous
  @result Returns a BOOL.
  @abstract Returns YES if the SndView responds to mouse-dragged events (as set through <b>setContinuous:</b>). 
  @discussion The default is NO.
*/
- (BOOL) isContinuous;

/*!
  @method isEditable
  @result Returns a BOOL.
  @abstract Returns YES if the SndView's sound data can be edited.
*/
- (BOOL) isEditable;

/*!
  @method isEnabled
  @result Returns a BOOL.
  @abstract Returns YES if the SndView is enabled, otherwise returns NO.
  @discussion The mouse has no effect in a disabled SndView. By default, a SndView is enabled.
*/
- (BOOL) isEnabled;

/*!
  @method isOptimizedForSpeed
  @result Returns a BOOL.
  @abstract Returns YES if the SndView is optimized for speedy display.
  @discussion SndViews are optimized by default.
*/
- (BOOL) isOptimizedForSpeed;

/*!
  @method isPlayable
  @result Returns a BOOL.
  @abstract Returns YES if the SndView's sound data can be played without first being converted.
*/
- (BOOL) isPlayable;

/*!
  @method isEntireSoundVisible
  @result Returns a BOOL
  @abstract Returns YES if the receiver is displaying the entire sound within the visible rectangle of it's enclosing scrollview.
 */
- (BOOL) isEntireSoundVisible;

- (float) getDefaultRecordTime;
- (void) setDefaultRecordTime: (float) seconds;

/*!
  @method mouseDown:
  @param  theEvent is a NSEvent *.
  @discussion Allows a selection to be defined by clicking and dragging the mouse.
              This method takes control until a mouse-up occurs. While dragging,
              the selected region is highlighted. On mouse up, the delegate is
              sent the <b>selectionChanged:</b> message. If <b>isContinuous</b> is
              YES, <b>selectionChanged:</b> messages are also sent while the mouse
              is being dragged. You never invoke this method; it's invoked
              automatically in response to the user's actions.
*/
- (void) mouseDown: (NSEvent *) theEvent;

/*!
  @method pasteboard:provideData:
  @param  thePasteboard is a NSPasteboard *.
  @param  type is a NSString *.
  @discussion Places the SndView's entire sound on the given pasteboard.
              Currently, the <i>type</i> argument must be &#ldquo;SndPasteboardType&#rdquo;,
              the pasteboard type that represents sound data.
*/
- (void) pasteboard: (NSPasteboard *) thePasteboard provideDataForType: (NSString *) pboardType;

/*!
  @method pause:
  @param  sender is an id.
  @discussion Pauses the current playback or recording session by invoking Snd's
              <b>pause:</b> method.
*/
- (void) pause: sender;

/*!
  @method play:
  @param  sender is an id.
  @discussion Play the current selection by invoking Snd's <b>play:</b> method.
              If there is no selection, the SndView's entire Snd is played.
              The <b>willPlay:</b> message is sent to the delegate before the
              selection is played; <b>didPlay:</b> is sent when the selection is
              done playing.
*/
- (void) play: sender;

/*!
  @method resume:
  @param  sender is an id.
  @discussion Resumes the current playback or recording session by invoking
              Snd's <b>resume:</b> method.
*/
- (void) resume: sender;

/*!
  @method record:
  @param  sender is an id.
  @discussion Replaces the SndView's current selection with newly recorded
              material. If there is no selection, the recording is inserted at the
              cursor. The <b>willRecord:</b> message is sent to the delegate
              before the recording is started; <b>didRecord:</b> is sent after the
              recording has completed. Recorded data is always taken from the
              CODEC microphone input.
*/
- (void) record: sender;

/*!
  @method stop:
  @param  sender is an id.
  @abstract Stops the SndView's current recording or playback.
*/
- (void) stop: (id) sender;

/*!
  @method readSelectionFromPasteboard:
  @param  thePasteboard is a NSPasteboard *.
  @result Returns a BOOL.
  @discussion Replaces the SndView's current selection with the sound data on
              the given pasteboard. The pasteboard data is converted to the format
              of the data in the SndView (if possible). If the SndView has no
              selection, the pasteboard data is inserted at the cursor position.
              Sets the current error code for the SndView's Snd object (which
              you can retrieve by sending <b>processingError</b> to the Snd) and
              returns YES.
*/
- (BOOL) readSelectionFromPasteboard: (NSPasteboard *) thePasteboard;

/*!
  @method setAmplitudeZoom:
  @param newAmplitudeZoom The new amplitude zoom factor.
  @abstract Sets the current vertical amplitude axis zoom factor. 
  @discussion If 1.0, this displays a full amplitude signal in the maximum vertical view width. 
              If greater than 1.0 a signal will be zoomed and clipped against the view. 
              If less than 1.0 the signal will be reduced within the view. 
              Values less than or equal to zero are not set.
 */
- (void) setAmplitudeZoom: (float) newAmplitudeZoom;

/*!
  @method amplitudeZoom
  @result Returns a float.
  @abstract Returns the current vertical amplitude axis zoom factor.
 */
- (float) amplitudeZoom;

/*!
  @method reductionFactor
  @result Returns a float.
  @abstract Returns the SndView's reduction factor in the horizontal time axis.
  @discussion Computed as follows: <tt>reductionFactor = sampleCount / displayUnits</tt>
*/
- (float) reductionFactor;

/*!
  @method setReductionFactor:
  @param  reductionFactor is a float.
  @result Returns a BOOL.
  @abstract Assigns the reduction factor in the horizontal time axis. 
  @discussion Recomputes the size of the SndView's frame, if autoscaling is disabled.
	      The frame's size (in display units) is set according to
              the following formula:
              
              <tt>displayUnits = sampleCount / reductionFactor</tt>
              
              Increasing the reduction factor zooms out,
              decreasing zooms in on the data. If autodisplaying is enabled, the
              Snd is automatically redisplayed.
              
              If the SndView is in autoscaling mode, or
              <i>reductionFactor</i> is less than 1.0, the method avoids computing
              the frame size and returns NO. (In autoscaling mode, the reduction
              factor is automatically recomputed when the sound data changes - see
              <b>scaleToFit:</b>.) Otherwise, the method returns YES. If
              <i>reductionFactor</i> is the same as the current reduction factor,
              the method returns immediately without recomputing the frame
              size.
*/
- (BOOL) setReductionFactor: (float) redFactor;

/*!
  @method scaleTo:
  @abstract Sets the proportion of the sound displayed within the SndView frame.
  @discussion Recomputes the SndViews reduction factor to fit a portion of the sound data (horizontally) within the views frame.
  @param scaleRatio The ratio of displayed content within the frame 1.0 = entire sound, 0.5 = half the sound etc.
 */
- (void) scaleTo: (float) scaleRatio;

/*!
  @method scaleToFit
  @abstract Recomputes the SndView's reduction factor to fit the sound data
            (horizontally) within the current frame.
  @discussion Invoked automatically when the SndView's data changes and the SndView is in autoscale mode.
              If the SndView isn't in autoscale mode, <b>resizeToFit</b> is
              invoked when the data changes. You never invoke this method
              directly; a subclass can reimplement this method to provide
              specialized behavior.
*/
- (void) scaleToFit;

/*!
  @method resizeToFit
  @abstract Resizes the SndView's frame (horizontally) to maintain a constant reduction factor. 
  @discussion This method is invoked automatically when the
              SndView's data changes and the SndView isn't in autoscale mode.
              If the SndView is in autoscale mode, <b>scaleToFit</b> is invoked
              when the data changes. You never invoke this method directly; a
              subclass can reimplement this method to provide specialized
              behavior.
*/
- (void) resizeToFit;

/*!
  @method resizeToFit:
  @param  withAutoscaling is a BOOL.
  @abstract Resizes the SndView's frame (horizontally) to maintain a constant reduction factor.
  @discussion This method is invoked automatically when the
              SndView's data changes and the SndView isn't in autoscale mode.
              If the SndView is in autoscale mode, <b>scaleToFit</b> is invoked
              when the data changes. You never invoke this method directly; a
              subclass can reimplement this method to provide specialized
              behavior.
*/
- (void) resizeToFit: (BOOL) withAutoscaling;

/*!
  @method resizeToScale:
  @param scaleRatio Scaling of the sound within the frame:  0 > scaleRatio <= 1.0 
  @abstract Resizes the sound within the frame to a normalized scale.
  @discussion 
 */
- (void) resizeToScale: (float) scaleRatio;

/*!
  @method setAutoscale:
  @param  aFlag is a BOOL.
  @abstract Sets the SndView's automatic scaling mode, used to determine how the SndView is
            redisplayed when its data changes.
  @discussion With autoscaling enabled (<i>aFlag</i> is YES), the SndView's reduction factor is
              recomputed so the sound data fits within the view frame. If it's
              disabled (<i>aFlag</i> is NO), the frame is resized and the
              reduction factor is unchanged. If the SndView is in an
              NSScrollView, autoscaling should be disabled (autoscaling is
              disabled by default).
*/
- setAutoscale: (BOOL) aFlag;

/*!
  @method setBezeled:
  @param  aFlag is a BOOL.
  @discussion If <i>aFlag</i> is YES, the display is given a bezeled border. By
              default, the border of a SndView display isn't bezeled. If
              autodisplay is enabled, the Snd is automatically
              redisplayed.
*/
- (void) setBezeled: (BOOL) aFlag;

/*!
  @method setContinuous:
  @param  aFlag is a BOOL.
  @abstract Sets the state of continuous action messages.
  @discussion If <i>aFlag</i> is YES, <b>selectionChanged:</b> messages are sent to the delegate as
              the mouse is being dragged. If NO, the message is sent only on mouse
              up. The default is NO. 
*/
- (void) setContinuous: (BOOL) aFlag;

/*!
  @method setDelegate:
  @param  anObject is an id.
  @abstract Sets the SndView's delegate to <i>anObject</i>.
  @discussion The delegate is sent messages when the user changes or acts on the
              selection.
*/
- (void) setDelegate: (id) anObject;


/*!
  @method setDisplayMode:
  @param  aMode is an int.
  @abstract Sets the SndView's display mode, either SND_SOUNDVIEW_WAVE or SND_SOUNDVIEW_MINMAX (the default).
  @discussion If autodisplaying is enabled, the Snd is automatically redisplayed.
*/
- (void) setDisplayMode: (int) aMode;

/*!
  @method setEditable:
  @param  aFlag is a BOOL.
  @discussion Enables or disables editing in the SndView as <i>aFlag</i> is YES
              or NO. By default, a SndView is editable.
*/
- (void) setEditable: (BOOL) aFlag;

/*!
  @method setEnabled:
  @param  aFlag is a BOOL.
  @discussion Enables or disables the SndView as <i>aFlag</i> is YES or NO. The
              mouse has no effect in a disabled SndView. By default, a SndView
              is enabled.
*/
- (void) setEnabled: (BOOL) aFlag;

/*!
  @method setOptimizedForSpeed:
  @param  flag is a BOOL.
  @discussion Sets the SndView to optimize its display mechanism. Optimization
              greatly increases the speed with which data can be drawn,
              particularly for large sounds. It does so at the loss of some
              precision in representing the sound data; however, these
              inaccuracies are corrected as you zoom in on the data. All
              SndView's are optimized by default.
*/
- (void) setOptimizedForSpeed: (BOOL) flag;

/*!
  @method setSound:
  @param  aSound is a Snd *.
  @abstract Sets the SndView's Snd object to <i>aSound</i>.
  @discussion If autoscaling is enabled, the drawing coordinate system is adjusted so
              <i>aSound</i>'s data fits within the current frame. Otherwise, the
              frame is resized to accommodate the length of the data. If
              autodisplaying is enabled, the SndView is automatically
              redisplayed.
*/
- (void) setSound: (Snd *) aSound;

/*!
  @method sound
  @result Returns a Snd instance.
  @abstract Returns the SndView's Snd object being displayed.
*/
- (Snd *) sound;

/*!
  @method setFrameSize:
  @param  newSize is a NSSize.
  @abstract Sets the width and height of the SndView's frame.
  @discussion If autodisplaying is enabled, the SndView is automatically redisplayed.
*/
- (void) setFrameSize: (NSSize) _newSize;

/*!
  @method soundBeingProcessed
  @result Returns an Snd.
  @discussion Returns the Snd object that's currently being played or recorded
              into. Note that the actual Snd object that's being performed isn't
              necessarily the object returned by SndView's <b>sound</b> method;
              for efficiency, SndView creates a private performance Snd
              object. While this is generally an implementation detail, this
              method is supplied in case the SndView's delegate needs to know
              exactly which object will be (or was) performed.
*/
- (Snd *) soundBeingProcessed;

/*!
  @method tellDelegate:
  @param  theMessage is a SEL.
  @discussion Sends <i>theMessage</i> to the SndView's delegate with the
              SndView as the argument. If the delegate doesn't respond to the
              message, then it isn't sent. You normally never invoke this method;
              it's invoked automatically when an action, such as playing or
              editing, is performed. However, you can invoke it in the design of a
              SndView subclass.
*/
- (void) tellDelegate: (SEL) theMessage;

/*!
  @method tellDelegate:duringPerformance:
  @param  theMessage is a SEL.
  @discussion Sends <i>theMessage</i> to the SndView's delegate with the
              SndView as the argument. If the delegate doesn't respond to the
              message, then it isn't sent. You normally never invoke this method;
              it's invoked automatically when an action, such as playing or
              editing, is performed. However, you can invoke it in the design of a
              SndView subclass.
*/
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance;

/*!
  @method validRequestorForSendType:returnType:
  @param  sendType is a NSString *.
  @param  returnType is a NSString *.
  @result Returns an id.
  @discussion You never invoke this method; it's implemented to support services
              that act on sound data.
*/
- validRequestorForSendType: (NSString *) sendType returnType: (NSString *) returnType;

/*!
  @method willPlay:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- (void) willPlay: sender duringPerformance: (SndPerformance *) performance;

/*!
  @method willRecord:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- (void) willRecord:sender;

- (BOOL) writeSelectionToPasteboard: (NSPasteboard *) thePasteboard types: (NSArray *) pboardTypes;
- (BOOL) writeSelectionToPasteboardNoProvide: thePasteboard types: (NSArray *) pboardTypes;

- (id) initWithCoder: (NSCoder *) aDecoder;
- (void) encodeWithCoder: (NSCoder *) aCoder;


/*************************
 * these methods are unique to SndKit.
 *************************/

- (BOOL) invalidateCacheStartPixel: (int) start end: (int) end;
	/* if end == -1, invalidates to end of last cache*/
- (BOOL) invalidateCacheStartSample: (int) start end: (int) end;
	/* start and end are samples. Must be exact. */

/*!
  @method invalidateCache
  @abstract Used if you change the data of a sound which is being used
            in a SndView in any way, to inform the SndView.
  @discussion The easiest message to use is -invalidateCache, but you can be more specific and tell it the
    exact sample number with -invalidateCacheStartSample:end:
 */
- (void) invalidateCache;

/*!
  @method setDrawsCrosses:
  @abstract Determines whether individual samples should be drawn as crosses when displaying sounds at extreme
	    magnification.
  @param aFlag YES to draw crosses linked by line segments, NO to draw samples as points linked by line segments.
  @discussion defaults to YES.
 */
- (void) setDrawsCrosses: (BOOL) aFlag;

/*!
  @method drawsCrosses
  @abstract Returns whether individual samples are drawn as crosses at extreme magnification.
  @result Returns YES if samples are drawn with a cross, NO if they are drawn as points.
 */
- (BOOL) drawsCrosses;

/* see class description for explanation of optimisation thresholds and skips, and peak fractions */
- (void) setOptThreshold: (int) threshold;
- (int) getOptThreshold;
- (void) setOptSkip: (int) skip;
- (int) getOptSkip;
- (void) setPeakFraction: (float) fraction;
- (float) getPeakFraction;

/*!
  @method setStereoMode:
  @abstract Determines how to draw multichannel sounds.
  @param stereoMode one of the values SV_LEFTONLY, SV_RIGHTONLY, SV_STEREOMODE
 */
- (BOOL) setStereoMode: (enum SndViewStereoMode) stereoMode;

/*!
  @method getStereoMode
  @abstract Returns the mode of drawing multichannel sounds.
  @result Returns 
 */
- (enum SndViewStereoMode) getStereoMode;

/*!
  @method setSelectionColor:
  @abstract Sets the selection colour.
  @param color An NSColor.
 */
- (void) setSelectionColor: (NSColor *) color;

/*!
  @method selectionColor
  @abstract Returns the current selection colour.
  @result Returns an NSColor.
 */
- (NSColor *) selectionColor;

/*!
  @method setBackgroundColor:
  @abstract Sets the background colour.
  @param color An NSColor.
 */
- (void) setBackgroundColor: (NSColor *) color;

/*!
  @method backgroundColor
  @abstract Returns the current background colour.
  @result Returns an NSColor.
 */
- (NSColor *) backgroundColor;

/*!
  @method setForegroundColor:
  @abstract Sets the foreground colour.
  @param color An NSColor instance.
 */
- (void) setForegroundColor: (NSColor *) color;

/*!
  @method foregroundColor
  @abstract Returns the current foreground colour.
  @result Returns an NSColor instance.
 */
- (NSColor *) foregroundColor;

/*!
  @method setDragIcon:
  @abstract Sets the icon used when dragging selections from the SndView.
  @param newDragIcon An NSImage instance to be used as the drag image. 
         If nil, the icon to appear will be the visible region of the selected SndView.
  @discussion If the default workspace image icon is desired, use:
    [sndView setDragIcon: [[NSWorkspace sharedWorkspace] iconForFileType: [Snd defaultFileExtension]]];
 */
- (void) setDragIcon: (NSImage *) newDragIcon;

/*!
  @method dragIcon
  @abstract Returns the current NSImage instance used when dragging a selection from the receiver.
  @result Returns an NSImage instance.
  @discussion If nil, the icon to appear will be the visible region of the selected SndView.
 */
- (NSImage *) dragIcon;

@end

#endif
