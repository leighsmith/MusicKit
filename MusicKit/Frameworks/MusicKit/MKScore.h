/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKScore is a collection of MKPart objects.  MKScores can be read from and
    written to a scorefile or midifile, performed with a MKScorePerformer,
    and an be used to record MKNotes from a MKScoreRecorder.

    Each MKScore has an info MKNote (a mute) that defines, in its parameters,
    information that can be useful in performing or otherwise interpreting
    the MKScore.  Typical information includes tempo, DSP headroom (see the
    MKOrchestra class), and sampling rate (the parameters MK_tempo,
    MK_headroom, and MK_samplingRate are provided to accommodate this
    utility).

    When you read a scorefile into a MKScore, a MKPart object is created and
    added to the MKScore for each MKPart name in the file's part statement.
    If the MKScore already contains a MKPart with the same name as a MKPart in
    the file, the MKNotes from the two sources are merged together in the
    existing MKPart in the MKScore.

    MKScoreFile print statements are printed as the scorefile is read into a
    MKScore. You can set the stream on which the messages are printed by
    invoking setScorefilePrintStream:.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
*/
/*
  $Log$
  Revision 1.9  2000/05/26 21:03:19  leigh
  Added combineNotes to do the combination over all MKParts

  Revision 1.8  2000/04/26 01:20:43  leigh
  Corrected readScorefileStream to take a NSData instead of NSMutableData instance

  Revision 1.7  2000/04/25 02:08:40  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.6  2000/03/29 03:17:47  leigh
  Cleaned up doco and ivar declarations

  Revision 1.5  2000/03/07 18:19:57  leigh
  Fixed misleading doco

  Revision 1.4  2000/02/08 04:15:18  leigh
  Added +midifileExtension

  Revision 1.3  1999/09/04 22:02:18  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.2  1999/07/29 01:25:49  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Score_H___
#define __MK_Score_H___

#import <Foundation/NSObject.h>

@interface MKScore : NSObject
{
    NSMutableArray *parts;                  /* The object's collection of Parts. */
    NSMutableData *scorefilePrintStream;    /* The stream used by scorefile print statements. */
    MKNote *info;                           /* The object's info Note. */
}
 
- init;
 /* 
  Inits the receiver.  You never invoke this method directly.  A subclass
 implementation should send [super init] before performing its own
 initialization.  The return value is ignored.  
 */

- (void)dealloc;
 /* 
 Frees the receiver and its contents.
 */

- releaseNotes; 
 /* 
 Removes and frees the MKNotes contained in the receiver's MKParts.
 Also frees the receiver's info MKNote.  Returns the receiver.
 */

- releaseParts; 
 /* 
 Removes and frees the receiver's MKParts and the MKNotes contained therein.
 Doesn't free the receiver's info MKNote.  MKParts that are currently
 being performed by a MKPartPerformer aren't freed.
 Returns the receiver.
 */

- releasePartsOnly; 
 /* 
 Removes and frees the receiver's Parts but doesn't free the Notes contained
 therein.  Parts that are currently being performed by a PartPerformer aren't
 freed.  Returns the receiver.  
 */

- releaseSelfOnly; 
 /* 
 Frees the receiver but not its Parts nor their Notes.  The info Note isn't
 freed.  Returns the receiver.  
 */

- (void)removeAllObjects; 
 /* 
 Removes the receiver's Parts but doesn't free them.
 Returns the receiver.
  */

- readScorefile:(NSString * )fileName; 
 /* 
 Opens the scorefile named fileName and merges its contents
 with the receiver.  The file is automatically closed.
 Returns the receiver or nil if the file couldn't be read.
 */

- readScorefileStream:(NSData *)stream; 
 /* 
 Reads the scorefile pointed to by stream into the receiver.
 The file must be open for reading; the sender is responsible
 for closing the file.
 Returns the receiver or nil if the file couldn't be read.
 */

- readScorefile:(NSString * )fileName firstTimeTag:(double )firstTimeTag lastTimeTag:(double )lastTimeTag timeShift:(double)timeShift; 
 /*
 The same as readScorefile:, but only those Notes with timeTags
 in the specified range are added to the receiver.  The
 added Notes' timeTags are shifted by timeShift beats.
 Returns the receiver or nil if the file couldn't be read.
 */

