/*
  $Id$
  Defined In: The MusicKit

  Description: 
    See MKInstrument.h

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* Modification history:

  $Log$
  Revision 1.9  2001/08/27 19:59:09  leighsmith
  Added allNotesOff as a abstract instance method (since nearly all instruments implemented this anyway) and this provides a mechanism to shut off any sounding notes when a MKNoteReceiver is squelched

  Revision 1.8  2001/08/07 16:16:11  leighsmith
  Corrected class name during decode to match latest MK prefixed name

  Revision 1.7  2001/01/31 21:43:50  leigh
  Typed note parameters

  Revision 1.6  2000/05/13 17:22:04  leigh
  Added indexOfNoteReciever method

  Revision 1.5  2000/04/25 02:11:02  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.4  2000/04/16 04:18:32  leigh
  class typing and comment cleanup

  Revision 1.3  1999/09/28 03:06:06  leigh
  Doco cleanup

  Revision 1.2  1999/07/29 01:16:37  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  03/13/90/daj - Changes to support category for private methods.
  03/21/90/daj - Added archiving.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
  09/26/90/daj & lbj - Added check for [owner inPerformance] in 
                       addNoteReceiver and check for _noteSeen in 
		       freeNoteReceivers.
  02/25/91/daj - Added removeFromPerformance and disconnectNoteReceivers.
                 Also flushed class description comment.
  10/7/93/daj - Added check in addNoteReceiver for existance of NoteReceivers list.
*/

#import "_musickit.h"

#import "ConductorPrivate.h"
#import "NoteReceiverPrivate.h"
#import "InstrumentPrivate.h"

@implementation MKInstrument

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKInstrument class])
      return;
    _MKCheckInit();
    [MKInstrument setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

+ new
  /* Create a new instance and sends [self init]. */
{
    return [[self allocWithZone:NSDefaultMallocZone()] init];
}

- init
  /* TYPE: Creating; Initializes the receiver.
   * Initializes the receiver.
   * You never invoke this method directly,
   * it's sent by the superclass when the receiver is created.
   * An overriding subclass method should send [super\ init]
   * before setting its own defaults. 
   */
{
    noteReceivers = [[NSMutableArray alloc] init];
    return self;
}

- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* TYPE: Performing; Realizes aNote.
   * Realizes aNote in the manner defined by the subclass.  
   * You never send this message; it's sent to an Instrument
   * as its NoteReceivers receive Note objects.
   */
{
    return self;
}


- firstNote: (MKNote *) aNote
  /* TYPE: Performing; Received just before the first Note is realized.
   * You never invoke this method directly; it's sent by the receiver to 
   * itself just before it realizes its first Note.
   * You can subclass the method to perform pre-realization initialization.
   * aNote, the Note that the Instrument is about to realize,
   * is provided as a convenience and can be ignored in a subclass 
   * implementation.  The Instrument isn't considered to be in performance 
   * until after this method returns.
   * The default implementation does nothing and returns the receiver.
   */
{
    return self;
}

- (NSArray *) noteReceivers	
  /* TYPE: Querying; Returns a copy of the Array of NoteReceivers.
   * Returns a copy of the Array of NoteReceivers. The NoteReceivers themselves
   * are not copied.	
   */
{
    return _MKLightweightArrayCopy(noteReceivers);
}

- (int) indexOfNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    return [noteReceivers indexOfObject: aNoteReceiver];
}

- (BOOL) isNoteReceiverPresent: (MKNoteReceiver *) aNoteReceiver
  /* TYPE: Querying; Returns YES if aNoteReceiver is present.
   * Returns YES if aNoteReceiver is a member of the receiver's 
   * NoteReceiver collection.  Otherwise returns NO.
   */
{
    return ([self indexOfNoteReceiver: aNoteReceiver] == ((unsigned)-1))? NO : YES;
}

-addNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* TYPE: Modifying; Adds aNoteReceiver to the receiver.
   * Removes aNoteReceiver from its current owner and adds it to the 
   * receiver. 
   * You can't add a NoteReceiver to an Instrument that's in performance.
   * If the receiver is in a performance, this message is ignored and nil is
   * returned. Otherwise aNoteReceiver is returned.
   */
{
    id owner = [aNoteReceiver owner];
    if (_noteSeen ||  /* in performance */
	(owner && (![owner removeNoteReceiver:aNoteReceiver]))) 
        /* owner might be in perf */
      return nil;
    if (!noteReceivers) /* Just in case init wasn't called */
      noteReceivers = [[NSMutableArray alloc] init];
    [noteReceivers addObject:aNoteReceiver];
    [aNoteReceiver _setOwner:self];
    return aNoteReceiver;
}

-removeNoteReceiver:(MKNoteReceiver *) aNoteReceiver
  /* TYPE: Modifying; Removes aNoteReceiver from the receiver.
   * Removes aNoteReceiver from the receiver and returns it
   * (the NoteReceiver) or nil if it wasn't owned by the receiver.
   * You can't remove a NoteReceiver from an Instrument that's in
   * performance. Returns nil in this case.
   */ 
{
    if ([aNoteReceiver owner] != self)
      return nil;
    if (_noteSeen)
      return nil;
    [noteReceivers removeObject:aNoteReceiver];
    [aNoteReceiver _setOwner:nil];
    return aNoteReceiver;
}

