/* Copyright 1993, CCRMA, Stanford University */
/* 
  Modification history:
  
  11/16/95/daj - Merged changes from LMS for mute/unmute of AD64x 

*/

#import "_musickit.h"
#import "DSPSerialPortDevice.h"
#import "MKOrchestra.h"
#import <AppKit/NSPanel.h>
#import <dsp/dsp_memory_map.h>

#define EQU(_x,_y) ((((_x)-(_y))>0)?(((_x)-(_y))<.0001):(((_y)-(_x))<.0001))

/* Serial port delegate of Orchestra.
 */
@implementation DSPSerialPortDevice:NSObject 
{
    BOOL sendsSettings;
}

-init
{
    sendsSettings = YES;
    return self;
}


-(BOOL)setUpAfterStartingSoundOut
{
    return YES;
}

-setSendsSettings:(BOOL)yesOrNo
/* Controls whether SCI commands, such as setting
 * the sampling rate  are sent in setUpSerialPort.  
 * It is up to the subclasses to pay attention to 
 * this flag and set or not set
 * the SCI accordingly. 
 */
{
    sendsSettings = yesOrNo;
    return self;
}

-(BOOL)sendsSettings
/* Returns value of sendsSettings */
{
    return sendsSettings;
}

-(int)inputChannelCount
{
    return 2;
}

-(int)outputChannelCount
{
    return 2;
}


-(int)outputPadding
{
    return 0;
}

-(int)inputPadding
{
    return 0;
}

-setUpSerialPort:orch
/* This is invoked by Orchestra open to set up the serial port. 
 * The DSPSerialPortDevice should fill the struct with the
 * appropriate values.
 */
{
    if (sendsSettings) {
	DSPWriteValue(0x0302,DSP_MS_X,0xFFF0); /* SCR */
	DSPWriteValue(0x0018,DSP_MS_X,0xFFF2); /* SCCR */
    }
    DSPWriteValue(0x4100,DSP_MS_X,0xFFEC); /* CRA */
    DSPWriteValue(0x2a00,DSP_MS_X,0xFFED); /* CRB */
    DSPWriteValue(0x1f7,DSP_MS_X,0xFFE1); /* PCC */
    return self;
}

-(BOOL)supportsSamplingRate:(double)rate;
/* This method returns YES if the device supports the specified
 * sampling rate or if that sampling rate is obtainable as half
 * of one of the sampling rates the device supports.
 * This method is implemented as 
 * return ([self hardwareSupportsSamplingRate:rate] ||
 *         [self hardwareSupportsSamplingRate:rate*2])
 * Subclass should not override this method.
 */
{ 
    return ([self hardwareSupportsSamplingRate:rate] ||
	    [self hardwareSupportsSamplingRate:rate*2]);
}

-(double)defaultSamplingRate;
/* This method returns a default sampling rate for this device.  
 * For Music Kit synthesis, this should be the lowest sampling rate
 * (within reason) so that naive users have the least trouble with
 * running out of DSP resources.  Half sampling rate may be returned.
 * Default version returns 22050.  A subclass may override this method.
 */
{
    return 22050.0;
}

-(BOOL)hardwareSupportsSamplingRate:(double)rate
  /* This returns YES if rate is a sampling rate 
   * actually supported by the device.  
   * Does not return YES for half sampling rates. 
   * A subclass may override this method.
   * Default version returns 44100.
   */
{
    double *arr;
    int cnt = [self hardwareSupportedSamplingRates:&arr];
    int i;
    for (i=0; i<cnt; i++) {
	if (EQU(arr[i],rate)) {
	  free((void *)arr);
	  return YES; 	
        }
    }
    free((void *)arr);
    return NO;
}

-(int)hardwareSupportedSamplingRates:(double **)ar 
{
    double *arr;
    _MK_MALLOC(arr,double,1);
    *ar = arr;
    arr[0] = 44100;
    return 1;	
}


-(BOOL)supportsHalfSamplingRate:(double)rate
  /* This returns YES if rate is available only
   * as half of one of the sampling rates 
   * supported by the hardware.  Implemented as
   * return ([self supportsSamplingRate:rate] && 
   *         ![self hardwareSupportsSamplingRate:rate]);
   * Subclass should not override this method.
   */
{
   return ([self supportsSamplingRate:rate] && 
	   ![self hardwareSupportsSamplingRate:rate]);
}

-(int)inputSampleSkip
{
    return 0;
}

-(int)outputSampleSkip
{
    return 0;
}

-(int)inputInitialSampleSkip
{
    return 0;
}

-(int)outputInitialSampleSkip
{
    return 0;
}

-closeDownSerialPort:orch
{
    return self;
}

-unMuteSerialPort:orch
{
    return self;
}

-adjustMonitor:(DSPLoadSpec *)system forOrchestra:orchestra
{
    return self;
}

@end

@implementation SSAD64x:DSPSerialPortDevice
{
	BOOL professional;
}

-(int)hardwareSupportedSamplingRates:(double **)ar 
{
    double *arr;
    _MK_MALLOC(arr,double,3);
    *ar = arr;
    arr[0] = 32000;
    arr[1] = 44100;
    arr[2] = 48000;
    return 3;	
}

