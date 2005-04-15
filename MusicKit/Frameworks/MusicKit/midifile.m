/*
  $Id$
  Defined In: The MusicKit

  Description:
    Based on original version written by Lee Boynton, extensively revised by
    David Jaffe.

    These routines might eventually be in a MIDI library. Nowdays, they're
    public MusicKit functions.

    The division of labor is as follows: All Music-Kit specifics are kept out
    of this file. The functions in this file read/write raw MIDI and meta-events.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.7  2005/04/15 04:18:25  leighsmith
  Cleaned up for gcc 4.0's more stringent checking of ObjC types

  Revision 1.6  2003/08/04 21:14:33  leighsmith
  Changed typing of several variables and parameters to avoid warnings of mixing comparisons between signed and unsigned values.

  Revision 1.5  2002/04/03 03:59:41  skotmcdonald
  Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

  Revision 1.4  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.3  2000/02/24 22:56:35  leigh
  Added Davids bug fix for unused recognised meta events

  Revision 1.2  1999/07/29 01:26:09  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  12/21/89/daj - Fixed bug in writing level-1 files. last_write_time 
                 needs to be set to 0 when the track's incremented.
		 Note: If this stuff is ever made reentrant (like if 
		       I ever support MidifileWriter/MKPerformer), all
		       statics will have to be struct entries.
  02/25-8/90/daj - Changed to make reentrant. Added sysexcl support.
                 Added support for most meta-events. All of the meta-events
		 defined in the July 1988 MIDI file spec are supported, 
		 with the exception of "MIDI Channel Prefix",
		 "MKInstrument Name" and "Sequencer-Specific Meta-Event".

                 To do:
		     Add support for writing formats 0 and 2.
		     Add support for SMPTE and MIDI time code (see
		     "division").
		     Implement MIDI Channel Prefix

  04/29/90/daj - Flushed unused auto vars
  05/24/91/daj - Added .5 to tempo when reading to avoid round-off error.
  09/13/91/daj - Fixed end of track time writing.
  01/17/92/daj - Fixed bug-fix (!) of 5/24/91.  I don't want to add .5 to
                 tempo when reading, because we're storing it as a double.
		 Furthermore, need to pass raw value upstairs, otherwise
		 truncation propogates tempo quantization when rewriting
		 MIDI files.  Also changed type of output tempo to double
		 in MKMIDIFILEWriteTempo.
  11/18/92/daj - Added midifileEvaluatesTempo switch
   12/11/93/daj - Added byte swapping for Intel hardware.
   12/10/94/dirk - Dirk Schwarzhans <dirk@diaspar.fb10.tu-berlin.de>
		  Fix of tempo-evaluation.  
		  This fix is based on work of  Brian 
		Willoughby who patched (in 2-92) the file "midifile.c"  which 
		was contained as example source code for using the midi driver 
		with NS release 2.x.
  8/19/95/lms/daj - Leigh Smith <leigh@psychokiller.dialix.oz.au>
		Fixed byte swapping for TEMPO event.
  12/3/95/lms - Fixed byte swapping for TEMPO event (again)
  1/11/96/lms - Hardwired writing the tempo to 60bpm when tempo-evaluating
		to preserve timing between events
  4/5/99/lms  - Changed prefixes to be public MusicKit routines.
*/

#import "_musickit.h"
#import "midi_spec.h"
#import "midifile.h"

/* Some metaevents */
#define SEQUENCENUMBER 0
#define TRACKCHANGE 0x2f
#define TEMPOCHANGE 0x51
#define SMPTEOFFSET 0x54
#define TIMESIG 0x58
#define KEYSIG 0x59

#define DEFAULTTEMPO (120.0)
#define DEFAULTDIVISION 1024

/*
 * reading
 */

