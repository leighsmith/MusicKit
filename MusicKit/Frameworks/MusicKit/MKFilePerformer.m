/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#ifdef SHLIB
#include "shlib.h"
#endif

/*
  FilePerformer.m
  Responsibility: David A. Jaffe
  
  DEFINED IN: The Music Kit
  HEADER FILES: musickit.h
*/
/* 
Modification history:

  10/26/89/daj - Added class method fileExtensions for binary scorefile
                 support.
  01/08/90/daj - Flushed _str method. 
  03/21/90/daj - Added archiving. Changed to use _extraVars struct.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  08/23/90/daj - Changed to zone API.
  03/04/91/daj - Fixed bug in copy and free of _extraVars.
  11/17/92/daj - Flushed _extraPerformerVars to go along with Performer change.
*/

#import "_musickit.h"
#import "_error.h"
#import "PerformerPrivate.h"
#import "MKFilePerformer.h"

@implementation MKFilePerformer: MKPerformer
/* A FilePerformer reads data from a file on the disk,
 * fashions a Note object from the data, and then performs
 * the Note.  An abstract superclass, FilePerformer
 * provides common functionality and declares subclass responsibilities
 * for the subclasses
 * MidifilePerformer and ScorefilePerformer.
 *
 * Note: In release 1.0, MidifilePerformer is not provided. Use a Score object
 * to read a Midifile.
 *
 * A FilePerformer is associated with a file, either by the
 * file's name or with a file pointer.  If you assoicate
 * a FilePerformer with a file name (through the \fBsetFile:\fR
 * method) the object will take care of opening and closing
 * the file for you:  the file is opened for reading when the
 * FilePerformer receives the \fBactivate\fR message and closed when
 * it receives \fBdeactivate\fR.  
 *
 * The \fBsetStream:\fR method associates a FilePerformer with a file
 * pointer.  In this case, opening and closing the file
 * is the responsibility of the application.  The FilePerformer's
 * file pointer is set to \fBNULL\fR after each performance 
 * so you must send another
 * \fBsetStream:\fR message in order to replay the file.
 *
 * Note:  The argument to \fBsetStream:\fR
 * is typically a pointer to a file on the disk, but it can also
 * be a UNIX socket or pipe.
 *
 * The FilePerformer class declares two methods as subclass responsibilities:
 * \fBnextNote\fR and \fBperformNote:\fR.
 * \fBnextNote\fR must be subclassed to access the next line of information
 * from the file and from it create either a Note object or a 
 * time value.  It 
 * returns the Note that it creates, or, in the case of a time value,
 * it sets the instance variable \fBfileTime\fR to represent
 * the current time in the file 
 * and returns \fBnil\fR.
 * 
 * The Note created by \fBnextNote\fR is passed as the argument
 * to \fBperformNote:\fR which 
 * is responsible
 * for performing any manipulations on the
 * Note and then sending it
 * by invoking \fBsendNote:\fR.  The return value of \fBperformNote:\fR
 * is disregarded.  
 *
 * Both \fBnextNote\fR and \fBperformNote:\fR are invoked 
 * by the \fBperform\fR method, which, recall from the Performer
 * class, is itself never called directly but is sent by a Conductor.
 * \fBperform\fR also checks and incorporates the time limit
 * and performance offset established by the timing window
 * variables inherited from Performer; \fBnextNote\fR and 
 * \fBperformNote:\fR needn't access nor otherwise be concerned
 * about these variables.
 *
 * Two other methods, \fBinitFile\fR and \fBfinishFile\fR, can
 * be redefined by a FilePerformer subclass, although neither
 * must be.  \fBinitializeFile\fR is invoked 
 * when the object is activated and should perform any special
 * initialization such as reading the file's header or magic number.
 * If \fBinitializeFile\fR returns \fBnil\fR, the FilePerformer is deactivated.
 * The default returns the receiver.
 *
 * \fBfinishFile\fR is invoked when the FilePerformer is deactivated
 * and should perform any post-performance cleanup.  Its return
 * value is disregarded.
 * 
 * A FilePerformer reads and performs one Note at a time.  This
 * allows efficient performance of arbitrarily large files.
 * Compare this to the 
 * Score object which reads and processes the entire file
 * before performing the first note.  However, unlike the Score object,
 * the FilePerformer doesn't allow individual timing control over the 
 * different Note streams in the file; the timing window
 * specifications inherited from Performer are applied to the entire
 * file.
 *
 * Any number of FilePerformers can perform the 
 * same file concurrently.
 */
{
    NSString * filename;       /* File name or NULL if the file pointer is specifed
					  directly. */
    double fileTime;     /* The current time in the file (in beats). */
    id stream;           /* Pointer to the FilePerformer's file. */ /*sb: either NSMutableData or NSData */
    double firstTimeTag; /* The smallest timeTag value considered for
			   performance.  */
    double lastTimeTag;   /* The greatest timeTag value considered for 
			   performance.  */
    void *_reservedFilePerformer1;
}
#define _extraVars _reservedFilePerformer1

