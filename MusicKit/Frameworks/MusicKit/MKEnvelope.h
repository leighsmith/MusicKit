/*
  $Id$
  
  Defined In: The MusicKit
  Description:

  Original Author: David Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
*/
/*
  $Log$
  Revision 1.4  2000/10/04 06:16:15  skot
  Added description selectors

  Revision 1.3  2000/04/02 16:50:32  leigh
  Cleaned up doco

  Revision 1.2  1999/07/29 01:25:44  leigh
  Added Win32 compatibility, CVS logs, SBs changes

*/
#ifndef __MK_Envelope_H___
#define __MK_Envelope_H___

#import <Foundation/Foundation.h>

typedef enum _MKEnvStatus { 
    MK_noMorePoints = -1,
    MK_noEnvError = 0,
    MK_stickPoint,
    MK_lastPoint} 
MKEnvStatus;

@interface MKEnvelope : NSObject
{
    double defaultSmoothing;    /* If no Smoothing-array, this is time constant. */
    double samplingPeriod;	/* If no X-array, this is abcissa scale */
    double *xArray;             /* Array of x values, if any. */
    double *yArray;	        /* Arrays of data values */
    double *smoothingArray;     /* Array of time constants. */
    int stickPoint;		/* Index of "steady-state", if any */
    int pointCount;		/* Number of points in envelope */
}

- init; 
-(int) pointCount; 
- (void)dealloc; 
- copyWithZone:(NSZone *)zone;
-copy;
-(double) defaultSmoothing;
-(double) samplingPeriod;
-(int) stickPoint; 
- setStickPoint:(int)sp; 
- setPointCount:(int)n xArray:(double *) xPtr orSamplingPeriod:(double)period yArray:(double *)yPtr smoothingArray:(double *)smoothingPtr orDefaultSmoothing:(double)smoothing;
-  setPointCount:(int)n xArray:(double *) xPtr yArray:(double *)yPtr ;
-(double *) yArray;
-(double *) xArray;
-(double *) smoothingArray;
-(MKEnvStatus) getNth:(int)n x:(double *)xPtr y:(double *)yPtr smoothing:(double *)smoothingPtr; 
- writeScorefileStream:(NSMutableData *)aStream; 
-(double)lookupYForX:(double)xVal;
-(double)lookupYForXAsymptotic:(double)xVal;
-(double)releaseDur;
-(double)attackDur;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (NSString*) description;

 /* The following methods are obsolete */
//- (void)initialize;
+ new; 

@end

#endif
