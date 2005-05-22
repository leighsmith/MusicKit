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

 @brief SndView is responsible for displaying a amplitude/time plot of Snd data.
 
 
   

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

<H2>Methods Implemented by the Delegate</H2>

 - selectionChanged: (id) sender
 Sent to the delegate when the SndView's selection changes.

 - soundDidChange: (id) sender
 Sent to the delegate when the SndView's sound data is edited.


<H2>SndView Adds These Features:</H2>
 <UL>
 <LI> Configurable speed optimizations (see below).
 <LI> Non-integer reduction factors (reductionFactor), and reductionFactor down to 0.04 (1 sample per 25 pixels) [SoundView only goes as low as 1].
 <LI> For 0.04 <= reductionFactor < 0.34, SndView can be instructed to draw small horizontal bars at each sample (this is the default).
      This allows for great accuracy in specifying selections for copy/paste operations.
 <LI> Configurable maximum recording time.
 <LI> Intelligent recording - converts recorded sounds to the format of the rest of the displayed sound if the format is not compatible.
      Queries hardware for allowable sampling rates/formats [NOT CURRENTLY SUPPORTED ON ANY PLATFORM].
 <LI> Can be instructed to display only left channel, only right channel, or average of both channels.
 <LI> Triple-click does a Select-All.
 </UL>

<H2>SndView fixes these bugs:</H2>
 <UL>
 <LI> SndView is not susceptable to the "info length" bug (I think...)
 <LI> SndView copes a lot better with recording into the sound [NOT CURRENTLY SUPPORTED ON ANY PLATFORM]
 <LI> SndView displays "Waveform" view perfectly, without the PostScript errors that plague SoundView
 <LI> SndView is scrupulous about floating point numbers and rounding, and should never leave cursor "turds" on the screen
 <LI> SndView does not alter the length of the selection if you change reductionFactor.
      Even if you extend the selection at a reductionFactor different to the one you created the selection at, 
      the sample at the non-changed end will remain the same.
 </UL>

<H2>SndView has these bugs:</H2>
 <UL>
 <LI> If SndView is destroyed without freeing it, and it has told the pasteboard that it has data ready for pasting
      (from a Copy or Cut operation) the application that requested the data will probably crash. 
      If the application containing SndView quits normally, SndView does provide the data though (as does SoundView, I think).
 <LI> With reductionFactor <= 1, reducing the selection while auto-scrolling leaves a horrible mess on the screen, until you take your finger off the mouse.
      This is because when a section of the view is drawn, it highlights the part of the new section that it thinks is within the selection rectangle.
      For reductionFactor <= 1, this is not immediately obvious, and I need to force the start and end of selection rectangle in this case to be midway between samples.
 </UL>

<H2>SndView is incompatible in these ways:</H2>
 <UL>
 <LI> The bounds rectangle is not scaled the same as SoundView's is. SoundView scales it's bounds so that (y = 0) runs through the centre of the view, and the maximum +y and -y limits
      correspond to the limits of the format of the sound it is displaying. SndView does not scale at all. It could be changed quite easily. As it is, this breaks any subclasses of 
      SoundView that draw into the view.
 <LI> "drawSamples from:to:" is not implemented (yet). But all you would have to do would be to invalidate the caches for that area (if necessary), and -display: the SndView
 <LI> Because of the caching mechanism, if you change samples "behind SndView's back" you must invalidate the cache for the affected samples,
      with "invalidateCacheStartSample:end:" before displaying.
 <LI> SoundView considers the left and right channels of the sound individually when it comes to finding maximum and minimum values for display. 
      This makes display at some resolutions look very odd, and it's not really intuitive, although at low resolutions it does have the side effect
      of in fact showing both channels (one as maximum and 1 as minimum). SndView on the other hand shows either only one channel, or the average 
      of both channels. Ideally it should have the option of showing both.
 </UL>

