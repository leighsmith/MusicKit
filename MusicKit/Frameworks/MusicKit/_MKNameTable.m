/*
 $Id$
 Defined In: The MusicKit

 Description:

 Note:
 * back-hashing is optionally supported.
 * the name is owned by the name table (it is copied and freed)
 * a type is associated with the name.

 Note that if back-hashing is not specified (via the _MK_BACKHASH bit),
 the object name is NOT accessible from the object. We use backhashing
 except for things such as pitch names and keywords, where backhashing
 is never done.

 We should convert it to an NSDictionary, however:
 1. NSDictionary always copies but memory's cheap so big deal.
 2. using the object as reference (back-hashing) needs somewhere to save the type,
 otherwise an enclosing object needs to be defined holding the object and the type
 parameters as the value. This means a search won't work.
 We could do this by making the type be an instance var of the object, or just having two dictionaries.

 Also, should NOT copy strings. Or, at least, have a no-copy bit
 that can be set for the strings that exist elsewhere (e.g. the
                                                       ones for the keywords and such) in the program.

 Original Author: David Jaffe

 Copyright (c) 1988-1992, NeXT Computer, Inc.
 Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
 Portions Copyright (c) 1994 Stanford University
 Portions Copyright (c) 1999-2000 The MusicKit Project.
 */
/*
Modification history:

 $Log$
 Revision 1.14  2003/08/16 22:29:11  leighsmith
 replaced some i386 #if conditions with a tighter check to verify it is only in the case of Intel NeXTStep platforms, several chunks of code were being compiled on Intel machines running GnuStep

 Revision 1.13  2003/08/04 21:14:33  leighsmith
 Changed typing of several variables and parameters to avoid warnings of mixing comparisons between signed and unsigned values.

 Revision 1.12  2002/04/16 15:07:06  sbrandon
 - now use proper capacity for new nametbles instead of default 10
 - included new debug tool "_MKPrintGlobalNameTables()" to view
   what's in there

 Revision 1.11  2002/04/15 14:28:15  sbrandon
 - changed symbols and types NSDictionaries to NSMapTables, because NSMapTables
   do not have to retain their objects (and I have set them up not to do so).
   This had been causing dealloc loops for objects held in the main dict
   and trying to remove themselves in their -dealloc methods.

 Revision 1.10  2002/04/03 03:59:41  skotmcdonald
 Bulk = NULL after free type paranoia, lots of ensuring pointers are not nil before freeing, lots of self = [super init] style init action

 Revision 1.9  2002/01/23 15:33:02  sbrandon
 The start of a major cleanup of memory management within the MK. This set of
 changes revolves around MKNote allocation/retain/release/autorelease.

 Revision 1.8  2001/09/06 21:27:48  leighsmith
 Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

 Revision 1.7  2000/10/01 06:42:47  leigh
 Doco cleanup.

 Revision 1.6  2000/07/22 00:34:05  leigh
 Minor doco and typing cleanups.

 Revision 1.5  2000/05/13 17:19:10  leigh
 stricter typing

 Revision 1.4  2000/04/22 20:10:24  leigh
 user defaults standardised to MK prefix

 Revision 1.3  2000/04/07 22:45:03  leigh
 Cleaned up defaults usage, removed redundant DSP output assignments (which are better covered using the IOKit).

 Revision 1.2  1999/07/29 01:25:59  leigh
 Added Win32 compatibility, CVS logs, SBs changes

 09/22/89/daj - Made back-hash optional in the interest of saving space.
 Flushed _MKNameTableAddGlobalNameNoCopy() in light of the
 decision to make name table bits (e.g. _MK_NOFREESTRINGBIT)
 globally defined.
 Flushed _MKNameTableAddNameNoCopy() and added a copyIt
 parameter to _MKNameTableAddName().
 10/06/89/daj - Changed to use hashtable.h version of table.
 12/03/89/daj - Added seed and ranSeed to initTokens list.
 03/05/90/daj - Added check for null name and nil object in public functions.
 Added conversion of name in MKNameObject to legal scorefile
 name and added private global function _MKSymbolize().
 03/06/90/daj - Added _MK_repeat to keyword list.
 04/21/90/daj - Removed unused auto var.
 10/02/94/daj - Added MKTrace defaults var
 ??/??/98/sb  - OpenStep conversion
 04/21/99/lms - overhaul for NSDictionary operation for portability and clarity
 */

