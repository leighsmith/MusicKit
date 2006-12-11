/*
  $Id$

*/
#import "PrefController.h"
#import "SpectroController.h"
#import "SoundDocument.h"
#import <AppKit/AppKit.h>
#import <Foundation/NSUserDefaults.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBox.h>

@implementation PrefController

- window
{
    return window;
}

- (void) setUpWell: (NSColorWell *) well tag: (int) aTag
{
    [well setTag: aTag];
    [well setContinuous: YES];
}

// TODO we currently initialize all the preferences in SpectroController.
#if 0
+ (void) initialize;
{    
    [super initialize];    
    
    // register our defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
	    @"1024", @"WindowSize",
	    @"2.0", @"ZPFactor",
	    @"0.5", @"HopRatio",
	    @"Hanning", @"WindowType",
	    @"10000", @"SpectrumMaxFreq",
	    @"-100", @"dBLimit",
	    @"5000", @"WFMaxFreq",
	    @"3.0", @"WFPlotHeight",
	    @"0", @"DisplayType",
	    colorToString([NSColor blackColor]), @"SpectrumColor",
	    colorToString([NSColor greenColor]), @"WaterfallColor",
	    colorToString([NSColor redColor]), @"CursorColor",
	    colorToString([NSColor lightGrayColor]), @"GridColor",
	    colorToString([NSColor blueColor]), @"AmplitudeColor",
	    nil, nil]];	
}
#endif

- (void) awakeFromNib
{
    char const *type;
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    [[NSColorPanel sharedColorPanel] setContinuous: YES];
    [self setUpWell: cursorColorWell tag: 0];
    [self setUpWell: spectrumColorWell tag: 1];
    [self setUpWell: gridColorWell tag: 2];
    [self setUpWell: amplitudeColorWell tag: 3];

    if([standardUserDefaults objectForKey: @"SpectrumColor"] != nil)
	[spectrumColorWell setColor: stringToColor([standardUserDefaults objectForKey: @"SpectrumColor"])];
    if([standardUserDefaults objectForKey: @"WaterfallColor"] != nil)
	[waterfallColorWell setColor: stringToColor([standardUserDefaults objectForKey: @"WaterfallColor"])];
    if([standardUserDefaults objectForKey: @"CursorColor"] != nil)
	[cursorColorWell setColor: stringToColor([standardUserDefaults objectForKey: @"CursorColor"])];
    if([standardUserDefaults objectForKey: @"GridColor"] != nil)
	[gridColorWell setColor: stringToColor([standardUserDefaults objectForKey: @"GridColor"])];
    if([standardUserDefaults objectForKey: @"AmplitudeColor"] != nil)
	[amplitudeColorWell setColor: stringToColor([standardUserDefaults objectForKey: @"AmplitudeColor"])];
    
    [windowSizeCell setStringValue: [standardUserDefaults objectForKey: @"WindowSize"]];
    [zpFactorCell setStringValue: [standardUserDefaults objectForKey: @"ZPFactor"]];
    [hopRatioCell setStringValue: [standardUserDefaults objectForKey: @"HopRatio"]];
    [spectrumMaxFreqCell setStringValue: [standardUserDefaults objectForKey: @"SpectrumMaxFreq"]];
    [wfMaxFreqCell setStringValue: [standardUserDefaults objectForKey: @"WFMaxFreq"]];
    [dBLimitCell setStringValue: [standardUserDefaults objectForKey: @"dBLimit"]];
    [wfPlotHeightCell setStringValue: [standardUserDefaults objectForKey: @"WFPlotHeight"]];
    if ([[standardUserDefaults objectForKey: @"DisplayType"] intValue])
	[displayMode selectCellWithTag: 1];
    else
	[displayMode selectCellWithTag: 0];

    type = [[standardUserDefaults objectForKey: @"WindowType"] cString];
    if (!strcmp(type, "Rectangular"))
	[windowTypeMatrix selectCellAtRow: 0 column: 0];	
    if (!strcmp(type, "Triangular"))
	[windowTypeMatrix selectCellAtRow: 1 column: 0];	
    if (!strcmp(type, "Hamming"))
	[windowTypeMatrix selectCellAtRow: 2 column: 0];	
    if (!strcmp(type, "Hanning"))
	[windowTypeMatrix selectCellAtRow: 3 column: 0];	
    if (!strcmp(type, "Blackman3"))
	[windowTypeMatrix selectCellAtRow: 0 column: 1];	
    if (!strcmp(type, "Blackman4"))
	[windowTypeMatrix selectCellAtRow: 1 column: 1];	
    if (!strcmp(type, "Kaiser"))
	[windowTypeMatrix selectCellAtRow: 2 column: 1];
    
    [self setPrefToView: [colorView contentView]];
}

