/*
  $Id$
  Defined In: The MusicKit

  Description:
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:03  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  04/21/90/daj - Changed _addShardSynthClaim to be void type
*/

-(MKOrchMemStruct *)_setSynthPatch:aSynthPatch     
  /* Private method used by SynthPatch to add the receiver to itself. */
{
    synthPatch = aSynthPatch;
    return [self _resources];
}

-(void)_setShared:aSharedKey
  /* makes object shared. If aSharedKey is nil, makes it unshared.
     Private method. */
{
    _sharedKey = aSharedKey;
}

-(void)_addSharedSynthClaim
  /* increment ref count */
{
    _MKAddSharedSynthClaim(_sharedKey);
}

-(oneway void)dealloc
{
    if (_MK_ORCHTRACE(orchestra,MK_TRACEORCHALLOC))
        _MKOrchTrace(orchestra,MK_TRACEORCHALLOC,"Really deallocating object %s_%p",[NSStringFromClass([self class]) cString],
                     self);

    [super dealloc];
}
