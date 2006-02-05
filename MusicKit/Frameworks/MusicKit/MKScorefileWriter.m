/*
  $Id$
  Defined In: The MusicKit

  Description:
    A score writer writes notes to a scorefile. Like any other MKInstrument,
    it maintains a list of MKNoteReceivers. Each MKNoteReceiver corresponds to
    a part to appear in the scorefile. Methods are provided for
    manipulating the set of MKNoteReceivers.

    It is illegal to remove parts during performance. 

    If a performance session is repeated, the file must be specified again
    using setFileStream: (see MKFileWriter class).

    PartNames in the score correspond to the names of the MKNoteReceivers. 
    You add the MKNoteReceivers with addNoteReceiver:. You name the
    MKNoteReceivers with the MKNameObject() C function.

    It's illegal to change the name of a data object (such as an MKEnvelope,
    MKWaveTable or MKNoteReceiver) during a performance
    involving a MKScorefileWriter. (Because an object'll get written to the
    file with the wrong name.)

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
Modification history prior to CVS commit.
  09/18/89/daj - Added casts to (id) in _getData/_setData: to accomodate new
                 void * type.
  10/25/89/daj - Added instance variable isOptimized.		 
  01/31/90/daj - Changed setOptimzedFile:, setFile:, etc. to not set 
                 isOptimized if first note has been seen. Changed isOptimized
		 to share _reservedScorefileWriter3 (to remain backward
		 compatible with 1.0 header file). Added check for 
		 inPerformance in -free.
  03/23/90/daj - Added archiving. Flushed hack described above. Added 
                 instance var.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
                 Fixed bug in read: method.
  08/23/90/daj - Changed to zone API.
*/

#import "_musickit.h"
#import "InstrumentPrivate.h"
#import "_scorefile.h"
#import "MKScorefileWriter.h"

@implementation MKScorefileWriter

#define SCOREPTR ((_MKScoreOutStruct *)_p)

#define VERSION2 2

+ (void) initialize
{
    if (self != [MKScorefileWriter class])
        return;
    [MKScorefileWriter setVersion: VERSION2]; //sb: suggested by Stone conversion guide (replaced self)
}

- init
{
    self = [super init];
    if(self != nil) {
	info = nil;
    }
    return self;
}

// Whenever we add a MKNoteReceiver, we create a MKPart and associate it with the note receiver.
- addNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    MKPart *partAssociatedWithNoteReceiver;
    id result = [super addNoteReceiver: aNoteReceiver];
    
    if(result != nil) {
	// Determine if we already have an MKPart associated with the MKNoteReceiver.
	partAssociatedWithNoteReceiver = [aNoteReceiver _getData];
	if(partAssociatedWithNoteReceiver == nil) { // create it fresh.
	    partAssociatedWithNoteReceiver = [MKPart partWithName: MKGetObjectName(aNoteReceiver)];
	    [aNoteReceiver _setData: partAssociatedWithNoteReceiver];
	}
    }
    return result;
}

- (void) encodeWithCoder: (NSCoder *) aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write:, which archives MKNoteReceivers.
     Then archives info, isOptimized, and MKPart info MKNotes.  */
{
    unsigned n = [noteReceivers count], noteReceiverIndex;

    [aCoder encodeValuesOfObjCTypes: "@ci", &info, &_isOptimized, &n];
    for (noteReceiverIndex = 0; noteReceiverIndex < n; noteReceiverIndex++)
        [aCoder encodeObject: [[[noteReceivers objectAtIndex: noteReceiverIndex] _getData] infoNote]];
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    int noteReceiverCount;
    int noteReceiverIndex;

    if ([aDecoder versionForClassName: @"MKScorefileWriter"] == VERSION2) {
	[aDecoder decodeValuesOfObjCTypes: "@ci", &info, &_isOptimized, &noteReceiverCount];
	NSArray *allNoteReceivers = [super noteReceivers];
	/* TODO Because we can't install the MKPart infos now in the MKNoteReceivers 
	   (since the MKNoteReceivers are in the super class), we have to save them temporarily
	   in an available NSArray _p and then insert them later. However at the moment there doesn't
	   seem to be a good time to determine when to do this. So this may be broken, unless the object decoding order has changed.
	 */
	for(noteReceiverIndex = 0; noteReceiverIndex < noteReceiverCount; noteReceiverIndex++) {
	    MKNote *partInfoNote = [aDecoder decodeObject];
	    MKNoteReceiver *aNoteReceiver = [allNoteReceivers objectAtIndex: noteReceiverIndex];
	    
	    // Create a MKPart
	    MKPart *partAssociatedWithNoteReceiver = [MKPart partWithName: MKGetObjectName(aNoteReceiver)];
	    [partAssociatedWithNoteReceiver setInfoNote: partInfoNote];
	    [aNoteReceiver _setData: partAssociatedWithNoteReceiver];
	}
    }
    return self;
}

+ (NSString *) fileExtension
  /* Returns "score", the default file extension for score files.
     This method is used by the MKFileWriter class. The string is not
     copied. No need to retain/autorelease since it's static anyway */
{
    return _MK_SCOREFILEEXT;
}

- (NSString *) fileExtension
  /* Returns "score", the default file extension for score files if the
     file was set with setFile: or setStream:. Returns "playscore", the
     default file extension for optimized format score files if the file
     was set with setOptimizedFile: or setOptimizedStream:. 
     The string is not copied. No need to retain/autorelease since it's static anyway */
{
    return _isOptimized ? _MK_BINARYSCOREFILEEXT : _MK_SCOREFILEEXT ;
}

