/* Settings is a modal panel for setting document-specific preferences */

#import "Settings.h"
#import "EnsembleApp.h"
#import "EnsembleDoc.h"
#import <appkit/appkit.h>

extern EnsembleDoc *keyDocument;

@implementation Settings
{
}

- setSamplingRate:(double)srate
{
	return[srateDisplayer selectCellWithTag:samplingRate = srate];
}

- setHeadroom:(double)value
{
	headroom = (fabs(value) >.001) ? value : 0.0;
	return[headroomDisplayer setDoubleValue:headroom];
}

- setLoadScore:(BOOL)load
{
	return[loadScoreDisplayer setState:loadScore = load];
}

- setProgram:(int)number
{
	program = number;
	if (number > 127)
		return [programDisplayer setStringValue:"Any"];
	else if (number >= 0)
		return [programDisplayer setIntValue:program + 1];
	else
		return [programDisplayer setStringValue:"---"];
}

- setDspNum:(int)num
 /* For supporting multiple DSPs in the future */
{
	if ([[Orchestra newOnDSP:num] init])
		return[dspNumDisplayer setIntValue:dspNum = num];
	else
		return nil;
}

- setHeadphoneLevel:(int)level
	/* Display level as a +6 to -78 dB scale */
{
	int displayLevel = level+6;
	char str[8] = "---";

	headphoneLevel = level;

	if ((displayLevel > 0) && (displayLevel <= 6))
		sprintf(str, "+%ddB", displayLevel);
	else if ((displayLevel <= 0) && (displayLevel >= -78))
		sprintf(str, "%ddB", displayLevel);
	[levelDisplayer setStringValue:str];
	return self;
}

- setSoundDeemphasis:(BOOL)state
{
	[deemphasisDisplayer setState:deemphasis = state];
	return self;
}

- takeSrateFrom:sender
{
	return[self setSamplingRate:(double)[[sender selectedCell] tag]];
}

- takeHeadroomFrom:sender
{
	return[self setHeadroom:headroom +
		   (double)[[sender selectedCell] tag] * 0.01];
}

- takeLoadScoreFrom:sender
{
	return[self setLoadScore:[sender state]];
}

- takeDspNumFrom:sender
{
	return[self setDspNum:dspNum + [[sender selectedCell] tag]];
}

- takeProgramFrom:sender
{
	return[self setProgram:MAX(MIN(program +
								   [[sender selectedCell] tag], 128), -1)];
}

- takeHeadphoneLevelFrom:sender
{
	return[self setHeadphoneLevel:MAX(MIN(headphoneLevel +
										[[sender selectedCell] tag], 0), -86)];
}

- takeDeemphasisFrom:sender
{
	return[self setSoundDeemphasis:[sender state]];
}

- runModal:sender
{
	if (keyDocument) {
		[documentDisplayer setStringValue:[keyDocument fileName]];
		[self setSamplingRate:[keyDocument samplingRate]];
		[self setHeadroom:[keyDocument headroom]];
		[self setLoadScore:[keyDocument loadScore]];
		[self setDspNum:[keyDocument dspNum]];
		[self setProgram:[keyDocument program]];
		[self setHeadphoneLevel:[keyDocument headphoneLevel]];
		[self setSoundDeemphasis:[keyDocument deemphasis]];
		[self center];
		[self makeKeyAndOrderFront:self];
		if ([NXApp runModalFor:self] == NX_RUNSTOPPED) {
			[keyDocument setSamplingRate:samplingRate];
			[keyDocument setHeadroom:headroom];
			[keyDocument setLoadScore:loadScore];
			[keyDocument setDspNum:dspNum];
			[keyDocument setProgram:program];
			[keyDocument setHeadphoneLevel:headphoneLevel];
			[keyDocument setSoundDeemphasis:deemphasis];
		}
		[self close];
	}
	return self;
}

- ok:sender
{
	return[NXApp stopModal];
}

- cancel:sender
{
	[NXApp abortModal];
	return nil;
}

@end
