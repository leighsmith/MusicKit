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
Modification history:

  $Log$
  Revision 1.5  2001/08/07 16:12:30  leighsmith
  Corrected class name during decode to match latest MK prefixed name

  Revision 1.4  2000/11/29 00:38:13  leigh
  Comment cleanup, now using _MKMalloc instead of malloc (better error checking)

  Revision 1.3  1999/09/04 22:44:23  leigh
  setInfo now setInfoNote

  Revision 1.2  1999/07/29 01:16:43  leigh
  Added Win32 compatibility, CVS logs, SBs changes

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
#define PARTINFO(_aNR) ((id)[_aNR _getData])

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKScorefileWriter class])
        return;
    [MKScorefileWriter setVersion: VERSION2]; //sb: suggested by Stone conversion guide (replaced self)
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write:, which archives NoteReceivers.
     Then archives info, isOptimized, and Part info Notes.  */
{
    unsigned n = [noteReceivers count], i;

    [aCoder encodeValuesOfObjCTypes: "@ci", &info, &_isOptimized, &n];
    for (i = 0; i < n; i++)
        [aCoder encodeObject: PARTINFO([noteReceivers objectAtIndex:i])];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    id *el;
    int noteReceiverCount;

    if ([aDecoder versionForClassName: @"MKScorefileWriter"] == VERSION2) {
	[aDecoder decodeValuesOfObjCTypes:"@ci",&info,&_isOptimized,&noteReceiverCount];
	/* Because we can't install the Part infos now in the NoteReceivers,
	   we have to use them temporarily in an available pointer, _p. 
	   See awake below. */
	_MK_MALLOC(el,id,noteReceiverCount);
	_p = el;
	while (noteReceiverCount--) 
	  *el++ = [[aDecoder decodeObject] retain];
    }
    /* from awake (sb) */
    {
        unsigned n;
//        id *el1,
        unsigned int el1;
        id *el2;

        for (el1 = 0 /*NX_ADDRESS(noteReceivers)*/,
         el2 = (id *)_p, n = [noteReceivers count];
         n--;)
             [[noteReceivers objectAtIndex:el1++] _setData:*el2++]; /* *el1++ */
    free(_p);
    _p = NULL;
    }
/****/
    return self;
}

+ (NSString *) fileExtension
  /* Returns "score", the default file extension for score files.
     This method is used by the FileWriter class. The string is not
     copied. */
{
    return [[_MK_SCOREFILEEXT retain] autorelease];
}

- (NSString *) fileExtension
  /* Returns "score", the default file extension for score files if the
     file was set with setFile: or setStream:. Returns "playscore", the
     default file extension for optimized format score files if the file
     was set with setOptimizedFile: or setOptimizedStream:. 
     The string is not copied. */
{
    return [[(_isOptimized ? _MK_BINARYSCOREFILEEXT : _MK_SCOREFILEEXT) retain] autorelease];
}

