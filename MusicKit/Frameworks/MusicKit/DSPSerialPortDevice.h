/*
  $Id$
  Defined In: The MusicKit

  Description:
    Serial port delegate of MKOrchestra. See the discussion below. With the demise
    of the NeXT hardware, this class becomes an example of DSP operation. In theory it still works.
    
  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 CCRMA, Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*
  $Log$
  Revision 1.5  2001/09/07 00:11:46  leighsmith
  Correctly added headerdoc comments

  Revision 1.4  2001/09/06 21:27:47  leighsmith
  Merged RTF Reference documentation into headerdoc comments and prepended MK to any older class names

  Revision 1.3  2001/03/12 01:56:54  leigh
  Typed orch to avoid warnings

  Revision 1.2  1999/07/29 01:25:42  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
/*!
  @class DSPSerialPortDevice
  @discussion

The DSPSerialPortDevice class corresponds to a device that plugs into the DSP
serial port.   Instantiating an instance of the DSPSerialPortDevice class itself
provides you with a serial port protocol that is used by many devices such as
the Ariel Digital Microphone and the Metaresearch Digital Ears.  For other
devices that don't follow that protocol, or for access to "customization"
commands, you may instantiate an instance of a subclass of DSPSerialPortDevice. 
The Music Kit provides a number of such subclasses:

SSAD64x	Singular Solutions AD64x ADC &amp; DAT interface.
StealthDAI2400	Stealth DAI2400 DAT interface.
ArielProPort	Ariel ProPort interface.

These class descriptions appear at the end of this document.  The file
DSPSerialPortDevice.h contains the interface declarations for these classes.  It
also contains defines for "classes" that are fully represented by the
DSPSerialPortDevice class itself:

ArielDigitalMic 	Ariel Digital Microphone 
MRDigitalEars	Metaresearch Digital Ears 

To use a DSPSerialPortDevice or subclass instance, you simply send the orchestra
instance the message <b>setSerialPortDevice:</b><i></i> with an argument of your
DSPSerialPortDevice instance.    In order to access the device for sound output,
you must also send to the orchestra the message <b>setSerialSoundOut:YES</b>.  
Similarly, to access the device for sound input, you must send the orchestra
<b>setSerialSoundIn:YES</b>.   To find out if you can use a particular sampling
rates, you send the message <b>supportsSamplingRate:</b> to the
DSPSerialPortDevice or subclass instance.  To find the default sampling rate,
send it the message <b>defaultSamplingRate</b>.

To implement a new DSPSerialPortDevice subclass for a new device, you override a
number of methods. The most important is <b>setUpSerialPort:</b>.   Other
methods you might want to override include <b>hardwareSupportedSamplingRates:</b>, <b>inputSampleSkip </b>and <b>outputSampleSkip</b>. 

The DSPSerialPortDevice class also supports "half sampling rates".   For
example, if the hardware supports 44100, 48000 and 32000, then the Music Kit
software will also allow the device to be used at 22050, 42000 and 16000.  
These half sampling rates are entirely automatic - the designer of a subclass
need not think about this at all.   He need only implement <b>hardwareSupportedSamplingRates:</b>.  

If you have several Orchestra instances (for example, if you have a cube with an
Ariel QuintProcessor) and each has its own serial port, each can have its own
instance of DSPSerialPortDevice or one of its subclasses.
*/
#ifndef __MK_DSPSerialPortDevice_H___
#define __MK_DSPSerialPortDevice_H___
#import <Foundation/NSObject.h>

@interface DSPSerialPortDevice:NSObject 
{
    BOOL sendsSettings;
}

#define ArielDigitalMic DSPSerialPortDevice /* Generic version works fine */
#define MRDigitalEars DSPSerialPortDevice   /* Generic version works fine */


/*!
  @method setUpSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to set up the serial port.   A
              subclass may override this method to provide appropriate values. 
              The default version of this method uses these settings: scr = 0x302,
              sccr = 0x18, cra = 0x4100 and crb = 0xa00.   If sendsSettings is NO,
              does not set scr or sccr.  See the DSP56001 manual for details.  A
              subclass may also override this method and invoke the orchestra
              method <b>sendSCIByte:</b> to send a command to the device hardware.
                
*/
-setUpSerialPort:orchestra;

-init;

/*!
  @method setSendsSettings:
  @param  yesOrNo is a BOOL.
  @result Returns an id.
  @discussion Set whether settings, such as the sampling rate are sent by the
              object (via the SCI port) to the device.  It is up to the subclass
              implementation of setUpSerialPort: to support this flag.   The
              default value is YES.
*/
-setSendsSettings:(BOOL)yesOrNo;

