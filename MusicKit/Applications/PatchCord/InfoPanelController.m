// InfoPanelController.m

#import "InfoPanelController.h"

@implementation InfoPanelController

- (id) init {
    return [super initWithWindowNibName:@"InfoPanel"];
}

- (IBAction) showWindow: (id) sender {
    [[self window] center];
    [super showWindow:sender];
}

// extract the version number from the NIB, perhaps we should be setting this via CVS and changing the Nib programmatically?
- (NSString *) versionDescription
{
   return @"Version 2.0";
}

@end