-initializeFile
    /* Initializes file specified by the name of the FileWriter. You never
       send this message directly. */
{
    id el;
    unsigned n = [noteReceivers count], i;
    _highTag = -1;
    _lowTag = MAXINT;
    _p = (void *)_MKInitScoreOut(stream,self,info,timeShift,YES,_isOptimized);
    /* Write declarations in header. */
    for (i = 0; i < n; i++) {
        el = [noteReceivers objectAtIndex:i];
        _MKWritePartDecl(el,SCOREPTR,PARTINFO(el));
    }

//#error StreamConversion: NXTell should be converted to an NSData method
//    SCOREPTR->_tagRangePos = NXTell(SCOREPTR->_stream);
    SCOREPTR->_tagRangePos = [SCOREPTR->_stream length];
    [SCOREPTR->_stream appendData: [@"                                        \n" dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    /* We'll fill this in later. */
    return self;
}

-finishFile
    /* Does not close file. You never send this message directly. */
{
//    long curPos;
//#error StreamConversion: NXTell should be converted to an NSData method
//    curPos = NXTell(SCOREPTR->_stream);
//#error StreamConversion: NXSeek should be converted to an NSData method
//    NXSeek(SCOREPTR->_stream,SCOREPTR->_tagRangePos,NX_FROMSTART);
    if (_lowTag < _highTag) {
        NSData *dataToAppend = [[NSString stringWithFormat:@"noteTagRange = %d to %d;\n", _lowTag,_highTag] 	dataUsingEncoding:NSNEXTSTEPStringEncoding];
        int len = [dataToAppend length];
        NSRange range = {SCOREPTR->_tagRangePos, len};/*sb: there are 40 spaces, but this replaces exact amount. */
        char *aBuffer = _MKMalloc(len);
        [dataToAppend getBytes:aBuffer]; //stick our string into a char buffer

        [SCOREPTR->_stream replaceBytesInRange:range withBytes:aBuffer];
        free(aBuffer);
    }
/*
      [SCOREPTR->_stream appendData:[[NSString stringWithFormat:@"noteTagRange = %d to %d;\n", _lowTag,_highTag] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
#error StreamConversion: NXSeek should be converted to an NSData method
    NXSeek(SCOREPTR->_stream,curPos,NX_FROMSTART);
 */
    (void)_MKFinishScoreOut(SCOREPTR,YES);
    return self;
}

-setInfoNote:(MKNote *) aNote
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

-setInfoNote:(MKNote *) aNote forNoteReceiver: (MKNoteReceiver *) aNR
  /* Sets Info for partName corresponding to specified NoteReceiver.
     If in performance or if aNR is not a NoteReceiver of the 
     receiver, generates an error and returns nil. 
     If the receiver is in performance, does nothing and returns nil. 
     aNote is copied. The old info, if any, is freed. */
{
    if (_noteSeen || (![self isNoteReceiverPresent:aNR]))
      return nil;
    [PARTINFO(aNR) release]; 
    [aNR _setData:(void *)[aNote copy]];
    return self;
}

- infoNoteForNoteReceiver:aNoteReceiver
{
    return PARTINFO(aNoteReceiver);
} 

- copyWithZone:(NSZone *)zone 
    /* Copies object and set of parts. The copy has a copy of 
       the noteReceivers and info notes. */
{
//    id el1,el2;
    int i;
    unsigned n = [noteReceivers count];
    MKScorefileWriter *newObj =  [super copyWithZone:zone];
    newObj->_highTag = -1;
    newObj->_lowTag = MAXINT;
    newObj->_p = NULL;
    newObj->info = [info copy];

    for (i=0;i<n;i++)
        [[newObj->noteReceivers objectAtIndex:i] _setData:[PARTINFO([noteReceivers objectAtIndex:i]) copy]];
    
/*    for (el1 = NX_ADDRESS(noteReceivers), el2 = NX_ADDRESS(newObj->noteReceivers), n = [noteReceivers count];
         n--;);
    [*el2++ _setData:[PARTINFO(*el1++) copy]]; *//* Copy part info notes. */ 
    return newObj;
}

- (void)dealloc
  /* Frees receiver, NoteReceivers and info notes. */ 
{
    /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
     * maybe need to put self in a global list of non-dealloced objects for later cleanup */
    unsigned n, i;
    if ([self inPerformance])
      return;
    [info release];
    n = [noteReceivers count];
    for (i = 0; i < n; i++)
        [PARTINFO([noteReceivers objectAtIndex: i]) release]; /* Free part info notes. */
    [super dealloc];
}

-realizeNote:aNote fromNoteReceiver:aNoteReceiver
  /* Realizes note by writing it to the file, assigned to the part 
     corresponding to aNoteReceiver. */
{
    int noteTag = [aNote noteTag];
    if (noteTag != MAXINT) {
	_highTag = MAX(noteTag,_highTag);
	_lowTag = MIN(noteTag,_lowTag);
    }
    _MKWriteNote(aNote,aNoteReceiver,SCOREPTR);
    return self;
}

-setOptimizedStream:(NSMutableData *)aStream
  /* Same as setStream: but specifies that the data be written in optimized 
     scorefile format. */
{
    id rtn;
    rtn = [super setStream:aStream];
    _isOptimized = YES;
    return rtn;
}

-setOptimizedFile:(NSString *)aName
  /* Same as setFile: but specifies that the file be in optimized format. */
{
    id rtn;
    rtn = [super setFile:aName];
    _isOptimized = YES;
    return rtn;
}

-setFile:(NSString *)aName
  /* See superclass documentation */
{
    id rtn;
    rtn = [super setFile:aName];
    _isOptimized = NO;
    return rtn;
}

-setStream:(NSMutableData *)aStream
  /* See superclass documentation */
{
    id rtn;
    rtn = [super setStream:aStream];
    _isOptimized = NO;
    return rtn;
}

@end

