/* a Notefilter subclass that provides various left-right panning effects. */

#import <musickit/musickit.h>
#import <appkit/appkit.h>
#import <mididriver/midi_spec.h>
#import "Location.h"
#import "LocationPerformer.h"
#import "ParamInterface.h"

@implementation Location:EnsembleNoteFilter
{
}

+ initialize
{
	[Location setVersion:2];
	return self;
}

- loadNibFile
{
	[NXApp loadNibSection:"Location.nib" owner:self];
	return self;
}

- setDefaults
{
	[super setDefaults];
	minBearing = -45.0;
	maxBearing = 45.0;
	width = 90.0;
	halfWidth = (maxBearing - minBearing) / 2.0;
	minFollowBearing = minBearing;
	maxFollowBearing = maxBearing;
	center = 0;
	positions = 3;
	spreadInc = width / positions;
	bearing = -45 + spreadInc / 2.0;
	type = Spread;
	minKey = c2k;
	maxKey = c6k;
	keyWidth = maxKey - minKey;
	minSweepTime = 2.0;
	sweepTimeScl = (8.0 - minSweepTime) / 127.0;
	sendMidiPan = NO;
	performerStatus = MK_inactive;
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	performer = [[LocationPerformer allocFromZone:[self zone]] init];
	[super init];
	note = [[Note alloc] init];
	[note setNoteType:MK_noteUpdate];
	conductor = [Conductor defaultConductor];
	tagTable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"i" capacity:128];
	return self;
}

- awakeFromNib
{
	[super awakeFromNib];
	[paramInterface setModeAt:2 to:INTS];
	[paramInterface setModeAt:3 to:KEYNUMS];
	[paramInterface setModeAt:4 to:KEYNUMS];
	[paramInterface setModeAt:5 to:DOUBLES];
	[paramInterface setIntValueAt:0 to:(int)minBearing];
	[paramInterface setIntValueAt:1 to:(int)maxBearing];
	[paramInterface setIntValueAt:2 to:positions];
	[paramInterface setIntValueAt:3 to:minKey];
	[paramInterface setIntValueAt:4 to:maxKey];
	[paramInterface setIntValueAt:5 to:minSweepTime];
	[typeButtons selectCellWithTag:type];
	[trackMidiSwitch setState:followMidiPan];
	[sendMidiSwitch setState:sendMidiPan];
	return self;
}

- free
{
	[note free];
	[tagTable free];
	[paramInterface free];
	return [super free];
}

- takeParamFrom:sender
{
	switch ([sender selectedIndex]) {
		case 0:
			minBearing = (double)[sender intValue];
			if (minBearing > maxBearing)
				[paramInterface setIntValueAt:1 to:(int)(maxBearing = minBearing)];
			[performer setMinBearing:minBearing];
			width = maxBearing - minBearing;
			halfWidth = width / 2.0;
			spreadInc = width / positions;
			break;
		case 1:
			maxBearing = (double)[sender intValue];
			if (maxBearing < minBearing)
				[paramInterface setIntValueAt:0 to:(int)(minBearing = maxBearing)];
			[performer setMaxBearing:maxBearing];
			width = maxBearing - minBearing;
			halfWidth = width / 2.0;
			spreadInc = width / positions;
			break;
		case 2:
			positions = [sender intValue];
			spreadInc = width / positions;
			if (type == Spread) {
				bearing = -45 + spreadInc / 2.0;
				[tagTable empty];
			}
		case 3:
			minKey = [sender intValue];
			if (minKey > maxKey)
				[paramInterface setIntValueAt:4 to:maxKey = minKey];
			keyWidth = maxKey - minKey;
			break;
		case 4:
			maxKey = [sender intValue];
			if (maxKey < minKey)
				[paramInterface setIntValueAt:3 to:minKey = maxKey];
			keyWidth = maxKey - minKey;
			break;
		case 5:
			[performer setSweepTime:[sender doubleValue]];
			break;
	}

	if (followMidiPan) {
		minFollowBearing = MAX(-45, (center - halfWidth));
		maxFollowBearing = MIN(45, (center + halfWidth));
	}
	[document setEdited];
	return self;
}