- initializeFile
    /* Initializes file specified by the name of the MKFileWriter. You never
       send this message directly. */
{
    unsigned n = [noteReceivers count], noteReceiverIndex;
    
    _highTag = -1;
    _lowTag = MAXINT;
    _p = (void *) _MKInitScoreOut(stream, self, info, timeShift, YES, _isOptimized);
    /* Write declarations in header. */
    for (noteReceiverIndex = 0; noteReceiverIndex < n; noteReceiverIndex++) {
	MKPart *partForNoteReceiver = [[noteReceivers objectAtIndex: noteReceiverIndex] _getData];
        _MKWritePartDecl(partForNoteReceiver, SCOREPTR, [partForNoteReceiver infoNote]);
    }

//#error StreamConversion: NXTell should be converted to an NSData method
//    SCOREPTR->_tagRangePos = NXTell(SCOREPTR->_stream);
    SCOREPTR->_tagRangePos = [SCOREPTR->_stream length];
    [SCOREPTR->_stream appendData: [@"                                        \n" dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    /* We'll fill this in later. */
    return self;
}

/* Does not close file. You never send this message directly. */
- finishFile
{
//    long curPos;
//#error StreamConversion: NXTell should be converted to an NSData method
//    curPos = NXTell(SCOREPTR->_stream);
//#error StreamConversion: NXSeek should be converted to an NSData method
//    NXSeek(SCOREPTR->_stream,SCOREPTR->_tagRangePos,NX_FROMSTART);
    if (_lowTag < _highTag) {
        NSData *dataToAppend = [[NSString stringWithFormat: @"noteTagRange = %d to %d;\n", _lowTag,_highTag] 	dataUsingEncoding:NSNEXTSTEPStringEncoding];
        int len = [dataToAppend length];
        NSRange range = {SCOREPTR->_tagRangePos, len};/*sb: there are 40 spaces, but this replaces exact amount. */
        char *aBuffer = _MKMalloc(len);
        [dataToAppend getBytes: aBuffer]; //stick our string into a char buffer

        [SCOREPTR->_stream replaceBytesInRange: range withBytes: aBuffer];
        free(aBuffer);
    }
/*
      [SCOREPTR->_stream appendData:[[NSString stringWithFormat:@"noteTagRange = %d to %d;\n", _lowTag,_highTag] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
#error StreamConversion: NXSeek should be converted to an NSData method
    NXSeek(SCOREPTR->_stream,curPos,NX_FROMSTART);
 */
    (void) _MKFinishScoreOut(SCOREPTR, YES);
    return self;
}

- setInfoNote: (MKNote *) aNote
  /* Sets info, overwriting any previous info. aNote is copied. The info is 
     written out in the initializeFile method. The old info, if any, is freed. 
     */
{
    [info autorelease];
    info = [aNote copy];
    return self;
}

-(MKNote *) infoNote
{
    return info;
}

- setInfoNote: (MKNote *) aNote forNoteReceiver: (MKNoteReceiver *) aNR
  /* Sets Info for partName corresponding to specified NoteReceiver.
     If in performance or if aNR is not a MKNoteReceiver of the 
     receiver, generates an error and returns nil. 
     If the receiver is in performance, does nothing and returns nil. 
     aNote is copied. The old info, if any, is freed. */
{
    if (noteSeen || (![self isNoteReceiverPresent: aNR]))
	return nil;
    // TODO this will leak. We need to recheck if we need to copy the note.
    [[aNR _getData] setInfoNote: [aNote copy]];
    return self;
}

- (MKNote *) infoNoteForNoteReceiver: (MKNoteReceiver *) aNoteReceiver
{
    return [[aNoteReceiver _getData] infoNote];
} 

- copyWithZone: (NSZone *) zone 
    /* Copies object and set of parts. The copy has a copy of 
       the noteReceivers and info notes. */
{
    unsigned int noteReceiverIndex;
    unsigned n = [noteReceivers count];
    MKScorefileWriter *newObj =  [super copyWithZone:zone];
    newObj->_highTag = -1;
    newObj->_lowTag = MAXINT;
    newObj->_p = NULL;
    newObj->info = [info copy];

    for (noteReceiverIndex = 0; noteReceiverIndex < n; noteReceiverIndex++) {
        MKPart *part = [[newObj->noteReceivers objectAtIndex: noteReceiverIndex] _getData];
	
	[part setInfoNote: [[part infoNote] copy]];
    }
    
    return newObj;
}

/* Frees receiver, MKNoteReceivers and info notes. */ 
- (void) dealloc
{    
    if (info != nil) {
	[info release];
	info = nil;
    }    
    [super dealloc];
}

- realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* Realizes note by writing it to the file, assigned to the part 
     corresponding to aNoteReceiver. */
{
    int noteTag = [aNote noteTag];
    
    if (noteTag != MAXINT) {
	_highTag = MAX(noteTag, _highTag);
	_lowTag = MIN(noteTag, _lowTag);
    }
    _MKWriteNote(aNote, [aNoteReceiver _getData], SCOREPTR);
    return self;
}

- setOptimizedStream: (NSMutableData *) aStream
  /* Same as setStream: but specifies that the data be written in optimized 
     scorefile format. */
{
    id rtn = [super setStream: aStream];
    _isOptimized = YES;
    return rtn;
}

- setOptimizedFile: (NSString *) aName
  /* Same as setFile: but specifies that the file be in optimized format. */
{
    id rtn;
    rtn = [super setFile: aName];
    _isOptimized = YES;
    return rtn;
}

- setFile: (NSString *) aName
  /* See superclass documentation */
{
    id rtn;
    rtn = [super setFile: aName];
    _isOptimized = NO;
    return rtn;
}

- setStream: (NSMutableData *) aStream
  /* See superclass documentation */
{
    id rtn;
    rtn = [super setStream: aStream];
    _isOptimized = NO;
    return rtn;
}

@end

