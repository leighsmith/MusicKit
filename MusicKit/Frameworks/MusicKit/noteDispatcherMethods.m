/*
  $Id$
  Defined In: The MusicKit

  Description:
    Methods used in MKPerformer and MKNoteFilter.
 
  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2004, The MusicKit Project.
*/
/*
 Modification history prior to commit to CVS:

  09/26/90/daj & lbj - Changed freeNoteSenders to make sure receiver's not
                       in performance. 
  02/25/91/daj - Added disconnectNoteSenders to be symmetrical with 
                 Instrument's disconnectNoteReceivers.
  03/08/95/daj - Fixed bug in removeNoteSenders.
*/

- (NSArray *) noteSenders
  /* TYPE: Processing
   * Returns a copy of the receiver's MKNoteSender Array. 
   */
{
     return _MKLightweightArrayCopy(noteSenders);
}
// return [noteSenders retain];  // no copy.

//   return [noteSenders copy];  // This copies a new array but the elements are the original noteSenders.
                               // If we copied the noteSenders we couldn't then connect senders 

- (BOOL) isNoteSenderPresent: (MKNoteSender *) aNoteSender
  /* Returns YES if aNoteSender is a member of the receiver's 
     MKNoteSender Array. */
{
    return [noteSenders containsObject: aNoteSender];
}

- releaseNoteSenders
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

- removeNoteSenders
  /* Empties noteSenders by repeatedly sending removeNoteSender:
     with each element of the collection as the argument. */
{
    unsigned i;
    
    if (!noteSenders)
	return self;
    i = [noteSenders count]; 
    /* We remove them in the reverse order, which should work (!) */
    while (i--) 
	[self removeNoteSender: [noteSenders objectAtIndex: i]];
    return self;
}

- (MKNoteSender *) noteSender
  /* Returns the default MKNoteSender. This is used when you don't care
     which MKNoteSender you get. */
{
    if ([noteSenders count] == 0)
        [self addNoteSender: [[MKNoteSender alloc] init]];
    return [noteSenders objectAtIndex: 0];
}

- disconnectNoteSenders
    /* Broadcasts "disconnect" to MKNoteSenders. */ 
{
    [noteSenders makeObjectsPerformSelector: @selector(disconnect)];
    return self;
}
