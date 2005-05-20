/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file has trace codes as well as error codes used by the Music Kit.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
#ifndef __MK_errors_H___
#define __MK_errors_H___

#import <Foundation/Foundation.h>

/* Music Kit TRACE codes */
#define MK_TRACEORCHALLOC 1       /* MKOrchestra allocation information */
#define MK_TRACEPARS 2            /* App params, when first encountered. */
#define MK_TRACEDSP 4             /* Music Kit DSP messages */
#define MK_TRACEMIDI 8            /* MIDI in/out/time warnings */
#define MK_TRACEPREEMPT 16        /* MKSynthInstrument preemptions msgs */
#define MK_TRACESYNTHINS  32      /* MKSynthInstrument messages */
#define MK_TRACESYNTHPATCH 64     /* MKSynthPatch library messages */
#define MK_TRACEUNITGENERATOR 128 /* MKUnitGenerator library messages */
#define MK_TRACECONDUCTOR 256     /* Conductor time messages */
#define MK_TRACEDSPARRAYS 512     /* Print arrays loaded to DSP */

/* Tracing.  */
/*!
  @brief Trouble-shoot the Music Kit  Turns on specified trace bit.

  To aid in debugging, the Music Kit is peppered with activity-tracing
  messages that print to <b>stderr</b> if but asked.The trace messages are
  divided into eight categories, represented by the following codes:
     
   <b>	Code	Value	Meaning</b>
   	MK_TRACEORCHALLOC	1	DSP resource allocation
   	MK_TRACEPARS	2	Application-defined parameters
   	MK_TRACEDSP	4	DSP manipulation
   	MK_TRACEMIDI	8	MIDI manipulation
   	MK_TRACEPREEMPT	16	MKSynthPatch preemption
   	MK_TRACESYNTHINS	32	SynthInstrument mechanations
     	MK_TRACESYNTHPATCH	64	MKSynthPatch library messages
     	MK_TRACEUNITGENERATOR	128	MKUnitGenerator library messages
     	MK_TRACECONDUCTOR	256	Conductor time setting messages
     	MK_TRACEDSPARRAYS	512	DSP array-setting messages
     
   To enable a set of messages, you pass a trace code to the
  <b>MKSetTrace()</b> function.  You can enable more than one set with a
  single function call by bitwise-or'ing the codes.   Clearing a trace is
  done similarly, by passing codes to <b>MKClearTrace()</b>.  The
  <b>MKIsTraced()</b> function returns YES or NO as the argument code is
  or isn't currently traced.  These functions should only be used while
  you're debugging and fine-tuning your application.  
     
   You should note that the codes given above are <b>#define</b>'d as
  their corresponding values and so can be used only when you call one of
  these functions within an application - they can't be used in a symbolic
  debugger such as <b>gdb</b>.  For this reason, the integer values
  themselves are also given; you must use the integer values to enable and
  disable a set of trace messages from within a debugger.  
     
   The debug flags are listed below with some of the possible messages
  you may see when using them.   MKNote that not all possible messages are
  included.
   
   <b>MK_TRACEORCHALLOC</b>
   The Orchestra allocation messages inform you of DSP resource
  allocation.  The most important of these have to do with MKSynthPatch,
  MKUnitGenerator, and Synth Data allocation.  When a MKSynthPatch is
  allocated, one of the following messages is printed:
     
  <tt>"allocSynthPatch returns <i>MKSynthPatchClass_SynthPatchId</i></tt>"
  <tt>"allocSynthPatch building <i>MKSynthPatchClass_SynthPatchId</i>..."</tt>
  <tt>"allocSynthPatch can't allocate <i>MKSynthPatchClass</i>"</tt>
     
   The first of these signifies that an appropriate MKSynthPatch object
  was found.  The second means that a new object was created.  The third
  denotes an inability to construct the requested object because of
  insufficient DSP resources.  As a MKSynthPatch's MKUnitGenerators are
  connected, the following message is printed:
   
   	<tt>"allocSynthPatch connectsContents of <i>MKSynthPatchClass_SynthPatchId</i></tt>"
   
   When a MKSynthPatch is deallocated and when it's freed, respectively,
  the following are printed:
   
   	<tt>"Returning <i>MKSynthPatchClass_SynthPatchId</i> to avail
  pool."</tt>
   <tt>	"Freeing <i>MKSynthPatchClass_SynthPatchId</i>"</tt>
     
   A MKUnitGenerator can be allocated without reference to other
  MKUnitGenerators, or it can be positioned before, after, or between
  other objects.  Examples:
   
   <tt>"allocUnitGenerator looking for a <i>UGClass</i>."</tt>
   <tt>	"allocUnitGenerator looking for a <i>UGClass</i> before
  <i>UGClass_UGid</i>"</tt>
   <tt>	"allocUnitGenerator looking for a <i>UGClass</i> after
  <i>UGClass_UGid</i>"</tt>
   <tt>	"allocUnitGenerator looking for a <i>UGClass</i> after
  <i>UGClass_UGid</i></tt>
   <tt>		and before <i>UGClass_UGid</i>"</tt>
   
   If a new MKUnitGenerator is built, the addresses (relocation or
  &ldquo;Reloc&rdquo;) and sizes (resources or &ldquo;Reso&rdquo;) of the
  allocated DSP resources are given:
   
   	<tt>"Reloc: pLoop <i>address</i>, xArg <i>address</i>, yArg
  <i>address</i>, lArg <i>address</i>,</tt>
   <tt>		xData <i>address</i>, yData <i>address</i>, pSubr
  <i>address</i>"</tt>
   <tt>	"Reso: pLoop <i>size</i>, xArg <i>size</i>, yArg <i>size</i>,
  lArg <i>size</i>, xData <i>size</i>,</tt>
   <tt>		yData <i>size</i>, pSubr <i>size</i>, time <i>orchestraLoopDuration</i>"</tt>
   
   As the MKUnitGenerator search (or allocation) succeeds or fails, one
  of the following is printed:
   
   "<tt>allocUnitGenerator returns</tt> <tt><i>UGClass_UGid</i></tt>"
   <tt>"Allocation failure: Can't allocate before specified ug."</tt>
   <tt>	"Allocation failure. DSP error."</tt>
   <tt>	"Allocation failure. Not enough computeTime."</tt>
   <tt>	"Allocation failure. Not enough <i>memorySegment</i>
  memory."</tt>
   
   Allocating a SynthData generates the first and then either the second
  or third of these messages:
   
   	<tt>"allocSynthData: looking in segment <i>memorySegment</i> for
  size <i>size</i>."</tt>
   <tt>	"allocSynthData returns <i>memorySegment</i> address of length
  <i>size</i>."</tt>
   <tt>	"Allocation failure: No more offchip data memory."</tt>
     
   When you install shared data, the following is printed: 
     
   	"<tt>Installing shared data <i>keyObjectName</i> in segment
  <i>memorySegment</i>.</tt>"
   
   During allocation of MKUnitGenerators and SynthDatas, existing
  resources might be compacted.  Compaction can cause free
  MKUnitGenerators and unreferenced shared data to be garbage collected,
  and active MKUnitGenerators to be relocated:
   
   	<tt>"Compacting stack."</tt>
   <tt>	"Copying arguments."</tt>
   <tt>	"Copying p memory."</tt>
   <tt>	"Garbage collecting freed unit generator UGClass_UGid"</tt>
     <tt>	"Moving <i>UGClass_UGid</i>."</tt>
   <tt>	"NewReloc: pLoop <i>address</i>, xArg <i>address</i>, yArg
  <i>address</i>, lArg <i>address</i>."</tt>
   <tt>	"Garbage collecting unreferenced shared data."</tt>
     <tt>	"No unreferenced shared data found."</tt>
   
   
   <b>MK_TRACEDSP</b>
   The DSP-trace messages give you details of how the DSP is being used.
   For example, when a MKUnitGenerator is allocated, the following message
  is printed among the search-build-return messages given above:
     
   	<tt>"Loading <i>UGClass_UGid</i> as UG <i>ugNum</i>."</tt>
     
   Unit Generators are given integer numbers for debugging purposes. 
  These numbers simply count up.  Numbers are not recycled.   Thus, an
  example of an actual "Loading..." message would be:
   
   	<tt>"Loading Out1aUGx_0x43100 as UG3."</tt>
   
   The most important of the DSP-trace messages reflect the setting of a
  MKUnitGenerator's memory arguments.  A memory argument takes either an
  address value or a data value.  When you set an address-valued argument,
  the following is printed:
   
   	<tt>"Setting <i>argName</i> of <i>UGugNum_Class</i> to <i>memSegment
  memNum</i> (0x<i>address</i>)."</tt>
   
   <i>argName</i> is the argument name in the source DSP (.asm) file.  
     
   A data-valued arguments is either a 24-bit or 48-bit word; separate
  functions (and cover methods) are defined for setting the two sizes of
  arguments.  The following messages are printed as the
  &ldquo;correct&rdquo; function is used to set an argument's value:
     
   <tt>	"Setting <i>argName</i> of <i>UGugNum_Class</i> to datum
  <i>value</i>."</tt>
   <tt>	"Setting <i>argName</i> of <i>UGugNum_Class</i> to long:</tt> 
     <tt>		<i>hi wd value</i> and <i>low wd value</i>."</tt>
     
   
   A 24-bit argument that's set with the long-setting function and vice
  versa produce these messages, respectively:
   
   <tt>	"Setting (L-just, 0-filled) <i>argName</i> of
  <i>UGugNum_Class</i> to datum <i>value</i>."</tt>
   <tt>	"Setting <i>argName</i> of <i>UGugNum_Class</i> to:
  <i>value</i>"</tt>
   
   If an argument is declared as optimizable, the following is printed
  when the optimization obtains:
   
   	"<tt>Optimizing away poke of <i>argName</i> of <i>UGugNum_Class</i>."</tt>
   
   SynthData allocation doesn't actually involve the DSP; the address of
  the memory that will be allocated on the DSP is computed, but the state
  of the DSP itself doesn't change until data is loaded into the
  SynthData:
   
   	<tt>"Loading array into <i>memorySegment</i> <i>memNum</i>
  [<i>lowAddr-highAddr</i>]."</tt>
   <tt>	"Loading constant value into <i>memorySegement</i> <i>memNum</i>
  [<i>lowAddr-highAddr</i>]."</tt>
   
   Here <i>memNum</i> is an integer assigned for debugging purposes. 
  <i>memorySegment</i> if one of xData, yData, xPatch or yPatch.  When an
  array is loaded, the loaded values are printed if <b>MK_DSPTRACEARRAYS</b> has been enabled.  Example:
   
   	<tt>"Loading array into <i>xPatch</i> <i>4</i> [<i>0x412-0x418</i>]."</tt>
   
   Clearing a SynthData's memory produces the following:
     
   <tt>	"Clearing <i>memorySegment</i> <i>memNum</i>
  [<i>lowAddr-highAddr</i>]."</tt>
   
   DSP manipulations that are performed as an atomic unit are bracketed
  by the messages:
   
   	<tt>"&lt;&lt;&lt; Begin orchestra atomic unit "</tt>
     <tt>	"end orchestra atomic unit.&gt;&gt;&gt; "</tt>
     
   
   <b>MK_TRACESYNTHINS</b>
   The SynthInstrument messages are printed when a SynthInstrument
  object receives MKNotes, and as it finds or creates MKSynthPatches to
  realize these MKNotes.  
   
   If a received MKNote's note tag is active or inactive, or if its note
  type is mute, the following are printed, respectively:
     
   <tt>	"SynthInstrument receives note for active notetag stream
  <i>noteTag</i></tt> 
   <tt>		at time <i>time</i>."</tt>
   <tt>	"SynthInstrument receives note for new notetag stream
  <i>noteTag</i></tt> 
   <tt>		at time <i>time</i>."</tt>
   <tt>	"SynthInstrument receives mute MKNote at time <i>time</i>."</tt>
     
   MKSynthPatch allocation is noted <i>only</i> if the SynthInstrument
  is in auto-allocation mode:
   
   <tt>	"SynthInstrument creates patch <i>synthPatchId</i> at time
  <i>time</i></tt> 
   <tt>		for tag <i>noteTag</i>."</tt>
   
   However, MKSynthPatch reuse and preemption produce the following
  messages, respectively, regardless of the SynthInstrument's allocation
  mode:
   
    <tt>	"SynthInstrument uses patch <i>synthPatchId</i> at time
  <i>time</i></tt> 
   <tt>		for tag <i>noteTag</i>."</tt>
   <tt>	"SynthInstrument preempts patch <i>synthPatchId</i> at time
  <i>time</i></tt> 
   <tt>		for tag <i>noteTag</i>."</tt>
   
   If a MKSynthPatch of the correct PatchTemplate isn't found and can't
  be allocated, an alternative is used; barring that, the SynthInstrument
  omits the MKNote:
   
   <tt>	"No patch of requested template was available. </tt>
     <tt>		Using alternative template."</tt>
   <tt>	"SynthInstrument omits note at time <i>time</i> for tag
  <i>noteTag</i>."</tt>
   
   
   <b>MK_TRACEPREEMPT</b>
   These are a subset of the SynthInstrument messages that deal with
  MKSynthPatch preemption and MKNote omission:
   
   <tt>	"SynthInstrument preempts patch <i>synthPatchId</i> at time
  <i>time</i></tt> 
   <tt>		for tag noteTag."</tt>
   <tt>	"SynthInstrument omits note at time <i>time</i> for tag
  <i>noteTag</i>.</tt>
   
   
   <b>MK_TRACEMIDI</b>
   The following are printed as ill-formed MKNote objects are converted
  to MIDI messages: 
   
   <tt>	"MKNoteOn missing a noteTag at time <i>time</i>"</tt>
     <tt>	"MKNoteOff missing a note tag at time <i>time</i>"</tt>
     <tt>	"MKNoteOff for noteTag which is already off at time
  <i>time</i>"</tt>
   <tt>	&ldquo;PolyKeyPressure with invalid noteTag or missing keyNum:
  time <i>time</i>;"</tt>
   
   
   <b>MK_TRACESYNTHPATCH </b>
   This referes to MKSynthPatch Library messages.  When debugging
  MKSynthPatches, you may also want to turn on TRACEUNITGENERATOR.
     
   <b>MK_TRACEUNITGENERATOR</b>
   This refers to MKUnitGenerator library messages.  f the sine ROM,
  which resides in Y memory, is requested by a MKUnitGenerator's X-space
  memory argument, the following appears:
   
   <tt>	"X-space oscgaf cannot use sine ROM at time</tt>
  <tt><i>time</i>."</tt> 
   
   If insufficient DSP memory is available to load a WaveTable of the
  requested length, the following is printed:
   
   <tt>	"Insufficient wavetable memory at time <i>time</i>.</tt>  
     <tt>		Using smaller table length <i>newLength</i>."</tt>
     
   <b>MK_TRACEPARS</b>
   By tracing MK_TRACEPARS, you're informed when an application-defined
  parameter is created:
   
   <tt>	"Adding new parameter <i>parameterName</i>"</tt>
     
   
   <b>MK_TRACECONDUCTOR</b>
   By tracing MK_TRACECONDUCTOR, a message giving the time in seconds is
  printed whenever time advances:
   
   <tt>	"t 4.1"</tt>
  @param  traceCode is an int.
  @return Return the value of the new (cumulative) trace code. 
*/
extern unsigned MKSetTrace(int traceCode);

