/*
 $Id$
 Defined In: The MusicKit
 HEADER FILES: MusicKit.h
 
 Description:
 See comments in MKNoteReceiver.h.
 
 Original Author: David A. Jaffe
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2004, The MusicKit Project.
 */
/* 
Modification history before commit to CVS:
 
 09/19/89/daj - Changed dataObject to type void *.
 03/13/90/daj - Moved private methods to category.
 03/21/90/daj - Added archiving.
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 08/23/90/daj - Zone API changes
 09/06/90/daj - Fixed bug in archiving again.
 */

#import "_musickit.h"
#import "InstrumentPrivate.h"

@implementation MKNoteReceiver

/* Gets the owner (an MKInstrument or MKNoteFilter). */
- owner
{
    return owner;
}

/* TYPE: Querying; YES if aNoteSender is a connection.
* Returns YES if aNoteSender is connected to the receiver.
*/
- (BOOL) isConnected: (MKNoteSender *) aNoteSender 
{
    return [noteSenders indexOfObject: aNoteSender] != NSNotFound; 
}

/* TYPE: Squelch; Turns off message-sending capability.
* Squelches the receiver.  While a receiver is squelched it can't send
* messages to its noteSenders.
*
* Note:  You can schedule a sendNote: message through
* sendNote:atTime: or sendNote:withDelay even if the
* receiver is squelched.
* However, if the receiver is still squelched when the
* sendNote: message is received, the MKNote isn't sent.
*
* Returns the receiver.
*/
- squelch
{
    isSquelched = YES;
    // This shuts down any sounding notes, otherwise it can be very annoying when
    // the instrument such as an MKSamplePlayerInstrument is playing a long sounding note.
    [owner allNotesOff];  
    return self;
}

/* TYPE: Squelch; Turns on message-sending capability.
* Unsquelches and returns the receiver.
*/
- unsquelch
{
    isSquelched = NO;
    return self;
}

/* TYPE: Querying; YES if the receiver is squelched.
* Returns YES if the receiver is squelched.
*/
- (BOOL) isSquelched
{
    return isSquelched;
}

/* TYPE: Querying; Returns the number of noteSenders.
* Returns the number of noteSenders in the
* receiver's connection set.
*/
- (unsigned) connectionCount
{
    return [noteSenders count];
}

/* TYPE: Manipulating; Returns a copy of the List of the connections.
* Returns a copy of the NSArray of the receiver's noteSenders. 
* The noteSenders themselves are not
* copied. TODO at the moment it is the sender's responsibility to free the NSArray.
*/
- (NSArray *) connections
{
    return _MKLightweightArrayCopy(noteSenders);
    // TODO should become return [_MKLightweightArrayCopy(noteSenders) autorelease];
}

#define VERSION2 2

+ (void) initialize
{
    if (self != [MKNoteReceiver class])
	return;
    [MKNoteReceiver setVersion: VERSION2];//sb: suggested by Stone conversion guide (replaced self)
}

- init 
{
    self = [super init];
    if(self != nil) {
	noteSenders = [[NSMutableArray alloc] init];
	owner = nil;
	dataObject = nil;
    }
    return self;
}

/* TYPE: Creating; Frees the receiver.
 * Frees the receiver. Illegal while the receiver is sending.
 * Also removes the name, if any, from the name table.
 */
- (void) dealloc
{
    if(noteSenders != nil) {
	// We have a retain cycle between MKNoteSenders and MKNoteReceivers since instances of both classes hold
	// (retaining) NSArrays of an arbitary number of the other class. The traditional way of dealing with such
	// a retain cycle is to assign one object as subordinated to the other, with the subordinate holding a
	// non-retained weak reference to the "superior" (retaining) object.
	// However storing the references in NSArrays themselves create retention. We therefore have a modified
        // policy: MKNoteReceivers are subordinated to MKNoteSenders, and they should inform the noteSenders here,
	// in dealloc, that they are no longer valid.
	// However, we can't just disconnect them since that would cause the noteSenders to each
	// attempt to remove their MKNoteReceivers from their noteReceivers NSArray, causing this dealloc method
	// to be called recursively and endlessly.
	// Two options seem possible: we temporarily retain our note receivers held by each of the note senders (!)
	// or reset the noteSenders connections to this receiver nil. Unfortunately that can't be done without NSArray
	// releasing the MKNoteReceiver element. 
	// The best option is to leave noteSenders connected to this note receiver and then release noteSenders and
	// require that any MKNoteReceivers explictly connected to an MKNoteSender must be disconnected from that
	// MKNoteSender.
	// [self disconnect];
	// NSLog(@"In MKNoteReceiver dealloc of %p, have disconnected, releasing %p\n", self, noteSenders);
	[noteSenders release];
	// NSLog(@"Released noteSenders %p\n", noteSenders);
	noteSenders = nil;	
    }
    [dataObject release];
    dataObject = nil;
    MKRemoveObjectName(self);
    [super dealloc];
}

/* TYPE: Creating; Creates a new MKNoteReceiver as a copy of the receiver.
 * Creates, initializes, and returns a new MKNoteReceiver with the same noteSenders as the receiver.
 */
- copyWithZone: (NSZone *) zone
{
    unsigned n = [noteSenders count], i;
    MKNoteReceiver *newObj = (MKNoteReceiver *) NSCopyObject(self, 0, zone);

    newObj->noteSenders = [[NSMutableArray arrayWithCapacity: [noteSenders count]] retain];
    for (i = 0; i < n; i++)
        [newObj connect: [noteSenders objectAtIndex: i]];
    newObj->dataObject = nil;
    newObj->owner = nil;
    return newObj;
}

