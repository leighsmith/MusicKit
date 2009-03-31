/*
  $Id$
  Defined In: The MusicKit

  Description:
    This file has trace codes as well as error codes used by the MusicKit.

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2005 The MusicKit Project.
*/
#ifndef __MK_errors_H___
#define __MK_errors_H___

#import <Foundation/Foundation.h>

/*!
  @file errors.h
 */

/*!
  @defgroup Tracing Trouble-shoot the MusicKit.
  */
/*!
  @brief Trace Constants
 
  To enable a set of messages, you pass a trace code to the
  <b>MKSetTrace()</b> function.  You can enable more than one set with a
  single function call by bitwise-or'ing the codes.   Clearing a trace is
  done similarly, by passing codes to <b>MKClearTrace()</b>.  The
  <b>MKIsTraced()</b> function returns YES or NO as the argument code is
  or isn't currently traced.  These functions should only be used while
  you're debugging and fine-tuning your application.  
 
  For more information on the constants and their meaning, see
  the trace function documentation.
 */
/*! DSP (MKOrchestra) resource allocation */
#define MK_TRACEORCHALLOC 1
/*! Application-defined parameters, when first encountered. */
#define MK_TRACEPARS 2
/*! DSP manipulation */
#define MK_TRACEDSP 4
/*! MIDI in/out/time warnings */
#define MK_TRACEMIDI 8
/*! MKSynthPatch preemption */
#define MK_TRACEPREEMPT 16
/*! MKSynthInstrument mechanations */
#define MK_TRACESYNTHINS  32
/*! MKSynthPatch library messages */
#define MK_TRACESYNTHPATCH 64
/*! MKUnitGenerator library messages */
#define MK_TRACEUNITGENERATOR 128
/*! MKConductor time setting messages */
#define MK_TRACECONDUCTOR 256
/*! DSP array-setting messages */
#define MK_TRACEDSPARRAYS 512

