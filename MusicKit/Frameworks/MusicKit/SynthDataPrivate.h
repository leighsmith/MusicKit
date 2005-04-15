/*
  $Id$
  Defined In: The MusicKit

  Description:

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/

#ifndef __MK__SynthData_H___
#define __MK__SynthData_H___

#import "MKSynthData.h"

@interface MKSynthData(Private)

- (MKOrchMemStruct *) _resources;

- _deallocAndAddToList;

+ (id) _newInOrch: (MKOrchestra *) anOrch
            index: (unsigned short) whichDSP
	   length: (unsigned int) size
	  segment: (MKOrchMemSegment) whichSegment 
         baseAddr: (DSPAddress) addr
        isModulus: (BOOL) yesOrNo;

- (MKOrchMemStruct *) _setSynthPatch: aSynthPatch;

- (void) _setShared: aSharedKey;

- (void) _addSharedSynthClaim;

@end

#endif
