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
 
 09/19/89/daj - Changed _myData to type void *.
 03/13/90/daj - Moved private methods to category.
 03/21/90/daj - Added archiving.
 04/21/90/daj - Small mods to get rid of -W compiler warnings.
 08/23/90/daj - Zone API changes
 09/23/95/daj - Bug fix to copyFromZone:. 
 */
#import "_musickit.h"
#import "NotePrivate.h"
#import "MKNoteSender.h"
#import "NoteReceiverPrivate.h"

@implementation MKNoteSender

#define VERSION2 2

+ (void) initialize
{
    if (self != [MKNoteSender class])
	return;
    [MKNoteSender setVersion: VERSION2];//sb: suggested by Stone conversion guide (replaced self)
}

- owner
    /* Gets the owner (an MKInstrument or MKNoteFilter). */
{
    return owner;
}

- (BOOL) isConnected: (MKNoteReceiver *) aNoteReceiver 
    /* Querying; YES if aNoteReceiver is a connection.
    * Returns YES if aNoteReceiver is connected to the receiver.
    */
{
    return ([noteReceivers indexOfObject: aNoteReceiver] != NSNotFound); 
}

- squelch
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
{
    isSquelched = YES;
    return self;
}

- unsquelch
    /* Squelch; Turns on message-sending capability.
    * Unsquelches and returns the receiver.
    */
{
    isSquelched = NO;
    return self;
}

- (BOOL) isSquelched
    /* Querying; YES if the receiver is squelched.
    * Returns YES if the receiver is squelched.
    */
{
    return isSquelched;
}

- (unsigned) connectionCount
    /* Querying; Returns the number of noteReceivers.
    * Returns the number of noteReceivers in the
    * receiver's connection set.
    */
{
    return [noteReceivers count];
}

- (NSArray *) connections
    /* Manipulating; Returns an NSArray of the connections - the receiver's noteReceivers.
    */
{
    return [[noteReceivers copy] autorelease];
}

- (void) dealloc 
    /* Frees the receiver.
    * Frees the receiver. Illegal while the receiver is sending. Returns nil
    * Also removes the name, if any, from the name table.
    * if the receiver is freed.
    */
{
    if (isSending)
	return;
    
    /* MMM sez: 
    
    I needed to use -finishUnarchiving to replace an instance of an
    obsolete class with a new version.  A noteSender was freed, and
    MKNoteSender's -disconnect broke because the noteReceiver instance
    variable was nil.  Apparently, at this point one can wind up freeing
    objects before they are fully unarchived.  MKNoteSender's -free should
    check.  12 Jul 93
    
    */
    
    if (noteReceivers) {  /* See comment above */
	[self disconnect];
	[noteReceivers release];
    }
    MKRemoveObjectName(self);
    [super dealloc];
}			

- (NSString *) description
{
    return [NSString stringWithFormat: @"%@ connected to %@\n", [super description], noteReceivers];
}

#define EXPANDAMT 1

- init
{
    self = [super init];
    if(self != nil) {
	noteReceivers = [[NSMutableArray alloc] initWithCapacity: EXPANDAMT];
	isSending = 0;	
    }
    return self;
}

- disconnect: (MKNoteReceiver *) aNoteReceiver
   /* Manipulating; Disconnects aNoteReceiver from the receiver.
    * Disconnects aNoteReceiver from the receiver.
    * Returns self. 
    * If the receiver is currently sending to its noteReceivers, returns nil.
    */
{
    if (!aNoteReceiver) 
	return self;
    if ([aNoteReceiver _disconnect: self])
	[self _disconnect: aNoteReceiver];
    return self;
}	

- connect: (MKNoteReceiver *) aNoteReceiver 
    /* Manipulating; Connects aNoteReceiver to the receiver.
    * Connects aNoteReceiver to the receiver 
    * and returns self.  
    */
{
    if (![aNoteReceiver isKindOfClass: [MKNoteReceiver class]])
	return self;
    if ([self _connect: aNoteReceiver])  
	[aNoteReceiver _connect: self];    
    return self;
}

- disconnect
    /* Manipulating; Disconnects all the receiver's noteReceivers.
    * Disconnects all the objects connected to the receiver.
    * Returns the receiver, unless the receiver is currently sending to its
    * noteReceivers, in which case does nothing and returns nil.
    */
{
    if (noteReceivers) /* This can happen if you use finishUnarchiving to replace a MKNoteSender */
        [noteReceivers removeAllObjects];
    return self;
}

