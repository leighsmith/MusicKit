/*
  $Id$
  Defined In: The MusicKit

  Description:
    Private MusicKit include file.
    This file contains everything used by the MusicKit privately.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2000 The MusicKit Project
*/
/* 
Modification history:

  $Log$
  Revision 1.4  2000/10/11 16:56:10  leigh
  Removed objc-runtime.h since it is included by FoundationKit.h

  Revision 1.3  2000/04/16 04:04:31  leigh
  removed unnecessary includes and defines

  Revision 1.2  1999/07/29 01:26:02  leigh
  Added Win32 compatibility, CVS logs, SBs changes

  09/15/89/daj - Added caching of Note class. (_MKClassNote())
  09/22/89/daj - Moved _MKNameTable functions to _MKNameTable.h.
  10/08/89/daj - Changed types for new _MKNameTable implementation.
  11/10/89/daj - Added caching of Partials class. (_MKClassPartials())
  11/26/89/daj - Added _MKBeginUGBlock() and _MKEndUGBlock().
  11/27/89/daj - Removed arg from _MKCurSample.
  12/3/89/daj  - Added seed and ranSeed tokens.
  12/22/89/daj - Removed uPlus
  01/08/90/daj - Added name arg to _MKNewScoreInStruct().
  02/26/90/daj - Changes to accomodate new way of doing midiFiles. 
                 Added midifile sys excl support.
  03/05/90/daj - Added macros for escape characters.
   3/06/90/daj - Added _MK_repeat to token list.
   3/13/90/daj - Removed _privatemsgs.h because it doesn't work with the new 
                 compiler. Changed all classes to use catagories instead.
		 Moved many declarations from this file to individual private
		 .h files.
   4/21/90/daj - Added macro _MK_MAKECOMPILERHAPPY to surpress warnings
                 that are unnecessary.
   4/23/90/daj - Moved much of this file to individual .h files and renamed
                 the file _utilities.h
		 The way you now use it is this:
		 First import _musickit.h. This imports musickit.h.
		 Then import any special _*.h files you need.
   7/24/90/daj - Added _MKDisableErrorStream to protect multi-threaded 
                 performance. 
   9/26/90/daj - Changed *cvtToId to objc_getClassWithoutWarning
   11/9/92/daj - Added MidiClass
*/
#ifndef __MK__musickit_H___
#define __MK__musickit_H___

//sb: for NSData etc
#import <Foundation/Foundation.h>

#ifndef _MKUTILITIES_H
#define _MKUTILITIES_H

//sb: for _MK_maxPrivPar etc...
#import "_MKParameter.h"
//sb: for MK_freq
#import "params.h" 

#import <stdarg.h> 
#import "midi_spec.h"
#import "MusicKit.h"

/* These are used to see if a class is loaded */ 
/* These are used to avoid going through the findClass hash every time */

typedef struct __MKClassLoaded { 
    id aClass;
    BOOL alreadyChecked;
} _MKClassLoaded;

#define _MK_GLOBAL

extern _MK_GLOBAL _MKClassLoaded _MKNoteClass;
extern _MK_GLOBAL _MKClassLoaded _MKMidiClass;
extern _MK_GLOBAL _MKClassLoaded _MKOrchestraClass;
extern _MK_GLOBAL _MKClassLoaded _MKWaveTableClass;
extern _MK_GLOBAL _MKClassLoaded _MKEnvelopeClass;
extern _MK_GLOBAL _MKClassLoaded _MKSamplesClass;
extern _MK_GLOBAL _MKClassLoaded _MKPartialsClass;
extern _MK_GLOBAL _MKClassLoaded _MKConductorClass;

extern id _MKCheckClassNote() ;
extern id _MKCheckClassMidi() ;
extern id _MKCheckClassOrchestra() ;
extern id _MKCheckClassWaveTable() ;
extern id _MKCheckClassEnvelope() ;
extern id _MKCheckClassSamples();
extern id _MKCheckClassPartials();
extern id _MKCheckClassConductor();

#define _MKClassNote() \
  ((_MKNoteClass.alreadyChecked) ? _MKNoteClass.aClass : \
  _MKCheckClassNote())

#define _MKClassMidi() \
  ((_MKMidiClass.alreadyChecked) ? _MKMidiClass.aClass : \
  _MKCheckClassMidi())

#define _MKClassOrchestra() \
  ((_MKOrchestraClass.alreadyChecked) ? _MKOrchestraClass.aClass : \
  _MKCheckClassOrchestra())

#define _MKClassWaveTable() \
  ((_MKWaveTableClass.alreadyChecked) ? _MKWaveTableClass.aClass : \
  _MKCheckClassWaveTable())

#define _MKClassEnvelope() \
  ((_MKEnvelopeClass.alreadyChecked) ? _MKEnvelopeClass.aClass : \
  _MKCheckClassEnvelope())

