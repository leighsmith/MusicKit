/*
  $Id$
  
  Defined In: The MusicKit
  Description:

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.2  2001/09/08 20:22:09  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

*/
#import <Foundation/NSObject.h>
#import <libc.h>

@interface _MKList:NSObject
{
    id *theList;
}
-(void)init;
-(void)dealloc;
-(id)objectAtIndex:(int)indx;
-(id *)baseAddress;

@end
