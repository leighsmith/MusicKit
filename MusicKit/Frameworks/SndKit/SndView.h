/********************************************************************************
$Id$

LEGAL:
This framework and all source code supplied with it, except where specified, are
Copyright Stephen Brandon and the University of Glasgow, 1999. You are free to use
the source code for any purpose, including commercial applications, as long as you
reproduce this notice on all such software.

Software production is complex and we cannot warrant that the Software will be
error free.  Further, we will not be liable to you if the Software is not fit
for the purpose for which you acquired it, or of satisfactory quality. 

WE SPECIFICALLY EXCLUDE TO THE FULLEST EXTENT PERMITTED BY THE COURTS ALL
WARRANTIES IMPLIED BY LAW INCLUDING (BUT NOT LIMITED TO) IMPLIED WARRANTIES
OF QUALITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT OF THIRD
PARTIES RIGHTS.

If a court finds that we are liable for death or personal injury caused by our
negligence our liability shall be unlimited.  

WE SHALL HAVE NO LIABILITY TO YOU FOR LOSS OF PROFITS, LOSS OF CONTRACTS, LOSS
OF DATA, LOSS OF GOODWILL, OR WORK STOPPAGE, WHICH MAY ARISE FROM YOUR POSSESSION
OR USE OF THE SOFTWARE OR ASSOCIATED DOCUMENTATION.  WE SHALL HAVE NO LIABILITY
IN RESPECT OF ANY USE OF THE SOFTWARE OR THE ASSOCIATED DOCUMENTATION WHERE SUCH
USE IS NOT IN COMPLIANCE WITH THE TERMS AND CONDITIONS OF THIS AGREEMENT.

********************************************************************************/
/*!
  @header SndView

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

&#183; In NX_SOUNDVIEW_WAVE mode, the drawing is rendered in an
oscilloscopic fashion.

&#183; In NX_SOUNDVIEW_MINMAX mode, two lines are drawn, one to
connect the maximum values, and one to connect the minimum values.

As you zoom in (as the reduction factor decreases), the two drawing
modes become indistinguishable.

<b>Autoscaling the Display</b>

When a SndView's sound data changes (due to editing or recording),
the manner in which the SndView is redisplayed depends on its
<b>autoscale</b> flag. With autoscaling disabled, the SndView's
frame grows or shrinks (horizontally) to fit the new sound data and
the reduction factor is unchanged. If autoscaling is enabled, the
reduction factor is automatically recomputed to maintain a constant
frame size. By default, autoscaling is disabled; this is to
accommodate the use of a SndView object as the document of an
NSScrollView.  */

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

/*!
@class SndView
@discussion To come
*/
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

/*!
  @method hideCursor
  @discussion Hides the SndView's cursor. This is usually handled
              automatically.
*/
- hideCursor;

/*!
  @method showCursor
  @discussion Displays the SndView's cursor. This is usually handled
              automatically.
*/
- showCursor;

- (void)initVars;
- (BOOL)scrollPointToVisible:(const NSPoint)point;

/*!
  @method resignFirstResponder
  @result Returns a BOOL.
  @discussion Resigns the position of first responder. Returns
              YES.
*/
- (BOOL)resignFirstResponder;

/*!
  @method becomeFirstResponder
  @result Returns a BOOL.
  @discussion Promotes the SndView to first responder, and returns YES. You
              never invoke this method directly.
*/
- (BOOL)becomeFirstResponder;

/*!
  @method copy:
  @param  sender is an id.
  @discussion Copies the current selection to the pasteboard.
*/
- (void)copy:(id)sender;

/*!
  @method cut:
  @param  sender is an id.
  @discussion Deletes the current selection from the SndView, copies it to the
              pasteboard, and sends a <b>soundDidChange:</b> message to the
              delegate. The insertion point is positioned to where the selection
              used to start.
*/
- (void)cut:(id)sender;

/*!
  @method delete:
  @param  sender is an id.
  @discussion Deletes the current selection from the SndView's Snd and sends
              the <b>soundDidChange:</b> message to the delegate. The deletion
              isn't placed on the pasteboard.
*/
- (void)delete:(id)sender;

