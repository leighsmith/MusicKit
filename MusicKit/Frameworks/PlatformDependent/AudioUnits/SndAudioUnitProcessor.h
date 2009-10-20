////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Original Author: Leigh Smith, <leigh@leighsmith.com>
//
//  Copyright (c) 2003, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>
// TODO while not within the SndKit framework.
// #import <SndKit/SndAudioProcessor.h>
#import <AudioUnit/AudioUnit.h>

/*!
  @class SndAudioUnitProcessor
  @brief Wraps an audio unit and it's signal processing behaviour.
  
  There is one AudioUnit per SndAudioUnitProcessor instance.
  In this context it forms the Model in an MVC triumvariate with SndAudioUnitController managing
  the display of the Audio Units GUI and the management of parameter changes.
*/

@interface SndAudioUnitProcessor : SndAudioProcessor
{
    /*! The AudioUnit handle used by the Apple AudioUnit API */
    AudioUnit audioUnit;
    /*! The bus of the audio unit to supply audio data to. */
    int inputBusNumber;
    /*! The number of channels on the input bus. */
    unsigned int inputChannelCount;
    /*! The bus of the audio unit to retrieve audio data from. 
	This could perhaps be determined by examining the bus characteristics of each audio unit.
     */
    int outputBusNumber;
    /*! The number of parameters in this AudioUnit. */
    int parameterListLength;
    /*! An array of AudioUnitParameterIDs used to refer to each AudioUnit parameter. */
    AudioUnitParameterID *parameterIDList;
    /*! Indicates if the AudioUnit accepts data as non-interleaved buffers (YES), or as a single interleaved buffer (NO). */
    BOOL auIsNonInterleaved;
    /*! buffer holding audio data in interleaved format. */
    float *interleavedInputSamples;
}

/*!
  @brief Returns an array of names of available audio units (on MacOS X).
  
  The names returned can be assumed to be human readable and reasonably formatted. They can also
  be assumed to be unique and therefore can be used to create an instance using +processorNamed:.
	  For the SndAudioUnitProcessor class, these names are those returned by those Apple AudioUnits available
  for loading.
  @return Returns an autoreleased NSArray of NSStrings of audio processors.
 */
+ (NSArray *) availableAudioProcessors;

/*!
  @brief Returns an autoreleased instance of a SndAudioProcessor subclass named <I>processorName</I>.
  @param processorName An NSString with one of the names returned by <B>+availableAudioProcessors</B>.
 */
+ (SndAudioProcessor *) audioProcessorNamed: (NSString *) processorName;

/*!
  @brief Returns the C++ AudioUnit handle.
 */
- (AudioUnit) audioUnit;

// TODO perhaps rename superclass and this to method initWithAudioUnitNamed: and remove paramCount parameter.

/*
 @brief Given a name previously returned by availableAudioUnits, a SndAudioUnitProcessor instance is created.
 @param audioUnitName The name of a unit as returned by <B>+availableAudioProcessors</B>.
 
   A SndAudioUnitProcessor instance is created for each AudioUnit. SndAudioUnitProcessor factory methods
             are the overseer of multiple available AudioUnits, each one is loaded and instantiated as a
             SndAudioUnitProcessor instance.
 */
- initWithParamCount: (const int) count name: (NSString *) audioUnitName;

/*!
  @brief Process the given audio buffer through the AudioUnit.
 */
- (BOOL) processReplacingInputBuffer: (SndAudioBuffer *) inB
                        outputBuffer: (SndAudioBuffer *) outB;


- (float) paramValue: (const int) index;

- (NSString *) paramName: (const int) index;

- (NSString*) paramLabel: (const int) index;

- (NSString *) paramDisplay: (const int) index;

- (void) setParam: (const int) index toValue: (const float) parameterValue;

@end
