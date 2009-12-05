#ifndef __MK_ExampApp_H___
#define __MK_ExampApp_H___
/* 
 *  Music Kit programming example  
 *  Author: David A. Jaffe
 *  This example illustrates real-time DSP control of the Ariel QuintProcessor.   
 */

#import <appkit/Application.h>

@interface ExampApp : Application
{
    id infoPanel;
    id stringTable;
    id bootingPanel;
    id susSlider;
    id pitchSlider;
    id brightSlider;
    id rateSlider;
    id playButton;
    double freq;  	/* frequency in Hz */
    BOOL continuous;    /* automatic mode switch */
    BOOL useNeXTDSP;
    double rate;
    double interval;
    double bright;
    double sustain;
    BOOL scheduled;
    BOOL varyPitch;
    BOOL varyBright;
    BOOL varySus;
    BOOL varyRate;
    BOOL varyInterval;
    id qp;            /* Quint Processor object */
    double echoAmp;
    BOOL strummingUp; 
}

-setRate:sender;
-useNeXTDSP:sender;
-setContinuous:sender;
-setSustain:sender;
-setBright:sender;
-varyPitch:sender;
-varyBright:sender;
-varySus:sender;
-varyRate:sender;
-setInterval:sender;
- setEchoAmp:sender;
- setEchoDur:sender;
- appDidInit:sender;
- playStrum:sender;
- setPitch:sender;
- terminate:sender;
- showInfoPanel:sender;

@end



#endif