- takeTypeFrom:sender
{
	ButtonCell *cell = [sender selectedCell];

	if (!cell)
		return self;
	type = (LocateType)[cell tag];
	if (type == Spread) {
		[paramInterface setEnabledAt:2 to:YES];
		bearing = -45 + spreadInc / 2.0;
	} else {
		[paramInterface setEnabledAt:2 to:NO];
		bearing = minBearing;
	}
	[paramInterface setEnabledAt:3 to:(type == Key)];
	[paramInterface setEnabledAt:4 to:(type == Key)];
	if (type == Sweep) {
		minFollowBearing = MAX(-45, (center - halfWidth));
		maxFollowBearing = MIN(45, (center + halfWidth));
		[paramInterface setEnabledAt:5 to:YES];
		[Conductor lockPerformance];
		[(LocationPerformer *) performer activate];
		[Conductor unlockPerformance];
	} else {
		[paramInterface setEnabledAt:5 to:NO];
		[Conductor lockPerformance];
		[(LocationPerformer *) performer deactivate];
		[Conductor unlockPerformance];
	}
	[Conductor lockPerformance];
	[note removePar:MK_bearing];
	[note removePar:MK_controlChange];
	[note removePar:MK_controlVal];
	[Conductor unlockPerformance];
	[tagTable empty];
	[document setEdited];

	return self;
}

- toggleFollowing:sender
{
	if (followMidiPan = [sender state]) {
		minFollowBearing = MAX(-45, (center - halfWidth));
		maxFollowBearing = MIN(45, (center + halfWidth));
	}
	[document setEdited];

	return self;
}

- togglePanSending:sender
{
	sendMidiPan = [sender state];
	[document setEdited];

	return self;
}

- spread:aNote
{
	double thisBearing;
	int tag = [aNote noteTag];
	int value = (int)[tagTable valueForKey:(const void *)tag];

	/* Don't move notes that have been placed already */
	if (value)
		thisBearing = (double)value;
	else {
		[tagTable insertKey:(const void *)tag value:(void *)((int)bearing)];
		thisBearing = bearing;
		bearing += spreadInc;
		if (bearing > maxBearing)
			bearing = minBearing + spreadInc / 2.0;
	}
	MKSetNoteParToDouble(aNote, MK_bearing, thisBearing);
	[noteSender sendNote:aNote];/* Send current note */
	if (sendMidiPan) {
		[note setNoteTag:tag];
		MKSetNoteParToInt(note, MK_controlChange, MIDI_PAN);
		MKSetNoteParToInt(note, MK_controlVal, (int)((thisBearing + 45.0) * 1.411));
		[noteSender sendNote:note];
	}
	return self;
}

extern long random();

#define MAXRAN 2147483647.0
#define NRAN (MIN(1.0,(double)random()/MAXRAN))

- randomize:aNote
{
	int tag = [aNote noteTag];
	void *value = [tagTable valueForKey:(const void *)tag];

	/* Don't move notes that have been placed already */
	if (value)
		bearing = (double)((int)value);
	else {
		bearing = minBearing + width * NRAN;
		[tagTable insertKey:(const void *)tag value:(void *)((int)bearing)];
	}
	MKSetNoteParToDouble(aNote, MK_bearing, bearing);
	[noteSender sendNote:aNote];/* Send current note */
	if (sendMidiPan) {
		[note setNoteTag:tag];
		MKSetNoteParToInt(note, MK_controlChange, MIDI_PAN);
		MKSetNoteParToInt(note, MK_controlVal, (int)((bearing + 45.0) * 1.411));
		[noteSender sendNote:note];
	}
	return self;
}

- keyLocate:aNote
{
	double key = MAX(MIN([aNote keyNum], maxKey), minKey);

	bearing = minBearing + width * (key - minKey) / keyWidth;
	MKSetNoteParToDouble(aNote, MK_bearing, bearing);
	[noteSender sendNote:aNote];/* Send current note */
	if (sendMidiPan) {
		[note setNoteTag:[aNote noteTag]];
		MKSetNoteParToInt(note, MK_controlChange, MIDI_PAN);
		MKSetNoteParToInt(note, MK_controlVal, (int)((bearing + 45.0) * 1.411));
		[noteSender sendNote:note];
	}
	return self;
}

- toggleBypass:sender
{
	if ((type == Sweep) && ![sender state])
		[(LocationPerformer *) performer deactivate];
	return [super toggleBypass:sender];
}

- hasActivated:sender
{
	performerStatus = MK_active;
	return self;
}

