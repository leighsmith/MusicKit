/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.5  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2000/05/06 00:58:14  leigh
  typed parameters to reduce warnings

  Revision 1.3  2000/04/01 22:11:01  leigh
  Fixed warnings from finicky compilers

  Revision 1.2  1999/07/29 01:25:54  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  4/26/90/daj - For a bit of efficiency, changed _MKTrace() to direct ref 
                to _MKTraceFlag, since _MKTraceFlag is, indeed, a 
                "private extern". Might want to do the same for
		_MKGetOrchSimulator (using @defs)
*/
#ifndef __MK__Orchestra_H___
#define __MK__Orchestra_H___

#import "_DSPMK.h"

#import "MKOrchestra.h"

#define _MK_ORCHTRACE(_orch,_debugFlag) \
  ((_MKTraceFlag & _debugFlag) || (_MKGetOrchSimulator(_orch)))

/* MKOrchestra functions */
extern id MKOrchestraClasses(void);
extern void _MKOrchResetPreviousLosingTemplate(id self);
extern id _MKFreeMem(id self,MKOrchAddrStruct *mem);
extern int _MKAddTemplate(id aNewTemplate);
extern FILE *_MKGetOrchSimulator();
extern DSPFix48 *_MKCurSample(id orch);
extern void _MKOrchAddSynthIns(id anIns);
extern void _MKOrchRemoveSynthIns(id anIns);
extern BOOL _MKOrchLateDeltaTMode(id theOrch); /* See MKOrchestra.m ***SIGH*** */

@interface MKOrchestra(Private)

+(NSMutableArray **)_addTemplate:aNewTemplate ;
+allocFromZone:(NSZone *)zone onDSP:(unsigned short)index;
-_adjustOrchTE:(int)yesOrNo reset:(int)reset;
-_notifyAbort;
-_clearNotification;

@end



#endif
