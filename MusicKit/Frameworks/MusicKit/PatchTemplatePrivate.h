/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:25:56  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  daj/04/23/90 - Created from _musickit.h
*/
#ifndef __MK__PatchTemplate_H___
#define __MK__PatchTemplate_H___

#import "MKPatchTemplate.h"

/* PatchTemplate functions */
extern BOOL _MKIsClassInTemplate(id templ,id factObj);
extern id _MKDeallocatedSynthPatches(id templ,int orchIndex);
extern void _MKEvalTemplateConnections(id templ,id synthPatchContents);
extern void _MKSetTemplateEMemUsage(id templ,MKOrchMemStruct *reso);
extern unsigned _MKGetTemplateEMemUsage(id templ);
extern id _MKAllocSynthPatch(id templ,id synthPatchFactory,id anOrch,int orchIndex);

#endif
