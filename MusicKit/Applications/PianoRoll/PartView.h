/* $Id$ */

#import <AppKit/NSView.h>
#import <MusicKit/MusicKit.h>
#import <Foundation/Foundation.h>

@interface PartView:NSView
{
    double beatScale, freqScale;
    NSMutableArray *selectedList;
}

- initWithScore: (MKScore *) aScore;
- (void)gotClicked:sender with:(NSEvent *)theEvent;
- (void)setBeatScale:(double)bscale;
- (void)setFreqScale:(double)fscale;
- (double)beatScale;
- (double)freqScale;

@end
