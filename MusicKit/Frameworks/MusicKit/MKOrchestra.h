/*
  $Id$
  Defined In: The MusicKit

  Description:
    See headerdoc description below for details.
 
    The MKOrchestra factory object manages all programs running on all the DSPs.
    Each instance of the MKOrchestra class corresponds to a single DSP. We call
    these instances "orchestra instances" or, simply, "orchestras". We call the
    collection of all orchestras the "MKOrchestra". Each orchestra instance is
    referred to by an integer 'orchIndex'. These indecies start at 0. 
    For the basic configuration, orchIndex is always 0.

    There are two levels of allocation: MKSynthPatch allocation and
    unit generator allocation. MKSynthPatches are higher-level entities,
    collections of MKUnitGenerators. Both levels may be used at the same time.

    CF: MKUnitGenerator.m, MKSynthPatch.m, MKSynthData.m and MKPatchTemplate.m.

  Original Author: David A. Jaffe

  Copyright 1988-1992, NeXT Inc.  All rights reserved.
  DSP Serial Port and subclass support and other 4.0 release extensions,
  Copyright 1993, CCRMA, Stanford Univ.
  Portions Copyright (c) 1999-2004 The MusicKit Project.
*/
/*!
  @class MKOrchestra
  @brief This is the allocator and manager of DSP resources.
  
  The MKOrchestra class manages signal processing resources used in music synthesis.
  Each instance of MKOrchestra represents a single "signal processor resource" that 
  may refer to a DSP hardware processor, or to processing behaviour performed by the
  main processor, a networked processor (i.e Beowulf clustered), or perhaps one of 
  the vector processor resources of a main processor. This is for historical reasons
  collectively termed a "DSP". The signal processing resource is identified by 
  <b>orchIndex</b>, a zero-based integer index.
  
  In the basic NeXT hardware configuration, there's only one MC56001 DSP so there's
  only one MKOrchestra instance (<b>orchIndex</b> 0).  On Intel-based hardware, there may
  be any number of DSPs or none, depending on how many DSP cards the user has installed (See
  "INSTALLING INTEL-BASED DSP DRIVERS" below). On PowerPC class machines the signal
  processing is performed on the main processor, so there's only one MKOrchestra.

  The methods defined by the MKOrchestra class let you manage a DSP by allocating 
  (TODO should this be assign?, i.e. alloc as normal, then assign the initialised instance?)
  portions of its memory for specific synthesis modules and by setting its
  processing characteristics. There are two levels of allocation: MKSynthPatch allocation and
  unit generator allocation. MKSynthPatches are higher-level entities, collections of
  MKUnitGenerators. 
 
  You can allocate entire MKSynthPatches or individual
  MKUnitGenerator and MKSynthData objects through the methods defined here.  Keep in
  mind, however, that similar methods defined in other class - specifically, the
  MKSynthPatch allocation methods defined in MKSynthInstrument, and the MKUnitGenerator
  and MKSynthData allocation methods defined in MKSynthPatch - are built upon and
  designed to usurp those defined by MKOrchestra.  You only to need to allocate
  synthesis objects directly if you want to assemble sound-making modules at a low
  level.

  Before you can do anything with an MKOrchestra - particularly, before you can
  allocate synthesis objects - you must create and open the MKOrchestra.  The
  MKOrchestra is a shared resource (that is, various DSP modules all use the same
  single MKOrchestra instance.)  Therefore, creation is done through the <b>orchestra</b>
  method - sending <b>orchestra</b> twice returns the same object.   (This strange
  convention is for historical reasons and matches the ApplicationKit
  convention.)  To open an MKOrchestra, you send it the <b>open</b> message.  This
  provides a channel of communication with the DSP that the MKOrchestra represents. 
  Once you've allocated the objects that you want, either through the methods
  described here or through those defined by MKSynthInstrument and MKSynthPatch, you
  can start the synthesis by sending the <b>run</b> message to the MKOrchestra.  (If
  your application uses the MusicKit's performance scheduling mechanism, the
  <b>run</b> message should be sent immediately before or immediately after the
  <b>startPerformance</b> message is sent to the MKConductor.) The <b>stop</b>
  method halts synthesis and <b>close</b> breaks communication with the DSP. 
  These methods change the MKOrchestra's status, which is always one of the
  following MKDeviceStatus values:

 <table border=1 cellspacing=2 cellpadding=0 align=center>
 <tr>
 <td align=left>MKDeviceStatus</td>
 <td align=left>Description</td>
 </tr>
 <tr>
 <td align=left>MK_devOpen</td>
 <td align=left>The MKOrchestra is open but not running.</td>
 </tr>
 <tr>
 <td align=left>MK_devRunning</td>
 <td align=left>The MKOrchestra is open and running.</td>
 </tr>
 <tr>
 <td align=left>MK_devStopped</td>
 <td align=left>The MKOrchestra has been running, but is now stopped.</td>
 </tr>
 <tr>
 <td align=left>MK_devClosed</td>
 <td align=left>The MKOrchestra is closed.</td>
 </tr>
 </table>

  You can query an MKOrchestra's status through the <b>deviceStatus</b>
  method.

  When the MKOrchestra is running, the allocated MKUnitGenerators produce a stream of
  samples that, by default, are sent to the "default sound output".  On most modern
  hardware, that is the stereo digital to analog converter (the
  DAC), which converts the samples into an audio signal.  This type of sound
  output is called "Host sound output" because the samples are sent from the DSP to
  the host computer.  
 
 TODO modify this:
 But there are a number of other alternatives.  You can write the
samples to the DSP serial port, to be played through any of a number of devices
that have their own DACs or do digital transfer to DAT recorders.  To do this,
invoke the method <b>setSerialSoundOut:</b> with a <b>YES</b> argument before
sending <b>open</b> to the MKOrchestra.  This is also called "SSI" sound output.
 See the DSPSerialPortDevice class for more details.  

  Another option is to write the samples to a soundfile. You do this by invoking the
  method <b>setOutputSoundfile:</b> before sending <b>open</b> to the MKOrchestra. 
  If you're writing a soundfile, the computer's DAC is automatically disabled.
  It is also possible to save the DSP commands as a "DSP commands format
  soundfile".   Such files are much smaller than the equivalent soundfile.  Use
  the method <b>setOutputCommandsFile:</b> to create such a file.  However,
  support for playing DSP commands file may not continue in future releases. 
  Therefore, we do not encourage their use.

  The MKOrchestra can also process sound that it receives. 
  To do this, send <b>setSoundIn:</b> with a <b>YES</b> argument. 
 TODO update this:
  &lt;&lt;Note that currently serial input may not be combined with writing a
  soundfile.&gt;&gt;

Every command that's sent to the DSP is given a timestamp indicating when the
command should be executed.  The manner in which the DSP regards these
timestamps depends on whether its MKOrchestra is timed or untimed, as set through
the <b>setTimed:</b> method.  In a timed MKOrchestra, commands are executed at the
time indicated by its timestamp.  If the MKOrchestra is untimed, the DSP ignores
the timestamps, executing commands as soon as it receives them.  By default, an
MKOrchestra is timed.

Since the DSP is a separate processor, it has its own clock and its own notion
of the current time. Since the DSP can be dedicated to a single task - in this
case, generating sound - its clock is generally more reliable than the main
processor, which may be controlling any number of other tasks.  If your
application is generating MKNotes without user-interaction, for example, if it's
playing a MKScore or scorefile, then you should set the Music Kit performance to
be unclocked, through the MKConductor's <b>setClocked:</b> method, and the
MKOrchestra to be timed.  This allows the Music Kit to process MKNotes and send
timestamped commands to the DSP as quickly as possible, relying on the DSP's
clock to synthesize the MKNotes at the correct time.  However, if your application
must respond to user-initiated actions with as little latency as possible, then
the MKConductor must be clocked.  In this case, you can set the MKOrchestra to be
untimed.  A clocked MKConductor and an untimed MKOrchestra yields the best possible
response time.

If your application responds to user actions, but can sustain some latency
between an action and its effect, then you may want to set the MKConductor to be
clocked and the DSP to be timed, and then use the C function
<b>MKSetDeltaT()</b> to set the <i>delta time</i>.  Delta time is an imposed
latency that allows the Music Kit to run slightly ahead of the DSP.  Any
rhythmic irregularities created by the Music Kit's dependence on the CPU's clock
are evened out by the utter dependability of the DSP's clock (assuming that the
such an irregularity isn't greater than the delta time).

Since parameter updates can occur asynchronously, the MKOrchestra doesn't know, at
the beginning of a MKNote, if the DSP can execute a given set of MKUnitGenerators
quickly enough to produce a steady supply of output samples for the entire
duration of the MKNote.  However, it makes an educated estimate and will deny
allocation requests that it thinks will overload the DSP and cause it to fall
out of real time.  Such a denial may result in a smaller number of
simultaneously synthesized voices.  You can adjust the MKOrchestra's DSP
processing estimate, or headroom, by invoking the <b>setHeadroom:</b> method. 
This takes an argument between -1.0 and 1.0; a negative headroom allows a more
liberal estimate of the DSP resources - resulting in more simultaneous voices -
but it runs the risk of causing the DSP to fall out of real time.  Conversely, a
positive headroom is more conservative: You have a greater assurance that the
DSP won't fall out of real time but the number of simultaneous voices is
decreased.  The default is a somewhat conservative 0.1.  If you're writing
samples to a soundfile with the DAC disabled, headroom is ignored.  On
Intel-based hardware, the differences between the clock and memory speed of
various DSP cards requires some hand-tuning of the headroom variable.  Slower
DSP cards should use a higher headroom and faster cards should use a negative
headroom.

When sending sound to the DSP serial port, there is very little latency - for
example, sound can be taken in the serial port, processed, and sent out again
with less than 10 milliseconds of delay.  However, in the case of sound output
via the NeXT monitor, there's a sound output time delay that's equal to the size
of the buffer that's used to collect computed samples before they're shovelled
to the NeXT DAC.  To accommodate applications that require the best possible
response time (the time between the iniitation of a sound and its actual
broadcast from the DAC), a smaller sample output buffer can be requested by
sending the <b>setFastResponse:YES</b> message to an MKOrchestra.  However, the
more frequent attention demanded by the smaller buffer will detract from
synthesis computation and, again, fewer simultaneous voices may result.  You can
also improve response time by using the high sampling rate (44100) although
this, too, attenuates the synthesis power of the DSP.  By default, the
MKOrchestra's sampling rate is 22050 samples per second.  <b>setFastResponse:</b>
has no effect when sending samples to the DSP serial port.

To avoid creating duplicate synthesis modules on the DSP, each instance of
MKOrchestra maintains a shared object table.  Objects on the table are
MKSynthPatches, SynthDatas, and MKUnitGenerators and are indexed by some other
object that represents the shared object.  For example, the OscgafUG
MKUnitGenerator (a family of oscillators) lets you specify its waveform-generating
wave table as a MKPartials object (you can also set it as a MKSamples object; for
the purposes of this example we only consider the MKPartials case).  When its wave
table is set, through the <b>setTable:length:</b> method, the oscillator
allocates a MKSynthData object from the MKOrchestra to represent the DSP memory that
will hold the waveform data that's computed from the MKPartials.  It also places
the MKSynthData on the shared object table using the MKPartials as an index by
sending the message

<tt>[MKOrchestra installSharedSynthData:theSynthData for:thePartials];</tt>

If another oscillator's wave table is set as the same MKPartials object, the
already-allocated MKSynthData can be returned by sending the message

<tt>id aSynthData = [MKOrchestra sharedObjectFor:thePartials];</tt>

The method <b>installSharedObject:for:</b> is provided for installing
MKSynthPatches and MKUnitGenerators.

If appropriate hardware is available, multiple DSPs may be used in concert.  The
MKOrchestra automatically performs allocation on the pool of DSPs.  On Intel-based
hardware, multiple DSP support is achieved by adding multiple DSP cards.  On
NeXT hardware, multiple DSP support is available via the Ariel QuintProcessor, a
5-DSP card.  

The MKOrchestra class may be subclassed to support other 56001-based cards.  See
the ArielQP and ArielQPSat objects for an example.

The default sound output configuration may be customized by using the defaults
data base.  On NeXT hardware, you can specify the destination of the sound
output, and on both NeXT hardware and Intel-based DSP cards with NeXT-compatible
DSP serial ports, you can specify the type of the serial port device.  The
default sound out type is derived from the MusicKit "OrchestraSoundOut" variable
in the defaults data base, which may currently have the value "SSI" or "Host".  
More values may be added in the future.  Note that an "SSI" value for
"OrchestraSoundOut" refers to the DSP's use of the SSI port and that usage does
not imply NeXT-compatiblility.  For example, for the Turtle Beach cards, the
default is "serialSoundOut" via the on-card CODEC.  (On Intel-based hardware,
the determination as to whether the DSP serial port is NeXT-compatible is based
on the driver's "SerialPortDevice" parameter - if its value is "NeXT", the
serial port is NeXT-compatible. )  You can always return to the default sample
output configuration by sending the message <b>setDefaultSoundOut</b>.

New MKOrchestras are auto-configured with their default configuration, with a
DSPSerialPortDevice object automatically created.  For devices with
NeXT-compatible DSP serial ports, you may change the configuration using the
MKOrchestra methods such as <b>-setSerialPortDevice:</b>.  

INSTALLING INTEL-BASED DSP DRIVERS

To install an Intel-based DSP driver, follow these steps:

1. Double click on the driver you want to install.  The drivers can be found on
<b>/LocalLibrary/Devices/.</b>  For example, to install the ArielPC56D driver,
double click on <b>/LocalLibrary/Devices/ArielPC56D.config</b>.  Type the root
pass word. It will tell you driver was successfully installed. Click
OK.
You've now "installed" the driver.

2. In <b>Configure.app</b>, Click Other. Click Add... Click Add.  Select the
driver (from the "other" category) and make sure that the I/O port corresponds
to your hardware configuration.  From Menu/Configuration, select Save.   You've
now "added the driver".	

3. Repeat the process for any other drivers, such as the TurtleBeach Multisound
driver, <b>/LocalLibrary/Devices/TurtleBeachMS.config.</b>	

4. If you have multiple cards of a certain type, repeat step 2, making sure to
assign a different I/O address to each instance of the driver.  The first will
be given the name &lt;driverName&gt;0, where &lt;driverName&gt; is the name of
the driver (e.g. "ArielPC56D")  The second will be given the name
&lt;driverName&gt;1, etc. The trailing number is called the "unit."  For
example,  if you add 2 Ariel cards to your system, they will be assigned the
names "ArielPC56D0" and "ArielPC56D1".  If you have one Multisound card, it will
be assigned the name "TurtleBeachMS0".  This assignment is done by the
<b>Configure.app</b> application.

5. Reboot.  Drivers are now installed and usable.

All DSP drivers are in the same "family", called "DSP."  All DSP units are
numbered with a set of "DSP indecies", beginning with 0.  (Note that this is
distinct from the "unit" numbers.) If there is only one DSP card, there is no
ambiguity.  However, if there is more than one card, the user's defaults data
base determines which DSP or DSPs should be used.  For example, in the example
given above, a user's defaults data base may have:
 	
MusicKit DSP0 ArielPC56D1	
MusicKit DSP2 ArielPC56D0	
MusicKit DSP4 TurtleBeachMS0

This means that the default DSP is the one on the 2nd Ariel card that you
installed.  Also, notice that there may be "holes" - in this example, there is
no DSP1 or DSP3.  DSP identifiers up to 15 may be used.  The DSP indecies refer
to the MKOrchestra index passed to methods like<b> +newOnDSP:</b>.  If there is no
driver for that DSP, <b>+newOnDSP:</b> returns nil.  

Some DSP cards support multiple DSPs on a single card.  For such cards, we have
the notion of a "sub-unit", which follows the unit in the assigned name with the
following format:  &lt;driver&gt;&lt;unit&gt;-&lt;subunit&gt;.   For example if
a card named "Frankenstein" supports 4 DSPs, and there are two Frankenstein
units installed in the system, the user's defaults data base might look like
this:
	
MusicKit DSP0 Frankenstein0-0	
MusicKit DSP1 Frankenstein0-1	
MusicKit DSP2 Frankenstein0-2	
MusicKit DSP3 Frankenstein0-3	
MusicKit DSP4 Frankenstein1-0	
MusicKit DSP5 Frankenstein1-1	
MusicKit DSP6 Frankenstein1-2	
MusicKit DSP7 Frankenstein1-3

Currently, the Music Kit provides drivers for the following cards: <b>Ariel
PC56D,  Turtle Beach Multisound</b>, <b>I*Link i56, Frankenstein</b>.  See the
release notes for the latest information on supported drivers.
*/
#ifndef __MK_Orchestra_H___
#define __MK_Orchestra_H___