- hasDeactivated:sender
{
	performerStatus = MK_inactive;
	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
{
	int noteType = [aNote noteType];
	int panVal = -1;
	double oldBearing = MK_NODVAL;

	if (MKIsNoteParPresent(aNote, MK_bearing))
		oldBearing = MKGetNoteParAsDouble(aNote, MK_bearing);
	if (MKGetNoteParAsInt(aNote, MK_controlChange) == 23)
		[performer setSweepTime:minSweepTime + sweepTimeScl *
		 MKGetNoteParAsDouble(aNote, MK_controlVal)];
	else if (MKGetNoteParAsInt(aNote, MK_controlChange) == MIDI_PAN) {
		panVal = MKGetNoteParAsDouble(aNote, MK_controlVal);
		center = (-45.0 + panVal *.70866);
		if (followMidiPan) {
			minBearing = MAX(-45, (center - halfWidth));
			maxBearing = MIN(45, (center + halfWidth));
			width = maxBearing - minBearing;
			if (type == Sweep) {
				[performer setMinBearing:minBearing];
				[performer setMaxBearing:maxBearing];
			}
		}
		[aNote removePar:MK_controlChange];	/* clobber pan message */
		[aNote removePar:MK_controlVal];
	}
	if ((noteType == MK_noteOn) || (noteType == MK_noteDur)) {
		switch (type) {
			case Spread:
				[self spread:aNote];
				break;
			case Randomize:
				[self randomize:aNote];
				break;
			case Key:
				[self keyLocate:aNote];
				break;
			case Sweep:
				MKSetNoteParToDouble(aNote, MK_bearing,[performer bearing]);
				[noteSender sendNote:aNote];
				if (performerStatus != MK_active)
					[(LocationPerformer *) performer activate];
				break;
		}
	} else
		[noteSender sendNote:aNote];
	/* restore previous parameters if necessary */
	if (panVal >= 0) {
		MKSetNoteParToInt(aNote, MK_controlChange, MIDI_PAN);
		MKSetNoteParToInt(aNote, MK_controlVal, panVal);
	}
	if (!MKIsNoDVal(oldBearing))
		MKSetNoteParToDouble(aNote, MK_bearing, oldBearing);

	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "dddddddddddiiiiicc",
				 &minBearing, &maxBearing, &minFollowBearing,
				 &maxFollowBearing, &width, &halfWidth, &center, &bearing,
				 &minSweepTime, &sweepTimeScl, &spreadInc,
				 &minKey, &maxKey, &keyWidth, &positions, &type,
				 &followMidiPan, &sendMidiPan);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int version;

	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "Location");

	if (version < 2) {
		id dummy;
		NXReadTypes(stream, "dddddddddddiiiiicc",
					&minBearing, &maxBearing, &minFollowBearing,
					&maxFollowBearing, &width, &halfWidth, &center, &bearing,
					&minSweepTime, &sweepTimeScl, &spreadInc,
					&minKey, &maxKey, &keyWidth, &positions, &type,
					&followMidiPan, &sendMidiPan);
		NXReadType(stream, "@", &dummy);
		NXReadType(stream, "@", &dummy);
		NXReadType(stream, "@", &dummy);
		NXReadType(stream, "@", &dummy);
		NXReadType(stream, "@", &dummy);
		NXReadType(stream, "@", &dummy);
		NXReadType(stream, "@", &dummy);
		NXReadType(stream, "@", &dummy);
	} else if (version == 2) {
		NXReadTypes(stream, "dddddddddddiiiiicc",
					&minBearing, &maxBearing, &minFollowBearing,
					&maxFollowBearing, &width, &halfWidth, &center, &bearing,
					&minSweepTime, &sweepTimeScl, &spreadInc,
					&minKey, &maxKey, &keyWidth, &positions, &type,
					&followMidiPan, &sendMidiPan);
	}
	return self;
}

- awake
 /* Initialize certain non-archived data */
{
	[super awake];
	note = [[Note alloc] init];
	[note setNoteType:MK_noteUpdate];
	conductor = [Conductor defaultConductor];
	performerStatus = MK_inactive;

	return self;
}

/* The following are obsolete - defined for compatability with old archived documents */
- takeBearingFrom:sender {return self;}
- takePositionsFrom:sender {return self;}
- takeKeyFrom:sender {return self;}
- takeSweepTimeFrom:sender {return self;}

@end
