/*
  $Id$
  Defined In: The MusicKit

  Description: this is included in MKFilePerformer.m

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
Modification history:

  $Log$
  Revision 1.3  2000/04/16 04:03:38  leigh
  comment cleanup

  Revision 1.2  1999/07/29 01:26:18  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/

-setFirstTimeTag:(double) aTimeTag
  /* TYPE: Accessing time; Sets firstTimeTag to aTimeTag
   * Sets the variable firstTimeTag to aTimeTag and 
   * returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, else self.
   *
   * firstTimeTag is used in subclasses such as PartSegment
   * to establish the smallest timeTag value that's considered for
   * performance.  
   */
{ 
    if (status != MK_inactive) 
      return nil;
    firstTimeTag = aTimeTag;
    return self;
}		

-setLastTimeTag:(double) aTimeTag
  /* TYPE: Accessing time; Sets lastTimeTag to aTimeTag
   * Sets the variable lastTimeTag to aTimeTag and 
   * returns the receiver.
   * Illegal while the receiver is active. Returns nil in this case, else self.
   *
   * lastTimeTag is used in subclasses such as PartSegment
   * to establish the greatest timeTag value that's considered for
   * performance.  
   */
{ 
    if (status != MK_inactive) 
      return nil;
    lastTimeTag = aTimeTag;
    return self;
}		


-(double)firstTimeTag 
  /* TYPE: Accessing time; Returns the value of firstTimeTag.
   * Returns the value of the receiver's firstTimeTag variable.
   */
{
	return firstTimeTag;
}

-(double)lastTimeTag 
  /* TYPE: Accessing time; Returns the value of lastTimeTag.
   * Returns the value of the receiver's lastTimeTag variable.
   */
{
	return lastTimeTag;
}