typedef struct _midiFileInStruct {
    double tempo;       /* in quarter notes per minute */
    double timeScale;   /* timeScale * currentTime gives time in seconds */
    int currentTrack;   /* Current track number */
    int currentTime;    /* Current time in quanta. */
    int currentOffset;	/* Added by dirk */
    int division;       /* # of delta-time ticks per quarter. (See spec) */
    short format;       /* Level 0, 1 or 2 */
    int quantaSize;     /* In micro-seconds. */
    unsigned char runningStatus; /* Current MIDI running status */
    NSMutableData *midiStream;     /* Midifile stream */
    int curBufSize;     /* Size of data buffer */
    /* Info for current msg. These are passed up to caller */
    int quanta;	        /* Time in quanta */
    BOOL metaeventFlag; /* YES if this is a meta-event */
    int nData;          /* Number of significant bytes in data */
    unsigned char *data;/* Data bytes */
    BOOL evaluateTempo;
    unsigned int streamPos; /*sb: used to keep track of position within stream, for reading and writing. */
} midiFileInStruct;

#define REFERENCE **

void *MKMIDIFileBeginReading(NSMutableData *midiStream,
			      int REFERENCE quanta,
			      BOOL REFERENCE metaeventFlag,
			      int REFERENCE nData,
			      unsigned char * REFERENCE data,
			      BOOL evaluateTempo)
{
    midiFileInStruct *rtn;
    _MK_MALLOC(rtn,midiFileInStruct,1);
    rtn->tempo = DEFAULTTEMPO; 	    /* in beats per minute */
    rtn->currentTrack = -1; /* We call the first or "tempo track" 
			       "track 0". Therefore, we start counting at -1
			       here. */ 
    rtn->currentTime = 0;
    rtn->currentOffset = 0;
    rtn->division = 0;
    rtn->format = 0;
    rtn->quantaSize = MKMIDI_DEFAULTQUANTASIZE; /* size in microseconds */
    rtn->midiStream = midiStream;
    rtn->evaluateTempo = evaluateTempo;
    rtn->streamPos = 0;

    /* Malloc enough for SMPTEoffset metaevent. Realloc longer fields later */
    rtn->curBufSize = 6;
    _MK_MALLOC(rtn->data,unsigned char,rtn->curBufSize);
    /* Values are always returned indirectly in these fields. */
    *nData = &rtn->nData;            
    *data = &rtn->data;
    *metaeventFlag = &rtn->metaeventFlag;
    *quanta = &rtn->quanta;
    return rtn;
}

#define IP ((midiFileInStruct *)p)

void *MKMIDIFileEndReading(void *p)
{
    free(IP->data);
    IP->data = NULL;
    free(IP);
    p = NULL; 
    return NULL;
}

enum {unrecognized = -1,endOfStream = 0,ok = 1,undefined,
	/* Multi-packet sys excl: */
	firstISysExcl,middleISysExcl,endISysExcl, 
	/* Single-packet sys excl */
	sysExcl};                                 

static int calcMidiEventSize(int status)
{
    if (MIDI_TYPE_3BYTE(status))
      return 3;
    else if (MIDI_TYPE_2BYTE(status))
      return 2;
    else return 1;
}

static int readChunkType(NSMutableData *midiStream,char *buf,unsigned int *streamPos)
{
//    int count = NXRead(midiStream,buf,4);
    NSRange range4 = NSMakeRange(*streamPos,4);
    if ([midiStream length] < *streamPos + 4) {
        *streamPos += 4;
        return 0;
        }
    [midiStream getBytes:buf range:range4];
    buf[4] = '\0';
//    return (count == 4)? ok : 0;
    *streamPos += 4;
    return ok;
}

static int readLong(NSMutableData *midiStream, int *n,unsigned int *streamPos)
{
    NSRange range4 = NSMakeRange(*streamPos,4);
    if ([midiStream length] < *streamPos + 4) {
        *streamPos += 4;
        return 0;
        }
//    int count = NXRead(midiStream,n,4);
    [midiStream getBytes:n range:range4];
    *n = NSSwapBigIntToHost(*n);
//    return (count == 4)? ok : 0;
    *streamPos += 4;
    return ok;
}

