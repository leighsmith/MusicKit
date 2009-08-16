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
  Revision 1.1  2000/06/09 03:19:07  leigh
  Added MKPatchConnection to remove a struct which required Storage

*/
#ifndef __MK_PatchConnection_H___
#define __MK_PatchConnection_H___

#import <Foundation/Foundation.h>

@interface MKPatchConnection : NSObject
{
@public
    unsigned _toObjectOffset;	
    unsigned _argObjectOffset;
    SEL _aSelector;
    IMP _methodImp;
}

- initWithTargetObjectOffset: (int) toObjInt selector: (SEL) aSelector argument: (int) withObjInt;

@end

#endif