/*!
  @brief Trouble-shoot the MusicKit. Turns off specified trace bit.

  To aid in debugging, the MusicKit is peppered with activity-tracing
  messages that print to <b>stderr</b> if but asked.The trace messages are
  divided into eight categories, represented by the following codes:
     
   <b>	Code	Value	Meaning</b>
   	MK_TRACEORCHALLOC	1	DSP resource allocation
   	MK_TRACEPARS	2	Application-defined parameters
   	MK_TRACEDSP	4	DSP manipulation
   	MK_TRACEMIDI	8	MIDI manipulation
   	MK_TRACEPREEMPT	16	MKSynthPatch preemption
   	MK_TRACESYNTHINS	32	SynthInstrument mechanations
     	MK_TRACESYNTHPATCH	64	MKSynthPatch library messages
     	MK_TRACEUNITGENERATOR	128	MKUnitGenerator library messages
     	MK_TRACECONDUCTOR	256	Conductor time setting messages
     	MK_TRACEDSPARRAYS	512	DSP array-setting messages
     
   To enable a set of messages, you pass a trace code to the
  <b>MKSetTrace()</b> function.  You can enable more than one set with a
  single function call by bitwise-or'ing the codes.   Clearing a trace is
  done similarly, by passing codes to <b>MKClearTrace()</b>.  The
  <b>MKIsTraced()</b> function returns YES or NO as the argument code is
  or isn't currently traced.  These functions should only be used while
  you're debugging and fine-tuning your application.  
     
  @param  traceCode is an int.
  @return Return the value of the new (cumulative) trace code. 
  @see MKSetTrace().
*/
extern unsigned MKClearTrace(int traceCode);