-(int)inputSampleSkip
{
    return 1;
}

-(int)outputSampleSkip
{
    return 1;
}

-(int)inputInitialSampleSkip
{
    return 1;
}

-(int)outputInitialSampleSkip
{
    return 1;
}

-setProfessional:(BOOL)yesOrNo
{
    professional = yesOrNo;
    return self;
}

-setUpSerialPort:orchestra
{
    int i;
    int *buff;
    double samplingRate = [orchestra samplingRate];

    if ([self supportsHalfSamplingRate:samplingRate]) /* it's a half sampling rate */
      samplingRate *= 2;

    /* In the following, the data loaded into the DIT Config Buffer represents
       the first 32 bits of the AES/EBU Channel Status Block */
    if (professional) {
	/* Professional (AES/EBU) Mode */
	int dit_prof_44_cmds[13] = {
	    12,    /* count of A/D64x commands	      */
	    0x29,  /* mute Digital Out (DIT) - lms */
	    0x59,  /* Set A/D64x Sample Rate = 44.1KHz */
	    0x68,  /* Init DIT Config Buffer	      */
	    0xa1,  /* Load DIT Data: Professional mode 
		      & Emphasis not indicated */
	    0xa4,  /* Load DIT Data: SR = 44.1KHz   */
	    0xa2,  /* Load DIT Data: Mode = Stereo  */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0xa8,  /* Load DIT Data: 16-bit data    */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0x69   /* Send DIT Config Buffer        */
	  };
	int dit_prof_32_cmds[13] = {
	    12,    /* count of A/D64x commands	      */
	    0x29,  /* mute Digital Out (DIT) - lms */
	    0x58,  /* Set A/D64x Sample Rate = 32KHz */
	    0x68,  /* Init DIT Config Buffer	      */
	    0xa1,  /* Load DIT Data: Professional mode 
		      & Emphasis not indicated */
	    0xac,  /* Load DIT Data: SR = 32KHz   */
	    0xa2,  /* Load DIT Data: Mode = Stereo  */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0xa8,  /* Load DIT Data: 16-bit data    */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0xa0,  /* Load DIT Data: <placeholder>  */
	    0x69   /* Send DIT Config Buffer        */
	  };
	int dit_prof_48_cmds[13] = {
	    12,     /* count of A/D64x commands	      */
	    0x29,  /* mute Digital Out (DIT) - lms */
	    0x5a,	  /* Set A/D64x Sample Rate = 48KHz   */
	    0x68,	  /* Init DIT Config Buffer	      */
	    0xa1,	     /* Load DIT Data: Professional mode
				& Emphasis not indicated */
	    0xa8,	     /* Load DIT Data: SR = 48KHz     */
	    0xa2,	     /* Load DIT Data: Mode = Stereo  */
	    0xa0,  	     /* Load DIT Data: <placeholder>  */
	    0xa8,	     /* Load DIT Data: 16-bit data    */
	    0xa0,	     /* Load DIT Data: <placeholder>  */
	    0xa2,	     /* Load DIT Data: <placeholder>  */
	    0xa0,	     /* Load DIT Data: <placeholder>  */
	    0x69	  /* Send DIT Config Buffer           */
	  };
	
	if (EQU(samplingRate,32000.0))
	  buff = dit_prof_32_cmds;
	else if (EQU(samplingRate,48000.0))
	  buff = dit_prof_48_cmds;
	else 
	  buff = dit_prof_44_cmds;
    }
    else {
	/* Consumer (S/PDIF) Mode */
	int dit_con_44_cmds[13] = {
	    12,  /* count of A/D64x commands	      */
	    0x29,	  /* mute Digital Out (DIT) - lms     */
	    0x59,	  /* Set A/D64x Sample Rate = 44.1KHz */
	    0x68,	  /* Init DIT Config Buffer	      */
	    0xa4,	     /* Load DIT Data: Consumer mode 
				& Copy Enable  */
	    0xa0,	     /* Load DIT Data: Two Channel    */
	    0xa1,	     /* Load DIT Data: Source = CD    */
	    0xa0, 	     /* Load DIT Data: <placeholder>  */
	    0xa0,	     /* Load DIT Data: No source #    */
	    0xa0,	     /* Load DIT Data: No channel #   */
	    0xa0,	     /* Load DIT Data: SR = 44.1KHz   */
	    0xa0,	     /* Load DIT Data: <placeholder>  */
	    0x69	  /* Send DIT Config Buffer           */
	  };
	int dit_con_32_cmds[13] = {
	    12,  /* count of A/D64x commands	      */
	    0x29,	  /* mute Digital Out (DIT) - lms  	      */
	    0x58,	  /* Set A/D64x Sample Rate = 32KHz */
	    0x68,	  /* Init DIT Config Buffer	      */
	    0xa4,	     /* Load DIT Data: Consumer mode 
				& Copy Enable  */
	    0xa0,	     /* Load DIT Data: Two Channel    */
	    0xa3,	     /* Load DIT Data: Source = DAT   */
	    0xa0, 	     /* Load DIT Data: <placeholder>  */
	    0xa0,	     /* Load DIT Data: No source #    */
	    0xa0,	     /* Load DIT Data: No channel #   */
	    0xa3,	     /* Load DIT Data: SR = 32KHz   */
	    0xa0,	     /* Load DIT Data: <placeholder>  */
	    0x69	  /* Send DIT Config Buffer           */
	  };
	int dit_con_48_cmds[13] = {
	    12,     /* count of A/D64x commands	      */
	    0x29,	  /* mute Digital Out (DIT) - lms  	      */
	    0x5a,	  /* Set A/D64x Sample Rate = 48KHz   */
	    0x68,	  /* Init DIT Config Buffer	      */
	    0xa4,	     /* Load DIT Data: Consumer mode 
				& Copy Enable  */
	    0xa0,	     /* Load DIT Data: Two Channel    */
	    0xa3,	     /* Load DIT Data: Source = DAT   */
	    0xa0,  	     /* Load DIT Data: <placeholder>  */
	    0xa0,	     /* Load DIT Data: No source #    */
	    0xa0,	     /* Load DIT Data: No channel #   */
	    0xa2,	     /* Load DIT Data: SR = 48KHz     */
	    0xa0,	     /* Load DIT Data: <placeholder>  */
	    0x69	  /* Send DIT Config Buffer           */
	  };
	if (EQU(samplingRate,32000.0)) 
	  buff = dit_con_32_cmds;
	else if (EQU(samplingRate,48000.0))
	  buff = dit_con_48_cmds;
	else 
	  buff = dit_con_44_cmds;
    }
    if (sendsSettings) {
	DSPWriteValue(0x0302,DSP_MS_X,0xFFF0); /* SCR */
	DSPWriteValue(0x1010,DSP_MS_X,0xFFF2); /* SCCR */
    }
    DSPWriteValue(0x4300,DSP_MS_X,0xFFEC); /* CRA */
    DSPWriteValue(0x0a00,DSP_MS_X,0xFFED); /* CRB */
    DSPWriteValue(0x1f7,DSP_MS_X,0xFFE1); /* PCC */
    if (sendsSettings)
      for (i=1; i<=buff[0]; i++) {
	  [orchestra sendSCIByte:buff[i]];
	  [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:(10000)/1000000.0]]; /* 10 ms. Essential, but probably could be shorter */
      }
    return self;
}

