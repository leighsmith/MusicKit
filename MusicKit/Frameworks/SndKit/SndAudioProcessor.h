////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Heavily inspired by Steinberg's VST effects plugins for the moment
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSOR_H__
#define __SNDKIT_SNDAUDIOPROCESSOR_H__

#import <Foundation/Foundation.h>

#import "SndAudioBuffer.h"
#import "SndAudioProcessorChain.h"

////////////////////////////////////////////////////////////////////////////////

/*!
  @class SndAudioProcessor
  @abstract A VST-like audio FX processing module base class.
  @discussion To come
*/
@interface SndAudioProcessor : NSObject {
    /*! @var numParams Number of parameters in the audio processor */
    int numParams;
    /*! @var audioProcessorChain The SndAudioProcessorChain hosting this processor */
    SndAudioProcessorChain *audioProcessorChain;
    /*! @var name */    
    NSString *name;
    /*! @var active Indicates the processor instance will perform the processing. */
    BOOL  active;
    /*! @var parameterDelegate Delegate object informed when a parameters value is changed. */
    id parameterDelegate;
}

/*!
  @method registerAudioProcessorClass:
  @abstract Registers an SndAudioProcessor class
  @discussion Automatically called by the SndAudioProcessor init method,
  so any subclasses will automatically register themselves once instantiated.
  @param fxclass The class of an SndAudioProcessor
*/
+ (void) registerAudioProcessorClass: (id) fxclass;

/*!
 @method fxClasses
 @discussion Use this to get a list of all the available FX processors.
 @result An NSArray of SndAudioProcessor sub-classed Class object ids
*/
+ (NSArray*) fxClasses;

/*!
  @method availableAudioProcessors
  @abstract Returns an array of names of available audio units (on MacOS X).
  @discussion The names returned can be assumed to be human readable and reasonably formatted. They can also
     be assumed to be unique and therefore can be used to create an instance using +processorNamed:.
  @result Returns an autoreleased NSArray of NSStrings of audio processors.
 */
+ (NSArray *) availableAudioProcessors;

/*!
 @method     audioProcessor
 @abstract   Factory method
 @discussion To come
 @result     Returns a freshly initialized, autoreleased SndAudioProcessor
*/
+ audioProcessor;

/*!
  @method audioProcessorNamed:
  @abstract Returns an autoreleased instance of a SndProcessor subclass named <I>processorName</I>.
  @param processorName The name of a SndAudioProcessor as returned previously by <B>availableAudioProcessors</B>.
  @discussion Factory method.
 */
+ (SndAudioProcessor *) audioProcessorNamed: (NSString *) processorName;

/*!
  @method     init
  @abstract   Initialization method
  @result     Returns <B>self</B>.
 */
- init;

/*!
  @method     initWithParamCount:name:
  @abstract   Initialization method
  @param      count
  @param      name
  @result     Returns <B>self</B>.
*/
- initWithParamCount: (const int) count name: (NSString *) name;

/*!
  @method     initWithParameterDictionary:name:
  @abstract   Initialization using a dictionary of parameters.
  @param      paramDictionary
  @param      name
  @result     Returns <B>self</B>.
 */
- initWithParameterDictionary: (NSDictionary *) paramDictionary name: (NSString *) name;

/*!
  @method      reset
  @abstract    Message sent when host determines the SndAudioProcessor should reinitialize
               its processing state. Eg, a delay processor would zero its z-buffers.
  @result      self
*/
- reset;

- (void) setNumParams: (const int) c;

/*!
  @method     paramCount
  @abstract   Gets the number of parameters
  @result     number of parameters
*/
- (int) paramCount;

/*!
  @method     paramValue:
  @abstract   Gets the value of the indexed parameter. 
  @discussion Following the VST convention, this should be in the range [0,1]. No enforcement at the present time.
  @param      index Index of the parameter
  @result     parameter value
*/
- (float) paramValue: (const int) index;

/*!
 @method   paramName:
 @abstract   Gets the name of indexed parameter.
 @param      index Parameter index
 @result     NSString with parameter name
*/
- (NSString *) paramName: (const int) index;

/*!
 @method     paramLabel:
 @abstract   Returns a label or extra text describing the parameters units of measurement.
 @param      index Parameter index
 @discussion Example: if the parameter is in deciDels, one may want to return "dB"
 @result     Returns the label for the parameter.
*/
- (NSString *) paramLabel: (const int) index;

