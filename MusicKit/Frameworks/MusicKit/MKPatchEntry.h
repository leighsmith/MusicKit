/*
  $Id$
  Defined In: The MusicKit

  Description:

  Original Author: Leigh M. Smith <leigh@tomandandy.com>

  Copyright (c) 1999 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and this copyright message remains intact
  and accompanies all derived code.
*/
/*
  $Log$
  Revision 1.1  2000/06/09 17:17:49  leigh
  Added MKPatchEntry replacing deprecated Storage class

*/
#import <Foundation/Foundation.h>

@interface MKPatchEntry : NSObject
{
    id entryClass;            /* Which class. */
    unsigned short type;      /*  */
    unsigned short segment;   /* Used only for data memory. MKOrchMemSegment. */
    unsigned length;          /* Length of data. */
}

- initWithClass: (id) entryClass type: (unsigned short) aType segment: (unsigned short) segment length: (unsigned) len;
- initWithClass: (id) entryClass type: (unsigned short) aType segment: (unsigned short) segment;
- initWithClass: (id) entryClass type: (unsigned short) aType;
- (unsigned short) type;
- (unsigned short) segment;
- (unsigned) length;
- entryClass;
@end
