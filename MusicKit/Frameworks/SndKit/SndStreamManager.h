/*
  $Id$

  Description:

  Original Author: SKoT McDonald, <skot@tomandandy.com>, tomandandy music inc.

  Sat 10-Feb-2001, Copyright (c) 2001 tomandandy music inc.

  Permission is granted to use and modify this code for commercial and non-commercial
  purposes so long as the author attribution and copyright messages remain intact and
  accompany all relevant code.
*/
#ifndef __SNDSTREAMMANAGER_H__
#define __SNDSTREAMMANAGER_H__

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>

@class SndAudioBuffer;
@class SndStreamClient;
@class SndStreamMixer;

#define SSM_VERSION 1 

/*!
    @class      SndStreamManager
    @abstract   
    @discussion To come
    @var        mixer
    @var        active
    @var        format
    @var        nowTime
*/
@interface SndStreamManager : NSObject
{
/*
    NSMutableArray *streamClients;
    NSLock         *streamClientsLock;
*/
    SndStreamMixer *mixer;

    BOOL            active;
    SndSoundStruct  format;
    double          nowTime;
}


/*!
    @method initialize;
    @abstract Class initialization method
    @discussion Creates the default stream manager
    @result void.
*/
+ (void) initialize;

/*!
    @method defaultStreamManager
    @abstract 
    @discussion 
    @result Returns the default manager
*/
+ (SndStreamManager*) defaultStreamManager;

/*!
    @method dealloc
    @abstract Destructor
    @discussion 
    @result void
*/
- (void) dealloc;

/*!
    @method description
    @abstract 
    @discussion 
    @result NSString with description of SndStreamManager
*/
- (NSString*) description;

/*!
    @method startStreaming
    @abstract 
    @discussion 
    @result Boolean indicating whether streaming was successfully started
*/
- (BOOL) startStreaming;

/*!
    @method stopStreaming
    @abstract 
    @discussion 
    @result Boolean indictaing whether streaming successfully stopped.
*/
- (BOOL) stopStreaming;

/*!
    @method addClient: (SndStreamClient*) client 
    @abstract 
    @discussion 
    @param (SndStreamClient*) client
    @result Boolean indicating whether client was successfully added
*/
- (BOOL) addClient: (SndStreamClient*) client;

/*!
    @method removeClient: 
    @abstract 
    @discussion 
    @param (SndStreamClient*) client
    @result Boolean indicating whether client was successfully removed
*/
- (BOOL) removeClient: (SndStreamClient*) client;

/*!
    @method processStreamAtTime:input:output:
    @abstract 
    @discussion
    @param (double) sampleCount
    @param (SNDStreamBuffer*) inB
    @param (SNDStreamBuffer*) outB
*/
- (void) processStreamAtTime: (double) sampleCount
                       input: (SNDStreamBuffer*) inB
                      output: (SNDStreamBuffer*) outB;

/*!
    @method setFormat:
    @abstract 
    @discussion 
    @param (SndSoundStruct*) f
    @result self
*/
- setFormat: (SndSoundStruct*) f;

/*!
    @method nowTime
    @abstract Return the current time as understood by the SndStreamManager
    @discussion 
    @result nowTime as a double 
*/
- (double) nowTime;

/*!
    @method mixer
    @abstract Mixer member accessor method
    @discussion 
    @result SndStreamMixer
*/
- (SndStreamMixer*) mixer;

/*!
    @method isActive
    @abstract indicates whether streaming is happening (active) 
    @discussion 
    @result Boolean
*/
- (BOOL) isActive;

@end

#endif