#import <Foundation/Foundation.h>
#import "orch.h"
#import "MKDeviceStatus.h"
#import "MKSynthData.h"

/*!
  @file MKOrchestra.h
 */

/*!
  @brief This enumeration defines the types of shared objects that can be
  registered with the MKOrchestra's shared object mechanism.
 
  The shared object mechanism manages reference counts, automatic lazy garbage
  collection, etc. Note that the same data object may be registered as the key for
  several different types of shared data.  For example, a MKPartials
  object may have associated with it two MKSynthData objects, one
  representing its oscTable representation and one representing its
  waveshapingTable representation.
 */
typedef enum _MKOrchSharedType {
    /*! Wildcard. */
    MK_noOrchSharedType = 0, 
    /*! Data used as a wave table for an oscillator.  This shared
	type must be a power of 2 in length and if a request for
        a shorter length is made, it is	downsampled. */
    MK_oscTable = 1, 
    /*! Data used as a waveshaping table. This table performs a non-linear mapping.
        When looked-up with a sine wave, it provides a specified spectrum.  */
    MK_waveshapingTable = 2,
    /*! Data used as an excitation table for waveguide-based synthesis. 
        This type is similar to oscTable but it need not be a power of 2 and
        it is shortened by truncation (from the end.) */
    MK_excitationTable = 3
} MKOrchSharedType;

