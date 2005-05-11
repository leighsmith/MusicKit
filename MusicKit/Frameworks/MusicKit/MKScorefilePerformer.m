/*
  $Id$
  Defined In: The MusicKit

  Description: 
    MKScorefilePerformers are used to access and perform scorefiles.
    Instances of this class are used directly in an application;
    you don't have to design your own subclass.
   
    A MKScorefilePerformer creates
    a separate MKNoteSender object for each part name in the file
    (as given in the file's part statements).  The MKNoteSender objects
    are maintained as an NSArray in the inherited variable noteSenders.
    The MKNoteSenders are named with the names of the MKParts in the file.
    Thus, you can find out the names of the MKParts in the file by getting
    an NSArray of the noteSenders (using -noteSenders) and using the function
    MKGetObjectName(noteSender).
   
    Much of MKScorefilePeformer's functionality is
    documented under MKFilePerformer, and MKPerformer.

  Original Author: David A. Jaffe
 
  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.13  2005/05/11 02:13:30  leighsmith
  Cleaned up parameter types and doxygen docs

  Revision 1.12  2004/12/13 02:25:44  leighsmith
  New typing for MKNoteReceiver _setData: and _getData

  Revision 1.11  2004/08/21 23:20:56  leighsmith
  Better typing of results

  Revision 1.10  2002/04/15 14:23:50  sbrandon
  - fixed a couple of internal comments that wrongly referred to List objects
    (now NSArray)

  Revision 1.9  2002/04/03 03:59:41  skotmcdonald
  Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

  Revision 1.8  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.7  2001/08/07 16:16:11  leighsmith
  Corrected class name during decode to match latest MK prefixed name

  Revision 1.6  2000/11/28 19:05:00  leigh
  Replaced fileExtensions with whatever MKScore deems valid

  Revision 1.5  2000/04/22 20:11:09  leigh
  Changed fileExtensions to less error-prone NSArray of NSStrings

  Revision 1.4  2000/04/13 21:50:15  leigh
  Fixed uninitialised readPosition index

  Revision 1.3  1999/09/04 22:43:23  leigh
  documentation cleanup

  Revision 1.2  1999/07/29 01:16:42  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/18/89/daj - Added casts to (id) in _getData/_setData: to accomodate new
                 void * type.
  10/26/89/daj - Added +fileExtensions method for binary scorefile
                 support.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
*/

#import "_musickit.h"
#import "_scorefile.h"
#import "InstrumentPrivate.h"
#import "PartPrivate.h"

#import "ScorefilePerformerPrivate.h"
@implementation MKScorefilePerformer

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKScorefilePerformer class])
        return;
    [MKScorefilePerformer setVersion:VERSION2]; //sb: suggested by Stone conversion guide (replaced self)
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write:, which archives MKNoteSenders.
     Then archives info and part infos gleaned from the Scorefile. */
{
    [aCoder encodeValuesOfObjCTypes: "@@", &info, &_partStubs];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* TYPE: Archiving; Reads object.
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    if ([aDecoder versionForClassName: @"MKScorefilePerformer"] == VERSION2) 
        [aDecoder decodeValuesOfObjCTypes: "@@", &info, &_partStubs];
    return self;
}

-init
  /* TYPE: Initializing
   * Sent by the superclass upoon creation.
   * You never invoke this method directly.
   */
{
  self = [super init];
  if (self != nil) {
    _partStubs = [NSMutableArray new];
  }
  return self;
}

+(NSString *)fileExtension
  /* Returns "score", the default file extension for score files.
     This method is used by the MKFilePerformer class. The string is not
     copied. */
{
    return [[_MK_SCOREFILEEXT retain] autorelease];
}

+(NSArray *)fileExtensions
  /* Returns a NSArray of the default file extensions 
     recognized by MKScorefilePerformer instances. This array typically consists of
     "score" and "playscore".
     This method is used by the MKFilePerformer class. */
{
    return [MKScore scorefileExtensions];
}

- (MKNote *) infoNote
{
    return info;
}

#define SCOREPTR ((_MKScoreInStruct *)_p)

-initializeFile
  /* TYPE: Accessing f
   * Initializes the information obtained from the scorefile header.
   * Notice that the parts representing the scorefile do not appear
   * in the MKScorefilePerformer until activation.
   * Returns the receiver, or nil if the file can't be read, there
   * are too many parse errors, or there is no body. 
   * You never send the initializeFile message 
   * directly to a MKScorefilePerformer; it's invoked by the
   * selfActivate method.
   */
{
    unsigned int readPosition = 0; // initialises a file pointer. Should only be at top level, when new file parsed...

    _p = (void *) _MKNewScoreInStruct(stream, self, scorefilePrintStream, YES, filename, &readPosition);
    if (!_p)
      return nil;
    _MKParseScoreHeader(SCOREPTR);
    if (SCOREPTR->timeTag > (MK_ENDOFTIME-1)) {
	[self deactivate];
	return nil;
    }
    return self;
}