/*!
  @brief Turns on specified trace bit.

  To aid in debugging, the MusicKit is peppered with activity-tracing
  messages that print to <b>stderr</b> if but asked. The trace messages are
  divided into eight categories, represented by the following codes:
     
 <table border=1 cellspacing=2 cellpadding=0 align=center>
 <tr>
 <td align=left>Code</td>
 <td align=left>Value</td>
 <td align=left>Meaning</td>
 </tr>
 <tr>
 <td align=left>MK_TRACEORCHALLOC</td>
 <td align=right>1</td>
 <td align=left>DSP resource allocation</td>
 </tr>
 <tr>
 <td align=left>MK_TRACEPARS</td>
 <td align=right>2</td>
 <td align=left>Application-defined parameters</td>
 </tr>
 <tr>
 <td align=left>MK_TRACEDSP</td>
 <td align=right>4</td>
 <td align=left>DSP manipulation</td>
 </tr>
 <tr>
 <td align=left>MK_TRACEMIDI</td>
 <td align=right>8</td>
 <td align=left>MIDI manipulation</td>
 </tr>
 <tr>
 <td align=left>MK_TRACEPREEMPT</td>
 <td align=right>16</td>
 <td align=left>MKSynthPatch preemption</td>
 </tr>
 <tr>
 <td align=left>MK_TRACESYNTHINS</td>
 <td align=right>32</td>
 <td align=left>MKSynthInstrument mechanations</td>
 </tr>
 <tr>
 <td align=left>MK_TRACESYNTHPATCH</td>
 <td align=right>64</td>
 <td align=left>MKSynthPatch library messages</td>
 </tr>
 <tr>
 <td align=left>MK_TRACEUNITGENERATOR</td>
 <td align=right>128</td>
 <td align=left>MKUnitGenerator library messages</td>
 </tr>
 <tr>
 <td align=left>MK_TRACECONDUCTOR</td>
 <td align=right>256</td>
 <td align=left>Conductor time setting messages</td>
 </tr>
 <tr>
 <td align=left>MK_TRACEDSPARRAYS</td>
 <td align=right>512</td>
 <td align=left>DSP array-setting messages</td>
 </tr>
 </table>
 
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
     
  <ul>
  <li><tt>"allocSynthPatch returns <i>MKSynthPatchClass_SynthPatchId</i>"</tt>
  <li><tt>"allocSynthPatch building <i>MKSynthPatchClass_SynthPatchId</i>..."</tt>
  <li><tt>"allocSynthPatch can't allocate <i>MKSynthPatchClass</i>"</tt>
  </ul>    
 
   The first of these signifies that an appropriate MKSynthPatch object
  was found.  The second means that a new object was created.  The third
  denotes an inability to construct the requested object because of
  insufficient DSP resources.  As a MKSynthPatch's MKUnitGenerators are
  connected, the following message is printed:
   
    <tt>"allocSynthPatch connectsContents of <i>MKSynthPatchClass_SynthPatchId</i>"</tt>
   
   When a MKSynthPatch is deallocated and when it's freed, respectively,
  the following are printed:
   
    <ul>
    <li><tt>"Returning <i>MKSynthPatchClass_SynthPatchId</i> to avail pool."</tt>
    <li><tt>"Freeing <i>MKSynthPatchClass_SynthPatchId</i>"</tt>
    </ul>    
     
   A MKUnitGenerator can be allocated without reference to other
  MKUnitGenerators, or it can be positioned before, after, or between
  other objects.  Examples:
   
 <ul>
   <li><tt>"allocUnitGenerator looking for a <i>UGClass</i>."</tt>
   <li><tt>"allocUnitGenerator looking for a <i>UGClass</i> before <i>UGClass_UGid</i>"</tt>
   <li><tt>"allocUnitGenerator looking for a <i>UGClass</i> after <i>UGClass_UGid</i>"</tt>
   <li><tt>"allocUnitGenerator looking for a <i>UGClass</i> after <i>UGClass_UGid</i> and before <i>UGClass_UGid</i>"</tt>
 </ul>    
   
   If a new MKUnitGenerator is built, the addresses (relocation or
  &ldquo;Reloc&rdquo;) and sizes (resources or &ldquo;Reso&rdquo;) of the
  allocated DSP resources are given:
   
 <ul>
  <li><tt>"Reloc: pLoop <i>address</i>, xArg <i>address</i>, yArg <i>address</i>, lArg <i>address</i>,</tt>
  <li><tt>		xData <i>address</i>, yData <i>address</i>, pSubr <i>address</i>"</tt>
  <li><tt>"Reso: pLoop <i>size</i>, xArg <i>size</i>, yArg <i>size</i>, lArg <i>size</i>, xData <i>size</i>,</tt>
  <li><tt>		yData <i>size</i>, pSubr <i>size</i>, time <i>orchestraLoopDuration</i>"</tt>
 </ul>    
   
   As the MKUnitGenerator search (or allocation) succeeds or fails, one of the following is printed:
   
 <ul>
   <li><tt>"allocUnitGenerator returns <i>UGClass_UGid</i>"</tt>
   <li><tt>"Allocation failure: Can't allocate before specified ug."</tt>
   <li><tt>"Allocation failure. DSP error."</tt>
   <li><tt>"Allocation failure. Not enough computeTime."</tt>
   <li><tt>"Allocation failure. Not enough <i>memorySegment</i> memory."</tt>
 </ul>    
   
   Allocating a MKSynthData generates the first and then either the second
  or third of these messages:
   
 <ul>
  <li><tt>"allocSynthData: looking in segment <i>memorySegment</i> for size <i>size</i>."</tt>
  <li><tt>"allocSynthData returns <i>memorySegment</i> address of length <i>size</i>."</tt>
  <li><tt>"Allocation failure: No more offchip data memory."</tt>
 </ul>    
     
   When you install shared data, the following is printed: 
     
   <tt>"Installing shared data <i>keyObjectName</i> in segment <i>memorySegment</i>."</tt>
   
  During allocation of MKUnitGenerators and MKSynthDatas, existing
  resources might be compacted.  Compaction can cause free
  MKUnitGenerators and unreferenced shared data to be garbage collected,
  and active MKUnitGenerators to be relocated:
   
 <ul>
   <li><tt>"Compacting stack."</tt>
   <li><tt>"Copying arguments."</tt>
   <li><tt>"Copying p memory."</tt>
   <li><tt>"Garbage collecting freed unit generator UGClass_UGid"</tt>
   <li><tt>"Moving <i>UGClass_UGid</i>."</tt>
   <li><tt>"NewReloc: pLoop <i>address</i>, xArg <i>address</i>, yArg <i>address</i>, lArg <i>address</i>."</tt>
   <li><tt>"Garbage collecting unreferenced shared data."</tt>
   <li><tt>"No unreferenced shared data found."</tt>
 </ul>    
   
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
   
   <tt>"Setting <i>argName</i> of <i>UGugNum_Class</i> to <i>memSegment memNum</i> (0x<i>address</i>)."</tt>
   
   <i>argName</i> is the argument name in the source DSP (.asm) file.  
     
  A data-valued arguments is either a 24-bit or 48-bit word; separate
  functions (and cover methods) are defined for setting the two sizes of
  arguments.  The following messages are printed as the
  &ldquo;correct&rdquo; function is used to set an argument's value:
     
 <ul>
   <li><tt>"Setting <i>argName</i> of <i>UGugNum_Class</i> to datum <i>value</i>."</tt>
   <li><tt>"Setting <i>argName</i> of <i>UGugNum_Class</i> to long: <i>hi wd value</i> and <i>low wd value</i>."</tt>
 </ul>    
   
   A 24-bit argument that's set with the long-setting function and vice
  versa produce these messages, respectively:
   
 <ul>
   <li><tt>"Setting (L-just, 0-filled) <i>argName</i> of <i>UGugNum_Class</i> to datum <i>value</i>."</tt>
   <li><tt>"Setting <i>argName</i> of <i>UGugNum_Class</i> to: <i>value</i>"</tt>
 </ul>    
   
   If an argument is declared as optimizable, the following is printed
  when the optimization obtains:
   
   <tt>"Optimizing away poke of <i>argName</i> of <i>UGugNum_Class</i>."</tt>
   
   MKSynthData allocation doesn't actually involve the DSP; the address of
  the memory that will be allocated on the DSP is computed, but the state
  of the DSP itself doesn't change until data is loaded into the
  MKSynthData:
   
 <ul>
  <li><tt>"Loading array into <i>memorySegment</i> <i>memNum</i> [<i>lowAddr-highAddr</i>]."</tt>
  <li><tt>"Loading constant value into <i>memorySegement</i> <i>memNum</i> [<i>lowAddr-highAddr</i>]."</tt>
 </ul>    
   
   Here <i>memNum</i> is an integer assigned for debugging purposes. 
  <i>memorySegment</i> if one of xData, yData, xPatch or yPatch.  When an
  array is loaded, the loaded values are printed if <b>MK_DSPTRACEARRAYS</b> has been enabled.  Example:
   
   <tt>"Loading array into <i>xPatch</i> <i>4</i> [<i>0x412-0x418</i>]."</tt>
   
   Clearing a SynthData's memory produces the following:
     
   <tt>"Clearing <i>memorySegment</i> <i>memNum</i> [<i>lowAddr-highAddr</i>]."</tt>
   
   DSP manipulations that are performed as an atomic unit are bracketed
  by the messages:
   
 <ul>
   <li><tt>"&lt;&lt;&lt; Begin orchestra atomic unit "</tt>
   <li><tt>"end orchestra atomic unit.&gt;&gt;&gt; "</tt>
 </ul>    
   
   <b>MK_TRACESYNTHINS</b>
 
   The MKSynthInstrument messages are printed when a MKSynthInstrument
  object receives MKNotes, and as it finds or creates MKSynthPatches to
  realize these MKNotes.  
   
   If a received MKNote's note tag is active or inactive, or if its note
  type is mute, the following are printed, respectively:
     
 <ul>
   <li><tt>"MKSynthInstrument receives note for active notetag stream <i>noteTag</i> at time <i>time</i>."</tt>
   <li><tt>"MKSynthInstrument receives note for new notetag stream <i>noteTag</i> at time <i>time</i>."</tt>
   <li><tt>"MKSynthInstrument receives mute MKNote at time <i>time</i>."</tt>
 </ul>    
     
   MKSynthPatch allocation is noted <i>only</i> if the MKSynthInstrument
  is in auto-allocation mode:
   
   <tt>"MKSynthInstrument creates patch <i>synthPatchId</i> at time <i>time</i> for tag <i>noteTag</i>."</tt>
   
   However, MKSynthPatch reuse and preemption produce the following
  messages, respectively, regardless of the MKSynthInstrument's allocation
  mode:
   
 <ul>
   <li><tt>"MKSynthInstrument uses patch <i>synthPatchId</i> at time <i>time</i> for tag <i>noteTag</i>."</tt>
   <li><tt>"MKSynthInstrument preempts patch <i>synthPatchId</i> at time <i>time</i> for tag <i>noteTag</i>."</tt>
 </ul>    
   
   If a MKSynthPatch of the correct MKPatchTemplate isn't found and can't
  be allocated, an alternative is used; barring that, the MKSynthInstrument
  omits the MKNote:
   
 <ul>
   <li><tt>"No patch of requested template was available. Using alternative template."</tt>
   <li><tt>"MKSynthInstrument omits note at time <i>time</i> for tag <i>noteTag</i>."</tt>
 </ul>    
   
   <b>MK_TRACEPREEMPT</b>
 
   These are a subset of the MKSynthInstrument messages that deal with
   MKSynthPatch preemption and MKNote omission:
   
 <ul>
   <li><tt>	"MKSynthInstrument preempts patch <i>synthPatchId</i> at time <i>time</i> for tag noteTag."</tt>
   <li><tt>	"MKSynthInstrument omits note at time <i>time</i> for tag <i>noteTag</i>.</tt>
 </ul>    
   
   <b>MK_TRACEMIDI</b>
 
   The following are printed as ill-formed MKNote objects are converted
  to MIDI messages: 
   
 <ul>
   <li><tt>"MKNoteOn missing a noteTag at time <i>time</i>"</tt>
   <li><tt>"MKNoteOff missing a note tag at time <i>time</i>"</tt>
   <li><tt>"MKNoteOff for noteTag which is already off at time <i>time</i>"</tt>
   <li><tt>"PolyKeyPressure with invalid noteTag or missing keyNum: time <i>time</i>;"</tt>
 </ul>    
   
   <b>MK_TRACESYNTHPATCH</b>
 
   This referes to MKSynthPatch Library messages.  When debugging
  MKSynthPatches, you may also want to turn on TRACEUNITGENERATOR.
     
   <b>MK_TRACEUNITGENERATOR</b>
 
   This refers to MKUnitGenerator library messages.  f the sine ROM,
  which resides in Y memory, is requested by a MKUnitGenerator's X-space
  memory argument, the following appears:
   
   <tt>"X-space oscgaf cannot use sine ROM at time <i>time</i>."</tt> 
   
   If insufficient DSP memory is available to load a WaveTable of the
  requested length, the following is printed:
   
   <tt>"Insufficient wavetable memory at time <i>time</i>. Using smaller table length <i>newLength</i>."</tt>
     
   <b>MK_TRACEPARS</b>
   By tracing MK_TRACEPARS, you're informed when an application-defined parameter is created:
   
   <tt>"Adding new parameter <i>parameterName</i>"</tt>
     
   <b>MK_TRACECONDUCTOR</b>
 
   By tracing MK_TRACECONDUCTOR, a message giving the time in seconds is
  printed whenever time advances:
   
   <tt>"t 4.1"</tt>
 
  @param  traceCode is an int.
  @return Return the value of the new (cumulative) trace code.
  @ingroup Tracing
*/
extern unsigned MKSetTrace(int traceCode);

