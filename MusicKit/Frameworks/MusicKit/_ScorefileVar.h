/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:26:01  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__ScorefileVar_H___
#define __MK__ScorefileVar_H___

#import <Foundation/NSObject.h>

/* _ScorefileVar functions */ 
#import "_MKParameter.h"
#import "tokens.h"

extern _MKParameter *_MKSFVarGetParameter(id sfVar);
extern id _MKNewScorefileVar(_MKParameter *aPar,NSString * name,BOOL untyped,
			     BOOL isReadOnly);
extern int _MKSFVarInternalType(id sfVar);
extern _MKParameterUnion *_MKSFVarRaw(id sfVar);
extern int _MKSetDoubleSFVar(id sfVar,double floval);
extern int _MKSetIntSFVar(id sfVar,int  intval);
extern int _MKSetStringSFVar(id sfVar,NSString * strval);
extern int _MKSetEnvSFVar(id sfVar,id envelope);
extern int _MKSetWaveSFVar(id sfVar,id waveTable);
extern int _MKSetObjSFVar(id sfVar,id anObj);
extern id _MKSetScorefileVarPreDaemon();
extern id _MKSetScorefileVarPostDaemon();
extern id _MKSetReadOnlySFVar(id sfVar,BOOL yesOrNo);
void _MKSFSetPrintfunc();

@interface _ScorefileVar : NSObject
{
	_MKToken token;
	_MKParameter *myParameter;
	BOOL (*preDaemon)();
	void (*postDaemon)();
	BOOL readOnly;
	NSString *s;
}
- copy;
- writeScorefileStream:(NSMutableData *)aStream; 
-(NSString *)varName;
- (void)dealloc; 

@end



#endif