/*!
  @method sendsSettings
  @result Returns a BOOL.
  @discussion Returns value of sendsSettings instance variable.
*/
-(BOOL)sendsSettings;

/*!
  @method supportsSamplingRate:
  @param  rate is a double.
  @result Returns a BOOL.
  @discussion This method returns YES if the device supports the specified
              sampling rate or if that sampling rate is obtainable as half of one
              of the sampling rates the device supports.  This method is
              implemented as: 	
              	
              <tt>
              return ([self hardwareSupportsSamplingRate:rate] ||	
                      [self hardwareSupportsSamplingRate:rate*2])
              </tt>
               
              Subclass should not override this method, but should implement <b>hardwareSupportedSamplingRates: </b>instead.
*/
-(BOOL)supportsSamplingRate:(double)rate;

/*!
  @method hardwareSupportsSamplingRate:
  @param  rate is a double.
  @result Returns a BOOL.
  @discussion This returns YES if rate is a sampling rate actually supported by
              the device.   Does not return YES for half sampling rates.  A
              subclass should not override this method.
*/
-(BOOL)hardwareSupportsSamplingRate:(double)rate;

/*!
  @method hardwareSupportedSamplingRates:
  @param  rates is a double **.
  @result Returns an int.
  @discussion This method mallocs and returns in <i>*rates</i> an array of
              sampling rates supported by the hardware.  In addition, it returns
              the length of the array.  A subclass may override this
              method.
*/
-(int)hardwareSupportedSamplingRates:(double **)ar ;

/*!
  @method supportsHalfSamplingRate:
  @param  rate is a double.
  @result Returns a BOOL.
  @discussion This returns YES if rate is available only as half of one of the
              sampling rates supported by the hardware.  Implemented
              as:
              <tt>
              return ([self supportsSamplingRate:rate] &amp;&amp;
                         ![self hardwareSupportsSamplingRate:rate]);
              </tt>
              
              Subclass should not override this method, but should implement <b>hardwareSupportedSamplingRates:</b> instead.
*/
-(BOOL)supportsHalfSamplingRate:(double)rate;

/*!
  @method defaultSamplingRate
  @result Returns a double.
  @discussion This method returns a default sampling rate for this device.   For
              Music Kit synthesis, this should be the lowest sampling rate (within
              reason) so that naive users have the least trouble with running out
              of DSP resources.  Half of a hardware-supported sampling rate may be
              returned.   Default version returns 22050.  A subclass may override
              this method.
*/
-(double)defaultSamplingRate;

/*!
  @method inputSampleSkip
  @result Returns an int.
  @discussion Returns samples skipped for sound input (i.e. sound entering the DSP
              via the serial port.)  Default is no skipping and this method
              returns 0.  A subclass may override this method.
*/
-(int)inputSampleSkip;

/*!
  @method outputSampleSkip
  @result Returns an int.
  @discussion Returns samples skipped for sound output (i.e. sound exiting the DSP
              via the serial port.)  Default is no skipping and this method
              returns 0.  A subclass may override this method.
*/
-(int)outputSampleSkip;

/*!
  @method inputInitialSampleSkip
  @result Returns an int.
  @discussion Returns samples initially skipped for input.   For example, if
              inputSampleSkip is 1 and the samples arrive in the DSP as
              0,&lt;sample&gt;,0,&lt;sample&gt;, then inputInitialSampleSkip
              should return 1.  On the other hand, if inputSampleSkip is 1 and the
              samples arrive in the DSP as &lt;sample&gt;,0,&lt;sample&gt;,0, then
              inputInitialSampleSkip should be 0.  Default is no initial skipping
              and this method returns 0.  A subclass may override this
              method.
*/
-(int)inputInitialSampleSkip;

/*!
  @method outputInitialSampleSkip
  @result Returns an int.
  @discussion Returns samples initially skipped for output.   For example, if
              outputSampleSkip is 1 and the samples are sent out the DSP as
              0,&lt;sample&gt;,0,&lt;sample&gt;, then outputInitialSampleSkip
              should return 1.  On the other hand, if outputSampleSkip is 1 and
              the samples are sent out the DSP as &lt;sample&gt;,0,&lt;sample&gt;,0, then outputInitialSampleSkip should be 0.  Default is no initial skipping and this method returns 0.  A subclass may override this method.
*/
-(int)outputInitialSampleSkip;

/*!
  @method inputChannelCount
  @result Returns an int.
  @discussion Returns number of input sound channels.   Default version returns 2
              for stereo.  A subclass may override this method.
*/
-(int)inputChannelCount;

