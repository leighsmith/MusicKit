////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    See Class headerdoc description below.
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
@brief An inspector window for SndAudioProcessors

  SndAudioProcessorInspector has an SndAudioArchitectureView allowing user to select
  the SndAudioProcessor of interest, whose parameters are then displayed
  in the tableview. A slider allows the user to change the "VST
  styled" float params in the range [0, 1]. This will change to utilize
  the newer NSValue styled parameter API shortly.
*/
@interface SndAudioProcessorInspector : NSObject {
/*! */  
  IBOutlet NSTableView *parameterTableView;
/*! */  
  IBOutlet NSSlider *parameterValueSilder;
/*! Checkbox */  
  IBOutlet NSButton *processorActive;
/*! */  
  IBOutlet NSTextField *processorName;
/*! */  
  IBOutlet SndStreamArchitectureView *sndArchView;
/*! The current target for inspection */  
  SndAudioProcessor *theAudProc;

/*! */  
  IBOutlet NSButton *addFxButton;
/*! */  
  IBOutlet NSButton *delFxButton;
/*! */  
  IBOutlet NSComboBox *fxChooser;
/*! */  
  IBOutlet NSPanel *window;
}

/*!
  @brief   To come
  
  To come
  @return     id to the default SndAudioProcessorInspector.
*/
+ defaultAudioProcessorInspector;

/*!
  @brief
  
  
  @param      anAudProc
  @return     self
*/
- initWithAudioProcessor: (SndAudioProcessor*) anAudProc;
/*!
  @brief
  
  
  @param      anAudProc
  @return
*/
- setAudioProcessor: (SndAudioProcessor*) anAudProc;
/*!
  @brief
  
  
  @param      sender
  @return
*/
- onProcessorActive: (id) sender;
/*!
  @brief
  
  
  @param      sender
  @return
*/
- onParameterValueSlider: (id) sender;
/*!
  @brief
  
  
  @param      sender
  @return
*/
- parameterTableAction: (id) sender;
/*!
  @brief   Adds an SndAudioProcessor of the Chooser's  currently selected type
  to the currently selected object in the SndStreamArchitectureView,
  which must be of type SndStreamClient or SndStreamMixer.
  
  To come
  @param      sender sender's id.
  @return     self
*/
- onAddFxButton: (id) sender;
/*!
  @brief   Respose method for the Del button.
  
  Removes the currently selected SndAudioProcessor from the host
  object's SndAudioProcessorChain. If the currently selected object
  is not an SndAudioProcessor, this method does nothing.
  @param      sender sender's id.
  @return     self
*/
- onDelFxButton: (id) sender;

@end

////////////////////////////////////////////////////////////////////////////////

#endif