#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import "_musickit.h"
#import "_MKNameTable.h"
#import "TuningSystemPrivate.h"
#import "MKTuningSystem.h"
#import "MKNote.h"
#import "_ParName.h"
#import "_ScorefileVar.h"

#define MASKBITS (_MK_NOFREESTRINGBIT | _MK_AUTOIMPORTBIT | _MK_BACKHASHBIT)
#define TYPEMASK(_x) (_x & (0xffff & ~(MASKBITS)))
// Dear WinNT doesn't know about PI, stolen from MacOSX-Servers math.h definition
#ifndef M_PI
#define M_PI            3.14159265358979323846  /* pi */
#endif

@implementation _MKNameTable

- (id) initWithCapacity: (unsigned) capacity;
{
  self = [super init];
  if (self != nil) {
  // NSObjectMapKeyCallBacks are objects which will be retained/released (all our keys
  // are NSStrings, so I'm happy with that)
  // NSNonRetainedObjectMapValueCallBacks are objects, but will never be retained or
  // released. This means that if the objects in question are ever dealloced, they MUST
  // call MKRemoveObjectName() in their dealloc method, so the map tables don't hold
  // dangling references.
    symbols    = NSCreateMapTable(NSObjectMapKeyCallBacks, NSNonRetainedObjectMapValueCallBacks,capacity); 
    types      = NSCreateMapTable(NSObjectMapKeyCallBacks, NSNonRetainedObjectMapValueCallBacks,capacity);
  }
  return self;
}

- (void) dealloc
{
  if (symbols != NULL) {
    NSFreeMapTable(symbols);
    symbols = NULL;
  }
  if (types != NULL) {
    NSFreeMapTable(types);
    types = NULL;
  }
  [super dealloc];
}

static void importAutoGlobals(_MKNameTable *globalTable,_MKNameTable *localTable)
/* Adds all the 'auto-import' symbols from globalTable to localTable. The
strings aren't copied. The type is set to be global.

'auto-import' symbols are all those that are not of type
MK_envelope, MK_waveTable or MK_object. (Actually, it's anything
                                         without the AUTOIMPORT bit on.) */
{
//  NSEnumerator *enumerator = [globalTable->symbols keyEnumerator];
  NSMapEnumerator enumerator = NSEnumerateMapTable(globalTable->symbols);
  id name;
  id obj;
  unsigned short type;

//  while ((name = [enumerator nextObject])) {
  while (NSNextMapEnumeratorPair(&enumerator, (void**)&name, (void**)&obj)) {
//    obj = [globalTable->symbols objectForKey: name];
    type = [(id)NSMapGet(globalTable->types, name) unsignedShortValue];
    if (type & _MK_AUTOIMPORTBIT)
      _MKNameTableAddName(localTable, name, nil, obj, type | _MK_NOFREESTRINGBIT, NO);
  }
  NSEndMapTableEnumeration(&enumerator);
}

_MKNameTable *_MKNameTableAddName(_MKNameTable * table, NSString *theName,id theOwner,
                                  id theObject, unsigned short theType,BOOL copyIt)
/*
 * Adds the object theObject in the table, with name theName and owner
 * theOwner. If there is already an entry for this name and owner does
 * nothing and returns nil. TheName is not copied unless copyIt is true.
 * Nowdays we ignore owner (which was nil anyway) and copyIt.
 * theType uses bits for freeing strings and backhashing which are redundant.
 * It uses the autoimport bit which may need to be used.
 * It should be able to be an instance var in theObject
 */
{
  if (!copyIt)
    theType |= _MK_NOFREESTRINGBIT;
//  [table->types setObject: [NSNumber numberWithUnsignedShort: theType] forKey: theName];
//  [table->symbols setObject: theObject forKey: theName];

  NSMapInsert(table->types, theName, [[NSNumber numberWithUnsignedShort: theType] retain] );
  NSMapInsert(table->symbols, theName, theObject);
  return table;
}

