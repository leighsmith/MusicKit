/*
  $Id$  
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A simple class which records MKNotes to a MKPart. That is, it acts as
    an MKInstrument that realizes MKNotes by adding them to its MKPart.
 
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/* Modification History:

   $Log$
   Revision 1.9  2004/10/25 16:22:50  leighsmith
   Updated for new ivar name

   Revision 1.8  2001/09/06 21:27:47  leighsmith
   Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

   Revision 1.7  2001/08/07 16:16:11  leighsmith
   Corrected class name during decode to match latest MK prefixed name

   Revision 1.6  2001/01/31 21:32:56  leigh
   Typed note parameters

   Revision 1.5  2000/11/25 21:53:29  leigh
   copyright added and source formatting

   Revision 1.4  2000/04/16 04:11:37  leigh
   comment cleanup

   Revision 1.3  2000/03/29 02:57:05  leigh
   Cleaned up doco and ivar declarations

   Revision 1.2  1999/07/29 01:16:39  leigh
   Added Win32 compatibility, CVS logs, SBs changes

   03/13/90/daj - Minor changes for new private category scheme.
   04/21/90/daj - Small mods to get rid of -W compiler warnings.
   08/27/90/daj - Changed to zone API.

*/

#import "_musickit.h"
#import "_noteRecorder.h"
#import "ConductorPrivate.h"
#import "InstrumentPrivate.h"
#import "PartPrivate.h"
#import "ScoreRecorderPrivate.h"

#import "MKPartRecorder.h"

@implementation MKPartRecorder

#import "noteRecorderMethods.m"

#define VERSION2 2
#define VERSION3 3 /* Changed Nov 7, 1992 */

+ (void)initialize
{
    if (self != [MKPartRecorder class])
      return;
    [MKPartRecorder setVersion:VERSION3];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: then archives timeUnit. 
     Optionally archives part using NXWriteObjectReference().
     */
{
    [super encodeWithCoder:aCoder];
    NSAssert((sizeof(MKTimeUnit) == sizeof(int)), @"write: method error.");
    [aCoder encodeValueOfObjCType:"i" at:&timeUnit];
    [aCoder encodeConditionalObject:part];
    [aCoder encodeConditionalObject:_scoreRecorder];
    [aCoder encodeValuesOfObjCTypes:"c",&compensatesDeltaT];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    int version;
    [super initWithCoder:aDecoder];
    version = [aDecoder versionForClassName: @"MKPartRecorder"];
    if (version >= VERSION2) {
	[aDecoder decodeValueOfObjCType:"i" at:&timeUnit];
	part = [[aDecoder decodeObject] retain];
	_scoreRecorder = [[aDecoder decodeObject] retain];
    }
    if (version >= VERSION3) {
	[aDecoder decodeValuesOfObjCTypes:"c",&compensatesDeltaT];
    }
    /* from awake (sb) */
    noteReceiver = [self noteReceiver];
    
    return self;
}

//- awake
  /* Initializes noteSender instance variable. */
//{
//#warning DONE ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
//    [super awake];
/*
    noteReceiver = [self noteReceiver];
 */
//    return self;
//}

- copyWithZone:(NSZone *)zone
{
    MKPartRecorder *newObj = [super copyWithZone:zone];
    newObj->noteReceiver = [newObj noteReceiver];
    return newObj;
}

- (void)dealloc
  /* If receiver is a member of a MKScoreRecorder or is in performance, 
     returns self and does nothing. Otherwise frees the receiver. */
{
    /*sb: FIXME!!! This is not the right place to decide whether or not to dealloc.
     * maybe need to put self in a global list of non-dealloced objects for later cleanup */
    if ([self inPerformance] || _scoreRecorder) 
      return;
    [noteReceiver release];/* sb */
    [super dealloc];
}

-init
  /* TYPE: Creating
   * This message is sent to when a new instance is created.
   * The default implementation returns the receiver and creates a single
   * NoteReceiver.
   * A subclass
   * implementation should first send [super init].
   */
{
    [super init];
    [self addNoteReceiver:noteReceiver = [MKNoteReceiver new]];
    timeUnit = MK_second;
    return self;
}

#if 0
-setArchivePart:(BOOL)yesOrNo
 /* Archive part when the receiver or any object pointing to the receiver
    is archived. */  
{
    archivePart = yesOrNo;
}

-(BOOL)archivePart
 /* Dont archive part when the receiver or any object pointing to the 
    receiver is archived. */  
{
    return archivePart;
}
#endif

void _MKSetScoreRecorderOfPartRecorder(aPR,aSR)
    MKPartRecorder *aPR;
    id aSR;
{
    aPR->_scoreRecorder = aSR;
}

-setPart: aPart
  /* Sets MKPart to which notes are sent. */
{
    part = aPart;
    return self;
}

-part
{
    return part;
}

- _realizeNote: (MKNote *) aNote fromNoteReceiver: (MKNoteReceiver *) aNoteReceiver
  /* Private */
{
    if (!noteSeen) {
	[MKConductor _afterPerformanceSel: @selector(_afterPerformance) to: self argCount: 0];
	[_scoreRecorder _firstNote: aNote];
	[part _addPerformanceObj: self];
	[self firstNote: aNote];
	noteSeen = YES;
    }
    return [self realizeNote: aNote fromNoteReceiver: aNoteReceiver];
}

-_afterPerformance
  /* Sent by conductor at end of performance. Private */
{
    [part _removePerformanceObj:self];
    [self afterPerformance];
    noteSeen = NO;
    return self;
}

-realizeNote:aNote fromNoteReceiver:aNoteReceiver
  /* Copies the note, adjusting its timetag and possibly adjusting its 
     duration according to tempo, then sends addNote: to the MKPart. */
{
    aNote = [aNote copyWithZone: NSDefaultMallocZone()];
    [aNote setTimeTag: _MKTimeTagForTimeUnit(aNote, timeUnit, compensatesDeltaT)];
    if ([aNote noteType] == MK_noteDur) 
        [aNote setDur: _MKDurForTimeUnit(aNote, timeUnit)];
    [part addNote: aNote];
    return self;
}

@end

