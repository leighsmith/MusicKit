/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:57  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__SynthData_H___
#define __MK__SynthData_H___

#import "MKSynthData.h"
@interface MKSynthData(Private)

-(MKOrchMemStruct *) _resources;
-_deallocAndAddToList;
+(id)_newInOrch:(id)anOrch index:(unsigned short)whichDSP
 length:(unsigned int)size segment:(MKOrchMemSegment)whichSegment 
 baseAddr:(DSPAddress)addr isModulus:(BOOL)yesOrNo;
-(MKOrchMemStruct *)_setSynthPatch:aSynthPatch;
-(void)_setShared:aSharedKey;
-(void)_addSharedSynthClaim;

@end



#endif
