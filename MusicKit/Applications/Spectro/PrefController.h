
#import <AppKit/AppKit.h>

@interface PrefController:NSObject
{
    IBOutlet NSColorWell *spectrumColorWell;
    IBOutlet NSColorWell *waterfallColorWell;
    IBOutlet NSColorWell *cursorColorWell;
    IBOutlet NSColorWell *gridColorWell;
    IBOutlet NSColorWell *amplitudeColorWell;
    id colorView;
    id fftView;
    id spectrumDisplayView;
    id soundDisplayView;
    id multiView;
    id window;
    id windowSizeCell;
    id hopRatioCell;
    id zpFactorCell;
    id windowTypeMatrix;
    id spectrumMaxFreqCell;
    id dBLimitCell;
    id wfPlotHeightCell;
    id wfMaxFreqCell;
    id displayMode;
}

- window;
- (void) awakeFromNib;
- okay: sender;
- defaults: sender;
- setPref: sender;
- setPrefToView: theView;
@end
