/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file should contain only utilities that we always want. 
    That is, this module is always loaded.

  Original Author: David A. Jaffe
  
  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT.
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2003, The MusicKit Project.
*/
/* 
Modification history pre-CVS:

  09/15/89/daj - Added caching of Note class. (_MKCheckClassNote())
  10/27/89/daj - Added argument to _MKOpenFileStream to surpress error msg.
  11/15/89/daj - Added caching of MKPartials class. (_MKCheckClassPartials())
  12/21/89/daj - Changed strstr() calls to isExtensionPresent() in 
                 _MKOpenFileStream(). This insures that the extension is the
		 final extension (i.e. it does the right thing with multiple-
		 extension files).
  01/6/90/daj - Added comments.	Flushed _MKLinkUnreferencedClasses().
  03/13/90/daj - Added "_MK_GLOBAL" to globals for 'ease of grep'.
  03/20/90/daj - Moved _MKInheritsFrom() to here.
  07/16/90/daj - Removed extra sprintfv in MKErrorCode
  07/24/90/daj - Added cthread_set_errno_self in addition to errno setting.
  07/24/90/daj - Added disabling of the error stream for multi-threaded
                 performance. 
  07/24/90/daj - Changed to use _MKSprintf and _MKVsprintf for thread-safety
                 in a multi-threaded Music Kit performance.
  09/02/90/daj - Added MKGetNoDVal() and MKIsNoDVal() 
  08/22/91/daj - Added localization of error strings. 
  10/22/91/DAJ - Flushed mkerrors.m to make it possible to auto-generate
                 localized error strings.
  06/31/92/daj - Changed NXBundle newFromPath: to initFromDirectory: for 3.0 
  10/20/92/daj - Set table name to _MK_ERRTAB so that localization will work.
   11/9/92/daj - Added MidiClass
   6/27/93/daj - Added checking for NULL file name in _MKOpenFileStream.
  07/1/93/daj -  Added an arg to machErr for more descritptive error reporting.
                 Also, added define/undef of MK_NODVAL (and corresponding change
		 in noDVal.h) to avoid compiler warnings.  I *think* I've done
		 this right now, from my reading of the compiler manual. Sigh.
  1/28/96/daj -  Minor optimization to file-reading name check.
*/

#define MK_NODVAL  /* Override reading definition in noDVal.h--see below */
#import "_musickit.h"
#undef MK_NODVAL

#import "_error.h"

#import <stddef.h>  /* errno */
#import <Foundation/NSBundle.h>
#import "MKPlugin.h"
#import "ScorePrivate.h"

/* globals */

_MK_GLOBAL _MKClassLoaded _MKNoteClass = {0};
_MK_GLOBAL _MKClassLoaded _MKOrchestraClass = {0};
_MK_GLOBAL _MKClassLoaded _MKWaveTableClass = {0};
_MK_GLOBAL _MKClassLoaded _MKEnvelopeClass = {0};
_MK_GLOBAL _MKClassLoaded _MKSamplesClass = {0};
_MK_GLOBAL _MKClassLoaded _MKConductorClass = {0};
_MK_GLOBAL _MKClassLoaded _MKPartialsClass = {0};
_MK_GLOBAL _MKClassLoaded _MKMidiClass = {0};
_MK_GLOBAL unsigned _MKTraceFlag = 0;

/* A dumb function that causes a reference to its arguments (to fool the linker.) */
void _MKLinkUnreferencedClasses()
{
}
/* The following mechanism is to make it so it's fast to check if a class
   is loaded. See the macros in _musickit.h */ 
static Class checkClass(_MKClassLoaded *cl, NSString *className)
    /* Gets and initializes class. There are macros that only invoke
       this when the class isn't initialized yet. */
{
    cl->alreadyChecked = YES;
    cl->aClass = NSClassFromString(className);
    [((id) cl->aClass) performSelector:@selector(initialize)]; /* Initialize it now, not later.*/
    return cl->aClass;
}

Class _MKCheckClassMidi() 
{
    return checkClass(&_MKMidiClass,@"MKMidi");
}

Class _MKCheckClassNote() 
{
    return checkClass(&_MKNoteClass,@"MKNote");
}

Class _MKCheckClassPartials() 
{
    return checkClass(&_MKPartialsClass,@"MKPartials");
}

Class _MKCheckClassOrchestra() 
{
    return checkClass(&_MKOrchestraClass,@"MKOrchestra");
}

Class _MKCheckClassWaveTable() 
{
    return checkClass(&_MKWaveTableClass,@"MKWaveTable");
}

Class _MKCheckClassEnvelope() 
{
    return checkClass(&_MKEnvelopeClass,@"MKEnvelope");
}

Class _MKCheckClassSamples()
{
    return checkClass(&_MKSamplesClass,@"MKSamples");
}

Class _MKCheckClassConductor()
{
    return checkClass(&_MKConductorClass,@"MKConductor");
}


/* MusicKit malloc functions */
char *_MKCalloc(unsigned nelem, unsigned elsize)
{
    void *rtn = calloc(nelem, elsize);
    if (!rtn) {
	NSLog(@"MusicKit memory exausted.\n");
	exit(1);
    }
    return rtn;
}

