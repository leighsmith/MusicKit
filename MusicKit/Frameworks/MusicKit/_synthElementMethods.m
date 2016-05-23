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
  Revision 1.4  2002/01/29 16:05:59  sbrandon
  re-typed _MKOrchTrace calls to use NSString

  Revision 1.3  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.2  1999/07/29 01:26:03  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  04/21/90/daj - Changed _addShardSynthClaim to be void type
*/

-(MKOrchMemStruct *)_setSynthPatch:aSynthPatch     
  /* Private method used by MKSynthPatch to add the receiver to itself. */
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

/*
-(oneway void)dealloc
{
    if (_MK_ORCHTRACE(orchestra,MK_TRACEORCHALLOC))
        _MKOrchTrace(orchestra,MK_TRACEORCHALLOC,@"Really deallocating object %@_%p",NSStringFromClass([self class]),
                     self);

    [super dealloc];
}
*/