/*!
  @brief Turns off specified trace bit.

  To aid in debugging, the MusicKit is peppered with activity-tracing
  messages that print to <b>stderr</b> if but asked.
 
  To enable a set of messages, you pass a trace code to the
  <b>MKSetTrace()</b> function.  You can enable more than one set with a
  single function call by bitwise-or'ing the codes.   Clearing a trace is
  done similarly, by passing codes to <b>MKClearTrace()</b>.  The
  <b>MKIsTraced()</b> function returns YES or NO as the argument code is
  or isn't currently traced.  These functions should only be used while
  you're debugging and fine-tuning your application.  
     
  @param  traceCode is an int.
  @return Return the value of the new (cumulative) trace code. 
  @see <b>MKSetTrace()</b>.
  @ingroup Tracing
*/
extern unsigned MKClearTrace(int traceCode);

/*!
  @brief Returns whether specified trace bit is on.

  To aid in debugging, the MusicKit is peppered with activity-tracing
  messages that print to <b>stderr</b> if but asked. 
 
  To enable a set of messages, you pass a trace code to the
  <b>MKSetTrace()</b> function.  You can enable more than one set with a
  single function call by bitwise-or'ing the codes.   Clearing a trace is
  done similarly, by passing codes to <b>MKClearTrace()</b>.  The
  <b>MKIsTraced()</b> function returns YES or NO as the argument code is
  or isn't currently traced.  These functions should only be used while
  you're debugging and fine-tuning your application.  

  @param  traceCode is an int.
  @return Returns a BOOL.
  @see <b>MKSetTrace()</b>.
  @ingroup Tracing
*/
extern BOOL MKIsTraced(int traceCode);

