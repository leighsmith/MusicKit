#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <MusicKit/MusicKit.h>

int main (int argc, const char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    MKNote *aNote, *partInfo;
    MKPart *aPart;
    MKScore *aScore;
    aScore = [[MKScore alloc] init];
    aPart = [[MKPart alloc] init];
    /* REPEAT FROM HERE TO XXX TO ADD MULTIPLE NOTES */
    aNote = [[MKNote alloc] init];
    [aNote setPar: MK_freq toDouble:440.0];
    [aNote setTimeTag: 1.0];
    [aNote setDur: 1.0];
    [aScore addPart: aPart];
    [aPart addNote: aNote];           /* Doesn't copy note */
    /* XXX */
    partInfo = [[MKNote alloc] init];	
    [partInfo setPar: MK_synthPatch toString: @"Pluck"];
    [aPart setInfoNote: partInfo];
    [aScore writeScorefile: @"test.score"];
    system("playscore test.score");  /* play the thing */
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}