/*!
  @method paste:
  @param  sender is an id.
  @discussion Replaces the current selection with a copy of the sound data
              currently on the pasteboard. If there is no selection the pasteboard
              data is inserted at the cursor position. The pasteboard data must be
              compatible with the SndView's data, as determined by the Snd
              method <b>compatibleWith:</b>. If the paste is successful, the
              <b>soundDidChange:</b> message is sent to the delegate.
*/
- (void)paste:(id)sender;

/*!
  @method selectAll:
  @param  sender is an id.
  @discussion Creates a selection over the SndView's entire Snd.
*/
- (void)selectAll:(id)sender;

/*!
  @method delegate
  @result Returns an id.
  @discussion Returns the SndView's delegate object.
*/
- delegate;

/*!
  @method didPlay:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- didPlay:sender duringPerformance: performance;

/*!
  @method didRecord:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- didRecord:sender;

/*!
  @method displayMode
  @result Returns an int.
  @discussion Returns the SndView's display mode, one of NX_SOUNDVIEW_WAVE
              (oscilloscopic display) or NX_SOUNDVIEW_MINMAX (minimum/maximum
              display; this is the default).
*/
- (int)displayMode;

/*!
  @method drawSamplesFrom:to:
  @param  first is an int.
  @param  last is an int.
  @result Returns an id.
  @discussion Redisplays the given range of samples. Returns YES if there is data
              that can be displayed, NO otherwise.
*/
- drawSamplesFrom:(int)first to:(int)last;

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
- (void)drawRect:(NSRect)rects;

/*!
  @method getSelection:size:
  @param  firstSample is an int *.
  @param  sampleCount is an int *.
  @discussion Returns the selection by reference. The index of the selection's
              first sample (counting from 0) is returned in <i>firstSample</i>.
              The size of the selection in samples is returned in
              <i>sampleCount</i>. 
*/
- getSelection:(int *)firstSample size:(int *)sampleCount;

/*!
  @method setSelection:size:
  @param  firstSample is an int.
  @param  sampleCount is an int.
  @discussion Sets the selection to be <i>sampleCount</i> samples wide, starting
              with sample <i>firstSample</i> (samples are counted from
              0).
*/
- (void)setSelection:(int)firstSample size:(int)sampleCount;

/*!
  @method hadError:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- hadError:sender;

/*!
  @method initWithFrame:
  @param  frameRect is a NSRect.
  @result Returns an id.
  @discussion Initializes the SndView, fitting the object within the rectangle
              pointing to by <i>frameRect</i>. The initialized SndView doesn't
              contain any sound data.   Returns <b>self</b>.
*/
- initWithFrame:(NSRect)frameRect;

/*!
  @method isAutoScale
  @result Returns a BOOL.
  @discussion Returns YES if the SndView is in autoscaling mode, otherwise
              returns NO.
*/
- (BOOL)isAutoScale;

/*!
  @method isBezeled
  @result Returns a BOOL.
  @discussion Returns YES if the SndView has a bezeled border, otherwise returns
              NO (the default).
*/
- (BOOL)isBezeled;

/*!
  @method isContinuous
  @result Returns a BOOL.
  @discussion Returns YES if the SndView responds to mouse-dragged events (as
              set through <b>setContinuous:</b>). The default is NO.
*/
- (BOOL)isContinuous;

/*!
  @method isEditable
  @result Returns a BOOL.
  @discussion Returns YES if the SndView's sound data can be
              edited.
*/
- (BOOL)isEditable;

/*!
  @method isEnabled
  @result Returns a BOOL.
  @discussion Returns YES if the SndView is enabled, otherwise returns NO. The
              mouse has no effect in a disabled SndView. By default, a SndView
              is enabled.
*/
- (BOOL)isEnabled;

/*!
  @method isOptimizedForSpeed
  @result Returns a BOOL.
  @discussion Returns YES if the SndView is optimized for speedy display.
              SndViews are optimized by default.
*/
- (BOOL)isOptimizedForSpeed;

/*!
  @method isPlayable
  @result Returns a BOOL.
  @discussion Returns YES if the SndView's sound data can be played without
              first being converted.
*/
- (BOOL)isPlayable;
- (float)getDefaultRecordTime;

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
- (void)mouseDown:(NSEvent *)theEvent;

