/*
  $Id$
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    Note that the code for writing scorefiles is spread between writeScore.m,
    MKNote.m, and _ParName.m. This is for reasons of avoiding inter-module
    communication (i.e. minimizing globals). Perhaps the scorefile-writing
    should be more cleanly isolated.

    See binaryScorefile.doc on the musickit source directory for explanation
    of binary scorefile format.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000 The MusicKit Project.  
*/ 
/* 
Modification history before commital to the CVS repository.

  09/22/89/daj - Added _MK_BACKHASH bit or'ed in with type when adding name,
                 to accommodate new way of handling back-hashing. Fixed bug
		 whereby very large table was needlessly created for writing
		 files.

  10/06/89/daj - Changed to use hashtable.h version of table.
  10/20/89/daj - Added binary scorefile support.
  12/15/89/daj - Changed SCOREMAGIC write to conform to one-word magic
  01/09/89/daj - Changed comments.
*/

#import "_musickit.h"
#import "_MKNameTable.h"   
#import "NotePrivate.h"
#import "tokens.h"
#import "_error.h"
#import "_noteRecorder.h"

static void writeScoreInfo(_MKScoreOutStruct *p,id info)
    /* Writes the MKScore "info note" */
{
    NSMutableData *aStream = p->_stream;
    if (!info)
      return;
    if (p->_binaryIndecies) 
      _MKWriteShort(aStream,_MK_info);
    else {
        [aStream appendData:
	    [[NSString stringWithFormat:@"%s ", _MKTokName(_MK_info)]
	    dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    }
    _MKWriteParameters(info,aStream,p);
}

#define NO_TAG_YET -1.0

_MKScoreOutStruct *
_MKInitScoreOut(NSMutableData *fileStream,id owner,id anInfoNote,double timeShift,
		BOOL isNoteRecorder,BOOL binary)
{
    /* Makes new _MKScoreOutStruct for specified file.
       Assumes file has just been opened. */
    _MKScoreOutStruct * p;
    if (!fileStream) 
      return NULL;
    _MK_MALLOC(p,_MKScoreOutStruct,1);
    p->_stream = [fileStream retain];             
    p->_nameTable = _MKNewScorefileParseTable();
    /* We need keyword and such symbols here to make sure there's no
       collision with such symbols when file is written. */
    p->timeTag = NO_TAG_YET; /* Insure first 0 tag is written */
    p->_timeShift = timeShift;
    p->_owner = owner;
    p->_ownerIsNoteRecorder = isNoteRecorder;
    p->isInBody = NO;
#   define DEFAULTINDECIES 8
    p->_binary = binary;
    if (binary) {
	p->_binaryIndecies = NSCreateMapTable(NSObjectMapKeyCallBacks,
                                NSIntMapValueCallBacks, DEFAULTINDECIES);
        p->_highBinaryIndex = 0;
    }
    else
        p->_binaryIndecies = NULL;
    if (binary)
      _MKWriteInt(p->_stream,MK_SCOREMAGIC);
    writeScoreInfo(p,anInfoNote);
    return p;
}

#define BINARY(_p) (p->_binary)

static void writePartInfo(_MKScoreOutStruct *p, MKPart *aPart, NSString *partName, MKNote *info)
    /* Writes the MKPart "info note" */
{
    NSMutableData *aStream = p->_stream;
    if (!info)
      return;
    if (BINARY(p)) {
	_MKWriteShort(aStream, _MK_partInstance);
	_MKWriteShort(aStream, (int)NSMapGet(p->_binaryIndecies,aPart));
    }
    else {
        [aStream appendData:[[NSString stringWithFormat:@"%@ ", partName]
           dataUsingEncoding:NSNEXTSTEPStringEncoding]];
    }
    _MKWriteParameters(info,aStream,p);
}

/* File must be open before this function is called. 
Gets partName from global table. 
If the partName collides with any symbols written to the
file, a new partName of the form partName<low integer> is formed.
If p has no name, generates a new name of the form 
<part><low integer>.  If p is NULL, returns NULL, else p.
*/
_MKScoreOutStruct *
_MKWritePartDecl(MKPart *aPart, _MKScoreOutStruct * p, MKNote *aPartInfo)
{
    BOOL newName;
    unsigned short iTmp;
    id tmp;
    NSString *partName;
    const char *tokname;
    
    if (!p)
	return NULL;
    partName = _MKNameTableGetObjectName(p->_nameTable, aPart, &tmp);
    if (partName)
	return p;                            /* Already declared */
    
    /* If we've come here, we already know that the object is not named in the local table. */
    partName = (NSString *) MKGetObjectName(aPart);     /* Get object's name */
    /* No name or Name exists */
    newName = (partName == nil) || (_MKNameTableGetObjectForName(p->_nameTable, partName, nil, &iTmp) != nil);
    if (newName) {      /* anonymous object or name collision */
	id hashObj;
	
	if (!partName) {
	    tokname = _MKTokNameNoCheck(_MK_part);
	    partName = [NSString stringWithCString: tokname];
	}
	// LMS check _MKTokNameNoCheck shouldn't return nil, which will cause problems trying to make it a NSString 
	/* Root of anonymous name */
	/*sb: was _MKMakeStr(partName) */
	partName = _MKUniqueName([[partName copy] autorelease], p->_nameTable, aPart, &hashObj);
	//LMS was not autoreleased but K. Hamel had problems when it wasn't??
	//      partName = _MKUniqueName([partName copy],p->_nameTable,aPart, &hashObj); /*sb: was _MKMakeStr(partName) */ 
    }
    if (BINARY(p)) {
	_MKWriteShort(p->_stream, _MK_part);
	_MKWriteNSString(p->_stream, partName);
	NSMapInsert(p->_binaryIndecies, aPart, (void *)(++(p->_highBinaryIndex)));
    }
    else 
	[p->_stream appendData: [[NSString stringWithFormat: @"%s %@;\n", _MKTokNameNoCheck(_MK_part), partName]
	    dataUsingEncoding: NSNEXTSTEPStringEncoding]];
    _MKNameTableAddName(p->_nameTable, partName, nil, aPart, _MK_partInstance | _MK_BACKHASHBIT, YES);
    writePartInfo(p, aPart, partName, aPartInfo);
    //    if (newName)  // K. Hamel reports problems
    //      [partName release];
    return p;
}

_MKScoreOutStruct *_MKFinishScoreOut(_MKScoreOutStruct * p, BOOL writeEnd)
{
    /* Frees struct pointed to by argument. Does not
       close file. Returns NULL. */
    if (p) {
	if (writeEnd) {
	    if (!(p->isInBody)) 
	      if (BINARY(p)) {
		  _MKWriteShort(p->_stream,_MK_begin);
		  _MKWriteShort(p->_stream,_MK_end);
	      }
	      else {
		  [p->_stream appendData:
		      [[NSString stringWithFormat:@"\n\n%s;\n\n", _MKTokNameNoCheck(_MK_begin)]
		      dataUsingEncoding:NSNEXTSTEPStringEncoding]];
		  [p->_stream appendData:
                      [[NSString stringWithFormat:@"%s;\n", _MKTokNameNoCheck(_MK_end)]
                      dataUsingEncoding:NSNEXTSTEPStringEncoding]];
	      }
	    else {
	      if (BINARY(p)) {
		  _MKWriteShort(p->_stream,_MK_end);
		  _MKWriteShort(p->_stream,0); /* Parser likes to read 
						  4 bytes */
	      }
	      else {
		[p->_stream appendData:
		   [[NSString stringWithFormat:@"%s;\n", _MKTokNameNoCheck(_MK_end)]
		    dataUsingEncoding:NSNEXTSTEPStringEncoding]];
              }
	  }
	}
    _MKFreeScorefileTable(p->_nameTable);
        [p->_stream release];
        if (p->_binaryIndecies) {
            NSFreeMapTable(p->_binaryIndecies);
        }
        free(p);
        p = NULL;
    }
    return NULL;
}

_MKScoreOutStruct *
_MKWriteNote(id aNote, id aPart, _MKScoreOutStruct * p)
{
    /* If p is NULL, return NULL. Else write note, adding timeTag if 
       necessary.
       If timeTag is out of order, error. */
    double timeTag;
    if (!p)
      return NULL;
    if (!(p->isInBody)) {
	if (BINARY(p))
	  _MKWriteShort(p->_stream,_MK_begin);
	else {
	    [p->_stream appendData:
	        [[NSString stringWithFormat:@"\n\n%s;\n\n", 
		_MKTokNameNoCheck(_MK_begin)]
		dataUsingEncoding:NSNEXTSTEPStringEncoding]];
        }
	p->isInBody = YES;
    }
    timeTag = ((p->_ownerIsNoteRecorder) ? 
	       _MKTimeTagForTimeUnit(aNote,[p->_owner timeUnit],
				     [p->_owner compensatesDeltaT]) :
	       [aNote timeTag] + p->_timeShift);
    if (timeTag < 0)
      timeTag = 0;
    if (timeTag > p->timeTag) {
	if (BINARY(p)) {
	    double t = timeTag;
#           define MAX_FLOAT_TIME ((float)2.5) /* Minutes */
	    /* At a sampling rate of 44100, we can encode 6 minutes with
	       sample-level accuracy in a float. At 48000, this goes down
	       to 5.8 minutes. For safety, we divide this by 2.
	       For more than MAX_FLOAT_TIME, we start to lose precision. 
	       Therefore, we never write more
	       than a MAX_FLOAT_TIME relative time to a binary scorefile. */
	    if (p->timeTag == NO_TAG_YET)  
	      p->timeTag = 0;
	    t -= p->timeTag; /* Make it relative */
	    while (t > MAX_FLOAT_TIME) {
		_MKWriteShort(p->_stream,_MK_time);
		_MKWriteFloat(p->_stream,MAX_FLOAT_TIME);
		t -= MAX_FLOAT_TIME;
	    }
	    _MKWriteShort(p->_stream,_MK_time);
	    _MKWriteFloat(p->_stream,(float)t);
	}
	else {
	  [p->_stream appendData:
	      [[NSString stringWithFormat:@"%s %.5f;\n", _MKTokNameNoCheck(_MK_time),
		   timeTag] dataUsingEncoding:NSNEXTSTEPStringEncoding]];
        }
	p->timeTag = timeTag;
    }
    else if (timeTag < p->timeTag) 
      MKErrorCode(MK_outOfOrderErr,timeTag,p->timeTag);
    if (aNote) 
      _MKWriteNote2(aNote,aPart,p);
    return p;
}

