/* EnsembleNoteFilter provides common functionality for all NoteFilter
 * subclasses in Ensemble.  Instances are maintained in four linked lists,
 * one for each input stage.  Although the filters are instatiated on
 * demand (except for KeyRange), there is a fixed order for the various
 * types (due to lack of an interface for an ordering mechanism, left as 
 * an exercise for the reader!).  When a filter is enabled, its noteReceiver
 * receives notes from the previous enabled filter in the chain, and its
 * noteSender sends to the next enabled filter, or to the instruments. If
 * a filter is not enabled (i.e., bypassed), it is still in the linked list,
 * but not connected to anything.
 */

#import <appkit/appkit.h>
#import "EnsembleApp.h"
#import "EnsembleNoteFilter.h"

const char *filterClasses[NUMFILTERS]
= {"MidiFilter", "Mapper", "FractalMelody",
   "Harmonics", "Echo", "Chord", "Quad",
   "Mapper", "Location", "MIDIometer"};
const char *filterNames[NUMFILTERS]
= {"MIDI Filter", "Data Map 1", "Fractal Melody",
   "Harmonics", "Echos", "Chord Map", "Quad",
   "Data Map 2", "Location", "MIDIometer"};

@implementation EnsembleNoteFilter:NoteFilter
{
}

+ initialize
{
	[EnsembleNoteFilter setVersion:2];
	return self;
}

- loadNibFile
 /* load the interface file. */
{
	return self;
}

- setDefaults
{
	isEnabled = NO;
	return self;
}

- init
 /* Called automatically when an instance is created. */
{
	[super init];
	noteReceiver = [self addNoteReceiver:[[NoteReceiver alloc] init]];
	noteSender = [self addNoteSender:[[NoteSender alloc] init]];
	[self setDefaults];
	return self;
}

- awakeFromNib
{
	[inspectorPanel setDelegate:self];
	[bypassButton setState:!isEnabled];
	return self;
}

- showInspector
{
	if (!inspectorPanel)
		[self loadNibFile];
	if (inspectorPanel)
		[inspectorPanel makeKeyAndOrderFront:nil];
	return self;
}

- free
 /* Disconnect from the other note filters before freeing. */
{
	[self setEnabled:NO];
	[lastFilter setNextFilter:nextFilter];
	[nextFilter setLastFilter:lastFilter];
	performer = [performer free];
	if (document && [document window])
		[document setEdited];
	if (inspectorPanel) {
		[inspectorPanel close];
		inspectorPanel = [inspectorPanel free];
	}
	return [super free];
}

- setDocument:aDocument
{
	document = aDocument;
	if ([performer respondsTo:@selector(setDocument:)])
		[performer setDocument:document];
	return self;
}

- inspectorPanel
{
	return inspectorPanel;
}

- setEnabled:(BOOL)enable
 /*
  * When a filter is enabled, its noteReceiver receives notes from the previous
  * enabled filter in the chain, and its noteSender sends to the next enabled
  * filter, or to the instruments. If a filter is not enabled (i.e., bypassed),
  * it is still in the linked list, but not connected to anything. 
  */
{
	id      senders;
	id      next = nextFilter;
	id      last = lastFilter;

	while (next && ![next isEnabled])
		next = [next nextFilter];
	while (last && ![last isEnabled])
		last = [last lastFilter];

	if (enable && (!isEnabled)) {
		/*
		 * Disconnect the note senders of the previous filter and/or
		 * performers, and reconnect them to our noteReceiver 
		 */
		if (last) {
			senders = [last allSenders];
			[senders makeObjectsPerform:@selector(disconnect)];
			[senders makeObjectsPerform:@selector(connect:) with :noteReceiver];
			[senders free];
		} else
			[document connectToPerformers:self];
		if (next) {
			senders = [self allSenders];
			[[next noteReceiver] disconnect];
			[senders makeObjectsPerform:@selector(connect:)
			 with :[next noteReceiver]];
			[senders free];
		} else
			[document connectToInstruments:self];
	}
	/* Disconnect this filter */
	else if ((!enable) && isEnabled) {
		/* First disconnect us from everything and stop any performer */
		senders = [self allSenders];
		[senders makeObjectsPerform:@selector(disconnect)];
		[noteReceiver disconnect];
		[senders free];
		if (last && next) {
			senders = [last allSenders];
			[senders makeObjectsPerform:@selector(connect:)
			 with :[next noteReceiver]];
			[senders free];
		} else if (last)
			[document connectToInstruments:last];
		else if (next)
			[document connectToPerformers:next];
	}
	isEnabled = enable;
	if ([bypassButton state] != !isEnabled)
		[bypassButton setState:!isEnabled];
	return self;
}