- readScorefileStream:(NSData *)stream firstTimeTag:(double )firstTimeTag lastTimeTag:(double )lastTimeTag timeShift:(double)timeShift; 
 /* 
 The same as readScorefileStream:, but only those Notes with timeTags
 in the specified range are added to the receiver.  The
 added Notes' timeTags are shifted by timeShift beats.
 Returns the receiver or nil if the file couldn't be read.
 */

- writeScorefile:(NSString * )aFileName; 
 /* 
 Opens the scorefile named fileName and writes the receiver
 to it (the file is overwritten).  The file is automatically closed.
 Returns the receiver or nil if the file couldn't be written.
 */

- writeScorefileStream:(NSMutableData *)aStream; 
 /* 
 Writes the receiver into the scorefile pointed to by stream.
 The file must be open for reading; the sender is responsible for
 closing the file.  Returns the receiver or nil if the file couldn't be
 written.  
 */

- writeScorefile:(NSString * )aFileName firstTimeTag:(double )firstTimeTag lastTimeTag:(double )lastTimeTag timeShift:(double)timeShift; 
 /* 
 The same as writeScorefile:, but only those Notes with timeTags
 in the specified range are written to the file.  The
 written Notes' timeTags are shifted by timeShift beats.
 Returns the receiver or nil if the file couldn't be written.
 */

- writeScorefileStream:(NSMutableData *)aStream firstTimeTag:(double )firstTimeTag lastTimeTag:(double )lastTimeTag timeShift:(double)timeShift; 
 /* 
 The same as writeScorefileStream:, but only those Notes with timeTags
 in the specified range are written to the file.  The
 written Notes' timeTags are shifted by timeShift beats.
 Returns the receiver or nil if the file couldn't be written.
 */

-writeOptimizedScorefile:(NSString *)aFileName;
-writeOptimizedScorefileStream:(NSMutableData *)aStream;
-writeOptimizedScorefile:(NSString *)aFileName firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift;
- writeOptimizedScorefileStream:(NSMutableData *)aStream 
 firstTimeTag:(double )firstTimeTag 
 lastTimeTag:(double )lastTimeTag 
 timeShift:(double)timeShift; 
 /* 
 These are the same as the analagous writeScorefile methods, except that they
 write the Scorefile in optimized format.
 */

- readMidifile:(NSString *)aFileName firstTimeTag:(double) firstTimeTag
    lastTimeTag:(double) lastTimeTag timeShift:(double) timeShift;
- readMidifileStream:(NSMutableData *) aStream firstTimeTag:(double) firstTimeTag
    lastTimeTag:(double) lastTimeTag timeShift:(double) timeShift;
-readMidifile:(NSString *)fileName;
-readMidifileStream:(NSMutableData *)aStream;
 /* Reads a Standard Midifile as described in the NeXT Reference Manual. */

-writeMidifile:(NSString *)aFileName firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift;
-writeMidifileStream:(NSMutableData *)aStream firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift;
-writeMidifileStream:(NSMutableData *)aStream ;
-writeMidifile:(NSString *)aFileName;
 /* Writes a Standard Midifile as described in the NeXT Reference Manual. */

-(unsigned ) noteCount; 
 /* 
   Returns the number of Notes in all the receiver's Parts.
   */

-replacePart:(id)oldPart with:(id)newPart;
  /* Removes oldPart from self and replaces it with newPart.
   * Returns newPart.
   * If oldPart is not a member of this score, returns nil
   * and doesn't add newPart.  If newPart is nil, or if
   * newPart is already a member of this score, or 
   * if newPart is not a kind of Part, returns nil.
   */

- addPart:aPart; 
 /* 
   Adds aPart to the receiver.  The Part is first removed from the Score
   that it's presently a member of, if any.  Returns aPart, or nil
   if it's already a member of the receiver.  
   */

- removePart:aPart; 
 /* 
   Removes aPart from the receiver.  Returns aPart 
   or nil if it wasn't a member of the receiver.
   */

- shiftTime:(double )shift; 
 /* 
   Shifts the timeTags of all receiver's Notes by shift beats.
   Returns the receiver.
   */

