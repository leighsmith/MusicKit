/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 2.1  2006/02/05 17:57:10  leighsmith
  Cleaned up prototypes for Xcode 2.2 as it is much more strict about mixing id with a defined type

  Revision 2.0  2004/12/06 18:09:03  leighsmith
  Beginning of rewrite to use the SndKit for native synthesis

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
extern void _MKOrchResetPreviousLosingTemplate(MKOrchestra *self);
extern id _MKFreeMem(MKOrchestra *self, MKOrchAddrStruct *mem);
extern int _MKAddTemplate(id aNewTemplate);
extern FILE *_MKGetOrchSimulator();
extern DSPFix48 *_MKCurSample(MKOrchestra *orch);
extern void _MKOrchAddSynthIns(id anIns);
extern void _MKOrchRemoveSynthIns(id anIns);
extern BOOL _MKOrchLateDeltaTMode(MKOrchestra *theOrch); /* See MKOrchestra.m ***SIGH*** */

@interface MKOrchestra(Private)

+(NSMutableArray **)_addTemplate:aNewTemplate ;
-_adjustOrchTE:(int)yesOrNo reset:(int)reset;
-_notifyAbort;
-_clearNotification;

@end



#endif
