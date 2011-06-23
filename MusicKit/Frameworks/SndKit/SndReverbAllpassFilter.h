////////////////////////////////////////////////////////////////////////////////
//
//  $Id$
//
//  Description:
//    Allpass filter declaration
//    Holds and filters a single audio channel.
//
//  Original Author: Written by Jezar at Dreampoint, June 2000
//    http://www.dreampoint.co.uk
//  Rewritten into Objective-C by Leigh M. Smith <leigh@leighsmith.com>
//
//  Jezar's code described as "This code is public domain"
//
//  Copyright (c) 2001,2009 The MusicKit Project.  All rights reserved.
//
//  Permission is granted to use and modify this code for commercial and
//  non-commercial purposes so long as the author attribution and copyright
//  messages remain intact and accompany all relevant code.
//
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@interface SndReverbAllpassFilter: NSObject
{
    float feedback;
    float *buffer;
    NSUInteger bufferSize;
    NSUInteger bufferIndex;
}

- initWithLength: (NSUInteger) size;

- (void) processBuffer: (float *) input
	     replacing: (float *) output
		length: (long) bufferLength
	      channels: (int) skip;

- (float) process: (float) input;

- (void) mute;

- (void) setFeedback: (float) val;

- (float) getFeedback;
  
@end
