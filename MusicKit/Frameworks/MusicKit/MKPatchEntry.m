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
  Revision 1.1  2000/06/09 17:17:50  leigh
  Added MKPatchEntry replacing deprecated Storage class

*/
#import "MKPatchEntry.h"

@implementation MKPatchEntry

- initWithClass: (id) aClass type: (unsigned short) aType
{
    entryClass = aClass;
    type = aType;
    return self;
}

- initWithClass: (id) aClass type: (unsigned short) aType segment: (unsigned short) seg
{
    segment = seg;
    return [self initWithClass: aClass type: aType];
}

- initWithClass: (id) aClass type: (unsigned short) aType segment: (unsigned short) seg length: (unsigned) len
{
    length = len;
    return [self initWithClass: aClass type: aType segment: seg];
}

- (unsigned short) type
{
    return type;
}

- (unsigned short) segment
{
    return segment;
}

- (unsigned) length
{
    return length;
}

- entryClass
{
    return entryClass;
}

@end
