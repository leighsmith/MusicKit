/*
  $Id$
  Defined In: The MusicKit

  Description:
    MKSynthData objects represent DSP memory that's used in music synthesis.
    For example, you can use a MKSynthData object to load predefined data
    for wavetable synthesis or to store DSP-computed data to create a
    digital delay.  Perhaps the most common use of MKSynthData is to create
    a location through which MKUnitGenerators can pass data.  This type of
    MKSynthData object is called a patchpoint.  For example, in frequency
    modulation an oscillator MKUnitGenerator writes its output to a
    patchpoint which can then be read by another oscillator as its
    frequency input.
   
    You never create MKSynthData objects directly in an application, they
    can only be created by the MKOrchestra through its
    allocSynthData:length: or allocPatchpoint: methods.  MKSynthData objects
    are typically owned by a MKSynthPatch, an object that configures a set
    of MKSynthData and MKUnitGenerator objects into a DSP software instrument.
   
    The methods setData: and setToConstant: are used to load a MKSynthData
    object with data from an array or as a constant, respectively.  These
    methods are simple versions of the more thorough methods
    setData:length:offset: and setToConstant:length:offset:, which allow you
    to load an arbitrary amount of data into any portion of the
    MKSynthData's memory.  The data in a MKSynthData object, like all DSP data
    used in music synthesis, is 24-bit fixed point words (data type
    DSPDatum).  You can declare a MKSynthData to be read-only by sending it
    the message setReadOnly:YES.  You can't change the data in a read-only
    MKSynthData object.
   
    An instance of MKSynthData consists of an MKOrchAddrStruct, a structure
    that describes the DSP location of the object's data, and a length
    instance variable, an integer value that measures the size of the data
    in DSPDatum words.  However, it doesn't contain a copy of the memory
    itself.  When you load data into a MKSynthData, it's instantly sent to
    the DSP device driver.
   
    DSP memory allocation and management is explained in the MKOrchestra
    class description; many of the return types used here, such as
    DSPAddress and DSPMemorySpace, are described in MKOrchestra.  In
    general, the design of the MKOrchestra makes intimate knowledge of the
    details of the DSP unnecessary.
   
    CF: MKSynthPatch, MKOrchestra, MKUnitGenerator

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University  
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.6  2001/09/08 21:53:16  leighsmith
  Prefixed MK for UnitGenerators and SynthPatches

  Revision 1.5  2001/09/06 21:27:48  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.4  2000/11/25 23:04:40  leigh
  Enforced ivar privacy

  Revision 1.3  2000/03/29 03:35:41  leigh
  Cleaned up doco and ivar declarations

  Revision 1.2  1999/07/29 01:25:51  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class MKSynthData
  @discussion

MKSynthData objects represent DSP memory that's used in music synthesis.  For
example, you can use a MKSynthData object to load predefined data for wavetable
synthesis or to store DSP-computed data to create a digital delay. Perhaps the
most common use of MKSynthData is to create a location through which
MKUnitGenerators can pass data.  This type of MKSynthData object is called a
<i>patchpoint</i>.  For example, in frequency modulation an oscillator
MKUnitGenerator writes its output to a patchpoint which can then be read by
another oscillator as its frequency input.

You never create MKSynthData objects directly in an application, they can only be
created by the MKOrchestra through its <b>allocSynthData:length:</b> or
<b>allocPatchpoint:</b> methods.  MKSynthData objects are typically owned by a
MKSynthPatch, an object that configures a set of MKSynthData and MKUnitGenerator
objects into a DSP software instrument.

The methods <b>setData:</b> and <b>setConstant:</b> are used to load a MKSynthData
object with data from an array or as a constant, respectively.  These methods
are simple versions of the more thorough methods <b>setData:length:offset:</b>
and <b>setConstant:length:offset:</b>, which allow you to load an arbitrary
amount of data into any portion of the SynthData's memory.  The data in a
MKSynthData object, like all DSP data used in music synthesis, is 24-bit fixed
point words (data type DSPDatum).  You can declare a MKSynthData to be read-only
by sending it the message <b>setReadOnly:YES</b>.  You can't change the data in
a read-only MKSynthData object.

An instance of MKSynthData consists of an MKOrchAddrStruct, a structure that
describes the DSP location of the object's data, and a <b>length</b> instance
variable, an integer value that measures the size of the data in DSPDatum words.
 However, it doesn't contain a copy of the memory itself.  When you load data
into a MKSynthData, it's instantly sent to the DSP device driver.

DSP memory allocation and management is explained in the MKOrchestra class
description; many of the return types used here, such as DSPAddress and
DSPMemorySpace, are described in MKOrchestra.  In general, the design of the
MKOrchestra makes intimate knowledge of the details of the DSP
unnecessary.

See also:  MKSynthPatch, MKOrchestra, MKUnitGenerator
*/
#ifndef __MK_SynthData_H___
#define __MK_SynthData_H___

#import <Foundation/NSObject.h>

