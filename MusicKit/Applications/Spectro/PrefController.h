
#import <AppKit/AppKit.h>

@interface PrefController:NSObject
{
    id colorView;
    id fftView;
    id spectrumDisplayView;
    id soundDisplayView;
    id multiView;
    IBOutlet NSColorWell *spectrumColorWell;
    IBOutlet NSColorWell *waterfallColorWell;
    IBOutlet NSColorWell *cursorColorWell;
    IBOutlet NSColorWell *gridColorWell;
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
- (void)awakeFromNib;
- setUpWell:well tag:(int)aTag;
- okay:sender;
- defaults:sender;
- setPref:sender;
- setPrefToView:theView;
@end
