/*
  $Id$  
  Defined In: The MusicKit
  HEADER FILES: MusicKit.h

  Description:
    MKPatchTemplate is a recipe for building a particular kind of MKSynthPatch.
    The template is created with the MKPatchTemplate class method +new
    and configured with the basic methods

    -to:(unsigned)anObjInt sel:(SEL)aSelector arg:(unsigned)anArgInt
    -(unsigned)addUnitGenerator:(id)aUGClass ordered:(BOOL)isOrdered
    -(unsigned)addSynthData:(MKOrchMemSegment)segment length:(unsigned)len
    -(unsigned)addPatchpoint:(MKOrchMemSegment)segment

    The template consists of "ordered" MKUnitGenerator factories,
    "unordered" MKUnitGenerator factories, "data memory blocks", and
    "message requests". (The meaning of the terms is indicated below.)  These
    are added to the template using the three methods shown above. In the
    case of "ordered" MKUnitGenerators, the order used is the order of the
    -addUnitGenerator: messages. -addUnitGenerator:ordered:, -addSynthData:length:,
    and -addPatchpoint: return an int value to be used as an argument to
    sendSel:to:with: or when referencing MKUnitGenerators in the MKSynthPatch.

    When MKUnitGenerators are connected up, it usually doesn't matter if
    there is a one-tick delay involved in the interconnection.  If it does
    not matter one way or the other, you should specify the MKUnitGenerator
    as an "unordered" MKUnitGenerator. However, if it is essential that no
    pipe-line delay be incurred, you should specify the two unit
    generators in the correct order as "ordered" MKUnitGenerators.
    Similarly, if it is essential that exactly one pipe-line delay be
    incurred, you should specify the two MKUnitGenerators in the reverse
    order in the "ordered" MKUnitGenerator list.

    Each data block used privately in the MKSynthPatch is allocated
    by specifying the length and memory segment of that data block to the
    MKPatchTemplate. The instances allocated are MKSynthData instances.

    Finally, the message requests of the Template are specified with the
    to:sel:arg: method. This mechanism is used primarily to specify the
    interconnections of the MKUnitGenerators.
    The to: and with: arguments are one of the values
    returned by addUnitGenerator:ordered: or addSynthData:length:.
    These connections are made automatically by the -initialize MKSynthPatch
    method. When the initialize method is sent to the MKSynthPatch,
    each of the connections is made in the order the to:sel:arg: messages
    were sent.

    It is important to point out that PatchTemplates are considered different
    by the MKOrchestra, even if their contents are identical. A MKPatchTemplate should not
    be changed once it has been used during a Musickit performance.

    MKPatchTemplate should never be freed.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/* 
Modification history:

  $Log$
  Revision 1.11  2003/08/04 21:14:33  leighsmith
  Changed typing of several variables and parameters to avoid warnings of mixing comparisons between signed and unsigned values.

  Revision 1.10  2002/01/29 16:28:35  sbrandon
  fixed object leak in to:sel:arg
  changed _MKOrchTrace fn calls to use NSString args

  Revision 1.9  2001/09/08 21:53:16  leighsmith
  Prefixed MK for UnitGenerators and SynthPatches

  Revision 1.8  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.7  2001/04/23 21:17:29  leighsmith
  Corrected _MKEvalTamplateConnections

  Revision 1.6  2000/06/09 17:17:51  leigh
  Added MKPatchEntry replacing deprecated Storage class

  Revision 1.5  2000/06/09 03:31:31  leigh
  Added MKPatchConnection to remove a struct which required Storage

  Revision 1.4  2000/05/06 01:12:14  leigh
  Typed parameters to reduce warnings

  Revision 1.3  2000/04/16 04:10:27  leigh
  Removed unnecessary MAKECOMPILERHAPPY test

  Revision 1.2  1999/07/29 01:16:40  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  01/02/90/daj - Deleted a comment.		       
  03/13/90/daj - Changes to support new categories for private methods.
  03/21/90/daj - Added archiving.
  04/21/90/daj - Small mods to get rid of -W compiler warnings.
  04/25/90/daj - Added CHECKCLASS to make sure that the right class is
                 returned when inheritance is used in MKSynthPatch design.
  04/27/90/daj - Removed checks for _MKClassOrchestra, since we're a
                 shlib now so MKOrchestra will always be there.
  08/27/90/daj - Added zone support API.
  07/05/91/daj - Fixed bug in _MKAllocSynthPatch.
  08/22/91/daj - Changed Storage API for 3.0.
*/
#import "_musickit.h"

