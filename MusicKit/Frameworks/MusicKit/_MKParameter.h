/*
  $Id$
  Defined In: The MusicKit
  Description:

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.5  2000/06/09 14:59:57  leigh
  Removed objc.h

  Revision 1.4  2000/05/06 00:30:48  leigh
  Better typing of _MKParAsInt()

  Revision 1.3  2000/02/07 00:30:14  leigh
  removed _MKHighestPar()

  Revision 1.2  1999/07/29 01:25:59  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/04/23/90 - Created from _musickit.h 
  08/13/90/daj - Added _MKParNameStr().
*/
#ifndef __MK__parameter_H___
#define __MK__parameter_H___

#import <Foundation/Foundation.h>
//#import <Foundation/NSData.h> /*sb... */
//#import <Foundation/NSArchiver.h> /*sb... */
#import "params.h" /*sb... */
//#import <objc/objc.h> /*sb... */

typedef union __MKParameterUnion {
    /* Used for Parameters and scoreFile parsing. */
    id symbol;        /* This type is needed for scorefile parsing.
			 Also used for storing envelopes and wavetables. */
    double rval;
    NSString *sval;
    int ival;
} _MKParameterUnion;

typedef struct __MKParameter 
{
    _MKParameterUnion _uVal;    /* Value. */
    short _uType;               /* Type of union. */
    short parNum;               /* Number of this parameter. */
}
_MKParameter;

#define _MK_FIRSTAPPPAR  (MK_MKPARBITVECTS * 32)

/* _MKParameter and _MKParName object 'methods' */
extern id _MKParNameObj(int aPar);
extern NSString *_MKParNameStr(int aPar);
extern const char *_MKUniqueNull();
extern BOOL _MKKeyNumPrintfunc();
extern BOOL _MKParInit();
extern _MKParameter *_MKNewStringPar();
extern _MKParameter *_MKNewDoublePar();
extern _MKParameter *_MKNewIntPar();
extern _MKParameter *_MKNewObjPar();
extern _MKParameter *_MKSetDoublePar();
extern double _MKParAsDouble();
extern _MKParameter *_MKSetIntPar();
extern int _MKParAsInt(_MKParameter *param);
extern _MKParameter *_MKSetStringPar();
extern NSString *_MKParAsString();
extern _MKParameter *_MKSetObjPar();
extern id _MKParAsObj();
extern id _MKParAsEnv();
extern id _MKParAsWave();
extern _MKParameterUnion *_MKParRaw();
extern NSString * _MKParAsStringNoCopy();
extern BOOL _MKIsParPublic();
extern _MKParameter * _MKCopyParameter(_MKParameter *aPar);

#import "_scorefile.h"

extern void _MKParWriteStdValueOn(_MKParameter *rcvr,NSMutableData *aStream,
				  _MKScoreOutStruct *p);
extern void _MKParWriteOn(_MKParameter *rcvr,NSMutableData *aStream,
			  _MKScoreOutStruct *p);
extern void _MKParWriteValueOn(_MKParameter *rcvr,NSMutableData *aStream,
			  _MKScoreOutStruct *p);
extern unsigned _MKGetParNamePar(id aParName);
extern void _MKArchiveParOn(_MKParameter *param,NSCoder *aTypedStream); /*sb: NSCoder originally ocnverted as NSArchiver */
extern void _MKUnarchiveParOn(_MKParameter *param,NSCoder *aTypedStream); /*sb: originally ocnverted as NSArchiver */
extern id  _MKDummyParameter();
extern BOOL _MKIsPar(unsigned aPar);
extern BOOL _MKIsPrivatePar(unsigned aPar);

typedef enum __MKPrivPar {
    _MK_dur = ((int)MK_privatePars + 1),
    _MK_maxPrivPar /* Must be <= MK_appPars */
}
_MKPrivPar;

extern _MKParameter *_MKFreeParameter(_MKParameter *param);



#endif