/*!
  @method outputChannelCount
  @result Returns an int.
  @discussion Returns number of output sound channels.   Default version returns 2
              for stereo.  A subclass may override this method.
*/
-(int)outputChannelCount;

/*!
  @method inputPadding
  @result Returns an int.
  @discussion Returns number of extra samples to append to each input sample
              frame.  Default implementation returns 0.  Subclasses may override
              this method.
*/
-(int)inputPadding;

/*!
  @method (BOOL)setUpAfterStartingSoundOut
  @result Returns an id.
  @discussion This is invoked by Orchestra open to determine whether to send
              <b>setUpSerialPort:</b> before or after calling <b>DSPMKStartSoundOut()</b>.
              The default implementation returns YES.  Subclasses may override this method.
*/
-(BOOL)setUpAfterStartingSoundOut;

/*!
  @method unMuteSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to unmute the serial port device. 
               A subclass may override this method to provide appropriate
              behaviour, when it is inclined to produce unwanted noise after
              setting up the serial port, before the DSP produces output.  The
              default version of this method does nothing. 
*/
-unMuteSerialPort:orch;

/*!
  @method closeDownSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion Subclass may override this method to do any special muting or other
              things needed for clean shut-down.   
*/
-closeDownSerialPort:orch;

/*!
  @method adjustMonitor:forOrchestra:
  @param  system is a DSPLoadSpec *.
  @param  orchestra is an Orchestra *.
  @result Returns an id.
  @discussion Implement this to make any adjustments to the DSP monitor before it
              is loaded.  If you implement this method, you must first call
              DSPSetSystem(system); in the implementation.  Normally, it's better
              if you can make your adjustments in setUpSerialPort:.
*/
-adjustMonitor:(DSPLoadSpec *)system forOrchestra:orchestra;

@end

/*!
  @class SSAD64x
  @discussion 
The SSAD64x
class is a DSPSerialPortDevice subclass that corresponds to the Singular
Solutions AD64x ADC &amp; DAT interface.
*/
@interface SSAD64x:DSPSerialPortDevice
{
	BOOL professional;
}

/*!
  @method setProfessional:
  @param  isPro is a BOOL.
  @result Returns an id.
  @discussion Sets the <i>professional</i> instance variable to <i>isPro.</i>Then,
              when <b>setUpSerialPort: </b>   is invoked, the AD64x will be set to
              professional (AES/EBU) or consumer (SPDIF) mode, according to the
              value of <i>professional.</i>
*/
-setProfessional:(BOOL)yesOrNo;   

/*!
  @method hardwareSupportedSamplingRates:
  @param  rates is a double **.
  @result Returns an int.
  @discussion Returns 3 and sets *<i>rates</i> to a malloc'ed array containing
              48000, 44100, and 32000. 
*/
-(int)hardwareSupportedSamplingRates:(double **)ar;

/*!
  @method setUpSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to set up the serial port.   Sends
              the appropriate values for the AD64x.   If sendsSettings is YES, it
              sets the device to the proper sampling rate and professional/consumer mode setting.
*/
-setUpSerialPort:orchestra;

/*!
  @method inputSampleSkip
  @result Returns an int.
  @discussion Returns skip for sound input (i.e. sound entering the DSP via the
              serial port.)  Since the AD64x requires a zero before each sample,
              this method returns 1.
*/
-(int)inputSampleSkip;

/*!
  @method outputSampleSkip
  @result Returns an int.
  @discussion Returns skip for sound output (i.e. sound exiting the DSP via the
              serial port.)  Since the AD64x requires a zero before each sample,
              this method returns 1.
*/
-(int)outputSampleSkip;

/*!
  @method unMuteSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion Unmutes device.   
*/
-unMuteSerialPort:orch;

/*!
  @method closeDownSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion Mutes device to prevent buzzing.   
*/
-closeDownSerialPort:orch;

@end

/*!
  @class StealthDAI2400
  @discussion 
The StealthDAI2400 class is a DSPSerialPortDevice subclass that corresponds to the
Stealth DAI2400 DAT interface.
*/
@interface StealthDAI2400:DSPSerialPortDevice
{
	BOOL copyProhibit,emphasis;
}

/*!
  @method setCopyProhibit:
  @param  setCopyProhibit is a BOOL.
  @result Returns an id.
  @discussion Sets the <i>copyProhibit</i> instance variable to
              <i>setCopyProhibit.</i>   Then, when <b>applySettings:</b> is
              invoked, the StealthDAI2400 will be told to set or clear the copy
              prohibit flag.
*/
-setCopyProhibit:(BOOL)yesOrNo;