static int readBytes(NSMutableData *midiStream, unsigned char *bytes,int n,unsigned int *streamPos)
{
    NSRange rangen = NSMakeRange(*streamPos,n);
    if ([midiStream length] < *streamPos + n) {
        *streamPos += n;
        return 0;
        }
//    int count = NXRead(midiStream,bytes,n);
    [midiStream getBytes:bytes range:rangen];
//    return (count == n) ? ok : 0;
    *streamPos += n;
    return ok;
}

static int readShort(NSMutableData *midiStream, short *n,unsigned int *streamPos)
{
    NSRange range2 = NSMakeRange(*streamPos,2);
    if ([midiStream length] < *streamPos + 2) {
        *streamPos += 2;
        return 0;
        }
//    int count = NXRead(midiStream,n,2);
    [midiStream getBytes:n range:range2];
    *n = NSSwapBigShortToHost(*n);
//    return (count == 2)? ok : 0;
    *streamPos += 2;
    return ok;
}

static int readVariableQuantity(NSMutableData *midiStream, int *n, unsigned int *streamPos)
{
    int lastByte = [midiStream length] - 1;
    const char *theData = [midiStream bytes];
    int m=0;
    unsigned char temp;
    while ((signed) (*streamPos)++ < lastByte) {
        temp = theData[*streamPos - 1];
        if (128 & temp)
          m = (m<<7) + (temp & 127);
        else {
            *n = (m<<7) + (temp & 127);
            return ok;
        }
    }

/*
    int m = 0;
    unsigned char temp;
    while (NXRead(midiStream,&temp,1) > 0) {
	if (128 & temp)
	  m = (m<<7) + (temp & 127);
	else {
	    *n = (m<<7) + (temp & 127);
	    return ok;
	}
    }
 */
    return endOfStream;
}

static int readTrackHeader(midiFileInStruct *p,unsigned int *streamPos)
{
    char typebuf[8];
    int size;
    if (!readChunkType(p->midiStream,typebuf,streamPos)) 
      return endOfStream;
    if (strcmp(typebuf,"MTrk")) 
      return endOfStream;
    p->currentTrack++;
    p->currentTime = 0;
    p->currentOffset = 0;
    if (!readLong(p->midiStream,&size,streamPos)) 
      return endOfStream;
    return ok;
}

static void checkRealloc(midiFileInStruct *p,int newSize)
{
    if (p->curBufSize < newSize)
      _MK_REALLOC(p->data,unsigned char,newSize);
    p->curBufSize = newSize;
}

