//
//  MKXMLObjectContainer.h
//  MusicXML
//
//  Created by Stephen Brandon on Wed May 01 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

// This class only exists as a superclass for MKXMLPartParser and MKXMLMeasureParser,
// since they both do similar jobs, depending on whether the score is timewise or partwise.
// Since either subclass can contain notes, we define methods in this superclass to handle
// the notes, and actions like backup and forward of time.


#import <Foundation/Foundation.h>
#import "MKXMLParser.h"

@class MKXMLAttributeStack;
@class MKPart;

@interface MKXMLObjectContainerParser : MKXMLParser

{
    MKPart   *mkp;
    MKXMLAttributeStack *attributeStack;
    NSMutableArray *notes;
}

- (void) addNote:(id)aNote;
- (void) backupBy:(unsigned)num;
- (void) forwardBy:(unsigned)num;

- (int) currentDivisions;

@end
