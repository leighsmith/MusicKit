/*
  $Id$
  Defined In: The MusicKit

  Description:
    Private class.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000 The MusicKit Project.
*/
#ifndef __MK__SharedSynthInfo_H___
#define __MK__SharedSynthInfo_H___

#import <Foundation/NSObject.h>
#import <Foundation/NSDictionary.h>

@interface _SharedSynthInfo : NSObject
{
    id synthObject;           /* The value we're interested in finding. */
    NSMutableArray *theList;  /* Back pointer to the NSMutableArray of values that match the keyObj. */
    id theKeyObject;          /* Back pointer to key object. */
    MKOrchMemSegment segment; /* Which segment or MK_noSegment for wildcard. */
    int length;               /* Or 0 for wild card */
    int referenceCount;       
    MKOrchSharedType type;        /* Which type or MK_noOrchSharedType for wildcard. */
}

@end

/* _SharedSynthKey functions */
extern BOOL _MKCollectSharedDataGarbage(id orch, NSHashTable *garbageTable);
extern NSHashTable *_MKGetSharedSynthGarbage(MKOrchestra *self);
extern BOOL _MKInstallSharedObject(NSMutableDictionary* _sharedSet, id aSynthObj, id aKeyObj,
				   MKOrchMemSegment whichSegment, int howLong,
				   MKOrchSharedType type);
extern id _MKFindSharedSynthObj(NSMutableDictionary* sharedSet, NSHashTable *garbageTable, id aKeyObj,
				MKOrchMemSegment whichSegment, int howLong, MKOrchSharedType type);
extern void _MKAddSharedSynthClaim(_SharedSynthInfo *aKey);
extern id _MKFreeSharedSet(NSMutableDictionary *sharedSet, NSHashTable **garbageTable);
extern NSMutableDictionary* _MKNewSharedSet(NSHashTable **garbageTable);
extern BOOL _MKReleaseSharedSynthClaim(_SharedSynthInfo *aKey, BOOL lazy);
extern int _MKGetSharedSynthReferenceCount(_SharedSynthInfo *sharedSynthKey);

#endif
