////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//
//  Original Author: SKoT McDonald, <skot@tomandandy.com>
//
//  Copyright (c) 2001, The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#ifndef __SNDKIT_SNDAUDIOPROCESSORINSPECTOR_H
#define __SNDKIT_SNDAUDIOPROCESSORINSPECTOR_H
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// since GNUstep appkit.h seems to leave this out...
#import <AppKit/NSDocumentController.h>

#import "SndAudioProcessor.h"
#import "SndStreamArchitectureView.h"

////////////////////////////////////////////////////////////////////////////////

/*!
@class SndAudioProcessorInspector
@abstract An inspector window for SndAudioProcessors
@discussion Inspector has an SndAudioArchitectureView allowing user to select
            the SndAudioProcessor of interest, whose parameters are then displayed
            in the tableview. A slider allows the user to change the Cubase VST
            styled float params in the range [0,1]. This will change to utilize
            the newer NSValue styled parameter API shortly.
*/
@interface SndAudioProcessorInspector : NSObject {
/*! @var parameterTableView */   
  IBOutlet NSTableView *parameterTableView;
/*! @var parameterValueSilder */   
  IBOutlet NSSlider *parameterValueSilder;
/*! @var processorActive Checkbox */   
  IBOutlet NSButton *processorActive;
/*! @var processorName */   
  IBOutlet NSTextField *processorName;
/*! @var sndArchView */   
  IBOutlet SndStreamArchitectureView *sndArchView;
/*! @var theAudProc The current target for inspection */   
  SndAudioProcessor *theAudProc;

/*! @var addFxButton */   
  IBOutlet NSButton *addFxButton;
/*! @var delFxButton */   
  IBOutlet NSButton *delFxButton;
/*! @var fxChooser */   
  IBOutlet NSComboBox *fxChooser;
/*! @var window */   
  IBOutlet NSPanel *window;
}

/*!
  @method     defaultAudioProcessorInspector
  @abstract   To come
  @discussion To come
  @result     id to the defualt SndAudioProcessorInspector.
*/
+ defaultAudioProcessorInspector;

/*!
  @method     initWithAudioProcessor:
  @abstract
  @discussion
  @param      anAudProc
  @result     self
*/
- initWithAudioProcessor: (SndAudioProcessor*) anAudProc;
/*!
  @method     setAudioProcessor:
  @abstract
  @discussion
  @param      anAudProc
  @result
*/
- setAudioProcessor: (SndAudioProcessor*) anAudProc;
/*!
  @method     onProcessorActive:
  @abstract
  @discussion
  @param      sender
  @result
*/
- onProcessorActive: (id) sender;
/*!
  @method     onParameterValueSlider:
  @abstract
  @discussion
  @param      sender
  @result
*/
- onParameterValueSlider: (id) sender;
/*!
  @method     parameterTableAction:
  @abstract
  @discussion
  @param      sender
  @result
*/
- parameterTableAction: (id) sender;
/*!
  @method     tableView:didClickTableColumn:
  @abstract
  @discussion
  @param      tableView
  @param      tableColumn
  @result
*/
- (void) tableView: (NSTableView*) tableView didClickTableColumn: (NSTableColumn*) tableColumn;
/*!
  @method     tableView:objectValueForTableColumn:row:
  @abstract
  @discussion
  @param      aTableView
  @param      aTableColumn
  @param      rowIndex
  @result
*/
- (id) tableView: (NSTableView*) aTableView objectValueForTableColumn: (NSTableColumn*) aTableColumn row: (int) rowIndex;
/*!
  @method     numberOfRowsInTableView:
  @abstract
  @discussion To come
  @param      aTableView
  @result     The number of parameters SndAudioProcessor 
*/
- (int) numberOfRowsInTableView: (NSTableView*) aTableView;
/*!
  @method     didSelectObject:
  @abstract
  @discussion To come
  @param      sndAudioArchObject
  @result     self
*/
- didSelectObject: (id) sndAudioArchObject;
/*!
  @method     onAddFxButton:
  @abstract   Adds an SndAudioProcessor of the Chooser's  currently selected type
              to the currently selected object in the SndStreamArchitectureView,
              which must be of type SndStreamClient or SndStreamMixer.
  @discussion To come
  @param      sender sender's id.
  @result     self
*/
- onAddFxButton: (id) sender;
/*!
  @method     onDelFxButton:
  @abstract   Respose method for the Del button.
  @discussion Removes the currently selected SndAudioProcessor from the host
              object's SndAudioProcessorChain. If the currently selected object
              is not an SndAudioProcessor, this method does nothing.
  @param      sender sender's id.
  @result     self
*/
- onDelFxButton: (id) sender;

@end

@interface SndAudioProcessor(Inspection)

/*!
  @method     inspect
  @abstract   Sets the SndAudioProcessorInspector's current inspection target to
              self.
  @discussion If the inspector window is not visible, it is created.
*/
- (SndAudioProcessorInspector*) inspect;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
