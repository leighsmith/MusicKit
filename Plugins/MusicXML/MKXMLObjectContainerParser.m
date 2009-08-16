//
//  MKXMLObjectContainer.m
//  MusicXML
//
//  Created by Stephen Brandon on Wed May 01 2002.
//  Copyright (c) 2002 Brandon IT Consulting. All rights reserved.
//

#import "MKXMLObjectContainerParser.h"
#import "MKXMLNoteParser.h"
#import "MKXMLAttributeStack.h"
#import <MusicKit/MKPart.h>


@implementation MKXMLObjectContainerParser

-(void) dealloc
{
    // don't bother releasing mkp, since we do not hold retain.
    [notes release];
    [attributeStack release];
    [super dealloc];
}

- (int) currentDivisions
{
    return [attributeStack currentDivisions];
}

//creating notes
//need:
// time data (ie for start of note) (running counter?)
// note number (have function to do this from step/alter/octave)
// every attribute we can lay our hands on
// "divisions" factor from either this version of part, or a previous one
//   to be able to ascertain note onsets, durations etc
// take account of "chord" and "dot" entries

-(void)addNote:(id)aNote
{
    if (aNote) {
        if (!notes) notes = [[NSMutableArray alloc] init];
        [notes addObject:aNote];
        [mkp addNote:[MKXMLNoteParser mknoteForDict:aNote currentDivisions:[self currentDivisions]]];
        if (![aNote objectForKey:@"chord"]) {
            info->startOfLastNote = info->startOfNextNote;
            info->startOfNextNote += (double)[[aNote objectForKey:@"duration"] intValue] / [self currentDivisions];
        }
    }
}

- (void) backupBy:(unsigned)num
{
    /* we are unsigned and a negative would be bad */
    double backupTime = (double)num / [self currentDivisions];
    if (backupTime <= info->startOfNextNote) {
        info->startOfNextNote -= backupTime;
    }
    else {
        info->startOfNextNote = 0;
    }
    info->startOfLastNote = info->startOfNextNote; /* no chance of a chord following a backup?) */
}

- (void) forwardBy:(unsigned)num
{
    info->startOfNextNote += (double) num / [self currentDivisions];
    info->startOfLastNote = info->startOfNextNote; /* no chance of a chord following a forward? */
}

@end
