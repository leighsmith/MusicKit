#import <musickit/musickit.h>
#import "SimplePerformer.h"


@implementation SimplePerformer

-init
{
    [super init];
    [self addNoteSender:[[NoteSender alloc] init]];
    aNote = [[Note alloc] init];          /* A note we'll use over and over */
    [aNote setNoteType:MK_noteOn];
    [aNote setNoteTag:MKNoteTag()];
    return self;
}

-activateSelf {         /* Invoked when performer is activated */
    nextPerform = 0;    /* No delay before first note. */
    return self;
}

-perform
{
    [[self noteSender] sendNote:aNote];
    nextPerform = 1.0;
    return self;
}

@end
