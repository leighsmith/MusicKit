/* SpectrumDocument.m */

#import "SoundController.h"
#import "SoundDocument.h"
#import "SpectrumDocument.h"
#import "SpectrumView.h"
#import "WaterfallView.h"
#import "SubSoundView.h"
#import "ScrollingSpectrum.h"
#import "SignalProcessor.h"

#import <AppKit/AppKit.h>
#import <string.h>
#import <Foundation/NSUserDefaults.h>
#import <math.h>
#import <stdlib.h>
#import <Foundation/NSByteOrder.h>
#import <SndKit/Snd.h>

#define SWAP(int) NSSwapBigShortToHost(int)
#define PUTVAL(cell,f)	[cell setStringValue:[NSString stringWithCString:doFloat(f, 2, 3)]]
#define M 32768

@implementation SpectrumDocument

- init
{
    NSRect theFrame;

    [super init];
    [NSBundle loadNibNamed:@"spectrum.nib" owner:self];
    [spectrumWindow setDelegate:self];
    theFrame = [spectrumWindow frame];
    [self newSpectrumLocation:&theFrame.origin];
    [spectrumWindow setFrameOrigin:NSMakePoint(theFrame.origin.x, theFrame.origin.y)];
    [spectrumWindow makeKeyAndOrderFront:nil];
        [waterfallWindow setDelegate:self];
    theFrame = [waterfallWindow frame];
    [self newWaterfallLocation:&theFrame.origin];
    [waterfallWindow setFrameOrigin:NSMakePoint(theFrame.origin.x, theFrame.origin.y)];
        [myWaterfallView setDelegate:self];
        [scrollSpectrum setDelegate:self];
    mySpectrumView = [scrollSpectrum spectrumView];
        [mySpectrumView setDelegate:self];
        mySignalProcessor = [[SignalProcessor alloc] init];
        currentFrame = 0;
        lastLength = 0;
        lobeWidth = 0;
        sliderCall = NO;
        miniature = NO;
        newWindow = YES;
        stop = NO;
        wfSliderEnabled = NO;
    return self;
}

- newSpectrumLocation:(NSPoint *)p
{
    int cnt, count = [[NSApp delegate] documentCount] - 1;
        if (count < 0) count = 7;

        cnt = (count > 3)? count - 4 : count;
        p->x += (20.0 * count);
        p->y -= (25.0 * cnt);
        return self;
}

- newWaterfallLocation:(NSPoint *)p
{
    int cnt, count = [[NSApp delegate] documentCount] - 1;
        if (count < 0) count = 7;

    cnt = (count > 3)? count - 4 : count;
        p->x += (10.0 * cnt);
    p->y -= (25.0 * count);
        return self;
}

- (void)awakeFromNib
{
        int dBLimit, i;
        float plotHeight;

        windowSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"WindowSize"] intValue];
        [windowSizeCell setIntValue:windowSize];

        hopRatio = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HopRatio"] floatValue];
        PUTVAL(hopRatioCell, hopRatio);

        zpFactor = [[[NSUserDefaults standardUserDefaults] objectForKey:@"ZPFactor"] floatValue];
        dataSize = windowSize * zpFactor;
        power = 0.999 + log((double) dataSize) / log(2.0);
        dataSize = pow(2.0, power);
        zpFactor = (float)dataSize / windowSize;
        PUTVAL(zpFactorCell, zpFactor);
        samples = (float *)malloc(dataSize * sizeof(float));

        dBLimit = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dBLimit"] floatValue];
        for (i=0; i<5; i++) {
                [[dBLimitsMatrix cellAtRow:i column:0] setStringValue:
                   [NSString stringWithFormat:@"%i dB",dBLimit * i/4]];
        }

        plotHeight = [[[NSUserDefaults standardUserDefaults] objectForKey:@"WFPlotHeight"] floatValue];
        [wfPlotHeight setFloatValue:plotHeight];

        [frameSlider setMinValue:1.0];

        windowType = [[NSUserDefaults standardUserDefaults] objectForKey:@"WindowType"];

        [windowTypeButton selectItemWithTitle:windowType];
}