id _MKNameTableGetObjectForName(_MKNameTable *table,NSString *theName,id theOwner,
                                unsigned short *typeP)
/*
 * If there is an object with this name and owner it is returned, otherwise
 * nil is returned.
 */
{
  id foundObject = NSMapGet(table->symbols, theName);
  id foundType;

  if(foundObject != nil) {
    foundType = NSMapGet(table->types, theName);
    *typeP = TYPEMASK([foundType unsignedShortValue]); /* Clear bits */
    return foundObject;
  }
  else {
    *typeP = 0;
    return nil;
  }
}

NSString * _MKNameTableGetObjectName(_MKNameTable *table,id theObject,id *theOwner)
/*
 * If theObject has been entered in the table before, this method returns
 * its name and sets theOwner to its owner (nil). Otherwise nil is returned.
 */
{
  NSMapEnumerator e = NSEnumerateMapTable(table->symbols);
  id obj,key;
  NSString* firstFoundName = nil;
  while (NSNextMapEnumeratorPair(&e, (void **)&key, (void **)&obj)) {
    if (obj == theObject) { // pointer equality, since the maptable does not copy objects
      firstFoundName = key;
      break;
    }
  }
  NSEndMapTableEnumeration(&e);
  
  if (firstFoundName) {
    *theOwner = nil; // never used anyway
    return [[firstFoundName retain] autorelease];
  }
  else
    return nil;
}

#if 0 /* therefore not updated to NSMapTable usage */
static _MKNameTable *_MKNameTableRemoveName(_MKNameTable *table,NSString *theName,id theOwner)
/*
 * Removes the entry associated to (theName x theOwner) if any.
 */
{
  nameRecord symbol;
  nameRecord *symbolRec1,*symbolRec2;
  symbol.name = theName;
  symbol.owner = theOwner;
  symbolRec1 = NSHashRemove(table->hTab, &symbol);
  if (symbolRec1)
    symbolRec2 = NSHashRemove(table->bTab, symbolRec1);
  else return NULL;
  giveSymbol(symbolRec1);
  return table;
}
#endif

_MKNameTable *_MKNameTableRemoveObject(_MKNameTable *table,id theObject)
/*
 * Removes theObject from the table.
 * Find the key, then remove the symbol and type entries.
 */
{
//  NSArray *allFoundNames = [table->symbols allKeysForObject: theObject];
  NSMapEnumerator e = NSEnumerateMapTable(table->symbols);
  id obj,key;
  NSString* firstFoundName = nil;
  while (NSNextMapEnumeratorPair(&e, (void **)&key, (void **)&obj)) {
    if (obj == theObject) { // pointer equality, since the maptable does not copy objects
      firstFoundName = key;
      break;
    }
  }
  NSEndMapTableEnumeration(&e);

  if (firstFoundName) {
    NSMapRemove(table->symbols,firstFoundName);
    NSMapRemove(table->types,firstFoundName);
    return table;
  }
  else
    return nil;
}


/* Routines to check and convert to C symbols for writing to score files. */

#define isIllegalFirstCChar(_c) (!isalpha(*sym) && (*sym != '_'))
#define isIllegalCChar(_c) (!isalnum(*sym) && (*sym != '_'))

static BOOL isCSym(const register char *sym)
{
  if (isIllegalFirstCChar(*sym))
    return NO;
  while (*++sym)
    if (isIllegalCChar(*sym))
      return NO;
  return YES;
}

static void convertToCSym(const register char *sym,register char *newSym)
/* newSym is assumed to be allocated to be at least the length of sym.
Returns newSym. */
{
  *newSym++ = (isIllegalFirstCChar(*sym)) ? '_' : *sym;
  while (*++sym)
    *newSym++ = (isIllegalCChar(*sym)) ? '_' : *sym;
  *newSym = '\0';
}

