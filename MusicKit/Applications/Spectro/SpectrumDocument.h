/* 
 * $Id$
 * Interface for SpectrumDocument class
 *
 * This object manages the computation and display of Spectrum data
 * via the SpectrumWindow, SpectrumView, ScrollingSpectrum, and the
 * SignalProcessor.
 
 * An instance of this object is created for each separate sound.
 *
 * Created by Gary Scavone.
 *
 * Modifications Copyright (c) 2003 The MusicKit Project, All Rights Reserved.
 *
 * Legal Statement Covering Additions by The MusicKit Project:
 *
 *   Permission is granted to use and modify this code for commercial and
 *   non-commercial purposes so long as the author attribution and copyright
 *   messages remain intact and accompany all relevant code.
 *
 */

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>
#import "SpectrumView.h"

@interface SpectrumDocument: NSObject
{
    IBOutlet id spectrumWindow;
    IBOutlet id scrollSpectrum;
    IBOutlet id waterfallWindow;
    IBOutlet id myWaterfallView;
    IBOutlet id mySignalProcessor;
    IBOutlet id mySound;
    IBOutlet id delegate;
    IBOutlet id waterFallButton;
    IBOutlet id cursorFreq;
    IBOutlet id cursorAmp;
    IBOutlet id sineError;
    IBOutlet id peakFreqCell;
    IBOutlet id windowSizeCell;
    IBOutlet id freqRangeMatrix;
    IBOutlet id wfFreqRangeMatrix;
    IBOutlet id wfTimeRangeMatrix;
    IBOutlet id wfPlotHeight;
    IBOutlet id dBLimitsMatrix;
    IBOutlet id zpFactorCell;
    IBOutlet id hopRatioCell;
    IBOutlet id windowTypeButton;
    IBOutlet id frameSlider;
    IBOutlet id wfFrameSlider;
    IBOutlet id currentFrameCell;
    IBOutlet id wfCurrentFrameCell;
    IBOutlet id wfCurrentFrameTime;
    IBOutlet id totalFramesCell;
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
    SndView *mySoundView;
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