- (void)setDelegate:(id)anObject
{
        delegate = anObject;
        [(SoundController *)[NSApp delegate] setDocument:delegate];
}

- delegate
{
        return delegate;
}

- setSoundView:aSoundView
{
        int i;
        int sMaxFreq, wfMaxFreq;
        float srate;
        float *w;
        NSBundle *mainB = [NSBundle mainBundle];
        
        mySoundView = aSoundView;
        mySound = [mySoundView sound];
        srate = [mySound samplingRate];

        if  ([mySound channelCount] > 1) {
                channel = 1 +
                    NSRunAlertPanel(
                        [mainB localizedStringForKey:@"Spectro is Confused" value:@"Spectro is Confused" table:nil],
                        [mainB localizedStringForKey:@"The Current Sound" value:@"The Current Sound" table:nil],
                        [mainB localizedStringForKey:@"Both Mixed" value:@"Both Mixed" table:nil],
                        [mainB localizedStringForKey:@"Right" value:@"Right" table:nil],
                        [mainB localizedStringForKey:@"Left" value:@"Left" table:nil]);
        }
        else channel = -1;	/* Mixed = 2, Right = 1, Left = 0, One = -1 */

        sMaxFreq = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumMaxFreq"] intValue];
        wfMaxFreq = [[[NSUserDefaults standardUserDefaults] objectForKey:@"WFMaxFreq"] intValue];
        if (sMaxFreq > (srate/2))
                sMaxFreq = srate/2;
        if (wfMaxFreq > (srate/2))
                wfMaxFreq = srate/2;
        for (i=0; i<5; i++) {
                [[freqRangeMatrix cellAtRow:0 column:i] setStringValue:
                    [NSString stringWithFormat:@"%i Hz",sMaxFreq * i/4]];
        }
        for (i=0; i<5; i++) {
                [[wfFreqRangeMatrix cellAtRow:0 column:i] setStringValue:
                    [NSString stringWithFormat:@"%i Hz",wfMaxFreq * i/4]];
        }
        displayPoints = (float) sMaxFreq * dataSize / srate;
        [scrollSpectrum setDisplayPoints:displayPoints];

        w = (float *)malloc((1+windowSize) * sizeof(float));
        for (i = 0; i<windowSize; i++) w[i] = 1.0;
        [mySignalProcessor window:windowSize array:w type:windowType];
        windowArea = 0.0;
        for (i = 0; i<windowSize; i++) windowArea += w[i];
        ceiling = 65536.0 * 65536.0 * windowArea * windowArea;
        free(w);//sb
        return self;
}

- setWindowTitle:(NSString *)aFileName
{
        [spectrumWindow setTitle:[@"SPECTRUM:   " stringByAppendingString:aFileName]];
        [waterfallWindow setTitle:[@"WATERFALL:   " stringByAppendingString:aFileName]];
        return self;
}

- soundChanged
{
        mySound = [mySoundView sound];
        return self;
}

- printSpectrum
{
        [spectrumWindow print:self];
        return self;
}

- printWaterfall
{
        [waterfallWindow print:self];
        return self;
}

- displayFreqRange
{
/* This method is called by "displayChanged" to reflect scrolling.
 * Also, it is called by the method "changeFreqRange".
 */
        int i, temp;
        float start, size, startFreq, freqDur;
        float srate;

/* Get the starting and number of data points from the ScrollingSpectrum,
 * convert them to frequencies, and show them in the appropriate Forms
 */
        if (!mySound) return nil;
        srate = [mySound samplingRate];
        [scrollSpectrum getWindowPoints:&start Size:&size];
        startFreq = (float) start * srate / dataSize;
        freqDur = (float) size * srate / dataSize;
    for (i=0; i<5; i++) {
                temp = (int) startFreq + freqDur * i/4;
                [[freqRangeMatrix cellAtRow:0 column:i]
                       setStringValue:[NSString stringWithFormat:@"%i Hz",temp]];
        }
        return self;
}