- (BOOL)isEnabled
{
	return isEnabled;
}

- setPosition:(int)aPosition
 /* Set the position this filter should occupy in the linked list */
{
	position = aPosition;
	return self;
}

- (int)position
{
	return position;
}

- setInputNum:(int)aInputNum
{
	inputNum = aInputNum;
	return self;
}

- (int)inputNum
{
	return inputNum;
}

- setNextFilter:aNoteFilter
{
	nextFilter = aNoteFilter;
	return self;
}

- nextFilter
{
	return nextFilter;
}

- setLastFilter:aNoteFilter
{
	lastFilter = aNoteFilter;
	return self;
}

- lastFilter
{
	return lastFilter;
}

- toggleBypass:sender
{
	[document setEdited];
	return [self setEnabled:![sender state]];
}

- reset
{
	return self;
}

- reset:sender
{
	return [self reset];
}

- setMenuCell:aCell
{
	menuCell = aCell;
	return self;
}

- allSenders
 /*
  * Returns a list of all of the filter's noteSenders combined with the
  * performer's noteSenders, if any. Sender must free the list when done.
  * Subclass may override to add additional noteSenders. 
  */
{
	id      list = [noteSenders copy];

	if (performer) {
		int     i;
		id      senders = [performer noteSenders];

		for (i = 0; i < [senders count]; i++)
			[list addObject:[senders objectAt:i]];
		[senders free];
	}
	return list;
}

- write:(NXTypedStream *) stream
 /* Archive the object to a typed stream */
{
	[super write:stream];
	NXWriteTypes(stream, "@cii@@", &performer,
				 &isEnabled, &position, &inputNum,
				 &nextFilter, &lastFilter);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the object from a typed stream */
{
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "EnsembleNoteFilter");

	if (version == 1) {
		NXReadTypes(stream, "@@cii@@@", &inspectorPanel, &performer,
				&isEnabled, &position, &inputNum,
				&document, &nextFilter, &lastFilter);
		inspectorPanel = [inspectorPanel free];
	}
	else if (version == 2)
		NXReadTypes(stream, "@cii@@", &performer,
				&isEnabled, &position, &inputNum,
				&nextFilter, &lastFilter);
	return self;
}

- awake
 /* Initialize some non-archived data. */
{
	[super awake];
	noteReceiver = [self noteReceiver];
	noteSender = [self noteSender];
	return self;
}

- copy:sender
 /* Archive this object to the pasteboard. */
{
	char   *data;
	const char *types[1];
	int     length;

	[Conductor lockPerformance];
	types[0] = NoteFilterPBType;
	[pasteboard declareTypes:types num:1 owner:self];
	data = NXWriteRootObjectToBuffer(self, &length);
	[pasteboard writeType:NoteFilterPBType data:data length:length];
	NXFreeObjectBuffer(data, length);
	[Conductor unlockPerformance];
	return self;
}

- delete:sender
{
	char label[32];

	sprintf(label, "Open %s", filterNames[position]);
	[menuCell setTitle:label];
	[NXApp delayedFree:self];
	return self;
}

- cut:sender
 /* Archive this object to the pasteboard, then free it. */
{
	[self copy:sender];
	[self delete:sender];
	return self;
}

- inspectorPanelDidResignKey:sender
{
	[inspectorPanel endEditingFor:nil];
	return self;
}

- inspectorPanelDidBecomeKey:sender
{
	[inspectorPanel makeFirstResponder:inspectorPanel];
	return self;
}

- performer
{
	return performer;
}

@end