static int readMetaevent(midiFileInStruct *p,unsigned int *streamPos)
{
    unsigned char theByte = '\0';
    int temp;
    int varQuantityLength; unsigned int poin;
    if (*streamPos >= [p->midiStream length]) return endOfStream; //sb
    poin = *streamPos;
    theByte = ((const char *)[p->midiStream bytes])[poin];
    *streamPos = poin + 1;
    if (!readVariableQuantity(p->midiStream,&varQuantityLength,streamPos))
      return endOfStream;
    if (theByte == SEQUENCENUMBER) {
	short val;
	if (!readShort(p->midiStream,&val,streamPos))
	  return endOfStream;
	p->data[0] = MKMIDI_sequenceNumber;
	p->data[1] = val >> 8;
	p->data[2] = val;
	varQuantityLength -= 2;
	p->nData = 3;
    }
    else if (theByte >= 1 && theByte <= 0x0f) { /* Text meta events */
	p->data[0] = theByte;
	p->nData = varQuantityLength + 1; /* nData doesn't include the \0 */
	checkRealloc(p,p->nData + 1);
	if (!readBytes(p->midiStream,&(p->data[1]),p->nData - 1,streamPos))
	  return endOfStream;
	p->data[p->nData] = '\0';
	return ok;
    }
    else if (theByte == TRACKCHANGE) { 		/* end of track */
	temp = readTrackHeader(p,streamPos);
	if (temp == endOfStream) 
	  return endOfStream;
	/* trackChange doesn't have any args but we pass up the track number,
	   so no varQuantityLength -= needed.
	 */
	p->nData = 3;
	p->data[0] = MKMIDI_trackChange;
	p->data[1] = (p->currentTrack >> 8);
	p->data[2] = p->currentTrack;
    } 
    else if (theByte == TEMPOCHANGE) { 	         /* tempo */
	double n;
	int i;
	if (!readBytes(p->midiStream,&(p->data[1]),3,streamPos))    /* 24 bits */
	  return endOfStream;
        i = (p->data[1] << 16) | (p->data[2] << 8) | p->data[3];
        n = (double)i;
	/* tempo in file is in micro-seconds per quarter note */
	p->tempo = 60000000.0 / n + 0.5; 
	/* division is the number of delta time "ticks" that make up a 
	   quarter note. Quanta size is in micro seconds. */
	if (p->evaluateTempo) {
	  p->currentOffset += ((int)(0.5 + (p->timeScale * (double)p->currentTime)));
	  p->currentTime = 0;
	  p->timeScale = n / (double)(p->division * p->quantaSize);
	}
	p->data[0] = MKMIDI_tempoChange;
	/* It's a 3 byte quantity but we store it in 4 bytes.*/
	/* We pass data up stairs and let caller disambiguate by dividing
	   60000000 by the value.  Otherwise, we'd have to pack a double
	   into an int. */
#if __LITTLE_ENDIAN__
	p->data[1] = i & 0xff;
	p->data[2] = (i >> 8) & 0xff;
	p->data[3] = (i >> 16);
	p->data[4] = 0;         
#else
	p->data[1] = 0;         
	p->data[2] = (i >> 16);
	p->data[3] = (i >> 8) & 0xff;
	p->data[4] = i & 0xff;
#endif
	p->nData = 5;
	varQuantityLength -= 3;
    } 
    else if (theByte == SMPTEOFFSET) {
	p->data[0] = MKMIDI_smpteOffset;
	if (!readBytes(p->midiStream,&(p->data[1]),5,streamPos))
	  return endOfStream;
	p->nData = 6;
	varQuantityLength -= 5;
    } 
    else if (theByte == TIMESIG) {
	if (!readBytes(p->midiStream,&p->data[1],4,streamPos))
	  return endOfStream;
	p->data[0] = MKMIDI_timeSig;
	p->nData = 5;
	varQuantityLength -= 4;
    } 
    else if (theByte == KEYSIG) {
	if (!readBytes(p->midiStream,&p->data[1],2,streamPos))
	  return endOfStream;
	p->data[0] = MKMIDI_keySig;
	p->nData = 3;
	varQuantityLength -= 2;
    } 
    else { /* Skip unrecognized meta events */
        // According to David J, we should simply advance past the variable quantity,
        // not read any further data.
        *streamPos += varQuantityLength;
	return unrecognized;
    }

    *streamPos += varQuantityLength;
    return ok;
}

/* We do not support multi-packet system exclusive messages with different
   timings. When such a beast occurs, it is concatenated into a single
   event and the time stamp is that of the last piece of the event. */

static int readSysExclEvent(midiFileInStruct *p,int oldState,unsigned int *streamPos)
{
    int len;
    unsigned char *ptr;
    if (!readVariableQuantity(p->midiStream,&len,streamPos))
      return endOfStream;
    if (oldState == undefined) {
	checkRealloc(p,len + 1); /* len doesn't include data[0] */
	p->data[0] = MIDI_SYSEXCL;
	p->nData = len + 1;
	ptr = &(p->data[1]);
    } else {      /* firstISysExcl or middleISysExcl */
	checkRealloc(p,len + p->nData);
	ptr = &(p->data[p->nData]);
	p->nData += len; 
    }
    if (readBytes(p->midiStream,ptr,len,streamPos) == endOfStream)
      return endOfStream;
    return ((p->data[p->nData - 1] == MIDI_EOX) ? 
	    ((oldState == undefined) ? sysExcl : endISysExcl) : 
	    ((oldState == undefined) ? firstISysExcl : middleISysExcl));
}

static int readEscapeEvent(midiFileInStruct *p,unsigned int *streamPos)
{
    if (!readVariableQuantity(p->midiStream,&(p->nData),streamPos))
      return endOfStream;
    checkRealloc(p,p->nData);
    return readBytes(p->midiStream,p->data, p->nData,streamPos);
}