NSString *_MKSymbolize(NSString *sym,BOOL *wasChanged)
/* Converts sym to new symbol, returns the new symbol (malloced),and
sets *wasChanged to YES. If sym is already a legal symbol, does not malloc,
returns sym, and sets *wasChagned to NO. */
{
  char     *newSym = NULL;
  NSString *result = nil;
  if (sym == nil) { *wasChanged = NO; return sym; }

  if (isCSym([sym cString])) { /* DAJ. Jan 27, 1996. Added null check */
    *wasChanged = NO;
    return sym;
  }
  _MK_MALLOC(newSym,char,[sym cStringLength] + 1);
  convertToCSym([sym cString],newSym);
  //    *wasChanged = NO;
  *wasChanged = YES; /* DAJ -- Jan 27, 96. Plugged leak */
  result = [[NSString alloc] initWithCString: newSym];
  free(newSym);
  newSym = NULL;
  return result;
}


/* Higher level interface and specific Music Kit use of name tables.  */

/* We keep two name tables, one for parsing (private, flat)
and one for writing (public, hierarchical). There are also private flat
local tables used for parsing. */

static _MKNameTable *globalParseNameTable;
static _MKNameTable *mkNameTable = nil;

void _MKPrintGlobalNameTables()
{
  NSLog(@"globalParseNameTable symbols:");
  NSLog(NSStringFromMapTable(globalParseNameTable->symbols));
  NSLog(@"globalParseNameTable types:");
  NSLog(NSStringFromMapTable(globalParseNameTable->types));
  NSLog(@"mkNameTable symbols:");
  NSLog(NSStringFromMapTable(mkNameTable->symbols));
  NSLog(@"mkNameTable types:");
  NSLog(NSStringFromMapTable(mkNameTable->types));
}

id MKRemoveObjectName(id object)
/*
 * Removes theObject from the table. Returns nil.
 */
{
  if (!mkNameTable)
    _MKCheckInit();
  _MKNameTableRemoveObject(mkNameTable,object);
  return nil;
}

BOOL MKNameObject(NSString * nameStr,id object)
/*
 * Adds the object theObject in the table, with name theName.
 * If the object is already named, does
 * nothing and returns NO. Otherwise returns YES. Note that the name is copied.
 */
{
  /* Always sets BACKHASH bit. */
  BOOL wasChanged;
  BOOL rtnVal;
  NSString * name;
  if (!mkNameTable)
    _MKCheckInit();
  if (nameStr == nil) return NO;
  if (![nameStr length]) /* Added check for !*name - DAJ 1/28/96 */
    return NO;

  name = _MKSymbolize(nameStr ,&wasChanged); /* Convert to valid sf name */
  rtnVal = (_MKNameTableAddName(mkNameTable,name,object,object,_MK_BACKHASHBIT,YES) != NULL);
  if (wasChanged)
    [name autorelease];
  return rtnVal;
}

NSString * MKGetObjectName(id object)
/*
 * Returns object name if any. If object is not found, returns nil. The name
 * is not copied and should not be freed or altered by caller.
 */
{
  id owner;
  if (!mkNameTable || !object)
    return nil;
  return _MKNameTableGetObjectName(mkNameTable,object,&owner);
}

#if 0
static id MKGetNamedObject(NSString *name)
/* Returns the first object found in the name table, with the given name.
Note that the name is not necessarily unique in the table; there may
be more than one object with the same name.
*/
{
  if (!mkNameTable || !name)
    return nil;
  return _MKNameTableGetFirstObjectForName(mkNameTable,name);
}
#endif

NSString *_MKGetGlobalName(id object)
/*
 * Returns object name if any. If object is not found, returns NULL. The name
 * is not copied and should not be freed or altered by caller.
 */
{
  id owner;
  if (!globalParseNameTable)
    return nil;
  return _MKNameTableGetObjectName(globalParseNameTable,object,&owner);
}

void _MKNameGlobal(NSString * name,id dataObj,unsigned short type,BOOL autoImport, BOOL copyIt)
/* Copies name */
{
  if (!globalParseNameTable)
    _MKCheckInit();
  if (autoImport)
    type |= _MK_AUTOIMPORTBIT;
  _MKNameTableAddName(globalParseNameTable,name,nil,dataObj,type,copyIt);
}