void *_MKMalloc(unsigned size)
{
    void *rtn = malloc(size);
    
    if (!rtn) {
	NSLog(@"MusicKit memory exausted.\n");
	exit(1);
    }
    return rtn;
}

char *_MKRealloc(void *ptr, unsigned size)
{
    char *rtn = realloc(ptr,size);
    
    if (!rtn) {
	NSLog(@"MusicKit memory exausted.\n");
	exit(1);
    }
    return rtn;
}

// Lightweight NSArray copying
// Now that we use NSArrays, a [List copyWithZone] did a shallow copy, whereas
// [NSMutableArray copyWithZone] does a deep copy, so we emulate the List operation, creating
// a new NSMutableArray, but populating it with the old array's elements, rather than duplicates.
// Being a "copy" method, we return a fully allocated, retained, non-auto-released object.
NSMutableArray *_MKLightweightArrayCopy(NSMutableArray *oldArray)
{
    NSMutableArray *newArray = [[NSMutableArray alloc] init];

    [newArray addObjectsFromArray: oldArray];
    return newArray;
}

// Allegedly, MacOS 10.x does a deep copy of NSArrays with -mutableArray,
// but this behaviour is not shared by GNUstep. Hence we make explicit
// which behaviour we are requesting.
// Being a "copy" method, we return a fully allocated, retained, non-
// auto-released object.
NSMutableArray *_MKDeepMutableArrayCopy(NSMutableArray *oldArray)
{
    NSMutableArray *newArray;
    int i, count;
    if (!oldArray) {
	return nil;
    }
    count = [oldArray count];
    newArray = [[NSMutableArray alloc] initWithCapacity: count];
    for (i = 0; i < count; i++) {
	[newArray addObject: [[oldArray objectAtIndex: i] copy]];
    }
    [newArray makeObjectsPerformSelector: @selector(release)];
    return newArray;
}

/* Tracing */
/* See musickit.h for details */

/* Set a trace bit */
unsigned MKSetTrace(int debugFlag)
{
    return (unsigned)(_MKTraceFlag |= debugFlag);
}

/* Clear a trace bit */
unsigned MKClearTrace(int debugFlag)
{
    return (unsigned)(_MKTraceFlag &= (~debugFlag));
}

/* Check a trace bit */
BOOL MKIsTraced(int debugFlag)
{
    return (_MKTraceFlag & debugFlag) ? YES : NO;
}

/* Error handling */
/* See musickit.h for details */

static void (*errorProc)(NSString *msg) = NULL;

/* Sets proc to be used when MKError() is called. If errProc is NULL,
   uses the default error handler, which writes to stderr. When the
   *errProc is called, errno is set to the MKErrno corresponding to err.
   errProc takes one string argument. */
void MKSetErrorProc(void (*errProc)(NSString *msg))
{
    errorProc = errProc;
}

// errorStream == nil implies output to standard error
static NSMutableData *errorStream = nil;

NSMutableData *MKErrorStream(void)
    /* Returns the Music Kit error stream */
{
    return errorStream;
}

void MKSetErrorStream(NSMutableData *aStream) 
    /* Sets the Music Kit error stream. nil means stderr.
       The Music Kit initialization sets the error stream to stderr. */
{
    if (aStream) {
        errorStream = aStream;
    }
    else {
        errorStream = nil;
    }
}

#define UNKNOWN_ERROR NSLocalizedStringFromTableInBundle(@"unknown error", _MK_ERRTAB, _MKErrorBundle(), "")

