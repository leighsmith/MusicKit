/*
  $Id$
  Defined In: The MusicKit

  Description:
    MKUnitGenerator is an abstract class; each subclass provides a
    particular music synthesis operation or function.  A MKUnitGenerator
    object represents a DSP unit generator, a program that runs on the
    DSP.
    
    You never create MKUnitGenerator objects directly in an application,
    they can only be created by the MKOrchestra through its
    allocUnitGenerator: method.  MKUnitGenerators are typically owned by a
    MKSynthPatch, an object that configures a set of MKSynthData and
    MKUnitGenerator objects into a DSP software instrument.  The MusicKit
    provides a number of MKUnitGenerator subclasses that can be configured
    to create new MKSynthPatch classes.
    
    Most of the methods defined in the MKUnitGenerator class are subclass
    responsiblities or are provided to help define the functionality of a
    subclass.  The most important of these are runSelf, idleSelf, and
    finishSelf.  These methods implement the behavior of the object in
    response to the run, finish, and idle messages, respectively.
    
    In addition to implementing the subclass responsibility methods, you
    should also provide methods for poking values into the memory
    arguments of the DSP unit generator that the MKUnitGenerator represents.
    For example, an oscillator MKUnitGenerator would provide a setFreq:
    method to set the frequency of the unit generator that's running on
    the DSP.
    
    MKUnitGenerator subclasses are created from DSP macro code.  The utility
    dspwrap turns a DSP macro into a MKUnitGenerator master class,
    implementing some of the subclass responsibility methods.
    
    It also creates a number of classes that inherit from your
    MKUnitGenerator subclass; these are called leaf classes.  A leaf class
    represents a specific memory space configuration on the DSP.  For
    example, OnePoleUG is a one-pole filter MKUnitGenerator master class
    provided by the Music Kit.  It has an input and an output argument
    that refer to either the x or the y memory spaces on the DSP.  To
    provide for all memory space configurations, dspwrap creates the leaf
    classes OnePoleUGxx, OnePoleUGxy, OnePoleUGyx, and OnePoleUGyy.
    
    You can modify a master class (the setFreq: method mentioned above
    would be implemented in a master class), but you never create an
    instance of one.  MKUnitGenerator objects are always instances of leaf
    classes.
    
    CF: MKSynthData, MKSynthPatch, MKOrchestra

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKUnitGenerator
  @brief MKUnitGenerators are the building blocks of DSP music synthesis.
 
Each MKUnitGenerator subclass represents a modular DSP program (a <i>unit
generator</i>) that provides a particular synthesis operation, such as waveform
generation, filtering, and mixing.  Sound is synthesized by dowloading unit
generators to the DSP, interconnecting them, and making them run. 

To download a copy of a particular unit generator to the DSP, you send the
<b>allocUnitGenerator:</b> message to an open MKOrchestra object, passing the
class of the MKUnitGenerator that represents the unit generator.  For example, to
download a copy of the unoise unit generator (which generates white noise), you
allocate an instance of the UnoiseUG class: 

<pre>
// Create an MKOrchestra and a variable for the MKUnitGenerator.

MKOrchestra *anOrch = [MKOrchestra new];
id aNoise;
// Open the MKOrchestra; check for failure.
if (![anOrch open])
. . .

// The MKUnitGenerator object is created at the same time that the
// unit generator program is download to the DSP.

aNoise = [anOrch allocateUnitGenerator: [UnoiseUGx class]];
</pre>

Notice that the receiver of the <b>class</b> message in the final line of the
example is UnoiseUGx. The &ldquo;x&rdquo; is explained later in this class
description.

To connect two MKUnitGenerators together, you allocate a <i>patchpoint</i> through
which they can communicate.  A patchpoint is a type of MKSynthData object that's
designed to be used for just this purpose, to communicate data from the output
of one MKUnitGenerator to the input of another.  For example, to connect our
UnoiseUGx object to a sound-output MKUnitGenerator, such as Out1aUGx, a patchpoint
must be allocated and then passed as the argument in an invocation of
UnoiseUGx's <b>setOutput:</b> method and Out1aUGx's <b>setInput:</b> method. 
But in order to do this, you have to understand a little bit about DSP memory
spaces:

The DSP's memory is divided into three sections, P, X, and Y:  P memory holds
program data; X and Y contain data. Unit generator programs are always
downloaded to P memory; the memory represented by a MKSynthData object is
allocated in either X or Y, as the argument to MKOrchestra's <b>allocSynthData:</b> method
is MK_xData or MK_yData.  In general, there's no difference between the two data
memory spaces (the one difference is mentioned below); dividing data memory into
two partitions allows the DSP to be used more efficiently (although it presents
some complications to the programmer, which you're living through right now).
Most of the methods defined in the MKUnitGenerator class are subclass responsiblities
or are provided to help define the functionality of a subclass.  The most important
of these are <b>runSelf</b>, <b>idleSelf</b>, and <b>finishSelf</b>.  These methods
implement the behavior of the object in response to the <b>run</b>, <b>finish</b>, and
<b>idle</b> messages, respectively.

In addition to implementing the subclass responsibility methods, you should also
provide methods for poking values into the memory arguments of the DSP unit
generator that the MKUnitGenerator represents.  For example, an oscillator
MKUnitGenerator would provide a <b>setFreq:</b> method to set the frequency of the
unit generator that's running on the DSP.

MKUnitGenerator subclasses are created from DSP macro code.  The utility
<b>dspwrap</b> turns a DSP macro into a MKUnitGenerator <i>master</i> class,
implementing some of the subclass responsibility methods.

It also creates a number of classes that inherit from your MKUnitGenerator
subclass; these are called <b>leaf</b> classes.  A leaf class represents a
specific memory space configuration on the DSP.  For example, OnePoleUG is a
one-pole filter MKUnitGenerator master class provided by the Music Kit.  It has an
input and an output argument that refer to either the x or the y memory spaces
on the DSP.  To provide for all memory space configurations, <b>dspwrap</b>
creates the leaf classes OnePoleUGxx, OnePoleUGxy, OnePoleUGyx, and
OnePoleUGyy.

You can modify a master class - for example, the <b>setFreq:</b> method
mentioned above would be implemented in a master class - but you never create an
instance of one.  MKUnitGenerator objects are always instances of leaf
classes.
*/
#ifndef __MK_UnitGenerator_H___
#define __MK_UnitGenerator_H___

