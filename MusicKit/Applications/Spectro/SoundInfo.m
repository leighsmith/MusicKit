/* SoundInfo.m
 * Originally from SoundEditor2.1
 * Modified by Gary Scavone for Spectro3.0
 * Last modified: 2/94
 */


#import <AppKit/AppKit.h>
#import "SoundInfo.h"

@implementation SoundInfo

- init
{
	[super init];
	[NSBundle loadNibNamed:@"soundInfo.nib" owner:self];
	ssize = 0;
	return self;
}

- displaySound:sound title:(NSString *)title
{
	sndhdr = [sound soundStruct];
	[self display:title];
	return self;
}

- setSoundHeader:sound
{
	sndhdr = [sound soundStruct];
	return self;
}

- (int)getSrate
{
	return sndhdr->samplingRate;
}

- (int)getChannelCount
{
	return sndhdr->channelCount;
}

- (NSString *)getSoundFormat
{
	NSString *format;
	
	switch (sndhdr->dataFormat) {
		case SND_FORMAT_MULAW_8:
		case SND_FORMAT_MULAW_SQUELCH:
			format = @"8-bit muLaw";
			ssize = 1;
			break;
		case SND_FORMAT_LINEAR_8:
			format = @"8-bit Linear";
			ssize = 1;
			break;
		case SND_FORMAT_LINEAR_16:
			format = @"16-bit Linear";
			ssize = 2;
			break;
		case SND_FORMAT_LINEAR_24:
			format = @"24-bit Linear";
			ssize = 3;
			break;
		case SND_FORMAT_LINEAR_32:
			format = @"32-bit Linear";
			ssize = 4;
			break;
		case SND_FORMAT_FLOAT:
			format = @"32-bit Floating Point";
			ssize = 4;
			break;
		case SND_FORMAT_DOUBLE:
			format = @"64-bit Floating Point";
			ssize = 8;
			break;
		case SND_FORMAT_INDIRECT:
			format = @"Fragmented";
			ssize = 8;
			break;
		default:
			format = @"DSP?";
			ssize = 8;
			break;
	}
	return format;
}

- (void)display:(NSString *)title
{
	int channels, frames, hours, minutes;
	float seconds;
//	char time[32];
	
        [siPanel setTitle:title];
	[siSize setIntValue:sndhdr->dataSize];
	[siRate setIntValue:[self getSrate]];
	channels = [self getChannelCount];
	[siChannels setIntValue:channels];
	if (channels < 1) channels = 1;
        [siFormat setStringValue:[self getSoundFormat]];
	frames = sndhdr->dataSize / ssize / channels;
	[siFrames setIntValue:frames];
	seconds = (float) frames / (float) sndhdr->samplingRate;
	hours = (int) (seconds / 3600);
	minutes = (int) ((seconds - hours * 3600) / 60);
	seconds = seconds - hours * 3600 - minutes * 60;
//	sprintf (time, "%02d:%02d:%05.2f", hours, minutes, seconds);
        [siTime setStringValue:[NSString stringWithFormat:@"%02d:%02d:%05.2f", hours, minutes, seconds]];
	[siPanel makeKeyAndOrderFront:self];
	[NSApp runModalForWindow:siPanel];
}

- setSiPanel:anObject
{
    siPanel = anObject;
    [siPanel setDelegate:self];
    return self;
}
- setSiSize:anObject
{
    siSize = anObject;
    [siSize setSelectable:NO];
    [siSize setEditable:NO];
    return self;
}

- setSiFrames:anObject
{
    siFrames = anObject;
    [siFrames setSelectable:NO];
    [siFrames setEditable:NO];
    return self;
}

- setSiFormat:anObject
{
    siFormat = anObject;
    [siFormat setSelectable:NO];
    [siFormat setEditable:NO];
    return self;
}

- setSiTime:anObject
{
    siTime = anObject;
    [siTime setSelectable:NO];
    [siTime setEditable:NO];
    return self;
}

- setSiRate:anObject
{
    siRate = anObject;
    [siRate setSelectable:NO];
    [siRate setEditable:NO];
    return self;
}

- setSiChannels:anObject
{
    siChannels = anObject;
    [siChannels setSelectable:NO];
    [siChannels setEditable:NO];
    return self;
}

- (BOOL)windowShouldClose:(id)sender
{
	[NSApp stopModal];
	return YES;
}

@end
