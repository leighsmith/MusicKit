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
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.8  2005/05/09 15:52:54  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.7  2004/08/21 23:21:50  leighsmith
  Corrected doco

  Revision 1.6  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.5  2000/11/28 19:15:13  leigh
  Doco cleanup

  Revision 1.4  2000/11/25 23:03:09  leigh
  Corrected typing of ivars and enforced their privacy

  Revision 1.3  2000/04/22 20:11:16  leigh
  Changed fileExtensions to less error-prone NSArray of NSStrings

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKScorefilePerformer
  @brief

ScorefilePerformers are used to perform scorefiles.  When the object is
activated, it reads the file's header and creates a NoteSender for each (unique)
member of the <b>part</b> statement.  A NoteSender is given the same name as the
MKPart for which it was created.

During a performance, a MKScorefilePerformer reads successive MKNote and time
statements from the file from which it creates MKNote objects that it sends
through its MKNoteSenders.  When it reaches the end of the file, the
MKScorefilePerformer is deactivated.

A MKScorefilePerformer has its own info MKNote that it fashions from the <b>info</b>
statement in the file, and defines an NSMutableData instance on which scorefile <b>print</b>
statements are printed.
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
 

/*!
  @return Returns an id.
  @brief Initializes the receiver.

  You invoke this method when creating a
  new intance.  A subclass implementation should send <b>[super
  init]</b> before performing its own initialization. 
  
*/
- init;

+(NSString *)fileExtension;
 /* Obsolete (see fileExtensions)
  */

/*!
  @return Returns an NSArray.
  @brief Returns a NSArray of the default file extensions
  recognized by MKScorefilePerformer instances.

  This array typically consists of
  "score" and "playscore".   This method is used by the MKFilePerformer
  class.  The string is not copied. 
*/
+(NSArray *)fileExtensions;

/*!
  @return Returns an MKNote.
  @brief Returns the receiver's info MKNote, fashioned from an <b>info</b>
  statement in the header of the scorefile.

  
*/
- infoNote;

/*!
  @return Returns an id.
  @brief You never invoke this method; it's invoked automatically by
  <b>selfActivate</b> (just before the file is performed).

  It reads
  the scorefile header and creates NoteSender objects for each member
  of the file's <b>part</b> statements.  It also creates info MKNotes
  from the file's MKScore and MKPart info statements and adds them to
  itself and its MKParts.  If the file can't be read, or the scorefile
  parser encounters too many errors, the receiver is
  deactivated.
*/
- initializeFile; 

/*!
  @return Returns an id.
  @brief You never invoke this method; it's invoked automatically by
  <b>deactivate</b>.

  Performs post-performance cleanup of the
  scorefile parser.
*/
- finishFile; 

/*!
  @return Returns an NSMutableData.
  @brief Returns the receiver's scorefile <b>print</b> statement
  stream.

  
*/
-(NSMutableData *)scorefilePrintStream;

/*!
  @return Returns an id.
  @brief Reads the next MKNote or time statement from the body of the
  scorefile.

  MKNote statements are turned into MKNote objects and
  returned.  If its a time statement that's read, fileTime is set to
  the statement's value and <b>nil</b> is returned.
  
  You never invoke this method; it's invoked automatically by the
  <b>perform</b> method.  If you override this method, you must
  send <b>[super nextNote]</b>.
*/
- nextNote; 

/*!
  @param  aNoteSender is an id.
  @return Returns an id.
  @brief Returns the info MKNote of the MKPart associated with the MKNoteSender
  <i>aNoteSender</i>.

  If <i>aNoteSender</i> isn't a contained in the
  receiver, returns <b>nil</b>.
*/
- infoNoteForNoteSender:aNoteSender; 

/*!
  @param  aNote is an id.
  @return Returns an id.
  @brief Sends <i>aNote</i> to the appropriate MKNoteSender You never send
  <b>performNote:</b> directly to a MKScorefilePerformer; it's invoked
  by the <b>perform</b> method.

  
*/
- performNote:aNote; 

/*!
  @param  aChan is an int.
  @return Returns an id.
  @brief Returns the first MKNoteSender whose corresponding MKPart has 
  a MK_midiChan info parameter equal to <i>aChan</i>, if any.

  <i>aChan</i> equal
  to 0 corresponds to the MKPart representing MIDI system and channel
  mode messages.
*/
-midiNoteSender:(int)aChan;

 /* 
  * Frees the receiver, its MKNoteSenders, and its info MKNote.  If the
  * receiver is active, this does nothing and returns self. Otherwise,
  * returns nil. You never call this directly, it is called by the release
  * mechanism of NSObject.
  */
- (void)dealloc;

 /* 
  * Creates and returns a new MKScorefilePerformer as a copy of the
  * receiver.  The info receiver's info MKNote is also copied.
  */
- copyWithZone:(NSZone *)zone;

  /* 
     You never send this message directly.  
     Should be invoked via NSArchiver. 
     Invokes superclass write:, which archives MKNoteSenders.
     Then archives info and part infos gleaned from the Scorefile. */
- (void)encodeWithCoder:(NSCoder *)aCoder;

  /* 
     You never send this message directly.  
     Should be invoked via NSArchiver. 
     Note that -init is not sent to newly unarchived objects. */
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

#endif