// Disconnects aNoteSender from the receiver. We do this by requesting the MKNoteSender to disconnect from us.
// This concentrates responsibility (and more concretely object allocation management) with the MKNoteSender.
- disconnect: (MKNoteSender *) aNoteSender
{
    if (!aNoteSender)
	return self;
    
    // Inform the note sender to disconnect from us.
    if ([aNoteSender _disconnect: self]) {
        [self _disconnect: aNoteSender];
    }
    return self;
}	

- disconnect
{
    /* Need to copy since MKNoteSender -disconnect: modifies contents. */
    NSMutableArray *allOfOurNoteSenders = _MKLightweightArrayCopy(noteSenders);
    // NSLog(@"MKNoteReceiver %p disconnecting all note senders %@\n", self, allOfOurNoteSenders);
    [allOfOurNoteSenders makeObjectsPerformSelector: @selector(disconnect:) withObject: self];
    [allOfOurNoteSenders release];
    return self;
}

/* TYPE: Manipulating; Connects aNoteSender to the receiver.
* Connects aNoteSender to the receiver 
* and returns self.  
*/
- connect: (MKNoteSender *) aNoteSender 
{
    if (![aNoteSender isKindOfClass: [MKNoteSender class]])
	return self;
    if ([self _connect: aNoteSender])  /* Success ? */
	[aNoteSender _connect: self];    /* Make other-way link */
    return self;
}

// Receiving; Forwards note to its owner, unless squelched.
- receiveNote: (MKNote *) aNote
{
    if (isSquelched)
	return nil;
    [owner _realizeNote: aNote fromNoteReceiver: self];
    return self;
}

 /* TYPE: Receiving; Receive MKNote at time specified in beats.
Receives the specifed note at the specified time using
the note's Conductor for time coordination. */
- receiveNote: (MKNote *) aNote atTime: (double) time 
{
    [[aNote conductor] sel: @selector(receiveNote:) to: self atTime: time  argCount: 1, aNote];
    return self;
}

/* Receives the specifed note, delayed by delayTime from the
current time, as far as the note's conductor is concerned. 
Uses the note's Conductor for time coordination. */
- receiveNote: (MKNote *) aNote withDelay: (double) delayTime
{
    [[aNote conductor] sel: @selector(receiveNote:) to: self withDelay: delayTime argCount: 1, aNote];
    return self;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{
    // Check if decoding a newer keyed coding archive
    if([aCoder allowsKeyedCoding]) {
	NSString *objectName = MKGetObjectName(self);
	
	[aCoder encodeConditionalObject: noteSenders forKey: @"MKNoteReceiver_noteSenders"];
	[aCoder encodeObject: objectName forKey: @"MKNoteReceiver_objectName"];
	[aCoder encodeBool: isSquelched forKey: @"MKNoteReceiver_isSquelched"];
	[aCoder encodeConditionalObject: owner forKey: @"MKNoteReceiver_owner"];
    }
    else {
	NSString *str;
	
	str = MKGetObjectName(self);
	[aCoder encodeConditionalObject: noteSenders];
	[aCoder encodeValuesOfObjCTypes: "@c", &str, &isSquelched];
	[aCoder encodeConditionalObject: owner];	
    }
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    // Check if decoding a newer keyed coding archive
    if([aDecoder allowsKeyedCoding]) {
	NSString *objectName;

	[noteSenders release];
	noteSenders = [[aDecoder decodeObjectForKey: @"MKNoteReceiver_noteSenders"] retain];
	objectName = [aDecoder decodeObjectForKey: @"MKNoteReceiver_objectName"];
	if (objectName) {
	    MKNameObject(objectName, self);
	}
	isSquelched = [aDecoder decodeBoolForKey: @"MKNoteReceiver_isSquelched"];
	[owner release];
	owner = [[aDecoder decodeObjectForKey: @"MKNoteReceiver_owner"] retain];
    }
    else {
	NSString *str;
	
	if ([aDecoder versionForClassName: @"MKNoteReceiver"] == VERSION2) {
	    noteSenders = [[aDecoder decodeObject] retain];
	    
	    [aDecoder decodeValuesOfObjCTypes: "@c", &str, &isSquelched];
	    if (str) {
		MKNameObject(str, self);
	    }
	    owner = [[aDecoder decodeObject] retain];
	}	
    }
    return self;
}

@end

@implementation MKNoteReceiver(Private)

/* Sets the owner (an MKInstrument or MKNoteFilter). In most cases,
only the owner itself sends this message. 
*/
- _setOwner: obj
{
    owner = obj; // Don't retain as this is a weak reference.
    return self;
}

/* Facility for associating an arbitrary datum in a MKNoteReceiver */
- (void) _setData: (id) anObj 
{
    [dataObject release];
    dataObject = [anObj retain];
}

- (id) _getData
{
    return [[dataObject retain] autorelease];
}

- _connect: (MKNoteSender *) aNoteSender
{
    if ([noteSenders indexOfObject: aNoteSender] != NSNotFound)  /* Already there. */
	return nil;
    [noteSenders addObject: aNoteSender];
    return self;
}

- _disconnect: (MKNoteSender *) aNoteSender
{
    unsigned int returnedIndex;
    
    if ((returnedIndex = [noteSenders indexOfObjectIdenticalTo: aNoteSender]) != NSNotFound) {
        [noteSenders removeObjectAtIndex: returnedIndex];
        return self; /* Returns aNoteSender if success */
    }
    /*    if ([noteSenders removeObject:aNoteSender])       return self;
    */
    return nil;
}

@end