-closeDownSerialPort:orchestra
{
  [orchestra sendSCIByte: 0x29];   /* mute Digital Out (DIT) - lms */
  return self;
}

-unMuteSerialPort:orchestra
{
    [orchestra sendSCIByte: 0x28]; /* unmute the Digital Out - lms */
    return self;
}

@end

@implementation StealthDAI2400:DSPSerialPortDevice
{
	BOOL copyProhibit,emphasis;
}

#define DAI_EXT_OSC    0x01
#define DAI_32         0x04
#define DAI_44         0x05
#define DAI_48         0x06
#define DAI_LOCK       0x07
#define DAI_UNLOCK     0x08
#define DAI_COPY_PROHIBIT      0x0A
#define DAI_COPY_ENABLE        0x0B
#define DAI_EMPHASIS_ON        0x0C
#define DAI_EMPHASIS_OFF       0x0D
#define DAI_RESET      0x13

-setCopyProhibit:(BOOL)yesOrNo
{
    copyProhibit = yesOrNo;
    return self;
}

-setEmphasis:(BOOL)yesOrNo
{
    emphasis = yesOrNo;
    return self;
}

-setUpSerialPort:orchestra
{
    double samplingRate = [orchestra samplingRate];
    int srateCode;
    if (sendsSettings) {
	DSPWriteValue(0x0302,DSP_MS_X,0xFFF0); /* SCR */
	DSPWriteValue(0x0018,DSP_MS_X,0xFFF2); /* SCCR */
    }
    DSPWriteValue(0x6000,DSP_MS_X,0xFFEC); /* CRA */
    /* 6000 = 24 bit mode, 1 sample per frame */
    DSPWriteValue(0x2a00,DSP_MS_X,0xFFED); /* CRB */
    /* 2000 = Receive enabled (unnecessary) 200 = synchronous
     * 800 = "network" mode.
     */
    DSPWriteValue(0x1f7,DSP_MS_X,0xFFE1); /* PCC */
    if ([self supportsHalfSamplingRate:samplingRate]) /* it's a half sampling rate */
      samplingRate *= 2;
    srateCode = ((EQU(samplingRate,32000.0)) ? DAI_32 : 
		 (EQU(samplingRate,48000.0)) ? DAI_48 : DAI_44);
    if (sendsSettings) {
	[orchestra sendSCIByte:srateCode];
	[orchestra sendSCIByte:(copyProhibit)?DAI_COPY_PROHIBIT:DAI_COPY_ENABLE];
	[orchestra sendSCIByte:(emphasis)?DAI_EMPHASIS_ON:DAI_EMPHASIS_OFF];
    }
    return self;
}

-(int)hardwareSupportedSamplingRates:(double **)ar 
{
    double *arr;
    _MK_MALLOC(arr,double,3);
    *ar = arr;
    arr[0] = 32000;
    arr[1] = 44100;
    arr[2] = 48000;
    return 3;	
}

@end

@implementation ArielProPort:DSPSerialPortDevice
{

}