- changeFreqRange:sender
{
/* This method is called via a change in the frequency range text cells
 * and after the windowSize or ZPFactor has been changed.
 */

        int minFreq, maxFreq;
        float srate, halfRate;

        srate = [mySound samplingRate];
        minFreq = [[freqRangeMatrix cellAtRow:0 column:0] intValue];
        if (minFreq < 0) {
                minFreq = 0;
                [[freqRangeMatrix cellAtRow:0 column:0] setStringValue:
                             [NSString stringWithFormat:@"%i Hz",minFreq]];
        }
        maxFreq = [[freqRangeMatrix cellAtRow:0 column:4] intValue];
        if (maxFreq > (halfRate = srate/2)) {
                maxFreq = halfRate;
                [[freqRangeMatrix cellAtRow:0 column:4] setStringValue:
                          [NSString stringWithFormat:@"%i Hz",maxFreq]];
        }
        displayPoints = (float) (maxFreq - minFreq) * dataSize / srate;
        [scrollSpectrum setDisplayPoints:displayPoints];
        [scrollSpectrum setWindowStart:(int) minFreq * dataSize / srate];
        [mySpectrumView setNeedsDisplay:YES];
        [self displayFreqRange];
        return self;
}

- changeWFFreqRange:sender
{
/* This method is called via a change in the waterfall maximum
 * frequency range text cell.
 */

        int i, maxFreq, temp;
        float srate, halfRate;

        srate = [mySound samplingRate];
        maxFreq = [[wfFreqRangeMatrix cellAtRow:0 column:4] intValue];
        if (maxFreq > (halfRate = srate/2) || maxFreq < 0) {
                maxFreq = halfRate;
        }
    for (i=0; i<5; i++) {
                temp = (int) maxFreq * i/4;
                [[wfFreqRangeMatrix cellAtRow:0 column:i] setStringValue:
                          [NSString stringWithFormat:@"%i Hz",temp]];
        }
        [self doWaterfall:self];
        return self;
}

- changedBLimits:sender
{
/* This method is called only via a change in the dB Limit text cell. */

    int temp, i;

    temp = [sender intValue];
    if (temp > 0) temp = -temp;
    for (i=0; i<5; i++) {
                    [[dBLimitsMatrix cellAtRow:i column:0] setStringValue:
                      [NSString stringWithFormat:@"%i dB",temp * i/4]];
        }
        [self doSpectrum];
        return self;
}

- changeWindowType:sender
{
    windowType = [sender titleOfSelectedItem];
    [self changeWindowSize:self];
    newWindow = YES;
    wfSliderEnabled = NO;
    return self;
}

- changeWindowSize:sender
{
/* This method checks all the FFT control parameter cells and sets
 * appropriate values.  It is called directly from the window size
 * cell as well as by changeHopRatio, changeZPFactor, and
 * changeWindowType.
 */
        int i;
        float temp;
        float *w;

        windowSize = [windowSizeCell intValue];
        if (windowSize <= 0) {
                windowSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"WindowSize"] intValue];
                [windowSizeCell setIntValue:windowSize];
        }
        hopRatio = [hopRatioCell floatValue];
        if (hopRatio <= 0.0) {
            hopRatio = [[[NSUserDefaults standardUserDefaults] objectForKey:@"HopRatio"] floatValue];
                PUTVAL(hopRatioCell, hopRatio);
        }
        else PUTVAL(hopRatioCell, hopRatio);
        zpFactor = [zpFactorCell floatValue];
        if (zpFactor < 1.0 || zpFactor > 30)
                zpFactor = 1.0;
        temp = (float) displayPoints / dataSize;
        dataSize = windowSize * zpFactor;
        power = 0.999 + log((double) dataSize) / log(2.0);
        dataSize = pow(2.0, power);
        zpFactor = (float)dataSize / windowSize;
        PUTVAL(zpFactorCell, zpFactor);
        if (samples)
                free(samples);
        samples = (float *)malloc(dataSize * sizeof(float));
        currentFrame = 0;
        displayPoints = (float) temp * dataSize;
        [scrollSpectrum setDisplayPoints:displayPoints];
        w = (float *)malloc((1+windowSize) * sizeof(float));
        for (i = 0; i<windowSize; i++) w[i] = 1.0;
        [mySignalProcessor window:windowSize array:w type:windowType];
        windowArea = 0.0;
        for (i = 0; i<windowSize; i++) windowArea += w[i];
        ceiling = 65536.0 * 65536.0 * windowArea * windowArea;
        wfSliderEnabled = NO;
        free(w);//sb
        [self doSpectrum];
        return self;
}

