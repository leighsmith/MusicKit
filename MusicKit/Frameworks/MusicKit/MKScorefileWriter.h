/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKScorefileWriter is an MKInstrument that realizes MKNotes by writing
    them to a scorefile.  Each of the receiver's MKNoteReceivers 
    correspond to a MKPart that will appear in the scorefile.
    Unlike most MKInstruments, the MKScorefileWriter class doesn't add
    any MKNoteReceivers to a newly created object, they must be added by 
    invoking the addNoteReceiver:. method. 

    The names of the MKParts represented in the scorefile are taken from the
    MKNoteRecievers for which they were created.  You can name a MKNoteReceiver by
    calling the MKNameObject() function.

    The header of the scorefile always includes a part statement naming the
    MKParts represented in the MKScore, and a tagRange statement, outlining the
    range of noteTag values used in the MKNote statements.

    You shouldn't change the name of a data object (such as an
    MKEnvelope, MKWaveTable, or MKNoteReceiver) during a performance involving a
    MKScorefileWriter.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.7  2005/05/09 15:52:54  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.6  2005/04/15 04:18:25  leighsmith
  Cleaned up for gcc 4.0's more stringent checking of ObjC types

  Revision 1.5  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2000/11/25 23:04:01  leigh
  Corrected typing of ivars and enforced their privacy

  Revision 1.3  1999/09/04 22:44:04  leigh
  setInfo now setInfoNote

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKScorefileWriter
  @brief

A MKScorefileWriter is an MKInstrument that realizes MKNotes by writing them to a
scorefile.  The name of the scorefile to which the MKNotes are written is set
through methods inherited from MKFileWriter.

Each of a ScorefileWriter's MKNoteReceivers corresponds to a MKPart that will appear
in the scorefile.  Unlike most Instruments, the MKScorefileWriter class doesn't
add any MKNoteReceivers to a newly created object, they must be added by invoking
the <b>addNoteReceiver:</b> method.

The names of the MKParts represented in the scorefile are taken from the
NoteRecievers for which they were created.  You can name a NoteReceiver by
calling the <b>MKNameObject()</b> function.

The header of the scorefile always includes a <b>part</b> statement that names
the MKParts represented in the MKScore, and a <b>tagRange</b> statement that states
the range of noteTag values used in the MKNote statements.  A MKScorefileWriter can
be given an info MKNote that's written as a MKScore info statement in the file;
similarly, the ScorefileWriter's MKNoteReceivers can each contain a MKPart info
MKNote.  These, too, are written to the scorefile, each in a separate MKPart info
statement.

You shouldn't change the name of a data object (such as an MKEnvelope, MKWaveTable,
or NoteReceiver) during a performance involving a MKScorefileWriter.
*/
#ifndef __MK_ScorefileWriter_H___
#define __MK_ScorefileWriter_H___

#import "MKFileWriter.h"

@interface MKScorefileWriter : MKFileWriter
{
    MKNote *info; /* The info MKNote to be written to the file. */

@private
    int _highTag,_lowTag;
    BOOL _isOptimized;
    void *_p;
}
 
 /* 
  * scorefiles.  The string isn't copied.  Note: This method is superceded
  * by the instance method by the same name.  */
+(NSString *)fileExtension;

/*!
  @return Returns an NSString.
  @brief Returns "score", the default file extension for score files if the
  file was set with <b>setFile:</b> or <b>setStream:</b>.

  Returns
  "playscore", the default file extension for optimized format score
  files if the file was set with <b>setOptimizedFile:</b> or
  <b>setOptimizedStream:</b>. The string is not copied.
*/
-(NSString *)fileExtension;

/*!
  @param  aNote is an MKNote.
  @return Returns an id.
  @brief Sets the receiver's info MKNote, freeing a previously set info MKNote,
  if any.

  The MKNote is written, in the scorefile, as a MKScore info
  statement.  Returns the receiver.
*/
-setInfoNote:(MKNote *) aNote;

/*!
  @return Returns an id.
  @brief Returns the receiver's info MKNote, as set through
  <b>setInfo:</b>.

  
*/
-(MKNote *) infoNote;

/*!
  @param  aPartInfo is an MKNote.
  @param  aNoteReceiver is an MKNoteReceiver.
  @return Returns an id.
  @brief Sets <i>aPartInfo</i> as the MKNote that's written as the info MKNote
  for the MKPart that corresponds to the MKNoteReceiver
  <i>aNoteReceiver</i>.

  The MKPart's previously set info MKNote, if any,
  is freed.  If the receiver is in performance, or if
  <i>aNoteReceiver</i> doesn't belong to the receiver, does nothing
  and returns <b>nil</b>, otherwise returns the receiver.
*/
-setInfoNote:(MKNote *) aPartInfo forNoteReceiver: (MKNoteReceiver *) aNR;

/*!
  @param  aNoteReceiver is an MKNoteReceiver instance.
  @return Returns an MKNote instance.
  @brief Returns the info MKNote that's associated with an MKNoteReceiver
  (as set through -<b>setInfo:forNoteReceiver:</b>).

  
*/
- (MKNote *) infoNoteForNoteReceiver: (MKNoteReceiver *) aNoteReceiver;

/*!
  @return Returns an id.
  @brief Initializes the scorefile.

  You never invoke this method; it's
  invoked automatically just before the receiver writes its first MKNote
  to the scorefile.
*/
- initializeFile; 

/*!
  @return Returns an id.
  @brief You never invoke this method; it's invoked automatically at the end
  of a performance.

  
*/
- finishFile; 

 /* 
  * Creates and returns a new MKScorefileWriter as a copy of the receiver.
  * The new object copies the receivers MKNoteReceivers and info MKNotes.
  * See MKInstrument copy method.
  */
- copyWithZone:(NSZone *)zone; 

/*!
  @param  aNote is an id.
  @param  aNoteReceiver is an id.
  @return Returns an id.
  @brief Realizes <i>aNote</i> by writing it to the scorefile.

  The MKNote
  statement created from <i>aNote</i> is assigned to the MKPart that
  corresponds to <i>aNoteReceiver</i>.
*/
- realizeNote:aNote fromNoteReceiver:aNoteReceiver; 

/*!
  @param  aName is a char *.
  @return Returns an id.
  @brief Sets file and specifies that the data be written in ascii (<tt>.score</tt>)
  format.

  See superclass documentation for details.
*/
- setFile:(NSString *)aName;

/*!
  @param  aStream is an NSMutableData.
  @return Returns an id.
  @brief Sets stream and specifies that the data be written in ascii (<tt>.score</tt>)
  format.

  See superclass documentation for details.
*/
-setStream:(NSMutableData *)aStream;

/*!
  @param  aStream is an NSMutableData.
  @return Returns an id.
  @brief Same as setStream: but specifies that the data be written in
  optimized scorefile (<tt>.playscore</tt>) format.

  
*/
-setOptimizedStream:(NSMutableData *)aStream;

/*!
  @param  aName is an NSString.
  @return Returns an id.
  @brief Same as setFile: but specifies that the data be written in optimized
  (<tt>.playscore</tt>) format.

  
*/
-setOptimizedFile:(NSString *)aName;

  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write:, which archives MKNoteReceivers.
     Then archives info, isOptimized, and MKPart info MKNotes.  */
- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     Note that -init is not sent to newly unarchived objects.
     See write:. */
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

#endif