// LMS: This should be done with a NSDictionary 
NSString * _MKGetErrStr(int errCode)
    /* Returns the error string for the given code or "unknown error" if
       the code is not a MKErrno. The string is not copied. Note that
       some of the strings have printf-style 'arguments' embedded. */
{
    NSString * msg = nil;
    if (errCode < MK_ERRORBASE || errCode > (int) MK_highestErr)
      return UNKNOWN_ERROR;
    errno = errCode;
    // LMS: since cthread_errno() is not called anywhere this is probably redundant and could be removed.
    // alternatively we could use the [NSThread threadDictionary] to store it if we wanted to retrieve it.
    // cthread_set_errno_self(errCode);
    switch (errCode) {
      case MK_musicKitErr:   /* Generic Music Kit error. */
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: %@.", _MK_ERRTAB, _MKErrorBundle(), "This error is used as a way of specifying Music Kit errors not otherwise defined in this list.");
	break;
      case MK_machErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: %@. Mach Error: %@ in '%@'", _MK_ERRTAB, _MKErrorBundle(), "This error is used for errors from the operating system.  For example, the MIDI object uses this error to report problems gaining access to the MIDI device.  There are two arguments which must be in the order indicated.  The first argument is the Music Kit explanation of what's wrong.  The second is the Mach explanation (as returned by mach_error_string).  The third is the offending function.");
	break;
      case MK_cantOpenFileErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Can't open file %@.", _MK_ERRTAB, _MKErrorBundle(), "This error warns that a file can't be opened.");
	break;
      case MK_cantCloseFileErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Can't close file %@.", _MK_ERRTAB, _MKErrorBundle(), "This error warns that a file can't be closed.");
	break;
      case MK_outOfOrderErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Note at time %f out-of-order. Current time is %f.", _MK_ERRTAB, _MKErrorBundle(), " This error warns that notes were found in a scorefile with times out of order.  There are two arguments, which must be in the order indicated. The first is the time of the incorrect note.  The second is the current time.");
	break;
      case MK_samplesNoResampleErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: MKSamples object cannot resample.", _MK_ERRTAB, _MKErrorBundle(), " This error warns that the MKSamples object cannot change the sampling rate of a Waveform.  This error will rarely be seen by a user.");
	break;
      case MK_noMoreTagsErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: No more noteTags.", _MK_ERRTAB, _MKErrorBundle(), "This error warns that the Music Kit has run out of "noteTags".  Thiswill probably never be seen by a user. ");
	break;
      case MK_notScorefileObjectTypeErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: The class %s does not have the appropriate methods to be used as a scorefile object type.", _MK_ERRTAB, _MKErrorBundle(), " This error warns that a class is specified in a scorefile as a 'scorefile object type'; but that class does not implement the appropriate methods to be used in that way.  This error will rarely if ever occur in practice. ");
	break;
	/* ---------------- Synthesis errors --------------------- */
      case MK_orchBadFreeErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Unit Generators are still in use.", _MK_ERRTAB, _MKErrorBundle(), " This error indicates that the developer attempted to abort the MKOrchestra while manually-allocated Unit Generators or SynthPatches were still allocated.  This error rarely if ever is seen by users.");
	break;
      case MK_synthDataCantClearErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Can't clear SynthData memory.", _MK_ERRTAB, _MKErrorBundle(), " A DSP error occurred when trying to clear DSP memory.  This error rarely if ever is seen by users.");
	break;
      case MK_synthDataLoadErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Can't load SynthData.", _MK_ERRTAB, _MKErrorBundle(), " A DSP error occurred when trying to load DSP memory.  This error rarely if ever is seen by users.");
	break;
      case MK_synthDataReadonlyErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Can't clear or load read-only SynthData.", _MK_ERRTAB, _MKErrorBundle(), "This error appears when an application attempts to clear or load DSPmemory that is marked as 'read-only'.  This error rarely if ever is seen by users. ");
	break;
      case MK_synthInsOmitNoteErr:
          msg = NSLocalizedStringFromTableInBundle(@"SynthInstrument: Omitting note at time %f.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if there are not enough DSP resources to play a note. Its one argument is the time of the note.");
	break;
      case MK_synthInsNoClass:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: No MKSynthPatch class set in SynthInstrument.", _MK_ERRTAB, _MKErrorBundle(), "This error warns that a SynthInstrument object cannot do DSP synthesis because no MKSynthPatch class was set.");
	break;
      case MK_ugLoadErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Can't load unit generator %s.", _MK_ERRTAB, _MKErrorBundle(), "A DSP error occurred when trying to load a unit generator module into DSP memory.  This error rarely if ever is seen by users. The one argument is the class of the unit generator that could not be loaded.");
	break;
      case MK_ugBadArgErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Argument %d out of bounds for %s.", _MK_ERRTAB, _MKErrorBundle(), " This error indicates that a DSP error occurred while attempting to set a DSP unit generator argument to an address. The three arguments, which must be in the order indicated, are the address number, the argument name and the unit generator name.  This error rarely if ever is seen by users.");
	break;
      case MK_ugBadAddrPokeErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Could not put address %d into argument %@ of %@.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates that a DSP error occurred while attempting to set a DSP unit generator argument to an address. The three arguments, which must be in the order indicated, are the address number, the argument name and the unit generator name.  This error rarely if ever is seen by users.");
	break;
      case MK_ugBadDatumPokeErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Could not put datum %d into argument %@ of %@.", _MK_ERRTAB, _MKErrorBundle(), " This error indicates that a DSP error occurred while attempting to set a DSP unit generator argument to a datum value.  The three arguments, which must be in the order indicated, are the datum value, the argument name and the unit generator name.  This error rarely if ever is seen by users. ");
	break;
      case MK_ugOrchMismatchErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Attempt to put address into argument of unit generator of a different orchestra.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates that an attempt was made to put a DSP address into a unit generator running on a different DSP MKOrchestra.  This error rarely if ever is seen by users.");
	break;
      case MK_ugArgSpaceMismatchErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Attempt to put %s-space address into %s-space argument %@ of %@.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates that an attempt was made to put a DSP address value with a memory space that does not match the memory space which the DSP unit generator assumes.  The arguments, which must be in the order specified, are the space of the address, the space of the agrument, the name of the argument, and the name of the unit generator.   This error rarely if ever is seen by users.");	
	break;
      case MK_ugNonAddrErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Attempt to set address-valued argument %@ of %@ to datum value.", _MK_ERRTAB, _MKErrorBundle(), " This error indicates that an attempt was made to set a DSP unit generator argument to a datum value when that unit generator argument accepts only an address.  The two arguments, which must be in the order indicated, are the name of the argument and the unit generator name.");	
	break;
      case MK_ugNonDatumErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Attempt to set argument %@ of %@ to an address.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates that an attempt was made to set a DSP unit generator argument to an address value when that unit generator argument accepts only a datum.  The two arguments, which must be in the order indicated, are the name of the argument and the unit generator name.");	
	break;
	/* --------- Scorefile language parse errors -------------- */
	/* These don't have "Scorefile error:" at the beginning because 
	   the scorefile error printing function gives enough information. */
	/* Illegal constructs */
      case MK_sfBadExprErr:
          msg = NSLocalizedStringFromTableInBundle(@"Illegal expression.", _MK_ERRTAB, _MKErrorBundle(), "Illegal expression.");
	break;
      case MK_sfBadDefineErr:
          msg = NSLocalizedStringFromTableInBundle(@"Illegal %s definition.", _MK_ERRTAB, _MKErrorBundle(), "Illegal definition.  The one argument is the type of the definition. For example 'Illegal envelope definition.'");
	break;
      case MK_sfBadParValErr:
          msg = NSLocalizedStringFromTableInBundle(@"Illegal parameter value.", _MK_ERRTAB, _MKErrorBundle(), "Illegal value for a Note's parameter. ");
	break;
      case MK_sfNoNestDefineErr:
          msg = NSLocalizedStringFromTableInBundle(@"%s definitions cannot be nested.", _MK_ERRTAB, _MKErrorBundle(), "This error warns that a certain kind of definition may not be nested.  The one argument is the type of definition.  For example 'Envelope definitions cannot be nested.'");
	break;
	/* Missing constructs */
      case MK_sfBadDeclErr:
          msg = NSLocalizedStringFromTableInBundle(@"Missing or illegal %s declaration.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates a missing or illegal declaration of some kind. The kind of declaration is given by the one argument. For example 'Missing or illegal envelope declaration.'");
	break;
      case MK_sfMissingStringErr:
          msg = NSLocalizedStringFromTableInBundle(@"Missing '%s'.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates that an expected construct of some kind is missing. The one argument is the kind of thing that is missing.  For example, 'Missing envelope.'");
	break;
      case MK_sfBadNoteTypeErr:
          msg = NSLocalizedStringFromTableInBundle(@"Missing noteType or duration.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates a bad note type or duration. ");
	break;
      case MK_sfBadNoteTagErr:
          msg = NSLocalizedStringFromTableInBundle(@"Missing noteTag.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates a missing note tag. ");
	break;
      case MK_sfMissingBackslashErr:
          msg = NSLocalizedStringFromTableInBundle(@"Back-slash must preceed newline.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if a backslash appears outside of a string and the backslash is not followed by a newline. ");
	break;
      case MK_sfMissingSemicolonErr:
          msg = NSLocalizedStringFromTableInBundle(@"Illegal statement. (Missing semicolon?) ", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an illegal statement is encountered and the Music Kit thinks the problem may be a missing semicolon.  ");
	break;
      case MK_sfUndeclaredErr:
          msg = NSLocalizedStringFromTableInBundle(@"Undefined %s: %s", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an undefined construct of a certain type is encountered.  There are two arguments, which must be in the order indicated.  The first argument is the type of construct and the second is the token encountered in the file.  For example, 'Undefined envelope: dog'.");
	break;
      case MK_sfBadAssignErr:
          msg = NSLocalizedStringFromTableInBundle(@"You can't assign to a %s.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an attempt is made to assign to a construct that cannot accept an assignment.  Example: 'You can't assign to a number.'  It is only legal to assign to a variable or similar construct.");
	break;
      case MK_sfBadIncludeErr:
          msg = NSLocalizedStringFromTableInBundle(@"A %s must appear in the same file as the matching %s", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if matching constructs are not found in the same file.  For example: 'A { must appear in the same file as the matching }.'");
	break;
      case MK_sfBadParamErr:
          msg = NSLocalizedStringFromTableInBundle(@"Parameter name expected here.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when something other than a note parameter name is found where a note parameter name is expected.");
	break;
      case MK_sfNumberErr:
          msg = NSLocalizedStringFromTableInBundle(@"Numeric value expected here.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when something other than a numeric value is found where a numeric value is expected.");
	break;
      case MK_sfStringErr:
          msg = NSLocalizedStringFromTableInBundle(@"String value expected here.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when something other than a string value is found where a string value is expected.");
	break;
      case MK_sfGlobalErr:
          msg = NSLocalizedStringFromTableInBundle(@"A %s may not be global.", _MK_ERRTAB, _MKErrorBundle(), "A construct that may not be global is declared as global. This error rarely occurs, since global variables are not documented.");
	break;
      case MK_sfCantFindGlobalErr:
          msg = NSLocalizedStringFromTableInBundle(@"Can't find global %s.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when a request is made to import a global that cannot be found.  This error rarely occurs, since global variables are not documented. ");
	break;
	/* Duplicate constructs */
      case MK_sfMulDefErr:
          msg = NSLocalizedStringFromTableInBundle(@"%s is already defined as a %s.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when the user attempts to define a token that is already defined.  The two arguments, which must occur in the order indicated, are the name of the token and the type it was previously defined as.");
	break;
      case MK_sfDuplicateDeclErr:
          msg = NSLocalizedStringFromTableInBundle(@"Duplicate declaration for %s.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates a duplicate declaration for the specified token. ");
	break;
	/* Construct in wrong place */
      case MK_sfNotHereErr:
          msg = NSLocalizedStringFromTableInBundle(@"A %s may not appear here.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when something occurs in the wrong place.  The single argument is the type of the thing that is in the wrong place.");
	break;
      case MK_sfWrongTypeDeclErr:
          msg = NSLocalizedStringFromTableInBundle(@"%s may not be declared as a %s here.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when something is declared where it should not be declared.  The two arguments, which must be in the order indicated, are the token that the user is trying to declare and the type that he is trying to declare it as.");
	break;
      case MK_sfBadHeaderStmtErr:
          msg = NSLocalizedStringFromTableInBundle(@"A header statement or declaration may not begin with %s.", _MK_ERRTAB, _MKErrorBundle(), "This is a common error indicating an illegal header statement or declaration that begins with the token indicated.");
	break;
      case MK_sfBadStmtErr:
          msg = NSLocalizedStringFromTableInBundle(@"A body statement or declaration may not begin with %s.", _MK_ERRTAB, _MKErrorBundle(), "This is a common error indicating a body statement or declaration that begins with the token indicated.");
	break;
      case MK_sfBadInitErr:
          msg = NSLocalizedStringFromTableInBundle(@"Illegal %s initialization.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates an attempt to illegally initialize the specified construct.");
	break;
      case MK_sfNoTuneErr:
          msg = NSLocalizedStringFromTableInBundle(@"Argument to 'tune' must be a pitch variable or number.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when an illegal argument follows the 'tune' construct. ");
	break;
      case MK_sfNoIncludeErr:
          msg = NSLocalizedStringFromTableInBundle(@"Can't 'include' a file when not reading from a file.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when individual statements are being typed in by the user and the user attempts to 'include' a file.  This error never occurs, since the functionality is not yet implemented.");
	break;
      case MK_sfCantFindFileErr:
          msg = NSLocalizedStringFromTableInBundle(@"Can't find file %s.", _MK_ERRTAB, _MKErrorBundle(), "The specified file could not be found. The single argument is the name of the file. ");
	break;
      case MK_sfCantWriteErr:
          msg = NSLocalizedStringFromTableInBundle(@"Can't write %s.", _MK_ERRTAB, _MKErrorBundle(), "The specified file could not be written. The single argument is the name of the file. ");
	break;
      case MK_sfOutOfOrderErr:
          msg = NSLocalizedStringFromTableInBundle(@"%s values must be increasing.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when values which must be increasing appear in some other order.  The one argument is the type of values.  Example: 'Envelope x values must be increasing.'");
	break;
      case MK_sfUnmatchedCommentErr:
          msg = NSLocalizedStringFromTableInBundle(@"'comment' without matching 'endComment'.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when a 'comment' statement appears without a matching 'endComment' statement.");
	break;
      case MK_sfInactiveNoteTagErr:
          msg = NSLocalizedStringFromTableInBundle(@"%s without active noteTag.", _MK_ERRTAB, _MKErrorBundle(), "This error appears when a note that requires an active noteTag appears with a noteTag that is not active.  For example, it occurs if a noteOff has a noteTag for which there was no preceeding noteOn.  The single argument is the type of the note.");
	break;
      case MK_sfCantFindClass:
          msg = NSLocalizedStringFromTableInBundle(@"Can't find class %s.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when the Music Kit cannot find the requested class. ");
	break;
      case MK_sfBoundsErr:
          msg = NSLocalizedStringFromTableInBundle(@"Lookup value out of bounds.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when the lookup value specified in a '@' scorefile construct is out of bounds. ");
	break;
      case MK_sfTypeConversionErr:
          msg = NSLocalizedStringFromTableInBundle(@"Illegal type conversion.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when the user attempts an illegal type conversion. For example, it occurs if he tries to assign an envelope to a variable that is typed as an 'int'.");
	break;
      case MK_sfReadOnlyErr:
          msg = NSLocalizedStringFromTableInBundle(@"Can't set %s. It is a readOnly variable.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when the user tries to set a variable that is read only. The single argument is the variable he tried to set.");
	break;
      case MK_sfArithErr:
          msg = NSLocalizedStringFromTableInBundle(@"Arithmetic error.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs an arithmetic error, such as division by 0. ");
	break;
      case MK_sfNonScorefileErr:
          msg = NSLocalizedStringFromTableInBundle(@"This doesn't look like a scorefile.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if the user tries to read a file as a scorefile and that file is not a scorefile.");
	break;
      case MK_sfTooManyErrorsErr:
          msg = NSLocalizedStringFromTableInBundle(@"Too many parser errors. Quitting.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs when the number of errors exceeds some limit.  (The limit is set by the application.)");
	break;
	/* -------------- MKUnitGenerator Library errors -------------- */
      case MK_ugsNotSetRunErr:
          msg = NSLocalizedStringFromTableInBundle(@"Unitgenerator Library: %s must be set before running %s.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if a DSP MKUnitGenerator argument is left unset and then the MKUnitGenerator is sent the -run message.  The two arguments, which must  be in the order indicated, are the argument that was left unset and the name of the MKUnitGenerator.  This error is rarely if ever seen by the user.");
	break;
      case MK_ugsPowerOf2Err:
          msg = NSLocalizedStringFromTableInBundle(@"Unitgenerator Library: Table size of %s must be a power of 2.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates a request to load an oscillator table that is a size which is not a power of 2.  This error is rarely seen by the user.");
	break;
      case MK_ugsNotSetGetErr:
          msg = NSLocalizedStringFromTableInBundle(@"Unitgenerator Library: %s of %s must be set before getting %s.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates that a particular argument of a particular DSP unit generator must be set before asking for the value of another argument of that unit generator.  The three arguments, which must be in the order specified, are the argument that needs to be set, the unit generator for which it needs to be set, and the argument whose value is being requested.  Users rarely see this error.");
	break;
	/* -------------------- MKSynthPatch Library errors -------------- */
      case MK_spsCantGetMemoryErr:
          msg = NSLocalizedStringFromTableInBundle(@"Synthpatch Library: Out of %s memory at time %.3f.", _MK_ERRTAB, _MKErrorBundle(), " This error indicates that a particular kind of memory is not available. The two arguments, which must be in the order indicated, are the type of memory and the time of the note for which the memory cannot be found. For example: '...Out of wavetable memory at time 3.123'.");
	break;
      case MK_spsSineROMSubstitutionErr:
          msg = NSLocalizedStringFromTableInBundle(@"Synthpatch Library: Out of wavetable memory at time %.3f. Using sine ROM.", _MK_ERRTAB, _MKErrorBundle(), "This error is a special purpose version of the preceeding error.  It indicates that there is no more wavetable memory at the indicated time and that the DSP sine ROM is being used instead.  The argument is the time at which the memory is not available.");
	break;
      case MK_spsInvalidPartialsDatabaseKeywordErr:
          msg = NSLocalizedStringFromTableInBundle(@"Synthpatch Library: Invalid timbre database keyword: %s.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if a scorefile or applicatin specifies a timbre specifier that is invalid or does not correspond to a known timbre.  The single argument is the timbre specifier.");
	break;
      case MK_spsOutOfRangeErr:
          msg = NSLocalizedStringFromTableInBundle(@"Synthpatch Library: %s out of range.", _MK_ERRTAB, _MKErrorBundle(), "This error occurs if a parameter is out of range for the MKSynthPatch. The single argument is the parameter that is out of range.  For example, '...pitch out of range.'");
	break;
      case MK_spsCantGetUGErr:
          msg = NSLocalizedStringFromTableInBundle(@"Synthpatch Library: Can't allocate %s at time %.3f.", _MK_ERRTAB, _MKErrorBundle(), "This error indicates that the MKSynthPatch could not allocate the specified resource at the specifed time.  The two arguments, which must be in the order specified, are the resource that could not be allocated and the time at which it could not be allocated.  Example: 'Can't allocate Pluck noise generator at time 3.123.'");
	break;
	/* ---------------- Post-2.0 errors ------------------------- */
      case MK_synthDataCantReadDSPErr:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: Can't read SynthData array from the DSP.", _MK_ERRTAB, _MKErrorBundle(), "A DSP error occurred when trying to read data from DSP memory.  This error rarely if ever is seen by users.");
	break;
      case MK_dspMonitorVersionError:
          msg = NSLocalizedStringFromTableInBundle(@"Music Kit: DSP runtime monitor version does not match Music Kit version for object: %s", _MK_ERRTAB, _MKErrorBundle(), "User has wrong DSP monitor.");
	break;
      default:
	break;
    }
    if (msg)
      return msg;
    return UNKNOWN_ERROR;
}

static BOOL errorStreamEnabled = YES;

void _MKDisableErrorStream(void)
{
    errorStreamEnabled = NO;
}

void _MKEnableErrorStream(void)
{
    errorStreamEnabled = YES;
}

// Calls the user's error proc (set with MKSetErrorProc), if any, with one argument, the msg.
// Otherwise, writes the message on the MusicKit error stream.
void MKError(NSString *msg)
{
    NSMutableData *errorStream = MKErrorStream();
    
    if (!msg)
        return;
    if (errorProc) {
	errorProc(msg);
	return;
    }
    else if (!errorStreamEnabled)
        return;
    if(errorStream == nil) {
        NSLog(@"%@\n", msg);      // default is to write to the standard logging.
    }
    else {
        [errorStream appendData: [msg dataUsingEncoding: NSNEXTSTEPStringEncoding]];
        [errorStream appendBytes: "\n" length: 1];
    }
}

/* Calling sequence like NSLog, but first arg is error code. It used to set errno. */
void MKErrorCode(int errorCode,...)
{
    NSString *fmt;
    va_list ap;
    
    va_start(ap, errorCode);
    errno = errorCode;
    // cthread_set_errno_self(errorCode);
    fmt = _MKGetErrStr(errorCode);
    if (errorProc) {
       // Immutable NSStrings are that thread-safe
        MKError([[[NSString alloc] initWithFormat: fmt arguments: ap] autorelease]);
    }
    else if (!errorStreamEnabled)
        return;
    else {
        NSString *theErrorString = [[[NSString alloc] initWithFormat:fmt arguments:ap] autorelease];
        NSMutableData *errorStream = MKErrorStream();
	
        if(errorStream == nil) {
            NSLog(@"%@\n", theErrorString); // default is to write to the standard logging.
        }
        else {
            [errorStream appendData: [theErrorString dataUsingEncoding: NSNEXTSTEPStringEncoding]];
            [errorStream appendBytes: "\n" length:1];
        }
    }
    va_end(ap);
}

/* Decibels */
/* See musickit.h */
double MKdB(double dbVal)
{
    /* dB to linear conversion */
    return (double) pow(10.0,dbVal/20.0);
}

/* Function to simplify file read/write of files. */

BOOL _MKOpenFileStreamForWriting(NSString * fileName,NSString *defaultExtension,NSMutableData *theData,BOOL errorMsg)
/*sb: changed as follows:
 *    For writing, returns the file name, with the extension appended if necessary.
 *
 *    The fd is no longer used.
 */
{
    if (!fileName) return NO;
    if (![fileName length]) return NO;

    if (defaultExtension) {
        if (![[fileName pathExtension] isEqualToString:defaultExtension]) {
            fileName = [fileName stringByAppendingPathExtension:defaultExtension];
        }
    }
    if (![theData writeToFile:fileName atomically:YES]) {
        if (errorMsg)
            MKErrorCode(MK_cantOpenFileErr,fileName);
        return NO;
    }

    return YES;
}

NSData *_MKOpenFileStreamForReading(NSString * fileName, NSString *defaultExtension, BOOL errorMsg)
    /* The algorithm is as follows:
       For write: append the extension if it's not already there somewhere.
       For read: look up without extension. If it's no there, append
       extension and try again. */
    /*sb: changed as follows: for reading, returns file contents as an NSData object.
    *    No longer supports file writing (see function above).
    */
{
    NSMutableData *rtnVal = nil;
    BOOL isDir;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (fileName == nil)
        return nil;
    if (![fileName length])
        return nil;

    if ([manager fileExistsAtPath: fileName isDirectory: &isDir] && !isDir)
        rtnVal = [NSData dataWithContentsOfFile: fileName];
    else if (defaultExtension != nil) {
        if ([manager fileExistsAtPath: [fileName stringByAppendingPathExtension: defaultExtension] isDirectory: &isDir] && !isDir)
            rtnVal = [NSData dataWithContentsOfFile: [fileName stringByAppendingPathExtension: defaultExtension]];
    }
    else if (errorMsg)
        MKErrorCode(MK_cantOpenFileErr, fileName);

    return rtnVal;
}


#if 0
/* MKOrchestra set/get */

/* At one time, I was thinking of supporting a List of all MKOrchestra classes
   so that people can add Orchestras for other hardware. But the changes
   needed to MKUnitGenerator, MKSynthPatch, etc. would be quite extensive. It's
   misleading to suggest that we really support other hardware now. Thus
   this function's not supported. */

static id orchList = nil;

id MKOrchestraClasses(void)
    /* Returns a List of MKOrchestra factories. Ordinarily this list contains
	only the MKOrchestra factory. However you may modify this List to
	add your own MKOrchestra analog. This List is used for any
	"broadcasts". For example, the Conductor sends +flushTimedMessages
	to each of the elements in the List. */
{
    return orchList ? orchList : (orchList = [[NSMutableArray alloc] init]);
}
#endif


/* Used by AsympUG, MKSynthPatch, etc. */
static double preemptDuration = .006;


double MKPreemptDuration(void)
/* Obsolete */
{
    return preemptDuration;
}

/* See musickit.h */
double MKGetPreemptDuration(void)
{
    return preemptDuration;
}

void MKSetPreemptDuration(double val)
{
    preemptDuration = val;
}

BOOL _MKInheritsFrom(id aFactObj,id superObj)
    /* Returns yes if aFactObj inherits from superObj */
{
    id obj = [NSObject class];
    for (;(aFactObj) && (aFactObj != obj) && (aFactObj != superObj);
	 aFactObj = [aFactObj superclass])
      ;
    return (aFactObj == superObj);
}



char * 
_MKMakeStr(str)
    char *str;
    /* Make a string and copy str into it. Returns 
       the new string. */
{
    char *rtnVal;
    if (!str)
      return NULL;
    _MK_MALLOC(rtnVal,char,strlen(str)+1);
    strcpy(rtnVal,str);
    return rtnVal;
}

char *
_MKMakeStrcat(str1,str2)
    char *str1,*str2;
    /* Makes a new string with str1 followed by str2. */
{
    char *rtnVal;
    if ((!str1) || (!str2))
      return NULL;
    _MK_MALLOC(rtnVal,char,strlen(str1)+strlen(str2)+1);
    strcpy(rtnVal,str1);
    strcat(rtnVal,str2);
    return rtnVal;
}

char *
_MKMakeSubstr(str,startChar,endChar)
    char *str;
    int startChar,endChar;
    /* Makes a new string consisting of a substring from the startChar'th
       character to the endChar'th character. If endChar is greater than
       the length of str, end at the end of the string. */
{
    char *rtnVal;
    register int i,len;
    register char *p,*q;
    if (!str)
      return NULL;
    len = strlen(str);
    endChar = MIN(endChar, len);
    _MK_MALLOC(rtnVal,char,endChar-startChar+2);
    p = str;
    q = rtnVal;
    if (startChar < 1) 
      startChar = 1;
    p += (startChar - 1);
    for (i = startChar; i <= endChar; i++)
      *q++ = *p++;
    *q = '\0';
    return rtnVal;
}

char *
_MKMakeStrRealloc(str, newStrPtr)
    char *str;
    char **newStrPtr;
    /* Assumes newStrPtr is already a valid string and does
       a REALLOC. Returns the new string and sets **newStrPtr
       to that string. */
{
    _MK_REALLOC(*newStrPtr,char,strlen(str)+1);
    strcpy(*newStrPtr,str);
    return *newStrPtr;
}


/* This should be left here, even though there is an inline version
 * in the header file.  (See compiler manual,which says:
 * This combination of inline and extern has almost the effect of a
 * macro.  The way to use it is to put a function definition in a header
 * file with these keywords, and put another copy of the definition
 * (lacking inline and extern) in a library file.  The definition in the
 * header file will cause most calls to the function to be inlined.  If
 * any uses of the function remain, they will refer to the single copy in
 * the library.
 * 
 */

double MKGetNoDVal(void)
  /* Returns the special NaN that the Music Kit uses to signal "no value". */
{
	union {double d; int i[2];} u;
	u.i[0] = _MK_NANHI;
	u.i[1] = _MK_NANLO;
	return u.d;
}

int MKIsNoDVal(double val)
  /* Compares val to see if it is the special NaN that the Music Kit uses
     to signal "no value". */
{
	union {double d; int i[2];} u;
	u.d = val;
	return (u.i[0] == _MK_NANHI); /* Don't bother to check low bits. */
}

/* The following is concerned with localization of strings. */

NSBundle *_MKErrorBundle(void)
{
    static NSBundle *musicKitStringsBundle = nil;
    if (!musicKitStringsBundle) {
	// Find the framework bundle, this is a global resource, so the path should be: framework_dir/Resources/Localized.strings
        musicKitStringsBundle = [NSBundle bundleForClass: [MKNote class]];
//	musicKitStringsBundle = 
//	  [[NSBundle alloc] initWithPath:@"/usr/local/lib/MusicKit/Languages"];
    }
    /* Strings should be in the file "Localized.strings" */
    return musicKitStringsBundle;
}

NSString *_MKErrorStringFile(void)
{   /* This is the name of the error string file */
    if (_MKErrorBundle()) /* This check may not be needed */
      return @"Localized";
    else return nil;
}


int _MKFindAppWrapperFile(NSString *fileName, NSString **returnName)
	/* fileName should include extension.
	 * returnNameBuffer should be of size MAXPATHLEN + 1.
	 * This function returns 1 and sets returnNameBuffer if successful.
         * If unsuccessful, returns 0.
         */
{
	NSBundle *bundle = [NSBundle mainBundle];
        NSString *retName;
	if (!bundle)
   	   return 0;
        retName = [bundle pathForResource:fileName ofType:@""];
        returnName = &retName;
	return (retName != nil);
}

void MKLoadAllBundlesOneOff(void)
{
    static BOOL done = NO;
    if (!done) {
        MKLoadAllBundles();
        done = YES;
    }
}

BOOL MKLoadAllBundles(void)
{
    NSArray *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    unsigned int i, j;
    id newClass;
    BOOL loadedSome = FALSE;

    for(i = 0; i < [libraryDirs count]; i++) {
        NSString *path = [[libraryDirs objectAtIndex: i]
                            stringByAppendingPathComponent: MK_BUNDLE_DIR];
        NSArray *files = [[NSFileManager defaultManager]
                            directoryContentsAtPath:path];

        for (j = 0 ; j < [files count] ; j++) {
            NSString *tryFile = [files objectAtIndex:j];
            if ([[tryFile pathExtension] isEqualToString: MK_BUNDLE_EXTENSION]) {
                tryFile = [path stringByAppendingPathComponent:tryFile];
                if ([[NSFileManager defaultManager] isReadableFileAtPath: tryFile]) {
                    NSBundle *bundleToLoad = [NSBundle bundleWithPath:tryFile];
                    NSLog(@"Attempting to load bundle at %@",tryFile);
                    if ((newClass = [[[bundleToLoad principalClass] alloc] init])) {
                        NSLog(@"Managed to load principal class");
                        loadedSome = TRUE;
                        if ([newClass conformsToProtocol:@protocol(MusicKitPlugin)]) {
                            [(id<MusicKitPlugin>)newClass setDelegate:[MKScore class]];
                            [MKScore addPlugin:newClass];
                        }
                        [newClass release];
                    }
                }
            }
        }
    }
    return loadedSome;
}    