/*!
  @brief Trouble-shoot the Music Kit. Returns whether specified trace bit is on.

  To aid in debugging, the Music Kit is peppered with activity-tracing
  messages that print to <b>stderr</b> if but asked.The trace messages are
  divided into eight categories, represented by the following codes:
     
   <b>	Code	Value	Meaning</b>
   	MK_TRACEORCHALLOC	1	DSP resource allocation
   	MK_TRACEPARS	2	Application-defined parameters
   	MK_TRACEDSP	4	DSP manipulation
   	MK_TRACEMIDI	8	MIDI manipulation
   	MK_TRACEPREEMPT	16	MKSynthPatch preemption
   	MK_TRACESYNTHINS	32	SynthInstrument mechanations
     	MK_TRACESYNTHPATCH	64	MKSynthPatch library messages
     	MK_TRACEUNITGENERATOR	128	MKUnitGenerator library messages
     	MK_TRACECONDUCTOR	256	Conductor time setting messages
     	MK_TRACEDSPARRAYS	512	DSP array-setting messages
     
   To enable a set of messages, you pass a trace code to the
  <b>MKSetTrace()</b> function.  You can enable more than one set with a
  single function call by bitwise-or'ing the codes.   Clearing a trace is
  done similarly, by passing codes to <b>MKClearTrace()</b>.  The
  <b>MKIsTraced()</b> function returns YES or NO as the argument code is
  or isn't currently traced.  These functions should only be used while
  you're debugging and fine-tuning your application.  

  @param  traceCode is an int.
  @return Returns a BOOL.
  @see MKSetTrace().
*/
extern BOOL MKIsTraced(int traceCode);