<H2>The optimization mechanism:</H2>
 When the reductionFactor starts to climb, more samples are crammed into each horizontal pixel in the view.
 Each pixel shows the maximum and minimum value represented within that number of samples.

 To display a very large sound in a small view, the reductionFactor may be in the 1000's.
 This means that eg 10,000 samples may need to be read, times the width of the view (perhaps 300).
 SndView seeks to reduce this number of reads by skipping samples when they are nowhere near its current maximum
 or minimum.

 <UL>
 <LI> Optimization only kicks in when reductionFactor > "threshold".
 <LI> At the start of the read for any particular pixel, SndView single-steps through the samples until it finds a local maximum/minimum.
      Thereafter it calculates 5% of the top of the peaks (or bottom of troughs), and if a particular sample is not within this "hot region",
      it takes bigger jumps until it finds a sample that is within the region. Once it finds this, it goes back to looking at every sample,
      until it moves out of the hot region again.
 <LI> "peak fraction" sets the percentage of the hot region (0.05 == 5%, default). Theoretically, the smaller this region, the faster the calculation,
      but in practice it doesn't make a lot of difference.
 <LI> "skip" should ideally increase in some sort of proportion to the reductionFactor.
      At present it is a fixed value, but a controller object could set it to, say, sqrroot(reductionFactor).
      I have not really tested this, but that's what this test application is for!
 </UL>

<H2>The caching mechanism</H2>
 <UL>
 <LI> When reductionFactor > 1, all display data is cached using the SndDisplayData and SndDisplayDataList classes.
 <LI> If reductionFactor changes, the caches are destroyed.
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
    /*! @var selectedFrames The region of the sound (in frames) selected (and displayed highlighted) for copy/paste/drag operations. */
    NSRange	selectedFrames;
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
        @field disabled To be described.
	@field continuousSelectionUpdates If YES, <b>selectionChanged:</b> delegate messages are sent as the mouse is being dragged.
	       If NO, the message is sent only on mouse	up.
        @field cursorOn To be described.
	@field drawsCrosses Draws a cross at each sample location when plotting at a sub-sample resolution.
	@field autoscale With autoscaling NO, the SndView's frame grows or shrinks (horizontally) to fit
	       the new sound data and the reduction factor is unchanged. If autoscaling is enabled, the
	       reduction factor is automatically recomputed to maintain a constant frame size.
        @field bezeled To be described.
        @field notEditable To be described.
        @field notOptimizedForSpeed To be described.
     */
    struct {
        unsigned int  disabled:1;
        unsigned int  continuousSelectionUpdates:1;
        unsigned int  cursorOn:1;
        unsigned int  drawsCrosses:1;
        unsigned int  autoscale:1;
        unsigned int  bezeled:1;
        unsigned int  notEditable:1;
        unsigned int  notOptimizedForSpeed:1;
    } svFlags;
    
    /*! @var cursorFlashTimer The NSTimer used for flashing the cursor. */
    NSTimer 	*cursorFlashTimer;
    /*! @var dragIcon The image used when dragging a selection from a SndView. If nil, then the visible region of a selection is used. */
    NSImage     *dragIcon;
    
    int		optThreshold;
    int		optSkip;
    float	peakFraction;

    /*! @var stereoMode of type SndViewStereoMode indicating to display a single channel or an average of all channels. */
    int		stereoMode;

    int		defaultRecordFormat;
    int		defaultRecordChannelCount;
    double	defaultRecordSampleRate;
    float	defaultRecordSeconds;
    /*! @var recordingSound A Snd instance holding the sound recorded from an input source. */
    Snd *recordingSound;
    
    /*! @var cachedSelectionRect An NSRect holding the pixel region of the SndView which has been selected.
	Holds the previous selection after selectedFrames has been changed in order to redraw just that region now deselected. */
    NSRect	cachedSelectionRect;
    /*! @var previousSelectedFrames An NSRange holding the range in frames previously selected. */
    NSRange     previousSelectedFrames;

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
    /*! @var validPasteboardReturnTypes valid pasteboard types. */
    NSArray *validPasteboardReturnTypes;
}

/*!
  @brief Hides the SndView's cursor.
*/
- hideCursor;

/*!
  @brief Displays the SndView's cursor.
*/
- showCursor;

/*!
  @return Returns a BOOL.
  @brief Resigns the position of first responder. 
  
   Returns YES.
*/
- (BOOL) resignFirstResponder;

