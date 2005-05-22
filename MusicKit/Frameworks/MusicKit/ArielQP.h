/*
  $Id$
  Defined In: The MusicKit

  Description:
    See the discussion below. With the demise of the QuintProcessor board (and NeXT hardware),
    this class becomes an example of multiple DSP operation. In theory it still works.
    
    This class is the MKOrchestra that represents the Quint Processor "hub"
    (or "master") DSP.  Creating an instance of ArielQP also creates the
    associated "satellite" DSPs ("sat" for short).  These are also called
    "slave" DSPs.  Note, however, that sending -open (or -run, etc.) to the ArielQP
    opens (or whatever) only the hub orchestra.   To send a messge to all the 
    satellite DSPs for this QuintProcessor, invoke the method makeSatellitesPerform:.
    Example:  [anArielQP makeSatellitesPerform:@selector(open)];  To send to all
    the DSPs for the QP, invoked makeQPPerform:.

    You may control whether sound from the satellite DSPs is brought into the
    hub DSP.  To control whether such sound is included or excluded, send 
    setSatSoundIn:.  The defualt is to include it.  Excluding it
    saves processing power on the hub, but means that the satellites will be useless,
    unless they send their sound out their serial port.

    If the satellite sound is included, it can be accessed via the In1qpUG MKUnitGenerator.
    Each instance of this unit generator takes sound from a particular channel on
    a particular DSP.  Note that you may have any number of these so that you can
    have multiple effects applied to the sound coming from a single source.

    For the common case of simply mixing each satellite to the output sample stream,
    a MKSynthPatch called ArielQPMix is provided in the Music Kit MKSynthPatch Library.
    This MKSynthPatch needs only to be allocated to work.   Be sure to deallocate it 
    before closing the MKOrchestra.
    
    FIXME: DRAM allocation

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.7  2005/05/22 07:34:06  leighsmith
  Corrected and updated headerdoc

  Revision 1.6  2005/05/09 15:52:49  leighsmith
  Converted headerdoc comments to doxygen comments

  Revision 1.5  2001/09/07 00:12:52  leighsmith
  Corrected naming of satellite class

  Revision 1.4  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.3  2000/03/31 00:16:44  leigh
  TODOs have become more standard FIXMEs

  Revision 1.2  1999/07/29 01:25:41  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class ArielQP
  @brief

The Ariel QuintProcessor is a board that fits into the NeXT cube.  It features
four "satellite" ("slave") DSPs with 16 or 32K of static RAM (SRAM), a hub DSP
with 8K of SRAM, a bank of dynamic RAM (DRAM) a set of serial ports, two per
DSP, and a SCSI chip.  The Music Kit supports the DSPs, the DSP ports, and the
DRAM.  It does not currently support the SCSI.

<b>ArielQP</b> class serves a dual purpose.  First it is a subclass of MKOrchestra
that represnts the hub DSP.  As such, it can be sent MKOrchestra messages such as
<b>allocUnitGenerator:</b>, <b>open</b>, <b>run</b>, etc.  Second, it
represents the Quint Processor as a whole.  The satellite DSPs are represented
by instances of the class <b>ArielQPSat</b> (see below).  Creating an instance
of ArielQP automatically creates the associated <b>ArielQPSat</b> objects.  
Freeing an <b>ArielQP</b> object frees its <b>ArielQPSat</b>
objects.

The <b>ArielQP</b> (hub DSP)  may be used as just another DSP, or it may be used
as the hub of the 5-DSP configuration.  To use it alone, send it the message
<b>setSatSoundIn:NO.</b>  In this mode, it sends and optionally receives sound
from its DSP serial port.  The satellite DSPs need not be used.  If they are
used, each sends and optionally receives sound from its serial port. Note that
in this mode you <i>must</i> have an Ariel ProPort plugged into any DSP that you
intend to use.  If you leave a DSP with no ProPort, its clock will never
advance.  Thus, for example, if you plan to use only DSP 'D', you should send
'run' to it alone, not to the MKOrchestra class.

<i>Note: The Quint Processor SCI port does not function like the NeXT DSP's SCI
port.  Therefore, when using a DSPSerialPortDevice with the QuintProcessor, you
should send setSendSettings:NO to disable sending of any commands to the SCI
port.  This implies that the only serial port device you should use with the
QuintProcess is the Ariel ProPort.</i>

To use the hub as part of a 5-DSP configuration, send the message
<b>setSatSoundIn:YES</b>to the <b>ArielQP.  </b>  The model here is of four
satellites doing synthesis or sound processing of sound received by their serial
ports and the hub merging these sounds, possibly doing more processing, and
sending the result out its serial port.  Since this is the most common way of
using the QuintProcessor, the default value of <b>satSoundIn </b>and
<b>hubSoundOut</b>are <b>YES</b> .  And since the hub is usually responsible for
sending sound to its serial port, the default value of <b>serialSoundOut</b> for
an <b>ArielQP</b> object is <b>YES.</b>  Note that in this mode you
<i>must</i> have an Ariel ProPort or equivalent plugged into DSP 'E'.

Note that <b>setSatSoundIn:YES</b>only <i>enables</i>  inter-DSP communication. 
In order to actually use the sound from the satellites, you must have one or
more instances of the unit generator <b>In1qpUG</b> running on the hub.  Each
instance provides access to one channel of sound from one of the satellite DSPs.
Multiple <b>In1qpUG</b> instances may be accessing the same satellite DSP
channel.  In addition, the Music Kit provides a MKSynthPatch for the common case
of simply adding all the satellites into the output stream.  This MKSynthPatch is
called <b>ArielQPMix</b>. Simply allocating an instance of this MKSynthPatch
immediately starts summing the satellites' sound into the hub DSP's output
stream.  You do not have to send the MKSynthPatch a MKNote.   <b>ArielQPMix</b> is
part of the Music Kit MKSynthPatch Library.

The hub has another special funtion - it alone can access the bank of DRAM.  To
access the DRAM, you need a unit generator that reads and writes the DRAM to be
running on the hub.  The Music Kit provides one such unit generator,
<b>DelayqpUG</b>, which implements a digital delay line using the DRAM.  To use
it, simply allocate one from the <b>ArielQP</b> object that represents the hub. 
<b>DelayqpUG</b> is very much like the DelayUG except that it is capable of much
longer delays.  Note that currently, the <b>ArielQP</b> class does not support
automatic allocation of DRAM - the  <b>MKSynthData</b> class is not used and the
application has to keep track of what memory it is using.  By combining
instances of In1qpUG and DelayqpUG, it is easy to make a MKSynthPatch that
reverberates the sound from the other DSPs.  Note that in the current
implemenation, the satellites do not have direct access to the DRAM.  To do
reverberation, they send their sound to the hub, either via inter-process sound
or via the DSP serial ports.  (Chaining DSP serial ports is a practical and
useful technique and is another approach to combining the power of the five
DSPs. )

The Music Kit does not automatically clear DRAM, with the exception of the
"zero" location.  If you want to clear a segment of DRAM, use a
<b>DelayqpUG</b>, set the input location to [orchestra segmentZero:MK_xPatch]
(or MK_yPatch), and let the <b>DelayqpUG</b> run for a while.  DRAM requires
periodic refreshing.  You can control whether this is "implicit" (done by the
mere accessing of the memory) or "automatic" (done by the Quint Processor
refresh hardware.)  The <b>ArielQP</b> method <b>setDRAMAutoRefresh:
</b>controls the refresh mode.  

The current version of<b> mkmon_A_qp_hub_8k.dsp</b> assumes a 256K DRAM bank. 
If you upgrade to larger DRAM, you have to change the configuration code in
<b>smsrc/reset_boot.asm</b>.

For an example of how to write a DSP unit generator that uses DRAM, see
<b>ugsrc/delayqp.asm</b>.  You should bracket any reading/writing of DRAM with
the macros <b>begin_dram_access</b> and <b>end_dram_access</b>.  See the file
<b>smsrc/qp.asm</b> for other useful QuintProcessor DSP macros.
*/
#ifndef __MK_ArielQP_H___
#define __MK_ArielQP_H___

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