/*!
  @brief Set the scorefile error threshhold, the number of parser errors to abort on.

  As a scorefile is read into an application, errors sometimes occur: 
  Time tags may be out of order; undeclared or mistyped names may pop up
  in the middle of the file.  The MusicKit keeps a count of these errors
  for each file it reads.  If the error count for a particular file
  exceeds the threshhold set as the <i>threshholdCount</i> argument to
  this function, the scorefile parsing is aborted and the file is closed
  (if the MusicKit opened it itself).  The default limit is ten
  errors.
  @param  threshholdCount is an int. To abort on the first error, 
  pass 1 as the argument. To never abort, pass MAXINT as the argument.
*/
extern void MKSetScorefileParseErrorAbort(int threshholdCount);

/*!
  @brief Handle Music Kit errors

  These functions define the Music Kit's error handling mechanism. 
  <b>MKError()</b> is used to signal an error.  It calls the current Music
  Kit error function, set through <b>MKSetErrorProc()</b>, to which it
  passes the single argument <i>msg</i>.  If the user hasn't declared an
  error function, then <i>msg</i> is written to the Music Kit error
  stream, as set through <b>MKSetErrorStream()</b>.  The default error
  stream is open to <b>stderr</b>. <b>MKErrorStream()</b> returns a
  pointer to the current Music Kit error stream.  Note that you
  <i>shouldn't</i> use <b>stderr</b> as the error stream if you're running
  a separate-threaded performance.
   
   A number of error codes represented by integer constants are provided
  by the Music Kit and listed in <b>&lt;MusicKit/errors.h&gt;</b>.  If the
  Music Kit itself generates an error, the global system variable
  <b>errno</b> is set to one of these error codes.  If you call
  <b>MKError()</b> from your application, <b>errno</b> isn't set. 
  
  @param errProc is a pointer to a function taking an NSString instance.
*/
 /* Due to the requirements of real-time The Music Kit uses a different 
    mechanism from that of the Application Kit to do error handling. The 
    following functions impelment that mechanism. 

    Note that it is not guaranteed to be safe to NX_RAISE an error in any 
    performance-oriented class. 
   */
