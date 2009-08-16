/* $Id$ */
#import <MusicKit/MusicKit.h>
#import <math.h>
#import "TadPole.h"
#import "PartView.h"

@implementation TadPole

- (void)setTadNote:aNote
{
    id oldNote;
    
    oldNote = tadNote;
    tadNote = aNote;
}

- whatisTadNote
{
    return tadNote;
}

- initNote:aNote second:bNote partNum:(int)partNumber beatscale:(double) bscale freqscale:(double) fscale
{
    NSRect aRect;
    
    [super init];
    if (!bNote)
        aRect = NSMakeRect([aNote timeTag]*bscale, log([aNote freq])*fscale, 
            [aNote dur]*bscale, 6.0);
    else
        aRect = NSMakeRect([aNote timeTag]*bscale, log([aNote freq])*fscale, 
            ([bNote timeTag] - [aNote timeTag])*bscale, 6.0);
    [self setFrame:aRect];
    tadNote = aNote;
    tadNoteb = bNote;
    partNum = partNumber;
    return self;
}

- (void)drawRect:(NSRect)rects
{
    double color;
    NSPoint minPoint, maxPoint;
    NSBezierPath *tadPolePath;

    if (rects.size.width > [self bounds].size.width)
        maxPoint.x = rects.size.width;
    else
        maxPoint.x = [self bounds].size.width;
    maxPoint.y = [self bounds].size.height / 2;
    if (rects.origin.x > 2)
        minPoint.x = rects.origin.x;
    else
        minPoint.x = 2.0;
    minPoint.y = [self bounds].size.height / 2;
    color = (partNum % 5)/10.0 + .5;
    tadPolePath = [NSBezierPath bezierPath];
    [tadPolePath setLineWidth: 1.0];
    if(selected)
        [[NSColor selectedControlColor] set];
    else
        [[NSColor purpleColor] set];
    [tadPolePath moveToPoint: minPoint];
    [tadPolePath lineToPoint: maxPoint];
    if (minPoint.x == 2) {
        [tadPolePath setLineWidth: 3.0];
        [[NSColor purpleColor] set];  // TODO needs to be some color based on partNum
        minPoint.y = 0.0;
        [tadPolePath moveToPoint: minPoint];
        maxPoint.x = 2.0;
        maxPoint.y = [self bounds].size.height;
        [tadPolePath lineToPoint: maxPoint];
    }
    [tadPolePath stroke];
}

- (BOOL)isSelected
{
    return selected;
}

- (void)unHighlight
{
    selected = NO;
    [self display]; 
}

- (void)doHighlight
{
    selected = YES;
    [self erase];
    [self display]; 
}

- (void)erase
{
    [self lockFocus];
    NSLog(@"erasing \n");
    [[NSColor controlBackgroundColor] set];
    [NSBezierPath fillRect: [self bounds]];
    [self unlockFocus]; 
}

- (void)setMoving:(BOOL)ismoving
{
    moving = ismoving; 
}

- (void)setFromPosWith:(double)bscale :(double)fscale
{
    [tadNote setTimeTag:[self frame].origin.x/bscale];
    [tadNote setPar:MK_freq toDouble:exp([self frame].origin.y/fscale)]; 
}

- (void)mouseDown:(NSEvent *)theEvent 
{
//	[[self superview] gotClicked:self with:theEvent];
}

@end