id _MKGetNamedGlobal(NSString * name,unsigned short *typeP)
{
  if (!globalParseNameTable)
    return nil;
  return _MKNameTableGetObjectForName(globalParseNameTable,name,nil,typeP);
}

#if 0

BOOL MKAddGlobalScorefileObject(id object,NSString *name)
/*
 * Adds the object theObject in the table, referenced in the scorefile
 * with the name specified. The name is copied.
 * If there is already a global scorefile object
 * with that name, does nothing and returns NO. Otherwise returns YES.
 * The object does not become visible to scorefiles unless they explicitly
 * do a call of getGlobal.
 * The type of the object in the scorefile is determined as follows:
 * * If object isKindOf:[MKWaveTable class], then the type is MK_waveTable.
 * * If object isKindOf:[MKEnvelope class], then the type is MK_envelope.
 * * Otherwise, the type is MK_object.
 */
{
  unsigned short type;
  if (!object || !name)
    return NO;
  if (![name length]) return NO;
  type = ([object isKindOfClass:[MKEnvelope class]]) ? MK_envelope :
    ([object isKindOfClass:[MKWaveTable class]]) ? MK_waveTable : MK_object;
  if (!globalParseNameTable)
    _MKCheckInit();
  _MKNameTableAddName(globalParseNameTable,name,nil,object, type | _MK_BACKHASHBIT,YES);
  return YES;
}

id MKGetGlobalScorefileObject(NSString *name)
/* Returns the global scorefile object with the given name. The object may
be either one that was added with MKAddGlobalScorefileObject or it
may be one that was added by the scorefile itself using "putGlobal".
Objects accessable to the application are those of type
MK_envelope, MK_waveTable and MK_object. An attempt to return some other
object will return nil.
Note that the name is not necessarily registered with the Music Kit
name table.
*/
{
  unsigned short typeP;
  id obj;
  if (!name)
    return nil;
  obj = _MKGetNamedGlobal(name,&typeP);
  switch (typeP) {
    case MK_envelope:
    case MK_waveTable:
    case MK_object:
      return obj;
    default:
      return nil;
  }
}

#endif
/* The following is a list of the key words recognized by the scorefile
parser. */

static const int keyWordsArr[] = {
  /* note types */
  MK_noteDur,MK_mute,MK_noteOn,MK_noteOff,MK_noteUpdate,
  /* MKMidi pars */
  MK_resetControllers,MK_localControlModeOn,MK_localControlModeOff,
  MK_allNotesOff,MK_omniModeOff,MK_omniModeOn,MK_monoMode,MK_polyMode,
  MK_sysClock,MK_sysStart,MK_sysContinue,MK_sysStop,MK_sysActiveSensing,
  MK_sysReset,
  /* Other keywords */
  _MK_part,_MK_doubleVarDecl,_MK_stringVarDecl,_MK_tune,
  _MK_intVarDecl,_MK_to,_MK_begin,_MK_end,_MK_include,_MK_comment,
  _MK_endComment,_MK_print,_MK_time,_MK_dB,_MK_ran,
  _MK_envelopeDecl,_MK_waveTableDecl,_MK_objectDecl,_MK_noteTagRange,
  _MK_envVarDecl,_MK_waveVarDecl,_MK_varDecl,_MK_objVarDecl,_MK_info,
  _MK_putGlobal,_MK_getGlobal,_MK_seed,_MK_ranSeed,_MK_repeat,
  _MK_if,_MK_else,_MK_while,_MK_do
};

/* The following define some assumed defaults used as a guess at Set sizes.
All such Sets are expandable, however. */

