/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    A score contains a collection of Parts and has methods for manipulating
    those Parts. Scores and Parts work closely together. 
    Scores can be performed. 
    The score can read or write itself from a scorefile or midifile.
     
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
*/
/* 
Modification history:

  $Log$
  Revision 1.13  2000/04/16 04:22:44  leigh
  Comment cleanup and removed assignment in condition warning

  Revision 1.12  2000/04/03 23:45:42  leigh
  Added description method

  Revision 1.11  2000/03/31 00:09:31  leigh
  Adopted OpenStep naming of factory methods

  Revision 1.10  2000/03/29 03:17:47  leigh
  Cleaned up doco and ivar declarations

  Revision 1.9  2000/03/11 01:11:24  leigh
  Reading instrument and track names in level 1 MIDI files now are stored in the MKPart infoNote

  Revision 1.8  2000/02/11 22:52:39  leigh
  Fixed memory leak reading scorefiles

  Revision 1.7  2000/02/08 04:15:18  leigh
  Added +midifileExtension

  Revision 1.6  2000/02/08 03:16:05  leigh
  Improved MIDI file writing, generating separate tempo track with Part info entries

  Revision 1.5  1999/10/10 01:10:22  leigh
  MIDI mode messages read from SMF0 files now receive MK_midiChan parameters so MKScores read from SMF1 or SMF0 behave the same.

  Revision 1.4  1999/09/04 22:02:18  leigh
  Removed mididriver source and header files as they now reside in the MKPerformMIDI framework

  Revision 1.3  1999/08/06 00:38:10  leigh
  converted strtols to NSScanners

  Revision 1.2  1999/07/29 01:16:42  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  12/8/89/daj  - Fixed bug in midi-file reading -- first part was being
                 initialized to a bogus info object. 
  12/15/89/daj - Changed how Midi channel is encoded and written so that the 
                 information is not lost when reading/writing a format 1
		 file.
  12/20/89/daj - Added writeOptimizedScorefile: and 
                 writeOptimizedScorefileStream:
  01/08/90/daj - Added clipping of firstTimeTag in readScorefile().
  02/26-28/90/daj - Changes to accomodate new way of doing midiFiles. 
                 Added midifile sys excl and meta-event support.
  03/13/90/daj - Changes for new categories for private methods.
  03/19/90/daj - Changed to use MKGetNoteClass(), MKGetPartClass().
  03/21/90/daj - Added archiving. 
  03/27/90/daj - Added 10 new scorefile methods to make the scorefile and
                 midifile cases look the same. *SIGH*
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/23/90/daj - Changes to make it a shlib and to make header files more
                 modular.
  05/16/90/daj - Got rid of the "fudgeTime" kludge in the MIDI file reader,
                 now that the Part object's been fixed to insure correct
		 ordering. Added check for clas of Part class in setPart:.
  06/10/90/daj - Fixed bug in writing of scorefiles.
  07/24/90/daj - Removed unneeded copy of Note from readScorefile. Then
                 added it back because it actually sped things up.
  08/31/90/daj - Added import of stdlib.h and define of NOT_YET
  09/26/90/daj - Fixed minor bug in freeNotes.
  12/18/90/daj - Added [parts free] to -free to fix memory leak.
                 Added MKMIDIFileEndReading() calls to fix memory leak.
  07/08/91/daj - Was off by one in putSysExcl.
  17/01/92/daj - Fixed midifile tempo bug.
   9/03/92/daj - Fixed writing of scorefiles to preserve Part Note List 
                 ordering.
  17/06/92/daj - When writing midifile, changed it so that if there is no
                 title: parameter, the part name of the first part is used.
  19/10/92/daj - Fixed a bug in scorefile merge function.
  11/17/92/daj - Minor change to shut up compiler warnings.
  11/18/92/daj - Removed bogus comment.
   6/26/93/daj - Added replacePart:with: method.
*/

#import <stdlib.h>
#import "_musickit.h"  
#import "PartPrivate.h"
#import "NotePrivate.h"
#import "_midi.h"
#import "midifile.h"
#import "tokens.h"
#import "_error.h"

#import "ScorePrivate.h"
@implementation MKScore

#define READIT 0
#define WRITEIT 1

/* Creation and freeing ------------------------------------------------ */

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKScore class])
      return;
    [MKScore setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    _MKCheckInit();
    return;
}

+ score
  /* Create a new instance and sends [self init]. */
{
    self = [self allocWithZone:NSDefaultMallocZone()];
    [self init];
//    [self initialize]; /* Avoid breaking pre-2.0 apps. */ //sb: removed
    return [self autorelease];
}

-init
  /* TYPE: Creating and freeing a Part
   * Initializes the receiver:
   *
   *  * Creates a new notes collection.
   * 
   * Sent by the superclass upon creation;
   * you never invoke this method directly.
   * An overriding subclass method should send [super initialize]
   * before setting its own defaults. 
   */
{
    parts = [[NSMutableArray alloc] init];
    return self;
}

-freeNotes
    /* Frees the notes contained in the parts. Does not freeParts
       nor does it free the receiver. Implemented as 
       [parts makeObjectsPerformSelector:@selector(freeNotes)];
       Also frees the receivers info.
       */
{
    [parts makeObjectsPerformSelector:@selector(freeNotes)];
    [info release];
    info = nil;
    return self;
}

-freeParts
    /* frees contained parts and their notes. Does not free the
       receiver. Use -free to free, all at once,
       parts, receiver and notes. Does not free Score's info. */
{
    [parts makeObjectsPerformSelector:@selector(_unsetScore)];
    [parts removeAllObjects];          /* Frees Parts. */
//    [parts removeAllObjects]; //sb: why was this done twice?
    return self;
}

-freePartsOnly
    /* Frees contained Parts, but not their notes. It is illegal
       to free a part which is performing or which has a PartSegment which
       is performing. Implemented as 
       [parts makeObjectsPerformSelector:@selector(freeSelfOnly)];
       Returns self. */
{
    [parts makeObjectsPerformSelector:@selector(_unsetScore)];
    [parts makeObjectsPerformSelector:@selector(freeSelfOnly)];
    [parts removeAllObjects];
    return self;
}

-freeSelfOnly
    /* Frees receiver. Does not free contained Parts nor their notes.  
       Does not free info.
    */
{
    [parts makeObjectsPerformSelector:@selector(_unsetScore)];
    [parts release];
//    [super release];
    return nil; //sb: nil to correspond to old -free return value.
}

- (void)dealloc
  /* Frees receiver, parts and Notes, including info. */
{
    [self freeParts];
    [info release];
    [parts release];
    [super dealloc];
}

- (void)removeAllObjects
  /* TYPE: Modifying; Removes the receiver's Parts.
   * Removes the receiver's Parts but doesn't free them.
   * Returns the receiver.
   */
{
    [parts makeObjectsPerformSelector:@selector(_unsetScore)];
    [parts removeAllObjects];
    return;
}