/*!
  @return Returns a BOOL.
  @brief Promotes the SndView to first responder, and returns YES. 
  
   You never invoke this method directly.
*/
- (BOOL) becomeFirstResponder;

/*!
  @param  sender is an id.
  @brief Copies the current selection to the pasteboard.
*/
- (void) copy: (id) sender;

/*!
  @param  sender is an id.
  @brief Deletes the current selection from the SndView, copies it to the
              pasteboard, and sends a <b>soundDidChange:</b> message to the
              delegate.

  The insertion point is positioned to where the selection used to start.
*/
- (void) cut: (id) sender;

/*!
  @param  sender is an id.
  @brief Deletes the current selection from the SndView's Snd and sends
              the <b>soundDidChange:</b> message to the delegate.

  The deletion isn't placed on the pasteboard.
*/
- (void) delete: (id) sender;

/*!
  @param  sender is an id.
  @brief Replaces the current selection with a copy of the sound data
            currently on the pasteboard. 
  
   If there is no selection the pasteboard data is inserted at the cursor position. 
  The pasteboard data must be compatible with the SndView's data, as determined by the Snd
  method <b>compatibleWithSound:</b>. If the paste is successful, the
  <b>soundDidChange:</b> message is sent to the delegate.
*/
- (void) paste: (id) sender;

/*!
  @param  sender is an id.
  @brief Creates a selection over the SndView's entire Snd.
*/
- (void) selectAll: (id) sender;

/*!
  @return Returns an id.
  @brief Returns the SndView's delegate object.
*/
- delegate;

/*!
  @brief Sent to the delegate just after the SndView's sound is played.
  
   Method implemented by the delegate.
  Used to redirect delegate messages from the SndView's Snd
  object; you never invoke this method directly.
 @param  sender is an id.
 @param  performance is a SndPerformance.
*/
- didPlay: (id) sender duringPerformance: (SndPerformance *) performance;

/*!
  @brief Sent to the delegate just after the SndView's sound is recorded into.
  
   Method implemented by the delegate.
  Used to redirect delegate messages from the SndView's Snd
  object; you never invoke this method directly.
 @param  sender is an id.
*/
- didRecord: (id) sender;

/*!
  @return Returns an int.
  @brief Returns the SndView's display mode, one of SND_SOUNDVIEW_WAVE
              (oscilloscopic display) or SND_SOUNDVIEW_MINMAX (minimum/maximum
              display; this is the default).
*/
- (int) displayMode;

/*!
  @param  rects is a NSRect.
  @brief Displays the SndView's sound data.

  The selection is highlighted and the cursor is drawn (if it isn't currently hidden).
                            
  You never send the <b>drawRect:</b> message directly
  to a SndView object. To cause a SndView to draw itself, send it
  one of the display messages defined by the NSView
  class.
*/
- (void) drawRect: (NSRect) rects;

/*!
  @param  firstSample is an unsigned int *.
  @param  sampleCount is an unsigned int *.
  @brief Returns the selection by reference.

  The index of the selection's first sample (counting from 0) is returned in <i>firstSample</i>.
  The size of the selection in samples is returned in <i>sampleCount</i>. 
*/
- (void) getSelection: (unsigned int *) firstSample size: (unsigned int *) sampleCount;

/*!
  @param  firstSample is an int.
  @param  sampleCount is an int.
  @brief Sets the selection to be <i>sampleCount</i> samples wide, starting
              with sample <i>firstSample</i> (samples are counted from 0).
*/
- (void) setSelection: (int) firstSample size: (int) sampleCount;

/*!
  @brief Sent to the delegate if an error is encountered during recording or playback of the SndView's sound.
  
   Used to redirect delegate messages from the SndView's Snd object; you never invoke this method directly.
  @param  sender is an id.
*/
- hadError: (id) sender;