- changeZPFactor:sender
{
/* This method is called via a change in the ZPFactor form cell.
 * This value is compared with the current window size and adjusted
 * to the next closest power of 2 higher.
 */	
        float startZPFactor;
        int startWindowSize;
        BOOL check = wfSliderEnabled;

        startWindowSize = [windowSizeCell intValue];
        startZPFactor = zpFactor;
        [self changeWindowSize:self];
        if ((startZPFactor == [zpFactorCell floatValue]) &&
                (startWindowSize == [windowSizeCell intValue]) &&
                check) wfSliderEnabled = YES;
        return self;
}

- changeHopRatio:sender
{
// This method is called only via a change in the hop size form cell.

        [self changeWindowSize:self];
        return self;
}

- nextFrame:sender
{
        int startSamp;

        currentFrame += 1;
        if (currentFrame > (totalFrames - 1)) {
                currentFrame = totalFrames - 1;
                return self;
        }
        [self doSpectrum];
        startSamp = currentFrame * hopRatio * windowSize + firstSample;
        if (wfSliderEnabled) {
                [wfFrameSlider setIntValue:currentFrame];
                [myWaterfallView placeSliderLineAt:currentFrame];
                [wfCurrentFrameCell setIntValue:currentFrame + 1];
                [wfCurrentFrameTime setFloatValue:(float) startSamp / [mySound samplingRate]];
        }
        return self;
}

- disableWFSlider
{
        wfSliderEnabled = NO;
        return self;
}

- setTotalFrames
{
/* This method recalculates the total number of frames to be processed.
 * It is called when the sound selection changes, when the hop time
 * changes, and when the window size changes.
 */	
        int diff, hopSize;

        [mySoundView getSelection:&firstSample size:&sampleCount];
        hopSize = hopRatio * windowSize;
        if (!hopRatio) totalFrames = 0;
        else {
                if ((diff = sampleCount - windowSize) < 0)
                        totalFrames = 0;
                else totalFrames = diff / hopSize + 1;
        }
        [totalFramesCell setIntValue:totalFrames];
        return self;
}

- frameSliderMoved:sender
{
        int startSamp;

        if (currentFrame == ([sender intValue] - 1)) return self;
        sliderCall = YES;
        currentFrame = [sender intValue] - 1;
        startSamp = currentFrame * hopRatio * windowSize + firstSample;
        if (wfSliderEnabled) {
                [wfFrameSlider setIntValue:currentFrame];
                [myWaterfallView placeSliderLineAt:currentFrame];
                [wfCurrentFrameCell setIntValue:currentFrame + 1];
                [wfCurrentFrameTime setFloatValue:(float) startSamp / [mySound samplingRate]];
        }
        [self doSpectrum];
        return self;
}

- wfFrameSliderMoved:sender
{
        int temp, startSamp;

        temp = [sender intValue];
        if (currentFrame == temp) return self;
        if (temp > totalFrames - 1) return self;
        currentFrame = temp;
        startSamp = currentFrame * hopRatio * windowSize + firstSample;
        [myWaterfallView placeSliderLineAt:currentFrame];
        [wfCurrentFrameCell setIntValue:currentFrame + 1];
        [wfCurrentFrameTime setFloatValue:(float) startSamp / [mySound samplingRate]];
        [self doSpectrum];
        return self;
}