#define SCALEQUANTA(_p,quanta) \
  ((int)(0.5 + (((midiFileInStruct *)_p)->timeScale * (double)quanta)))

/*
 * Exported routines
 */

int MKMIDIFileReadPreamble(void *p,int *level,int *trackCount)
{
    char typebuf[8];
    int size;
    short fmt, tracks, div;

    if ((!readChunkType(IP->midiStream,typebuf,&(IP->streamPos))) ||
        (strcmp(typebuf,"MThd")) ||  /* not a midifile */
         (!readLong(IP->midiStream,&size,&(IP->streamPos))) ||
         (size < 6) ||               /* bad header */
         (!readShort(IP->midiStream,&fmt,&(IP->streamPos))) ||
         (fmt < 0 || fmt > 2)  ||     /* must be level 0, 1 or 2 */
         (!readShort(IP->midiStream,&tracks,&(IP->streamPos))) ||
         (!readShort(IP->midiStream,&div,&(IP->streamPos))))
         return endOfStream;
     size -= 6;
     if (size)
         IP->streamPos += size; //sb: to replace seek
         /*      NXSeek(IP->midiStream,size,NX_FROMCURRENT);*/ /* Skip any extra length in field. */
    *trackCount = fmt ? tracks-1 : 1;
    *level = IP->format = fmt;
    if (div < 0) { /* Time code encoding? */
	/* For now, we undo the effect of the time code. We may want to
	   eventually pass the time code up? */ 
	short SMPTEformat,ticksPerFrame;
	ticksPerFrame = div & 0xff;
	SMPTEformat = -(div >> 8); 
	/* SMPTEformat is one of 24, 25, 29, or 30. It's stored negative */
	div = ticksPerFrame * SMPTEformat;
    }
    IP->division = div;
    IP->currentTrack = -1;
//    IP->timeScale = 60000000.0 / (double)(IP->division * IP->quantaSize);
    IP->timeScale = 1000000.0/(double)(IP->division * IP->quantaSize);
    return ok;
}

int MKMIDIFileReadEvent(register void *p)
    /* return endOfStream when EOS is reached, return 1 otherwise.
       Data should be an array of length 3. */
{
    int deltaTime,quantaTime,state = undefined;
    unsigned char theByte = '\0';
    unsigned int poin;
    if (IP->currentTrack < 0 && !readTrackHeader(p,&(IP->streamPos))) 
      return endOfStream;
    for (; ;) {
        if (!readVariableQuantity(IP->midiStream,&deltaTime,&(IP->streamPos))) 
	  return endOfStream;
	IP->currentTime += deltaTime;
//	quantaTime = SCALEQUANTA(p,IP->currentTime); **** removed by dirk ****
	quantaTime = IP->currentOffset + SCALEQUANTA(p,IP->currentTime);
        if (IP->streamPos >= [IP->midiStream length])
            return endOfStream;
        poin = IP->streamPos;
        theByte = ((const char *)[IP->midiStream bytes])[poin++];
        IP->streamPos = poin;
	if (theByte == 0xff) {
	    state = readMetaevent(p,&(IP->streamPos));
	    IP->metaeventFlag = YES;
	    if (state != unrecognized) {
		IP->quanta = quantaTime;
		return state;
	    }
	} else if ((theByte == MIDI_SYSEXCL) || (state != undefined)) {
	    /* System exclusive */
            state = readSysExclEvent(p,state,&(IP->streamPos));
	    IP->metaeventFlag = NO;
	    switch (state) {
	      case firstISysExcl:
		IP->quanta = quantaTime;
		break;
	      case middleISysExcl:
		IP->quanta += quantaTime;
		break;
	      case endISysExcl:
		IP->quanta += quantaTime;
		return ok;
	      case endOfStream:
	      case sysExcl:
		IP->quanta = quantaTime;
		return ok;
	      default:
		break;
	    }
	} else if (theByte == 0xf7) { /* Special "escape" code */
	    IP->quanta = quantaTime;
            return readEscapeEvent(p,&(IP->streamPos));
	} else { /* Normal MIDI */
	    BOOL newRunningStatus = (theByte & MIDI_STATUSBIT);
	    if (newRunningStatus)
	      IP->runningStatus = theByte;
	    IP->metaeventFlag = 0;
	    IP->quanta = quantaTime;
	    IP->nData = calcMidiEventSize(IP->runningStatus);
	    IP->data[0] = IP->runningStatus;
	    if (IP->nData > 1) {
		if (newRunningStatus) {
//                    if (!NXRead(IP->midiStream,&(IP->data[1]),1)) 
                    if (IP->streamPos >= [IP->midiStream length])
                        return endOfStream;
                    poin = IP->streamPos;
                    IP->data[1] = ((const char *)[IP->midiStream bytes])[poin++];
                    IP->streamPos=poin;
		}
		else IP->data[1] = theByte;
		if (IP->nData > 2) {
//                    if (!NXRead(IP->midiStream,&(IP->data[2]),1))
                    if (IP->streamPos >= [IP->midiStream length])
                        return endOfStream;
                    poin = IP->streamPos;
                    IP->data[2] = ((const char *)[IP->midiStream bytes])[poin++];
                    IP->streamPos = poin;
                    }
	    }
	    return ok;
	}
    }
}