/*!
  @brief Initializes the SndView, fitting the object within the rectangle given by <i>frameRect</i>. 
  
   The initialized SndView doesn't contain any sound data.   
  @param  frameRect is a NSRect.
  @return Returns <b>self</b>.
*/
- initWithFrame: (NSRect) frameRect;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the SndView is in autoscaling mode, otherwise returns NO.
*/
- (BOOL) isAutoScale;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the SndView has a bezeled border, otherwise returns NO (the default).
*/
- (BOOL) isBezeled;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the SndView responds to mouse-dragged events (as set through <b>setContinuousSelectionUpdates:</b>). 
  
   The default is NO.
*/
- (BOOL) isContinuousSelectionUpdates;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the SndView's sound data can be edited.
*/
- (BOOL) isEditable;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the SndView is enabled, otherwise returns NO.
  
   The mouse has no effect in a disabled SndView. By default, a SndView is enabled.
*/
- (BOOL) isEnabled;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the SndView is optimized for speedy display.
  
   SndViews are optimized by default.
*/
- (BOOL) isOptimizedForSpeed;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the SndView's sound data can be played without first being converted.
*/
- (BOOL) isPlayable;

/*!
  @return Returns a BOOL
  @brief Returns YES if the receiver is displaying the entire sound within the visible rectangle of it's enclosing scrollview.
 */
- (BOOL) isEntireSoundVisible;

- (float) getDefaultRecordTime;
- (void) setDefaultRecordTime: (float) seconds;

/*!
  @brief Not normally messaged directly by a client class, it's default operation is to inform the delegate
  that the selection changed if setContinuousSelectionUpdates was set to YES.

  This allows subclasses to know when selections change and override default behaviour.
 */
- (void) selectionChanged;

/*!
  @param  theEvent is an NSEvent instance.
  @brief Allows a selection to be defined by clicking and dragging the mouse.

  This method takes control until a mouse-up occurs. While dragging,
  the selected region is highlighted. On mouse up, the delegate is
  sent the <b>selectionChanged:</b> message. If <b>isContinuous</b> is
  YES, <b>selectionChanged:</b> messages are also sent while the mouse
  is being dragged. You never invoke this method; it's invoked
  automatically in response to the user's actions.
*/
- (void) mouseDown: (NSEvent *) theEvent;

/*!
  @param  thePasteboard is a NSPasteboard instance.
  @param  pboardType is a NSString instance.
  @brief Places the SndView's entire sound on the given pasteboard.
  
  Currently, the <i>type</i> argument must be &#ldquo;SndPasteboardType&#rdquo;,
  the pasteboard type that represents sound data.
*/
- (void) pasteboard: (NSPasteboard *) thePasteboard provideDataForType: (NSString *) pboardType;

/*!
  @brief Pauses the current playback or recording session by invoking Snd's <b>pause:</b> method.
  @param  sender is an id.
*/
- (void) pause: (id) sender;

/*!
  @brief Play the current selection by invoking Snd's <b>play:</b> method.
  
  If there is no selection, the SndView's entire Snd is played.
  The <b>willPlay:</b> message is sent to the delegate before the
  selection is played; <b>didPlay:</b> is sent when the selection is
  done playing.
  @param  sender is an id.
*/
- (void) play: (id) sender;

/*!
  @param  sender is an id.
  @brief Resumes the current playback or recording session by invoking
              Snd's <b>resume:</b> method.
*/
- (void) resume: (id) sender;

/*!
  @param  sender is an id.
  @brief Replaces the SndView's current selection with newly recorded material.

  If there is no selection, the recording is inserted at the
  cursor. The <b>willRecord:</b> message is sent to the delegate
  before the recording is started; <b>didRecord:</b> is sent after the
  recording has completed. Recorded data is always taken from the
  CODEC microphone input.
*/
- (void) record: (id) sender;

/*!
  @param  sender is an id.
  @brief Stops the SndView's current recording or playback.
*/
- (void) stop: (id) sender;

/*!
  @param  thePasteboard is a NSPasteboard instance.
  @return Returns a BOOL.
  @brief Replaces the SndView's current selection with the sound data on
              the given pasteboard.

  The pasteboard data is converted to the format
  of the data in the SndView (if possible). If the SndView has no
  selection, the pasteboard data is inserted at the cursor position.
  Sets the current error code for the SndView's Snd object (which
  you can retrieve by sending <b>processingError</b> to the Snd) and
  returns YES.
*/
- (BOOL) readSelectionFromPasteboard: (NSPasteboard *) thePasteboard;

