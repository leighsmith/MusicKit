#ifndef __MK_ArielQP_H___
#define __MK_ArielQP_H___
//#import <musickit/Orchestra.h>
//sbrandon: changed to following, as all part of 1 framework now.
#import "MKOrchestra.h"
#import "MKSynthData.h"

#define MK_DRAM_ZERO 0           /* Use first sample as a ZERO */
#define MK_DRAM_SINK 1           /* Use second sample as a SINK */

@interface ArielQP:MKOrchestra
{
    int slot;         /* One of 2, 4 or 6 */
    BOOL satSoundIn;  /* YES if we're receiving sound from the satellites */
    BOOL DRAMAutoRefresh; /* YES if we're refreshing when needed */
    MKSynthData *_satSynthData; /* Buffers for incoming sound data */
    BOOL _initialized;
    NSDate * _reservedArielQP1; //sb: was double
}
/* This class is the Orchestra that represents the Quint Processor "hub"
 * (or "master") DSP.  Creating an instance of ArielQP also creates the
 * associated "satellite" DSPs ("sat" for short).  These are also called
 * "slave" DSPs.  Note, however, that sending -open (or -run, etc.) to the ArielQP
 * opens (or whatever) only the hub orchestra.   To send a messge to all the 
 * satellite DSPs for this QuintProcessor, invoke the method makeSatellitesPerform:.
 * Example:  [anArielQP makeSatellitesPerform:@selector(open)];  To send to all
 * the DSPs for the QP, invoked makeQPPerform:.
 *
 * You may control whether sound from the satellite DSPs is brought into the
 * hub DSP.  To control whether such sound is included or excluded, send 
 * setSatSoundIn:.  The defualt is to include it.  Excluding it
 * saves processing power on the hub, but means that the satellites will be useless,
 * unless they send their sound out their serial port.
 *
 * If the satellite sound is included, it can be accessed via the In1qpUG UnitGenerator.
 * Each instance of this unit generator takes sound from a particular channel on
 * a particular DSP.  Note that you may have any number of these so that you can
 * have multiple effects applied to the sound coming from a single source.
 *
 * For the common case of simply mixing each satellite to the output sample stream,
 * a SynthPatch called ArielQPMix is provided in the Music Kit SynthPatch Library.
 * This SynthPatch needs only to be allocated to work.   Be sure to deallocate it 
 * before closing the Orchestra.
 * 
 * TODO: DRAM allocation
 */

+new;
/* Create ArielQP for default slot, 2 */

+newInSlot:(unsigned short)slot;
/* Create ArielQP for specified slot */

-satellite:(char)which;
/* Returns the specified satellite.  which should be one of 'A','B','C' or 'D' */

-setSatSoundIn:(BOOL)yesOrNo;
/* Controls whether sound is obtained from the satellites. Default is YES. */

- setDRAMAutoRefresh:(BOOL)yesOrNo;
/* Controls whether DRAM auto refresh is on.  Default is off. */

-(BOOL)DRAMAutoRefresh;
/* Returns whether DRAM auto refresh is on. */

-(BOOL)satSoundIn;
/* Returns value of satSoundIn */

-makeSatellitesPerform:(SEL)selector;
/* Sends specified selector to each satellite */

-makeSatellitesPerform:(SEL)selector with:arg;
/* Sends specified selector to each satellite with specified arg */

-makeQPPerform:(SEL)selector;
/* Sends specified selector to each satellite and the hub (self) */

-makeQPPerform:(SEL)selector with:arg;
/* Sends specified selector to each satellite and the hub (self) */

- setDRAMAutoRefresh:(BOOL)yesOrNo;

@end

#import "MusicKit.h"

@interface ArielQPSat:MKOrchestra
{
    BOOL hubSoundOut; /* YES if we're sending sound to the hub. */
    NSDate * _reservedArielQPSat1; //sb: changed from double
}

-hub;
/* Returns hub corresponding to this satellite. */

-setHubSoundOut:(BOOL)yesOrNo;
/* Default is YES. Setting hubSoundOut disables serialSoundOut.  
 * Must be invoked when the deviceStatus is closed.
 */

-(BOOL)hubSoundOut;
/* Returns status of hubSoundOut */

-(int)outputChannelOffset;
-(int)outputChannelCount;
-(int)outputInitialOffset;
-(BOOL)upSamplingOutput;
-(BOOL)isRealTime;
/* 
 * For all of these methods:
 * if hubSoundOut, forwards message to hubOrchestra.  Otherwise,
 * invokes superclass implementation.
 */

-setSerialSoundOut:(BOOL)yesOrNo;



@end


#endif
