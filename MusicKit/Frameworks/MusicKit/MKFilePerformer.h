/*
  $Id$  
  Defined In: The MusicKit

  Description:
    A MKFilePerformer reads data from a file on the disk,
    fashions a MKNote object from the data, and then performs
    the MKNote.  An abstract superclass, MKFilePerformer
    provides common functionality and declares subclass responsibilities
    for the subclasses MKMidifilePerformer and MKScorefilePerformer.

    Note: In release 1.0, MKMidifilePerformer is not provided. Use a MKScore object
    to read a Midifile.

    A MKFilePerformer is associated with a file, either by the
    file's name or with a file pointer.  If you assoicate
    a MKFilePerformer with a file name (through the setFile:
    method) the object will take care of opening and closing
    the file for you:  the file is opened for reading when the
    MKFilePerformer receives the activate message and closed when
    it receives deactivate.

    The setStream: method associates a MKFilePerformer with a file
    pointer.  In this case, opening and closing the file
    is the responsibility of the application.  The MKFilePerformer's
    file pointer is set to NULL after each performance
    so you must send another setStream: message in order to replay the file.

    Note:  The argument to setStream: is typically a pointer to a file on the disk, but it can also
    be a UNIX socket or pipe.

    The MKFilePerformer class declares two methods as subclass responsibilities:
    nextNote and performNote:. nextNote must be subclassed to access the next line of information
    from the file and from it create either a MKNote object or a
    time value.  It returns the MKNote that it creates, or, in the case of a time value,
    it sets the instance variable fileTime to represent the current time in the file
    and returns nil.

    The MKNote created by nextNote is passed as the argument
    to performNote: which is responsible for performing any manipulations on the
    MKNote and then sending it by invoking sendNote:.
    The return value of performNote: is disregarded.

    Both nextNote and performNote: are invoked
    by the perform method, which, recall from the MKPerformer
    class, is itself never called directly but is sent by a MKConductor.
    perform also checks and incorporates the time limit
    and performance offset established by the timing window
    variables inherited from MKPerformer; nextNote and
    performNote: needn't access nor otherwise be concerned
    about these variables.

    Two other methods, initFile and finishFile, can
    be redefined by a MKFilePerformer subclass, although neither
    must be.  initializeFile is invoked
    when the object is activated and should perform any special
    initialization such as reading the file's header or magic number.
    If initializeFile returns nil, the MKFilePerformer is deactivated.
    The default returns the receiver.

    finishFile is invoked when the MKFilePerformer is deactivated
    and should perform any post-performance cleanup.  Its return
    value is disregarded.

    A MKFilePerformer reads and performs one MKNote at a time.  This
    allows efficient performance of arbitrarily large files.
    Compare this to the MKScore object which reads and processes the entire file
    before performing the first note.  However, unlike the MKScore object,
    the MKFilePerformer doesn't allow individual timing control over the
    different MKNote streams in the file; the timing window
    specifications inherited from MKPerformer are applied to the entire
    file.

    Any number of MKFilePerformers can perform the same file concurrently.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
  $Log$
  Revision 1.5  2000/04/22 20:16:02  leigh
  Changed fileExtensions to less error-prone NSArray of NSStrings

  Revision 1.4  2000/04/02 17:05:05  leigh
  Cleaned up doco

  Revision 1.3  1999/07/29 04:48:03  leigh
  removed extraneous _extraVar ivar

  Revision 1.2  1999/07/29 01:25:45  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_FilePerformer_H___
#define __MK_FilePerformer_H___
//sb:
#import <Foundation/Foundation.h>

#import "MKPerformer.h"

@interface MKFilePerformer : MKPerformer
{
    NSString *filename;       /* File name or nil if the file pointer is specifed directly. */
    double fileTime;          /* The current time in the file (in beats). */
    id stream;                /* Pointer to the MKFilePerformer's file, either NSMutableData or NSData */
    double firstTimeTag;      /* The smallest timeTag value considered for performance. */
    double lastTimeTag;       /* The greatest timeTag value considered for performance. */
}
 
- init;
- copyWithZone:(NSZone *)zone;
- setFile:(NSString *)aName;
- setStream:(id)aStream; // either NSMutableData, or NSData
-(id) stream; // either NSMutableData, or NSData
-(NSString *) file; 
- activateSelf; 
+(NSString *)fileExtension;
+(NSArray *)fileExtensions;
- perform; 
- performNote:aNote; 
- nextNote; 
- initializeFile; 
- (void)deactivate; 
- finishFile; 
- setFirstTimeTag:(double)aTimeTag; 
- setLastTimeTag:(double)aTimeTag; 
-(double) firstTimeTag; 
-(double) lastTimeTag; 
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end



#endif