-(int)hardwareSupportedSamplingRates:(double **)ar 
{
    double *arr;
    _MK_MALLOC(arr,double,7);
    *ar = arr;
    arr[0] = 8000;
    arr[1] = 11025;
    arr[2] = 16000;
    arr[3] = 32000;
    arr[4] = 44100;
    arr[5] = 48000;
    arr[6] = 96000;
    return 7;	
}

-setUpSerialPort:orchestra
{
    int srateCode;
    double samplingRate = [orchestra samplingRate];
    /* This object uses the SCI as a PARALLEL port. */
    DSPWriteValue(0x1f8,DSP_MS_X,0xFFE1); /* PCC */
    DSPWriteValue(0x007,DSP_MS_X,0xFFE3); /* PCDDR */
    if ([self supportsHalfSamplingRate:samplingRate]) /* it's a half sampling rate */
      samplingRate *= 2;
    if (EQU(samplingRate,96000.0))
      srateCode = 0;
    else if (EQU(samplingRate,48000.0))
      srateCode = 1;
    else if (EQU(samplingRate,44100.0))
      srateCode = 2;
    else if (EQU(samplingRate,32000.0))
      srateCode = 3;
    else if (EQU(samplingRate,16000.0))
      srateCode = 4;
    else if (EQU(samplingRate,11025.0))
      srateCode = 5;
    else if (EQU(samplingRate,8000.0))
      srateCode = 6;
    else srateCode = 2; /* Use 44100 as a default, for lack of anything
			 * better to do
			 */
    if (sendsSettings)
      DSPWriteValue(srateCode,DSP_MS_X,0xFFE5); /* Send Srate to PCD */
    /* Now set up CRA and B */
    DSPWriteValue(0x4100,DSP_MS_X,0xFFEC); /* CRA */
    /* 6000 = 24 bit mode, 1 sample per frame */
    DSPWriteValue(0x0a00,DSP_MS_X,0xFFED); /* CRB.  They start with receive
					    * and receive interrupt enabled (Ba00)
					    * I hope it doesn't matter. */
    /* Synchronous network mode */
    DSPWriteValue(0x1f8,DSP_MS_X,0xFFE1); /* PCC again (not needed?) */
    /* They then go ahead and set M_IPR */
    return self;
}

@end


@implementation TurtleBeachMS:DSPSerialPortDevice
{

}

/* Special multisound DSP registers */
#define MSOUND_AMPS_REG 0xffc0
#define MSOUND_DAC_REG 0xffc1
#define MSOUND_ISRATE_REG 0xffc2
#define MSOUND_OSRATE_REG 0xffc3
#define MSOUND_MEM_REG 0xffc4

/* Various values for those registers */
#define MSOUND_DAC_RESET 0x11
#define MSOUND_DAC_RUN 0x0

#define MSOUND_SRATE_44 0
#define MSOUND_SRATE_22 1
#define MSOUND_SRATE_11 2

#define MSOUND_AMP_ON 0x80

#define MSOUND_MEM_ENABLE 0x1

-setUpSerialPort:orchestra
{
    int srateCode;
    double samplingRate = [orchestra samplingRate];
    DSPWriteValue(0x6100,DSP_MS_X,0xFFEC); /* CRA */
    /* All normal settings, plus 24-bit mode */

    DSPWriteValue(0x0800,DSP_MS_X,0xFFED); /* CRB */
    /* Normal settings, except asynchronous mode (separate frame synchs
     * for transmit and receive.) 
     *
     * They start with rx, rxi, tx, txi, but we set these ourself.
     */

    DSPWriteValue(0x1fb,DSP_MS_X,0xFFE1); /* PCC */
    /* Serial IO on all pins except 2 */

    if ([self supportsHalfSamplingRate:samplingRate]) /* it's a half sampling rate */
      samplingRate *= 2;
    if (EQU(samplingRate,11025.0)) 
      srateCode = MSOUND_SRATE_11;
    else if (EQU(samplingRate,44100.0))
      srateCode = MSOUND_SRATE_44;
    else srateCode = MSOUND_SRATE_22;
    DSPWriteValue(srateCode,DSP_MS_Y,MSOUND_OSRATE_REG);
    DSPWriteValue(srateCode,DSP_MS_Y,MSOUND_ISRATE_REG);
    DSPWriteValue(MSOUND_DAC_RESET,DSP_MS_Y,MSOUND_DAC_REG);
    /* FIXME. Need to wait for DAC to reset here? */
    DSPWriteValue(MSOUND_DAC_RUN,DSP_MS_Y,MSOUND_DAC_REG);
/*    DSPWriteValue(MSOUND_MEM_ENABLE,DSP_MS_Y,MSOUND_MEM_REG); */
    /* FIXME. Maybe not here.  They do a bset.  */
    /* FIXME. They zero low byte of off-chip memory here */
    DSPWriteValue(MSOUND_AMP_ON,DSP_MS_Y,MSOUND_AMPS_REG);
    DSPWriteValue(0x1fb,DSP_MS_X,0xFFE1); /* PCC */
    return self;
}

