#ifndef __MK_ScorefileWriter_H___
#define __MK_ScorefileWriter_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  MKScorefileWriter.h
  DEFINED IN: The Music Kit
  */

#import "MKFileWriter.h"

@interface MKScorefileWriter : MKFileWriter
/*  
 * 
 * A ScorefileWriter is an Instrument that realizes Notes by writing
 * them to a scorefile.  Each of the receiver's NoteReceivers 
 * correspond to a Part that will appear in the scorefile.
 * Unlike most Instruments, the ScorefileWriter class doesn't add
 * any NoteReceivers to a newly created object, they must be added by 
 * invoking the addNoteReceiver:. method. 
 * 
 * The names of the Parts represented in the scorefile are taken from the
 * NoteRecievers for which they were created.  You can name a NoteReceiver by
 * calling the MKNameObject() function.
 * 
 * The header of the scorefile always includes a part statement naming the
 * Parts represented in the Score, and a tagRange statement, outlining the
 * range of noteTag values used in the Note statements.
 * 
 * You shouldn't change the name of a data object (such as an
 * Envelope, WaveTable, or NoteReceiver) during a performance involving a
 * ScorefileWriter.
 */
{
    id info; /* The info Note to be written to the file. */

    /* The following for internal use only */
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

-setInfo:aNote;
 /* 
  * Sets the receiver's info Note, freeing a previously set info Note, if any. 
  * The Note is written, in the scorefile, as an info statement.
  * Returns the receiver.
  */

- infoNote;
 /* 
  * Returns the receiver's info Note, as set through setInfo:.
  */

-setInfo:aPartInfo forNoteReceiver:aNoteReceiver;
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