/*
 * writing
 */

typedef struct _midiFileOutStruct {
    double tempo;     
    double timeScale; 
    int currentTrack;
    int division;
    int currentCount;
    int lastTime;
    NSMutableData *midiStream;
    int quantaSize;
    BOOL evaluateTempo;
} midiFileOutStruct;

#define OP ((midiFileOutStruct *)p)

static int writeBytes(midiFileOutStruct *p, const unsigned char *bytes,int count)
{
//    int bytesWritten;
    /*bytesWritten = */[p->midiStream appendBytes:bytes length:count];
    OP->currentCount += count;
/*    if (bytesWritten != count)
      return endOfStream;
    else return ok;
 */
    return ok;
}

static int writeByte(midiFileOutStruct *p, unsigned char n)
{
    /*int bytesWritten = */[p->midiStream appendBytes:&n length:1];
    p->currentCount += 1;//bytesWritten;
    return 1;//bytesWritten;
}

static int writeShort(midiFileOutStruct *p, short n)
{
//    int bytesWritten;
    n = NSSwapHostShortToBig(n);
    /*bytesWritten = */ [p->midiStream appendBytes:&n length:2];
    p->currentCount += 2;//bytesWritten;
//    return (bytesWritten == 2) ? ok : endOfStream;
    return 2;
}

static int writeLong(midiFileOutStruct *p, int n)
{
//    int bytesWritten;
    n = NSSwapHostIntToBig(n);
   /* bytesWritten = */[p->midiStream appendBytes:&n length:4];
    p->currentCount += 4;//bytesWritten;
//    return (bytesWritten == 4) ? ok : endOfStream;
        return 4;
}

static int writeChunkType(midiFileOutStruct *p, char *buf)
{
    /*int bytesWritten = */[p->midiStream appendBytes:buf length:4];
    p->currentCount += 4;//bytesWritten;
//    return (bytesWritten == 4) ? ok : endOfStream;
    return 4;
}

static int writeVariableQuantity(midiFileOutStruct *p, int n)
{
    if ((n >= (1 << 28) && !writeByte(p,(((n>>28)&15)|128) )) ||
	(n >= (1 << 21) && !writeByte(p,(((n>>21)&127)|128) )) ||
	(n >= (1 << 14) && !writeByte(p,(((n>>14)&127)|128) )) ||
	(n >= (1 << 7) && !writeByte(p,(((n>>7)&127)|128) ))) 
      return endOfStream;
    return writeByte(p,(n&127));
}

