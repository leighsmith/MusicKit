/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Modification history:

   09/26/90/daj & lbj - Changed freeNoteSenders to make sure receiver's not
                        in performance. 
   02/25/91/daj - Added disconnectNoteSenders to be symmetrical with 
                  Instrument's disconnectNoteReceivers.
   03/08/95/daj - Fixed bug in removeNoteSenders.
*/
#import <objc/objc.h>

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

-freeNoteSenders
  /* TYPE: Creating
   * Empties and frees contents of \fBnoteSenders\fR.
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
//    [aList release]; // don't release because aList is autoreleased
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

