#ifndef __MK__ParName_H___
#define __MK__ParName_H___
/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
#import <Foundation/NSObject.h>

#import "_MKParameter.h"

@interface _ParName : NSObject
{
    BOOL (*printfunc)(_MKParameter *param,NSMutableData *aStream,
		      _MKScoreOutStruct *p);
    int par;
    char *s;
}

@end



#endif