/*!
  @method     paramDisplay:
  @abstract   Converts an object-internal value into a more user-friendly representation.
  @param      index Parameter index
  @discussion Example: An instance variable may have a floating point range [0,1], but it
              represents a deciBel amount for user purposes. This method is an opportunity for the
              object to provide a more meaningful description of the parameter.
  @result     Returns a containing the alternative string representation of the parameter
*/
- (NSString *) paramDisplay: (const int) index;

/*!
 @method     setParam:toValue:
 @abstract   Sets the indexed parameter to the value v.
 @discussion By VST convention, the argument v should be in the range [0,1]. If the
             internal parameter has a different range, this should be mapped internally.
 @param      index Index of the parameter to be set 
 @param      v Floating point value in the range [0,1]
*/
- (void) setParam: (const int) index toValue: (const float) v;

/*!
 @method     processReplacingInputBuffer:outputBuffer:
 @abstract   Process the inputBuffer, and replace the results in the output buffer
 @discussion Overide this method with your own FX processing routines.
             There is nothing to stop inB and outB referring to the same buffer -  
             be warned that replacing the output values in outB may change inB in 
             these cases.
 @param      inB The input buffer
 @param      outB The output buffer
 @result     BOOL indicates whether the output is held in outB (YES), or inB (NO). 
             Means that processors that decide not to touch their data at all don't 
             need to spend time copying between buffers.
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB;

/*!
 @method    setAudioProcessorChain:
 @abstract
 @discussion (Internal SndKit use only) Individual processors may want
             to query their enclosing processor chain, for example to
             get the time at the start of the buffer (nowTime). This
             method gets called when a processor gets added to the chain,
             with the id of the chain.
 @param      inChain
 @result     void.
*/
- (void) setAudioProcessorChain: (SndAudioProcessorChain *) inChain;

/*!
  @method     audioProcessorChain
  @abstract   Returns the SndAudioProcessorChain to which the processor is
              attached
  @discussion
  @result     id of the SndAudioProcessorChain
*/
- (SndAudioProcessorChain *) audioProcessorChain;

/*!
  @method     isActive
  @abstract   Processor activity status query method
  @result     Returns TRUE if the processor is active, ie whether the host processor 
              chain should pass the audio stream through this processor.
*/
- (BOOL) isActive;

/*!
  @method     setActive
  @abstract   Sets the active status of the processor.
  @param      b TRUE if the processor is to be made active.
  @result     self
*/
- setActive: (const BOOL) b;

/*!
  @method     setName:
  @abstract
  @result
  @discussion
*/
- setName: (NSString *) aName;

/*!
  @method     name
  @abstract
  @result
  @discussion
*/
- (NSString *) name;

/*!
  @method     description
  @abstract
  @result
  @discussion
*/
- (NSString *) description;

/*!
  @method     paramDictionary
  @abstract   Returns an NSDictionary holding all parameters of a SndAudioProcessor instance.
  @result     An autoreleased NSDictionary.
  @discussion Each element in the dictionary has a key with an NSString of the parameter name and an 
              object which is an NSValue of a floating point value.
*/
- (NSDictionary *) paramDictionary;

/*!
  @method     setParamsWithDictionary:
  @abstract   Creates parameters with names and values provided by the given NSDictionary.
  @param      paramDictionary an NSDictionary holding NSString keys and NSValue float encoded objects.
  @discussion Each element in the dictionary has a key with an NSString of the parameter name and an
              object which is an NSValue of a floating point value.
 */
- (void) setParamsWithDictionary: (NSDictionary *) paramDictionary;

/*!
  @method     setParamWithKey:toValue:
  @abstract   Assigns the parameter named keyName to the passed value.
  @param      keyName An NSString case-sensitively matching a parameter name.
  @param      value An NSValue holding an encoded float value between 0.0 and 1.0.
  @discussion
*/
// - (void) setParamWithKey: (NSString *) keyName toValue: (NSValue *) value;
- (void) setParamWithKey: (NSString *) keyName toValue: (NSNumber *) value;

/*!
  @method     paramObjectForIndex:
  @abstract
  @result
  @discussion
*/
// - (id) paramObjectForIndex: (const int) i;
- (NSNumber *) paramObjectForIndex: (const int) i;

/*!
  @method setParameterDelegate:
  @abstract Assigns the current parameter delegate.
  @discussion The message -parameter:ofAudioProcessor:didChangeTo: is sent to the delegate when a parameter changes.
  @param delegate An object to receive notification that a parameter changed value.
 */
- (void) setParameterDelegate: (id) delegate;

/*!
 @method parameterDelegate
 @result Returns the current parameter delegate. 
 */
- (id) parameterDelegate;

@end

#endif
