/* A simple note filter that allows notes within a specified range,
 * and handles trasnsposition. 
 */

#import "musickit/musickit.h"
#import <objc/List.h>
#import "KeyRange.h"
#import "ParamInterface.h"
// #import <appkit/appkit.h>
#import <mididriver/midi_spec.h>

@implementation KeyRange:EnsembleNoteFilter
{
}

+ initialize
{
	[KeyRange setVersion:3];
	return self;
}

- setDefaults
{
	[self setMinKey:12];
	[self setMaxKey:108];
	return self;
}
	
- init
 /* Called automatically when an instance is created. */
{
	[super init];
	tagTable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"i" capacity:256];
	return self;
}

- updateRangeDisplay
{
	char   *str;

	if (!rangeField)
		return self;
	NX_MALLOC(str, char, 10);
	sprintf(str, "%s:%4s", [ParamInterface keyNameFor:minKey], 
		[ParamInterface keyNameFor:maxKey]);
	[rangeField setStringValue:str];
	NX_FREE(str);

	return self;
}

- awakeFromNib
{
	[super awakeFromNib];
	[self updateRangeDisplay];
	[minKeySlider setIntValue:minKey];
	[maxKeySlider setIntValue:maxKey];
	[transpositionField setIntValue:transposition];
	[transpositionSlider setIntValue:transposition];
	return self;
}

- free
{
	[tagTable free];
	return [super free];
}

- setMinKey:(int)aKey
{
	minKey = aKey;
	if (minKey > maxKey)
		[maxKeySlider setIntValue:maxKey = minKey];
	[self updateRangeDisplay];

	return self;
}

- setMaxKey:(int)aKey
{
	maxKey = aKey;
	if (maxKey < minKey)
		[minKeySlider setIntValue:minKey = maxKey];
	[self updateRangeDisplay];

	return self;
}

- takeMinKeyFrom:sender
{
	[document setEdited];
	return[self setMinKey:[sender intValue]];
}

- takeMaxKeyFrom:sender
{
	[document setEdited];
	return[self setMaxKey:[sender intValue]];
}

- (int)minKey
{
	return minKey;
}

- (int)maxKey
{
	return maxKey;
}

- takeTranspositionFrom:sender
{
	transposition = [sender intValue];
	if (transpositionField)
		[transpositionField setIntValue:transposition];
	[document setEdited];

	return self;
}

- realizeNote:aNote fromNoteReceiver:aNoteReceiver
 /*
  * Block all notes with keynum out of range, transpose if needed. Save note
  * tags of all noteOns passed through.  If a noteOff or noteUpdate comes along
  * and the tag is not present in the hash table, omit it as well. 
  *
  * Note that this version only handles key numbers, and notes with note tags.  It
  * needs to be expanded to handle notes without note tags and to reset freq0
  * and freq1 when they are present and transposition is in effect.  Left as an
  * exercise for the reader! 
  */
{
	int     tag = [aNote noteTag];
	int     mappedtag = MAXINT, newtag = 0;
	int     key = 0, newkey = MAXINT;

	if (tag != MAXINT) {
		key = [aNote keyNum];
		mappedtag = (int)[tagTable valueForKey:(const void *)tag];
		if (key != MAXINT) {
			if ((key < minKey) || (key > maxKey)) {
				if (mappedtag)
					[tagTable removeKey:(const void *)tag];
				return self;
			}
			if (transposition) {
				MKSetNoteParToInt(aNote, MK_keyNum, newkey = key + transposition);
				if (!mappedtag)
					newtag = MKNoteTag();
			}
			if (!mappedtag)
				[tagTable insertKey:(const void *)tag
				 value:(void *)(mappedtag = (newtag) ? newtag : tag)];
		}
		if (!mappedtag)
			return self;
		if (mappedtag != tag)
			[aNote setNoteTag:mappedtag];
	}
	[noteSender sendNote:aNote];
	if (mappedtag != tag)
		[aNote setNoteTag:tag];
	if (newkey != MAXINT)
		MKSetNoteParToInt(aNote, MK_keyNum, key);
	return self;
}

- write:(NXTypedStream *) stream
 /* Archive the notefilter to a typed stream. */
{
	[super write:stream];
	NXWriteTypes(stream, "iii", &minKey, &maxKey, &transposition);
	return self;
}

- read:(NXTypedStream *) stream
 /* Unarchive the notefilter from a typed stream. */
{
	int version;
	[super read:stream];
	version = NXTypedStreamClassVersion(stream, "KeyRange");
	
	if (version < 2) {
		NXReadTypes(stream, "iii", &minKey, &maxKey, &transposition);
		rangeField = NXReadObject(stream);
		transpositionField = NXReadObject(stream);
		minKeySlider = NXReadObject(stream);
		maxKeySlider = NXReadObject(stream);
	}
	else if (version == 2)
		NXReadTypes(stream, "iii@@@@", &minKey, &maxKey, &transposition, 
			&rangeField, &transpositionField, &minKeySlider, &maxKeySlider);	
	else if (version == 3)
		NXReadTypes(stream, "iii", &minKey, &maxKey, &transposition);
	return self;
}

- awake
 /* Allocate the note tag hashtable, which isn't archived */
{
	[super awake];
	tagTable = [[HashTable alloc] initKeyDesc:"i" valueDesc:"i" capacity:256];
	return self;
}

@end