/* METHOD TYPES
 * Initializing a FilePerformer
 * Accessing files
 * Accessing Notes
 * Performing
 */

#import "timetagInclude.m"

/* Special factory methods. ---------------------------------------- */

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKFilePerformer class])
      return;
    [MKFilePerformer setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Invokes superclass write: method. Then archives filename, 
     firstTimeTag, and lastTimeTag. 
     */
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeValuesOfObjCTypes:"*ddd",&filename,&firstTimeTag,&lastTimeTag];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    [super initWithCoder:aDecoder];
    if ([aDecoder versionForClassName:@"FilePerformer"] == VERSION2) {
	[aDecoder decodeValuesOfObjCTypes:"*ddd",&filename,&firstTimeTag,&lastTimeTag];
    }
    return self;
}

-init
  /* TYPE: Initializing; Sent automatically on instance creation.
   * Initializes the receiver by setting \fBstream\fR and \fBfilename\fR
   * to \fBNULL\fR.
   * Sent by the superclass upoon creation.
   * You never invoke this method directly.
   * An overriding subclass method should send \fB[super initDefaults]\fR
   * before setting its own defaults. 
   */
{
    [super init];
    lastTimeTag = MK_ENDOFTIME;
    return self;
}

- (void)dealloc
{
    if (filename)
      [filename release];
    free(_extraVars);
    [super dealloc];
}

-setFile:(NSString *)aName
  /* TYPE: Modifying; Associates the receiver with file \fIaName\fR.
   * Associates the receiver with file \fIaName\fR. The string is copied.
   * The file is opened when the first Note is realized
   * (written to the file) and closed at the end of the
   * performance.
   * It's illegal to invoke this method during a performance. Returns nil
   * in this case. Otherwise, returns the receiver.
   */
{
    if (status != MK_inactive) 
      return nil;
/*
    if (filename) {
	free(filename);
	filename = NULL;
    }
 */
    [filename autorelease];
    filename = [aName copy];
//    filename = _MKMakeStr(aName);
    stream = nil;
    return self;
}

- setStream:(id) aStream
/* * Either NSMutableData, or NSData
   * Sets \fBstream\fR to \fBaStream\fR and sets \fBfilename\fR to NULL.
   * \fIaStream\fR must be open for
   * reading.  Returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, otherwise
   * self.
   */
{
    if (status != MK_inactive) 
      return nil;
    [self setFile:nil];
    stream = aStream;
    return self;
}

-(id) stream
  /* Either NSMutableData, or NSData
   * Returns the file pointer associated with the receiver
   * or nil if it isn't set.
   * Note that if the file was specified with \fBfile:\fR and
   * the performer is inactive (i.e. the file isn't open), this will return
   * nil.
   */
{
    return stream;
}



-(NSString *)file
  /* TYPE: Querying; Returns the name set through \fBsetFile:\fR.
   * If the file associated with the receiver was set through 
   * \fBsetFile:\fR,
   * returns the file name, otherwise returns NULL.
   */
{
    return filename;
}

+(NSString *)fileExtension
  /* Returns default file extension for files managed by the subclass. The
     default implementation returns NULL. Subclass may override this to
     specify a default file extension. */
{
    return NULL;
}

+(NSString **)fileExtensions
  /* This method is used when several file extensions must be handled. 
     The value returned by this method is a pointer to a null-terminated
     array of strings, each of which is a valid file extension for files
     handled by the subclass.  Subclass may override this to specify a default 
     file extension.  The default implementation returns 
     an array with one element equal to [self fileExtension]. */
{
    static NSString *extensions[2] = {NULL};
    extensions[0] = [self fileExtension];
    return extensions;
}

/* Methods required by superclasses. ------------------------------- */