typedef enum _MKEMemType {
    MK_orchEmemNonOverlaid = 0, 
    MK_orchEmemOverlaidXYP = 1, 
    MK_orchEmemOverlaidPX = 2
} MKEMemType;

/*!
  @brief MK_UNTIMED and MK_TIMED are arguments for the MKConductor <b>setTimed:</b> method.     
 
  @see <b>MKConductor</b> and the Performance Concepts documentation for details.
 */
typedef enum {
    /*! DSP commands are executed as soon as they are sent. */
    MK_UNTIMED = 0,
    /*! DSP commands are executed at the time of their time-stamp. */
    MK_TIMED = 1,
    /*! Obsolete. */
    MK_SOFTTIMED = 2
} MKOrchestraTiming;

/*!
  @brief Get the MKSynthPatch preemption time

  During a performance, DSP resources can become scarce; it's sometimes
  necessary to preempt active MKSynthPatches in order to synthesize new
  MKNotes.  This preemption is handled by MKSynthInstrument objects. But
  rather than simply yank the rug from under an active MKSynthPatch, a
  certain amount of time is given to allow the patch to &ldquo;wind
  down&rdquo; before it's killed in order to prevent clicks.  By default,
  this grace period, or &ldquo;preempt duration&rdquo;, is 0.006 seconds -
  not a lot of time but enough to avoid snapping the MKSynthPatch's
  envelopes.  You can set the preempt duration yourself through
  <b>MKSetPreemptDuration()</b>.  Preempt duration is global to an
  application; it's current value is retrieved through
  <b>MKGetPreemptDuration()</b>. 
  @return Returns the preempt duration.
  @see <b>MKSetPreemptDuration()</b>.
*/
extern double MKGetPreemptDuration(void);

/*!
  @brief Set the MKSynthPatch preemption time.

  During a performance, DSP resources can become scarce; it's sometimes
  necessary to preempt active MKSynthPatches in order to synthesize new
  MKNotes.  This preemption is handled by MKSynthInstrument objects. But
  rather than simply yank the rug from under an active MKSynthPatch, a
  certain amount of time is given to allow the patch to &ldquo;wind
  down&rdquo; before it's killed in order to prevent clicks.  By default,
  this grace period, or &ldquo;preempt duration&rdquo;, is 0.006 seconds -
  not a lot of time but enough to avoid snapping the MKSynthPatch's
  envelopes.  You can set the preempt duration yourself through
  <b>MKSetPreemptDuration()</b>.  Preempt duration is global to an
  application; it's current value is retrieved through
  <b>MKGetPreemptDuration()</b>. 
  @param  seconds is a double.
*/
extern void MKSetPreemptDuration(double seconds);
 
@interface MKOrchestra : SndStreamClient
{
    /*! @var computeTime Runtime of orchestra loop in seconds. */
    double computeTime; 
    /*! @var samplingRate Sampling rate. */     
    double samplingRate;
    /*! @var unitGeneratorStack Stack of MKUnitGenerator instances in the order they appear in DSP memory. 
    MKSynthData instances are not on this unitGeneratorStack. */
    NSMutableArray *unitGeneratorStack;      
    /*! @var outputSoundfile For output sound samples. */
    NSString *outputSoundfile;
    id outputSoundDelegate;
    /*! @var inputSoundfile For input sound samples. READ DATA */
    NSString *inputSoundfile;
    /*! @var outputCommandsFile For output DSP commands. */
    NSString *outputCommandsFile;
    id xZero;         /* Special pre-allocated x patch-point that always holds
                         0 and to which nobody ever writes, by convention.  */
    id yZero;         /* Special pre-allocated y patch-point that always holds
                         0 and to which nobody ever writes, by convention.  */
    id xSink;      /* Special pre-allocated x patch-point that nobody ever
                      reads, by convention. */
    id ySink;      /* Special pre-allocated y patch-point that nobody ever
                      reads, by convention. */
    id xModulusSink;/* Special pre-allocated x patch-point that nobody ever
                      reads, by convention. */
    id yModulusSink;/* Special pre-allocated y patch-point that nobody ever
                      reads, by convention. */
    id sineROM;    /* Special read-only MKSynthData object used to represent
                      the SineROM. */
    id muLawROM;   /* Special read-only MKSynthData object used to represent
                      the Mu-law ROM. */
    /*! @var deviceStatus Status of MKOrchestra. */
    MKDeviceStatus deviceStatus;
    /*! @var orchIndex Index of the DSP resource managed by this instance. */
    unsigned short orchIndex;
    char isTimed;    /* Determines whether DSP commands go out timed or not. */
    BOOL useDSP;     /* YES if running on an actual DSP (Default is YES) */
    BOOL hostSoundOut;   /* YES if sound is going to the DACs. */
    /*! @var soundIn Indicates if this orchestra will process incoming sound. */
    BOOL soundIn;
    BOOL isLoopOffChip; /* YES if loop has overflowed off chip. */
    BOOL fastResponse;  /* YES if response latency should be minimized */
    /*! @var localDeltaT positive offset in seconds added to out-going time-stamps */
    double localDeltaT;
    short onChipPatchPoints;
    int release;
    char version;
    NSString *monitorFileName;   /* NULL uses default monitor */
    DSPLoadSpec *mkSys;
    NSString *lastAllocFailStr;
    id _sysUG;
    int _looper;
    void *_availDataMem[3];
    void  *_eMemList[3];
    NSMutableDictionary *_sharedSet;
    DSPAddress _piLoop;
    DSPAddress _xArg;
    DSPAddress _yArg;
    DSPAddress _lArg;
    DSPAddress _maxXArg;
    DSPAddress _maxYArg;
    DSPAddress *_xPatch;
    DSPAddress *_yPatch;
    unsigned long _xPatchAllocBits;
    unsigned long _yPatchAllocBits;
    double _headroom;
    double _effectiveSamplePeriod;
    id _orchloopClass;
    id _previousLosingTemplate;
    DSPFix48 _previousTimeStamp;
    int _parenCount;
    int _bottomOfMemory;
    unsigned int _bottomOfExternalMemory[3];
    int _topOfExternalMemory[3];
    int _onChipPPPartitionSize;
    int _numXArgs;
    int _numYArgs;
    float _xArgPercentage;
    float _yArgPercentage;
    void *_simFP;
    MKEMemType _overlaidEMem;
    BOOL _nextCompatibleSerialPort;
    NSString *_driverParMonitorFileName;
    // added in by LMS, thawing the ancient ivar freeze
    double previousTime;
    NSHashTable *sharedGarbage;
    char *simulatorFile;
    id readDataUG;
    id xReadData;
    id yReadData;
    double timeOffset;
    double synchTimeRatio;
    NSTimer *timedEntry;
    BOOL synchToConductor;
}

/*!
  @return Returns a MKDeviceStatus.
  @brief Returns the MKDeviceStatus of the receiver, one of
  
	  <UL>
  <LI>	MK_devClosed 
  <LI>	MK_devOpen 
  <LI>	MK_devRunning 
  <LI>	MK_devStopped
  </UL>
  
  The MKOrchestra states are explained in the class description, above.

  
*/
- (MKDeviceStatus) deviceStatus;