extern void MKSetErrorProc(void (*errProc)(NSString *msg));
    /* Sets proc to be used when MKError() and MKErrorCode() are called. 
       If errProc is NULL, uses the default error proc, which writes to the 
       Music Kit error NSMutableData (see MKSetErrorStream()). 
       errProc takes one string argument. 
       When the *errProc is called in response to a Music Kit error, errno is 
       set to the MKErrno corresponding to the error. If *errProc is invoked in
       response to an application-defined error (see MKError), errno is not
       set; it's up to the application to set it, if desired. 
       */


/*!
  @brief Handle Music Kit errors

  These functions define the Music Kit's error handling mechanism. 
  <b>MKError()</b> is used to signal an error.  It calls the current Music
  Kit error function, set through <b>MKSetErrorProc()</b>, to which it
  passes the single argument <i>msg</i>.  If the user hasn't declared an
  error function, then <i>msg</i> is written to the Music Kit error
  stream, as set through <b>MKSetErrorStream()</b>.  The default error
  stream is open to<b> stderr</b>.<b>  MKErrorStream()</b> returns a
  pointer to the current Music Kit error stream.  MKNote that you
  <i>shouldn't</i> use <b>stderr</b> as the error stream if you're running
  a separate-threaded performance.
   
   A number of error codes represented by integer constants are provided
  by the Music Kit and listed in <b>&lt;MusicKit/errors.h&gt;</b>.  If the
  Music Kit itself generates an error, the global system variable
  <b>errno</b> is set to one of these error codes.  If you call
  <b>MKError()</b> from your application, <b>errno</b> isn't set. 
  
  @param  msg is an NSString instance.
  @return Returns an id.
*/
extern void MKError(NSString *msg);
    /* Calls the user's error proc (set with MKSetErrorProc), if any, with 
       one argument, the msg. Otherwise, writes the message on the Music
       Kit error stream. (See MKSetErrorStream) Returns nil.
       */