@interface MKSynthData : NSObject
{
    /* DO NOT CHANGE THE POSITION OF THE FOLLOWING BLOCK OF IVARS! */
    id synthPatch;      /* The MKSynthPatch that owns this object (if any). */
    id orchestra;       /* The orchestra on which the SynthElement object is allocated. */

@private
    unsigned short _orchIndex;
    unsigned short _synthPatchLoc;
    id _sharedKey;
    BOOL _protected;
    int _instanceNumber;
    /* END OF INVARIANT IVARS */

    unsigned int length;       /* Length of allocated memory in words. */
    MKOrchAddrStruct orchAddr; /* Structure that directly represents DSP memory. Contains size, space, etc.*/
    BOOL readOnly;             /* YES if the object's data is read-only. */

    MKOrchMemStruct _reso;     /* Each instance has its own here */
    BOOL isModulus;
}

+new;
+ allocWithZone:(NSZone *)zone;
+alloc;
-copy;

- copyWithZone:(NSZone *)zone;
 /* These methods are overridden to return [self doesNotRecognize]. 
    You never create, free or copy MKUnitGenerators directly. These operations
    are always done via an MKOrchestra object. */

- (void)dealloc; /* was "free" before conversion */
 /* Same as [self dealloc]. */


/*!
  @method clear
  @result Returns an id.
  @discussion Clears the receiver's memory but doesn't deallocate
              it.
*/
- clear; 

/*!
  @method length
  @result Returns an unsigned int.
  @discussion Returns the size (in words) of the receiver's memory
              block.
*/
-(unsigned int ) length; 

/*!
  @method address
  @result Returns a DSPAddress.
  @discussion Returns the DSP address of the receiver's memory
              block.
*/
-(DSPAddress ) address; 

/*!
  @method memorySpace
  @result Returns a DSPMemorySpace.
  @discussion Returns the DSP space in which the receiver's memory block is
              allocated.
*/
-(DSPMemorySpace ) memorySpace; 

/*!
  @method orchAddrPtr
  @result Returns a MKOrchAddrStruct *.
  @discussion Returns a pointer to the receiver's address structure.
*/
-(MKOrchAddrStruct *) orchAddrPtr; 

-(BOOL)isModulus;


/*!
  @method setData:length:offset:
  @param  dataArray is a DSPDatum *.
  @param  len is an int.
  @param  off is an int.
  @result Returns an id.
  @discussion Loads (at most) <i>len</i> words of data from <i>dataArray</i> into
              the receiver's memory, starting at location <i>off</i> words from
              the beginning of the receiver's memory block.  If <i>off</i> +
              <i>len</i> is greater than the receiver's length (as returned by the
              <b>length</b> method), or if the data couldn't otherwise be loaded,
              the error MK_synthDataLoadErr is generated and <b>nil</b> is
              returned.  Otherwise returns the receiver.
*/
- setData:(DSPDatum *)dataArray length:(unsigned int )len offset:(int )off; 

/*!
  @method setShortData:length:offset:
  @param  dataArray is a short *.
  @param  len is an int.
  @param  off is an int.
  @result Returns an id.
  @discussion Loads (at most) len words of data from <i>dataArray</i> into the
              receiver's memory, right justified, starting at location <i>off</i>
              words from the beginning of the receiver's memory block.  If
              <i>off</i> + <i>len</i> is greater than the receiver's length (as
              returned by the <b>length</b> method), or if the data couldn't
              otherwise be loaded, the error MK_synthDataLoadErr is generated and
              <b>nil</b> is returned. Otherwise returns the receiver.
*/
-setShortData:(short *)dataArray length:(unsigned int )len offset:(int)off;

/*!
  @method setData:
  @param  dataArray is a DSPDatum *.
  @result Returns an id.
  @discussion Loads <i>dataArray</i> into the receiver's memory.  Implemented as
              (and returns the value of):
              
              <tt>[self setData:dataArray length:length offset:0];</tt>
              
              where the second argument is the instance variable <b>length</b>.
              This assumes that <i>dataArray</i> is the same length as the receiver.
*/
- setData:(DSPDatum *)dataArray; 

/*!
  @method setShortData:
  @param  dataArray is a short *.
  @result Returns an id.
  @discussion Loads <i>dataArray</i> into the receiver's memory, right justified. 
              Implemented as (and returns the value of)

              <tt>[self setShortData:dataArray length:length offset:0];</tt>
 
              where the second argument is the instance variable length.
              This assumes that dataArray is the same length as the receiver.
*/
- setShortData:(short *)dataArray;

/*!
  @method setToConstant:length:offset:
  @param  value is a DSPDatum.
  @param  len is an int.
  @param  off is an int.
  @result Returns an id.
  @discussion Similar to <b>setData:length:offset:</b>, but loads the constant
              <i>value</i> rather than an array; see <b>setData:length:offset:</b>
              for details.
*/
- setToConstant:(DSPDatum )value length:(unsigned int )len offset:(int )off; 