- okay: sender
{
    int selectedRow, selectedCol, temp;
    NSUserDefaults *ourDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *newDefaults = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
	@"", @"WindowSize",
	@"", @"ZPFactor",
	@"", @"HopRatio",
	@"", @"WindowType",
	@"", @"SpectrumMaxFreq",
	@"", @"dBLimit",
	@"", @"WFMaxFreq",
	@"", @"WFPlotHeight",
	@"", @"DisplayType",
	@"", @"SpectrumColor",
	@"", @"WaterfallColor",
	@"", @"CursorColor",
	@"", @"GridColor",
	@"", @"AmplitudeColor",
	NULL, NULL] retain];

    if ([windowSizeCell intValue] > 0)
	[newDefaults setObject: [windowSizeCell stringValue] forKey: @"WindowSize"];
    else {
	[windowSizeCell setIntValue: 1024];
	[newDefaults setObject: @"1024" forKey: @"WindowSize"];
    }
    
    if ([zpFactorCell floatValue] >= 1.0)
	[newDefaults setObject: [zpFactorCell stringValue] forKey: @"ZPFactor"];
    else {
	[zpFactorCell setFloatValue: 1.0];
	[newDefaults setObject: @"1.0" forKey: @"ZPFactor"];
    }
    if ([hopRatioCell floatValue] > 0)
	[newDefaults setObject: [hopRatioCell stringValue] forKey: @"HopRatio"];
    else {
	[hopRatioCell setFloatValue: 0.5];
	[newDefaults setObject: @"0.5" forKey: @"HopRatio"];
    }
    if ([spectrumMaxFreqCell intValue] > 0)
	[newDefaults setObject: [spectrumMaxFreqCell stringValue] forKey: @"SpectrumMaxFreq"];
    else {
	[spectrumMaxFreqCell setIntValue: 10000];
	[newDefaults setObject: @"10000" forKey: @"SpectrumMaxFreq"];
    }
    if ((temp = [dBLimitCell intValue]) < 0)
	[newDefaults setObject: [dBLimitCell stringValue] forKey: @"dBLimit"];
    else {
	[dBLimitCell setIntValue: -temp];
	[newDefaults setObject: [dBLimitCell stringValue] forKey: @"dBLimit"];
    }
    if ([wfMaxFreqCell intValue] > 0)
	[newDefaults setObject: [wfMaxFreqCell stringValue] forKey: @"WFMaxFreq"];
    else {
	[wfMaxFreqCell setIntValue: 5000];
	[newDefaults setObject: @"5000" forKey: @"WFMaxFreq"];
    }
    if ([wfPlotHeightCell floatValue] >= 1)
	[newDefaults setObject: [wfPlotHeightCell stringValue] forKey: @"WFPlotHeight"];
    else {
	[wfPlotHeightCell setFloatValue: 3.0];
	[newDefaults setObject: @"3.0" forKey: @"WFPlotHeight"];
    }
    if ([displayMode selectedRow] > 0)
	[newDefaults setObject: @"1" forKey: @"DisplayType"]; /* Outline Mode */
    else {
	[newDefaults setObject: @"0" forKey: @"DisplayType"]; /* Wave Mode */
    }
    selectedRow = [windowTypeMatrix selectedRow];
    selectedCol = [windowTypeMatrix selectedColumn];
    if (!selectedCol) 
	switch (selectedRow) {
	case 0:
	    [newDefaults setObject: @"Rectangular" forKey: @"WindowType"];
	    break;
	case 1:
	    [newDefaults setObject: @"Triangular" forKey: @"WindowType"];
	    break;
	case 2:
	    [newDefaults setObject: @"Hamming" forKey: @"WindowType"];
	    break;
	case 3:
	    [newDefaults setObject: @"Hanning" forKey: @"WindowType"];
	    break;
	}
    else
	switch (selectedRow) {
	case 0:
	    [newDefaults setObject: @"Blackman3" forKey: @"WindowType"];
	    break;
	case 1:
	    [newDefaults setObject: @"Blackman4" forKey: @"WindowType"];
	    break;
	case 2:
	    [newDefaults setObject: @"Kaiser" forKey: @"WindowType"];
	    break;
	}
    [newDefaults setObject: colorToString([spectrumColorWell color]) forKey: @"SpectrumColor"];
    [newDefaults setObject: colorToString([waterfallColorWell color]) forKey: @"WaterfallColor"];
    [newDefaults setObject: colorToString([cursorColorWell color]) forKey: @"CursorColor"];
    [newDefaults setObject: colorToString([gridColorWell color]) forKey: @"GridColor"];
    [newDefaults setObject: colorToString([amplitudeColorWell color]) forKey: @"AmplitudeColor"];

    [ourDefaults registerDefaults: newDefaults]; //stick these in the temporary area that is searched last.

    [window orderOut: self];
    [([NSColorPanel sharedColorPanelExists] ? [NSColorPanel sharedColorPanel] : nil) orderOut: self];
    [(SoundDocument *) [[NSApp delegate] document] setColors];
	
    return self;
}