/*!
  @brief Handle Music Kit errors

  These functions define the Music Kit's error handling mechanism. 
  <b>MKError()</b> is used to signal an error.  It calls the current Music
  Kit error function, set through <b>MKSetErrorProc()</b>, to which it
  passes the single argument <i>msg</i>.  If the user hasn't declared an
  error function, then <i>msg</i> is written to the Music Kit error
  stream, as set through <b>MKSetErrorStream()</b>.  The default error
  stream is open to<b> stderr</b>.<b>  MKErrorStream()</b> returns a
  pointer to the current Music Kit error stream.  MKNote that you
  <i>shouldn't</i> use <b>stderr</b> as the error stream if you're running
  a separate-threaded performance.
   
   A number of error codes represented by integer constants are provided
  by the Music Kit and listed in <b>&lt;MusicKit/errors.h&gt;</b>.  If the
  Music Kit itself generates an error, the global system variable
  <b>errno</b> is set to one of these error codes.  If you call
  <b>MKError()</b> from your application, <b>errno</b> isn't set. 
  
  @param  aStream is a NSMutableData instance.
*/
extern void MKSetErrorStream(NSMutableData *aStream);
    /* Sets the Music Kit error stream. 
       nil means stderr. The Music Kit initialization sets the error 
       stream to stderr. Note that during a multi-threaded Music Kit 
       performance, errors invoked from the Music Kit thread are not sent
       to the error stream. Use MKSetErrorProc to see them. */

extern NSMutableData *MKErrorStream(void);
    /* Returns the Music Kit error stream. This is, by default, stderr.  */

/* Errors generated by the Music Kit. You don't normally generate these 
 * yourself. */

#define MK_ERRORBASE 4000    /* 1000 error codes for us start here */

