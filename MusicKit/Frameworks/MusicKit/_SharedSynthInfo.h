/*
  $Id$
  Defined In: The MusicKit

  Description:
    Private class.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
  $Log$
  Revision 1.3  1999/11/07 05:10:45  leigh
  Doco cleanup

  Revision 1.2  1999/07/29 01:26:01  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK__SharedSynthInfo_H___
#define __MK__SharedSynthInfo_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSDictionary.h>

/* _SharedSynthKey functions */
extern BOOL _MKCollectSharedDataGarbage(id orch,NXHashTable *garbageTable);
extern NXHashTable *_MKGetSharedSynthGarbage(id self);
extern BOOL _MKInstallSharedObject(NSMutableDictionary* _sharedSet,id aSynthObj,id aKeyObj,
				   MKOrchMemSegment whichSegment,int howLong,
				   MKOrchSharedType type);
extern id _MKFindSharedSynthObj(NSMutableDictionary* sharedSet,NXHashTable *garbageTable,id aKeyObj,
				MKOrchMemSegment whichSegment,int howLong,MKOrchSharedType type);
extern void _MKAddSharedSynthClaim(id aKey);
extern id _MKFreeSharedSet(NSMutableDictionary* sharedSet,NXHashTable **garbageTable);
extern NSMutableDictionary* _MKNewSharedSet(NXHashTable **garbageTable);
extern BOOL _MKReleaseSharedSynthClaim(id aKey,BOOL lazy);
extern int _MKGetSharedSynthReferenceCount(id sharedSynthKey);

@interface _SharedSynthInfo : NSObject
{
    id synthObject;           /* The value we're interested in finding. */
    id theList;               /* Back pointer to the NSMutableArray of values that match the keyObj. */
    id theKeyObject;          /* Back pointer to key object. */
    MKOrchMemSegment segment; /* Which segment or MK_noSegment for wildcard. */
    int length;               /* Or 0 for wild card */
    int referenceCount;       
    MKOrchSharedType type;        /* Which type or MK_noOrchSharedType for wildcard. */
}

@end

#endif