#define _MKClassSamples() \
  ((_MKSamplesClass.alreadyChecked) ? _MKSamplesClass.aClass : \
  _MKCheckClassSamples())

#define _MKClassPartials() \
  ((_MKPartialsClass.alreadyChecked) ? _MKPartialsClass.aClass : \
  _MKCheckClassPartials())

#define _MKClassConductor() \
  ((_MKConductorClass.alreadyChecked) ? _MKConductorClass.aClass : \
  _MKCheckClassConductor())

extern void _MKLinkUnreferencedClasses();
extern BOOL _MKInheritsFrom(id aFactObj,id superObj);

#define BACKSLASH '\\'
#define BACKSPACE '\b'
#define FORMFEED '\f'
#define CR '\r'
#define TAB '\t'
#define NEWLINE '\n'
#define QUOTE '\''
#define VT '\v'

#define _MK_TINYTIME ((double)1.0e-05) /* Must be less than 1/2 a tick. */

#define _MK_LINEBREAKS 0 /* No line breaks within envelopes or notes. */

#define _MK_PERMS 0664 /* RW for owner and group. R for others */ 

#define _MK_DPSPRIORITY NSDefaultRunLoopMode 	/*sb: or is it NSEventTrackingRunLoopMode?
						 * originally: 30 */
						/* Almost maximum. Display Postscript priority */

/* Initialization of musickit */
extern void _MKCheckInit();

//sb: needed?
//#import <objc/objc-runtime.h>

/* The following finds the class or nil if its not there. */
/*sb: this is the proper OpenStep way, as far as I know */
#define _MK_FINDCLASS(_x) NSClassFromString(_x)
/* Might want to change this to the following: */
// #define _MK_FINDCLASS(_x) ([Object findClass:_x])

/* String functions */
char *_MKMakeStr();
char *_MKMakeStrcat();
char *_MKMakeSubstr();
char *_MKMakeStrRealloc();

/* Conversion */
extern double _MKStringToDouble(NSString * sVal);
extern int _MKStringToInt(NSString * sVal);
extern NSString * _MKDoubleToString(double dVal);
extern NSString * _MKIntToString(int iVal);
extern NSString * _MKDoubleToStringNoCopy(double dVal);
extern NSString * _MKIntToStringNoCopy(int iVal); 
/* See /usr/include/dsp/dsp.h, imported by musickit.h */
extern DSPFix24 _MKDoubleToFix24(double dval);
extern double _MKFix24ToDouble(DSPFix24 ival);
extern int _MKFix24ToInt(DSPFix24 ival);
extern void _MKDoubleToFix24Array (double *doubleArr, DSPDatum *fix24Arr, int len);
extern void _MKFix24ToDoubleArray (DSPDatum *fix24Arr, double *doubleArr, int len);

// array duplication
NSMutableArray *_MKLightweightArrayCopy(NSMutableArray *oldArray);

/* Files */
/*
extern NSMutableData *_MKOpenFileStream(char * fileName,int *fd,int readOrWrite,
				   char *defaultExtension,BOOL raiseError);
 */
extern NSData *_MKOpenFileStreamForReading(NSString * fileName,
                                           NSString *defaultExtension,BOOL errorMsg);
extern BOOL _MKOpenFileStreamForWriting(NSString * fileName,
                                         NSString *defaultExtension,NSMutableData *theData,BOOL errorMsg);

extern int _MKFindAppWrapperFile(NSString *fileName,NSString **returnNameBuffer);

/* Floating point resoulution */
#define _MK_VARRESOLUTION (((double)1.0/(double)44000.0)/(double)2.0)

/* For debugging */
extern void _MKOrchTrace(id orch,int typeOfInfo,char * fmt, ...);
extern unsigned _MKTraceFlag;
#define _MKTrace() _MKTraceFlag

/* Memory alloc */
extern char * _MKMalloc(); /* These will be replaced with NeXT equiv*/
extern char * _MKCalloc(); 
extern char * _MKRealloc();
#define  _MK_MALLOC( VAR, TYPE, NUM )				\
   ((VAR) = (TYPE *) _MKMalloc( (unsigned)(NUM)*sizeof(TYPE) )) 
#define  _MK_REALLOC( VAR, TYPE, NUM )				\
   ((VAR) = (TYPE *) _MKRealloc((char *)(VAR), (unsigned)(NUM)*sizeof(TYPE)))
#define  _MK_CALLOC( VAR, TYPE, NUM )				\
   ((VAR) = (TYPE *) _MKCalloc( (unsigned)(NUM),sizeof(TYPE) )) 

/* For multi-threaded MK performance. */
extern void _MKDisableErrorStream(void);
extern void _MKEnableErrorStream(void);

#import <Foundation/NSBundle.h>
extern NSBundle *_MKErrorBundle(void);
extern NSString *_MKErrorStringFile(void);
#define _MK_ERRTAB _MKErrorStringFile()

#endif _MKUTILITIES_H



#endif
