/*
  $Id$
  Defined In: The MusicKit

  Description:
    A MKFileWriter is an MKInstrument that realizes MKNotes by writing them to
    a file on the disk. An abstract superclass, MKFileWriter
    provides common functionality and declares subclass responsibilities
    for the subclasses MKMidifileWriter and MKScorefileWriter.
    Note: In this release, MKMidifileWriter is not provided. Use a MKScore object
    to write a Midifile.

    A MKFileWriter is associated with a file, either by the
    file's name or with a file pointer.  If you assoicate
    a MKFileWriter with a file name (through the setFile:
    method) the object will take care of opening and closing
    the file for you:  the file is opened for writing when the
    object first receives the realizeNote: message
    and closed after the performance.  The
    file is overwritten each time it's opened.

    The setStream: method associates a MKFileWriter with a file
    pointer.  In this case, opening and closing the file
    is the responsibility of the application.  The MKFileWriter's
    file pointer is set to NULL after each performance.

    To design a subclass of MKFileWriter you must implement
    the method realizeNote:fromNoteReceiver:.

    Two other methods, initializeFile and finishFile, can
    be redefined in a subclass, although neither
    must be.  initializeFile is invoked
    just before the first Note is written to the
    file and should perform any special
    initialization such as writing a file header.

    finishFile is invoked after each performance
    and should perform any post-performance cleanup.
    The values returned by initializeFile and finishFile are ignored.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University 
*/
/*
  $Log$
  Revision 1.3  2000/04/16 04:16:17  leigh
  comment cleanup

  Revision 1.2  1999/07/29 01:25:45  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_FileWriter_H___
#define __MK_FileWriter_H___

#import <Foundation/Foundation.h>

#import "MKInstrument.h"
#import "timeunits.h"

@interface MKFileWriter : MKInstrument
{
    MKTimeUnit timeUnit;
    NSMutableString *filename;        /* Or NULL. */
    NSMutableData *stream;            /* Pointer of open file. */
    double timeShift;
    BOOL compensatesDeltaT;
    int _fd;
}

- init; 
-setTimeUnit:(MKTimeUnit)aTimeUnit;
-(MKTimeUnit)timeUnit;
+(NSString *)fileExtension;
-(NSString *)fileExtension;
- setFile:(NSString *)aName; 
- setStream:(NSMutableData *)aStream; 
- (NSMutableData *) stream; 
- copyWithZone:(NSZone *)zone; 
- (NSString *) file; 
- finishFile; 
- initializeFile; 
- firstNote:aNote; 
- afterPerformance; 
- (double)timeShift;
- setTimeShift:(double)timeShift;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end



#endif
