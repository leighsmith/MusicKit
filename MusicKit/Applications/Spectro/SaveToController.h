#import <SndKit/Snd.h>

@interface SaveToController:NSObject
{
    Snd *sound;
    Snd *newSound;

    int newDataFormat;
    double newSamplingRate;
    int newChannelCount;

    id	newChnMtx;
    id	newFmtMtx;
    id	newFsMtx;
}

- (void)setSound:(Snd *)aSound;
- soundTemplate;
- revert:sender;
- setNewChn:sender;
- setNewFmt:sender;
- setNewFs:sender;

@end
