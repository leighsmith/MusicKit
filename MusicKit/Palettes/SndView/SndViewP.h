#import <InterfaceBuilder/InterfaceBuilder.h>
#import <SndKit/SndKit.h>

@interface SndViewP : IBPalette
{
    IBOutlet SndView *view1;
    IBOutlet SndView *view2;
    IBOutlet SndView *view3;
}

- (void) finishInstantiate;

@end