/*!
  @method setEmphasis:
  @param  useEmphasis is a BOOL.
  @result Returns an id.
  @discussion Sets the <i>empahsis</i> instance variable to <i>useEmphasis.</i>  
              Then, when <b>applySettings:</b> is invoked, the StealthDAI2400 will
              be set to whether or not to use emphasis.
*/
-setEmphasis:(BOOL)yesOrNo;

/*!
  @method hardwareSupportedSamplingRates:
  @param  rates is a double **.
  @result Returns an int.
  @discussion Returns 3 and sets *<i>rates</i> to a malloc'ed array containing 
              48000, 44100, 32000. 
*/
-(int)hardwareSupportedSamplingRates:(double **)ar;

/*!
  @method setUpSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to set up the serial port.   Sends
              the appropriate values for the StealthDAI2400.
*/
-setUpSerialPort:orchestra;

@end

/*!
  @class ArielProPort
  @discussion 
The ArielProPort class is a DSPSerialPortDevice subclass that corresponds to the
Ariel ProPort ADC/DAC interface.
*/
@interface ArielProPort:DSPSerialPortDevice
{}

/*!
  @method hardwareSupportedSamplingRates:
  @param  rates is a double.
  @result Returns an int.
  @discussion Returns 7 and sets *<i>rates</i> to a malloc'ed array containing 
              96000, 48000, 44100, 32000, 16000, 11025 or 8000.  Note that 96000
              is supported by the ProPort for input only.
*/
-(int)hardwareSupportedSamplingRates:(double **)ar;

/*!
  @method setUpSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to set up the serial port.   Sends
              the appropriate values for the ArielProPort.
*/
-setUpSerialPort:orchestra;
@end

@interface TurtleBeachMS:DSPSerialPortDevice
{}


/*!
  @method setUpSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to set up the serial port.   Sends
              the appropriate values for the TurtleBeachMS.
*/
-setUpSerialPort:orchestra;

/*!
  @method hardwareSupportedSamplingRates:
  @param  rates is a double **.
  @result Returns an int.
  @discussion Returns 3 and sets *<i>rates</i> to a malloc'ed array containing
              48000, 44100, and 32000. 
*/
-(int)hardwareSupportedSamplingRates:(double **)ar;

@end


@interface TurtleBeachFiji:DSPSerialPortDevice
{}


/*!
  @method setUpSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to set up the serial port.   Sends
              the appropriate values for the TurtleBeachFiji.
*/
-setUpSerialPort:orchestra;

/*!
  @method hardwareSupportedSamplingRates:
  @param  rates is a double **.
  @result Returns an int.
  @discussion Returns 3 and sets *<i>rates</i> to a malloc'ed array containing
              48000, 44100, and 32000. 
*/
-(int)hardwareSupportedSamplingRates:(double **)ar;
-adjustMonitor:(DSPLoadSpec *)system forOrchestra:orchestra;

@end


@interface Frankenstein:DSPSerialPortDevice
{
    unsigned long initWord1,initWord2;
    unsigned long runTimeWord1,runTimeWord2;
    int lineOutAtten,lineInGain;
    MKOrchestra *orch;
}

/* The following methods are invoked by the MKOrchestra. */

/*!
  @method setUpSerialPort:
  @param  orchestra is an id.
  @result Returns an id.
  @discussion This is invoked by Orchestra open to set up the serial port.   Sends
              the appropriate values for the TurtleBeachFiji.
*/
-setUpSerialPort:orchestra;

/*!
  @method hardwareSupportedSamplingRates:
  @param  rates is a double **.
  @result Returns an int.
  @discussion Returns 3 and sets *<i>rates</i> to a malloc'ed array containing
              48000, 44100, and 32000. 
*/
-(int)hardwareSupportedSamplingRates:(double **)ar;

/*!
  @method outputPadding
  @result Returns an int.
  @discussion Returns number of extra samples to append to each output sample
              frame.  Default implementation returns 0.  Subclasses may override
              this method.  Currently, only padding of 2 or 0 are
              supported.
*/
-(int)outputPadding;

/*!
  @method inputPadding
  @result Returns an int.
  @discussion Returns number of extra samples to append to each input sample
              frame.  Default implementation returns 0.  Subclasses may override
              this method.
*/
-(int)inputPadding;
-setLineOutAttenuation:(double)val;  /* In db from -95 to 0 */
-setLineInGain:(int)val;  /* In db from 0 to 22.5 */
-(BOOL)setUpAfterStartingSoundOut; /* Returns NO */

@end

#endif

