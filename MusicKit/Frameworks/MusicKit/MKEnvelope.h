#ifndef __MK_Envelope_H___
#define __MK_Envelope_H___
//sb:
#import <Foundation/Foundation.h>

/* Copyright 1988-1992, NeXT Inc.  All rights reserved. */
/*
  MKEnvelope.h
  
  DEFINED IN: The Music Kit
*/

#import <Foundation/NSObject.h>

typedef enum _MKEnvStatus { 
    MK_noMorePoints = -1,
    MK_noEnvError = 0,
    MK_stickPoint,
    MK_lastPoint} 
MKEnvStatus;

@interface MKEnvelope : NSObject
{
    double defaultSmoothing; 
    double samplingPeriod; 
    double *xArray;
    double *yArray;
    double *smoothingArray; 
    int stickPoint;         
    int pointCount;         
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
-(MKEnvStatus) getNth:(int)n x:(double *)xPtr y:(double *)yPtr smoothing:(double *)smoothingPtr; 
- writeScorefileStream:(NSMutableData *)aStream; 
-(double)lookupYForX:(double)xVal;
-(double)lookupYForXAsymptotic:(double)xVal;
-(double)releaseDur;
-(double)attackDur;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

 /* The following methods are obsolete */
//- (void)initialize;
+ new; 


@end



#endif