#import "OrchestraPrivate.h"
#import "SynthPatchPrivate.h"
#import "UnitGeneratorPrivate.h"
#import "MKPatchEntry.h"
#import "MKPatchConnection.h"

#import "PatchTemplatePrivate.h"

@implementation MKPatchTemplate:NSObject

#define ENTRYDESCR @"{#SSI}"

+new
{
    self = [super allocWithZone:NSDefaultMallocZone()];
    [self init];
    return self;
}

-init
  /* Creates a new MKPatchTemplate instance. */
{
    [super init];
    _deallocatedPatches = [_MKClassOrchestra() _addTemplate:self];
    _connectionStorage = [[NSMutableArray array] retain];
    _elementStorage = [[NSMutableArray array] retain];
    return self;
}

#define VERSION2 2

+ (void)initialize
{
    if (self != [MKPatchTemplate class])
      return;
    [MKPatchTemplate setVersion:VERSION2];//sb: suggested by Stone conversion guide (replaced self)
    return;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
  /* TYPE: Archiving; Writes object.
     You never send this message directly.  
     */
{
   /* [super encodeWithCoder:aCoder];*/ /*sb: unnecessary */
    [aCoder encodeValuesOfObjCTypes:"@@i",&_elementStorage,&_connectionStorage,
		 &_eMemSegments];
}

- (id)initWithCoder:(NSCoder *)aDecoder
  /* You never send this message directly.  
     Should be invoked via NXReadObject(). 
     See write:. */
{
    /* [super initWithCoder:aDecoder]; */ /*sb: unnecessary */
    if ([aDecoder versionForClassName:@"MKPatchTemplate"] == VERSION2) 
        [aDecoder decodeValuesOfObjCTypes:"@@i",&_elementStorage,&_connectionStorage, &_eMemSegments];
    /* from awake (sb) */
    {
        int i,count;
        MKPatchConnection *conn;
        MKPatchEntry *templ;

        _deallocatedPatches = [_MKClassOrchestra() _addTemplate:self];
        /* Update IMP pointers */
        count = [_connectionStorage count];
        for (i=0; i<count; i++) {
            conn = [_connectionStorage objectAtIndex:i];
            templ = [_elementStorage objectAtIndex:conn->_toObjectOffset];
            conn->_methodImp = [[templ entryClass] instanceMethodForSelector:conn->_aSelector];
        }
    }
    return self;
}

-copy
{
    return [self copyWithZone:[self zone]];
}

- copyWithZone:(NSZone *)zone
  /* Creates a new MKPatchTemplate that's a copy of the receiver, containing
     the same connections and entries. */
{
    MKPatchTemplate *newObj = NSCopyObject(self, 0, zone);

    _deallocatedPatches = [_MKClassOrchestra() _addTemplate:newObj];
    newObj->_connectionStorage = [_connectionStorage copy];
    newObj->_elementStorage = [_elementStorage copy];
    return newObj;
}

-(unsigned)synthElementCount
  /* Returns the number of entries in the template. */
{
    return [_elementStorage count];
}

-to:(unsigned)toObjInt sel:(SEL)aSelector arg:(unsigned)withObjInt
  /* Adds a request to send aSelector to the entry specified by toObjInt
     with the argument as the entry specified by withObjInt. For example,
     if you say 

     unsigned osc = [tmpl addUnitGenerator:OscgUG]; 
     unsigned  patchPoint = [tmpl addPatchpoint:MK_xPatch];
     [tmpl to:osc sel:@selector(setOutput:) arg:patchPoint];

     then later, when the MKSynthPatch is built, the message

     [[self at:osc] setOutput:[self at:patchPoint]];

     will be sent. If toObjInt or withObjInt is invalid, returns nil, else self.
     */
{
    MKPatchConnection *conn = [[MKPatchConnection alloc] initWithTargetObjectOffset: toObjInt
                                                                           selector: aSelector
                                                                           argument: withObjInt];
    unsigned int i = [_elementStorage count];
    if ((toObjInt < i) && (withObjInt < i))
      // This implies that rather than keeping the instance method for the selector, we should retain the selector
      conn->_methodImp =
          [[(MKPatchEntry *)[_elementStorage objectAtIndex:toObjInt] entryClass] instanceMethodForSelector: aSelector];
    else 
      return nil;
    [_connectionStorage addObject: conn];
    [conn release]; // retain held in _connectionStorage
    return self;
}

#define ORDERED   ((short)1)
#define UNORDERED ((short)2)
#define SYNTHDATA ((short)3)
#define PATCHPOINT ((short)4)

static unsigned addEl(MKPatchTemplate *self, MKPatchEntry *newEntry)
{
    unsigned curIndex = [self->_elementStorage count];
    /* Count is num elements. But we pass an index so need to subtract 1. */ 
    [self->_elementStorage addObject: newEntry];
    // LMS: I'm not quite sure if we should be returning curIndex before the addObject or after.
    return curIndex; 
}

-(unsigned)addUnitGenerator:(id)aUGClass ordered:(BOOL)isOrdered
  /* Adds a MKUnitGenerator or PatchPoint class to the receiver. If isOrdered
     is NO, the ordering of the MKUnitGenerator in memory is considered
     irrelevant. It is more efficient, from the standpoint of memory 
     thrashing, to set isOrdered to NO. However, it makes the job of 
     writing MKSynthPatches trickier, since the designer may need to ask each
     MKUnitGenerator if it runs after or before the others. */
{
    MKPatchEntry *newEntry = [[MKPatchEntry alloc] initWithClass: aUGClass
                                                            type: (isOrdered) ? ORDERED : UNORDERED];
    return addEl(self, newEntry);
}

-(unsigned)addUnitGenerator:aUGClass
  /* Same as [self addUnitGenerator:aUGClass ordered:YES]; */
{
    return [self addUnitGenerator:aUGClass ordered:YES];
}

-(unsigned)addSynthData:(MKOrchMemSegment)segment length:(unsigned)len
  /* Adds a request for a data memory segment of the specified segment type
     and length. */
{
    MKPatchEntry *newEntry = [[MKPatchEntry alloc] initWithClass: [MKSynthData class]
                                                            type: SYNTHDATA
                                                         segment: (unsigned short) segment
                                                          length: len];
    return addEl(self, newEntry);
}

-(unsigned)addPatchpoint:(MKOrchMemSegment)segment
  /* Adds a request for a data memory segment of the specified segment type */
{
    MKPatchEntry *newEntry = [[MKPatchEntry alloc] initWithClass: [MKSynthData class]
                                                            type: PATCHPOINT 
                                                         segment: (unsigned short) segment]; 
    return addEl(self, newEntry);
}

NSMutableArray *_MKDeallocatedSynthPatches(MKPatchTemplate *templ,int orchIndex)
{
    return templ->_deallocatedPatches[orchIndex];
}

BOOL _MKIsClassInTemplate(MKPatchTemplate *templ,id factObj)
{
    /* Returns YES if factObj is present in templ as a unit generator,
       ordered or unordered. */
    unsigned int i;
    for (i = 0; i < [templ->_elementStorage count]; i++) {
        MKPatchEntry *el = [templ->_elementStorage objectAtIndex: i];
        if ([el entryClass] == factObj) 
            return YES;
   }
   return NO;
}

void _MKEvalTemplateConnections(MKPatchTemplate *templ,id synthElements)
{
    register unsigned n;
//    int arr=0; //arr[conn->_toObjectOffset], arr[conn->_argObjectOffset]
//    id *arr = NX_ADDRESS(synthElements);
    NSArray *connectionStorage = templ->_connectionStorage;

    for (n = 0; n < [connectionStorage count]; n++) {
        register MKPatchConnection *conn = (MKPatchConnection *)([connectionStorage objectAtIndex: n]);
        (*conn->_methodImp)([synthElements objectAtIndex: conn->_toObjectOffset], conn->_aSelector,
                            [synthElements objectAtIndex: conn->_argObjectOffset]);
    }
}

unsigned _MKGetTemplateEMemUsage(MKPatchTemplate *templ)
{
    return templ->_eMemSegments;
}

void _MKSetTemplateEMemUsage(MKPatchTemplate *templ,MKOrchMemStruct *reso)
{
    if (templ->_eMemSegments == MAXINT) {
	if (reso->xData) 
	  templ->_eMemSegments |= (1 << ((unsigned)(MK_xData)));
	if (reso->yData)
	  templ->_eMemSegments |= (1 << ((unsigned)(MK_yData)));
	if (reso->pSubr)
	  templ->_eMemSegments |= (1 << ((unsigned)(MK_pSubr)));
    }
}

#define CHECKCLASS 1

id _MKAllocSynthPatch(MKPatchTemplate *templ,id synthPatchClass,id anOrch,
		      int orchIndex)
{
    id aPatch;
#if CHECKCLASS
    if (templ) {
    	int n = [templ->_deallocatedPatches[orchIndex] count];
        int ptr=n; id tempObj; //sb
//        id *ptr = NX_ADDRESS(templ->_deallocatedPatches[orchIndex]) + n; 
			/* points 1 beyond last object */
	aPatch = nil;
	while ((n-- > 0) && (aPatch == nil)) { 
	    /* March down List (from end toward beginning) looking for a 
	       class match. Normally, the very first one we check will 
	       match. */
            tempObj = [templ->_deallocatedPatches[orchIndex] objectAtIndex:--ptr]; //sb
            if ([tempObj class] == synthPatchClass) {//*--ptr
                aPatch = tempObj; /* Must be before remove! */ //*ptr
		[templ->_deallocatedPatches[orchIndex] removeObjectAtIndex:n];
	    }	
	}
	if (aPatch) {
	    if (_MK_ORCHTRACE(anOrch,MK_TRACEORCHALLOC))
	      _MKOrchTrace(anOrch,MK_TRACEORCHALLOC,
			   @"allocSynthPatch returns %@_%p",
                    NSStringFromClass([synthPatchClass class]),aPatch);
	    [aPatch _allocate]; /* Tell it it's allocated */
	    return aPatch;
	}
    }
#else
    if (templ && 
#error ListToMutableArray: removeLastObject raises when List equivalent returned nil
	(aPatch = [templ->_deallocatedPatches[orchIndex] removeLastObject])) {
	if (_MK_ORCHTRACE(anOrch,MK_TRACEORCHALLOC))
	  _MKOrchTrace(anOrch,MK_TRACEORCHALLOC,
		       "allocSynthPatch returns %s_%p",
                [NSStringFromClass([synthPatchClass class]) cString],aPatch);
	[aPatch _allocate]; /* Tell it it's allocated */
	return aPatch;
    }
#endif
    /* If no deallocated patches, we try and allocate a new one. */
    [anOrch beginAtomicSection];
    aPatch = [synthPatchClass _newWithTemplate:templ inOrch:anOrch index:
	      orchIndex];
    if (!templ)
      return aPatch;
    if (_MK_ORCHTRACE(anOrch,MK_TRACEORCHALLOC))
      _MKOrchTrace(anOrch,MK_TRACEORCHALLOC,
		   @"allocSynthPatch building %@_%p...",
                   NSStringFromClass([synthPatchClass class]),aPatch);
    
    {
        unsigned int entryIndex;
	id anOrderedUG = nil;
	id aSE = nil;
        BOOL firstOrdered = YES;
	
        for (entryIndex = 0; entryIndex < [templ->_elementStorage count]; entryIndex++) {
            MKPatchEntry *el = [templ->_elementStorage objectAtIndex: entryIndex];
	    switch ([el type]) {
	    case ORDERED:
		if (firstOrdered) {
                    anOrderedUG = [anOrch allocUnitGenerator: [el entryClass]]; 
		    firstOrdered = NO;
		}
		else
                    anOrderedUG = [anOrch allocUnitGenerator: [el entryClass] after: anOrderedUG];
		aSE = anOrderedUG;
		break;
	    case UNORDERED:
                aSE = [anOrch allocUnitGenerator: [el entryClass]]; 
		break;
	    case PATCHPOINT:
		aSE = [anOrch allocPatchpoint: [el segment]];
		break;
	    case SYNTHDATA:
		aSE = [anOrch allocSynthData: [el segment] length: [el length]];
		break;
	    }
            if (aSE) {
                [aPatch _add:aSE];
                [aSE release]; /* now only the patch has responsibility for releasing */
            }
	    else {
                [aPatch _free];
                [aPatch release];
		[anOrch endAtomicSection];
		return nil;
	    }
	}    
    }
    if (![aPatch _connectContents]) {
        [aPatch _free];
        [aPatch release];
	[anOrch endAtomicSection];
	return nil;
    }
    if (_MK_ORCHTRACE(anOrch,MK_TRACEORCHALLOC))
      _MKOrchTrace(anOrch,MK_TRACEORCHALLOC,
		   @"allocSynthPatch connectsContents of %@_%p",
                   NSStringFromClass([synthPatchClass class]),aPatch);
    [anOrch endAtomicSection];
    return aPatch;
}

@end

