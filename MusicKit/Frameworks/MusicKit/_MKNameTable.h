/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  $Id$
  Defined In: The MusicKit
*/
/*
Modification history:

  $Log$
  Revision 1.2  1999/07/29 01:25:59  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/22/89/daj - Moved _MKNameTable functions to _MKNameTable.h. Added global
                 defines of bits.
  10/06/89/daj - Changed to use hashtable.h version of table.
  01/31/90/daj - Added import of hashtable.h
  ??/??/98/sb  - OpenStep conversion
  04/21/99/lms - overhaul for NSDictionary operation for portability and clarity
*/
#ifndef __MK__MKNameTable_H___
#define __MK__MKNameTable_H___

#define _MK_NOFREESTRINGBIT 0x8000 /* Set if string is never to be freed */
#define _MK_AUTOIMPORTBIT 0x4000 /* Set if all LOCAL tables should import */
#define _MK_BACKHASHBIT 0x2000  /* Set if object-to-name lookup is required */

@interface _MKNameTable: NSObject
{
    NSMutableDictionary *symbols;
    NSMutableDictionary *types;
}

- (id) initWithCapacity: (unsigned) capacity;
- (void) dealloc;

@end

/* Private name table functions */
extern void _MKNameGlobal(NSString * name,id dataObj,unsigned short type, BOOL autoImport,BOOL copyIt);
extern id _MKGetNamedGlobal(NSString * name,unsigned short *type);
extern NSString *_MKGetGlobalName(id object);

/* Very private name table functions */
extern NSString 	*_MKUniqueName(NSString *name,_MKNameTable *table,id anObject,id *hashObj);
extern _MKNameTable 	*_MKNewScorefileParseTable(void);
extern id 		_MKGetListElementWithName(id aList,char *aName);
extern _MKNameTable 	*_MKNameTableAddName(_MKNameTable *table,NSString *theName,
				      id owner, id object,
				      unsigned short type,BOOL copyIt);
extern id 		_MKNameTableGetFirstObjectForName(_MKNameTable *table,NSString *theName);
extern id 		_MKNameTableGetObjectForName(_MKNameTable *table,NSString *theName,id theOwner,
					unsigned short *typeP);
extern NSString 	*_MKNameTableGetObjectName(_MKNameTable *table,id theObject,id *theOwner);
extern _MKNameTable 	*_MKNameTableRemoveName(_MKNameTable *table,NSString *theName,id theOwner);
extern _MKNameTable 	*_MKNameTableRemoveObject(_MKNameTable *table,id theObject);
extern void 		_MKFreeScorefileTable(_MKNameTable *aTable);
extern NSString		*_MKSymbolize(NSString *sym,BOOL *wasChanged);

#endif