/*!
  @method pasteboard:provideData:
  @param  thePasteboard is a NSPasteboard *.
  @param  type is a NSString *.
  @discussion Places the SndView's entire sound on the given pasteboard.
              Currently, the <i>type</i> argument must be &#ldquo;NXSoundPboardType&#rdquo;,
              the pasteboard type that represents sound data.
*/
- (void)pasteboard:(NSPasteboard *)thePasteboard provideDataForType:(NSString *)pboardType;

/*!
  @method pause:
  @param  sender is an id.
  @discussion Pauses the current playback or recording session by invoking Snd's
              <b>pause:</b> method.
*/
- (void)pause:sender;

/*!
  @method play:
  @param  sender is an id.
  @discussion Play the current selection by invoking Snd's <b>play:</b> method.
              If there is no selection, the SndView's entire Snd is played.
              The <b>willPlay:</b> message is sent to the delegate before the
              selection is played; <b>didPlay:</b> is sent when the selection is
              done playing.
*/
- (void)play:sender;

/*!
  @method resume:
  @param  sender is an id.
  @discussion Resumes the current playback or recording session by invoking
              Snd's <b>resume:</b> method.
*/
- (void)resume:sender;

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
- (void)record:sender;

/*!
  @method stop:
  @param  sender is an id.
  @discussion Stops the SndView's current recording or playback.
*/
- (void)stop:(id)sender;

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
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)thePasteboard;

/*!
  @method reductionFactor
  @result Returns a float.
  @discussion Returns the SndView's reduction factor, computed as follows:
                            
              <tt>reductionFactor = sampleCount / displayUnits</tt>
*/
- (float)reductionFactor;

/*!
  @method setReductionFactor:
  @param  reductionFactor is a float.
  @result Returns a BOOL.
  @discussion Recomputes the size of the SndView's frame, if autoscaling is
              disabled. The frame's size (in display units) is set according to
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
- (BOOL)setReductionFactor:(float)redFactor;

/*!
  @method scaleToFit
  @discussion Recomputes the SndView's reduction factor to fit the sound data
              (horizontally) within the current frame. Invoked automatically when
              the SndView's data changes and the SndView is in autoscale mode.
              If the SndView isn't in autoscale mode, <b>sizeToFit</b> is
              invoked when the data changes. You never invoke this method
              directly; a subclass can reimplement this method to provide
              specialized behavior.
*/
- scaleToFit;

/*!
  @method sizeToFit
  @discussion Resizes the SndView's frame (horizontally) to maintain a constant
              reduction factor. This method is invoked automatically when the
              SndView's data changes and the SndView isn't in autoscale mode.
              If the SndView is in autoscale mode, <b>scaleToFit</b> is invoked
              when the data changes. You never invoke this method directly; a
              subclass can reimplement this method to provide specialized
              behavior.
*/
- (void)sizeToFit;

/*!
  @method sizeToFit:
  @param  withAutoscaling is a BOOL.
  @discussion Resizes the SndView's frame (horizontally) to maintain a constant
              reduction factor. This method is invoked automatically when the
              SndView's data changes and the SndView isn't in autoscale mode.
              If the SndView is in autoscale mode, <b>scaleToFit</b> is invoked
              when the data changes. You never invoke this method directly; a
              subclass can reimplement this method to provide specialized
              behavior.
*/
- (void)sizeToFit:(BOOL)withAutoscaling;

/*!
  @method setAutoscale:
  @param  aFlag is a BOOL.
  @discussion Sets the SndView's automatic scaling mode, used to determine how
              the SndView is redisplayed when its data changes. With autoscaling
              enabled (<i>aFlag</i> is YES), the SndView's reduction factor is
              recomputed so the sound data fits within the view frame. If it's
              disabled (<i>aFlag</i> is NO), the frame is resized and the
              reduction factor is unchanged. If the SndView is in an
              NSScrollView, autoscaling should be disabled (autoscaling is
              disabled by default).
*/
- setAutoscale:(BOOL)aFlag;

