/*
 $Id$
 Defined In: The MusicKit
 HEADER FILES: MusicKit.h
 
 Description:
   See comments in MKNoteSender.h
 
 Original Author: David A. Jaffe
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University  
 Portions Copyright (c) 1999-2004, The MusicKit Project.
 */
/* 
Modification history prior to commit to CVS:
 
 09/19/89/daj - Changed dataObject to type void *.
 03/13/90/daj - Moved private methods to category.
 03/21/90/daj - Added archiving.
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 08/23/90/daj - Zone API changes
 09/23/95/daj - Bug fix to copyFromZone:. 
 */
#import "_musickit.h"
#import "NotePrivate.h"
#import "MKNoteSender.h"

@implementation MKNoteSender

#define VERSION2 2

+ (void) initialize
{
    if (self != [MKNoteSender class])
	return;
    [MKNoteSender setVersion: VERSION2];//sb: suggested by Stone conversion guide (replaced self)
}

/* Gets the owner (an MKInstrument or MKNoteFilter). */
- owner
{
    return owner;
}

/* Querying; YES if aNoteReceiver is a connection.
* Returns YES if aNoteReceiver is connected to the receiver.
*/
- (BOOL) isConnected: (MKNoteReceiver *) aNoteReceiver 
{
    return ([noteReceivers indexOfObject: aNoteReceiver] != NSNotFound); 
}

/* Squelch; Turns off message-sending capability.
* Squelches the receiver.  While a receiver is squelched it can't send
* messages to its noteReceivers.
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
    return self;
}

/* Squelch; Turns on message-sending capability.
* Unsquelches and returns the receiver.
*/
- unsquelch
{
    isSquelched = NO;
    return self;
}

/* Querying; YES if the receiver is squelched.
* Returns YES if the receiver is squelched.
*/
- (BOOL) isSquelched
{
    return isSquelched;
}

/* Querying; Returns the number of noteReceivers.
* Returns the number of noteReceivers in the
* receiver's connection set.
*/
- (unsigned) connectionCount
{
    return [noteReceivers count];
}

/* Manipulating; Returns an NSArray of the connections - the receiver's noteReceivers. */
- (NSArray *) connections
{
    return [[noteReceivers copy] autorelease];
}

- (void) dealloc 
{
    // Illegal while the receiver is sending.
    if (isSending)
	NSLog(@"Assertion failed: attempting to dealloc while MKNoteSender %@ is sending %d\n", self, isSending);
    
    if (noteReceivers != nil) {
	// NSLog(@"in MKNoteSenders dealloc disconnecting all receivers %p\n", noteReceivers);
	[self disconnectAllReceivers];
	[noteReceivers release];
	noteReceivers = nil;
    }
    [dataObject release];
    dataObject = nil;
    // We don't release the owner since it is a weak reference.
    // Also removes the name, if any, from the name table. TODO check if appropriate to do here.
    MKRemoveObjectName(self);
    [super dealloc];
}			

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ connected to %@\n", [super description], noteReceivers];
}

- init
{
    self = [super init];
    if(self != nil) {
	noteReceivers = [[NSMutableArray alloc] initWithCapacity: 2];
	isSending = 0;
	owner = nil;
	dataObject = nil;
    }
    return self;
}

// Disconnects aNoteReceiver from our MKNoteSender instance.
- disconnect: (MKNoteReceiver *) aNoteReceiver
{
    if (!aNoteReceiver) 
	return self;
    if ([aNoteReceiver _disconnect: self])
	[self _disconnect: aNoteReceiver];
    return self;
}	

/* Manipulating; Connects aNoteReceiver to the receiver.
* Connects aNoteReceiver to the receiver 
* and returns self.  
*/
- connect: (MKNoteReceiver *) aNoteReceiver 
{
    if (![aNoteReceiver isKindOfClass: [MKNoteReceiver class]])
	return self;
    if ([self _connect: aNoteReceiver])  
	[aNoteReceiver _connect: self];    
    return self;
}

- (void) disconnectAllReceivers
{
    /* This can happen if you use finishUnarchiving to replace a MKNoteSender */
    if (noteReceivers != nil) {
	// causes a release of each element in the noteReceivers NSArray. dealloc in each noteReceiver
	// must not then disconnect senders as this will cause a release cycle.
	[noteReceivers removeAllObjects];
    }
}

/* Keep in mind that the connection set may change between the time that
 * this message is received and the time that the sendNote:
 * message is sent.
 */
- (void) sendNote: (MKNote *) aNote atTime: (double) time
{	
    [[aNote conductor] sel: @selector(sendNote:) to: self atTime: time argCount: 1, aNote];
}

/* Keep in mind that the connection set may change between the time that
 * this message is received and the time that the sendNote:
 * message is sent.
 */
- (void) sendNote: (MKNote *) aNote withDelay: (double) deltaT
{
    [[aNote conductor] sel: @selector(sendNote:) to: self withDelay: deltaT argCount: 1, aNote];
}

/* Sends the specifed note, delayed by delayTime from the
current time, as far as the note's conductor is concerned. Then
frees the note. */
- sendAndFreeNote: (MKNote *) aNote withDelay: (double) delayTime
{
    [[aNote conductor] sel: @selector(sendAndFreeNote:) to: self withDelay: delayTime argCount: 1, aNote];
    return self;
}

/* Send note and then free it. */
- sendAndFreeNote: (MKNote *) aNote
{
    [self sendNote: aNote];
    [aNote release];
    return self;
}

/* Send the specifed note at the specified time using
the note's MKConductor for time coordination. Then free the note. */
- sendAndFreeNote: (MKNote *) aNote atTime: (double) time
{
    [[aNote conductor] sel: @selector(sendAndFreeNote:) to: self atTime: (double) time argCount: 1, aNote];
    return self;
}

