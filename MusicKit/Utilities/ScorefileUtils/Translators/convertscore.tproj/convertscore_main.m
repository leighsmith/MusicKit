/*
  $Id$
  Defined In: The MusicKit

  Description:
    This is a command line scorefile conversion utility, converting to and from
    standard MIDI files (SMF), text scorefiles and binary playscorefiles.
    See help string below for details.

  Original Author: David A. Jaffe.
  Converted to OpenStep: Leigh M. Smith <leigh@tomandandy.com>

  Copyright 1988-1992, NeXT Inc.  All rights reserved.
  Portions Copyright (c) 1999-2000 The MusicKit Project.
*/
/*
 Modification history:
   $Log$
   Revision 1.5  2000/11/29 03:47:45  leigh
   Added copyright statement

   Revision 1.4  2000/06/13 17:50:28  leigh
   Made file searches use platform independent approach, add note combining

*/
#import <Foundation/Foundation.h>
#import <MusicKit/MusicKit.h>

#define SCORE_DIR @"Music/Scores/"

// Make sure these two match array indexes and order and then everything's sweet.
enum fileFormat {none=-1,midi=0,score=1,playscore=2};
static NSArray *scorefileExtensions;

static NSString *findFile(NSString *name)
{
    NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    unsigned i, j;

    if (!name) {
        fprintf(stderr,"No file name specified.\n");
        exit(1);
    }
    if([[NSFileManager defaultManager] isReadableFileAtPath: name])
        return name;
    for(i = 0; i < [libraryDirs count]; i++) {
        NSString *directoryQualifiedName;
        directoryQualifiedName = [[[libraryDirs objectAtIndex: i] stringByAppendingPathComponent: SCORE_DIR]
                                        stringByAppendingPathComponent: name];
        for(j = 0; j < [scorefileExtensions count]; j++) {
            NSString *fullyQualifiedName = [directoryQualifiedName
                                            stringByAppendingPathExtension: [scorefileExtensions objectAtIndex: j]];
            if([[NSFileManager defaultManager] isReadableFileAtPath: fullyQualifiedName])
                return fullyQualifiedName;
        }
    }
    return nil;
}

static char *formatStr(int aFormat)
{
    return (aFormat == score) ? ".score" : (aFormat == playscore) ? ".playscore" : ".midi";
}

enum fileFormat determineInputFormat(NSString *inputFile)
{
    NSFileHandle *fh;
    int firstWord;
    NSData *firstWordData;
    NSString *foundFile;

    foundFile = findFile(inputFile);
    if (foundFile == nil) {
        fprintf(stderr,"Can't find %s.\n", [foundFile cString]);
        exit(1);
    }
    fh = [NSFileHandle fileHandleForReadingAtPath: foundFile];
    firstWordData = [fh readDataOfLength: 4];
    firstWord = NSSwapBigIntToHost(*((int *)[firstWordData bytes]));
    if (firstWord == MK_SCOREMAGIC)
        return playscore;
    else if (firstWord == MK_MIDIMAGIC)
        return midi;
    else
        return score;
}

const char * const help = "\n"
"usage : convertscore [-m]|[-p]|[-s] [-tnc] [-o file] file\n"
"        [-m] write midifile (.midi) format \n"
"        [-p] write optimized scorefile (.playscore) format \n"
"        [-s] write scorefile (.score) format \n"
"        [-t] convert tempo changes to time tags, defaulting tempo to 60 BPM\n"
"        [-n] write key number names in symbolic format, defaulting to numeric\n"
"        [-c] combine note-on/off pairs to noteDur\'s when writing scorefiles\n"
"        [-o <output file>] \n"
"\n";

int main (int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *inputFile;
    NSString *outputFile = nil;
    int errorFlag = 0;
    enum fileFormat outFormat = none,inFormat = none;
    int i;
    MKScore *aScore;
    BOOL combineNotes = NO;
    BOOL writeKeyNames = NO;
    BOOL absoluteTempo = NO;	/* by default, we use the tempo from the */
    				/* midifile & convert the time-tags without */
				/* considering the tempo. */
    scorefileExtensions = [NSArray arrayWithObjects:  @"midi", @"score", @"playscore", nil];
    if (argc == 1) {
	fprintf(stderr,help);
	exit(1);
    }
    for (i=1; i<(argc-1); i++) {
	if ((strcmp(argv[i],"-m") == 0))  /* midi */
            outFormat = midi;
	else if ((strcmp(argv[i],"-p") == 0)) /* optimized scorefile */
            outFormat = playscore;
	else if (strcmp(argv[i],"-s") == 0)
            outFormat = score;
	else if (strcmp(argv[i],"-t") == 0)
            absoluteTempo = YES;
        else if (strcmp(argv[i],"-n") == 0)
            writeKeyNames = YES;
        else if (strcmp(argv[i],"-c") == 0)
            combineNotes = YES;
	else if (strcmp(argv[i],"-o") == 0)  {
	    i++;
	    if (i < argc)
                outputFile = [NSString stringWithCString: argv[i]];
	}
    }
    inputFile = [NSString stringWithCString: argv[argc-1]];
    if (!outputFile)
        outputFile = [inputFile stringByDeletingPathExtension]; /* Extension added by write routine */

    inFormat = determineInputFormat(inputFile);
    [MKScore setMidifilesEvaluateTempo: absoluteTempo];
    MKWriteKeyNumNames(writeKeyNames);
    aScore = [MKScore score];

    if (outFormat == none)
        outFormat = (inFormat == playscore) ? score : playscore;
    fprintf(stderr,"Converting from %s to %s format.\n", formatStr(inFormat), formatStr(outFormat));
    switch (inFormat) {
    case score:
    case playscore:
        if (![aScore readScorefile: inputFile])  {
            fprintf(stderr,"Fix scorefile errors and try again.\n");
            exit(1);
        }
        break;
    case midi: {
        MKNote *aNoteInfo = [[MKNote alloc] init];
        NSArray *parts;
        if (![aScore readMidifile: inputFile])  {
            fprintf(stderr,"This doesn't look like a midi file.\n");
            exit(1);
        }
        [aNoteInfo setPar: MK_synthPatch toString: @"midi0"];
        printf("%d parts\n", [aScore partCount]);
        parts = [aScore parts];
        [parts makeObjectsPerformSelector: @selector(setInfoNote:) withObject: aNoteInfo];
        if(combineNotes) {
            [aScore combineNotes];
        }
        break;
    }
    case none:
        fprintf(stderr, "Internal error, no inputFormat\n");
        exit(1);
    }
    switch (outFormat) {
    case score:
        if (![aScore writeScorefile: outputFile])
            errorFlag = 1;
        break;
    case playscore:
        if (![aScore writeOptimizedScorefile: outputFile])
            errorFlag = 1;
        break;
    case midi:
        if (![aScore writeMidifile: outputFile])
            errorFlag = 1;
        break;
    case none:
        fprintf(stderr, "Internal error, no inputFormat\n");
        exit(1);
    }
    if (errorFlag) {
	fprintf(stderr,"Can't write %s.\n", [outputFile cString]);
	exit(1);
    }
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