#define NUMKEYWORDS (sizeof(keyWordsArr)/sizeof(int))
#define NUMOCTAVES (128/12)
#define NUMPITCHVARS (NUMOCTAVES * (9 + 12)) /* 9 enharmnonic equivalents */
#define NUMKEYVARS (NUMPITCHVARS)
#define NUMOTHERMUSICKITVARS 9 /* Other than KEYVARS and PITCHVARS */
#define NUMMUSICKITVARS (NUMKEYVARS + NUMPITCHVARS + NUMOTHERMUSICKITVARS)
#define NAPPVARSGUESS 15 /* Per file. (This includes parts and envelopes)  */
#define NFILESGUESS 2 /* Num scoreFiles being read at once or sequentially. */
#define GLOBALTABLESIZE (NUMMUSICKITVARS)
#define GLOBALTABLEBACKHASHSIZE (BACKHASHSIZE)
#define LOCALTABLESIZE (NAPPVARSGUESS + GLOBALTABLESIZE)
#define LOCALTABLEBACKHASHSIZE (BACKHASHSIZE)

/* Re. _MK_NOFREESTRINGBIT below:
Actually, this is not needed, since we never free the elements of the
global table. But I left it in anyway, to highlight that the string is
in the text segment and that horrible things will happen if it's freed */

static id addReadOnlyVar(NSString * name,int val)
{
  /* Add a read-only variable to the global parse table. */
  _ScorefileVar *rtnVal;
  _MKNameGlobal(name,rtnVal = _MKNewScorefileVar(_MKNewIntPar(val,MK_noPar),name,NO,YES),
                _MK_typedVar | _MK_NOFREESTRINGBIT,YES,NO);
  return rtnVal;
}

static void initKeyWords()
{
    /* Init the symbol table used to store key words for score file parsing. */
    static BOOL initialised = NO;
    unsigned int i;
    int tok;
    
    if (initialised)
	return;
    addReadOnlyVar(@"NO",0);
    addReadOnlyVar(@"YES",1);
    _MKNameGlobal(@"PI", _MKNewScorefileVar(_MKNewDoublePar(M_PI,MK_noPar), @"PI", NO, YES),
		  (unsigned short)_MK_typedVar | _MK_NOFREESTRINGBIT,YES,NO);
    for (i=0; i<NUMKEYWORDS; i++) {
	tok = (int)(keyWordsArr[i]);
	_MKNameGlobal([NSString stringWithCString:_MKTokName(tok)],@"",
	       (unsigned short)tok | _MK_NOFREESTRINGBIT,YES,NO);
    }
    initialised = YES;
}

/* set up defaults which will apply to each app linked to the MK framework. */
void _MKCheckInit(void)
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary *MKDefaults;

  if (globalParseNameTable)  /* Been here? */
    return;
  MKDefaults = [[NSDictionary dictionaryWithObjectsAndKeys:
    @"", @"MKTrace",
#if 0  // disabled as it is becoming redundant as we move DSP to native CPU
    @"", @"MKDSPSerialPortDevice0",
    @"", @"MKDSPSerialPortDevice1",
    @"", @"MKDSPSerialPortDevice2",
    @"", @"MKDSPSerialPortDevice3",
    @"", @"MKDSPSerialPortDevice4",
    @"", @"MKDSPSerialPortDevice5",
    @"", @"MKDSPSerialPortDevice6",
    @"", @"MKDSPSerialPortDevice7",
    @"", @"MKDSPSerialPortDevice8",
    @"", @"MKDSPSerialPortDevice9",
    @"", @"MKDSPSerialPortDevice10",
    @"", @"MKDSPSerialPortDevice11",
    @"", @"MKDSPSerialPortDevice12",
    @"", @"MKDSPSerialPortDevice13",
    @"", @"MKDSPSerialPortDevice14",
    @"", @"MKDSPSerialPortDevice15",
#endif
#if i386 && defined(__NeXT__)
    @"SSI", @"MKOrchestraSoundOut",   /* One of "Host", "SSI", "IRQA", "IRQB" */
#else
    @"Host", @"MKOrchestraSoundOut",
#endif
    NULL,NULL] retain];

  [defaults registerDefaults:MKDefaults]; //stick these in the temporary area that is searched last.

  MKSetTrace([defaults integerForKey:@"MKTrace"]);

  /*sb: I don't think we need to register anything here. */
  MKSetErrorStream(nil);
  /* We don't try and use the Appkit error mechanism. It's not well-suited to real-time. */
  //  NXRegisterErrorReporter( MK_ERRORBASE, MK_ERRORBASE+1000,_MKWriteError);
  globalParseNameTable = [[_MKNameTable alloc] initWithCapacity: GLOBALTABLESIZE];
  mkNameTable = [[_MKNameTable alloc] initWithCapacity: 0];
  [[[MKNote alloc] init] release]; /* Force initialization. Must be after table creation.*/
  _MKTuningSystemInit();
}

