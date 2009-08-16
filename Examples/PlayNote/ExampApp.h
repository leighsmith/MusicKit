#ifndef __MK_ExampApp_H___
#define __MK_ExampApp_H___

/* 
 *  Music Kit programming example  
 *  Author: Doug Keislar, NeXT Developer Support  
 *  This example illustrates real-time DSP control.   
 *  The interface has a button for playing a note with a plucked-string 
 * timbre, and a slider to change its pitch.
 */

#import <AppKit/AppKit.h>

@interface ExampApp : NSObject
{
    id infoPanel;
    id stringTable;
}

- appDidInit:sender;
- terminate:sender;
- playNote:sender;
- bendPitch:sender;
- showInfoPanel:sender;

@end

#endif