#ifndef _MK_UNITGENERATOR_H
#define _MK_UNITGENERATOR_H

#import <Foundation/NSData.h> /*sb for NSData */
#import <Foundation/NSObject.h>
#import "orch.h"

typedef struct _MKUGArgStruct {   /* Used to represent Unit Generator args */
    MKOrchAddrStruct addrStruct;  /* Specifies location of arg. */
    DSPMemorySpace addressMemSpace;/* For address-valued arguments, 
                      space where the DSP code assumes the 
                      address is or DSP_MS_N */
    DSPLongDatum curVal;           /* The most recently poked value of arg.
                      If arg is not long, low order word
                      is ignored. (Used by optimizer)  */
    BOOL initialized;              /* Argument set yet? (Used by optimizer) */
    int type;                      /* Reserved. */
} MKUGArgStruct;

#import "dspwrap.h"

@interface MKUnitGenerator : NSObject
{
    id synthPatch;      /* The MKSynthPatch that owns this object, if any. */
    id orchestra;       /* The MKOrchestra on which the object is allocated. */

@protected
    unsigned short _orchIndex;
    unsigned short _synthPatchLoc;
    id _sharedKey;
    BOOL _protected;
    int _instanceNumber;

    BOOL isAllocated;   /* YES if allocated */
    MKUGArgStruct *args;   /* Pointer to the first of a block of 
                             MKUGArgStructs. Each of these corresponds to 
                             a unit generator memory argment. */
    MKSynthStatus status;
    MKOrchMemStruct relocation;

    MKLeafUGStruct *_classInfo; /* Same as [[self class] classInfo]. 
                                   Stored in instance as an optimization. */ 
    id _next;                   /* For available linked lists. */
}

+new;
+ allocWithZone:(NSZone *)zone;
+alloc;
-copy;
- copyWithZone:(NSZone *)zone;

 /* These methods are overridden to return [self doesNotRecognize]. 
    You never create, free or copy MKUnitGenerators directly. These operations
    are always done via an MKOrchestra object. */

+orchestraWillCreate:anOrch;
 /* Sent by MKOrchestra before creating a new instance.  This method may be
  * overridden to do any last-minute adjustments before the MKOrchestra creates 
  * a new instance.  Default implementation does nothing.
  */

- (void)dealloc; /*sb: used to be -free before OS conversion */
 /* Same as [self dealloc]. */


