/*
  $Id$
  Defined In: The MusicKit

  Description: This file is included by UnitGenerator.m and SynthData.m

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:26:17  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  11/20/89/daj - Minor change to do lazy garbage collection of synth data. 
   8/27/90/daj - Added override of allocFromZone: and copyFromZone:
                 Changed -free to be like [self dealloc]. 
*/
#import <objc/objc.h>
#import <Foundation/NSZone.h>

+new 
  /* We override this method since instances are never created directly.
     They are always created by the Orchestra.
     A private version of +new is used internally. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

+ allocWithZone:(NSZone *)zone
  /* We override this method since instances are never created directly.
     They are always created by the Orchestra.
     A private version of +new is used internally. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

+alloc;
  /* We override this method since instances are never created directly.
     They are always created by the Orchestra.
     A private version of +new is used internally. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

- (void)dealloc /*sb: used to be -free before OS conversion */
{
    [self mkdealloc];
    [super dealloc]; /*sb: added */
}

-copy
  /* We override this method since instances are never created directly. 
     They are always created by the Orchestra. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

- copyWithZone:(NSZone *)zone
  /* We override this method since instances are never created directly. 
     They are always created by the Orchestra. */
{
    [self doesNotRecognizeSelector:_cmd];  return nil;
}

+orchestraClass
  /* This method always returns the Orchestra factory. It is provided for
   applications that extend the Music Kit to use other hardware. Each 
   subclass is associated with a particular kind of hardware.
   The default hardware is that represented by Orchestra, the DSP56001.

   If you have some other hardware, you do the following:
   1. Make an analog to the Orchestra class for your hardware.
   2. Add this class to the List returned by MKOrchestraFactories().
   3. Make a subclass and override +orchestraFactory to return 
   the class you designed. 
   4. You also need to override some other methods. This 
   procedure is not documented yet. Talk to the NeXT developer support group 
   for more
   information. They can also tell you exactly what part of the Orchestra
   protocol your Orchestra analog needs to support.
   */
{
    return _MKClassOrchestra();
}

-orchestra
    /* returns the orchestra instance to which the receiver belongs. */
{
    return orchestra;
}

-(BOOL)isFreeable
  /* Used by the Orchestra instance to determine when the receiver may
     be freed. Returns YES if the receiver is not allocated or is part of 
     a SynthPatch which is freeable. */
{
    return ((![self isAllocated]) || (synthPatch && [synthPatch isFreeable]));
}

-(id)synthPatch
    /* Returns the SynthPatch of which the receiver is a member, if any. */
{
    return synthPatch;
}

- (void)mkdealloc /*sb: changed from dealloc to avoid conflict with foundation kit */
  /* Deallocates receiver and frees synthpatch of which it's a member, if any. 
   */
{
    _MKDeallocSynthElementSafe(self,ISDATA);
    return;
}

-(int)instanceNumber
{
    return _instanceNumber;
}