- sendNote: (MKNote *) aNote atTime: (double) time
    /* Sending; Sends aNote at beat time of the performance.
    * Schedules a request (with aNote's Conductor) for 
* sendNote:aNote to be sent to the receiver at time
    * time, measured in beats from the beginning of the
    * performance.
    * Returns the receiver.
    * 
    * Keep in mind that the connection set may change between the time that
   * this message is received and the time that the sendNote:
    * message is sent.
    */
{	
    [[aNote conductor] sel: @selector(sendNote:) to: self atTime: time argCount: 1, aNote];
    return self;
}

- sendNote: (MKNote *) aNote withDelay: (double) deltaT
    /* Sending; Sends aNote after deltaT beats.
    * Schedules a request (with aNote's Conductor) for 
* sendNote:aNote to be sent to the receiver at time
    * deltaT measured in beats
    * from the time this message is received.
    * Returns the receiver.
    *
    * Keep in mind that the connection set may change between the time that
   * this message is received and the time that the sendNote:
    * message is sent.
    */
{
    [[aNote conductor] sel: @selector(sendNote:) to: self withDelay: deltaT argCount: 1, aNote];
    return self;
}

- sendAndFreeNote: (MKNote *) aNote withDelay: (double) delayTime
    /* Sends the specifed note, delayed by delayTime from the
    current time, as far as the note's conductor is concerned. Then
    frees the note. */
{
    [[aNote conductor] sel: @selector(sendAndFreeNote:) to: self withDelay: delayTime argCount: 1, aNote];
    return self;
}

- sendAndFreeNote: (MKNote *) aNote
    /* Send note and then free it. */
{
    [self sendNote: aNote];
    [aNote release];
    return self;
}

- sendAndFreeNote: (MKNote *) aNote atTime: (double) time
    /* Send the specifed note at the specified time using
    the note's Conductor for time coordination. Then free the note. */
{
    [[aNote conductor] sel: @selector(sendAndFreeNote:) to: self atTime: (double) time argCount: 1, aNote];
    return self;
}

- sendNote: (MKNote *) aNote
    /* Sending; Immediately sends aNote.
   * If the receiver isn't squelched, the receiveNote:aNote
    * message is sent to its noteReceivers and the receiver is returned.
    * If the receiver is squelched, the message isn't sent 
    * and nil is returned.
    */
{
    if (![self connectionCount])
	return self;
    if (_ownerIsAPerformer)
	[aNote _setPerformer:owner];
    isSending++;
    if(!isSquelched)
	[noteReceivers makeObjectsPerformSelector: @selector(receiveNote:) withObject: aNote];
    if (_ownerIsAPerformer)
	[aNote _setPerformer:nil];
    isSending--;
    return (isSquelched) ? nil : self;
}

- copyWithZone: (NSZone *) zone
    /* Creates a new MKNoteSender as a copy of the receiver.
    * Creates, initializes, and returns a new MKNoteSender with the same noteReceivers as the receiver.
    * Thus a new array but the elements are the original noteSenders.
    * If we copied the noteSenders, then we couldn't connect senders.
    */
{
    unsigned int noteReceiverIndex;
    MKNoteSender *newObj = NSCopyObject(self, 0, zone);
    
    newObj->noteReceivers = [NSMutableArray arrayWithCapacity: [noteReceivers count]];
    for (noteReceiverIndex = 0; noteReceiverIndex < [noteReceivers count]; noteReceiverIndex++) {
        [newObj connect: [noteReceivers objectAtIndex: noteReceiverIndex]];
    }
    newObj->_myData = _myData;     /* Data object is now copied, (previously wasn't). But should it?? LMS */
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
	if ([aDecoder versionForClassName:@"MKNoteSender"] == VERSION2) {
	    [aDecoder decodeValuesOfObjCTypes:"@cc", &str, &isSquelched, &_ownerIsAPerformer];
	    if (str) {
		MKNameObject(str,self);
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

- _setOwner: obj
    /* Sets the owner (an MKInstrument or MKNoteFilter). In most cases,
    only the owner itself sends this message. 
    */
{
    owner = obj;
    return self;
}


- (void) _setData: (void *) anObj 
    /* Facility for associating arbitrary data with a NoteReceiver */
{
    _myData = anObj;
}

- (void *) _getData
    /* */
{
    return _myData;
}

- (void) _setPerformer: aPerformer
    /* Sets the receiver's MKPerformer.
    * Associates a aPerformer
    * with the receiver, such that aPerformer
    * owns the receiver.
    * Normally, you only invoke this method if you are 
    * implementing a subclass of MKPerformer that creates MKNoteSender instances.
    * Returns the receiver.
    */
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