/* Reading Scorefiles ------------------------------------------------ */

static id readScorefile(); /* forward ref */

#if 0
-readScorefileIncrementalStream:(NSMutableData *)aStream
  /* Read and execute the next statement from the specified scorefile stream.
     You may repeatedly send this message until the stream reaches EOF or 
     an END statement is parsed.
     */
{
    /* Need to keep a table mapping streams to _MKScorefileInStructs or could
       have this method return a 'handle' */
    /* FIXME */
    [NSException raise:NSInvalidArgumentException format:@"*** Method not implemented: %s", sel_getName(_cmd)];
}
#endif

-readScorefile:(NSString *)fileName 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
 timeShift:(double)timeShift
  /* Read from scoreFile to receiver, creating new Parts as needed
       and including only those notes between times firstTimeTag to
       time lastTimeTag, inclusive. Note that the TimeTags of the
       notes are not altered from those in the file. I.e.
       the first note's TimeTag will be greater than or equal to
       firstTimeTag.
       Merges contents of file with current Parts when the Part
       name found in the file is the same as one of those in the
       receiver. 
       Returns self or nil if file not found or the parse was aborted
       due to errors. */
{
    NSData *stream;
    id rtnVal;
    stream = _MKOpenFileStreamForReading(fileName,
			       _MK_BINARYSCOREFILEEXT,NO);
    if (!stream)
      stream = _MKOpenFileStreamForReading(fileName,_MK_SCOREFILEEXT, YES);
    if (!stream)
    	return nil;
    rtnVal = readScorefile(self, stream, firstTimeTag, lastTimeTag, timeShift, fileName);
//    [stream release]; //sb: no. The above functions are autoreleased.
    return rtnVal;
 }

-readScorefileStream:(NSMutableData *)stream 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
 timeShift:(double)timeShift
    /* Read from scoreFile to receiver, creating new Parts as needed
       and including only those notes between times firstTimeTag to
       time lastTimeTag, inclusive. Note that the TimeTags of the
       notes are not altered from those in the file. I.e.
       the first note's TimeTag will be greater than or equal to
       firstTimeTag.
       Merges contents of file with current Parts when the Part
       name found in the file is the same as one of those in the
       receiver. 
       Returns self or nil if the parse was aborted due to errors. 
       It is the application's responsibility to close the stream after calling
       this method.
       */
{
    return readScorefile(self,stream,firstTimeTag,lastTimeTag,timeShift,NULL);
}
-(oneway void)release
{[super release];}
/* Scorefile reading "convenience" methods  --------------------------- */

-readScorefile:(NSString *)fileName     
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
{
    return [self readScorefile:fileName firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag timeShift:0.0];
}

-readScorefileStream:(NSMutableData *)stream
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
{
    return [self readScorefileStream:stream firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag timeShift:0.0];
}

