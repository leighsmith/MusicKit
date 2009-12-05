/* A performer which implements dynamic panning back and forth */

#import <musickit/musickit.h>
#import <appkit/appkit.h>
#import <mididriver/midi_spec.h>
#import "Location.h"
#import "LocationPerformer.h"
#import "EnsembleDoc.h"

@implementation LocationPerformer:Performer
{
}

+ initialize
 /* Set the version. This can be used in a later version to distinguish older
  * formats when unarchiving documents. 
  */
{
	[LocationPerformer setVersion:2];
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	noteSender = [self addNoteSender:[[NoteSender allocFromZone:[self zone]] init]];
	minBearing = -45.0;
	maxBearing = 45.0;
	bearing = minBearing;
	width = 90.0;
	sweepTime = 2.0;
	direction = 2;
	note = [[Note allocFromZone:[self zone]] init];
	[note setNoteType:MK_noteUpdate];
	conductor = [Conductor defaultConductor];

	return self;
}

- free
{
	[self deactivate];
	[note free];
	return[super free];
}

- setMinBearing:(double)aBearing
{
	minBearing = aBearing;
	width = maxBearing - minBearing;

	return self;
}

- setMaxBearing:(double)aBearing
{
	maxBearing = aBearing;
	width = maxBearing - minBearing;

	return self;
}

- setSweepTime:(double)aTime
{
	sweepTime = aTime;
	return self;
}

- (double)bearing
{
	return bearing;
}

- setSendMidiPan:(BOOL)sendPan
{
	sendMidiPan = sendPan;
	return self;
}

- perform
{
	MKSetNoteParToDouble(note, MK_bearing, bearing);
	[noteSender sendNote:note];	/* Send current note */
	if (sendMidiPan) {
		MKSetNoteParToInt(note, MK_controlChange, MIDI_PAN);
		MKSetNoteParToInt(note, MK_controlVal, (int)((bearing + 45.0) * 1.411));
		[noteSender sendNote:note];
	}
	bearing += direction;
	if (bearing > maxBearing) {
		bearing = maxBearing;
		direction = -direction;
	} else if (bearing < minBearing) {
		bearing = minBearing;
		direction = -direction;
	}
	nextPerform = 2 * sweepTime / width;

	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the performer to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "ddddddc", &minBearing, &maxBearing,
				 &bearing, &width, &sweepTime, &direction, &sendMidiPan);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the performer to a typed stream. */
{
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "LocationPerformer");

	if (version < 2) {
		NXReadTypes(stream, "ddddddc", &minBearing, &maxBearing,
				&bearing, &width, &sweepTime, &direction, &sendMidiPan);
		NXReadObject(stream);
	}
	else if (version == 2)
		NXReadTypes(stream, "ddddddc", &minBearing, &maxBearing,
				&bearing, &width, &sweepTime, &direction, &sendMidiPan);
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];
	noteSender = [self noteSender];
	conductor = [Conductor defaultConductor];
	note = [[Note alloc] init];
	[note setNoteType:MK_noteUpdate];

	return self;
}

@end
