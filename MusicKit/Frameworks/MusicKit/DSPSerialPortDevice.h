/*
  $Id$

  Serial port delegate of Orchestra.
*/
/*
  $Log$
  Revision 1.2  1999/07/29 01:25:42  leigh
  Added Win32 compatibility, CVS logs, SBs changes

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

-setUpSerialPort:orchestra;
-init;
-setSendsSettings:(BOOL)yesOrNo;
-(BOOL)sendsSettings;
-(BOOL)supportsSamplingRate:(double)rate;
-(BOOL)hardwareSupportsSamplingRate:(double)rate;
-(int)hardwareSupportedSamplingRates:(double **)ar ;
-(BOOL)supportsHalfSamplingRate:(double)rate;
-(double)defaultSamplingRate;
-(int)inputSampleSkip;
-(int)outputSampleSkip;
-(int)inputInitialSampleSkip;
-(int)outputInitialSampleSkip;
-(int)inputChannelCount;
-(int)outputChannelCount;
-(int)inputPadding;
-(BOOL)setUpAfterStartingSoundOut;
-unMuteSerialPort:orch;
-closeDownSerialPort:orch;
-adjustMonitor:(DSPLoadSpec *)system forOrchestra:orchestra;

@end

@interface SSAD64x:DSPSerialPortDevice
{
	BOOL professional;
}
-setProfessional:(BOOL)yesOrNo;   
-(int)hardwareSupportedSamplingRates:(double **)ar;
-setUpSerialPort:orchestra;
-(int)inputSampleSkip;
-(int)outputSampleSkip;
-unMuteSerialPort:orch;
-closeDownSerialPort:orch;

@end

@interface StealthDAI2400:DSPSerialPortDevice
{
	BOOL copyProhibit,emphasis;
}
-setCopyProhibit:(BOOL)yesOrNo;
-setEmphasis:(BOOL)yesOrNo;
-(int)hardwareSupportedSamplingRates:(double **)ar;
-setUpSerialPort:orchestra;
@end

@interface ArielProPort:DSPSerialPortDevice
{}
-(int)hardwareSupportedSamplingRates:(double **)ar;
-setUpSerialPort:orchestra;
@end

@interface TurtleBeachMS:DSPSerialPortDevice
{}

-setUpSerialPort:orchestra;
-(int)hardwareSupportedSamplingRates:(double **)ar;

@end


@interface TurtleBeachFiji:DSPSerialPortDevice
{}

-setUpSerialPort:orchestra;
-(int)hardwareSupportedSamplingRates:(double **)ar;
-adjustMonitor:(DSPLoadSpec *)system forOrchestra:orchestra;

@end


@interface Frankenstein:DSPSerialPortDevice
{
    unsigned long initWord1,initWord2;
    unsigned long runTimeWord1,runTimeWord2;
    int lineOutAtten,lineInGain;
    id orch;
}

/* The following methods are invoked by the Orchestra. */
-setUpSerialPort:orchestra;
-(int)hardwareSupportedSamplingRates:(double **)ar;
-(int)outputPadding;
-(int)inputPadding;
-setLineOutAttenuation:(double)val;  /* In db from -95 to 0 */
-setLineInGain:(int)val;  /* In db from 0 to 22.5 */
-(BOOL)setUpAfterStartingSoundOut; /* Returns NO */

@end

#endif

