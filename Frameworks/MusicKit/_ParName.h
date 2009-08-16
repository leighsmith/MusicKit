/*
 $Id$
 Defined In: The MusicKit
 
 Description:
 This class defines the parameter-representation mechanism and is a private
 MusicKit class used for parameter names.
 
 Each parameter is represented by a unique instance of _ParName.
 They have an optional function which is called when the parameter value is written and
 they have a low integer value, the particular parameter.
 The printfunc allows particular parameters to write in
 special ways. For example, keyNum writes using the keyNum constants.
 You never instantiate instances of this class directly.
 
 The term "parameter" is, unfortunately, used loosely for several things.
 This could be cleaned up, but it's all private functions, so it's just
 an annoyance to the maintainer:
 
 1) An object, of class _ParName, that represents the parameter name. E.g.
 there is only one instance of this object for all frequency parameters.
 
 2) A low integer that corresponds to the _ParName object. E.g. the constant
 MK_freq is a low integer that represents all frequency parameters.
 
 3) A string name that corresponds to the _ParName object. E.g. "freq".
 
 4) A struct called _MKParameter, that represents the particular parameter
 value.  E.g. there is one _MKParameter for each note containing a frequency.
 
 The _ParName contains the string name, the low integer, and a function
 (optional) for printing the parameter values in a special way.
 
 The _MKParameter contains the data, the type of the data, and the
 low integer. There's an array that maps low integers to _ParNames.
 
 MKNote objects contain an NSHashTable of _MKParameters. @see MKNote.m
 
 Note that the code for writing scorefiles is spread between writeScore.m,
 MKNote.m, and _ParName.m. This is for reasons of avoiding inter-module
 communication (i.e. minimizing globals). Perhaps the scorefile-writing
 should be more cleanly isolated.
  
 Original Author: David A. Jaffe
 
 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1999-2006, The MusicKit Project.
 
 Modification history in CVS at musickit.org
 */
#ifndef __MK__ParName_H___
#define __MK__ParName_H___

#import <Foundation/Foundation.h>

#import "_MKParameter.h"

@interface _ParName : NSObject
{
    // printfunc is a function for writing the value of the par.
    // See _ParName.m for details.
    BOOL (*printfunc)(_MKParameter *param, NSMutableData *aStream, _MKScoreOutStruct *p);
    int par;    /* What parameter this is. */
    NSString *s;    /* Name of parameter */
}

@end

extern unsigned _MKGetParNamePar(_ParName *aParName);

#endif