- (void)dealloc
  /* TYPE: Creating; Frees the receiver and its NoteReceivers.
   * Removes and frees the receiver's NoteReceivers and then frees the
   * receiver itself.  
   * The NoteReceiver's connections are severed (see the PerfLink class).
   * This message is ignored if the receiver is in a performance. In this
   * case self is returned; otherwise nil is returned.
   */
{
    if (_noteSeen)
      return;
    [self releaseNoteReceivers];
    [noteReceivers release];
    [super dealloc];
}

-disconnectNoteReceivers
    /* Broadcasts "disconnect" to NoteReceivers. */ 
{
    [noteReceivers makeObjectsPerformSelector:@selector(disconnect)];
    return self;
}

-removeFromPerformance
    /* Invokes [self disconnectNoteReceivers].  If the receiver is 
       in performance, also sends [self _afterPerformance] */
{
    if (!_noteSeen) 
	return nil;
    [self disconnectNoteReceivers];	
    MKCancelMsgRequest(_afterPerfMsgPtr);
    [self _afterPerformance];
    return self;
}

-releaseNoteReceivers
  /* TYPE: Creating; Frees the receiver's NoteReceivers.
   * Removes and frees the receiver's NoteReceivers.
   * The NoteReceiver's connections are severed (see the PerfLink class).
   * Returns the receiver. 
   */
{
    NSMutableArray *aList;

    if (_noteSeen)
      return nil;
    aList = _MKLightweightArrayCopy(noteReceivers);
    [self disconnectNoteReceivers];
    [self removeNoteReceivers];
    [aList removeAllObjects];  /* Split this up because elements may try
				  and remove themselves from noteReceivers
				  when they are freed. */
    // [aList release]; // don't release as aList is autoreleased.
    return self;
}

-removeNoteReceivers
  /* Empties noteReceivers by repeatedly sending removeNoteSender:
     with each element of the collection as the argument. */
{
    /* Need to use seq because we may be modifying the List. */
    unsigned i;
    if (!noteReceivers)
      return self;
    i = [noteReceivers count]; 
    while (i--) 
      [self removeNoteReceiver:[noteReceivers objectAtIndex:i]];
    return self;
}

-(BOOL)inPerformance
  /* TYPE: Querying; Returns YES if first Note has been seen.
   * Returns NO if the receiver has yet to receive a Note object.
   * Otherwise returns YES.
   */
{
    return (_noteSeen);
}    

-afterPerformance 
  /* TYPE: Performing; Sent after performance is finished.
   * You never invoke this method; it's automatically
   * invoked when the performance is finished.
   * A subclass can implement this method to do post-performance
   * cleanup.  The default implementation does nothing and
   * returns the receiver.
   */
{
    return self;
}

- copyWithZone:(NSZone *)zone
  /* TYPE: Creating; Creates and returns a copy of the receiver.
   * Creates and returns a new Instrument as a copy of the receiver.  
   * The new object has its own NoteReceiver collection that contains
   * copies of the receiver's NoteReceivers.  The new NoteReceivers'
   * connections (see the PerfLink class) are copied from 
   * those in the receiver.
   */
{
    MKNoteReceiver *el;
    int noteReceiverIndex;

    /* sb: the following suggested by Stone porting guide */
    MKInstrument *newObj = [MKInstrument allocWithZone:[self zone]];
    newObj->_noteSeen = NO;
    newObj->noteReceivers = [[NSMutableArray arrayWithCapacity:[noteReceivers count]] retain];
    
    for(noteReceiverIndex = 0; noteReceiverIndex < [noteReceivers count]; noteReceiverIndex++) {
      el = [noteReceivers objectAtIndex: noteReceiverIndex]; 
      [newObj addNoteReceiver:[el copy]];
    }
    return newObj;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

- (MKNoteReceiver *) noteReceiver
  /* TYPE: Querying; Returns the receiver's first NoteReceiver.
   * Returns the first NoteReceiver in the receiver's List.
   * This is particularly useful for Instruments that have only
   * one NoteReceiver.
   */
{
    if ([noteReceivers count] == 0)
        [self addNoteReceiver:[[MKNoteReceiver alloc] init]];
    return [noteReceivers objectAtIndex:0];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives noteReceiver List. */
{
    [aCoder encodeObject:noteReceivers];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    if ([aDecoder versionForClassName: @"MKInstrument"] == VERSION2) 
      noteReceivers = [[aDecoder decodeObject] retain];
    return self;
}

// Immeditately stops playing any sounding notes. The default is to do nothing.
- allNotesOff
{
    return self;
}

@end

@implementation MKInstrument(Private)

- _realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* Private */
{
    if (!_noteSeen) {
	_afterPerfMsgPtr = [MKConductor _afterPerformanceSel:
			    @selector(_afterPerformance) 
			    to:self argCount:0];
	[self firstNote:aNote];
	_noteSeen = YES;
    }
    return [self realizeNote:aNote fromNoteReceiver:aNoteReceiver];
}

-_afterPerformance
  /* Sent by conductor at end of performance. Private */
{
    [self afterPerformance];
    _noteSeen = NO;
    return self;
}

@end

