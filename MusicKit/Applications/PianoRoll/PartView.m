/* $Id$ */

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <MusicKit/MusicKit.h>
#import <math.h>
#import "PartView.h"
#import "TadPole.h"

#define DEFAULT_BEATSCALE 32
#define DEFAULT_FREQSCALE 16

@implementation PartView

/* used to quickly identify PartView in a NSWindow */
- (int) tag
{
    return 1;
}

- setScore: (MKScore *) aScore
{
    NSArray *theParts;
    MKPart *thePart;
    MKNote *theNote;
    TadPole *newTad;
    int i, j, k, scoreDuration, partCount;
    NSRect aRect;
    
    beatScale = DEFAULT_BEATSCALE;
    freqScale = DEFAULT_FREQSCALE;
    selectedList = [[NSMutableArray alloc] init];
    
    theParts = [aScore parts];
    partCount = [theParts count];
    
    scoreDuration = 0;			/* find the length of the score */
    for (i = 0; i < [theParts count]; i++) {
        thePart = [theParts objectAtIndex:i];
        for (j = 0; j < [thePart noteCount]; j++) {
            theNote = [thePart nth:j];
            if ([theNote noteType] == MK_noteDur) {
                if ([theNote timeTag] + [theNote dur] > scoreDuration)
                    scoreDuration = [theNote timeTag] + [theNote dur];
            }
            else if ([theNote timeTag] > scoreDuration)
                scoreDuration = [theNote timeTag];
        }
    }
    if(scoreDuration * beatScale > [self bounds].size.width) {  
        beatScale = [self bounds].size.width / scoreDuration;
    }
    aRect = NSMakeRect(0.0, 0.0, scoreDuration*beatScale, log(MAXFREQ)*freqScale);
//    [self initWithFrame:aRect];

    for (i = 0; i < partCount; i++) {
        thePart = [theParts objectAtIndex:i];
        for (j = 0; j < [thePart noteCount]; j++) {
            theNote = [thePart nth: j];
            switch ([theNote noteType]) {
            case MK_mute:
            case MK_noteOff:
                break;
            case MK_noteDur:
                newTad = [[TadPole alloc] initNote: theNote
                                            second: nil
                                           partNum: i
                                         beatscale: beatScale
                                         freqscale: freqScale];
                [self addSubview:newTad];
                break;
            case MK_noteUpdate:
                if ([theNote noteTag] == MAXINT)  /* no note tag! */
                    break;
            case MK_noteOn:
                if (MKIsNoDVal([theNote freq])) /* no frequency - not quite kosher */
                    break;
                for (k = j+1; k < [thePart noteCount]; k++)
                    if ([[thePart nth:k] noteTag] == [theNote noteTag])
                        break;
                if (k < [thePart noteCount]) {
                    newTad = [[TadPole alloc] initNote:theNote
                                                second:[thePart nth:k]
                                                partNum:i
                                                beatscale:beatScale
                                                freqscale:freqScale];
                    [self addSubview:newTad];
                    break;
                }
            }
        }
    }
    return self;
}

- (void)gotClicked:sender with:(NSEvent *)theEvent
{
	BOOL loop = YES, inside, wasdragged = NO, wasSelected = YES;
	NSPoint ePoint, thePoint;
	NSEvent *nEvent;
        int i;
	id theTad;
		
	if (![sender isSelected]) {
		wasSelected = NO;
		[sender setMoving:YES];
		[sender doHighlight];
		for (i = 0; i < [selectedList count]; i++)
                [[selectedList objectAtIndex:i] unHighlight];
                [selectedList removeAllObjects];
		[selectedList addObject:sender];
	}
		else [sender erase];
//	ePoint.x = theEvent->location.x;
//	ePoint.y = theEvent->location.y;
//	ePoint = [self convertPoint:ePoint fromView:nil];
        ePoint = [theEvent locationInWindow];
	while (loop) {
		nEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask |			NSLeftMouseDraggedMask)];
		thePoint.x = [nEvent locationInWindow].x;
		thePoint.y = [nEvent locationInWindow].y;
		thePoint = [self convertPoint:thePoint fromView:nil];
		inside = NSMouseInRect(thePoint , [self bounds] , [self isFlipped]);
		switch ([nEvent type]) {
		case NSLeftMouseUp:
			loop = NO;
			if (!wasdragged && wasSelected) {
				[sender unHighlight];
				[selectedList removeObject:sender];
			}
			else {
				for (i = 0; i < [selectedList count]; i++) {
                                theTad = [selectedList objectAtIndex:i];
					[theTad setFromPosWith:beatScale :freqScale];
					[theTad setMoving:NO];
					[theTad display];
				}
			}
			break;
		case NSLeftMouseDragged:
			wasdragged = YES;
			for (i = 0; i < [selectedList count]; i++) {
                        theTad = [selectedList objectAtIndex:i];
				[theTad setMoving:YES];
			//	[theTad moveBy:thePoint.x - ePoint.x :thePoint.y - ePoint.y];
                                [theTad setFrameOrigin:NSMakePoint(([theTad frame].origin.x + thePoint.x - ePoint.x), ([theTad frame].origin.y + thePoint.y - ePoint.y))];
				[theTad display];
			}
			ePoint.x = thePoint.x;
			ePoint.y = thePoint.y;
			break;
                default:        // Makes explicit to the compiler we do nothing with other events.
                        break;
		}
	}
}

- (double) beatScale
{
	return beatScale;
}

- (double)freqScale
{
	return freqScale;
}

- (void)setBeatScale:(double)bscale
{
	beatScale = bscale; 
}

- (void)setFreqScale:(double)fscale
{
	freqScale = fscale; 
}

- (void) documentView
{
}

@end