-(int)hardwareSupportedSamplingRates:(double **)ar 
{
    double *arr;
    _MK_MALLOC(arr,double,3);
    *ar = arr;
    arr[0] = 11025;
    arr[1] = 22050;
    arr[2] = 44100;
    return 3;	
}
@end


@implementation Frankenstein:DSPSerialPortDevice
{

}

-(int)hardwareSupportedSamplingRates:(double **)ar 
{
    double *arr;
    _MK_MALLOC(arr,double,8);
    *ar = arr;
    arr[0] = 8000;
    arr[1] = 9000;
    arr[2] = 16000;
    arr[3] = 22050;
    arr[4] = 27000;
    arr[5] = 32000;
    arr[6] = 44100;
    arr[7] = 48000;

    return 8;	
}


-(int)outputPadding
  /* This codec has <left channel><right channel><control word><control word> */
{
    return 2;
}

-(int)inputPadding
{
    return 2;
}

/* From codec.asm from Motorola */

/* Run-time settings */

/* Bits for Data Time Slot 5, Output Setting */
#define EVM_HEADPHONE_EN    0x800000
#define EVM_LINEOUT_EN      0x400000
#define EVM_LEFT_OUT_ATTN   0x010000 // 63*LEFT_ATTN   = -94.5 dB, 1.5 dB steps

/* Bits for Data Time Slot 6, Output Setting */
#define EVM_SPEAKER_EN      0x004000
#define EVM_RIGHT_OUT_ATTN  0x000100 // 63*RIGHT_OUT_ATTN  = -94.5 dB, 1.5 dB steps

/* Bits for Data Time Slot 7, Input Setting */
#define EVM_MIC_IN_SELECT   0x100000 // Or 0 for line in 
#define EVM_LEFT_IN_GAIN    0x010000 // 15*LEFT_GAIN    = 22.5 dB, 1.5 dB steps

/* Bits for Data Time Slot 8, Input Setting */
#define EVM_RIGHT_IN_GAIN   0x000100 // 15*RIGHT_IN_GAIN   = 22.5 dB, 1.5 dB steps
#define EVM_MONITOR_ATTN    0x001000 // 15*MONITOR_ATTN = mute,    6   dB steps

// #define DEFAULT_LINE_ATTEN 6

/* By trial and error, we found that this combination gives more or less
 * equal gain when doing in->out->in->out chains -- DAJ
 */
#define DEFAULT_LINE_OUT_ATTEN 0
#define DEFAULT_LINE_IN_GAIN 7    

#define EVM_DEFAULT_RUNTIME_SETTINGS_WORD1  \
    (EVM_HEADPHONE_EN+EVM_LINEOUT_EN+\
     (DEFAULT_LINE_OUT_ATTEN*EVM_LEFT_OUT_ATTN)+\
	(DEFAULT_LINE_OUT_ATTEN*EVM_RIGHT_OUT_ATTN))   

#define EVM_DEFAULT_RUNTIME_SETTINGS_WORD2  \
    (EVM_MIC_IN_SELECT+(15*EVM_MONITOR_ATTN)+\
	(DEFAULT_LINE_IN_GAIN*EVM_RIGHT_IN_GAIN)+\
	(DEFAULT_LINE_IN_GAIN*EVM_LEFT_IN_GAIN))

-(BOOL)setUpAfterStartingSoundOut
{
    return NO;
}

-_updateRunTimeState
{
    /* 
     * This is now in the .asm code for init, but we can call it here
     * if we want to change it during a performance
     */
    DSPAddress outBuff;
    int endBuff;
    int i;
    if (!orch || ([orch deviceStatus] == MK_devClosed))
	return nil;
    DSPSetCurrentDSP([orch index]);
    outBuff = DSP_YB_DMA_W;
    endBuff = DSP_NB_DMA + outBuff;
    i = outBuff;
    while (i<endBuff) {
	DSPMKSendValue(runTimeWord1,DSPLCtoMS[(int)DSP_LC_Y],i+2);
	DSPMKSendValue(runTimeWord2,DSPLCtoMS[(int)DSP_LC_Y],i+3);
	i += 4;
    }
    return self;
}

-setLineOutAttenuation:(double)val  /* In db from -95 to 0 */
{
    unsigned long iVal;
    val -= val;
    val /= 1.5;
    iVal = val;
    if (iVal > 63)
      iVal = 63;
    lineOutAtten = iVal;
    runTimeWord1 &= ~(EVM_LEFT_OUT_ATTN * 63); 
    runTimeWord1 |= (EVM_LEFT_OUT_ATTN * iVal);
    runTimeWord1 &= ~(EVM_RIGHT_OUT_ATTN * 63); 
    runTimeWord1 |= (EVM_RIGHT_OUT_ATTN * iVal);
    return [self _updateRunTimeState];
}

-setLineInGain:(int)val  /* In db from 0 to 22.5 */
{
    unsigned long iVal;
    val /= 1.5;
    iVal = val;
    if (iVal > 15)
      iVal = 15;
    lineInGain = iVal;
    runTimeWord2 &= ~(EVM_RIGHT_IN_GAIN * 15); /* Turn off all bits */
    runTimeWord2 &= ~(EVM_LEFT_IN_GAIN * 15); 
    runTimeWord2 |= (EVM_RIGHT_IN_GAIN * iVal);
    runTimeWord2 |= (EVM_LEFT_IN_GAIN * iVal);
    return [self _updateRunTimeState];
}

