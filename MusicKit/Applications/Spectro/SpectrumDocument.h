/* SpectrumDocument.h -- Interface for SpectrumDocument class
 *
 * This object manages the computation and display of Spectrum data
 * via the SpectrumWindow, SpectrumView, ScrollingSpectrum, and the
 * SignalProcessor.
 
 * An instance of this object is created for each separate sound.
 *
 * Created by Gary Scavone.  Last modified: 4/94.
 *
 */

#import <Foundation/NSObject.h>
#import "SubSoundView.h"
#import "SpectrumView.h"

@interface SpectrumDocument:NSObject
{
    id spectrumWindow;
    id scrollSpectrum;
	id waterfallWindow;
	id myWaterfallView;
	id mySignalProcessor;
	id mySound;
	id delegate;
    id waterFallButton;
	id cursorFreq;
	id cursorAmp;
	id sineError;
	id peakFreqCell;
	id windowSizeCell;
	id freqRangeMatrix;
	id wfFreqRangeMatrix;
	id wfTimeRangeMatrix;
	id wfPlotHeight;
	id dBLimitsMatrix;
	id zpFactorCell;
	id hopRatioCell;
	id windowTypeButton;
	id frameSlider;
	id wfFrameSlider;
	id currentFrameCell;
	id wfCurrentFrameCell;
	id wfCurrentFrameTime;
	id totalFramesCell;
	int dataSize;
	int windowSize;
	int firstSample;
	int sampleCount;
	int totalFrames;
	int currentFrame;
	int channel;
	int power;
	int lastLength;
	int lobeWidth;
	float hopRatio;
	float displayPoints;
	float zpFactor;
	float *samples;
	float *window;
	float windowArea;
	float ceiling;
	NSString *windowType;
	SubSoundView *mySoundView;
    SpectrumView *mySpectrumView;
	BOOL sliderCall;
	BOOL miniature;
	BOOL newWindow;
	BOOL stop;
	BOOL wfSliderEnabled;
}

- init;
- newSpectrumLocation:(NSPoint *)p;
- newWaterfallLocation:(NSPoint *)p;
- (void)awakeFromNib;
- (void)setDelegate:(id)anObject;
- delegate;
- setSoundView:aSoundView;
- setWindowTitle:(NSString *)aFileName;
- soundChanged;
- printSpectrum;
- printWaterfall;
- displayFreqRange;
- changeFreqRange:sender;
- changeWFFreqRange:sender;
- changedBLimits:sender;
- changeWindowType:sender;
- changeWindowSize:sender;
- changeZPFactor:sender;
- changeHopRatio:sender;
- nextFrame:sender;
- disableWFSlider;
- setTotalFrames;
- frameSliderMoved:sender;
- wfFrameSliderMoved:sender;
- wfPlotHeightChanged:sender;
- spectroButtonDepressed;
- doSpectrum;
- doWaterfall:sender;
- checkStopButton;
- interpolatePeak:sender;
- closeWindows;
- setViewColors;

@end

@interface SpectrumDocument(SpectrumViewDelegate)

- cursorMoved:sender;

@end

@interface SpectrumDocument(ScrollingSpectrumDelegate)

- spectrumMoved:sender;

@end

@interface SpectrumDocument(WindowDelegate)

- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidMiniaturize:(NSNotification *)notification;
- (void)windowDidDeminiaturize:(NSNotification *)notification;

@end