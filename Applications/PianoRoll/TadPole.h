/* $Id$ */

#import <AppKit/AppKit.h>

@interface TadPole:NSView
{
	BOOL selected;
	BOOL moving;
	int partNum;
	id tadNote;
	id tadNoteb;
	id offNote;
}

- initNote:aNote second:bNote partNum:(int)partNumber beatscale:(double) bscale freqscale:(double) fscale;
- (void)drawRect:(NSRect)rect;
- (void)setTadNote:aNote;
- whatisTadNote;
- (BOOL)isSelected;
- (void)unHighlight;
- (void)doHighlight;
- (void)erase;
- (void)setMoving:(BOOL)ismoving;
- (void)setFromPosWith:(double)bscale :(double)fscale;
- (void)mouseDown:(NSEvent *)theEvent;

@end