/* Initialization-only time settings */
#define EVM_SRATE_MASK      0x003800
#define EVM_NO_PREAMP       0x100000 
#define EVM_LO_OUT_DRV      0x080000
#define EVM_HI_PASS_FILT    0x008000
#define EVM_SAMP_RATE_9     0x003800
#define EVM_SAMP_RATE_48    0x003000
#define EVM_SAMP_RATE_44    0x002800
#define EVM_SAMP_RATE_32    0x001800
#define EVM_SAMP_RATE_27    0x001000
#define EVM_SAMP_RATE_22    0x001800
#define EVM_SAMP_RATE_16    0x000800
#define EVM_SAMP_RATE_8     0x000000
#define EVM_STEREO          0x000400
#define EVM_DATA_8LIN       0x200300
#define EVM_DATA_8A         0x200200
#define EVM_DATA_8U         0x200100
#define EVM_DATA_16         0x200000
#define EVM_IMMED_3STATE    0x800000
#define EVM_XTAL2_SELECT    0x200000
#define EVM_BITS_64         0x000000
#define EVM_BITS_128        0x040000
#define EVM_BITS_256        0x080000
#define EVM_CODEC_MASTER    0x020000
#define EVM_CODEC_TX_OFF    0x010000

#define EVM_DEFAULT_I_ONLY_SETTING_WORD1 \
   (EVM_NO_PREAMP+EVM_HI_PASS_FILT+EVM_STEREO+EVM_DATA_16)
#define EVM_DEFAULT_I_ONLY_SETTING_WORD2 \
   (EVM_IMMED_3STATE+EVM_XTAL2_SELECT+EVM_BITS_64+EVM_CODEC_MASTER)

-init
{
    [super init];
    lineOutAtten = DEFAULT_LINE_OUT_ATTEN;
    lineInGain = DEFAULT_LINE_IN_GAIN;
    initWord1 = EVM_DEFAULT_I_ONLY_SETTING_WORD1;
    initWord2 = EVM_DEFAULT_I_ONLY_SETTING_WORD2;
    runTimeWord1 = EVM_DEFAULT_RUNTIME_SETTINGS_WORD1;
    runTimeWord2 = EVM_DEFAULT_RUNTIME_SETTINGS_WORD2;
    orch = nil;
    return self;
}

-setUpSerialPort:orchestra
{
    /* Need to set output buffer to have codec config words */
    double samplingRate;
    DSPAddress codecCtl1Loc,codecCtl2Loc,codecStat1Loc,codecStat2Loc;
    unsigned long srateCode;
    orch = orchestra; /* Save for above */
    samplingRate = [orchestra samplingRate];
    if ([self supportsHalfSamplingRate:samplingRate]) 
      /* it's a half sampling rate */
      samplingRate *= 2;
    if (EQU(samplingRate,9000))
      srateCode = EVM_SAMP_RATE_9;
    else if (EQU(samplingRate,48000))
      srateCode = EVM_SAMP_RATE_48;
    else if (EQU(samplingRate,44100))
      srateCode = EVM_SAMP_RATE_44;
    else if (EQU(samplingRate,27000))
      srateCode = EVM_SAMP_RATE_27;
    else if (EQU(samplingRate,22050))
      srateCode = EVM_SAMP_RATE_22;
    else if (EQU(samplingRate,16000))
      srateCode = EVM_SAMP_RATE_16;
    else if (EQU(samplingRate,8000))
      srateCode = EVM_SAMP_RATE_8;
    else /* Default */
      srateCode = EVM_SAMP_RATE_44;
    initWord1 &= ~(EVM_SRATE_MASK); /* Cancel old one. */
    initWord1 |= srateCode;
    codecCtl1Loc = DSPGetSystemSymbolValueInLC("X_CODEC_CTL1", DSP_LC_X);
    codecCtl2Loc = DSPGetSystemSymbolValueInLC("X_CODEC_CTL2", DSP_LC_X);
    codecStat1Loc = DSPGetSystemSymbolValueInLC("X_CODEC_STAT1", DSP_LC_X);
    codecStat2Loc = DSPGetSystemSymbolValueInLC("X_CODEC_STAT2", DSP_LC_X);
    DSPWriteValue(initWord1,DSP_MS_X,codecCtl1Loc);
    DSPWriteValue(initWord2,DSP_MS_X,codecCtl2Loc);
    DSPWriteValue(runTimeWord1,DSP_MS_X,codecStat1Loc);
    DSPWriteValue(runTimeWord2,DSP_MS_X,codecStat2Loc);
    return self;
}

-(double)defaultSamplingRate
{
    return 44100;
}

@end

@implementation TurtleBeachFiji:DSPSerialPortDevice
{

}


/* Special multisound DSP registers */
#define FIJI_SRATE_REG 0xffc0
#define FIJI_DIGITAL_AUDIO_CONTROL_REG 0xffc1
#define FIJI_LOW_RAM_WRITE_ENABLE_REG 0xffc2
#define FIJI_MIDI_CONTROL_REG 0xffc3
#define FIJI_PERIPHERAL_CONTROL_REG 0xffc4