/*!
  @method setBezeled:
  @param  aFlag is a BOOL.
  @discussion If <i>aFlag</i> is YES, the display is given a bezeled border. By
              default, the border of a SndView display isn't bezeled. If
              autodisplay is enabled, the Snd is automatically
              redisplayed.
*/
- (void)setBezeled:(BOOL)aFlag;

/*!
  @method setContinuous:
  @param  aFlag is a BOOL.
  @discussion Sets the state of continuous action messages. If <i>aFlag</i> is
              YES, <b>selectionChanged:</b> messages are sent to the delegate as
              the mouse is being dragged. If NO, the message is sent only on mouse
              up. The default is NO. 
*/
- (void)setContinuous:(BOOL)aFlag;

/*!
  @method setDelegate:
  @param  anObject is an id.
  @discussion Sets the SndView's delegate to <i>anObject</i>. The delegate is
              sent messages when the user changes or acts on the
              selection.
*/
- (void)setDelegate:(id)anObject;
- (void)setDefaultRecordTime:(float)seconds;

/*!
  @method setDisplayMode:
  @param  aMode is an int.
  @discussion Sets the SndView's display mode, either NX_SOUNDVIEW_WAVE or
              NX_SOUNDVIEW_MINMAX (the default). If autodisplaying is enabled, the
              Snd is automatically redisplayed.
*/
- (void)setDisplayMode:(int)aMode; /*NX_SOUNDVIEW_WAVE or NX_SOUNDVIEW_MINMAX*/

/*!
  @method setEditable:
  @param  aFlag is a BOOL.
  @discussion Enables or disables editing in the SndView as <i>aFlag</i> is YES
              or NO. By default, a SndView is editable.
*/
- (void)setEditable:(BOOL)aFlag;

/*!
  @method setEnabled:
  @param  aFlag is a BOOL.
  @discussion Enables or disables the SndView as <i>aFlag</i> is YES or NO. The
              mouse has no effect in a disabled SndView. By default, a SndView
              is enabled.
*/
- (void)setEnabled:(BOOL)aFlag;

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
- (void)setOptimizedForSpeed:(BOOL)flag;

/*!
  @method setSound:
  @param  aSound is a Snd *.
  @discussion Sets the SndView's Snd object to <i>aSound</i>. If autoscaling
              is enabled, the drawing coordinate system is adjusted so
              <i>aSound</i>'s data fits within the current frame. Otherwise, the
              frame is resized to accommodate the length of the data. If
              autodisplaying is enabled, the SndView is automatically
              redisplayed.
*/
- (void)setSound:(Snd *)aSound;

/*!
  @method sound
  @result Returns a Snd *.
  @discussion Returns a pointer to the SndView's Snd object.
*/
- sound;

/*!
  @method setFrameSize:
  @param  newSize is a NSSize.
  @discussion Sets the width and height of the SndView's frame. If
              autodisplaying is enabled, the SndView is automatically
              redisplayed.
*/
- (void)setFrameSize:(NSSize)_newSize;

/*!
  @method soundBeingProcessed
  @result Returns an id.
  @discussion Returns the Snd object that's currently being played or recorded
              into. Note that the actual Snd object that's being performed isn't
              necessarily the object returned by SndView's <b>sound </b>method;
              for efficiency, SndView creates a private performance Snd
              object. While this is generally an implementation detail, this
              method is supplied in case the SndView's delegate needs to know
              exactly which object will be (or was) performed.
*/
- soundBeingProcessed;

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
- (void)tellDelegate:(SEL)theMessage;

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
- (void)tellDelegate:(SEL)theMessage duringPerformance: performance;

/*!
  @method validRequestorForSendType:returnType:
  @param  sendType is a NSString *.
  @param  returnType is a NSString *.
  @result Returns an id.
  @discussion You never invoke this method; it's implemented to support services
              that act on sound data.
*/
- validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType;

/*!
  @method willPlay:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
- (void)willPlay:sender duringPerformance: performance;

/*!
  @method willRecord:
  @param  sender is an id.
  @discussion Used to redirect delegate messages from the SndView's Snd
              object; you never invoke this method directly.
*/
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
********************************************/
@end

#endif