- defaults: sender
{
    [windowSizeCell setStringValue: @"1024"];
    [zpFactorCell setStringValue: @"2.0"];
    [hopRatioCell setStringValue: @"0.5"];
    [spectrumMaxFreqCell setStringValue: @"10000"];
    [wfMaxFreqCell setStringValue: @"5000"];
    [dBLimitCell setStringValue: @"-100"];
    [wfPlotHeightCell setStringValue: @"3.0"];
    [windowTypeMatrix selectCellAtRow: 3 column: 0];	/* Hanning */
    [displayMode selectCellAtRow: 0 column: 0];		/* Wave Mode */
    [spectrumColorWell setColor: [NSColor blackColor]];
    [cursorColorWell setColor: [NSColor redColor]];
    [gridColorWell setColor: [NSColor lightGrayColor]];
    [amplitudeColorWell setColor: [NSColor blueColor]];

    return self;
}

- setPref: sender
{
    id newView = nil;
    
    switch ([sender tag]) {
    case 0: 
	newView = [colorView contentView];
	break;
    case 1:
	newView = [fftView contentView];
	break;
    case 2:
	newView = [spectrumDisplayView contentView];
	break;
    case 3:
	newView = [soundDisplayView contentView];
	break;
    }
    
    [self setPrefToView: newView];
    return self;
}

- setPrefToView:theView
{
    NSRect boxRect, viewRect;
    
    boxRect = [multiView frame];
    viewRect = [theView frame];
    
    [[(NSBox *)multiView contentView] retain];
    [(NSBox *)multiView setContentView: theView];
    
    (&viewRect)->origin.x = (NSWidth(boxRect) - NSWidth(viewRect)) / 2.0;
    (&viewRect)->origin.y = (NSHeight(boxRect) - NSHeight(viewRect)) / 2.0;
    
    [theView setFrame:viewRect];	/* center the view */
    [multiView setNeedsDisplay:YES];
    return self;
}

@end