/*!
  @param  headroom is a double.
  @return Returns an id.
  @brief Sets the receiver's computation headroom, adjusting the tradeoff
  between processing power and reliability.

  The argument should be in
  the range -1.0 to 1.0.  As you increase an MKOrchestra's headroom, the
  risk of falling out of real time decreases, but synthesis power is
  also weakened.  The default, 0.1, is a conservative estimate and can
  be decreased in many cases without heightening the risk of falling
  out of real time.
  
  The effective sampling period - the amount of time the MKOrchestra 
  thinks the DSP has to produce a sample - is based on the formula
  
  (1.0/<b>samplingRate</b>) * (1.0 - <b>headroom</b>).
  
  Returns the receiver.
*/
- (void) setHeadroom: (double) headroom;

/*!
  @brief Sets the headroom of all MKOrchestras instances that have been created.
  @param  headroom is a double.
  @return Returns the receiver.
  @see  -<b>setHeadroom:</b>
*/
+ (void) setHeadroom: (double) headroom;

/*!
  @brief Returns the receiver's headroom, as set through the <b>setHeadroom:</b> method.

  Headroom should be a value between -.0  and 1.0.  The default is 0.1.
  @return Returns a double.
*/
- (double) headroom;

// TODO investigate if needed.
// TODO candidate to return void
/*!
  @return Returns an id.
  @brief Marks the beginning of a section of DSP commands that are sent as a
  unit.

  Returns the receiver.
*/
- beginAtomicSection;

// TODO investigate if needed.
// TODO candidate to return void
/*!
  @return Returns an id.
  @brief Marks the end of a section of DSP commands that are sent as a unit.

  Returns the receiver.
*/
- endAtomicSection;

/*!
  @brief Returns and initializes a new MKOrchestra for the default DSP, if one
  doesn't already exist, otherwise returns the existing one.
 
  The DSP isn't actually claimed until the MKOrchestra instance is sent the
  <b>open</b>message.
  @return Returns an autoreleased MKOrchestra instance.
*/
+ orchestra; 

/*!
  @brief Creates and returns an MKOrchestra instance for the <i>index</i>'th DSP.

  If an MKOrchestra object already exists for the specified DSP,
  the existing object is returned.  Returns <b>nil</b> if <i>index</i>
  is out of bounds or if the <i>index</i>'th DSP isn't available.  For
  example, on Intel hardware, if there is no driver for the
  <i>index</i>'th DSP, this method returns nil.  Note that for some
  types of DSP devices, the object returned will be a <i>subclass</i>
  of MKOrchestra, rather than an instance of MKOrchestra.  
  @param  index is an unsigned short indicating which DSP resource to initialise on.
  @return Returns an id.
  @see registerOrchestraSubclass:forOrchIndex:.
*/
+ orchestraOnDSP: (unsigned short) index; 

/*!
  @brief Creates an MKOrchestra instance for every available DSP, if it has not
  already been created.

  This is accomplished by consulting the user's defaults data base (setable with the
  Preferences application).  Returns all the MKOrchestra's created.
  @return Returns an NSArray of MKOrchestra instances.
*/
+ (NSArray *) orchestrasOnAllDSPs;

/*!
  @brief Flushes all currently buffered DSP commands by invoking the
  <b>flushTimedMessages</b> instance method for each MKOrchestra.

  The usual way to invoke this method is via the MKConductor
  +<b>unlockPerformance</b> method  (which must be preceeded by
  +<b>lockPerformance</b>.)    
  @return Returns an id.
*/
+ flushTimedMessages; 

/*!
  @brief Returns the maximum possible number of DSPs.

  This may be more than the number of DSPs you actually have.   
  @return Returns an unsigned short.
*/
+ (unsigned short) DSPCount;

/*!
  @brief Returns the MKOrchestra of the <i>index</i>'th DSP.

  If <i>index</i> is out of bounds, or if an MKOrchestra hasn't been created for the
  specified DSP, <b>nil</b> is returned.
  @param  index is an unsigned short.
  @return Returns an id.
*/
+ (MKOrchestra *) nthOrchestra: (unsigned short) index; 

/*!
  @brief Initialises the MKOrchestra instance on the first (default) DSP resource.
 */
- init;

/*!
  @brief Initialises an MKOrchestra instance on the given DSP processing resource.
  
  A DSP processing resource is nowdays an abstract concept of processing resource which
  may refer to a hardware DSP processor, vector unit or networked processor.
  @param dspIndex The index of the DSP processing resource as returned by +driverNames.
 */
- initOnDSP: (unsigned short) dspIndex;

/*!
  @brief Sends <b>open</b> to each of the MKOrchestra instances and sets each
  to MK_devOpen.

  If any of the MKOrchestras responds to the <b>open</b>
  message by returning <b>nil</b>, so too does this method return
  <b>nil</b>.  Otherwise returns the receiver.  Note that if you first
  send <b>open</b> and then create a new MKOrchestra, the new MKOrchestra
  will not automatically be opened.  
  @return Returns an id.
*/
+ open; 

/*!
  @brief Sends <b>run</b> to each of the MKOrchestra instances and sets each to MK_devRunning.

  If any of the MKOrchestras responds to the <b>run</b>
  message by returning <b>nil</b>, so too does this method return
  <b>nil</b>.  Otherwise returns the receiver.
  @return Returns an id.
*/
+ run; 

/*!
  @brief Sends <b>stop</b> to each of the MKOrchestra instances and sets each
  to MK_devStopped.

  If any of the MKOrchestras responds to the
  <b>run</b> message by returning <b>nil</b>, so too does this method
  return <b>nil</b>.  Otherwise returns the receiver.
  @return Returns an id.
*/
+ stop; 

/*!
  @brief Sends <b>close</b> to each of the MKOrchestra instances and sets each
  to MK_devClosed.

  If any of the MKOrchestras responds to the <b>close</b> message by returning <b>nil</b>,
  so too does this method return <b>nil</b>.  Otherwise returns the receiver.
  @return Returns an id.
*/
+ close; 

/*!
  @brief Sends <b>abort</b> to each of the MKOrchestra instances and sets each to MK_devClosed.

  If any of the MKOrchestras responds to the <b>abort</b> message by returning <b>nil</b>,
  so too does this method return <b>nil</b>.  Otherwise returns the receiver.
  @return Returns an id.  
*/
+ abort;

// TODO document
// TODO investigate if needed.
- (void) synchTime: (NSTimer *) timer;

/*!
  @brief Returns the tick size used by synthesis unit-generators.

  Each unit generator runs for this many frames, and patchpoints are this
  length. Since 1989, the tick-size used on the DSP has been 16. 
  @return Returns an int.
*/
- (int) tickSize; 

/*!
  @brief Returns the receiver's sampling rate.

  The default is determined by the method <b>defaultSamplingRate</b>.
  @return Returns a double.
*/
- (double) samplingRate; 

// TODO candidate to return void
/*!
  @param  newSRate is a double.
  @return Returns an id.
  @brief Sets the sampling rate of all the MKOrchestra instances by sending
  <b>setSamplingRate:</b><i>newSRate</i> to all closed MKOrchestras.

  
  This method also changes the default sampling rate; when a new
  MKOrchestra is subsequently created, it also gets set to
  <i>newSRate</i>.  Returns the receiver.
*/
+ (void) setSamplingRate: (double) newSRate; 

// TODO candidate to return BOOL
/*!
  @param  newSRate is a double.
  @return Returns an id.
  @brief Sets the receiver's sampling rate to <i>newSRate</i>, taken as
  samples per second.

  The receiver must be closed - <b>nil</b> is
  returned if the receiver's status isn't MK_devClosed.  Returns the
  receiver.
*/
- setSamplingRate: (double) newSRate; 

// TODO candidate to return void
/*!
  @param  areOrchsTimed is a MKOrchestraTiming.
  @return Returns an id.
  @brief Sends <b>setTimed:</b><i>areOrchsTimed</i> to each MKOrchestra
  instance.

  If <i>areOrchsTimed</i> is YES, the DSP processes the
  commands that it receives at the times specified by the commands'
  timestamps.  If it's <b>NO</b>, DSP commands are processed as
  quickly as possible.  By default, an MKOrchestra is timed.  Note,
  however, that this method changes the default to
  <i>areOrchsTimed</i>.
*/
+ setTimed: (MKOrchestraTiming) areOrchsTimed; 

