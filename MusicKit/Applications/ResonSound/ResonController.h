#ifndef __MK_ResonController_H___
#define __MK_ResonController_H___

#import <appkit/appkit.h>

@interface ResonController: NSObject
{
    id	ampFieldBank;
    id	ampSliderBank;
    id	freqFieldBank;
    id	freqSliderBank;
    id	panFieldBank;
    id	panSliderBank;
    id	resGainFieldBank;
    id	resGainSliderBank;
    id	outputDevice;
    id	inputDevice;
}

- runFrom:sender;
- setAmpFromSlider:sender;
- setFreqFromSlider:sender;
- setPanFromSlider:sender;
- setResGainFromSlider:sender;
- showInfoPanel:sender;
- help:sender;

@end
#endif