-(BOOL ) isPartPresent:aPart; 
 /* 
   Returns YES if aPart has been added to the receiver,
   otherwise returns NO.
   */

- midiPart:(int )aChan; 
  /* 
     Returns the first Part with a MK_midiChan info parameter equal to
     aChan, if any. aChan equal to 0 corresponds to the Part representing
     MIDI system and channel mode messages. */

-(unsigned )partCount;
 /* 
   Returns the number of Part contained in the receiver.
   */

- parts;
 /* 
   Creates and returns a List containing the 
   receiver's Parts.  The Parts themselves
   aren't copied. It is the sender's repsonsibility to free the List. 
   */

- combineNotes;
    /* combine notes into noteDurs for all MKParts */

- copyWithZone:(NSZone *)zone; 
 /* 
   Creates and returns a new Score as a copy of the receiver.
   The receiver's Part, Notes, and info Note are all copied.
   */

- copy;
 /* Returns [self copyFromZone:[self zone]] */

-setInfoNote:(MKNote *) aNote;
 /* 
   Sets the receiver's info Note to a copy of aNote.  The receiver's
   previous info Note is removed and freed.
   */

-(MKNote *) infoNote;
 /* 
   Returns the receiver's info Note.
   */

-setScorefilePrintStream:(NSMutableData *)aStream;
 /* 
   Sets the stream used by ScoreFile print statements to
   aStream.  Returns the receiver.
   */  

-(NSMutableData *)scorefilePrintStream;
 /* 
   Returns the receiver's ScoreFile print statement stream.
   */

- (void)encodeWithCoder:(NSCoder *)aCoder;
 /* 
   You never send this message directly.  
   Should be invoked with NXWriteRootObject(). 
   Archives Notes and info. Also archives Score using 
   NXWriteObjectReference(). */
- (id)initWithCoder:(NSCoder *)aDecoder;
 /* 
   You never send this message directly.  
   Should be invoked via NXReadObject(). 
   Note that -init is not sent to newly unarchived objects.
   See write:. */
//- awake;
 /* 
   Maps noteTags as represented in the archive file onto a set that is
   unused in the current application. This insures that the integrity
   of the noteTag is maintained. The noteTags of all Parts in the Score are 
   considered part of a single noteTag space. */ 

+setMidifilesEvaluateTempo:(BOOL)yesOrNo;
 /* By default, when writing to a MIDIfile, tempo is factored into the timestamps. 
  * Disable this factoring, send [Score setMidifilesEvaluateTempo:NO] 
  */

+(BOOL)midifilesEvaluateTempo;
  /* Returns value set with setMidifilesEvaluateTempo: */

+ (NSString *) midifileExtension;
  /* returns the extension used in writing and reading MIDI files */  

+ score;
  /* manufactures an allocated, initialised and autoreleased instance */

- writeScorefile:(NSString * )aFileName 
 firstTimeTag:(double )firstTimeTag 
 lastTimeTag:(double )lastTimeTag;
- writeScorefileStream:(NSMutableData *)aStream 
 firstTimeTag:(double )firstTimeTag 
 lastTimeTag:(double )lastTimeTag;
- readScorefile:(NSString * )fileName 
 firstTimeTag:(double )firstTimeTag 
 lastTimeTag:(double )lastTimeTag;
- readScorefileStream:(NSMutableData *)stream 
 firstTimeTag:(double )firstTimeTag 
 lastTimeTag:(double )lastTimeTag;
-writeOptimizedScorefile:(NSString *)aFileName 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag;
- readMidifile:(NSString *)aFileName 
 firstTimeTag:(double) firstTimeTag
 lastTimeTag:(double) lastTimeTag;
- readMidifileStream:(NSMutableData *) aStream 
 firstTimeTag:(double) firstTimeTag
 lastTimeTag:(double) lastTimeTag;
-writeMidifile:(NSString *)aFileName 
 firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag;
-writeMidifileStream:(NSMutableData *)aStream 
 firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag;
- writeOptimizedScorefileStream:(NSMutableData *)aStream 
 firstTimeTag:(double )firstTimeTag 
 lastTimeTag:(double )lastTimeTag ;

@end

#endif