/* Bit 0 - HDRREC */
#define FIJI_ADC_CLOCKS 0
#define FIJI_DA_HEADER_CLOCKS 1
/* Bit 1 - MABLE2HDR */
#define FIJI_HDRREC 0
#define FIJI_MA1 2

#define FIJI_ADC_CONTROL (FIJI_ADC_CLOCKS|FIJI_HDRREC) // Default

#define FIJI_SRATE_DISABLED 0xf
#define FIJI_SRATE_44 0xb  /* 44.1 */
#define FIJI_SRATE_22 0xa  /* 22.05 */
#define FIJI_SRATE_11 0x9  /* 11.025 */
#define FIJI_SRATE_5 0x8   /* 5.51 */

#define FIJI_SRATE_48 0x7   /* 48 */
#define FIJI_SRATE_32 0x3   /* 32 */
#define FIJI_SRATE_8 0x1    /* 8 */

/* Bit 7 */
#define FIJI_DPUNMUTE 0x80
/* Bit 6 */
#define FIJI_DPCLK 0x40
/* Bit 5 */
#define FIJI_DPDATA 0x20
/* Bit 4 */
#define FIJI_HDR_TXVER 0x10
/* Bit 3 */
#define FIJI_DATIICCLK 0x8
/* Bits 2-0 */
/* Digital peripheral chip selects (active low) for DPCLK and DPDATA */
#define FIJI_AUXCS 0x4 /* Aux input pot chip select */
#define FIJI_MICCS 0x2 /* Mic " " */
#define FIJI_LINCS 0x1 /* Line " " */

#define FIJI_PERIPHERAL_DEFAULTS FIJI_DPUNMUTE

#define CAN_SET_AFTER_BOOT 0	/* This doesn't work when set to 1, for some reason.
                                   so we have to kludge around it by diddling the
                                   monitor itself.  Sigh. */

#if (CAN_SET_AFTER_BOOT)
-setUpSerialPort:orchestra
{
    int srateCode;
    double samplingRate = [orchestra samplingRate];

    DSPWriteValue(0,DSP_MS_X,0xFFE1); /* PCC */
    DSPWriteValue(0xb02,DSP_MS_X,0xFFF0); /* SCR */
    DSPWriteValue(0xc00,DSP_MS_X,0xFFF2); /* SCCR */
    DSPWriteValue(0,DSP_MS_X,0xFFE3); /* PCDDR */
    DSPWriteValue(0x1E7,DSP_MS_X,0xFFE1); /* PCC */
    /* Serial IO on all pins except 3 & 4 */


    DSPWriteValue(0x6100,DSP_MS_X,0xFFEC); /* CRA */
    /* All normal settings, plus 24-bit mode */

    DSPWriteValue(0x0A00,DSP_MS_X,0xFFED); /* CRB */
    /* Plus SYN */

//  The following is done by reset_boot.asm
//  DSPWriteValue(FIJI_MEM_ENABLE,DSP_MS_Y,FIJI_LOW_RAM_WRITE_ENABLE_REG); 
    if ([self supportsHalfSamplingRate:samplingRate]) /* it's a half sampling rate */
      samplingRate *= 2;
    if (EQU(samplingRate,11025.0)) 
      srateCode = FIJI_SRATE_11;
    else if (EQU(samplingRate,44100.0))
      srateCode = FIJI_SRATE_44;
    else if (EQU(samplingRate,48000.0))
      srateCode = FIJI_SRATE_48;
    else if (EQU(samplingRate,32000.0))
      srateCode = FIJI_SRATE_32;
    else if (EQU(samplingRate,8000.0))
      srateCode = FIJI_SRATE_8;
    else if (EQU(samplingRate,5510.0))
      srateCode = FIJI_SRATE_5;
    else srateCode = FIJI_SRATE_22; /* Default */
    DSPWriteValue(srateCode,DSP_MS_Y,FIJI_SRATE_REG);    
    DSPWriteValue(FIJI_ADC_CONTROL,DSP_MS_Y,FIJI_DIGITAL_AUDIO_CONTROL_REG);
    DSPWriteValue(FIJI_PERIPHERAL_DEFAULTS,DSP_MS_Y,
		  FIJI_PERIPHERAL_CONTROL_REG);
    DSPWriteValue(0x1E7,DSP_MS_X,0xFFE1); /* PCC */
    return self;
}

#else 

static int setImmediate(int word,int data) {
	/* Insert data into bits 9-16 of word */
	word &= 0xff00ff;	/* Cf. DSP5600x manual */
	data <<= 8;
	return word | data;
}

#define PLL_NO_SET (-1)

#import <Foundation/NSUserDefaults.h>