- wfPlotHeightChanged:sender
{
        if ([sender floatValue] < 1) [sender setFloatValue:1.0];
        [self doWaterfall:self];
        return self;
}

- spectroButtonDepressed
{
    [spectrumWindow makeKeyAndOrderFront:nil];
        [self doSpectrum];
        return self;
}

- doSpectrum
{
    int i, startSample, hopSize;
    short swappedInt;
    unsigned char *mulawData;
    short *linearData;
    float floor;
    NSBundle *mainB = [NSBundle mainBundle];
    
    if ((windowSize != [windowSizeCell intValue]) ||
        (![[NSString stringWithCString:doFloat(hopRatio, 2, 3)] isEqualToString:[hopRatioCell stringValue]]) ||
        (![[NSString stringWithCString:doFloat(zpFactor, 2, 3)] isEqualToString:[zpFactorCell stringValue]]))
        [self changeWindowSize:self];
    [self setTotalFrames];
    if (!totalFrames) {
        NSRunAlertPanel(
            [mainB localizedStringForKey:@"Alert" value:@"Alert" table:nil],
            [mainB localizedStringForKey:@"Sound Selection" value:@"Sound Selection" table:nil],
            [mainB localizedStringForKey:@"OK" value:@"OK" table:nil],
           nil, nil);
        [mySpectrumView frames:NO];
        [mySpectrumView drawSpectrum:(int)(dataSize/2) array:NULL];
        currentFrame = 0;
        [frameSlider setIntValue:1];
        [currentFrameCell setIntValue:0];
        return self;
        }
    [mySpectrumView frames:YES];
    hopSize = hopRatio * windowSize;
    [frameSlider setMaxValue:(double)totalFrames];
    if (totalFrames <= currentFrame)
        currentFrame = totalFrames - 1;
    floor = [[dBLimitsMatrix cellAtRow:4 column:0] floatValue];
    startSample = currentFrame*hopSize + firstSample;

    if ([mySound dataFormat] == SND_FORMAT_MULAW_8) {
        mulawData = [(Snd *) mySound data];
        for (i=0; i<windowSize; i++)
            samples[i] = (float) SndMuLawToLinear(mulawData[startSample + i]);
    }
    else {
        linearData = (short *)[(Snd *)mySound data];
        if (channel == 2) 		/* Both Mixed */
            for (i=0; i<windowSize; i++) {
                swappedInt = SWAP((linearData[2*(startSample + i)]
                                   + linearData[2*(startSample + i) + 1]) * 0.5);
                samples[i] = (float) swappedInt;
            }

        if (channel == 1)		/* Right Only */
            for (i=0; i<windowSize; i++) {
                swappedInt = SWAP(linearData[2*(startSample + i) + 1]);
                samples[i] = (float) swappedInt;
                }

        if (channel == 0)		/* Left Only */
            for (i=0; i<windowSize; i++) {
                swappedInt = SWAP(linearData[2*(startSample + i)]);
                samples[i] = (float) swappedInt;
                }

        if (channel == -1)		/* Mono File */
            for (i=0; i<windowSize; i++) {
                swappedInt = SWAP(linearData[startSample + i]);
                samples[i] = (float) swappedInt;
                }
    }
    for (i=windowSize; i<dataSize; i++) samples[i] = 0.0;
    [mySignalProcessor window:windowSize array:samples type:windowType];
    if (power%2 == 0)
        [mySignalProcessor fhtRX4:power/2 array:samples];
        else
            [mySignalProcessor fftRX2:power array:samples];
    [mySignalProcessor logMag:dataSize array:samples floor:floor ceiling:ceiling];
    [mySpectrumView drawSpectrum:(int)(dataSize/2) array:samples];

    [currentFrameCell setIntValue:currentFrame + 1];
    if (sliderCall){
        sliderCall = NO;
        return self;
        }
    [frameSlider setIntValue:currentFrame + 1];
    return self;
}