/*!
  @param newAmplitudeZoom The new amplitude zoom factor.
  @brief Sets the current vertical amplitude axis zoom factor. 
  
   If 1.0, this displays a full amplitude signal in the maximum vertical view width. 
  If greater than 1.0 a signal will be zoomed and clipped against the view. 
  If less than 1.0 the signal will be reduced within the view. 
  Values less than or equal to zero are not set.
 */
- (void) setAmplitudeZoom: (float) newAmplitudeZoom;

/*!
  @return Returns a float.
  @brief Returns the current vertical amplitude axis zoom factor.
 */
- (float) amplitudeZoom;

/*!
  @return Returns a float.
  @brief Returns the SndView's reduction factor in the horizontal time axis.
  
   Computed as follows: <tt>reductionFactor = sampleCount / displayUnits</tt>
*/
- (float) reductionFactor;

/*!
  @param  reductionFactor is a float.
  @return Returns a BOOL.
  @brief Assigns the reduction factor in the horizontal time axis. 
  
   Recomputes the size of the SndView's frame, if autoscaling is disabled.
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
- (BOOL) setReductionFactor: (float) reductionFactor;

/*!
  @brief Sets the proportion of the sound displayed within the SndView frame.
  
   Recomputes the SndViews reduction factor to fit a portion of the sound data (horizontally) within the views frame.
  @param scaleRatio The ratio of displayed content within the frame 1.0 = entire sound, 0.5 = half the sound etc.
 */
- (void) scaleTo: (float) scaleRatio;

/*!
  @brief Recomputes the SndView's reduction factor to fit the sound data
            (horizontally) within the current frame.
  
   Invoked automatically when the SndView's data changes and the SndView is in autoscale mode.
  If the SndView isn't in autoscale mode, <b>resizeToFit</b> is
  invoked when the data changes. You never invoke this method
  directly; a subclass can reimplement this method to provide
  specialized behavior.
*/
- (void) scaleToFit;

/*!
  @brief Resizes the SndView's frame (horizontally) to maintain a constant reduction factor. 
  
   This method is invoked automatically when the
  SndView's data changes and the SndView isn't in autoscale mode.
  If the SndView is in autoscale mode, <b>scaleToFit</b> is invoked
  when the data changes. You never invoke this method directly; a
  subclass can reimplement this method to provide specialized
  behavior.
*/
- (void) resizeToFit;

/*!
  @param  withAutoscaling is a BOOL.
  @brief Resizes the SndView's frame (horizontally) to maintain a constant reduction factor.
  
   This method is invoked automatically when the
  SndView's data changes and the SndView isn't in autoscale mode.
  If the SndView is in autoscale mode, <b>scaleToFit</b> is invoked
  when the data changes. You never invoke this method directly; a
  subclass can reimplement this method to provide specialized
  behavior.
*/
- (void) resizeToFit: (BOOL) withAutoscaling;

/*!
  @param scaleRatio Scaling of the sound within the frame:  0 > scaleRatio <= 1.0 
  @brief Resizes the sound within the frame to a normalized scale.
 */
- (void) resizeToScale: (float) scaleRatio;

/*!
  @param  aFlag is a BOOL.
  @brief Sets the SndView's automatic scaling mode, used to determine how the SndView is
            redisplayed when its data changes.
  
   With autoscaling enabled (<i>aFlag</i> is YES), the SndView's reduction factor is
  recomputed so the sound data fits within the view frame. If it's
  disabled (<i>aFlag</i> is NO), the frame is resized and the
  reduction factor is unchanged. If the SndView is in an
  NSScrollView, autoscaling should be disabled (autoscaling is
  disabled by default).
*/
- setAutoscale: (BOOL) aFlag;

/*!
  @param  aFlag is a BOOL.
  @brief If <i>aFlag</i> is YES, the display is given a bezeled border.

  By default, the border of a SndView display isn't bezeled. If
  autodisplay is enabled, the Snd is automatically
  redisplayed.
*/
- (void) setBezeled: (BOOL) aFlag;

