#import <appkit/appkit.h>

@interface MyApplication:Application {
    id	tempoSlider,synthIns,cond,perf;
}

- setTempoFromSlider:sender;
- startStop:sender;

@end
