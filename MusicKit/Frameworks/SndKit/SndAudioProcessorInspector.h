//
//  SndAudioProcessorInspector.h
//  SndKit
//
//  Created by SKoT McDonald on Fri Dec 21 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#import "SndAudioProcessor.h"

@interface SndAudioProcessorInspector : NSDocumentController {
  id parameterTableView;
//  id parameterBrowser;
  id parameterValueSilder;
  id processorActive;
  id processorName;
  id sndArchView;
  NSDictionary *paramDictionary;
  
  SndAudioProcessor *theAudProc; 
}

- init;
- initWithAudioProcessor: (SndAudioProcessor*) anAudProc;

- (void) dealloc;

- setAudioProcessor: (SndAudioProcessor*) anAudProc;

- onProcessorActive: (id) sender;
- onParameterValueSlider: (id) sender;

- parameterTableAction: (id) sender;

- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

- didSelectObject: (id) sndAudioArchObject;


@end