/*!
  @param  aFlag is a BOOL.
  @brief Sets the state of continuous action messages.
  
   If <i>aFlag</i> is YES, <b>selectionChanged:</b> messages are sent to the delegate as
  the mouse is being dragged. If NO, the message is sent only on mouse up. The default is NO. 
*/
- (void) setContinuousSelectionUpdates: (BOOL) aFlag;

/*!
  @param  anObject is an id.
  @brief Sets the SndView's delegate to <i>anObject</i>.
  
   The delegate is sent messages when the user changes or acts on the selection.
*/
- (void) setDelegate: (id) anObject;

/*!
  @param  aMode is an int.
  @brief Sets the SndView's display mode, either SND_SOUNDVIEW_WAVE or SND_SOUNDVIEW_MINMAX (the default).
  
   If autodisplaying is enabled, the Snd is automatically redisplayed.
*/
- (void) setDisplayMode: (int) aMode;

/*!
  @param  aFlag is a BOOL.
  @brief Enables or disables editing in the SndView as <i>aFlag</i> is YES or NO.

  By default, a SndView is editable.
*/
- (void) setEditable: (BOOL) aFlag;

/*!
  @param  aFlag is a BOOL.
  @brief Enables or disables the SndView as <i>aFlag</i> is YES or NO.

  The mouse has no effect in a disabled SndView. By default, a SndView is enabled.
*/
- (void) setEnabled: (BOOL) aFlag;

/*!
  @param  flag is a BOOL.
  @brief Sets the SndView to optimize its display mechanism.

  Optimization greatly increases the speed with which data can be drawn,
  particularly for large sounds. It does so at the loss of some
  precision in representing the sound data; however, these
  inaccuracies are corrected as you zoom in on the data. All
  SndView's are optimized by default.
*/
- (void) setOptimizedForSpeed: (BOOL) flag;

/*!
  @param  aSound is a Snd instance.
  @brief Sets the SndView's Snd object to <i>aSound</i>.
  
   If autoscaling is enabled, the drawing coordinate system is adjusted so
  <i>aSound</i>'s data fits within the current frame. Otherwise, the
  frame is resized to accommodate the length of the data. If
  autodisplaying is enabled, the SndView is automatically
  redisplayed.
*/
- (void) setSound: (Snd *) aSound;

/*!
  @brief Returns the SndView's Snd object being displayed.
  @return Returns a Snd instance.
*/
- (Snd *) sound;

/*!
  @brief Sets the width and height of the SndView's frame.
  
  If autodisplaying is enabled, the SndView is automatically redisplayed.
  @param  newSize is a NSSize.
*/
- (void) setFrameSize: (NSSize) newSize;

/*!
  @return Returns an Snd.
  @brief Returns the Snd object that's currently being played or recorded into.

  Note that the actual Snd object that's being performed isn't
  necessarily the object returned by SndView's <b>sound</b> method;
  for efficiency, SndView creates a private performance Snd
  object. While this is generally an implementation detail, this
  method is supplied in case the SndView's delegate needs to know
  exactly which object will be (or was) performed.
*/
- (Snd *) soundBeingProcessed;

/*!
  @param  theMessage is a SEL.
  @brief Sends <i>theMessage</i> to the SndView's delegate with the
              SndView as the argument.

  If the delegate doesn't respond to the
  message, then it isn't sent. You normally never invoke this method;
  it's invoked automatically when an action, such as playing or
  editing, is performed. However, you can invoke it in the design of a
  SndView subclass.
*/
- (void) tellDelegate: (SEL) theMessage;

/*!
  @brief Sends <i>theMessage</i> to the SndView's delegate with the SndView as the argument.

  If the delegate doesn't respond to the message, then it isn't sent.
  You normally never invoke this method;
  it's invoked automatically when an action, such as playing or
  editing, is performed. However, you can invoke it in the design of a
  SndView subclass.
  @param  theMessage is a SEL.
  @param  performance The SndPerformance instance performing when the message is sent.
*/
- (void) tellDelegate: (SEL) theMessage duringPerformance: (SndPerformance *) performance;

