////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description: A category of Snd performing I/O to AppKit pasteboards.
//    We place this in a separate category to isolate AppKit dependence.
//
//  Original Author:  Leigh Smith, <leigh@leighsmith.com>
//
//  Copyright (c) 2004, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and 
//  non-commercial purposes so long as the author attribution and copyright 
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import "SndPasteboard.h"

#include <AppKit/NSPasteboard.h>
#include <AppKit/NSApplication.h>

#ifndef USE_NEXTSTEP_SOUND_IO
NSString *SndPasteboardType = @"NXSoundPboardType";
#endif

@implementation Snd(Pasteboard)

- (void) writeToPasteboard: (NSPasteboard *) thePboard
{
    /* here I provide data straight away. Ideally, a non-freeing object
    * should be given the data to hold, and it should implement the "provideData"
    * method.
    * If I could guarantee that the Snd Class object itself wold not be freed
    * (for instance when the app is terminated) then one could specify the class
    * object. Cunning, eh. Maybe I'll do that anyway, and use a static variable to
    * hold the data...
    */
    /* an alternative method of providing the data here is to NOT compact,
    * but to write the data to a stream (  NXStream *ts ) and send the stream to 
    * the pasteboard. I'll leave it like it is for now.
    */
    /* here I assume that the header will be in host form, and the sound data
    * will be in "sound" (ie big endian) format. This is ok if we aren't trying
    * to share the pasteboard between dissimilar machines...
    */
    BOOL ret;
    NSMutableData *ts = [NSMutableData dataWithCapacity:soundStructSize];
    
    //	[self compactSamples];
    [self writeSoundToData:ts];
    [thePboard declareTypes:[NSArray arrayWithObject:SndPasteboardType] owner:nil];	
    
    ret = [thePboard setData:ts forType:SndPasteboardType];
    if (!ret) {
        printf("Sound paste error\n");
    }
}

- initFromPasteboard: (NSPasteboard *) thePboard
{
    NSData *soundData = [thePboard dataForType: SndPasteboardType];
        
    return [self initWithData: soundData];
}

@end