// TODO candidate to return void
/*!
  @param  isOrchTimed is a MKOrchestraTiming.
  @return Returns an id.
  @brief If <i>isOrchTimed</i> is YES, the receiver's DSP executes the
  commands it receives according to their timestamps.

  If it's NO, it
  ignores the timestamps processes the commands immediately.  By
  default, an MKOrchestra is timed.   * Note that untimed mode was
  originally intended primarily as a means of inserting "out of band"
  messages into a timed stream and is not as efficient for
  high-bandwidth transfers normally associated with a Music Kit
  performance.  Note also that untimed mode is not deterministic with
  respect to precise timing. However, it has the advantage of
  providing the minimum possible latency.  It is permissable to change
  time timing mode during a Music Kit performance.
*/
- setTimed: (MKOrchestraTiming) isOrchTimed; 

/*!
  @brief Returns <b>YES</b> if the receiver is timed <b>NO</b> if it's untimed.
  @return Returns a MKOrchestraTiming.
*/
- (MKOrchestraTiming) isTimed; 

// TODO candidate to return void
/*!
  @brief Specify that the MKOrchestra is to synchronize the DSP's notion of
  time to that of the MKConductor's time.
 
   The DSP sample counter and the System clock (i.e. the MKConductor
  clock) are intended to keep the same time (except for fluctuations
  due to the internal buffering of the DSP and sound drivers).  Over a
  long-term  performance, however, the two clocks may begin to drift
  apart slightly, on the order of a few milliseconds per minutes.  If
  you are running with an extremely small "delta time" (cf.
  <b>MKSetDeltaT()</b>), you may want to synchronize the two clocks
  periodically.  By sending <b>setSynchToConductor:YES</b>, you
  specify that the MKOrchestra is to synchronizes the DSP's notion of
  time to that of the MKConductor's time every 10 seconds to account for
  slight differences between the rate of the two clocks.   This method
  assumes an Application object exists and is running and that the
  MKConductor is in clocked mode.
  
  Note:  This method may cause time to go backwards in the DSP temporarily,
  and thus may cause distortion of envelopes, lost notes, etc.
  Therefore, its use is recommended only when absolutely necessary.
  An alternative method of synchronization (though no safer) can be found
  in the Ensemble programming example.
  @param  yesOrNo is a BOOL.
  @return Returns an id.
*/
- setSynchToConductor: (BOOL) yesOrNo;

/*!
  @brief &lt;&lt;NeXT hardware only.&gt;&gt; Sets the size of the sound
  output buffer; two sizes are possible.

  If <i>yesOrNo</i> is YES,
  the smaller size is used, thereby improving response time but
  somewhat decreasing the DSP's synthesis power.  If it's NO, the
  larger buffer is used.  By default, an MKOrchestra uses the larger
  buffer.  Returns the receiver.  This method has no effect if sound
  output is done via the DSP serial port.
  @param  yesOrNo is a BOOL.
  @return Returns an id.
*/
- setFastResponse: (char) yesOrNo;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief Sends <b>setFastResponse:</b><i>yesOrNo</i> to all existing
  MKOrchestras objects and returns the receiver.

  This also sets the
  default used by subsequently created MKOrchestras.
*/
+setFastResponse:(char)yesOrNo;

/*!
  @brief Returns YES if the receiver is using small sound-out buffers to
  minimize response latency.

  Otherwise returns NO.
  @return Returns a BOOL.
*/
- (char) fastResponse;

+ setAbortNotification:aDelegate;

/*!
  @brief Sets the offset, in seconds, that's added to the timestamps of
  commands sent to the receiver's DSP.

  The offset is added to the delta time that's set with <b>MKSetDeltaT()</b>.
  This has no effect if the receiver isn't timed.  
  @param  val is a double.
  @return Returns the receiver.
*/
- setLocalDeltaT: (double) val;

/*!
  @brief Returns the value set through <b>setLocalDeltaT:</b>.
  @return Returns a double.
*/
- (double) localDeltaT;

/*!
  @brief Sets the local delta time for all MKOrchestras and changes the
  default, which is otherwise 0.0.
  @param  val is a double.
  @return Returns an id.
*/
+ setLocalDeltaT: (double) val;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief Sets whether the receiver, which must be
  closed, sends its sound signal to the host DAC, as <i>yesOrNo</i> is
  YES or NO.

  Returns the receiver, or <b>nil</b> if it isn't closed. 
  On NeXT hardware, the default is to send sound to the host
  DAC.
  
  Sending <b>setHostSoundOut:YES</b> also sends <b>setOutputSoundfile: nil</b>;
  you can't write samples to a soundfile and to the DAC at the same time.
  Sending <b>setHostSoundOut:YES</b> also sends s<b>etSerialSoundOut: NO</b>;
  you can't write samples to the DSP serial port and to the DAC at the same time.
*/
- setHostSoundOut: (BOOL) yesOrNo;

- (BOOL) hostSoundOut;

- setSoundOut: (BOOL) yesOrNo;

/*!
  @brief Sets whether the receiver, which must be closed, receives sound, as <i>yesOrNo</i> is YES or NO.
  @param  yesOrNo is a BOOL.
  @return Returns the receiver, or <b>nil</b> if it isn't closed.
 */
- setSoundIn: (BOOL) yesOrNo;

/*!
  @brief Sets whether soundIn is enabled.
  @return Returns a BOOL.
 */
- (BOOL) soundIn;

/*!
  @brief Sets extra debugging information during orchestra synthesis to printed.
  
  Used to be setOnChipMemoryDebug:patchPoints:.
 */
- (void) setDebug: (BOOL) yesOrNo;

/*!
  @brief Sets the soundfile to which sound samples are written.

  The receiver must be closed; <b>nil</b> is returned if it's open, otherwise
  returns the receiver.  A copy of <i>fileName</i> is stored in the
  instance variable <i>outputSoundfile</i>.    If you re-run the
  MKOrchestra, the file is rewritten. To specify that you no longer want
  to write a file when the MKOrchestra is re-run, close the MKOrchestra,
  then send <b>setOutputSoundfile:NULL</b>.  When switching from
  soundfile writing to other forms of sound output,  note that you
  must explicitly send <b>setHostSoundOut:YES</b>or <b>
  setSerialSoundOut:YES </b>after setting the output soundfile to
  NULL. 
  
  It is not permissable to have an output soundfile open and do host
  or serial port sound output at the same time.  
  @param  fileName is an NSString instance.
  @return Returns an id.
*/
- setOutputSoundfile: (NSString *) fileName;

/*!
  @brief Returns a pointer to the name of the receiver's output soundfile, or nil if none.
  @return Returns an NSString instance.
*/
- (NSString *) outputSoundfile;

-setOutputSoundDelegate:aDelegate;
-outputSoundDelegate;

/*!
  @param  fileName is an NSString instance.
  @return Returns an id.
  @brief Sets a file name to which DSP commands are to be written as a DSP
  Commands format soundfile.

  A copy of the fileName is stored in the
  instance variable <i>outputCommandsFile</i>.   This message is
  ignored if the receiver is not closed.  Playing of DSP Commands
  format soundfiles is currently (1995) implemented only for NeXT
  hardware.
*/
- setOutputCommandsFile: (NSString *) fileName;

/*!
  @return Returns a NSString.
  @brief Returns the output soundfile or <b>nil</b> if none.
*/
- (NSString *) outputCommandsFile;

/*!
  @param  classObj is an id.
  @return Returns an id.
  @brief Allocates a MKUnitGenerator of class <i>classObj</i>.

  The object is allocated on the first MKOrchestra that can accomodate it.  Returns
  the MKUnitGenerator, or <b>nil</b> if the object couldn't be
  allocated.
*/
+ allocUnitGenerator: (id) classObj; // (Class) classObj 

/*!
  @param  segment is a MKOrchMemSegment.
  @param  size is an unsigned.
  @return Returns an id.
  @brief Allocates a MKSynthData object.

  The allocation is on the first
  MKOrchestra that will accommodate <i>size</i> words in segment
  <i>segment</i>.  Returns the MKSynthData, or <b>nil</b> if the object
  couldn't be allocated.
*/
+ allocSynthData: (MKOrchMemSegment) segment length: (unsigned) size; 

/*!
  @brief Allocates a patchpoint in segment <i>segment</i> Returns the
  patchpoint (a MKSynthData object), or <b>nil</b> if the object
  couldn't be allocated.
  @param  segment is a MKOrchMemSegment.
  @return Returns an id.
*/
+ allocPatchpoint: (MKOrchMemSegment) segment; 

/*!
  @brief This is the same as <b>allocSynthPatch:patchTemplate:</b> but uses
  the default template obtained by sending the message
  <b>defaultPatchTemplate</b> to <i>aSynthPatchClass.</i>
  @param  aSynthPatchClass is an id.
  @return Returns an id.
*/
+ allocSynthPatch: (id) aSynthPatchClass;  // (Class) aSynthPatchClass 