/* Sending; Immediately sends aNote.
* If the receiver isn't squelched, the receiveNote:aNote
* message is sent to its noteReceivers and the receiver is returned.
* If the receiver is squelched, the message isn't sent 
* and nil is returned.
*/
- sendNote: (MKNote *) aNote
{
    if (![self connectionCount])
	return self;
    if (_ownerIsAPerformer)
	[aNote _setPerformer: owner];
    isSending++;
    if(!isSquelched)
	[noteReceivers makeObjectsPerformSelector: @selector(receiveNote:) withObject: aNote];
    if (_ownerIsAPerformer)
	[aNote _setPerformer: nil];
    isSending--;
    return (isSquelched) ? nil : self;
}

/* Creates a new MKNoteSender as a copy of the receiver.
* Creates, initializes, and returns a new MKNoteSender with the same noteReceivers as the receiver.
* Thus a new array but the elements are the original noteSenders.
* If we copied the noteSenders, then we couldn't connect senders.
*/
- copyWithZone: (NSZone *) zone
{
    unsigned int noteReceiverIndex;
    MKNoteSender *newObj = NSCopyObject(self, 0, zone);
    
    newObj->noteReceivers = [[NSMutableArray arrayWithCapacity: [noteReceivers count]] retain];
    for (noteReceiverIndex = 0; noteReceiverIndex < [noteReceivers count]; noteReceiverIndex++) {
        [newObj connect: [noteReceivers objectAtIndex: noteReceiverIndex]];
    }
    newObj->dataObject = [dataObject retain];
    newObj->owner = owner;
    newObj->_ownerIsAPerformer = _ownerIsAPerformer;
    newObj->isSending = isSending;
    return newObj;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{
    // Check if decoding a newer keyed coding archive
    if([aCoder allowsKeyedCoding]) {
	NSString *objectName = MKGetObjectName(self);
	
	/* We don't write connection count here because we can deduce it in initWithCoder: */
	[aCoder encodeConditionalObject: noteReceivers forKey: @"MKNoteSender_noteReceivers"];
	[aCoder encodeObject: objectName forKey: @"MKNoteSender_objectName"];
	[aCoder encodeBool: isSquelched forKey: @"MKNoteSender_isSquelched"];
	[aCoder encodeBool: _ownerIsAPerformer forKey: @"MKNoteSender_ownerIsAPerformer"];
	[aCoder encodeConditionalObject: owner forKey: @"MKNoteSender_owner"];
    }
    else {
	NSString *str = MKGetObjectName(self);
	/* We don't write connection count here because we can deduce it in initWithCoder: */
	[aCoder encodeValuesOfObjCTypes:"@cc", &str, &isSquelched, &_ownerIsAPerformer];
	[aCoder encodeConditionalObject:owner];
	[aCoder encodeConditionalObject:noteReceivers];
    }    
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    // Check if decoding a newer keyed coding archive
    if([aDecoder allowsKeyedCoding]) {
	NSString *objectName;
	
	[noteReceivers release];
	noteReceivers = [[aDecoder decodeObjectForKey: @"MKNoteSender_noteReceivers"] retain];
	objectName = [aDecoder decodeObjectForKey: @"MKNoteSender_objectName"];
	if (objectName) {
	    MKNameObject(objectName, self);
	}
	isSquelched = [aDecoder decodeBoolForKey: @"MKNoteSender_isSquelched"];
	_ownerIsAPerformer = [aDecoder decodeBoolForKey: @"MKNoteSender_ownerIsAPerformer"];
	[owner release];
	owner = [[aDecoder decodeObjectForKey: @"MKNoteSender_owner"] retain];
    }
    else {
	NSString *str;
	if ([aDecoder versionForClassName: @"MKNoteSender"] == VERSION2) {
	    [aDecoder decodeValuesOfObjCTypes: "@cc", &str, &isSquelched, &_ownerIsAPerformer];
	    if (str) {
		MKNameObject(str, self);
		[str release];
	    }
	    owner = [[aDecoder decodeObject] retain];
	    noteReceivers = [[aDecoder decodeObject] retain];
	}
    }
    return self;    
}

@end

@implementation MKNoteSender(Private)

/* Sets the owner (an MKInstrument or MKNoteFilter). In most cases,
only the owner itself sends this message. 
*/
- _setOwner: obj
{
    owner = obj;
    return self;
}

/* Facility for associating arbitrary data with a MKNoteSender */
- (void) _setData: (id) anObj 
{
    [dataObject release];
    dataObject = [anObj retain];
}

- (id) _getData
{
    return [[dataObject retain] autorelease];
}

- (void) _setPerformer: aPerformer
{
    if (!aPerformer) 
	_ownerIsAPerformer = NO;
    else {
	owner = aPerformer;
	_ownerIsAPerformer = YES;
    }
}

- _disconnect: (MKNoteReceiver *) aNoteReceiver
{
    unsigned int i;
    
    if (noteReceivers == nil) /* This can happen if you use finishUnarchiving to replace a MKNoteSender */
	return self;
    if ((i = [noteReceivers indexOfObject: aNoteReceiver]) != NSNotFound) {
	[noteReceivers removeObjectAtIndex: i];
	return self;
    }
    return nil;
}

- _connect: (MKNoteReceiver *) aNoteReceiver
{
    unsigned int i = [noteReceivers indexOfObject: aNoteReceiver];
    
    if (i != NSNotFound) 
	return nil; /* Already there. */
    [noteReceivers addObject: aNoteReceiver];
    return self;
}

@end
