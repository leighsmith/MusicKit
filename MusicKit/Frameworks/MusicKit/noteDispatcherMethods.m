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
  Revision 1.5  2000/04/25 02:08:39  leigh
  Renamed free methods to release methods to reflect OpenStep behaviour

  Revision 1.4  2000/04/16 04:05:07  leigh
  comment cleanup

  Revision 1.3  2000/04/04 00:14:10  leigh
  Removed crufty include file

  Revision 1.2  1999/07/29 01:26:10  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/26/90/daj & lbj - Changed freeNoteSenders to make sure receiver's not
                       in performance. 
  02/25/91/daj - Added disconnectNoteSenders to be symmetrical with 
                 Instrument's disconnectNoteReceivers.
  03/08/95/daj - Fixed bug in removeNoteSenders.
*/

-noteSenders
  /* TYPE: Processing
   * Returns a copy of the receiver's NoteSender Array. 
   */
{
     return _MKLightweightArrayCopy(noteSenders);
}
// return [noteSenders retain];  // no copy.

//   return [noteSenders copy];  // This copies a new array but the elements are the original noteSenders.
                               // If we copied the noteSenders we couldn't then connect senders 

-(BOOL)isNoteSenderPresent:(id)aNoteSender
  /* Returns YES if aNoteSender is a member of the receiver's 
     NoteSender List. */
{
    return [noteSenders containsObject:aNoteSender];
}

-releaseNoteSenders
  /* TYPE: Creating
   * Empties and frees contents of noteSenders.
   * Returns the receiver.
   */
{
    NSMutableArray * aList; //sb: static type
    if ([self inPerformance])
      return nil;
    aList = _MKLightweightArrayCopy(noteSenders);
    [self removeNoteSenders];
    [aList removeAllObjects];  /* Split this up because elements may try
			     and remove themselves from noteSenders
			     when they are freed. */
    // don't release aList because it is autoreleased by _MKLightweightArrayCopy
    return self;
}

-removeNoteSenders
  /* Empties noteSenders by repeatedly sending removeNoteSender:
     with each element of the collection as the argument. */
{
    unsigned i;
    if (!noteSenders)
      return self;
    i = [noteSenders count]; 
    /* We remove them in the reverse order, which should work (!) */
    while (i--) 
      [self removeNoteSender:[noteSenders objectAtIndex:i]];
    return self;
}

-noteSender
  /* Returns the default NoteSender. This is used when you don't care
     which NoteSender you get. */
{
    if ([noteSenders count] == 0)
        [self addNoteSender:[[MKNoteSender alloc] init]];
    return [noteSenders objectAtIndex:0];
}

-disconnectNoteSenders
    /* Broadcasts "disconnect" to NoteSenders. */ 
{
    [noteSenders makeObjectsPerformSelector:@selector(disconnect)];
    return self;
}

