/*
  $Id$
  Defined In: The MusicKit

  Description:
    This class is used for variable values. Setting a ScorefileVar never
    changes its type unless it is an Untyped score var. Automatic type
    conversion is done where possible.

    This is a private musickit class.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
  $Log$
  Revision 1.3  2000/05/13 17:16:49  leigh
  Doco cleanup and stricter typing of parameters

  Revision 1.2  1999/07/29 01:26:01  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__ScorefileVar_H___
#define __MK__ScorefileVar_H___

#import <Foundation/NSObject.h>

/* _ScorefileVar functions */ 
#import "_MKParameter.h"
#import "tokens.h"

@interface _ScorefileVar : NSObject
{
    _MKToken token;
    _MKParameter *myParameter;          /* Used internally to store value. */
    BOOL (*preDaemon)();
    /* preDaemon is an optional function of three arguments:
       id varObject; _MKToken newValueType; and char *ptrToNewValue;
       It is called before the value is set and is used to filter bad values.
       It returns YES if the value should be set or NO if it should not be set.
       */
    void (*postDaemon)();
    /* postDaemon is an optional function of one arguments:
       id ScorefileVarObject;
       It is called after the value has been set.
       */
    BOOL readOnly;   /* YES, if variable should not be changed. */
    NSString *s;     // name string of the variable.
}

- copy;
- writeScorefileStream:(NSMutableData *)aStream; 
- (NSString *) varName;
- (void)dealloc; 

@end

extern _MKParameter *_MKSFVarGetParameter(id sfVar);
extern _ScorefileVar *_MKNewScorefileVar(_MKParameter *aPar,NSString * name,BOOL untyped, BOOL isReadOnly);
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

#endif
