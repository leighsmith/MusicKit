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
  Portions Copyright (c) 1999-2000, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.4  2000/11/25 23:04:01  leigh
  Corrected typing of ivars and enforced their privacy

  Revision 1.3  1999/09/04 22:44:04  leigh
  setInfo now setInfoNote

  Revision 1.2  1999/07/29 01:25:50  leigh
  Added Win32 compatibility, CVS logs, SBs changes

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
 
+(NSString *)fileExtension;
 /* 
  * scorefiles.  The string isn't copied.  Note: This method is superceded
  * by the instance method by the same name.  */

-(NSString *)fileExtension;
 /* 
  * Returns "score", the default file extension for score files if the
  * file was set with setFile: or setStream:. Returns "playscore", the
  * default file extension for optimized format score files if the file was
  * set with setOptimizedFile: or setOptimizedStream:.  The string is not
  * copied. */

-setInfoNote:(MKNote *) aNote;
 /* 
  * Sets the receiver's info Note, freeing a previously set info Note, if any. 
  * The Note is written, in the scorefile, as an info statement.
  * Returns the receiver.
  */

-(MKNote *) infoNote;
 /* 
  * Returns the receiver's info Note, as set through setInfo:.
  */

-setInfoNote:(MKNote *) aPartInfo forNoteReceiver: (MKNoteReceiver *) aNR;
 /* 
  * Sets aNote as the Note that's written as the info Note for the
  * Part that corresponds to the NoteReceiver aNR.
  * The Part's previously set info Note, if any, is freed.
  * If the receiver is in performance, or if aNR doesn't belong
  * to the receiver, does nothing and returns nil,
  * Otherwise returns the receiver.
  */

- infoNoteForNoteReceiver:aNoteReceiver;
 /* 
  * Returns the info Note that's associated with a NoteReceiver
  * (as set through setInfo:forNoteReceiver:).
  */

- initializeFile; 
 /* 
  * Initializes the scorefile.
  * You never invoke this method; it's invoked automatically just before the
  * receiver writes its first Note to the scorefile.
  */

- finishFile; 
 /* 
  * You never invoke this method; it's invoked automatically at the end
  * of a performance. 
  */

- copyWithZone:(NSZone *)zone; 
 /* 
  * Creates and returns a new ScorefileWriter as a copy of the receiver.
  * The new object copies the receivers NoteReceivers and info Notes.
  * See Instrument copy method.
  */

- realizeNote:aNote fromNoteReceiver:aNoteReceiver; 
 /* 
  * Realizes aNote by writing it to the scorefile.  The Note statement
  * created from aNote is assigned to the Part that corresponds to
  * aNoteReceiver.
  */

-setFile:(NSString *)aName;
  /* Sets file and specifies that the data be written in ascii (.score) format.
     See superclass documentation for details. 
   */ 

-setStream:(NSMutableData *)aStream;
  /* Sets stream and specifies that the data be written in ascii (.score) 
     format. See superclass documentation for details. 
   */ 

-setOptimizedStream:(NSMutableData *)aStream;
  /* Same as setStream: but specifies that the data be written in optimized 
     scorefile (.playscore) format. */

-setOptimizedFile:(NSString *)aName;
  /* Same as setFile: but specifies that the data be written in optimized 
     (.playscore) format. */

- (void)encodeWithCoder:(NSCoder *)aCoder;
  /* 
     You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write:, which archives NoteReceivers.
     Then archives info, isOptimized, and Part info Notes.  */
- (id)initWithCoder:(NSCoder *)aDecoder;
  /* 
     You never send this message directly.  
     Should be invoked via NXReadObject(). 
     Note that -init is not sent to newly unarchived objects.
     See write:. */
//- awake;
  /* 
     Gets object ready for use. */

@end



#endif
