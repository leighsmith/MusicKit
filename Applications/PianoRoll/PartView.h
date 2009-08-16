/* $Id$ */

#import <AppKit/NSView.h>
#import <MusicKit/MusicKit.h>
#import <Foundation/Foundation.h>
#define MAXFREQ 7040

@interface PartView: NSView
{
    double beatScale, freqScale;
    NSMutableArray *selectedList;
}

- setScore: (MKScore *) aScore;
- (void)gotClicked:sender with:(NSEvent *)theEvent;
- (void)setBeatScale:(double)bscale;
- (void)setFreqScale:(double)fscale;
- (double)beatScale;
- (double)freqScale;

@end