/*!
  @defgroup ErrorFns Handle MusicKit errors.
 */

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
  @ingroup ErrorFns
*/
extern void MKSetScorefileParseErrorAbort(int threshholdCount);

/*!
  @brief Sets function to be used when MKError() and MKErrorCode() are called.

  These functions define the MusicKit's error handling mechanism. 
  Due to the requirements of real-time, the MusicKit uses a different 
  mechanism from that of the Application Kit to do error handling. The 
  following functions implement that mechanism.
  <b>MKError()</b> is used to signal an error.  It calls the current Music
  Kit error function, set through <b>MKSetErrorProc()</b>, to which it
  passes the single argument <i>msg</i>.  If the user hasn't declared an
  error function, then <i>msg</i> is written to the MusicKit error
  stream, as set through <b>MKSetErrorStream()</b>.  The default error
  stream is open to <b>stderr</b>. <b>MKErrorStream()</b> returns a
  pointer to the current MusicKit error stream.  Note that you
  <i>shouldn't</i> use <b>stderr</b> as the error stream if you're running
  a separate-threaded performance.
  
  Note that it is not guaranteed to be safe to NS_RAISE an error in any 
  performance-oriented class. 
   
   A number of error codes represented by integer constants are provided
  by the MusicKit and listed in <b>&lt;MusicKit/errors.h&gt;</b>.  If the
  MusicKit itself generates an error, the global system variable
  <b>errno</b> is set to one of these error codes.  If you call
  <b>MKError()</b> from your application, <b>errno</b> isn't set. 

  If errProc is NULL, uses the default error proc, which writes to the 
  MusicKit error NSMutableData (see MKSetErrorStream()). 
  errProc takes one string argument. 
  When the *errProc is called in response to a MusicKit error, errno is 
  set to the MKErrno corresponding to the error. If *errProc is invoked in
  response to an application-defined error (see MKError), errno is not
  set; it's up to the application to set it, if desired. 

  @param errProc is a pointer to a function taking an NSString instance.
  @ingroup ErrorFns
*/
extern void MKSetErrorProc(void (*errProc)(NSString *msg));