/*!
  @brief Allocates a MKSynthPatch with a MKPatchTemplate of <i>p</i> on the first
  DSP with sufficient resources.

  Returns the MKSynthPatch or <b>nil</b> if it couldn't be allocated.
  @param  aSynthPatchClass is an id.
  @param  p is an id.
  @return Returns an id.
*/
+ allocSynthPatch: (id) aSynthPatchClass patchTemplate: (id) p;

/*!
  @brief Deallocates the argument, which must be a previously allocated
  MKSynthPatch, MKUnitGenerator or MKSynthData, by sending it the
  <b>dealloc</b> message.

  This method is provided for symmetry with
  the <b>alloc</b>family of methods.
  @param  aSynthResource is an id.
  @return Returns an id.
*/
+ dealloc: (id) aSynthResource;

/*!
  @brief Sends buffered DSP commands to the DSP.

  This is done for you by the MKConductor.  However, if your application sends messages directly to
  a MKSynthPatch or MKUnitGenerator without the assistance of a MKConductor,
  you must invoke this method yourself (after sending the synthesis
  messages). The usual way to invoke this method is via the
  MKConductor <b>+unlockPerformance</b> method (which must be preceeded
  by <b>+lockPerformance</b>). Note that you must send flushTimedMessages even if the MKOrchestra is set to
  MK_UNTIMED mode ("flushTimedMessages" is somewhat of a misnomer; a
  better name would have been "sendBufferedDSPCommands").
  @return Returns the receiver.
*/
- flushTimedMessages;

+ (int) sharedTypeForName: (char *) str;
+ (char *) nameForSharedType: (int) typeInt;

/*!
  @brief Places <i>aSynthObj</i> on the shared object table and sets its reference count to 1.

  <i>aKeyObj</i> is  any object associated with
  the abstract notion of the data and is used to index the shared
  object.  Does nothing and returns <b>nil</b> if the <i>aSynthObj</i>
  is already present in the table.  Also returns <b>nil</b> if the
  orchestra isn't open.  Otherwise, returns the receiver.
  
  This method differs from <b>installSharedObjectWithSegmentAndLength:for:</b> 
  in that the length and segment are wild cards.
  @param  aSynthObj is an id.
  @param  aKeyObj is an id.
  @return Returns an id.
*/
- installSharedObject: (id) aSynthObj for: (id) aKeyObj;

/*!
  @brief Places <i>aSynthObj</i> on the shared object table and sets its
  reference count to 1.

  <i>aKeyObj</i> is used to index the shared
  object.  <i>type</i> is used to specify additional details about the
  data that is being installed.  For example, oscillator tables are
  intsalled as type <b>MK_oscTable</b>, while waveshaping tables are
  installed as <b>MK_waveshapingTable</b>. Waveguide physical model
  excitation tables are installed as <b>MK_excitationTable.</b> <i>type</i>
  makes it possible to use <i>aKeyObj</i> to lookup various
  different types of Synth objects.  Does nothing and returns
  <b>nil</b> if the <i>aSynthObj</i> is already present in the table. 
  Also returns <b>nil</b> if the orchestra isn't open.  Otherwise,
  returns the receiver.
  
  This method differs from <b>installSharedObjectWithSegmentAndLength:for:</b>
  in that the length and segment are wild cards.
  @param  aSynthObj is an id.
  @param  aKeyObj is an id.
  @param  aType is a MKOrchSharedType.
  @return Returns an id.
 */
- installSharedObject: (id) aSynthObj for: (id) aKeyObj type: (MKOrchSharedType) aType;

/*!
  segment specified by <i>aSynthDataObj</i> and sets its reference
  count to 1.

  Does nothing and returns <b>nil</b> if the
  <i>aSynthObj</i> is already present in the table.  Also returns
  <b>nil</b> if the orchestra is not open.  Otherwise, returns the
  receiver.
  
  This method differs from <b>installSharedObjectWithSegmentAndLength:for:</b> in that the length is a wild card.
  @param  aSynthDataObj is an id.
  @param  aKeyObj is an id.
  @return Returns an id.
  @brief Places <i>aSynthDataObj</i> on the shared object table in the
 */
- installSharedSynthDataWithSegment: (id) aSynthDataObj for: (id) aKeyObj;

/*!
  @brief Places <i>aSynthDataObj</i> on the shared object table in the
  segment specified by <i>aSynthDataObj</i> and sets its reference
  count to 1.

  Does nothing and returns <b>nil</b> if the
  <i>aSynthObj</i> is already present in the table.  Also returns
  <b>nil</b> if the orchestra is not open.  Otherwise, returns the
  receiver.
  
  This method differs from <b>installSharedObjectWithSegmentAndLength:for:</b> in that the length
  is a wild card.
  @param  aSynthDataObj is an id.
  @param  aKeyObj is an id.
  @param  aType is an MKOrchSharedType.
  @return Returns an id.
 */
- installSharedSynthDataWithSegment: (id) aSynthDataObj 
				for: (id) aKeyObj 
			       type: (MKOrchSharedType) aType;

- installSharedSynthDataWithSegmentAndLength: (MKSynthData *) aSynthDataObj
					 for: (id) aKeyObj;

/*!
  @brief Places <i>aSynthDataObj</i> on the shared object table in the
  segment of aSynthDataObj with the specified length and sets its
  reference count to 1.

  <i>aKeyObj</i> is used to index the shared
  object.  Does nothing and returns <b>nil</b> if the
  <i>aSynthDataObj</i> is already present in the table.  Also returns
  <b>nil</b> if the orchestra is not open.  Otherwise, returns the
  receiver.
 @param  aSynthDataObj is an id.
 @param  aKeyObj is an id.
 @param  aType is an MKOrchSharedType.
 @return Returns an id. 
*/
- installSharedSynthDataWithSegmentAndLength: (MKSynthData *) aSynthDataObj
					 for: (id) aKeyObj
					type: (MKOrchSharedType) aType;

/*!
  @brief Returns, from the receiver's shared object table, the MKSynthData,
  MKUnitGenerator, or MKSynthPatch object that's indexed by <i>aKeyObj</i>
  If the object is found,  <i>aKeyObj</i>'s reference count is
  incremented.

  If it isn't found, or if the receiver isn't open,
  returns <b>nil</b>.
  @param  aKeyObj is an id.
  @return Returns an id.
*/
- sharedObjectFor: (id) aKeyObj;

/*!
  @brief Returns, from the receiver's shared object table, the MKSynthData,
  MKUnitGenerator, or MKSynthPatch object that's indexed by
  <i>aKeyObj.</i> <i> </i> The object must be allocated with the
  specified type.

  If the object is found,  <i>aKeyObj</i>'s reference
  count is incremented. If it isn't found, or if the receiver isn't
  open, returns <b>nil</b>.
 @param  aKeyObj is an id.
 @param  aType is a MKOrchSharedType.
 @return Returns an id.
 */
- sharedObjectFor: (id) aKeyObj type: (MKOrchSharedType) aType;

/*!
  @brief Returns, from the receiver's shared data table, the MKSynthData,
  MKUnitGenerator, or MKSynthPatch object that's indexed by
  <i>aKeyObj</i>.

  The object must be allocated in the specifed
  segment.  <i>aKeyObj</i> on the receiver in the specified segment. 
  If the object is found, <i>aKeyObj</i>'s reference count is
  incremented.  If it isn't found, or if the receiver isn't open,
  returns <b>nil</b>.
  @param  aKeyObj is an id.
  @param  whichSegment is a MKOrchMemSegment.
  @return Returns an id.
*/
- sharedSynthDataFor: (id) aKeyObj segment: (MKOrchMemSegment) whichSegment;

/*!
  @brief Returns, from the receiver's shared data table, the MKSynthData,
  MKUnitGenerator, or MKSynthPatch object that's indexed by
  <i>aKeyObj</i>.

  The object must be allocated in the specifed
  segment.  <i>aKeyObj</i> on the receiver in the specified segment. 
  If the object is found, <i>aKeyObj</i>'s reference count is
  incremented.  If it isn't found, or if the receiver isn't open,
  returns <b>nil</b>.
  @param  aKeyObj is an id.
  @param  whichSegment is a MKOrchMemSegment.
  @param  aType is a MKOrchSharedType.
  @return Returns an id.
*/
- sharedSynthDataFor: (id) aKeyObj 
	     segment: (MKOrchMemSegment) whichSegment
		type: (MKOrchSharedType) aType; 

