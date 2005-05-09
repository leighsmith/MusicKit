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
  @brief A VST-like audio FX processing module base class.
  
  To come
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
  @brief Registers an SndAudioProcessor class
  
  Automatically called by the SndAudioProcessor init method,
  so any subclasses will automatically register themselves once instantiated.
  @param fxclass The class of an SndAudioProcessor
*/
+ (void) registerAudioProcessorClass: (id) fxclass;

/*!
 @brief Use this to get a list of all the available FX processors.

  
 @return An NSArray of SndAudioProcessor sub-classed Class object ids
*/
+ (NSArray*) fxClasses;

/*!
  @brief Returns an array of names of available audio units (on MacOS X).
  
  The names returned can be assumed to be human readable and reasonably formatted. They can also
  be assumed to be unique and therefore can be used to create an instance using +processorNamed:.
  @return Returns an autoreleased NSArray of NSStrings of audio processors.
 */
+ (NSArray *) availableAudioProcessors;

/*!
 @brief  Factory method
 
  To come
 @return  Returns a freshly initialized, autoreleased SndAudioProcessor
*/
+ audioProcessor;

/*!
  @brief Returns an autoreleased instance of a SndProcessor subclass named <I>processorName</I>.
  @param processorName The name of a SndAudioProcessor as returned previously by <B>availableAudioProcessors</B>.
  
  Factory method.
 */
+ (SndAudioProcessor *) audioProcessorNamed: (NSString *) processorName;

/*!
  @brief   Initialization method
  @return     Returns <B>self</B>.
 */
- init;

/*!
  @brief   Initialization method
  @param      count
  @param      name
  @return     Returns <B>self</B>.
*/
- initWithParamCount: (const int) count name: (NSString *) name;

/*!
  @brief   Initialization using a dictionary of parameters.
  @param      paramDictionary NSDictionary of parameters and values to initialise SndAudioProcessor instance with.
  @param      name Name of the SndAudioProcessor to initialise.
  @return     Returns <B>self</B>.
 */
- initWithParameterDictionary: (NSDictionary *) paramDictionary name: (NSString *) name;

/*!
  @brief    Message sent when host determines the SndAudioProcessor should reinitialize
  its processing state. Eg, a delay processor would zero its z-buffers.
  @return      self
*/
- reset;

- (void) setNumParams: (const int) c;

/*!
  @brief   Gets the number of parameters
  @return     number of parameters
*/
- (int) paramCount;

/*!
  @brief   Gets the value of the indexed parameter. 
  
  Following the VST convention, this should be in the range [0,1]. No enforcement at the present time.
  @param      index Index of the parameter
  @return     parameter value
*/
- (float) paramValue: (const int) index;

/*!
 @brief  Gets the name of indexed parameter.
 @param  index Parameter index
 @return  NSString with parameter name
*/
- (NSString *) paramName: (const int) index;

/*!
 @brief  Returns a label or extra text describing the parameters units of measurement.
 @param  index Parameter index
 
  Example: if the parameter is in deciBels, an appropriate result might be to return "dB"
 @return  Returns the label for the parameter.
*/
- (NSString *) paramLabel: (const int) index;

/*!
  @brief   Converts an object-internal value into a more user-friendly representation.
  @param      index Parameter index
  
  Example: An instance variable may have a floating point range [0,1], but it
  represents a deciBel amount for user purposes. This method is an opportunity for the
  object to provide a more meaningful description of the parameter.
  @return     Returns an NSString containing the alternative string representation of the parameter
*/
- (NSString *) paramDisplay: (const int) index;

/*!
 @brief  Sets the indexed parameter to the value v.
 
  By VST convention, the argument v should be in the range [0,1]. If the
  internal parameter has a different range, this should be mapped internally.
 @param  index Index of the parameter to be set 
 @param  v Floating point value in the range [0,1]
*/
- (void) setParam: (const int) index toValue: (const float) v;

/*!
 @brief  Process the inputBuffer, and replace the results in the output buffer
 
  Overide this method with your own FX processing routines.
  There is nothing to stop inB and outB referring to the same buffer -  
  be warned that replacing the output values in outB may change inB in 
  these cases.
 @param  inB The input buffer
 @param  outB The output buffer
 @return  BOOL indicates whether the output is held in outB (YES), or inB (NO). 
  Means that processors that decide not to touch their data at all don't 
  need to spend time copying between buffers.
*/
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB;

/*!
 @brief
 
  (Internal SndKit use only) Individual processors may want
  to query their enclosing processor chain, for example to
  get the time at the start of the buffer (nowTime). This
  method gets called when a processor gets added to the chain,
  with the id of the chain.
 @param  inChain
*/
- (void) setAudioProcessorChain: (SndAudioProcessorChain *) inChain;

/*!
  @brief   Returns the SndAudioProcessorChain to which the processor is
  attached
  
  
  @return     Returns a SndAudioProcessorChain instance.
*/
- (SndAudioProcessorChain *) audioProcessorChain;

/*!
  @brief   Processor activity status query method
  @return     Returns TRUE if the processor is active, ie whether the host processor 
  chain should pass the audio stream through this processor.
*/
- (BOOL) isActive;

/*!
  @brief   Sets the active status of the processor.
  @param      b TRUE if the processor is to be made active.
  @return     self
*/
- setActive: (const BOOL) b;

/*!
  @brief   Assigns the SndAudioProcessor instance a new name.
  @return     Returns self.
  
  
*/
- setName: (NSString *) aName;

/*!
  @brief   Returns the name of the audio processor.
  @return     Returns an NSString instance.
  
  The name may or may not be unique to each instance of a SndAudioProcessor.
*/
- (NSString *) name;

/*!
  @brief   Returns an NSDictionary holding all parameters of a SndAudioProcessor instance.
  @return     An autoreleased NSDictionary.
  
  Each element in the dictionary has a key with an NSString of the parameter name and an 
  object which is an NSValue of the floating point parameter value.
*/
- (NSDictionary *) paramDictionary;

/*!
  @brief   Sets parameters with names and values provided by the given NSDictionary.
  @param      paramDictionary an NSDictionary holding NSString keys and NSValue float encoded objects.
  
  Each element in the dictionary has a key with an NSString of the parameter name and an
  object which is an NSValue of the floating point parameter value.
 */
- (void) setParamsWithDictionary: (NSDictionary *) paramDictionary;

/*!
  @brief   Assigns the parameter named keyName to the passed value.
  @param      keyName An NSString case-sensitively matching a parameter name.
  @param      value An NSValue holding an encoded float value between 0.0 and 1.0.
  
  
*/
- (void) setParamWithKey: (NSString *) keyName toValue: (NSNumber *) value;
// TODO - (void) setParamWithKey: (NSString *) keyName toValue: (NSValue *) value;


/*!
  @brief   Returns the parameter value as an NSNumber given an index.
  @return     Returns an NSNumber instance.
  
  
*/
- (NSNumber *) paramObjectForIndex: (const int) i;
// TODO - (id) paramObjectForIndex: (const int) i;

/*!
  @brief Assigns the current parameter delegate.
  
  The message -parameter:ofAudioProcessor:didChangeTo: is sent to the delegate when a parameter changes.
  @param delegate An object to receive notification that a parameter changed value.
 */
- (void) setParameterDelegate: (id) delegate;

/*!
 @return Returns the current parameter delegate. 
 */
- (id) parameterDelegate;

@end

@protocol SndAudioProcessorParameterDelegate

- (void) parameter: (unsigned int) parameter 
  ofAudioProcessor: (SndAudioProcessor *) processor
       didChangeTo: (float) inValue;

@end

#endif
