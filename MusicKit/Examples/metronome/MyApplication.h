#import <appkit/appkit.h>

@interface MyApplication:Application {
    id	tempoSlider,aNote,pluck,cond;
}

- setTempoFromSlider:sender;
- startStop:sender;

@end