/*!
  @brief Returns the receiver's master structure.

  A subclass responsibility,
  this method is automatically generated by <b>dspwrap</b>.
  @return Returns a MKMasterUGStruct *.
*/
+(MKMasterUGStruct *) masterUGPtr; 

/*!
  @brief Returns the receiver's leaf structure.

  A subclass responsibility, this method is automatically generated by <b>dspwrap</b>.
  @return Returns a MKLeafUGStruct *.
*/
+ (MKLeafUGStruct *) classInfo; 

/*!
  @brief Returns the number of memory arguments in the receiver's DSP code.
  @return Returns an unsigned.
*/
+ (unsigned int) argCount; 

/*!
  @brief You never invoke this method.

  It's invoked by the MKOrchestra if it
  had to move the receiver during compaction.  A subclass can override
  this method to perform special behavior.  The default does nothing. 
  The return value is ignored.
  @return Returns an id.
*/
- moved; 

/*!
  @brief A subclass can override this method to reduce the command stream on
  an argument-by-argument basis, returning <b>YES</b> if <i>arg</i>
  should be optimized, <b>NO</b> if it shouldn't.

  The default implementation always returns <b>NO</b>.
  
  Optimization of means that if the argument it's set to the same value
  twice, the second setting is supressed.  You should never optimize
  an argument that the receiver's DSP code itself might change.
  
  Argument optimization applies to the entire class - all instances of
  the MKUnitGenerators leaf classes inherit an argument's optimization -
  and it can't be changed during a performance.
  @param  arg is an unsigned.
  @return Returns a BOOL.
*/
+ (BOOL) shouldOptimize: (unsigned) arg;

/*!
  @brief Invoke this method when the receiver is is created, after its code is loaded.

  If this method returns <b>nil</b>, the receiver is
  automatically freed by the MKOrchestra.  A subclass implementation
  should send <b>[super init]</b> before doing its own initialization
  and should immediately return <b>nil</b> if <b>[super init]</b>
  returns <b>nil</b>.  The default implementation returns self.
  @return Returns an id.
*/
- init;

/*!
  @brief Starts the receiver by sending <b>[self runSelf]</b> and then sets
  its status to MK_running.

  You never subclass this method;
  <b>runSelf</b> provides subclass runtime instructions.  A
  MKUnitGenerator must be sent <b>run</b> before it can be used.
  @return Returns an id.
*/
- run;

/*!
  @brief Subclass implementation of this method provides instructions for
  making the object's DSP code usable (as defined by the subclass).

  You never invoke this method directly, it's invoked automatically by
  the <b>run</b> method.  The default does nothing and returns the
  receiver.
  @return Returns an id.
*/
- runSelf; 

/*!
  @brief Finishes the receiver's activity by sending <b>finishSelf</b> and
  then sets its status to MK_finishing.

  You never subclass this method; <b>finishSelf</b> provides subclass finishing instructions. 
  Returns the value of <b>[self finishSelf]</b>, which is taken as the
  amount of time, in seconds, before the receiver can be idled.
  @return Returns a double.
 */
- (double) finish; 

/*!
  @brief A subclass may override this method to provide instructions for
  finishing.

  Returns the amount of time needed to finish; The default returns 0.0.
  @return Returns a double.
*/
- (double) finishSelf; 

/*!
  @brief Idles the receiver by sending <b>[self idleSelf]</b> and then sets
  its status to MK_idle.

  You never subclass this method; <b>idleSelf</b> provides subclass idle instructions.
  The idle state is defined as the MKUnitGenerator's producing no output.
  @return Returns an id.
*/
- idle;

/*!
  @brief A subclass may override this method to provide instructions for idling.

  The default does nothing and returns the receiver.  Most
  MKUnitGenerator subclasses implement <b>idleSelf</b> to patch their
  outputs to sink, a location that, by convention, nobody reads. 
  MKUnitGenerators that have inputs, such as Out2sumUG, implement
  <b>idleSelf</b> to patch their inputs to zero, a location that
  always holds the value 0.0.
  @return Returns an id.
*/
- idleSelf; 

/*!
  @brief Returns the receiver's status, one of MK_idle, MK_running, and MK_finishing.
  @return Returns an int.
*/
- (int) status; 