-activateSelf
  /* TYPE: Performing; Prepares the reciever for a performance.
   * Invoked by the \fBactivate\fR method, this prepares the receiver 
   * for a performance by opening the associated file (if necessary)
   * and invoking \fBnextNote\fR until it returns 
   * an appropriate Note -- one with 
   * a timeTag between \fBfirstTimeTag\fR
   * and \fBlastTimeTag\fR, inclusive.
   * If an appropriate Note isn't found 
   * \fB[self\ deactivate]\fR is sent. 
   *
   * You never send the \fBactivateSelf\fR message directly to 
   * a FilePerformer.  
   */
{
    if (filename) {
	NSString **fileExt = [[self class] fileExtensions];
	for (; ;) {
/*	    stream = _MKOpenFileStream(filename,&(_fd(self)),NX_READONLY,
				       *fileExt,NO);
 */
            stream = _MKOpenFileStreamForReading(filename,*fileExt,NO);//sb
            if (stream) {
                [stream retain];
                break;
            }
	    if (*fileExt++ == nil) 
	      break;
	} 
	if (!stream)
	  _MKErrorf(MK_cantOpenFileErr,filename);
    }
    fileTime = 0;
    if ((!stream) || (![self initializeFile])) 
      return nil;
    [noteSenders makeObjectsPerformSelector:@selector(_setPerformer:) withObject:self];
    /* The first element in the file may be a time or a note. If it's a note,
       than its time is implicitly 0. Since we don't lookahead unless 
       firstTimeTag > 0, it is guaranteed that this note will not be overlooked.
       */
    if (firstTimeTag > 0)
      for (; ;) {
	  [self nextNote];
	  if (fileTime > (MK_ENDOFTIME-1))  {
	      [self deactivate];
	      return nil;
	  }
	  if (fileTime >= firstTimeTag)
	    break;
      }
    /* Insure we run for the first time on our first note. */
//  nextPerform = fileTime - firstTimeTag;
    nextPerform = fileTime;
    return self;
}

-perform 
  /* TYPE: Performing
   * Grabs the next Note out of the file through \fBnextNote\fR,
   * processes it through 
   * \fBperformNote:\fR (the method that sends the Note), and
   * sets the value of \fBnextPerform\fR. 
   * You may override this method to modify nextPerform, but you must
   * send [super perform].
   * You never send perform directly to an object.
   * Returns the receiver.
   */
{
    id aNote;
    double t = fileTime;
    while (aNote = [self nextNote])
      [self performNote:aNote];
    if (fileTime > (MK_ENDOFTIME-1) || fileTime >= lastTimeTag) 
      [self deactivate];
    else 
      nextPerform = fileTime - t;
    return self;
}

/* Methods which must be supplied by subclass. ---------------- */

-performNote:(id)aNote
  /* TYPE: Accessing Notes
   * This is a subclass responsibility expected to manipulate
   * and send \fBaNote\fR which was presumably just read from a file.
   * It's up to the subclass to free \fIaNote\fR. 
   *
   * You never send the \fBperformNote:\fR message 
   * directly to a FilePerformer; it's invoked by the \fBperform\fR
   * method.
   */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", sel_getName(_cmd)]; return nil;
}

-(id)nextNote     
  /* TYPE: Accessing Notes
   * This is a subclass responsibility expected to get the next Note
   * from the file.  Should return the Note or \fBnil\fR if the
   * next file entry is a performance time.  In the latter case,
   * this should update \fBfileTime\fR.
   *
   * You never send the \fBnextNote\fR message 
   * directly to a FilePerformer; it's invoked by the \fBperform\fR
   * method.
   */
{
    [NSException raise:NSInvalidArgumentException format:@"*** Subclass responsibility: %s", sel_getName(_cmd)]; return nil;
}

-initializeFile
  /* TYPE: Performing; Preparing the file for a performance.
   * This is a subclass responsibility expected to perform 
   * any special file initialization and return the receiver.
   * If \fBnil\fR is returned, the receiver is deactivated.
   *
   * You never send the \fBinitializeFile\fR message 
   * directly to a FilePerformer; it's invoked by the \fBactivateSelf\fR
   * method.
   *
   */
{
    return self;
}

- (void)deactivate 
  /* TYPE: Performing; Cleans up after a performance.
   * Invokes \fBfinishFile\fR, closes the file (if it was 
   * set through \fBsetFile:\fR), and sets the file pointer
   * to \fBNULL\fR.
   */
{
   [super deactivate];  // added by LMS - never stopped the performance.
   if (stream)
     [self finishFile];
   if (filename) {
       [stream release];
   }
   stream = nil;
}

-finishFile
  /* TYPE: Performing; Cleans up after a performance.
   * Subclass should override this to do any cleanup
   * needed after a performance -- however, you shouldn't 
   * close the file pointer as part of this method.
   *
   * You never send the \fBfinishFile\fR message directly to a
   * FilePerformer; it's invoked by the \fBdeactivate\fR method.
   */
{
    return self;
} 

- copyWithZone:(NSZone *)zone
  /* The returned value is a copy of the receiver, with a copy of the filename
     and stream set to NULL. The NoteSenders are not copied (the superclass
     copy method is overridden); instead, an empty list is given.  */
{
    MKFilePerformer *newObj = [super _copyFromZone:zone];
    newObj->filename = [filename copy];//_MKMakeStr(filename);
    newObj->stream = nil;
    return newObj;
}

@end

