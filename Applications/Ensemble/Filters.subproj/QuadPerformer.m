#import "Quad.h"
#import "QuadPerformer.h"
#import "WmFractal.h"
#import <appkit/Control.h>

@implementation QuadPerformer

+ initialize
{
	[QuadPerformer setVersion:2];
	return self;
}

-init
    /* Called automatically when an instance is created. */
{     
    [super init]; 
    interval = 0.2;
    conductor = [Conductor clockConductor];
    return self;
}

-free
{
    [self deactivate];
    xFractal = [xFractal free];
    xFractal = [yFractal free];
    return [super free];
}

- setNoteFilter:anObject
{
	noteFilter = anObject;
	return self;
}

- setFractalX:xObject y:yObject
{
    xFractal = xObject;
    yFractal = yObject;
    return self;
}

- setInterval:(double)anInterval
{
    interval = anInterval;
    return self;
}

- inspectFractal:sender
{
	if ([[sender selectedCell] tag]==0)
		[xFractal show:sender];
	else [yFractal show:sender];
	return self;
}

-activateSelf
{
    startTime = (float)[conductor time];
    return self;
}

- perform
{
    float now = (float)[conductor time]-startTime;

    [noteFilter moveTo:2.0*[xFractal generate:now]-1.0
        :2.0*[yFractal generate:now]-1.0];
    
    nextPerform = interval;
    return self;
}

- write:(NXTypedStream *) stream
    /* Archive the performer to a typed stream. */
{
    [super write:stream];
    NXWriteTypes(stream, "@@d@",
		 &xFractal, &yFractal, &interval, &noteFilter);
    return self;
}

- read:(NXTypedStream *) stream
    /* Unarchive the performer from a typed stream. */
{
	int version;
	
    [super read:stream];
	version = NXTypedStreamClassVersion(stream, "QuadPerformer");

	if (version <= 1) {
		id doc;
    	NXReadTypes(stream, "@@d@@",
			&xFractal, &yFractal, &interval, &noteFilter, &doc);
	}
	else
    	NXReadTypes(stream, "@@d@",
			&xFractal, &yFractal, &interval, &noteFilter);
    return self;
}

- awake
    /* Initialize certain non-archived data */
{
    [super awake];
    conductor = [Conductor clockConductor];
    return self;
}
@end
