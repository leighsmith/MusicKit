////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    sndinfo - a simple SndKit report generator of sound file parameters.
//    This command line tool attempts to recreate the utility supplied on NeXTStep
//    but updated to read all file formats supported. The output format doesn't
//    match the original, but it has broadly the same info.
//
//  Original Author: Leigh Smith <leigh@leighsmith.com>
//
//  Copyright (c) 2001-2002, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

void printSoundReport(NSString *filename, Snd *snd)
{
    NSString *formatName = SndFormatName([snd dataFormat], YES);
    
    printf("File: %s\n", [filename cString]);
    printf("Data Format: %s\n", [formatName cString]);
    printf("Sampling Rate: %.2lf Hz\n", [snd samplingRate]);
    printf("Channels: %d\n", [snd channelCount]);
    printf("Sample frames: %ld\n", [snd lengthInSampleFrames]);
    printf("Duration %.3lf seconds\n", [snd duration]);
    printf("Info: %s\n", [[snd info] cString]);
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *filename;
    Snd *snd;
    int argIndex;

    for(argIndex = 1; argIndex < argc; argIndex++) {
	filename = [NSString stringWithCString: argv[argIndex]];
	snd = [[Snd alloc] initFromSoundfile: filename];
	if(snd != nil) {
	    printSoundReport(filename, snd);
	}
    }
	    
    [pool release];
    return 0;
}