void *MKMIDIFileBeginWriting(NSMutableData *midiStream, int level, NSString *sequenceName,
			      BOOL evaluateTempo)
{
    short lev = level, div = DEFAULTDIVISION, ntracks = 1;
    midiFileOutStruct *p;
    _MK_MALLOC(p,midiFileOutStruct,1);
    OP->tempo = DEFAULTTEMPO; 	    /* in beats per minute */
    OP->quantaSize = MKMIDI_DEFAULTQUANTASIZE; /* size in microseconds */
    OP->lastTime = 0;
    OP->midiStream = midiStream;
    if ((!writeChunkType(p,"MThd")) || (!writeLong(p,6)) ||
	!writeShort(p,lev) || !writeShort(p,ntracks) || !writeShort(p,div))
      return endOfStream;
    OP->division = div;
    OP->currentTrack = -1;
//    OP->timeScale = 60000000.0 / (double)(OP->division * OP->quantaSize);
    OP->timeScale = (double)(OP->division * OP->quantaSize)/1000000.0;
    OP->currentCount = 0;
    OP->evaluateTempo = evaluateTempo;
    if (MKMIDIFileBeginWritingTrack(p,sequenceName))
      return p;
    else {
      free(p);
      p = NULL;
      return NULL;
    }
}

int MKMIDIFileEndWriting(void *p)
{
  short ntracks = OP->currentTrack+1; /* +1 for "tempo track" */
  NSRange replaceRange;

  if (OP->currentCount) {  /* Did we forget to finish before? */
    int err = MKMIDIFileEndWritingTrack(p,0);
    if (err == endOfStream) {
      free(p);
      p = NULL;
      return endOfStream;
    }
  }
  replaceRange.location = 10;
  replaceRange.length = 2;

  ntracks = NSSwapHostShortToBig(ntracks);
  [OP->midiStream replaceBytesInRange: replaceRange withBytes: &ntracks];

  if(p) { free(p); p = NULL; };
  return ok;
}

int MKMIDIFileBeginWritingTrack(void *p, NSString *trackName)
{
    if (OP->currentCount) /* Did we forget to finish before? */
      MKMIDIFileEndWritingTrack(p,0);
    if (!writeChunkType(p,"MTrk")) 
      return endOfStream;
    if (!writeLong(p,0))  /* This will be the length of the track, but is dummy'ed for now. */
      return endOfStream;
    OP->lastTime = 0;
    OP->currentTrack++;
    OP->currentCount = 0; /* Set this after the "MTrk" and dummy length are written */
    if (trackName) {
        int i = [trackName cStringLength];
	if (i) {
	    if (!writeByte(p,0) || !writeByte(p,0xff) || !writeByte(p,0x03) || 
		!writeVariableQuantity(p,i) ||
		!writeBytes(p,(const char *)[trackName cString],i))  
	      return endOfStream;
	}
    }
    return ok;
}

static int writeTime(midiFileOutStruct *p, int quanta)
{
    int thisTime = (int)(0.5 + (OP->timeScale * quanta));
    int deltaTime = thisTime - OP->lastTime;
    OP->lastTime = thisTime;
    if (!writeVariableQuantity(p,deltaTime)) 
      return endOfStream;
    return ok;
}

int MKMIDIFileEndWritingTrack(void *p,int quanta)
{
    int cc;
    int trackLengthPos;
    NSRange replaceRange;

    if (!writeTime(p,quanta) || 
	!writeByte(p,0xff) || 
	!writeByte(p,TRACKCHANGE) || 
	!writeByte(p,0)) 
	return endOfStream;
    /* Seek back to the track length field for this track. */

    /* +4 because we don't include the "MTrk" specification and length in the count */
    trackLengthPos = [OP->midiStream length] - (OP->currentCount+4);
    
    cc = NSSwapHostIntToBig(OP->currentCount);
    replaceRange.location = trackLengthPos;
    replaceRange.length = 4;
    [OP->midiStream replaceBytesInRange: replaceRange withBytes: &cc];

    OP->currentCount = 0; /* Signals other functions that we've just finished a track. */
    return ok;
}