/*!
  @brief Returns, from the receiver's shared data table, the MKSynthData,
  MKUnitGenerator, or MKSynthPatch object that's indexed by
  <i>aKeyObj</i>.

  The object must be allocated in the specifed
  segment.  <i>aKeyObj</i> on the receiver in the specified segment. 
  If the object is found, <i>aKeyObj</i>'s reference count is
  incremented.  If it isn't found, or if the receiver isn't open,
  returns <b>nil</b>.
  @param  aKeyObj is an id.
  @param  whichSegment is a MKOrchMemSegment.
  @param  length is an integer.
  @return Returns an id.
*/
- sharedSynthDataFor: (id) aKeyObj
	     segment: (MKOrchMemSegment) whichSegment 
	      length: (int) length;

/*!
  @brief Returns, from the receiver's shared data table, the MKSynthData,
  MKUnitGenerator, or MKSynthPatch object that's indexed by
  <i>aKeyObj</i>.

  The object must be allocated in the specifed
  segment, have a length of <i>length</i>and have a type <i>type</i> .
  <i>aKeyObj</i> on the receiver in the specified segment.  If the
  object is found, <i>aKeyObj</i>'s reference count is incremented. 
  If it isn't found, or if the receiver isn't open, returns
  <b>nil</b>.
  @param  aKeyObj is an id.
  @param  whichSegment is a MKOrchMemSegment.
  @param  length is an int.
  @param  aType is a MKOrchSharedType.
  @return Returns an id.
 */
- sharedSynthDataFor: (id) aKeyObj
	     segment: (MKOrchMemSegment) whichSegment
	      length: (int) length
		type: (MKOrchSharedType) aType; 

/*!
  @return Returns an id.
  @brief Returns a MKSynthData object representing the SineROM.

  You should
  never deallocate this object.
*/
- sineROM; 

/*!
  @return Returns an id.
  @brief Returns a MKSynthData object representing the MuLawROM.

  You should
  never deallocate this object.
*/
- muLawROM; 

/*!
  @param  segment is a MKOrchMemSegment.
  @return Returns an id.
  @brief Returns a special pre-allocated patchpoint (a MKSynthData) in the
  specified segment that always holds 0 and to which, by convention,
  nothing is ever written.

  The patchpoint shouldn't be deallocated. 
  <i>segment</i> can be MK_xPatch or MK_yPatch.
*/
- segmentZero: (MKOrchMemSegment) segment; 

/*!
  @param  segment is a MKOrchMemSegment.
  @return Returns an id.
  @brief Returns a special pre-allocated patchpoint (a MKSynthData) in the
  specified segment which may be used to write garbage.

  It's commonly
  used as a place to send the output of idle MKUnitGenerators.  The
  patchpoint shouldn't be deallocated.  <i>segment</i> can be
  MK_xPatch or MK_yPatch.
*/
- segmentSink: (MKOrchMemSegment) segment; 

/*!
  @param  segment is a MKOrchMemSegment.
  @return Returns an id.
  @brief Returns a special pre-allocated patchpoint (a MKSynthData) in the
  specified segment, aligned for modulus addressing, which may be used
  to write garbage.

  It's commonly used as a place to send the output
  of idle MKUnitGenerators.  The patchpoint shouldn't be deallocated. 
  <i>segment</i> can be MK_xPatch or MK_yPatch.
*/
- segmentSinkModulus: (MKOrchMemSegment) segment; 

/*!
  @return Returns an id.
  @brief Opens the receiver's DSP and sets the receiver's status to
  MK_devOpen.

  Resets orchestra loop (if not already reset), freeing
  all Unit Generators and MKSynthPatches.  Returns <b>nil</b> if the DSP
  can't be opened for some reason,  otherwise returns the receiver.  
  To find out why the DSP can't be opened, enable Music Kit or DSP
  error tracing.  Possible problems opening the DSP include another
  application using the DSP, a missing DSP monitor file, a version
  mismatch and missing or broken hardware. 
*/
- open; 

/*!
  @return Returns an id.
  @brief Starts the clock on the receiver's DSP, thus allowing the processor
  to begin executing commands, and sets the receiver's status to
  MK_devRunning.

  This opens the DSP if it isn't already open. 
  Returns <b>nil</b> if the DSP couldn't be opened or run, otherwise
  returns the receiver.
*/
- run; 

/*!
  @return Returns an id.
  @brief Stops the clock on the receiver's DSP, thus halting execution of
  commands, and sets the receiver's status to MK_devStopped.

  This
  opens the DSP if it isn't already open.  Returns <b>nil</b> if an
  error occurs, otherwise returns the receiver.
*/
- stop; 

/*!
  @return Returns an id.
  @brief Waits for all enqueued DSP commands to be executed.

  Then severs
  communication with the DSP, allowing other processes to claim it. 
  The MKSynthPatch-allocated MKUnitGenerators and MKSynthInstrument-allocated MKSynthPatches are freed.  All MKSynthPatches must be idle and non-MKSynthPatch-allocated MKUnitGenerators must be deallocated before sending this message.  Returns <b>nil</b> if an error occurs, otherwise returns the receiver.
*/
- close; 

/*!
  @return Returns an id.
  @brief This is the same as <b>close</b>, except that it doesn't wait for
  enqueued DSP commands to be executed.

  Returns <b>nil</b> if an
  error occurs, otherwise returns the receiver.
*/
- abort;

- useDSP: (BOOL) useIt; 
- (BOOL) isDSPUsed; 

/*!
  @param  typeOfInfo is an int.
  @param  fmt,... is a char *.
  @return Returns an id.
  @brief Used to print debugging information.

  The arguments to the <b>msg:</b> keyword are like those to <b>printf()</b>.  If the
  <i>typeOfInfo</i> trace is set, prints to stderr.  
*/
- trace: (int) typeOfInfo msg: (NSString *) fmt,...; 

/*!
  @brief Returns a pointer to the name of the specified MKOrchMemSegment.
  
  The name is not copied and should not be freed.
  @param  whichSegment is an int.
  @return Returns an NSString instance.
*/
- (NSString *) segmentName: (int) whichSegment; 

/*!
  @return Returns an unsigned short.
  @brief Returns the index of the DSP associated with the receiver.
  
  Used to be named index.
*/
- (unsigned short) orchestraIndex; 

/*!
  @brief Returns the compute time estimate currently used by the receiver in
  seconds per sample.
  @return Returns a double.
*/
- (double) computeTime; 

/*!
  @brief Same as <b>allocSynthPatch:patchTemplate:</b> but uses the default
  template, obtained by sending the message <b>defaultPatchTemplate</b> to <i>aSynthPatchClass</i>.
  @param  aSynthPatchClass is an id.
  @return Returns an id.
*/
- allocSynthPatch: (id) aSynthPatchClass; 

/*!
  @brief Allocates and returns a MKSynthPatch for MKPatchTemplate <i>p</i>.

  The receiver first tries to find an idle MKSynthPatch; failing that, it
  creates and returns a new one.  The MKUnitGenerators are added to the
  SynthPatch's unitGenerators list in the same order they are
  specified in the MKPatchTemplate.  If a new MKSynthPatch can't be built,
  this method returns <b>nil</b>.
  @param  aSynthPatchClass is an id.
  @param  p is an id.
  @return Returns an id.
 */
- allocSynthPatch: (id) aSynthPatchClass patchTemplate: (id) p; 

/*!
  @brief Allocates and returns a MKUnitGenerator of the specified class,
  creating a new one, if necessary.
  @param  aClass is an id.
  @return Returns an id.
*/
- allocUnitGenerator: (id) aClass; 

/*!
  @brief Allocates and returns a MKUnitGenerator of the specified class.

  The newly allocated object will execute before <i>aUnitGeneratorInstance</i>.
  @param  aClass is an id.
  @param  aUnitGeneratorInstance is an id.
  @return Returns an id.
*/
- allocUnitGenerator: (id) aClass before: (id) aUnitGeneratorInstance; 

/*!
  @brief Allocates and returns a MKUnitGenerator of the specified class.

  The newly allocated object will execute after <i>aUnitGeneratorInstance</i>.
  @param  aClass is an id.
  @param  aUnitGeneratorInstance is an id.
  @return Returns an id. 
 */
- allocUnitGenerator: (id) aClass after: (id) aUnitGeneratorInstance; 

