
#import "PrefController.h"
#import "SoundController.h"
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

- (void)awakeFromNib
{
	char const *type;
	
	[[NSColorPanel sharedColorPanel] setContinuous:YES];
	[self setUpWell:cursorColorWell tag:0];
	[self setUpWell:spectrumColorWell tag:1];
	[self setUpWell:gridColorWell tag:2];

	[spectrumColorWell setColor:StringToColor(
		[[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumColor"])];
	[waterfallColorWell setColor:StringToColor(
		[[NSUserDefaults standardUserDefaults] objectForKey:@"WaterfallColor"])];
        [cursorColorWell setColor:StringToColor(
		[[NSUserDefaults standardUserDefaults] objectForKey:@"CursorColor"])];
        [gridColorWell setColor:StringToColor(
		[[NSUserDefaults standardUserDefaults] objectForKey:@"GridColor"])];
	
	[windowSizeCell setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"WindowSize"]];
	[zpFactorCell setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"ZPFactor"]];
	[hopRatioCell setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"HopRatio"]];
	[spectrumMaxFreqCell setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"SpectrumMaxFreq"]];
	[wfMaxFreqCell setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"WFMaxFreq"]];
	[dBLimitCell setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"dBLimit"]];
	[wfPlotHeightCell setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"WFPlotHeight"]];
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"DisplayType"] intValue])
		[displayMode selectCellWithTag:1];
	else
		[displayMode selectCellWithTag:0];

	type = [[[NSUserDefaults standardUserDefaults] objectForKey:@"WindowType"] cString];
	if (!strcmp(type, "Rectangular"))
		[windowTypeMatrix selectCellAtRow:0 column:0];	
	if (!strcmp(type, "Triangular"))
		[windowTypeMatrix selectCellAtRow:1 column:0];	
	if (!strcmp(type, "Hamming"))
		[windowTypeMatrix selectCellAtRow:2 column:0];	
	if (!strcmp(type, "Hanning"))
		[windowTypeMatrix selectCellAtRow:3 column:0];	
	if (!strcmp(type, "Blackman3"))
		[windowTypeMatrix selectCellAtRow:0 column:1];	
	if (!strcmp(type, "Blackman4"))
		[windowTypeMatrix selectCellAtRow:1 column:1];	
	if (!strcmp(type, "Kaiser"))
		[windowTypeMatrix selectCellAtRow:2 column:1];
	
	[self setPrefToView:[colorView contentView]];
}

- setUpWell:well tag:(int)aTag
{
	[well setTag:aTag];
	[well setContinuous:YES];
	return self;
}

