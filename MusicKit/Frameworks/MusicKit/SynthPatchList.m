/* SynthPatchList.m created by leigh on Tue 23-May-2000 */

#import "SynthPatchList.h"

@implementation SynthPatchList

- init
{
    [super init];
    idleNewest = idleOldest = activeNewest = activeOldest = nil;
    idleCount = totalCount = manualCount = 0;
    template = nil;
    return self;
}

- (void) setTemplate: (id) newTemplate
{
    template = [newTemplate retain];
}

- (void) setActiveNewest: (id) newActiveNewest
{
    activeNewest = [newActiveNewest retain];
}

- (void) setActiveOldest: (id) newActiveOldest
{
    activeOldest = [newActiveOldest retain];
}

@end