int MKMIDIFileWriteSig(void *p,int quanta,short metaevent,unsigned data)
{
    BOOL keySig = (metaevent == MKMIDI_keySig);
    unsigned char b;
    unsigned char byteCount = (keySig) ? 2 : 4;
    b = (keySig) ? KEYSIG : TIMESIG;
    if (!writeTime(p,quanta) || 
	!writeByte(p,0xff) ||
	!writeByte(p,b) ||
	!writeByte(p,byteCount))
      return endOfStream;
    return (keySig) ? writeShort(p,data) : writeLong(p,data);
}

int MKMIDIFileWriteText(void *p,int quanta,short metaevent,NSString *text)
{
    int i;
    if (!text)
      return ok;
    i = [text length];
    if (!writeTime(p,quanta) || 
	!writeByte(p,0xff) ||
	!writeByte(p,metaevent) ||
	!writeVariableQuantity(p,i) || !writeBytes(p,(const unsigned char *)[text cString],i))
      return endOfStream;
    return ok;
}

int MKMIDIFileWriteSMPTEoffset(void *p,unsigned char hr,unsigned char min,
				unsigned char sec,unsigned char ff,
				unsigned char fr)
{
    if (!writeByte(p,0) ||  /* Delta-time is always 0 for SMPTE offset */
	!writeByte(p,0xff) ||
	!writeByte(p,SMPTEOFFSET) ||
	!writeByte(p,5) || !writeByte(p,hr) || !writeByte(p,min) ||
	!writeByte(p,sec) || !writeByte(p,fr) || !writeByte(p,ff))
      return endOfStream;
    return ok;
}

int MKMIDIFileWriteSequenceNumber(void *p,int data)
{
    if (!writeByte(p,0) || /* Delta time is 0 */
	!writeByte(p,0xff) ||
	!writeByte(p,SEQUENCENUMBER) ||
	!writeByte(p,2) || !writeShort(p,data))
      return endOfStream;
    return ok;
}

int MKMIDIFileWriteTempo(void *p,int quanta, double beatsPerMinute)
{
    int n;
    OP->tempo = beatsPerMinute;
    n = (int)(0.5 + (60000000.0 / OP->tempo));
    if (OP->evaluateTempo) {
      OP->timeScale = (double) n / (double)(OP->division * OP->quantaSize);
      /* 
       * if evaluating tempo we replace the original with 60bpm
       * to preserve the absolute timing between notes.
       */
      n = 1000000;
    }
    n %= 0x00ffffff; /* Endian-kosher &= */
    n += 0x03000000; /* Endian-kosher |= */
    if (!writeTime(p,quanta) || 
	!writeByte(p,0xff) || 
	!writeByte(p,TEMPOCHANGE) || 
	!writeLong(p,n)) 
      return endOfStream;
    return ok;
}

int MKMIDIFileWriteEvent(register void *p, int quanta, int nData, unsigned char *bytes)
{
    if (!writeTime(p,quanta))
      return endOfStream;
    if (nData && MIDI_TYPE_SYSTEM(bytes[0])) 
      if (!writeByte(p,MIDI_EOX) ||  /* Escape byte */
	  !writeVariableQuantity(p,nData)) /* Length of message */
	return endOfStream;
    if (!writeBytes(p,bytes,nData)) 
      return endOfStream;
    return ok;
}

int MKMIDIFileWriteSysExcl(void *p, int quanta, int nData, unsigned char *bytes)
    /* Assumes there's no MIDI_SYSEXCL at start and there is a
     * MIDI_EOX at end. */
{
    if (!writeTime(p,quanta) || !writeByte(p,MIDI_SYSEXCL) ||
	!writeVariableQuantity(p,nData) || !writeBytes(p,bytes,nData))
      return endOfStream;
    return ok;
}

#if 0

// this is a kludge in the sense that it is modifying the times as they are read from the MIDI file.
// if we ever wanted to playback twice what was read, we would have a problem.
int MKMIDISetReadQuantasize(void *p,int usec)
{
    IP->quantaSize = usec;
    if (IP->division) {
	double n = 60000000.0 / IP->tempo;
	IP->timeScale = n / (double)(IP->division * IP->quantaSize);
    }
    return usec;
}

#endif