- okay:sender
{
	int selectedRow, selectedCol, temp;
        NSUserDefaults *ourDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *newDefaults = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            @"",@"WindowSize",
            @"",@"ZPFactor",
            @"",@"HopRatio",
            @"",@"WindowType",
            @"",@"SpectrumMaxFreq",
            @"",@"dBLimit",
            @"",@"WFMaxFreq",
            @"",@"WFPlotHeight",
            @"",@"DisplayType",
            @"",@"SpectrumColor",
            @"",@"WaterfallColor",
            @"",@"CursorColor",
            @"",@"GridColor",
            NULL,NULL] retain];

            
	if ([windowSizeCell intValue] > 0)
            [newDefaults setObject:[windowSizeCell stringValue] forKey:@"WindowSize"];
	else {
            [windowSizeCell setIntValue:1024];
            [newDefaults setObject:@"1024" forKey:@"WindowSize"];

	}
	if ([zpFactorCell floatValue] >= 1.0)
            [newDefaults setObject:[zpFactorCell stringValue] forKey:@"ZPFactor"];
	else {
            [zpFactorCell setFloatValue:1.0];
            [newDefaults setObject:@"1.0" forKey:@"ZPFactor"];
	}
	if ([hopRatioCell floatValue] > 0)
            [newDefaults setObject:[hopRatioCell stringValue] forKey:@"HopRatio"];
	else {
            [hopRatioCell setFloatValue:0.5];
            [newDefaults setObject:@"0.5" forKey:@"HopRatio"];
	}
	if ([spectrumMaxFreqCell intValue] > 0)
            [newDefaults setObject:[spectrumMaxFreqCell stringValue] forKey:@"SpectrumMaxFreq"];
	else {
            [spectrumMaxFreqCell setIntValue:10000];
            [newDefaults setObject:@"10000" forKey:@"SpectrumMaxFreq"];
	}
	if ((temp = [dBLimitCell intValue]) < 0)
            [newDefaults setObject:[dBLimitCell stringValue] forKey:@"dBLimit"];
	else {
            [dBLimitCell setIntValue:-temp];
            [newDefaults setObject:[dBLimitCell stringValue] forKey:@"dBLimit"];
	}
	if ([wfMaxFreqCell intValue] > 0)
            [newDefaults setObject:[wfMaxFreqCell stringValue] forKey:@"WFMaxFreq"];
	else {
            [wfMaxFreqCell setIntValue:5000];
            [newDefaults setObject:@"5000" forKey:@"WFMaxFreq"];
	}
	if ([wfPlotHeightCell floatValue] >= 1)
            [newDefaults setObject:[wfPlotHeightCell stringValue] forKey:@"WFPlotHeight"];
	else {
            [wfPlotHeightCell setFloatValue:3.0];
            [newDefaults setObject:@"3.0" forKey:@"WFPlotHeight"];
	}
	if ([displayMode selectedRow] > 0)
            [newDefaults setObject:@"1" forKey:@"DisplayType"]; /* Outline Mode */
	else {
            [newDefaults setObject:@"0" forKey:@"DisplayType"]; /* Wave Mode */
	}
	selectedRow = [windowTypeMatrix selectedRow];
	selectedCol = [windowTypeMatrix selectedColumn];
	if (!selectedCol) switch (selectedRow) {
            case 0:
                [newDefaults setObject:@"Rectangular" forKey:@"WindowType"];
			break;
            case 1:
                [newDefaults setObject:@"Triangular" forKey:@"WindowType"];
                break;
            case 2:
                [newDefaults setObject:@"Hamming" forKey:@"WindowType"];
                break;
            case 3:
                [newDefaults setObject:@"Hanning" forKey:@"WindowType"];
                break;
                }
        else switch (selectedRow) {
            case 0:
                [newDefaults setObject:@"Blackman3" forKey:@"WindowType"];
                break;
            case 1:
                [newDefaults setObject:@"Blackman4" forKey:@"WindowType"];
                break;
            case 2:
                [newDefaults setObject:@"Kaiser" forKey:@"WindowType"];
                break;
                }
    [newDefaults setObject:colorToString([spectrumColorWell color]) forKey:@"SpectrumColor"];
    [newDefaults setObject:colorToString([waterfallColorWell color]) forKey:@"WaterfallColor"];
    [newDefaults setObject:colorToString([cursorColorWell color]) forKey:@"CursorColor"];
    [newDefaults setObject:colorToString([gridColorWell color]) forKey:@"GridColor"];

    [ourDefaults registerDefaults:newDefaults];//stick these in the temporary area that is searched last.

    [window orderOut:self];
    [([NSColorPanel sharedColorPanelExists] ? [NSColorPanel sharedColorPanel] : nil) orderOut:self];
    [[[NSApp delegate] document] setColors];
	
    return self;
}

- defaults:sender
{
	[windowSizeCell setStringValue:@"1024"];
	[zpFactorCell setStringValue:@"2.0"];
	[hopRatioCell setStringValue:@"0.5"];
	[spectrumMaxFreqCell setStringValue:@"10000"];
	[wfMaxFreqCell setStringValue:@"5000"];
	[dBLimitCell setStringValue:@"-100"];
	[wfPlotHeightCell setStringValue:@"3.0"];
	[windowTypeMatrix selectCellAtRow:3 column:0];	/* Hanning */
	[displayMode selectCellAtRow:0 column:0];		/* Wave Mode */
	[spectrumColorWell setColor:[NSColor blackColor]];
	[cursorColorWell setColor:[NSColor redColor]];
	[gridColorWell setColor:[NSColor lightGrayColor]];

	return self;
}

- setPref:sender
{
	id newView = nil;
	
#ifndef WIN32
        switch ([[sender selectedCell] tag]) {
#else
        switch ([sender tag]) {
#endif
		case 0: newView = [colorView contentView];
				break;
		case 1: newView = [fftView contentView];
				break;
		case 2: newView = [spectrumDisplayView contentView];
				break;
		case 3: newView = [soundDisplayView contentView];
				break;
	}
	
	[self setPrefToView:newView];
	return self;
}

- setPrefToView:theView
{
	NSRect boxRect, viewRect;
	
	boxRect = [multiView frame];
	viewRect = [theView frame];
	
        [[(NSBox *)multiView contentView] retain];
        [(NSBox *)multiView setContentView:theView];
	
	(&viewRect)->origin.x = (NSWidth(boxRect) - NSWidth(viewRect)) / 2.0;
	(&viewRect)->origin.y = (NSHeight(boxRect) - NSHeight(viewRect)) / 2.0;
	
	[theView setFrame:viewRect];	/* center the view */
        [multiView setNeedsDisplay:YES];
	return self;
}

@end