typedef enum _MKErrno {
    MK_musicKitErr = MK_ERRORBASE,
    MK_machErr,
    /* Representation errors */
    MK_cantOpenFileErr ,
    MK_cantCloseFileErr,
    MK_outOfOrderErr,           /* Scorefile parsing/writing error */
    MK_samplesNoResampleErr,
    MK_noMoreTagsErr,
    MK_notScorefileObjectTypeErr,
    /* Synthesis errors */
    MK_orchBadFreeErr,
    MK_synthDataCantClearErr,   /* Synthdata errors */ 
    MK_synthDataLoadErr,
    MK_synthDataReadonlyErr,
    MK_synthInsOmitNoteErr,     /* MKSynthInstrument errors */
    MK_synthInsNoClass,
    MK_ugLoadErr,               /* MKUnitGenerator errors. */
    MK_ugBadArgErr,
    MK_ugBadAddrPokeErr,
    MK_ugBadDatumPokeErr,
    MK_ugOrchMismatchErr,
    MK_ugArgSpaceMismatchErr,
    MK_ugNonAddrErr,
    MK_ugNonDatumErr,

    /* Scorefile errors. */
    MK_sfBadExprErr,     /* Illegal constructs */
    MK_sfBadDefineErr,
    MK_sfBadParValErr,
    MK_sfNoNestDefineErr,

    MK_sfBadDeclErr,     /* Missing constructs */
    MK_sfMissingStringErr,
    MK_sfBadNoteTypeErr,
    MK_sfBadNoteTagErr,
    MK_sfMissingBackslashErr,
    MK_sfMissingSemicolonErr,
    MK_sfUndeclaredErr,
    MK_sfBadAssignErr,
    MK_sfBadIncludeErr,
    MK_sfBadParamErr,
    MK_sfNumberErr,
    MK_sfStringErr,
    MK_sfGlobalErr,
    MK_sfCantFindGlobalErr,
    
    MK_sfMulDefErr, /* Duplicate constructs */
    MK_sfDuplicateDeclErr,

    MK_sfNotHereErr,
    MK_sfWrongTypeDeclErr,
    MK_sfBadHeaderStmtErr,
    MK_sfBadStmtErr,

    MK_sfBadInitErr,
    MK_sfNoTuneErr,
    MK_sfNoIncludeErr,
    MK_sfCantFindFileErr,
    MK_sfCantWriteErr,
    MK_sfOutOfOrderErr,
    MK_sfUnmatchedCommentErr,
    MK_sfInactiveNoteTagErr,
    MK_sfCantFindClass,
    MK_sfBoundsErr, 
    MK_sfTypeConversionErr,
    MK_sfReadOnlyErr,
    MK_sfArithErr,
    MK_sfNonScorefileErr,
    MK_sfTooManyErrorsErr,
    
    /* Unit generator library errors. */
    MK_ugsNotSetRunErr,
    MK_ugsPowerOf2Err,
    MK_ugsNotSetGetErr,

    /* Synth patch library errors. */
    MK_spsCantGetMemoryErr,
    MK_spsSineROMSubstitutionErr,
    MK_spsInvalidPartialsDatabaseKeywordErr, 
    MK_spsOutOfRangeErr,
    MK_spsCantGetUGErr,

    /* Errors added in Release 3.0 */
    MK_synthDataCantReadDSPErr,
    MK_dspMonitorVersionError,
    /* End marker */
    MK_highestErr,
    /* Reserved from here until MK_maxErr */
    MK_maxErr = (MK_ERRORBASE + 1000)
} MKErrno;

#define MK_sfNonAsciiErr MK_sfNonScorefileErr /* For backwards compatibility */


/* The remaining functions are the Music Kit's own internal error handling
 * functions. Normally, you don't call these functions.  However, if you 
 * need to raise an error with a Music Kit error code, you call MKErrorCode().  
 */

extern void MKErrorCode(int errorCode, ...); 
/* Calling sequence like printf, but first arg is musickit error code instead
 * of formating info, the second arg is a formating NSString derived from the string in
 * /Local/Library/MusicKit/Languages/<language>.lproj/Localized.strings. 
 *
 * It's the caller's responsibility that the expansion of the arguments 
 * using sprintf doesn't exceed the size of the error buffer (_MK_ERRLEN). 
 * Fashions the error message and sends it to MKError(). 
 */

#define _MK_ERRLEN 2048

/* 
 * These functions are for accessing Music Kit's localized strings. 
 */ 
extern NSBundle *_MKErrorBundle(void); 
/* 
 * Music Kit bundle for selected language in 
 * /usr/local/lib/MusicKit/Languages, if found.  
 */
extern NSString *_MKErrorStringFile(void); 
/* Returns "Localized" if _MKErrorBundle() returns non-null */

#endif