- doWaterfall:sender
{
        int i, k, j, hopSize, maxFreq;
        short swappedInt;
        unsigned char *mulawData;
        short *linearData;
        float floor, srate;
        float startTime, timeDur;
        NSBundle *mainB = [NSBundle mainBundle];
        
        if (stop) {
                stop = NO;
                return self;
        }
        if ((windowSize != [windowSizeCell intValue]) ||
                        (![[NSString stringWithCString:doFloat(hopRatio, 2, 3)] isEqualToString:[hopRatioCell stringValue]]) ||
                        (![[NSString stringWithCString:doFloat(zpFactor, 2, 3)] isEqualToString:[zpFactorCell stringValue]]))
                [self changeWindowSize:self];
        [self setTotalFrames];
        if (!totalFrames) {
                NSRunAlertPanel(
                    [mainB localizedStringForKey:@"Alert" value:@"Alert" table:nil],
                    [mainB localizedStringForKey:@"Sound Selection" value:@"Sound Selection" table:nil],
                    [mainB localizedStringForKey:@"OK" value:@"OK" table:nil], nil, nil);
                [mySpectrumView frames:NO];
                currentFrame = 0;
                [wfFrameSlider setIntValue:0];
                [wfCurrentFrameCell setIntValue:0];
                [waterFallButton setState:0];
                return self;
        }
        [mySpectrumView frames:YES];
        [waterfallWindow makeKeyAndOrderFront:nil];
        hopSize = hopRatio * windowSize;
        srate = [mySound samplingRate];
        [wfFrameSlider setMaxValue:(double)totalFrames+2];
        floor = [[dBLimitsMatrix cellAtRow:4 column:0] floatValue];
        maxFreq = [[wfFreqRangeMatrix cellAtRow:0 column:4] intValue];
        [myWaterfallView setup:totalFrames
                                length:(int) (dataSize * maxFreq / srate)];

        for (j=totalFrames-1; j>=0; j--) {
                k = j * hopSize;

                if ([mySound dataFormat] == SND_FORMAT_MULAW_8) {
                        mulawData = [(Snd *)mySound data];
                        for (i=0; i<windowSize; i++)
                                samples[i] = (float) SndMuLawToLinear(mulawData[firstSample + k + i]);
                }
                else {
                        linearData = (short *)[(Snd *)mySound data];
                        if (channel == 2) 		/* Both Mixed */
                                for (i=0; i<windowSize; i++) {
                                        swappedInt = SWAP((linearData[2*(firstSample + k + i)]
                                                        + linearData[2*(firstSample + k + i) + 1]) * 0.5);
                                        samples[i] = (float) swappedInt;
                                }

                        if (channel == 1)		/* Right Only */
                                for (i=0; i<windowSize; i++) {
                                        swappedInt = SWAP(linearData[2*(firstSample + k + i) + 1]);
                                        samples[i] = (float) swappedInt;
                                }

                        if (channel == 0)		/* Left Only */
                           for (i=0; i<windowSize; i++) {
                                        swappedInt = SWAP(linearData[2*(firstSample + k + i)]);
                                        samples[i] = (float) swappedInt;
                                }

                        if (channel == -1)		/* Mono File */
                            for (i=0; i<windowSize; i++) {
                                        swappedInt = SWAP(linearData[firstSample + k + i]);
                                        samples[i] = (float) swappedInt;
                                }
                }
        for (i=windowSize; i<dataSize; i++) samples[i] = 0.0;
        [mySignalProcessor window:windowSize array:samples type:windowType];
        if (power%2 == 0)
                [mySignalProcessor fhtRX4:power/2 array:samples];
        else
                [mySignalProcessor fftRX2:power array:samples];
        [mySignalProcessor logMag:dataSize array:samples floor:floor ceiling:ceiling];
        [myWaterfallView storeNext:samples];
        [self checkStopButton];
        if (stop) break;
        }
        startTime = (float) firstSample / srate;
        timeDur = (float) ((totalFrames-1) * hopRatio * windowSize + windowSize) / srate;
        for (i=0; i<5; i++)
                [[wfTimeRangeMatrix cellAtRow:4-i column:0] setFloatValue:startTime + timeDur * i * 0.25];

        currentFrame = 0;
        [wfCurrentFrameCell setIntValue:currentFrame + 1];
        [wfCurrentFrameTime setFloatValue:startTime];
        [wfFrameSlider setIntValue:currentFrame];
        [myWaterfallView placeSliderLineAt:currentFrame];
        [self doSpectrum];
        wfSliderEnabled = YES;
        [waterFallButton setState:0];
        [myWaterfallView setNeedsDisplay:YES];
        return self;
}