/*!
  @brief Returns a pointer to the structure that describes the receiver's location on the DSP.

  You can access the fields of the structure
  without caching it first, for example:
  
  <tt>[aUnitGenerator relocation]-&gt;pLoop</tt>
  
  returns the starting location of the receiver's pLoop code.
  @return Returns a MKOrchMemStruct *.
*/
- (MKOrchMemStruct *) relocation; 

/*!
  @brief Returns <b>YES</b> if the receiver is executed after <i>aUnitGenerator</i>.

  Execution order is determined by comparing the objects' pLoop addresses.
  @param  aUnitGenerator is an id.
  @return Returns a BOOL.
*/
- (BOOL) runsAfter: (MKUnitGenerator *) aUnitGenerator; 

/*!
  @brief Returns the number of memory arguments in the receiver's DSP code.
  
  The same value is returned by the <b>argCount</b> class method.
  @return Returns an unsigned.
*/
- (unsigned int) argCount; 

/*!
  @brief Returns a pointer to the receiver's leaf structure.

  The same structure pointer is returned by the <b>classInfo</b> class method.
  @return Returns a MKLeafUGStruct *.
*/
- (MKLeafUGStruct *) classInfo; 

/*!
  @brief Return a pointer to the structure that describes the receiver's
  memory requirements.

  Each field of the structure represents a
  particular MKOrchestra memory segment; its value represents the number
  of words that the segment requires.
  @return Returns a MKOrchMemStruct *.
*/
- (MKOrchMemStruct *) resources; 

/*!
  @brief Returns the name of the receiver's <i>argNum</i>'th DSP code
  argument, as declared in the DSP unit generator source code.

  The name isn't copied.
  @param  argNum is an unsigned.
  @return Returns an NSString*.
*/
+ (NSString *) argName: (unsigned) argNum; 

/*!
  @brief This method always returns the MKOrchestra class.

  It's provided for applications that extend the MusicKit to use other synthesis
  hardware.  If you're using more than one type of hardware, you
  should create a subclass of MKUnitGenerator for each.  The default
  hardware is that represented by MKOrchestra, the DSP56001.
  @return Returns an id.
*/
+ orchestraClass;

/*!
  @brief Returns the receiver's MKOrchestra object.
  @return Returns an id.
*/
- orchestra; 

 /* 
 * Deallocates the receiver and frees its MKSynthPatch, if any.
 * Returns nil.
 * sb: changed from dealloc to avoid conflict with foundation kit.
 */
- (void) mkdealloc; 

/*!
  @brief Invoked by the MKOrchestra to determine whether the receiver may be freed.

  Returns YES if it can, NO if it can't.  (A MKUnitGenerator can
  be freed if it isn't currently allocated or its MKSynthPatch can be
  freed).
  @return Returns a BOOL.
*/
- (BOOL) isFreeable; 

/*!
  @brief Returns the MKSynthPatch that the receiver is part of, if any.
  @return Returns an id.
*/
- synthPatch; 

/*!
  @brief Returns YES if the receiver has been allocated (by its MKOrchestra), NO if it hasn't.
  @return Returns a BOOL.
*/
- (BOOL) isAllocated; 

/*!
  @brief Sets the datum-valued argument <i>argNum</i> to <i>val</i>.

  If <i>argNum</i> is an L-space argument (two 24-bit words), its
  high-order word is set to <i>val</i> and its low-order word is
  cleared.  If <i>argNum</i> (as an index) is out of bounds, an error
  is generated and <b>nil</b> is returned.  Otherwise returns the
  receiver.  This is ordinarily invoked by a subclass.
  @param  argNum is an unsigned.
  @param  val is a DSPDatum.
  @return Returns an id.
 */
- setDatumArg: (unsigned) argNum to: (DSPDatum) val; 

/*!
  @brief Sets the datum-valued argument <i>argNum</i> to <i>val</i>.

  If <i>argNum</i> isn't an L-space argument (it can't accommodate a
  48-bit value) its value is set to the high 24-bits of <i>val</i>. 
  If <i>argNum</i> (as an index) is out of bounds, an error is
  generated and <b>nil</b> is returned.  Otherwise returns the
  receiver.  This is ordinarily only invoked by a subclass.
  @param  argNum is an unsigned.
  @param  val is a DSPLongDatum *.
  @return Returns an id.
 */
- setDatumArg: (unsigned) argNum toLong: (DSPLongDatum *) val;