/*!
  @param  sendType is a NSString instance.
  @param  returnType is a NSString instance.
  @return Returns an id.
  @brief You never invoke this method; it's implemented to support services
              that act on sound data.
*/
- validRequestorForSendType: (NSString *) sendType returnType: (NSString *) returnType;

/*!
  @brief Sent to the delegate just before the SndView's sound is played.
  @param  sender is an id.
  @param performance A SndPerformance instance indicating which performance is about to play.
  
   Method implemented by the delegate.
  Used to redirect delegate messages from the SndView's Snd
  object; you never invoke this method directly.
*/
- (void) willPlay: sender duringPerformance: (SndPerformance *) performance;

/*!
  @brief Sent to the delegate just before the SndView's sound is recorded into.
  @param  sender is an id.
  
   Method implemented by the delegate.
  Used to redirect delegate messages from the SndView's Snd
  object; you never invoke this method directly.
*/
- (void) willRecord: (id) sender;

/*!
  @brief write the selected region of sound to the pasteboard.
  @param thePasteboard The pasteboard to receive the sound region.
  @param pboardTypes An array of ? sound formats?
 */
- (BOOL) writeSelectionToPasteboard: (NSPasteboard *) thePasteboard types: (NSArray *) pboardTypes;
- (BOOL) writeSelectionToPasteboardNoProvide: (NSPasteboard *) thePasteboard types: (NSArray *) pboardTypes;

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
  @brief Used if you change the data of a sound which is being used
            in a SndView in any way, to inform the SndView.
  
   The easiest message to use is -invalidateCache, but you can be more specific and tell it the
    exact sample number with -invalidateCacheStartSample:end:
 */
- (void) invalidateCache;

/*!
  @brief Determines whether individual samples should be drawn as crosses when displaying sounds at extreme
	    magnification.
 
  Defaults to YES.
  @param aFlag YES to draw crosses linked by line segments, NO to draw samples as points linked by line segments.
 */
- (void) setDrawsCrosses: (BOOL) aFlag;

/*!
  @brief Returns whether individual samples are drawn as crosses at extreme magnification.
  @return Returns YES if samples are drawn with a cross, NO if they are drawn as points.
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
  @brief Determines how to draw multichannel sounds.
  @param stereoMode one of the values SV_LEFTONLY, SV_RIGHTONLY, SV_STEREOMODE
 */
- (BOOL) setStereoMode: (enum SndViewStereoMode) stereoMode;

/*!
  @brief Returns the mode of drawing multichannel sounds.
  @return Returns 
 */
- (enum SndViewStereoMode) getStereoMode;

/*!
  @brief Sets the selection colour.
  @param color An NSColor.
 */
- (void) setSelectionColor: (NSColor *) color;

/*!
  @brief Returns the current selection colour.
  @return Returns an NSColor.
 */
- (NSColor *) selectionColor;

/*!
  @brief Sets the background colour.
  @param color An NSColor.
 */
- (void) setBackgroundColor: (NSColor *) color;

/*!
  @brief Returns the current background colour.
  @return Returns an NSColor.
 */
- (NSColor *) backgroundColor;

/*!
  @brief Sets the foreground colour.
  @param color An NSColor instance.
 */
- (void) setForegroundColor: (NSColor *) color;

/*!
  @brief Returns the current foreground colour.
  @return Returns an NSColor instance.
 */
- (NSColor *) foregroundColor;

/*!
  @brief Sets the icon used when dragging selections from the SndView.
  
   If the default workspace image icon is desired, use:
    [sndView setDragIcon: [[NSWorkspace sharedWorkspace] iconForFileType: [Snd defaultFileExtension]]];
 @param newDragIcon An NSImage instance to be used as the drag image. 
 If nil, the icon to appear will be the visible region of the selected SndView.
 */
- (void) setDragIcon: (NSImage *) newDragIcon;

/*!
  @brief Returns the current NSImage instance used when dragging a selection from the receiver.
  
   If nil, the icon to appear will be the visible region of the selected SndView.
 @return Returns an NSImage instance.
 */
- (NSImage *) dragIcon;

@end

#endif