/*!
  @brief Calls the user's error procedure (aka function, set with MKSetErrorProc), if any, with 
         one argument, the message. Otherwise, writes the message on the MusicKit error stream.

  These functions define the MusicKit's error handling mechanism. 
  <b>MKError()</b> is used to signal an error.  It calls the current Music
  Kit error function, set through <b>MKSetErrorProc()</b>, to which it
  passes the single argument <i>msg</i>.  If the user hasn't declared an
  error function, then <i>msg</i> is written to the MusicKit error
  stream, as set through <b>MKSetErrorStream()</b>.  The default error
  stream is open to<b> stderr</b>.<b>  MKErrorStream()</b> returns a
  pointer to the current MusicKit error stream.  MKNote that you
  <i>shouldn't</i> use <b>stderr</b> as the error stream if you're running
  a separate-threaded performance.
   
  A number of error codes represented by integer constants are provided
  by the MusicKit and listed in <b>&lt;MusicKit/errors.h&gt;</b>.  If the
  MusicKit itself generates an error, the global system variable
  <b>errno</b> is set to one of these error codes.  If you call
  <b>MKError()</b> from your application, <b>errno</b> isn't set. 
  
  @param  msg is an NSString instance.
  @see MKSetErrorStream.
  @ingroup ErrorFns
 */