/*!
  @method setToConstant:
  @param  value is a DSPDatum.
  @result Returns an id.
  @discussion Fills the receiver's memory with the constant <i>value</i>. 
              Implemented as (and returns the value of)
              
              <tt>[self setToConstant:value length:length offset:0];</tt>
              
              where the second argument is the instance variable <b>length</b>.
*/
- setToConstant:(DSPDatum )value;    

/*!
  @method run
  @result Returns an id.
  @discussion This does nothing and returns the receiver.  It's provided for
              compatibility with MKUnitGenerator; specifically, it allows a
              MKSynthPatch to send <b>run</b> to all its MKSynthElement objects
              without regard for their class.
*/
- run;

/*!
  @method idle
  @result Returns an id.
  @discussion This does nothing and returns the receiver.  It's provided for
              compatibility with MKUnitGenerator; specifically, it allows a
              MKSynthPatch to send <b>idle</b> to all its MKSynthElement objects
              without regard for their class.
*/
- idle;

/*!
  @method finish
  @result Returns a double.
  @discussion This does nothing and returns 0.0.  It's provided for compatibility
              with MKUnitGenerator; specifically, it allows a MKSynthPatch to send
              <b>finish</b> to all its SynthElement objects without regard for
              their class.
*/
- (double)finish;

/*!
  @method orchestraClass
  @result Returns an id.
  @discussion This method always returns the <b>id</b> of the MKOrchestra class. 
              It's provided for applications that extend the MusicKit to use
              other synthesis hardware.  If you're using more than one type of
              hardware, you should create a subclass of MKSynthData and/or
              MKUnitGenerator for each.  The default hardware is that represented
              by MKOrchestra, the DSP56001.
*/
+ orchestraClass;

/*!
  @method orchestra
  @result Returns an id.
  @discussion Returns the receiver's MKOrchestra object.
*/
- orchestra; 

- (void)mkdealloc;	/* sb: was dealloc, but this may differ from OpenStep's
			 * ideas of dealloc. I have changed things here and
			 * in MKSynthPatch h/m, MKUnitGenerator.h (not m), and in
			 * synthElementMethods.m
			 */
 /* 
 * Deallocates the receiver and frees its MKSynthPatch, if any. Returns nil.
 */


/*!
  @method isAllocated
  @result Returns a BOOL.
  @discussion Provided for compatability with MKUnitGenerator. Always returns YES,
              since deallocated SynthDatas are freed immediately.
*/
-(BOOL) isAllocated;

/*!
  @method isFreeable
  @result Returns a BOOL.
  @discussion Invoked by the MKOrchestra to determine whether the receiver may be
              freed.  Returns YES if it can, NO if it can't.  (A MKSynthData can be
              freed if its a member of a MKSynthPatch that can be
              freed.)
*/
-(BOOL ) isFreeable; 

/*!
  @method synthPatch
  @result Returns an id.
  @discussion Returns the MKSynthPatch that the receiver is part of, if
              any.
*/
- synthPatch; 

/*!
  @method setReadOnly:
  @param  readOnlyFlag is a BOOL.
  @result Returns an id.
  @discussion Sets the receiver to read-only if <i>readOnlyFlag</i> is YES and
              read-write if it's NO.  The default access for a MKSynthData object is
              read-write.  Returns the receiver.  The MKOrchestra automatically
              creates some read-only MKSynthData objects (SineROM, MuLawROM, and the
              zero and sink patchpoints) that ignore this method.
*/
- setReadOnly:(BOOL)readOnlyFlag;

/*!
  @method readOnly
  @result Returns a BOOL.
  @discussion Returns YES if the receiver is read-only.
*/
- (BOOL)readOnly;

/*!
  @method referenceCount
  @result Returns an int.
  @discussion If the receiver is installed in its MKOrchestra's shared object table,
              this returns the number of objects that have allocated it. Otherwise
              returns 1.
*/
-(int)referenceCount;

 /* -read: and -write: 
  * Note that archiving is not supported in the MKSynthData object, since,
  * by definition the MKSynthData instance only exists when it is resident on
  * a DSP.
  */


/*!
  @method readDataUntimed:length:offset:
  @param  dataArray is a DSPDatum *.
  @param  len is an int .
  @param  off is an int .
  @result Returns an id.
  @discussion Queries the DSP for the value of the given DSP memory.
              
              This returns a valid value by reference only when one of the following is true:
               &#183;   the data was allocated before the MKOrchestra started running
               &#183;   the data was allocated more than deltaT in the past
               &#183;   delta-t is 0
               &#183;   there is no Conductor performing
*/
-readDataUntimed:(DSPDatum *)dataArray length:(unsigned int )len offset:(int )off;

/*!
  @method readShortDataUntimed:length:offset:
  @param  dataArray is a short *.
  @param  len is an int.
  @param  off is an int.
  @result Returns an id.
  @discussion Queries the DSP for the value of the given DSP memory.  Same as
              readDataUntimed:length:offset: for 16-bit arrays of data.
              
*/
-readShortDataUntimed:(short *)dataArray length:(unsigned int )len offset:(int)off;

@end



#endif