// Needs NSDictionary
_MKNameTable *
_MKNewScorefileParseTable(void)
{
  /* Initialize a local symbol table for a new score file to be parsed.
  Global symbols are not included here. */
  _MKNameTable *localTable = [[_MKNameTable alloc] initWithCapacity: LOCALTABLESIZE];
  initKeyWords();     /* Add key words to global symbol table. */
  importAutoGlobals(globalParseNameTable,localTable);
  return localTable;
}

void _MKFreeScorefileTable(_MKNameTable *aTable)
{
  [aTable release];
}

NSString *_MKUniqueName(NSString *name,_MKNameTable *table,id anObject,id *hashObj)
/* Name is assumed malloced. anObject may be nil. This routine
makes sure that name is not in the table. If it is in the table,
a new name of the form <oldName><int> is generated. */
/*sb: either the original NSString name is returned, or a new, autoreleased string
* is returned.
*/
{
#   define FIRSTDIGIT 0
  int i;
  NSString *newName;
  //    int nDigits = 1, nextPower = 10;
  //    int newSize = strlen(name) + nDigits;
  unsigned short typeP;
  /*sb: added this to here to do initial check for un-suffixed name */
  *hashObj = _MKNameTableGetObjectForName(table,name,nil,&typeP);
  /* Name unused or we found it? */
  if ((!*hashObj) || (*hashObj == anObject))
    return name;

  //    _MK_REALLOC(name,char,newSize+1);     /* Now expand (1 for NULL) */
  for (i = FIRSTDIGIT;  ; i++) {
    //	if (i >= nextPower) {                 /* Make more room */
    //	    newSize++;
    //	    _MK_REALLOC(name,char,newSize+1); /* 1 for NULL */
    //	    nextPower *= 10;
    //	    nDigits++;
    //	}
    //	sprintf(&(name[newSize - nDigits]),"%d",i);
    newName = [NSString stringWithFormat:@"%@%d",name,i];
    *hashObj = _MKNameTableGetObjectForName(table,newName,nil,&typeP);
    /* Name unused or we found it? */
    if ((!*hashObj) || (*hashObj == anObject))
      return newName;
  }
}

#if 0
char *MKUniqueName(NSString *name,id anObject)
/* name must be a valid malloc'ed string.
* Checks to see if there is an object (other than 'anObject')
* in the Music Kit name table with the specified name.  If so,
* reallocs and returns a name of the form <oldName><int> that
* is not used by any object in the table.
* If name is not in the table, or anObject is already named
* with the given name, returns name.
* anObject may be nil, in which case a name is generated if
* and only if name is already present in the table.
*
* Example of use:
*
* char *s = malloc(10);
* sprintf(s,"hello");
* MKNameObject(MKUniqueName(s),myObject);
* sprintf(s,"hello");
* // Here, myOtherObject will get the name "hello1"
* MKNameObject(MKUniqueName(s),myOtherObject);
* free(s);
*/
{
  unsigned short typeP;
  id hashObj;
  /* First see if it's already there */
  NSString *s;
  if (anObject)
    s = MKGetObjectName(anObject);
  if (s != nil)
    if ([s isEqualToString:name])
      return name;
#if 0
  if (s && !strcmp(s,name))  /* anObject is already named 'name' */
    return name;
#endif
  hashObj = _MKNameTableGetObjectForName(mkNameTable,name,nil,&typeP);
  if (!*hashObj)             /* 'name' isn't in table */
    return name;
  return _MKUniqueName(name,mkNameTable,anObject,&hashObj);
}
#endif

@end