-finishFile
  /* TYPE: Accessing f
   * Performs file finalization and returns the receiver.
   * You never send the finishFile message 
   * directly to a MKScorefilePerformer; it's invoked by the
   * deactivate method.
   */
{
    _p = (void *)_MKFinishScoreIn(SCOREPTR);
    return self;
}

-setScorefilePrintStream:(NSMutableData *)aStream
  /* Sets the stream to be used for Scorefile 'print' statement output. */
{
    scorefilePrintStream = aStream;
    return self;
}

-(NSMutableData *)scorefilePrintStream
  /* Returns the stream used for Scorefile 'print' statement output. */
{
    return scorefilePrintStream;
}

- (MKNote *) nextNote
  /* TYPE: Accessing N
   * Grabs the next entry in the body of the scorefile.
   * If the entry is a note statement, this fashions a MKNote
   * object and returns it.  If it's a time statement, updates
   * the fileTime variable
   * and returns nil.
   *
   * You never send nextNote directly to a 
   * MKScorefilePerformer; it's invoked by the perform method.
   * You may override this method, e.g. to modify the note before it is 
   * performed but you must send [super nextNote].
   */
{
    MKNote *aNote = _MKParseScoreNote(SCOREPTR);
    fileTime = SCOREPTR->timeTag;
    return aNote;
}

- (MKNote *) infoNoteForNoteSender: (MKNoteSender *) aNoteSender
  /* If aNoteSender is a member of the receiver, returns the info MKNote
     corresponding to the partName represented by that MKNoteSender. Otherwise, 
     returns nil. */
{
    id owner = [aNoteSender owner];
    return (owner == self) ? [((id)[aNoteSender _getData]) infoNote] : nil;
}

/* Returns the first MKNoteSender whose corresponding MKPart has 
 a MK_midiChan info parameter equal to
 aChan, if any. aChan equal to 0 corresponds to the MKPart representing
 MIDI system and channel mode messages. */
- (MKNoteSender *) midiNoteSender: (int) aChan
{
    MKNoteSender *noteSender;
    MKNote *aInfo;
    unsigned n,i;
    
    if (aChan == MAXINT)
      return nil;
    n = [noteSenders count];
    for (i = 0; i < n; i++) {
        noteSender = [noteSenders objectAtIndex: i];
        if ((aInfo = [((MKPart *) [noteSender _getData]) infoNote]))
            if ([aInfo parAsInt: MK_midiChan] == aChan)
                return [[noteSender retain] autorelease];
    }
    return nil;
}

- performNote: (MKNote *) aNote
  /* TYPE: Accessing N
   * Sends aNote to the appropriate MKNoteSender
   * You never send performNote: directly to a MKScorefilePerformer;
   * it's invoked by the perform method.
   */
{
    [[SCOREPTR->part _noteSender] sendNote: aNote];    
    return self;
}

- (void) dealloc
  /* Frees receiver and its MKNoteSenders.  Also frees the info.
     If the receiver is active, does nothing and returns self. Otherwise,
     returns nil. */
{
    if (status != MK_inactive) {
	NSLog(@"MKScorefilePerformer -dealloc: Assertion failure status not inactive\n");
    }
    if (_partStubs != nil) {
	[_partStubs removeAllObjects];
	[_partStubs release];
	_partStubs = nil;
    }
    if (info != nil) {
	[info release];
	info = nil;
    }
    [super dealloc];
}

- copyWithZone: (NSZone *) zone
  /* Copies self and info. */
{
    MKScorefilePerformer *newObj = [super copyWithZone:zone];
    newObj->info = [info copy];
    return newObj;
}


@end


@implementation MKScorefilePerformer(Private)

-_newFilePartWithName:(NSString *)name
  /* You never send this message. It is used only by the Scorefile parser
     to add a MKNoteSender to the receiver when a part is declared in the
     scorefile. 
     It is a method rather than a C function to hide from the parser
     the differences between MKScore and MKScorefilePerformer.
     */
{
    MKNoteSender *aNoteSender = [MKNoteSender new];
    MKPart *aPart = [MKPart new];
    
    [self addNoteSender: aNoteSender];
    MKNameObject(name, aNoteSender);  // enable retrieving the noteSender by name.
    [aNoteSender _setData: aPart];  /* Back ptr */
    [aPart _setNoteSender: aNoteSender];/* Forward ptr for performNote */
    [_partStubs addObject: aPart];
    [aNoteSender release];/*sb*/
    [aPart release];
    return aPart;/*sb: retain is held in _partStubs */
}

-_elements
  /* Same as noteSenders. (Needed by Scorefile parser.) 
   It is a method rather than a C function to hide from the parser
   the differences between MKScore and MKScorefilePerformer. */
{
//    return [self noteSenders];
    return _MKLightweightArrayCopy(_partStubs); 
}

-_setInfo:aInfo
  /* Needed by scorefile parser  */
{
    if (!info)
      info = [aInfo copy];
    else [info copyParsFrom:aInfo];
    return self;
}

@end

