/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/* Converted to OpenStep by Nick Porcaro for Staccato Systems 1997 */

/*
  Envelope.h

  DEFINED IN: The Music Kit
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
typedef enum _MKEnvStatus {
    MK_noMorePoints = -1,
    MK_noEnvError = 0,
    MK_stickPoint,
    MK_lastPoint}
MKEnvStatus;
#define MK_DEFAULTSMOOTHING    1.0


@interface Envelope : NSObject
{
    double defaultSmoothing;    /* If no Smoothing-array, this is time constant. */
    double samplingPeriod;	/* If no X-array, this is abcissa scale */
    double *xArray;             /* Array of x values, if any. */
    double *yArray;	        /* Arrays of data values */
    double *smoothingArray;           /* Array of time constants. */
    int stickPoint;		/* Index of "steady-state", if any */
    int pointCount;		/* Number of points in envelope */
    void *_reservedEnvelope1;
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
-(double)lookupYForX:(double)xVal;
-(double)lookupYForXAsymptotic:(double)xVal;
-(double)releaseDur;
-(double)attackDur;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