static int getPLL(void) {
    
//#error DefaultsConversion: the NXDefaultsVector type is obsolete. Construct a dictionary of default registrations and use the NSUserDefaults 'registerDefaults:' method

    static NSDictionary *serialPortDefaults = nil;
    NSUserDefaults *ourDefaults = [NSUserDefaults standardUserDefaults];

    static int defaultsInitialized = 0;
    char *defaultsValue;
    if (serialPortDefaults == nil)
        serialPortDefaults = [[NSDictionary dictionaryWithObjectsAndKeys:
            @"",@"DSP_PLL",NULL,NULL] retain];

//#error DefaultsConversion: NXRegisterDefaults() is obsolete. Construct a dictionary of default registrations and use the NSUserDefaults 'registerDefaults:' method

    if (!defaultsInitialized)
        [ourDefaults registerDefaults:serialPortDefaults];//stick these in the temporary area that is searched last.

//      NXRegisterDefaults("MusicKit", serialPortDefaults);
    defaultsInitialized = 1;
    
//#warning DefaultsConversion: This used to be a call to NXGetDefaultValue with the owner "MusicKit".  If the owner was different from your applications name, you may need to modify this code.

    defaultsValue = (char *)[[ourDefaults objectForKey:@"DSP_PLL"] cString];
    if (defaultsValue)
      return atoi(defaultsValue);
    else return PLL_NO_SET;
}

-adjustMonitor:(DSPLoadSpec *)system forOrchestra:orchestra
{
    int srateCode;
    int addr;
    int PLLValue;
    DSPSection *sys,*glob;
    DSPDataRecord *dr;
    int *code;
    double samplingRate = [orchestra samplingRate];
    if ([self supportsHalfSamplingRate:samplingRate]) /* it's a half sampling rate */
      samplingRate *= 2;
    if (EQU(samplingRate,11025.0)) 
      srateCode = FIJI_SRATE_11;
    else if (EQU(samplingRate,44100.0))
      srateCode = FIJI_SRATE_44;
    else if (EQU(samplingRate,48000.0))
      srateCode = FIJI_SRATE_48;
    else if (EQU(samplingRate,32000.0))
      srateCode = FIJI_SRATE_32;
    else if (EQU(samplingRate,8000.0))
      srateCode = FIJI_SRATE_8;
    else if (EQU(samplingRate,5510.0))
      srateCode = FIJI_SRATE_5;
    else srateCode = FIJI_SRATE_22; /* Default */
    if (!system)
	return nil;
    DSPSetSystem(system);	/* Cf _DSPBoot() for all of this */
    sys = system->systemSection;
    glob = system->globalSection;
    if (!sys) 
	sys = glob;
    if (!sys)
       return nil;
    dr = sys->data[(int) DSP_LC_P];
    if (!dr)
       return nil;
    code = dr->data;	/* first code block */
    if (!code)
       return nil;
    PLLValue = getPLL();
    if (PLLValue != PLL_NO_SET) {
	addr = DSPGetSystemSymbolValueInLC("SET_PLL", DSP_LC_P);
	if (addr != -1) {	       
	    /* +1 below because we are hacking into a movep #val,loc,
	     * so data is in 2nd location */
	    code[addr+1] = PLLValue;
	}
    }
    addr = DSPGetSystemSymbolValueInLC("PIN_SRATE", DSP_LC_P);
    if (addr != -1)	       
        code[addr] = setImmediate(code[addr],srateCode);  		
    addr = DSPGetSystemSymbolValueInLC("PIN_PCSR", DSP_LC_P);
    if (addr != -1)
    	code[addr] = setImmediate(code[addr],FIJI_PERIPHERAL_DEFAULTS);
    addr = DSPGetSystemSymbolValueInLC("PIN_DACR", DSP_LC_P);
    if (addr != -1)
    	code[addr] = setImmediate(code[addr],FIJI_ADC_CONTROL);
    addr = DSPGetSystemSymbolValueInLC("PIN_IN_VOL", DSP_LC_P);
    if (addr != -1) {
	/* +1 below because we are hacking into a move $>val,loc,
	 * so data is in 2nd location */
	if ([orchestra serialSoundIn])
    		code[addr+1] = 0xc0c000; 
		/* <left><right><0> volume. c0 is unity */
	else 
    		code[addr+1] = 0; /* off */
    }
    return self;
}

-setUpSerialPort:orchestra
{
    DSPWriteValue(0,DSP_MS_X,0xFFE1); /* PCC */
    DSPWriteValue(0xb02,DSP_MS_X,0xFFF0); /* SCR */
    DSPWriteValue(0xc00,DSP_MS_X,0xFFF2); /* SCCR */
    DSPWriteValue(0,DSP_MS_X,0xFFE3); /* PCDDR */
    DSPWriteValue(0x1E7,DSP_MS_X,0xFFE1); /* PCC */
    /* Serial IO on all pins except 3 & 4 */
    DSPWriteValue(0x6100,DSP_MS_X,0xFFEC); /* CRA */
    /* All normal settings, plus 24-bit mode */
    DSPWriteValue(0x0A00,DSP_MS_X,0xFFED); /* CRB */
    /* Plus SYN */
    DSPWriteValue(0x1E7,DSP_MS_X,0xFFE1); /* PCC */
    return self;
}

#endif

-(int)hardwareSupportedSamplingRates:(double **)ar 
{
    double *arr;
    _MK_MALLOC(arr,double,7);
    *ar = arr;
    arr[0] = 11025;
    arr[1] = 22050;
    arr[2] = 44100;
    arr[3] = 48000;
    arr[4] = 32000;
    arr[5] = 8000;
    arr[6] = 5510;
    return 7;	
}

@end