/*!
  @return Returns an id.
  @brief If an ArielQP for slot 2 already exists, returns it.

  Otherwise, if
  an Ariel QuintProcessor board is installed in slot 2, creates and
  returns a new instance of ArielQP and creates, if necessary, four
  instances of ArielQPSat.  Otherwise returns nil.
*/
+new;

/*!
  @param  slot is an int.
  @return Returns an id.
  @brief If an ArielQP for the specified already exists, returns it.

  
  Otherwise, if an Ariel QuintProcessor board is installed in the
  specified, creates and returns a new instance of ArielQP and
  creates, if necessary, four instances of ArielQPSat.  Otherwise
  returns nil.  <i>&lt;&lt;Note:  In release 4.0 of the Music Kit, the
  first Ariel QuintProcessor must be in slot 2, the second must be in
  slot 4 and the third must be in slot 6. &gt;&gt;</i>
*/
+newInSlot:(unsigned short)slot;

/*!
  @brief Returns the specified satellite, which should be one of 'A', 'B', 'C', or 'D'.
  @param  which is a char.
  @return Returns an id.
*/
-satellite:(char)which;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i>, enables the hub/satellite inter-process sound
  link.

  Note that if the link is enabled, all five DSPs must be sent
  the <b>run</b> message.  Otherwise, the hub DSP will block waiting
  for sound from the satellites that are not running.   If the link is
  not enabled, then the hub does not block and the other DSPs need not
  be running.  <b>setSatSoundIn:</b> must be sent when the ArielQP and
  ArielQPSat objects are closed (i.e. before they have been sent the
  <b>-open </b>message.
*/
-setSatSoundIn:(BOOL)yesOrNo;
/* Controls whether sound is obtained from the satellites. Default is YES. */


/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i>, enables the DRAM refresh.

  If you use the macros
  provided in the file <b>smsrc/qp.asm</b>, your unit generator will
  automatically turn off refresh before accessing memory, then turn it
  on again.  Refresh is off by default.  For very low sampling rates
  or non-sequential DRAM accesses, it may be necessary to turn it on. 
  You'll know if you need to turn it on because you'll hear clicks
  and pops.
*/
- setDRAMAutoRefresh:(BOOL)yesOrNo;
/* Controls whether DRAM auto refresh is on.  Default is off. */


/*!
  @return Returns a BOOL.
  @brief Returns whether Auto Refresh is on.

  
*/
-(BOOL)DRAMAutoRefresh;

/*!
  @return Returns a BOOL.
  @brief Returns whether the hub/satellite inter-process sound link is
  enabled.

  
*/
-(BOOL)satSoundIn;

/*!
  @brief Sends the specified selector to the four ArielQPSat objects.
  @param  selector is a SEL.
  @return Returns an id.
*/
-makeSatellitesPerform:(SEL)selector;

/*!
  @brief Sends the specified selector to the four ArielQPSat objects with the
  specified argument.
  @param  selector is a SEL.
  @param  arg is an id.
  @return Returns an id.
*/
-makeSatellitesPerform:(SEL)selector with: (id) arg;

/*!
  @param  selector is a SEL.
  @return Returns an id.
  @brief Sends the specified selector to the objects representing all five
  DSPs.
*/
-makeQPPerform:(SEL)selector;

/*!
  @param  selector is a SEL.
  @param  arg is an id.
  @return Returns an id.
  @brief Sends the specified selector to the objects representing all five
  DSPs with the specified argument.
*/
- makeQPPerform: (SEL) selector with: (id) arg;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i>, enables the DRAM refresh.

  If you use the macros
  provided in the file <b>smsrc/qp.asm</b>, your unit generator will
  automatically turn off refresh before accessing memory, then turn it
  on again.  Refresh is off by default.  For very low sampling rates
  or non-sequential DRAM accesses, it may be necessary to turn it on. 
  You'll know if you need to turn it on because you'll hear clicks
  and pops.
*/
- setDRAMAutoRefresh:(BOOL)yesOrNo;

@end

#import "MusicKit.h"

/*!
  @class ArielQPSat
  @brief

The ArieQPSat objects are used to represent the
QuintProcessor's satellite DSPs, one per instance of ArielQPSat. The satellite
DSPs can either be used individually, sending their sound out their serial port
(by sending the message <b>setSerialSoundOut:YES</b>) or they can be used as a
group, sending their sound to the hub DSP (by sending the message
<b>setHubSoundOut:YES</b>.)  These two modes cannot be combined.   Sending one
message, automatically disables the other.
*/
@interface ArielQPSat:MKOrchestra
{
    BOOL hubSoundOut; /* YES if we're sending sound to the hub. */
    NSDate * _reservedArielQPSat1; //sb: changed from double
}


/*!
  @return Returns an id.
  @brief Returns the hub corresponding to this satellite.

  
*/
-hub;

/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief If <i>yesOrNo</i>, enables the hub/satellite inter-process sound
  link.

  Note that if the link is enabled, all five DSPs must be sent
  the <b>run</b> message.  Otherwise, the hub DSP will block waiting
  for sound from the satellites that are not running.   If the link is
  not enabled, then the hub does not block and the other DSPs need not
  be running.  <b>setSatSoundIn:</b> must be sent when the ArielQP and
  ArielQPSat objects are closed (i.e. before they have been sent the
  <b>-open</b> message.   Sending this message automatically sends
  <b>setSerialSoundOut:NO</b> if serialSoundOut is
  enabled.
*/
-setHubSoundOut:(BOOL)yesOrNo;
/* Default is YES. Setting hubSoundOut disables serialSoundOut.  
 * Must be invoked when the deviceStatus is closed.
 */


/*!
  @return Returns a BOOL.
  @brief Returns whether the hub/satellite inter-process sound link is
  enabled.

  
*/
-(BOOL)hubSoundOut;

/*!
  @return Returns an int.
  @brief If hub sound out, forwards this message to the hub.

  Otherwise
  invokes super's version of this method.
*/
-(int)outputChannelOffset;

/*!
  @return Returns an int.
  @brief If hub sound out, forwards this message to the hub.

  Otherwise
  invokes super's version of this method.
*/
-(int)outputChannelCount;

/*!
  @return Returns an int.
  @brief If hub sound out, forwards this message to the hub.

  Otherwise
  invokes super's version of this method.
*/
-(int)outputInitialOffset;

/*!
  @return Returns a BOOL.
  @brief If hub sound out, forwards this message to the hub.

  Otherwise
  invokes super's version of this method.
*/
-(BOOL)upSamplingOutput;

/*!
  @return Returns a BOOL.
  @brief If hub sound out, forwards this message to the hub.

  Otherwise
  invokes super's version of this method.
*/
-(BOOL)isRealTime;
/* 
 * For all of these methods:
 * if hubSoundOut, forwards message to hubOrchestra.  Otherwise,
 * invokes superclass implementation.
 */


/*!
  @param  yesOrNo is a BOOL.
  @return Returns an id.
  @brief Same as superclass method except that sending this message
  automatically sends <b>setHubSoundOut:NO</b> if hubSoundOut is
  enabled.

  
*/
-setSerialSoundOut:(BOOL)yesOrNo;

@end

#endif