- checkStopButton
{
/* This is a hack for checking the stop button.  To be done right,
 * the "doWaterfall" method should be in a separate thread, but I
 * don't have the time to figure that out right now.
 */
        NSRect buttonBounds;
        NSPoint mousePosition;
        int mouseDown;

        mousePosition = [spectrumWindow mouseLocationOutsideOfEventStream];
        buttonBounds = [waterFallButton bounds];
        [waterFallButton convertRect:buttonBounds toView:[waterFallButton superview]];
// sbrandon 17/9/2001 commented out because does not work on MacOSX, and  there should
// be a more elegant solution anyway.
//        PSbuttondown(&mouseDown);
        if ([waterFallButton mouse:mousePosition inRect:buttonBounds]
                                && mouseDown) stop = YES;
        else stop = NO;
        return self;
}

- interpolatePeak:sender
{
        int n, i, max, index, ratio, factor;
        float cursorPoint, peakFreq, alpha, beta, gamma;
        float peakOffset, peakDiff, area, ceil, floor, temp;
        float *w;
        double windowSum, error;
        BOOL reachedEnd = NO;

        if (!totalFrames) return self;
        if (windowSize != lastLength || newWindow) {
                if (window)
                        free(window);
                window = (float *)calloc(3000, sizeof(float));
                w = (float *)malloc(M * sizeof(float));
                for (i = 0; i<windowSize; i++) w[i] = 1.0;
                for (i = windowSize; i<M; i++) w[i] = 0.0;
                [mySignalProcessor window:windowSize array:w type:windowType];
                area = 0.0;
                for (i = 0; i<windowSize; i++) area += w[i];
                ceil = area * area;
                floor = [[dBLimitsMatrix cellAtRow:4 column:0] floatValue];
                factor = 0.5 + log((double) M) / log(2.0);
                [mySignalProcessor fftRX2:factor array:w];
                [mySignalProcessor logMag:M array:w floor:floor ceiling:ceil];
                window[0] = 1.0;
                i = 1;
                while (w[i] > w[i+1]) {
                        window[i] = w[i];
                        i++;
                }
                free(w);//sb
                lobeWidth = i-1;
                lastLength = windowSize;
                newWindow = NO;
        }

        [mySpectrumView getCursorLocation:&cursorPoint];
        n = (int)cursorPoint;
        i = 0;
        if (samples[n] < samples[n+1]) {
                while (samples[n+i] < samples[n+1+i])
                        i++;
                max = n + i;
        }
        else {
                while (samples[n-i] <= samples[n-1-i]) {
                        i++;
                        if (n-i == 0) {
                                reachedEnd = YES;
                                break;
                        }
                }
                if (!n) {
                        reachedEnd = YES;
                        i = 0;
                }
                max = n - i;
        }
        if (reachedEnd) {
                while (samples[n-i] <= samples[n-i+1])
                        i--;
                max = n - i;
        }
        alpha = samples[max-1];
        beta = samples[max];
        gamma = samples[max+1];
        peakOffset = 0.5 * (alpha - gamma) / (alpha - 2*beta + gamma);
        peakFreq = (max + peakOffset) * [mySound samplingRate] / dataSize;
        [mySpectrumView setCursor:max + peakOffset];
        [peakFreqCell setFloatValue:peakFreq];
        ratio = M / dataSize;
        index = fabs(peakOffset * ratio) + 0.5;
        peakDiff = 1 - beta - 0.25 * (alpha - gamma) * peakOffset;
        windowSum = pow(window[index], 2.0);
        error = pow(window[index] - peakDiff - samples[max], 2.0);
        i = 1;
        while (i*ratio <= lobeWidth) {
                if (max-i < 0 || max+i > (dataSize/2 - 1)) break;
                windowSum += pow(window[index+i*ratio], 2.0)
                                        + pow(window[i*ratio-index], 2.0);
                error += pow(window[index+i*ratio] - peakDiff - samples[max+i], 2.0) +
                                pow(window[i*ratio-index] - peakDiff - samples[max-i], 2.0);
                i++;
        }
        temp = (float) pow(sqrt(error) / sqrt(windowSum), 0.8);
        PUTVAL(sineError, temp);
        return self;
}

