#ifndef __MK__Orchestra_H___
#define __MK__Orchestra_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Modification history:

   4/26/90/daj - For a bit of efficiency, changed _MKTrace() to direct ref 
                 to _MKTraceFlag, since _MKTraceFlag is, indeed, a 
		 "private extern". Might want to do the same for
		 _MKGetOrchSimulator (using @defs)

*/

#import "_DSPMK.h"

#import "MKOrchestra.h"

#define _MK_ORCHTRACE(_orch,_debugFlag) \
  ((_MKTraceFlag & _debugFlag) || (_MKGetOrchSimulator(_orch)))

/* Orchestra functions */
extern id MKOrchestraClasses(void);
extern void _MKOrchResetPreviousLosingTemplate(id self);
extern id _MKFreeMem(id self,MKOrchAddrStruct *mem);
extern _MKAddTemplate(id aNewTemplate);
extern FILE *_MKGetOrchSimulator();
extern DSPFix48 *_MKCurSample(id orch);
extern void _MKOrchAddSynthIns(id anIns);
extern void _MKOrchRemoveSynthIns(id anIns);
extern BOOL _MKOrchLateDeltaTMode(id theOrch); /* See Orchestra.m ***SIGH*** */

@interface MKOrchestra(Private)

+(id *)_addTemplate:aNewTemplate ;
+allocFromZone:(NSZone *)zone onDSP:(unsigned short)index;
-_adjustOrchTE:(int)yesOrNo reset:(int)reset;
-_notifyAbort;
-_clearNotification;

@end



#endif