/*!
  @brief Sets the addresst-valued argument <i>argNum</i> to <i>memoryObj</i>.
  
  If <i>argNum</i> (as an index) is out of bounds, an error is
  generated and <b>nil</b> is returned.  Otherwise returns the
  receiver.  This is ordinarily only invoked by a subclass.
 @param  argNum is an unsigned.
 @param  memoryObj is an id.
 @return Returns an id.
 */
- setAddressArg: (unsigned) argNum to: (id) memoryObj; 

/*! 
  @brief Sets the addresst-valued argument argNum to address.
  
  If argNum (as an index) is out of bounds, an error is
  generated and nil is returned.  Otherwise returns the receiver.
  This is ordinarily only invoked by a subclass.
  @param  argNum is an unsigned.
  @param  address is a DSPAddress.
  @return Returns an id.
*/
- setAddressArg: (unsigned) argNum toInt: (DSPAddress) address;

/*!
  @brief Sets the address-valued argument <i>argNum</i> to the sink
  patchpoint.

  (Sink is a location which, by convention, is never
  read.) If <i>argNum</i> (as an index) is out of bounds, an error is
  generated and <b>nil</b> is returned.  Otherwise returns the
  receiver.  This is ordinarily only invoked by a subclass.
  @param  argNum is an unsigned.
  @return Returns an id.
*/
- setAddressArgToSink: (unsigned) argNum; 

/*!
  @brief Sets the address-valued argument <i>argNum</i> to a zero patchpoint.
  
  (A zero patchpoint is a location with a constant 0 value; by
  convention the patchpoint is never written to.) If <i>argNum</i> (as
  an index) is out of bounds, an error is generated and <b>nil</b> is
  returned.  Otherwise returns the receiver.  This is ordinarily only
  invoked by a subclass.
  @param  argNum is an unsigned.
  @return Returns an id.
*/
- setAddressArgToZero: (unsigned) argNum; 

/*!
  @brief Returns the memory space to or from which the address-valued
  argument <i>argNum</i> reads or writes.

  If <i>argNum</i> isn't an address-valued argument, returns DSP_MS_N.
  @param  argNum is an unsigned.
  @return Returns a DSPMemorySpace.
*/
+ (DSPMemorySpace) argSpace: (unsigned) argNum; 

/*!
  @brief You never invoke this method directly, it's invoked from <b>free</b>.

  A subclass may implement this method to provide
  specialized behavor  before the object is freed. 
  For example, you might want to release locally-allocated MKSynthData. 
  @return Returns an id.
*/
- freeSelf;

/*!
  @brief Sets whether various error checks are done, such as verifying that
  MKUnitGenerator arguments and MKSynthData memory spaces are correct.

  The default is NO. You should send enableErrorChecking:YES when you
  are debugging MKUnitGenerators or MKSynthPatches, then disable it when
  your application is finished.
  @param  yesOrNo is a BOOL.
  @return Returns an id.
*/
+ enableErrorChecking: (BOOL) yesOrNo;

/*!
  @brief If this object is installed in its MKOrchestra's shared table, returns
  the number of objects that have allocated it.

  Otherwise returns 1 if it is allocated, 0 if it is not.
  @return Returns an int.
*/
- (int) referenceCount;

/* Functions that are equivalent to above methods, for speed. The first
   argument is assumed to be an instance of class MKUnitGenerator. */
id MKSetUGDatumArg(id self,unsigned argNum,DSPDatum val);
id MKSetUGDatumArgLong(id self,unsigned argNum,DSPLongDatum *val);
id MKSetUGAddressArg(id self,unsigned argNum,id memoryObj);
id MKSetUGAddressArgToInt(id self,unsigned argNum,DSPAddress addr);


/*!
  @brief Writes the MKUnitGenerator as a portion of a DSP .lod file.

  You normally don't invoked this method.  It's invoked by MKOrchestra's
  <b>writeSymbolTable:</b>.
  @param  s is a NSMutableData.
  @return Returns an id.
*/
- writeSymbolsToStream: (NSMutableData *) s;

/*!
  @brief Returns a low integer that uniquely identifies this MKUnitGenerator.
  
  This integer is unique for the duration of the execution of the
  program, unlike object <b>id</b> values, which may be reassigned
  after an object is freed.
  @return Returns an int.
*/
- (int) instanceNumber;

 /* -read: and -write: 
  * Note that archiving is not supported in the MKUnitGenerator object, since,
  * by definition the MKUnitGenerator instance only exists when it is resident on
  * a DSP.
  */

@end

#endif /* _MK_UNITGENERATOR_H  */

#endif