- closeWindows
{
/*sb: I don't think this is necessary any more */
#if 0
    if (miniature) {
                [[spectrumWindow counterpart] close];
                [[waterfallWindow counterpart] close];
        }
#endif
    [spectrumWindow close];
    [waterfallWindow close];
    return self;
}

- setViewColors
{
        [mySpectrumView setColors];
        [myWaterfallView setColors];
        return self;
}

@end

@implementation SpectrumDocument(SpectrumViewDelegate)

- cursorMoved:sender
{
/* This method is sent from the spectrumView as a delegate method
 * when mousedowns are received by the view.
 */
        int i, startFreq, endFreq, dBRange;
        float cursorPoint, fractPoint, frequency, amplitude;

        startFreq = [[freqRangeMatrix cellAtRow:0 column:0] intValue];
        endFreq = [[freqRangeMatrix cellAtRow:0 column:4] intValue];
        dBRange = [[dBLimitsMatrix cellAtRow:4 column:0] intValue];
        [mySpectrumView getCursorLocation:&cursorPoint];
        frequency = (float) cursorPoint * [mySound samplingRate] / dataSize;
        if (frequency < startFreq)
                frequency = startFreq;
        if (frequency > endFreq)
                frequency = endFreq;
        [cursorFreq setFloatValue:frequency];

/* Do a simple linear interpolation between data points in samples array */

        i = (int)cursorPoint;			/* Integer portion of cursor point */
        fractPoint = cursorPoint - i;	/* Fraction portion */
        amplitude = ((samples[i+1] - samples[i]) * fractPoint) + samples[i];
        if (amplitude <= 0) {
              [cursorAmp setStringValue:[NSString stringWithFormat:@"<= %i",dBRange]];
        }
        else [cursorAmp setFloatValue:(1 - amplitude) * dBRange];
        return self;
}

@end

@implementation SpectrumDocument(ScrollingSpectrumDelegate)

- spectrumMoved:sender
{
        [self displayFreqRange];
        return self;
}

@end

@implementation SpectrumDocument(WindowDelegate)

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [spectrumWindow makeFirstResponder:mySpectrumView];
    [(SoundController *)[NSApp delegate] setDocument:delegate];
}

- (void)windowDidMiniaturize:(NSNotification *)notification
{
    miniature = YES;
    [spectrumWindow setMiniwindowImage:[NSImage imageNamed:@"Spectro.tiff"]];
    [spectrumWindow setMiniwindowTitle:@"Spectrum"];
    [waterfallWindow setMiniwindowImage:[NSImage imageNamed:@"Spectro.tiff"]];
    [waterfallWindow setMiniwindowTitle:@"Waterfall"];
}

- (void)windowDidDeminiaturize:(NSNotification *)notification
{
    miniature = NO;
}

@end