/*!
  @brief Allocates and returns an MKUnitGenerator of the specified class.

  The newly allocated object will execute immediately after
  <i>aUnitGeneratorInstance</i> and before <i>anotherUnitGenerator</i>.
  @param  aClass is an id.
  @param  aUnitGeneratorInstance is an id.
  @param  anotherUnitGeneratorInstance is an id.
  @return Returns an id.
 */
- allocUnitGenerator: (id) aClass between: (id) aUnitGeneratorInstance : (id) anotherUnitGeneratorInstance;

- (NSString *) lastAllocationFailureString;

/*!
  @brief Allocates and returns a new MKSynthData object with the specified
  length, or <b>nil</b> if the receiver doesn't have sufficient
  resources, if <i>size</i> is 0, or if an illegal segment is
  requested.

  <i>segment</i> should be MK_xData or MK_yData.
  @param  segment is a MKOrchMemSegment.
  @param  size is an unsigned.
  @return Returns an id.
 */
- allocSynthData: (MKOrchMemSegment) segment length: (unsigned) size; 

/*!
  @brief Allocates and returns a MKSynthData to be used as a patchpoint in the
  specified segment (MK_xPatch or MK_yPatch).

  Returns <b>nil</b> if an illegal segment is requested.
  @param  segment is a MKOrchMemSegment.
  @return Returns an id.
*/
- allocPatchpoint: (MKOrchMemSegment) segment; 

/*!
  @brief Deallocates <i>aSynthResource</i> by sending it the <b>dealloc</b>
  message.

  <i>aSynthResource</i> may be a MKUnitGenerator, a MKSynthData
  or a MKSynthPatch.  This method is provided for symmetry with the
  <b>alloc</b> family of methods.
  @param  aSynthResource is an id.
  @return Returns an id.
*/
- dealloc: (id) aSynthResource;

/*!
  @brief Returns <b>YES</b> if the receiver runs in real time.

  This will be <b>YES</b> if any of soundOut, serialSoundOut or soundIn is
  <b>YES</b>.  Subclasses may want to override this method.
  @return Returns a BOOL.
*/
- (BOOL) isRealTime;


/*!
  @brief Returns YES if the DSP or driver supports the specified sampling
  rate (or half that rate).

  The implementation forwards the message
  <b>supportsSamplingRate:</b> to the serial port device, if
  serialSoundOut or soundIn is enabled.  Otherwise, for NeXT
  hardware, it returns YES if aRate is 22050 or 44100.  A subclass may
  override this method.
  @param  rate is a double.
  @return Returns a BOOL.
*/
- (BOOL) supportsSamplingRate: (double) rate;

- (int) hardwareSupportedSamplingRates: (double **) arr;

/*!
  @return Returns a double.
  @brief Returns the default sampling rate for the driver or hardware
  corresponding to this MKOrchestra instance's DSP.

  If serialSoundOut
  or soundIn is enabled, this method simply forwards the
  <b>defaultSamplingRate</b> message to the DSPSerialPortDevice
  object.  Otherwise, returns 22050.0.  Note that you may change the
  sampling rate using <b>setSamplingRate:</b>, but the default will
  still remain the same.  A subclass may override this method to
  provide a different default.
*/
- (double) defaultSamplingRate;

/*!
  @return Returns a BOOL.
  @brief Returns YES if the MKOrchestra will do better with a lower sampling
  rate than is ordinarily needed.

  The default implementation returns
  YES if the driver parameter "WaitStates" is "3".  This is to
  accomodate the Multisound card.
*/
- (BOOL) prefersAlternativeSamplingRate;

+ setAbortNotification: aDelegate;

/*!
  @brief Resets serialSoundOut, hostSoundOut, serialPortDevice, etc. to
  produce the "default sound output" for the given hardware.
 
  On NeXT hardware, the default sound output is the NeXT monitor's DAC. On
  Intel-based hardware, this method sets up the card with the default
  serial port device, if any.
  @return Returns an id.
*/
- setDefaultSoundOut;

/*!
 @brief These constants define the Orchestra capabilities bits returned by the Orchestra <b>capabilities </b>method.
 */
#define MK_nextCompatibleDSPPort 1
#define MK_hostSoundOut (1<<1)
#define MK_serialSoundOut (1<<2)
#define MK_soundIn (1<<3)
#define MK_soundfileOut (1<<4)

/*!
  @return Returns an unsigned.
  @brief returns an unsigned int, the bits of which report what capabilities
  are provided by the DSP device corresponding to the MKOrchestra.

  Possible values (defined in MKOrchestra.h) are as follows:
<tt>
#define MK_nextCompatibleDSPPort 1
#define MK_hostSoundOut (1<<1)
#define MK_serialSoundOut (1<<2)
#define MK_soundIn (1<<3)
#define MK_soundfileOut (1<<4)
</tt> 
*/
- (unsigned) capabilities;

/*!
  @brief Returns the number of output channels.

  This information is normally derived from the serial port device,
  if any, or it defaults to 2. 
  However, subclasses may override this method.  For example, the
  ArielQPSat class, when sending its sound to the hub DSP, forwards
  this message to the ArielQP obect that represents the hub DSP.
  @return Returns an int.
*/
- (int) outputChannelCount;

/*!
  @brief When sending sound to the DSP serial port, the sound
  may need to be up-sampled if the current sampling rate is supported
  by the serial port device only as a "half sampling rate" @see
  DSPSerialPortDevice for more info).
 
  Subclasses may override this method. For example, the ArielQPSat
  class, when sending its sound to the hub DSP, forwards this message
  to the ArielQP obect that represents the hub DSP.
  @return Returns YES if we are upsampling the sound before sending it to its output location.
*/
- (BOOL) upSamplingOutput;

/*!
  @brief A subclass may implement this message.

  It is sent after boot and before sound out is started.
  The default implementation does nothing.
  @return Returns an id.
*/
- setUpDSP;

/*!
  @brief Returns YES.

  Subclass can override, if desired.  For example, the
  ArielQP class overrides this method to return NO.
  @return Returns a BOOL.
*/
- (BOOL) startSoundWhenOpening;

/*!
  @brief Used by subclasses to register themselves as the default class for
  the specified DSP index.

  This allows the user to say <b>[MKOrchestra orchestraOnDSP:3]</b> and get an
  instance of <b>ArielQPSat</b>, for example.
  @param  classObject is an id.
  @param  index is an int.
  @return Returns an id.
 */
+ registerOrchestraSubclass: (id) classObject forOrchIndex: (int) index;

- segmentInputSoundfile: (MKOrchMemSegment) segment;
- setInputSoundfile: (NSString *) file;
- (NSString *) inputSoundfile;
- pauseInputSoundfile;
- resumeInputSoundfile;

/*!
  @brief Drivers now refer to independently addressable sound ports which consist of 1 or more channels
  of sound.

  Returns those drivers returned by the SndKit.
  @return Returns an NSArray of driver names.
 */
+ (NSArray *) getDriverNames;

/*!
  @brief Returns the name of the sound driver associated with this instance of MKOrchestra.

  The string is copied.   
  @return Returns a NSString instance.
*/
- (NSString *) driverName;

/*!
  @brief &lt;&lt;Intel-based hardware only&gt;&gt; Returns the unit of the
  DSP driver associated with this instance of MKOrchestra.
  @return Returns an int.
*/
- (int) driverUnit;

- (int) driverSubUnit;

/*!
  @brief &lt;&lt;Intel-based hardware only&gt;&gt; Returns the parameter
  value of the specified driver parameter for the driver associated
  with the given index of MKOrchestra.

  The string is not copied and should not be freed.   
 @param  parameterName is a NSString.
 @param  index is an unsigned short.
 @return Returns an NSString.
 */
+ (NSString *) driverParameter: (NSString *) parameterName forOrchIndex: (unsigned short) index;

/*!
  @brief &lt;&lt;Intel-based hardware only&gt;&gt; Returns the parameter
  value of the specified driver parameter for the driver associated
  with this instance of MKOrchestra.

  The string is not copied and should not be freed.   
  @param  parameterName is an NSString.
  @return Returns an NSString.
*/
- (NSString *) driverParameter: (NSString *) parameterName;

- awaitEndOfTime: (double) endOfTime timeStamp: (DSPTimeStamp *) aTimeStampP;

- setSimulatorFile: (char *) filename;
- (char *) simulatorFile;

- sharedObjectFor: aKeyObj segment: (MKOrchMemSegment) whichSegment length: (int) length;
- sharedObjectFor: aKeyObj segment: (MKOrchMemSegment) whichSegment;

@end

@interface OrchestraDelegate : NSObject

-orchestra: (id) sender didRecordData: (short *) data size: (unsigned int) dataCount;

@end

#endif
