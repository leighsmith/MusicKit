/*
  $Id$
  Defined In: The MusicKit

  Description:
    MKScorefilePerformers are used to perform scorefiles.  
    Instances of this class are used directly in an application;
    you don't have to design your own subclass.
   
    When the object is activated, it reads the file's header and creates a
    MKNoteSender for each (unique) member of the part statement.
    A MKNoteSender is given the same name as the MKParts for which it was created.
    Thus, you can find out the names of the MKParts in the file by getting
    an NSArray of the noteSenders (using -noteSenders) and using the function
    MKGetObjectName(noteSender).

    A MKScorefilePerformer also has an info MKNote which it fashions from the
    info statement in the file and defines a stream on which scorefile
    print statements are printed.

    During a performance, a MKScorefilePerformer reads successive MKNote and
    time statements from the file.  When it reaches the end of the file,
    the MKScorefilePerformer is deactivated.

    Much of MKScorefilePeformer's functionality is documented under MKFilePerformer,
    and MKPerformer.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2000/11/28 19:15:13  leigh
  Doco cleanup

  Revision 1.4  2000/11/25 23:03:09  leigh
  Corrected typing of ivars and enforced their privacy

  Revision 1.3  2000/04/22 20:11:16  leigh
  Changed fileExtensions to less error-prone NSArray of NSStrings

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_ScorefilePerformer_H___
#define __MK_ScorefilePerformer_H___

#import "MKFilePerformer.h"

@interface MKScorefilePerformer : MKFilePerformer
{
    NSMutableData *scorefilePrintStream;  // The stream used for the scorefile's print statements.
    MKNote *info;                         // MKScore info MKNote for the file.

@private
    void *_p;
    NSMutableArray *_partStubs;
}
 
- init;
 /* 
  * Initializes the receiver.  You never invoke this method directly.  A
  * subclass implementation should send [super initialize] before
  * performing its own initialization.  The return value is ignored.
  */

+(NSString *)fileExtension;
 /* Obsolete (see fileExtensions)
  */

+(NSArray *)fileExtensions;
 /* Returns a NSArray of the default file extensions
  * recognized by MKScorefilePerformer instances. This array consists of
  * "score" and "playscore".  This method is used by the MKFilePerformer
  * class.  The string is not copied. */

- infoNote;
 /* 
  * Returns the receiver's info MKNote, fashioned from an info statement
  * in the header of the scorefile.
  */

- initializeFile; 
 /* 
  * You never invoke this method; it's invoked automatically by
  * selfActivate (just before the file is performed).  It reads the
  * scorefile header and creates MKNoteSender objects for each member of the
  * file's part statements.  It also creates info MKNotes from the file's
  * MKScore and MKPart info statements and adds them to itself and its MKParts.
  * If the file can't be read, or the scorefile parser encounters too many
  * errors, the receiver is deactivated.
  */

- finishFile; 
 /* 
  * You never invoke this method; it's invoked automatically by
  * deactivate.  Performs post-performance cleanup of the scorefile
  * parser.
  */

-(NSMutableData *)scorefilePrintStream;
 /* 
  * Returns the receiver's scorefile print statement stream.
  */

- nextNote; 
 /* 
  * Reads the next MKNote or time statement from the body of the scorefile.
  * Note statements are turned into MKNote objects and returned.  If its a
  * time statement that's read, fileTime is set to the statement's value
  * and nil is returned.
  * 
  * You never invoke this method; it's invoked automatically by the
  * perform method.  If you override this method, you must send 
  * [super nextNote].
  */

- infoNoteForNoteSender:aNoteSender; 
 /* 
  * Returns the info MKNote of the MKPart associated with the 
  * MKNoteSender aNoteSender.  If aNoteSender isn't 
  * a contained in the receiver, returns nil.
  */

- performNote:aNote; 
 /* 
  * Sends aNote to the appropriate MKNoteSender
  * You never send performNote: directly to a ScorefilePerformer;
  * it's invoked by the perform method.  
  */

-midiNoteSender:(int)aChan;
 /* Returns the first MKNoteSender whose corresponding MKPart has 
  * a MK_midiChan info parameter equal to
  * aChan, if any. aChan equal to 0 corresponds to the MKPart representing
  * MIDI system and channel mode messages. */

- (void)dealloc;
 /* 
  * Frees the receiver, its MKNoteSenders, and its info MKNote.  If the
  * receiver is active, this does nothing and returns self. Otherwise,
  * returns nil. You never call this directly, it is called by the release
  * mechanism of NSObject.
  */

- copyWithZone:(NSZone *)zone;
 /* 
  * Creates and returns a new MKScorefilePerformer as a copy of the
  * receiver.  The info receiver's info MKNote is also copied.
  */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked via NSArchiver. 
     Invokes superclass write:, which archives MKNoteSenders.
     Then archives info and part infos gleaned from the Scorefile. */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Should be invoked via NSArchiver. 
     Note that -init is not sent to newly unarchived objects. */

@end

#endif
