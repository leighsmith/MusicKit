/*
  $Id$
  Defined In: The MusicKit
  Description:
    Functions for writing and reading text and binary score files.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2005, The MusicKit Project.
*/

#ifndef __MK__scorefile_H___
#define __MK__scorefile_H___

#import <Foundation/Foundation.h>

#import "_MKNameTable.h"

typedef struct __MKScoreInStruct { 
    double timeTag;                 /* Time of most recently read note. */
    id part;                        /* part to which current note goes.*/
    BOOL isInBody;                  /* YES if we've already parsed the header 
				     */
    NSMutableData *printStream;          /* Stream used for scorefile print output */
    BOOL _freeStream;               /* YES if stream was auto-created to
				       go to stderr */
    void *_parsePtr;                /* Private pointer to parse state. */
    _MKNameTable *_symbolTable;     /* Private symbol table used for parse. */
    NSMutableDictionary *_noteTagTable; /* Private map to unique set of noteTags.*/
    int _fileHighTag,_fileLowTag;   /* Private. Tag range. */
    int _newLowTag;                 /* Private. Tag base for noteTag map. */
    id _aNote;                      /* Private. parser 'owns' note. */
    char *_ranState;                /* Private. So each file has its own random
				       sequence. */
    id _owner;                      /* Private. Where to put part decls. */
    int _errCount;                  /* Error count. */
    NSMutableArray *_binaryIndexedObjects; /* List of indexed objects. */
    BOOL _binary;
    void *_repeatStack;
} _MKScoreInStruct;

typedef struct __MKScoreOutStruct { 
    double timeTag;                  /* Time of most recently written note,
				        including timeShift. */
    BOOL isInBody;                   /* YES if first note has been written. */
    NSMutableData *_stream;          /* The output file. */
    id _owner;                       /* Private */
    _MKNameTable *_nameTable;        /* Private */
    BOOL _ownerIsNoteRecorder;       /* Private. */
    double _timeShift;               /* Added to time tags before writing. */ 
    long _tagRangePos;
    NSMapTable *_binaryIndecies;     /* For encoding objects in binary files. (mapping from object to index) */
    int _highBinaryIndex;            /* Currently highest index. */
    BOOL _binary;
} _MKScoreOutStruct;

/* Functions for writing score files: */
extern _MKScoreOutStruct *
_MKInitScoreOut(NSMutableData *fileStream,id owner,id anInfoNote,
		  double timeShift,BOOL isNoteRecorder,BOOL binary);
extern _MKScoreOutStruct *
  _MKWritePartDecl(id part, _MKScoreOutStruct * p,id aPartInfo);
extern _MKScoreOutStruct *
  _MKWriteNote(id aNote, id aPart, _MKScoreOutStruct * scoreWPtr);
extern _MKScoreOutStruct *
  _MKFinishScoreOut(_MKScoreOutStruct * scoreWPtr,   BOOL writeEnd);

/* Functions for reading score files: */
extern void _MKParseScoreHeader(_MKScoreInStruct *scorefileRPtr);
extern _MKScoreInStruct *_MKNewScoreInStruct(NSData *aStream,id owner,
                    NSMutableData *printStream,
                    BOOL mergeParts,NSString *name,unsigned int *pointer);
extern BOOL _MKParseScoreHeaderStmt(_MKScoreInStruct *scorefileRPtr);
extern id _MKParseScoreNote(_MKScoreInStruct * scorefileRPtr);
extern _MKScoreInStruct *_MKFinishScoreIn(_MKScoreInStruct *scorefileRPtr);

extern const char *_MKTranstab(); /* defined in parseScore.m */

/* functions for writing binary scorefiles */
extern void _MKWriteIntPar(NSMutableData *aStream,int anInt);
extern void _MKWriteDoublePar(NSMutableData *aStream,double aDouble);
extern void _MKWriteStringPar(NSMutableData *aStream,NSString *aString);
extern void _MKWriteVarPar(NSMutableData *aStream,NSString *aString);
extern void _MKWriteInt(NSMutableData *aStream,int anInt);
extern void _MKWriteShort(NSMutableData *aStream,short anShort);
extern void _MKWriteDouble(NSMutableData *aStream,double aDouble);
extern void _MKWriteChar(NSMutableData *aStream,char aChar);
extern void _MKWriteString(NSMutableData *aStream,char *aString);
extern void _MKWriteNSString(NSMutableData *aStream,NSString *aString);
extern void _MKWriteFloat(NSMutableData *aStream,float aFloat);

#define _MK_BINARYSCOREFILEEXT @"playscore"
#define _MK_SCOREFILEEXT @"score"

#endif