-readScorefile:(NSString *)fileName     
{
    return [self readScorefile:fileName firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

-readScorefileStream:(NSMutableData *)stream     
{
    return [self readScorefileStream:stream firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

/* Writing Scorefiles --------------------------------------------------- */

-_noteTagRangeLowP:(int *)lowTag highP:(int *)highTag
    /* Returns by reference the lowest and highest noteTags in receiver. */
{
    int noteTag,ht,lt;
    id notes;
    unsigned n = [parts count],m,i,j;
    ht = 0;
    lt = MAXINT;
    for (i = 0; i < n; i++) {
        notes = [[parts objectAtIndex:i] notesNoCopy];
        m = [notes count];
        for (j = 0; j < m; j++) {
            noteTag = [[notes objectAtIndex:j] noteTag];
            if (noteTag != MAXINT) {
                ht = MAX(ht,noteTag);
                lt = MIN(lt,noteTag);
            }
        }
    }
    *highTag = ht;
    *lowTag = lt;
    return self;
}

static void writeNotes();

-_writeScorefileStream:(NSMutableData *)aStream firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift
 binary:(BOOL)isBinary
  /* Same as writeScorefileStream: but only writes notes within specified
     time bounds. */
{
    _MKScoreOutStruct * p;
    int lowTag, highTag;
    if (!aStream) 
      return nil;
    p = _MKInitScoreOut(aStream,self,info,timeShift,NO,isBinary);
    [self _noteTagRangeLowP:&lowTag highP:&highTag];
    if (lowTag <= highTag) {
	if (isBinary) {
	    _MKWriteShort(aStream,_MK_noteTagRange);
	    _MKWriteInt(aStream,lowTag);
	    _MKWriteInt(aStream,highTag);
	}
	else 
            [aStream appendData:[[NSString stringWithFormat:@"%s = %d %s %d;\n", 
                      _MKTokNameNoCheck(_MK_noteTagRange), lowTag,
		      _MKTokNameNoCheck(_MK_to), highTag] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    }
    writeNotes(aStream, self, p, firstTimeTag, lastTimeTag, timeShift);
    _MKFinishScoreOut(p,YES);            /* Doesn't close aStream. */
    return self;
}

-_writeScorefile:(NSString *)aFileName firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift 
 binary:(BOOL)isBinary
{
    NSMutableData *stream = [NSMutableData data];
    BOOL success;

    [self _writeScorefileStream:stream firstTimeTag:firstTimeTag 
          lastTimeTag:lastTimeTag timeShift:timeShift binary:isBinary];

    success = _MKOpenFileStreamForWriting(aFileName,
                               (isBinary) ? _MK_BINARYSCOREFILEEXT : _MK_SCOREFILEEXT,
                               stream, YES);
    // [stream release]; // this should be ok to do, but somehow isn't - indicative of a bigger leak elsewhere.
    if (!success) {
        _MKErrorf(MK_cantCloseFileErr, aFileName);
        return nil;
    }
    else
        return self;
}

-writeScorefile:(NSString *)aFileName 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
 timeShift:(double)timeShift
  /* Write scorefile to file with specified name within specified
     bounds. */
{
    return [self _writeScorefile:aFileName 
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:timeShift
	  binary:NO];
}

-writeScorefileStream:(NSMutableData *)aStream 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
 timeShift:(double)timeShift
  /* Same as writeScorefileStream: but only writes notes within specified
     time bounds. */
{
    return [self _writeScorefileStream:aStream
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:timeShift binary:NO];
}

-writeOptimizedScorefile:(NSString *)aFileName 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
 timeShift:(double)timeShift
  /* Write scorefile to file with specified name within specified
     bounds. */
{
    return [self _writeScorefile:aFileName 
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:timeShift
	  binary:YES];
}

-writeOptimizedScorefileStream:(NSMutableData *)aStream 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
 timeShift:(double)timeShift
  /* Same as writeScorefileStream: but only writes notes within specified
     time bounds. */
{
    return [self _writeScorefileStream:aStream
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:timeShift binary:YES];
}

/* Scorefile writing "convenience methods" ------------------------ */

-writeScorefile:(NSString *)aFileName 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
{
    return [self _writeScorefile:aFileName 
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:0.0
	  binary:NO];
}

-writeScorefileStream:(NSMutableData *)aStream 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
{
    return [self _writeScorefileStream:aStream
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:0.0 binary:NO];
}

-writeScorefile:(NSString *)aFileName 
{
    return [self writeScorefile:aFileName firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

-writeScorefileStream:(NSMutableData *)aStream
{
    return [self writeScorefileStream:aStream firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

-writeOptimizedScorefile:(NSString *)aFileName 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
{
    return [self _writeScorefile:aFileName 
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:0.0
	  binary:YES];
}

-writeOptimizedScorefileStream:(NSMutableData *)aStream 
 firstTimeTag:(double)firstTimeTag 
 lastTimeTag:(double)lastTimeTag 
{
    return [self _writeScorefileStream:aStream
	  firstTimeTag:firstTimeTag
	  lastTimeTag:lastTimeTag
	  timeShift:0.0 binary:YES];
}

-writeOptimizedScorefile:(NSString *)aFileName 
{
    return [self writeOptimizedScorefile:aFileName firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

-writeOptimizedScorefileStream:(NSMutableData *)aStream
{
    return [self writeOptimizedScorefileStream:aStream firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}


/* Writing MIDI files ------------------------------------------------ */

static BOOL midifilesEvaluateTempo = YES;

+setMidifilesEvaluateTempo:(BOOL)yesOrNo
{
    midifilesEvaluateTempo = yesOrNo;
    return self;
}

+(BOOL)midifilesEvaluateTempo
{
    return midifilesEvaluateTempo;
}

static int timeInQuanta(void *p,double timeTag)
{
    return MKMIDI_DEFAULTQUANTASIZE * timeTag + .5; /* .5 for rounding */
}

static void putMidi(struct __MKMidiOutStruct *ptr)
{
    MKMIDIFileWriteEvent(ptr->_midiFileStruct,
			  timeInQuanta(ptr->_midiFileStruct,ptr->_timeTag),
			  ptr->_outBytes,
			  &(ptr->_bytes[0]));
}

static void putSysExcl(struct __MKMidiOutStruct *ptr,NSString *sysExclString)
{
    const char *sysExclStr = [sysExclString cString];
    unsigned char *buffer = alloca(strlen(sysExclStr)); /* More than enough */
    unsigned char *bufptr = buffer;
    int len;
    unsigned char c;
    c = _MKGetSysExByte(&sysExclStr);
    if (c == MIDI_SYSEXCL) 
      c = _MKGetSysExByte(&sysExclStr);
    *bufptr++ = c;
    while (*sysExclStr && c != MIDI_EOX) 
      *bufptr++ = c = _MKGetSysExByte(&sysExclStr);
    if (c != MIDI_EOX) 
      *bufptr++ = MIDI_EOX;
    len = bufptr - buffer;
    MKMIDIFileWriteSysExcl(ptr->_midiFileStruct, timeInQuanta(ptr->_midiFileStruct,ptr->_timeTag), len, buffer);
}

static void sendBufferedData(struct __MKMidiOutStruct *ptr)
    /* Dummy function. (Since we don't need an extra level of buffering
       here */
{

}

// return the extension of MIDI files for pathnames
+ (NSString *) midifileExtension
{
    return [[_MK_MIDIFILEEXT retain] autorelease];
}

#define T timeInQuanta(fileStructP,(t+timeShift))
#define STRPAR MKGetNoteParAsStringNoCopy
#define INTPAR MKGetNoteParAsInt
#define DOUBLEPAR MKGetNoteParAsDouble
#define INRANGE(_par) (_par >= 128 && _par <= 159)	
#define PRESENT(_par) (parBits & (1<<(_par - 128)))
#define WRITETEXT(_meta,_par) MKMIDIFileWriteText(fileStructP,T,(_meta),STRPAR(curNote,(_par)))

/* Write a single MKNote to the MIDI file, tagged appropriately */
static void writeNoteToMidifile(_MKMidiOutStruct *p, void *fileStructP, MKNote *curNote, double timeShift,
 int defaultChan)
{
    int chan;
    unsigned parBits;
    double t;

    /* First handle normal midi */
    chan = INTPAR(curNote,MK_midiChan);
    t = [curNote timeTag];
    _MKWriteMidiOut(curNote, t+timeShift, ((chan == MAXINT) ? defaultChan : chan), p, nil);
    /* Now check for meta-events. */
    parBits= [curNote parVector:4];
    if (parBits) {
        if (PRESENT(MK_text))
          WRITETEXT(MKMIDI_text,MK_text);
        if (PRESENT(MK_title))
          WRITETEXT(MKMIDI_sequenceOrTrackName,MK_title);
        if (PRESENT(MK_instrumentName))
          WRITETEXT(MKMIDI_instrumentName,MK_instrumentName);
        if (PRESENT(MK_lyric))
          WRITETEXT(MKMIDI_lyric,MK_lyric);
        if (PRESENT(MK_cuePoint))
          WRITETEXT(MKMIDI_cuePoint,MK_cuePoint);
        if (PRESENT(MK_marker))
          WRITETEXT(MKMIDI_marker,MK_marker);
        if (PRESENT(MK_timeSignature)) {
            unsigned int nn, dd, cc, bb, allData;
            NSString *timeSigString = STRPAR(curNote, MK_timeSignature);
            NSScanner *timeSigScan;
            if(timeSigString == nil) {
                allData = 0;
            }
            else {
                timeSigScan = [NSScanner scannerWithString: timeSigString];
                [timeSigScan scanInt: &nn];  // numerator
                [timeSigScan scanInt: &dd];  // denominator
                [timeSigScan scanInt: &cc];  // ?? to check against SMF spec
                [timeSigScan scanInt: &bb];  // ?? to check against SMF spec
                allData = (nn << 24) | (dd << 16) | (cc << 8) | bb;
            }
            MKMIDIFileWriteSig(fileStructP,T,MKMIDI_timeSig, allData);
        }
        if (PRESENT(MK_keySignature)) {
            NSString *keySigString = STRPAR(curNote,MK_keySignature);
            NSScanner *keySigScan;
            unsigned int sf, mi, allData;
            if(keySigString == nil) {
                allData = 0;
            }
            else {
                keySigScan = [NSScanner scannerWithString: keySigString];
                [keySigScan scanInt: &sf];  // ??
                [keySigScan scanInt: &mi];  // ??
                allData = (sf << 8) | mi;
            }
            MKMIDIFileWriteSig(fileStructP, T, MKMIDI_keySig, allData);
        }
        if (PRESENT(MK_tempo))
          MKMIDIFileWriteTempo(fileStructP,T, DOUBLEPAR(curNote,MK_tempo));
    }
}


-writeMidifileStream:(NSMutableData *)aStream firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift
    /* Write midi on aStream. */
{
    _MKMidiOutStruct *p;
    void *fileStructP;
    double t = 0;
    MKNote *anInfo = nil;
    NSString *title = nil;
    int defaultChan;
    double tempo;
    MKPart *aPart, *curPart;
    NSArray *notes;
    MKNote *curNote;
    unsigned i,j, numOfParts, numOfNotes;

    NSAssert((INRANGE(MK_tempo) && INRANGE(MK_lyric) &&
                INRANGE(MK_cuePoint) && INRANGE(MK_marker) &&
                INRANGE(MK_timeSignature) &&
                INRANGE(MK_keySignature)), @"Illegal use of parVector.");

    if (!aStream) 
        return nil;
    tempo = 60;
    if (info) {
	if ([info isParPresent:MK_title])
	  title = [info parAsStringNoCopy:MK_title];
	if (title == nil) { /* Try using tempo track part name */
	    id aPart = [parts objectAtIndex:0];
	    if (aPart)
	      title = (NSString *) MKGetObjectName(aPart);
	}
	if ([info isParPresent: MK_tempo])
	  tempo = [info parAsDouble: MK_tempo];
    }
    p = _MKInitMidiOut();
    if (!(fileStructP = MKMIDIFileBeginWriting(aStream, 1, title, [MKScore midifilesEvaluateTempo]))) {
	_MKFinishMidiOut(p);
	return nil;
    }
    else p->_midiFileStruct = fileStructP; /* Needed so functions called from
					      _MKWriteMidiOut can find 
					      struct */
    numOfParts = [parts count];
    if (numOfParts == 0) {
	MKMIDIFileEndWriting(fileStructP);
	_MKFinishMidiOut(p);
	return self;
    }
    p->_owner = self;
    p->_putSysMidi = putMidi;
    p->_putChanMidi = putMidi;
    p->_putSysExcl = putSysExcl;
    p->_sendBufferedData = sendBufferedData;
    MKMIDIFileWriteTempo(fileStructP,0,tempo);
    if (info) {
        if ([info isParPresent:MK_copyright])
            MKMIDIFileWriteText(fileStructP, 0, MKMIDI_copyright, STRPAR(info,MK_copyright));
        if ([info isParPresent:MK_text])
            MKMIDIFileWriteText(fileStructP, 0, MKMIDI_text, STRPAR(info,MK_text));
	if ([info isParPresent:MK_sequence])
	    MKMIDIFileWriteSequenceNumber(fileStructP, INTPAR(info,MK_sequence));
	if ([info isParPresent:MK_smpteOffset]) {
            unsigned int hr, mn, sec, fr, ff;
            NSString *smpteString = STRPAR(info, MK_smpteOffset);
            NSScanner *smpteScan;
            if(smpteString == nil) {
                hr = mn = sec = fr = ff = 0;
            }
            else {
                smpteScan = [NSScanner scannerWithString: smpteString];
                [smpteScan scanInt: &hr];
                [smpteScan scanInt: &mn];
                [smpteScan scanInt: &sec];
                [smpteScan scanInt: &fr];
                [smpteScan scanInt: &ff];
            }
            MKMIDIFileWriteSMPTEoffset(fileStructP,hr,mn,sec,fr,ff);
	}
    }
    MKMIDIFileEndWritingTrack(fileStructP, lastTimeTag < MK_ENDOFTIME ? lastTimeTag : 0); // 0 end time is a little kludgy

    for (i = 0; i < numOfParts; i++) {
        curPart = [parts objectAtIndex:i];
	if ([curPart noteCount] == 0)
            continue;
        MKMIDIFileBeginWritingTrack(fileStructP, (NSString *) MKGetObjectName(curPart));
	aPart = [curPart copy]; /* Need to copy to split notes. */
	[aPart splitNotes]; 
	[aPart sort];
	notes = [aPart notesNoCopy];
	anInfo = [aPart infoNote];
	defaultChan = 1;
	if (anInfo) {
            if ([anInfo isParPresent: MK_midiChan]) {
                defaultChan = [anInfo parAsInt: MK_midiChan];
	    }
	    // If the time of the part info note has not been set, it becomes 0,
            // otherwise use whatever is there, hopefully user knows best.
            if([anInfo timeTag] >= MK_ENDOFTIME) {
                [anInfo setTimeTag: 0];
            }
            writeNoteToMidifile(p, fileStructP, anInfo, timeShift, defaultChan);
	}
        numOfNotes = [notes count];
        for (j = 0; j < numOfNotes; j++) {
            curNote = [notes objectAtIndex:j];
            if ((t = [curNote timeTag]) >= firstTimeTag) {
                if (t > lastTimeTag)
                    break;
                else {
                    writeNoteToMidifile(p, fileStructP, curNote, timeShift, defaultChan);
		}
	    }
        }
	MKMIDIFileEndWritingTrack(fileStructP,T);
	[aPart release];
    }
    MKMIDIFileEndWriting(fileStructP);
    _MKFinishMidiOut(p);
    return self;
}
     
-writeMidifile:(NSString *)aFileName firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag timeShift:(double)timeShift
   	/* Write midi to file with specified name. */
{
    NSMutableData *stream = [NSMutableData data];
    BOOL success;

    [self writeMidifileStream: stream
                 firstTimeTag: firstTimeTag 
                  lastTimeTag: lastTimeTag
                    timeShift: timeShift];
    success = _MKOpenFileStreamForWriting(aFileName, [MKScore midifileExtension], stream, YES);

    // [stream release]; // this should be ok to do, but somehow isn't - indicative of a bigger leak elsewhere.
    if (!success) {
        _MKErrorf(MK_cantCloseFileErr, aFileName);
        return nil;
    }
    else {
        return self;
    }
}

/* Midi file writing "convenience methods" --------------------------- */

-writeMidifileStream:(NSMutableData *)aStream 
 firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag
{
    return [self writeMidifileStream:aStream firstTimeTag:firstTimeTag 
	  lastTimeTag:lastTimeTag timeShift:0.0];
}

-writeMidifile:(NSString *)aFileName 
 firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag
{
    return [self writeMidifile:aFileName firstTimeTag:firstTimeTag 
	  lastTimeTag:lastTimeTag timeShift:0.0];
}

-writeMidifileStream:(NSMutableData *)aStream 
{
    return [self writeMidifileStream:aStream firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME];
}

-writeMidifile:(NSString *)aFileName
{
    return [self writeMidifile:aFileName firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME];
}
  

/* Reading MIDI files ---------------------------------------------- */

- readMidifile:(NSString *)aFileName firstTimeTag:(double) firstTimeTag
    lastTimeTag:(double) lastTimeTag timeShift:(double)timeShift
{
    id rtnVal;
    id stream;/*sb: could be NSMutableData or NSData */

    stream = _MKOpenFileStreamForReading(aFileName, [MKScore midifileExtension], YES);
    if (!stream)
       return nil;
    rtnVal = [self readMidifileStream:stream firstTimeTag:firstTimeTag 
	    lastTimeTag:lastTimeTag timeShift:timeShift];
//    [stream release]; //sb: no. _MKOpenFileStreamForReading autoreleases.
    return rtnVal;
}

static void writeDataAsNumString(id aNote,int par,unsigned char *data,
				 int nBytes)
{
#   define ROOM 4 /* Up to 3 digits per number followed by space */
    int size = nBytes * ROOM;
    char *str = malloc(size);//sb: was alloca
    NSString * retStr;
    int i,j;
    for (i=0; i<nBytes; i++) 
      sprintf(&(str[i * ROOM]),"%-3d ",j = data[i+1]);
    str[size - 1] = '\0'; /* Write over last space. */
    retStr = [NSString stringWithCString:str];
    MKSetNoteParToString(aNote,par,retStr);
    free(str);
}

- readMidifileStream:(NSMutableData *) aStream firstTimeTag:(double) firstTimeTag
    lastTimeTag:(double) lastTimeTag timeShift:(double)timeShift
{
    int fileFormatLevel;
    int trackCount;
    double timeFactor,t,prevT,lastTempoTime = -1;
    id              aPart;
    int             i;
    register id     aNote;
#   define MIDIPARTS (16 + 1)
    _MKMidiInStruct *midiInPtr;
    id *midiParts,*curPart;
    BOOL trackInfoMidiChanWritten = NO;
    void *fileStructP;
    int *quanta;
    BOOL *metaevent;
    int *nData;
    unsigned char **data;
    if (!(fileStructP = MKMIDIFileBeginReading(aStream,&quanta,&metaevent,&nData,&data,[MKScore midifilesEvaluateTempo])))
      return nil;
#   define DATA (*data)
    if (!MKMIDIFileReadPreamble(fileStructP,&fileFormatLevel,&trackCount)) 
      return nil;
    if (fileFormatLevel == 0)
      trackCount = MIDIPARTS;
    else trackCount++; 	/* trackCount doesn't include the 'tempo' track so
			   we increment here */
    if (!(midiInPtr = _MKInitMidiIn())) {
	MKMIDIFileEndReading(fileStructP);
	return nil;
    }
    _MK_MALLOC(midiParts,id,trackCount);
    curPart = midiParts;
    for (i=0; i<trackCount; i++) { 
	aPart = [MKGetPartClass() new];
	aNote = [MKGetNoteClass() new];
	if ((fileFormatLevel == 0) && (i != 0))
	  [aNote setPar:MK_midiChan toInt:i];
	[aPart setInfoNote:aNote];
	[self addPart:aPart];
	*curPart++ = aPart;
    }
    lastTimeTag = MIN(lastTimeTag, MK_ENDOFTIME);
    timeFactor = 1.0/(double)MKMIDI_DEFAULTQUANTASIZE;
    /* In format 0 files, *curPart will be the _MK_MIDISYS part. */
    curPart = midiParts;
#   define FIRSTTRACK (MKPart *)*midiParts
#   define CURPART (MKPart *)*curPart
    prevT = -1;
    if (!info) 
      info = [MKGetNoteClass() new];
#   define SHORTDATA ((int)(*((short *)&(DATA[1]))))
#   define LONGDATA ((int)(*((int *)&(DATA[1]))))
#   define STRINGDATA ((char *)&(DATA[1]))
#   define LEVEL0 (fileFormatLevel == 0)
#   define LEVEL1 (fileFormatLevel == 1)
#   define LEVEL2 (fileFormatLevel == 2)
    if (LEVEL2) /* Sequences numbered consecutively from 0 by default. */
      MKSetNoteParToInt([FIRSTTRACK infoNote],MK_sequence,0);
    while (MKMIDIFileReadEvent(fileStructP)) {
	if (*metaevent) {
	    /* First handle meta-events that are Part or Score info
	       parameters. We never want to skip these. */
	    switch (DATA[0]) { 
	    case MKMIDI_sequenceNumber:
		MKSetNoteParToInt(LEVEL2 ? [CURPART infoNote] : info,
				  MK_sequence,SHORTDATA);
		break;
	    case MKMIDI_smpteOffset: 
		writeDataAsNumString(LEVEL2 ? [CURPART infoNote] : info,
				     MK_smpteOffset,DATA,5);
		break;
	    case MKMIDI_sequenceOrTrackName:
                /* Check if it is the first part. There is no MK_title in level 2 files, since
                   the title is merely the name of the first sequence. */
		if ((curPart == midiParts) && !LEVEL2) 
                   MKSetNoteParToString(info, MK_title, [NSString stringWithCString:STRINGDATA]);
		/* In level 1 files, we name the current part with the
		   title. Note that we do this even if the name is a 
		   sequence name rather than a track name. In level 0 
		   files, we do not name the part. */
                if(LEVEL1)
                    MKSetNoteParToString([CURPART infoNote], MK_title, [NSString stringWithCString:STRINGDATA]);
		if (fileFormatLevel != 0)
                    MKNameObject([NSString stringWithCString:STRINGDATA], *curPart);
		break;
	    case MKMIDI_copyright:
                MKSetNoteParToString(info,MK_copyright,[NSString stringWithCString:STRINGDATA]);
		break;
            case MKMIDI_instrumentName:
		/* An instrument name is the sort of thing you need in a part info note, but the strict definition of
                   the SMF spec allows you to rename the track at different time points, why? It would have been better
                   to define more tracks, each with a separate instrument. In that rather wierd case,
                   this code is wrong as it will take the last instrument name used as the info note. */
                MKSetNoteParToString(LEVEL1 ? [CURPART infoNote] : info,
                                     MK_instrumentName, [NSString stringWithCString:STRINGDATA]);
	    default:
		break;
	    }
	}
	t = *quanta * timeFactor;
	/* FIXME Should do something better here. (need to change
	   Part to allow ordering spec for simultaneous notes.) */
	if (t < firstTimeTag) 
	  continue;
	if (t > lastTimeTag)
	  if (LEVEL0)
	    break; /* We know we're done */
	  else continue;
	if (*metaevent) {
	    /* Now handle meta-events that can be in regular notes. These
	       are skipped when out of the time window, as are regular 
	       MIDI messages. */
	    aNote = [MKGetNoteClass() noteWithTimeTag:t+timeShift];
	    switch (DATA[0]) { 
	      case MKMIDI_trackChange: 
		/* Sent at the end of every track. May be missing from the
		   end of the file. */
		if (t > (prevT + _MK_TINYTIME)) {
		    /* We've got a significant trackChange time. */
		    MKSetNoteParToString(aNote,LEVEL1 ? MK_track : MK_sequence,
					 @"end");
		    [CURPART addNote:aNote];    /* Put an end-of-track mark */
		}
		else [aNote release];
		curPart++;
		if (curPart >= midiParts + trackCount)
		  goto outOfLoop;
		trackInfoMidiChanWritten = NO;
		if (LEVEL1) /* Other files have no "tracks" */
		  MKSetNoteParToInt([CURPART infoNote],MK_track,SHORTDATA);
		else if (LEVEL2) {
		    /* Assign ascending sequence number parameters */
#		    define OLDNUM \
		       MKGetNoteParAsInt([(*(curPart-1)) infoNote],MK_sequence)
		    MKSetNoteParToInt([CURPART infoNote],MK_sequence,OLDNUM + 1);
		}
		lastTempoTime = -1;
		prevT = -1;
		continue; /* Don't clobber prevT below */
	      case MKMIDI_tempoChange: 
		/* For MK-compatibility, tempo is duplicated in info
		   Notes, but only if it's at time 0 in file.    */
		if (t == 0) 
		  if (lastTempoTime == 0) {
		      /* Supress duplicate tempi, which can arise because of 
			 the way we duplicate tempo in info */
		      [aNote release];
		      break;
		  }
		  else { /* First setting of tempo for current track. */
		      id theInfo = LEVEL2 ? [CURPART infoNote] : info;
		      if (!MKIsNoteParPresent(theInfo,MK_tempo)) 
			MKSetNoteParToDouble(theInfo,MK_tempo,
			 [MKScore midifilesEvaluateTempo] ? 60 : 60000000.0/LONGDATA);
   		  }
		lastTempoTime = t;
		if(![MKScore midifilesEvaluateTempo]) {
		   MKSetNoteParToDouble(aNote,MK_tempo,60000000.0/LONGDATA);
		   [(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
		}
		break;
	      case MKMIDI_text:
	      case MKMIDI_cuePoint:
	      case MKMIDI_lyric: 
		MKSetNoteParToString(aNote,
				     ((DATA[0] == MKMIDI_text) ? MK_text :
				      (DATA[0] == MKMIDI_lyric) ? MK_lyric : MK_cuePoint),
                                     [NSString stringWithCString:STRINGDATA]);
		[CURPART addNote:aNote];
		break;
	      case MKMIDI_marker:
                  MKSetNoteParToString(aNote,MK_marker,[NSString stringWithCString:STRINGDATA]);
		[(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
		break;
	      case MKMIDI_timeSig:
		writeDataAsNumString(aNote,MK_timeSignature,DATA,4);
		[(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
		break;
	      case MKMIDI_keySig: {
		  char str[5];
		  /* Want sf signed, hence (char) cast  */
		  int x = (int)((char)DATA[2]); /* sf */
		  sprintf(&(str[0]),"%-2d ",x);
		  x = (int)DATA[3]; /* mi */
		  sprintf(&(str[3]),"%d",x);
		  str[4] = '\0';
                  MKSetNoteParToString(aNote,MK_keySignature,[NSString stringWithCString:str]);
		  [(LEVEL2 ? FIRSTTRACK : CURPART) addNote:aNote];
		  break;
	      }
	      default:
		[aNote release];
		break;
	    }
	} 
	else { /* Standard MIDI, not sys excl */
	    switch (*nData) {
	      case 3:
		midiInPtr->_dataByte2 = DATA[2];
		/* No break */
	      case 2:
		midiInPtr->_dataByte1 = DATA[1];
		/* No break */
	      case 1:
		/* Status passed directly below. */
		break;
	      default: { /* Sys exclusive */
		  unsigned j;
		  char *str = alloca(*nData * 3); /* 3 chars per byte */
		  char *ptr = str;
		  unsigned char *p = *data;
		  unsigned char *endP = p + *nData;
		  sprintf(ptr,"%-2x",j = *p++);
		  ptr += 2;
		  while (p < endP) {
		      sprintf(ptr,",%-2x",j = *p++);
		      ptr += 3;
		  }
		  *ptr = '\0';
		  aNote = [MKGetNoteClass() noteWithTimeTag:t+timeShift];
                  MKSetNoteParToString(aNote,MK_sysExclusive,[NSString stringWithCString:str]); /* copy */
		  [CURPART addNote:aNote];
		  continue;
	      }
	    }
	    aNote = _MKMidiToMusicKit(midiInPtr,DATA[0]);
	    if (aNote) { /* _MKMidiToMusicKit can omit Notes sometimes. */
		[aNote setTimeTag:t+timeShift];
		/* Need to copy Note because it's "owned" by midiInPtr. */
		if (LEVEL0) {
		  // LMS even if aNote has come from a Level0 file it should retain midiChannels from mode messages.
                  if (midiInPtr->chan != _MK_MIDISYS)   
                    MKSetNoteParToInt(aNote, MK_midiChan, midiInPtr->chan);
		  [midiParts[midiInPtr->chan] addNoteCopy:aNote];
		}
		else {
		    if (!trackInfoMidiChanWritten && midiInPtr->chan != _MK_MIDISYS) {
			trackInfoMidiChanWritten = YES;
			MKSetNoteParToInt([CURPART infoNote], MK_midiChan, midiInPtr->chan);
			/* Set Part's chan to chan of first note in track. */
		    }
		    aNote = [CURPART addNoteCopy:aNote];
		    /* aNote is new one */
		    if (midiInPtr->chan != _MK_MIDISYS)
		      MKSetNoteParToInt(aNote,MK_midiChan,midiInPtr->chan);
		}
	    }
	} /* End of standard MIDI block */
	prevT = t;	 
    } /* End of while loop */
  outOfLoop:
    free(midiParts);
    _MKFinishMidiIn(midiInPtr);
    MKMIDIFileEndReading(fileStructP);
    return self;
}

/* Midifile reading "convenience methods"------------------------ */

-readMidifile:(NSString *)fileName
 firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag
{
    return [self readMidifile:fileName firstTimeTag:firstTimeTag 
	  lastTimeTag:lastTimeTag timeShift:0.0];
}

-readMidifileStream:(NSMutableData *)aStream
 firstTimeTag:(double)firstTimeTag
 lastTimeTag:(double)lastTimeTag
{
    return [self readMidifileStream:aStream firstTimeTag:firstTimeTag 
	  lastTimeTag:lastTimeTag timeShift:0.0];
}

-readMidifile:(NSString *)fileName
  /* Like readMidifile:firstTimeTag:lastTimeTag:, 
     but always reads the whole file. */
{
    return [self readMidifile:fileName firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

-readMidifileStream:(NSMutableData *)aStream
    /* Like readMidifileStream:firstTimeTag:lastTimeTag:, 
       but always reads the whole file. */
{
    return [self readMidifileStream:aStream firstTimeTag:0.0 
	  lastTimeTag:MK_ENDOFTIME timeShift:0.0];
}

/* Number of notes and parts ------------------------------------------ */

-(unsigned)partCount
{
    return [parts count];
}

-(unsigned)noteCount
    /* Returns the total number of notes in all the contained Parts. */
{
    unsigned n = [parts count], i;
    unsigned numNotes = 0;
    for (i = 0; i < n; i++)
        numNotes += [[parts objectAtIndex:i] noteCount];

    return numNotes;
}

/* Modifying the set of Parts. ------------------------------- */

-replacePart:(id)oldPart with:(id)newPart
  /* Removes oldPart from self and replaces it with newPart.
   * Returns newPart.
   * If oldPart is not a member of this score, returns nil
   * and doesn't add newPart.  If newPart is nil, or if
   * newPart is already a member of this score, or 
   * if newPart is not a kind of Part, returns nil.
   */
{
    int i = [parts indexOfObject:oldPart];
    if (i == NSNotFound)
      return nil;
    [self removePart:oldPart];
    if ((!newPart) || ([newPart score] == self) || ![newPart isKindOfClass:[MKPart class]])
      return nil;
    [newPart _setScore:self];
    [parts insertObject:newPart atIndex:i];
    return newPart;
}

-addPart:(id)aPart
    /* If aPart is already a member of the Score, returns nil. Otherwise,
       adds aPart to the receiver and returns aPart,
       first removing aPart from any other score of which it is a member. */
{
    if ((!aPart) || ([aPart score] == self) || ![aPart isKindOfClass:[MKPart class]])
      return nil;
    [aPart _setScore:self];
    if (![parts containsObject:aPart]) [parts addObject:aPart];
    return self;
}

-removePart:(id)aPart
    /* Removes aPart from self and returns aPart. 
       If aPart is not a member of this score, returns nil. */
{
    [aPart _unsetScore];
    [parts removeObject:aPart];
    return self; //sb: assume self is correct. Arrays return void...
}

-shiftTime:(double)shift
  /* TYPE: Editing
   * Shift is added to the timeTags of all notes in the Part. 
   */
{
    unsigned n = [parts count], i;
    for (i = 0; i < n; i++)
        [[parts objectAtIndex:i] shiftTime:shift];
    return self;
}

/* Finding a Part ----------------------------------------------- */

-(BOOL)isPartPresent:aPart
    /* Returns whether Part is a member of the receiver. */
{
    return ([parts indexOfObject:aPart] == -1) ? NO : YES;
}

-midiPart:(int)aChan
  /* Returns the first Part with a MK_midiChan info parameter equal to
     aChan, if any. aChan equal to 0 corresponds to the Part representing
     MIDI system and channel mode messages. */
{
    id el, aInfo;
    unsigned n, i;
    if (aChan == MAXINT)
      return nil;
    n = [parts count];
    for (i = 0; i < n; i++) {
        el = [parts objectAtIndex:i];
        if ((aInfo = [el infoNote]))
            if ([aInfo parAsInt:MK_midiChan] == aChan)
                return [[el retain] autorelease];
    }
    return nil;
}


/* Manipulating notes. ------------------------------- */


static void merge(NSMutableArray *listOfLists,NSMutableArray *allNotes)
    /* ListOfLists is an Array containing List objects, one per Part.
       AllNotes is an empty List big enough to hold all the Notes of all the
       Parts. 
       */
{
    int *counts,*maxcounts;
    int listCount;
    int i,j,k;
    double t;
    MKNote *aNote,*theNote;
    id aList;
    int theList = 0; /* Give it a value to shut up compiler warnings */
    int max=0;
    IMP addMethod;
    listCount = [listOfLists count];
    _MK_CALLOC(counts,int,listCount);
    _MK_CALLOC(maxcounts,int,listCount);
    addMethod = [allNotes methodForSelector:@selector(addObject:)];

    for (k = 0; k < listCount; k++)
        maxcounts[max++] = [[listOfLists objectAtIndex:k] count];

    while (listCount > 0) {
	t = MK_ENDOFTIME;
	theNote = nil;
	i = 0;
	while (i < listCount) {
            aList = [listOfLists objectAtIndex:i]; //sb: was NX_ADDRESS(listOfLists)[i];
	    if (counts[i] < maxcounts[i])  // LMS changed from <= on Hamels recommendation & I agree.
                aNote = [aList objectAtIndex:counts[i]];
            else aNote = nil;
            if (!aNote) {  /* No more notes. */
                [listOfLists removeObjectAtIndex:i]; /* Pushes others down.       */
                for (j = i+1; j<listCount; j++) { /* Push counts down          */
                    counts[j-1] = counts[j];
                    maxcounts[j-1] = maxcounts[j];
                    }
                listCount--;                    /* One less list             */
                }
            else if ([aNote timeTag] < t) {   /* Candidate                 */
                t = [aNote timeTag];
                theNote = aNote;
		theList = i;
		i++;
                }
            else i++;
            }
        if (theNote) {
            (*addMethod)(allNotes,@selector(addObject:),theNote);
            counts[theList]++;
            }
        }
    free(counts);
    free(maxcounts);
}

static void writeNotes(NSMutableData *aStream, MKScore *aScore, _MKScoreOutStruct *p,
	 double firstTimeTag, double lastTimeTag, double timeShift)
{
    /* Write score body on aStream. Assumes p is a valid _MKScoreOutStruct. */
    MKPart *currentPart;
    unsigned n = [aScore->parts count], i;
    BOOL timeBounds = ((firstTimeTag != 0) || (lastTimeTag != MK_ENDOFTIME));
    NSMutableArray *allNotes = [NSMutableArray arrayWithCapacity: [aScore noteCount]];
    NSMutableArray *listOfLists = [NSMutableArray arrayWithCapacity: [aScore->parts count]];
    id aPart,aList;
    MKNote *currentNote;
    for (i = 0; i < n; i++) {
        currentPart = [aScore->parts objectAtIndex:i];
	if (timeBounds) 
	    aList = [currentPart firstTimeTag:firstTimeTag lastTimeTag:lastTimeTag];
	else {
	    [currentPart sort];
	    aList = [currentPart notesNoCopy];
	}
	if (aList)
	    [listOfLists addObject:aList];
	_MKWritePartDecl(currentPart,p,[currentPart infoNote]);
    }
    merge(listOfLists,allNotes);

    n = [allNotes count];
    p->_timeShift = timeShift;

    for (i = 0; i < n; i++) {
        currentNote = [allNotes objectAtIndex:i];
        _MKWriteNote(currentNote,aPart = [currentNote part],p);
    }
}

static id
readScorefile(MKScore *self,
    NSMutableData *stream,
    double firstTimeTag, double lastTimeTag, double timeShift,
    NSString *fileName)
 {
     /* Read from scoreFile to receiver, creating new Parts as needed
       and including only those notes between times firstTimeTag to
       time lastTimeTag, inclusive. Note that the TimeTags of the
       notes are not altered from those in the file. I.e.
       the first note's TimeTag will be greater than or equal to
       firstTimeTag.
       Merges contents of file with current Parts when the Part
       name found in the file is the same as one of those in the
       receiver. 
       Returns self or nil if error abort.  */
    register _MKScoreInStruct *p;
    register id aNote;
    IMP noteCopy, partAddNote;
    id rtnVal;
    unsigned int readPosition = 0;   // this is the top level.
        
    partAddNote = [MKGetPartClass() instanceMethodForSelector:@selector(addNote:)];
    noteCopy = [MKGetNoteClass() instanceMethodForSelector:@selector(copy)];
    p = _MKNewScoreInStruct(stream, self, self->scorefilePrintStream, NO, fileName, &readPosition);
    if (!p)
      return nil;
    _MKParseScoreHeader(p);
    lastTimeTag = MIN(lastTimeTag, MK_ENDOFTIME);
    firstTimeTag = MIN(firstTimeTag, MK_ENDOFTIME);
    do {
      aNote = _MKParseScoreNote(p);
    } while (p->timeTag < firstTimeTag);
    /* Believe it or not, is actually better to copy the note here!
       I'm not sure why.  Maybe the hashtable has some hysteresis and
       it gets reallocated each time. */
    while (p->timeTag <= lastTimeTag) {
	if (aNote) {
	    aNote = (id)(*noteCopy)(aNote, @selector(copy));
	    _MKNoteShiftTimeTag(aNote, timeShift);
	    (*partAddNote)(p->part, @selector(addNote:), aNote);
	}
	aNote = _MKParseScoreNote(p);
	if ((!aNote) && (p->timeTag > (MK_ENDOFTIME-1)))
	  break;
    }
    rtnVal = (p->_errCount == MAXINT) ? nil : self;
    _MKFinishScoreIn(p);
    return rtnVal;
}    

-setScorefilePrintStream:(NSMutableData *)aStream
  /* Sets the stream to be used for Scorefile 'print' statement output. */
{
    scorefilePrintStream = aStream;
    return self;
}

-(NSMutableData *)scorefilePrintStream
  /* Returns the stream used for Scorefile 'print' statement output. */
{
    return scorefilePrintStream;
}

-_setInfo:aInfo
  /* Needed by scorefile parser  */
{
    if (!info)
      info = [aInfo copy];
    else [info copyParsFrom:aInfo];
    return self;
}

-setInfoNote:(MKNote *) aNote
  /* Sets info, overwriting any previous info. aNote is copied. The old info,
     if any, is freed. */
{
    [info release];
    info = [aNote copy];
    return self;
}

- (MKNote *) infoNote
{
    return info;
}


-parts
  /* Returns a copy of the List of Parts in the receiver. The Parts themselves are not copied.
     Now that we use NSArrays, a [List copyWithZone] did a shallow copy, whereas
     [NSMutableArray copyWithZone] does a deep copy, so we emulate the List operation.  */
{
    return _MKLightweightArrayCopy(parts);
}

- copyWithZone:(NSZone *)zone
  /* Copies receiver, including its Parts, Notes and info. */ 
{
    unsigned n = [parts count], i;
    MKScore *newScore = [MKScore allocWithZone:zone];
    [newScore init];
    for (i = 0; i < n; i++)
        [newScore addPart:[[parts objectAtIndex:i] copyWithZone:zone]];

    newScore->info = [info copyWithZone:zone];
    return newScore;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* You never send this message directly.  
     Should be invoked with NXWriteRootObject(). 
     Archives Parts, Notes and info. */
{
    /*[super encodeWithCoder:aCoder];*/ /*sb: unnec */
    [aCoder encodeValuesOfObjCTypes:"@@",&parts,&info];
}

static BOOL isUnarchiving = NO;

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    isUnarchiving = YES; /* Inhibit Parts' mapping of noteTags. */
    /*[super initWithCoder:aDecoder];*/ /*sb: unnec */
    if ([aDecoder versionForClassName:@"Score"] == VERSION2) 
      [aDecoder decodeValuesOfObjCTypes:"@@",&parts,&info];
    /* from awake (sb) */
    {
        id tagTable;
        tagTable = [HashTable newKeyDesc:"i" valueDesc:"i"];
        [parts makeObjectsPerformSelector:@selector(_mapTags:) withObject:tagTable];
        [tagTable release];
        isUnarchiving = NO;
        }
    /****/
    return self;
}

#if 0
- awake
  /* Maps noteTags as represented in the archive file onto a set that is
     unused in the current application. This insures that the integrity
     of the noteTag is maintained. */
{
/*    id tagTable; */
#warning DONE ArchiverConversion: put the contents of your 'awake' method at the end of your 'initWithCoder:' method instead
    [super awake];
/*
    tagTable = [HashTable newKeyDesc:"i" valueDesc:"i"];
    [parts makeObjectsPerformSelector:@selector(_mapTags:) withObject:tagTable];
    [tagTable release];
    isUnarchiving = NO;
 */
    return self;
}
#endif

- (NSString *) description
{
    int i;
    NSMutableString *scoreDescription = [[NSMutableString alloc] initWithString: @"MKScore containing MKParts:\n"];
    NSMutableArray *partList = [self parts];
    MKPart *aPart;

    for(i = 0; i < [partList count]; i++) {
        aPart = [partList objectAtIndex: i];
        [scoreDescription appendString: [aPart description]];
    }
    [scoreDescription appendFormat: @"With MKScore info note:\n%@", [[self infoNote] description]];

    return scoreDescription;
}

@end

@implementation MKScore(Private)

+(BOOL)_isUnarchiving
{
    return isUnarchiving;
}

-_newFilePartWithName:(NSString *)name
 /* You never send this message. It is used only by the Scorefile parser
     to add a Part to the receiver when a part is declared in the
     scorefile. 
     It is a method rather than a C function to hide from the parser
     the differences between Score and ScorefilePerformer.
     */
{
    id aPart = [MKGetPartClass() new];
    MKNameObject(name,aPart);
    [self addPart:aPart];
    [aPart release];
    return aPart; /* sb: I have checked, and it's ok to return "reference" here rather than retained object */
}

#if 0
-_elements
  /* Same as parts. (needed by Scorefile parser)
     It is a method rather than a C function to hide from the parser
     the differences between Score and ScorefilePerformer.
     */
{
    return [self parts];
}
#endif

@end