extern void MKError(NSString *msg);

/*!
  @brief Sets the MusicKit error stream.

  These functions define the MusicKit's error handling mechanism. 
  <b>MKError()</b> is used to signal an error.  It calls the current Music
  Kit error function, set through <b>MKSetErrorProc()</b>, to which it
  passes the single argument <i>msg</i>.  If the user hasn't declared an
  error function, then <i>msg</i> is written to the MusicKit error
  stream, as set through <b>MKSetErrorStream()</b>.  The default error
  stream is open to<b> stderr</b>.<b>  MKErrorStream()</b> returns a
  pointer to the current MusicKit error stream.  MKNote that you
  <i>shouldn't</i> use <b>stderr</b> as the error stream if you're running
  a separate-threaded performance.
   
  A number of error codes represented by integer constants are provided
  by the MusicKit and listed in <b>&lt;MusicKit/errors.h&gt;</b>.  If the
  MusicKit itself generates an error, the global system variable
  <b>errno</b> is set to one of these error codes.  If you call
  <b>MKError()</b> from your application, <b>errno</b> isn't set. 

  The MusicKit initialization sets the error stream to stderr. 
  Note that during a multi-threaded MusicKit 
  performance, errors invoked from the MusicKit thread are not sent
  to the error stream. Use MKSetErrorProc to see them.
 
  @param  aStream is a NSMutableData instance. nil means stderr.
  @ingroup ErrorFns
  @see <b>MKError()</b>.
*/
extern void MKSetErrorStream(NSMutableData *aStream);

/*!
  @brief Returns the MusicKit error stream. This is, by default, stderr.
  @return Returns an NSMutableData instance.
  @see <b>MKError()</b>.
  @ingroup ErrorFns
*/
extern NSMutableData *MKErrorStream(void);

/* Errors generated by the MusicKit. You don't normally generate these 
 * yourself. */

#define MK_ERRORBASE 4000    /* 1000 error codes for us start here */

/*!
  @brief This enumeration defines the exceptions that the MusicKit can generate
  via the <b>MKErrorCode</b>() mechanism.
 
  The errors are in six categories: general errors, representation errors, synthesis errors,
  scorefile errors, MKUnitGenerator library errors and MKSynthPatch
  library errors.
 */
