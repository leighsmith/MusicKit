#import <dpsclient/wraps.h>
#import <dpsclient/dpsNeXT.h>
#import <appkit/nextstd.h>
#import <appkit/Control.h>
#import "MeterView.h"

@implementation MeterView

{
}

- initFrame:(const NXRect *)frameRect
{
	[super initFrame:frameRect];
	backgroundGray = NX_DKGRAY;
	meterGray = 0.83334;
	lastValue = bounds.size.height;	/* to insure initial background drawing */
	[self setClipping:NO];
	return self;
}

- setBackgroundGray:(float)aValue
{
	backgroundGray = aValue;
	return [self display];
}

- setMeterGray:(float)aValue
{
	meterGray = aValue;
	return [self display];
}

- setFloatValue:(float)aValue
{
	lastValue = currentValue;

	if (aValue < 0.0)
		aValue = 0.0;
	else if (aValue > 1.0)
		aValue = 1.0;

	currentValue = aValue * bounds.size.height;

	if (lastValue != currentValue) [self display];
	return self;
}

struct TEData {
	MeterView *self;
	float delayedValue;
};

static void setValueDelayed(DPSTimedEntry timedEntry, double now,
				struct TEData * data)
{
	[data->self setFloatValue:data->delayedValue];
	DPSRemoveTimedEntry(timedEntry);
	NX_FREE(data);
}

- setFloatValue:(float)aValue withDelay:(double)aDelay
{
	struct TEData *data;

	if (aDelay > 0) {
		NX_MALLOC(data, struct TEData, 1);
		data->self = self;
		data->delayedValue = aValue;
		DPSAddTimedEntry(aDelay, (DPSTimedEntryProc) setValueDelayed,
						(void *)data, 1);
	} else
		[self setFloatValue:aValue];
	return self;
}

- takeFloatValueFrom:sender
{
	return [self setFloatValue:[sender floatValue]];
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
	/* Just paint the changed rectangle */
	PSsetgray((currentValue>lastValue)?meterGray:backgroundGray);
	PSrectfill(0, lastValue, bounds.size.width,(currentValue-lastValue));
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive this filter to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "ff", &backgroundGray, &meterGray);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive a filter from a typed stream. */
{
	[super read:stream];
	NXReadTypes(stream, "ff", &backgroundGray, &meterGray);
	return self;
}

- awake
{
	[super awake];
	lastValue = bounds.size.height;	/* to insure initial background drawing */
	return self;
}

@end