typedef enum _MKErrno {
    // <b>GENERAL ERRORS</b>
    /*!	Used as a way of specifying MusicKit errors not otherwise defined. */	
    MK_musicKitErr = MK_ERRORBASE,
    /*! Used for errors from the operating system. For example, the MIDI object 
        uses this error to report problems gaining access to the MIDI device. */
    MK_machErr,

    // <b>REPRESENTATION ERRORS</b>General purpose errors dealing with music representation.	
    /*! Warns that a file can't be opened.  */
    MK_cantOpenFileErr,
    /*! Warns that a file can't be closed. */
    MK_cantCloseFileErr,
    /*! Warns that notes were found in a scorefile with times out of order. */
    MK_outOfOrderErr,           /* Scorefile parsing/writing error */
    /*! Samples class: Warns that the MKSamples object cannot change the sampling 
	rate of a waveform by anything but a negative power of 2. */
    MK_samplesNoResampleErr,
    /*!	Warns that the MusicKit has run out of <i>noteTags</i>. */
    MK_noMoreTagsErr,
    /*!	Warns that a class is specified in a scorefile as a <i>scorefile object type</i>; 
        but that class does not implement the appropriate protocol to be used in that way. */
    MK_notScorefileObjectTypeErr,
    
    /* Synthesis errors */    
    /*!	MKOrchestra class: Attempt to free a MKUnitGenerator that's in use. */
    MK_orchBadFreeErr,
    /*! MKSynthData class: A DSP error occurred when trying to clear a MKSynthData. */
    MK_synthDataCantClearErr,   /* MKSynthData errors */ 
    /*!	MKSynthData class: A DSP error occurred when trying to load a MKSynthData. */
    MK_synthDataLoadErr,
    /*!	MKSynthData class: An attempt was made to set the value of a read-only MKSynthData. */
    MK_synthDataReadonlyErr,
    /*! MKSynthInstrument class: A MKNote had to be omitted. */
    MK_synthInsOmitNoteErr,     /* MKSynthInstrument errors */
    /*!	MKSynthInstrument class: No MKSynthPatch class was set. */
    MK_synthInsNoClass,
    /*! MKUnitGenerator class: A DSP error occurred when loading a unit generator. */
    MK_ugLoadErr,               /* MKUnitGenerator errors. */
    /*!	MKUnitGenerator class: A bad argument was specified.  Probably a bug in a subclass. */
    MK_ugBadArgErr,
    /*!	MKUnitGenerator class: A DSP error occurred when trying to put an address in an argument. */
    MK_ugBadAddrPokeErr,
    /*!	MKUnitGenerator class: A DSP error occurred when trying to put a datum in an argument. */
    MK_ugBadDatumPokeErr,
    /*!	MKUnitGenerator class: An attempt was made to set an argument to a MKSynthData from a different MKOrchestra. */
    MK_ugOrchMismatchErr,
    /*!	MKUnitGenerator class: The memory space of an address-valued argument does not match the MKSynthData it was given. */
    MK_ugArgSpaceMismatchErr,
    /*!	MKUnitGenerator class: An attempt was made to set a DSP unit generator argument to a datum value when that
        unit generator argument accepts only an address. */
    MK_ugNonAddrErr,
    /*!	MKUnitGenerator class: An attempt was made to set a DSP unit generator argument to an address value when
        that unit generator argument accepts only a datum. */
    MK_ugNonDatumErr,

    /* Scorefile Language Errors. */
    /*!	Illegal expression. */
    MK_sfBadExprErr,     /* Illegal constructs */
    /*! Illegal definition. */
    MK_sfBadDefineErr,
    /*! Illegal parameter value. */
    MK_sfBadParValErr,
    /*! Illegal nesting of definitions. */
    MK_sfNoNestDefineErr,

    /*! Illegal declaration. */
    MK_sfBadDeclErr,     /* Missing constructs */
    /*! Missing string where a string is required. */
    MK_sfMissingStringErr,
    /*! Illegal note type. */
    MK_sfBadNoteTypeErr,
    /*! Illegal (non-integer) note tag. */
    MK_sfBadNoteTagErr,
    /*! Missing backslash. */
    MK_sfMissingBackslashErr,
    /*! Missing semicolon. */
    MK_sfMissingSemicolonErr,
    /*! Undeclared symbol. */
    MK_sfUndeclaredErr,
    /*! Illegal assignment. */
    MK_sfBadAssignErr,
    /*! Illegal include. */
    MK_sfBadIncludeErr,
    /*! Illegal parameter. */
    MK_sfBadParamErr,
    /*! Illegal number. */
    MK_sfNumberErr,
    /*! Illegal string. */
    MK_sfStringErr,
    /*! Illegal global symbol. */
    MK_sfGlobalErr,
    /*! Undefined global symbol. */
    MK_sfCantFindGlobalErr,
    
    /*! Multiple definitions. */
    MK_sfMulDefErr, /* Duplicate constructs */
    /*! Duplicate declarations. */
    MK_sfDuplicateDeclErr,

    /*! Something may not appear where it does appear. */
    MK_sfNotHereErr,
    /*! Something is declared where it should not be   declared.. */
    MK_sfWrongTypeDeclErr,
    /*! Illegal header statement. */
    MK_sfBadHeaderStmtErr,
    /*! Illegal body statement. */
    MK_sfBadStmtErr,

    /*! Illegal initialization. */
    MK_sfBadInitErr,
    /*! Illegal argument follows the <b>tune</b> construct. */
    MK_sfNoTuneErr,
    /*! Unused. */
    MK_sfNoIncludeErr,
    /*! Can't find a file. */
    MK_sfCantFindFileErr,
    /*! Can't write a file. */
    MK_sfCantWriteErr,
    /*! Times appear out of order in a file. */
    MK_sfOutOfOrderErr,
    /*! <b>comment</b> without a matching  <b>endComment</b>. */
    MK_sfUnmatchedCommentErr,
    /*! A noteOff or noteUpdate appears for an inactive noteTag. */
    MK_sfInactiveNoteTagErr,
    /*! An Objective-C class is specified which can not be found. */
    MK_sfCantFindClass,
    /*! Lookup value is out of bounds. */
    MK_sfBoundsErr, 
    /*! Illegal type conversion. */
    MK_sfTypeConversionErr,
    /*! An attempt to set a read-only variable. */
    MK_sfReadOnlyErr,
    /*! An arithmetic error, such as divide by zero. */
    MK_sfArithErr,
    /*! An attempt to read a text file that is not a ScoreFile. */
    MK_sfNonScorefileErr,
    /*! Too many errors have occurred -- aborting. */
    MK_sfTooManyErrorsErr,
    
    /* Unit generator library errors. */
    /*! MK_ugsNotSetRunErr Indicates a memory argument that needs to be set before <b>run</b> is sent. */
    MK_ugsNotSetRunErr,
    /*!	Indicates that a MKUnitGenerator that accepts only power-of-2 length MKSynthData was passed a MKSynthData of some other length. */
    MK_ugsPowerOf2Err,
    /*! Indicates that a value was queried before a dependent value was set. */
    MK_ugsNotSetGetErr,

    /* Synth patch library errors. */
    /*! Indicates a MKSynthPatch cannot get enough DSP  memory for some purpose. */
    MK_spsCantGetMemoryErr,
    /*! Indicates a MKSynthPatch is substituting the sine ROM for the requested wavetable,
	due to a lack of DSP memory. */
    MK_spsSineROMSubstitutionErr,
    /*! Indicates an invalid keyword was passed to the MKTimbre data base. */
    MK_spsInvalidPartialsDatabaseKeywordErr, 
    /*! Indicates that a parameter is out of range. */
    MK_spsOutOfRangeErr,
    /*!	Indicates that a MKSynthPatch can't allocate an MKUnitGenerator it needs.
        This can arise, for example, if a MKSynthPatch allocates MKUnitGenerators
	outside of its basic definition (i.e. outside of the <b>patchTemplateFor:</b> method.) */
    MK_spsCantGetUGErr,

    /* Errors added in Release 3.0 */
    /*!	MKSynthData class: Problem reading MKSynthData from DSP.  */
    MK_synthDataCantReadDSPErr,
    /*!	MKOrchestra class: Mismatch between DSP monitor version and MKOrchestra version. */
    MK_dspMonitorVersionError,
    /* End marker */
    MK_highestErr,
    /* Reserved from here until MK_maxErr */
    MK_maxErr = (MK_ERRORBASE + 1000)
} MKErrno;

#define MK_sfNonAsciiErr MK_sfNonScorefileErr /* For backwards compatibility */


/* The remaining functions are the MusicKit's own internal error handling
 * functions. Normally, you don't call these functions.  However, if you 
 * need to raise an error with a MusicKit error code, you call MKErrorCode().  
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
 * These functions are for accessing MusicKit's localized strings. 
 */ 
extern NSBundle *_MKErrorBundle(void); 
/* 
 * MusicKit bundle for selected language in 
 * /usr/local/lib/MusicKit/Languages, if found.  
 */
extern NSString *_MKErrorStringFile(void); 
/* Returns "Localized" if _MKErrorBundle() returns non-null */

#endif
